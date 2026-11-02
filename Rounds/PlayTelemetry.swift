//
//  PlayTelemetry.swift
//  Rounds
//
//  Every step of every attempt, written twice: to Supabase `play_events`
//  (durable, append-only) and to PostHog. Same event names and payload keys
//  as the web game.
//
//  Events land in a small on-disk queue first and are sent in batches in the
//  background, so a dead network or a killed app never slows play or loses
//  data. Each event has its own id, so a retried batch can't double-count.
//

import Foundation
import Supabase

/// One play of one case. Create when the case is shown; `case_started` fires on first interaction.
@MainActor
final class PlayAttempt {
    let id = UUID()
    let caseID: UUID
    let mode: String
    let difficulty: Int
    let category: String
    private(set) var isEnded = false
    private(set) var hasStarted = false
    private var step = 0
    private var startedAt = Date()
    private var lastAt = Date()

    init(caseID: UUID, mode: String, difficulty: Int, category: String) {
        self.caseID = caseID
        self.mode = mode
        self.difficulty = difficulty
        self.category = category
    }

    /// Emits `case_started` once, on the first real interaction.
    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        startedAt = Date()
        lastAt = startedAt
        emit("case_started", ["hints_visible": .integer(1)])
    }

    func emit(_ type: String, _ payload: [String: AnyJSON] = [:]) {
        let now = Date()
        var full = payload
        full["mode"] = .string(mode)
        full["difficulty"] = .integer(difficulty)
        full["category"] = .string(category)
        full["ms_since_prev"] = .integer(Int(now.timeIntervalSince(lastAt) * 1000))
        full["ms_since_start"] = .integer(Int(now.timeIntervalSince(startedAt) * 1000))
        lastAt = now
        let index = step
        step += 1
        PlayTelemetry.shared.record(attempt: self, type: type, stepIndex: index, payload: full, at: now)
    }

    func end(_ type: String, _ payload: [String: AnyJSON] = [:]) {
        guard hasStarted, !isEnded else { return }
        isEnded = true
        var p = payload
        p["total_ms"] = .integer(Int(Date().timeIntervalSince(startedAt) * 1000))
        emit(type, p)
        PlayTelemetry.shared.flushSoon(delay: 0)
    }
}

@MainActor
final class PlayTelemetry {
    static let shared = PlayTelemetry()
    static let schemaVersion = 1

    struct Row: Codable, Sendable {
        let id: UUID
        let attempt_id: UUID
        let user_id: String
        let case_id: UUID
        let event_type: String
        let step_index: Int
        let payload: [String: AnyJSON]
        let client_ts: String
        let platform: String
        let app_version: String
        let schema_version: Int
        let session_id: String?
    }

    private var pending: [Row] = []
    private var flushing = false
    private var scheduled = false
    private let maxQueue = 1000
    private let batchSize = 50
    private let fileURL: URL
    private let appVersion: String
    private let iso: ISO8601DateFormatter

    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("play_events_queue.json")
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        appVersion = "\(v) (\(b))"
        iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let data = try? Data(contentsOf: fileURL),
           let rows = try? JSONDecoder().decode([Row].self, from: data) {
            pending = rows
        }
    }

    func record(attempt: PlayAttempt, type: String, stepIndex: Int, payload: [String: AnyJSON], at date: Date) {
        // PostHog: the same event, flattened.
        var props: [String: Any] = [
            "attempt_id": attempt.id.uuidString.lowercased(),
            "case_id": attempt.caseID.uuidString.lowercased(),
            "step_index": stepIndex,
            "platform": "ios",
            "schema_version": Self.schemaVersion,
        ]
        for (k, v) in payload { props[k] = v.value }
        AnalyticsManager.shared.track(type, properties: props)

        guard let uid = AccountManager.shared.userID else { return }
        pending.append(Row(
            id: UUID(),
            attempt_id: attempt.id,
            user_id: uid,
            case_id: attempt.caseID,
            event_type: type,
            step_index: stepIndex,
            payload: payload,
            client_ts: iso.string(from: date),
            platform: "ios",
            app_version: appVersion,
            schema_version: Self.schemaVersion,
            session_id: nil
        ))
        if pending.count > maxQueue { pending.removeFirst(pending.count - maxQueue) }
        persist()
        flushSoon()
    }

    /// Batches whatever arrives in the next few seconds into one request.
    func flushSoon(delay: TimeInterval = 3) {
        guard !scheduled else { return }
        scheduled = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            self.scheduled = false
            await self.flush()
        }
    }

    /// Call on launch and when returning to the foreground. Never throws.
    func flush() async {
        guard !flushing, let uid = AccountManager.shared.userID else { return }
        let batch = Array(pending.filter { $0.user_id == uid }.prefix(batchSize))
        guard !batch.isEmpty else { return }
        flushing = true
        defer { flushing = false }
        do {
            try await AccountManager.shared.supabase
                .from("play_events")
                .upsert(batch, onConflict: "id", ignoreDuplicates: true)
                .execute()
            let sent = Set(batch.map(\.id))
            pending.removeAll { sent.contains($0.id) }
            persist()
            if pending.contains(where: { $0.user_id == uid }) { flushSoon(delay: 0.5) }
        } catch {
            #if DEBUG
            print("📊 play_events flush failed: \(error.localizedDescription)")
            #endif
            flushSoon(delay: 30)
        }
    }

    private func persist() {
        let rows = pending
        let url = fileURL
        Task.detached(priority: .utility) {
            if let data = try? JSONEncoder().encode(rows) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}
