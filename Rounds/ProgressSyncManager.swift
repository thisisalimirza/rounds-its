//
//  ProgressSyncManager.swift
//  Rounds
//
//  Mirrors on-device progress to Supabase so an account, not a device, is what
//  holds someone's history.
//
//  Until this existed nothing on the phone was ever uploaded: streaks, stats
//  and case history lived only in SwiftData, so signing in merged nothing, the
//  web had nothing to show, and reinstalling lost everything.
//
//  SwiftData stays authoritative on-device — this is a mirror, not a
//  replacement. Play works fully offline and a failed sync is always safe to
//  retry, because the server merges rather than overwrites (see
//  public.sync_progress: cumulative fields take the max, completed cases take
//  the union). That is what stops a fresh install from wiping a long streak.
//

import Foundation
import SwiftData
import Supabase

@MainActor
@Observable
final class ProgressSyncManager {
    static let shared = ProgressSyncManager()
    private init() {}

    private(set) var lastSyncedAt: Date?
    private(set) var isSyncing = false

    /// Set once at app start so syncing can read SwiftData off the main store
    /// without every caller having to pass a context around.
    private weak var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Debounce window. Games finish in bursts and each one would otherwise
    /// fire a round trip; the server merge is idempotent so a slightly stale
    /// mirror costs nothing.
    private static let minimumInterval: TimeInterval = 60

    /// Number of completed cases at the last successful push, used to notice
    /// when CloudKit has delivered history this device didn't have.
    private var lastPushedCaseCount = -1

    /// Re-pushes after CloudKit has had a chance to backfill.
    ///
    /// SwiftData's CloudKit mirroring is asynchronous: on a fresh install the
    /// local store starts empty and history arrives over the following seconds
    /// or minutes. A single push at launch therefore captures almost nothing —
    /// which is why a reinstalled device showed two hundred cases locally and
    /// one on the web.
    ///
    /// Rather than guess at a settle time, this re-checks on a short schedule
    /// and pushes only when the case count has actually grown, so a device with
    /// nothing new makes no requests at all.
    func startBackfillWatch() {
        backfillTask?.cancel()
        backfillTask = Task { [weak self] in
            for delay in [3, 10, 30, 60, 120] as [UInt64] {
                try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
                if Task.isCancelled { return }
                await self?.pushIfCaseCountChanged()
            }
        }
    }

    private var backfillTask: Task<Void, Never>?

    private func pushIfCaseCountChanged() async {
        guard let context = modelContext else { return }
        let count = (try? context.fetchCount(FetchDescriptor<CaseHistoryEntry>())) ?? 0
        guard count != lastPushedCaseCount else { return }
        await pushIfPossible(force: true)
        lastPushedCaseCount = count
    }

    // MARK: - Push

    /// Uploads local stats, merging server-side. Safe to call often.
    func pushIfPossible(force: Bool = false) async {
        guard !isSyncing else { return }
        guard AccountManager.shared.isReady else { return }

        if !force, let last = lastSyncedAt,
           Date().timeIntervalSince(last) < Self.minimumInterval {
            return
        }

        guard let snapshot = currentSnapshot() else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            _ = try await AccountManager.shared.syncProgress(snapshot)
            lastSyncedAt = Date()
        } catch {
            // Never surfaced to the user: the local store is authoritative and
            // the next launch retries.
            print("⚠️ progress push failed: \(error.localizedDescription)")
        }

        // Aggregates are only half the picture. The rich records — every case
        // played, every miss, every differential — go up separately, and are
        // reconciled rather than replayed so this stays cheap to call often.
        await pushRecords()
    }

    // MARK: - Pull

    /// Fetches the merged server state and folds anything the server knows and
    /// this device doesn't back into SwiftData.
    ///
    /// Called after linking an account, which is the moment a device can
    /// legitimately learn about history it never had — a streak built on an old
    /// phone, cases solved before a reinstall.
    func pullAndMerge() async {
        guard let context = modelContext else { return }

        do {
            guard let remote = try await AccountManager.shared.fetchProgress() else { return }

            let descriptor = FetchDescriptor<PlayerStats>()
            guard let stats = try context.fetch(descriptor).first else { return }

            // Same max/union rules as the server, so push and pull agree and
            // repeated syncs converge instead of oscillating.
            stats.gamesPlayed = max(stats.gamesPlayed, remote.gamesPlayed)
            stats.gamesWon    = max(stats.gamesWon,    remote.gamesWon)
            stats.totalScore  = max(stats.totalScore,  remote.totalScore)
            stats.maxStreak   = max(stats.maxStreak,   remote.maxStreak)
            stats.currentStreak = max(stats.currentStreak, remote.currentStreak)

            if remote.guessDistribution.count == stats.guessDistribution.count {
                stats.guessDistribution = zip(stats.guessDistribution, remote.guessDistribution).map(max)
            }

            if let remoteLast = remote.lastPlayedDate {
                stats.lastPlayedDate = max(stats.lastPlayedDate ?? .distantPast, remoteLast)
            }

            try context.save()
            lastSyncedAt = Date()
        } catch {
            print("⚠️ progress pull failed: \(error.localizedDescription)")
        }

        // Then the records themselves, so a new phone shows the actual case
        // list and weak spots rather than just a plausible-looking total.
        await pullRecords()
    }

    // MARK: - Snapshot

    private func currentSnapshot() -> ProgressSnapshot? {
        guard let context = modelContext else { return nil }

        do {
            guard let stats = try context.fetch(FetchDescriptor<PlayerStats>()).first else { return nil }

            // Completed cases come from CaseHistoryEntry, not GameSession.
            //
            // GameSession is a transient per-play object — GameView creates one
            // with @State when a case opens and replaces it on the next case,
            // so at any moment the store holds roughly the case being played.
            // CaseHistoryEntry is the durable record written on completion, and
            // it is what CaseHistoryView actually lists.
            //
            // Reading GameSession meant the mirror uploaded only the most
            // recent case, which is exactly what the web dashboard showed
            // while the phone displayed two hundred.
            let history = try context.fetch(FetchDescriptor<CaseHistoryEntry>())
            let completed = history.map { $0.caseID.uuidString }

            return ProgressSnapshot(
                gamesPlayed: stats.gamesPlayed,
                gamesWon: stats.gamesWon,
                totalScore: stats.totalScore,
                currentStreak: stats.currentStreak,
                maxStreak: stats.maxStreak,
                guessDistribution: stats.guessDistribution,
                completedCaseIDs: Array(Set(completed)),
                lastPlayedDate: stats.lastPlayedDate,
                lastDailyCasePlayed: stats.lastDailyCasePlayed,
                deviceUpdatedAt: Date()
            )
        } catch {
            print("⚠️ progress snapshot failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Records
    //
    // Everything below moves the per-row history — case results, misses, saved
    // differentials, achievements, the leaderboard entry — rather than the
    // aggregate counters `sync_progress` handles.
    //
    // These tables were the last part of a student's account that lived only on
    // one phone. Weak Spots is built from MissedItem; switching devices reset
    // the analysis the app exists to provide.

    /// Rows sent per request. Large enough that a 300-case history is two round
    /// trips, small enough to stay well inside PostgREST's request limits.
    private static let uploadChunkSize = 200

    /// Uploads anything the server doesn't already have.
    ///
    /// Every table here is keyed on a client-generated id and every row is
    /// immutable once written, so "sync" reduces to a set difference: ask the
    /// server which ids it holds, send the rest. That makes uploads idempotent
    /// (a retry is a no-op) and self-healing (a device restored from CloudKit
    /// weeks later still converges), without the client having to remember what
    /// it uploaded — a watermark would silently skip rows that CloudKit
    /// backfills with older timestamps.
    private func pushRecords() async {
        guard let context = modelContext,
              let userID = AccountManager.shared.authUserID else { return }
        let uid = userID.uuidString

        do {
            let history = try context.fetch(FetchDescriptor<CaseHistoryEntry>())
            try await reconcile(table: "case_history", userID: uid,
                                rows: history.map { CaseHistorySyncRow($0, userID: uid) })

            let misses = try context.fetch(FetchDescriptor<MissedItem>())
            try await reconcile(table: "missed_items", userID: uid,
                                rows: misses.map { MissedItemSyncRow($0, userID: uid) })

            let ddx = try context.fetch(FetchDescriptor<DDxSession>())
            try await reconcile(table: "ddx_sessions", userID: uid,
                                rows: ddx.map { DDxSessionSyncRow($0, userID: uid) })

            // Single-row tables. Nothing to reconcile — just overwrite, but
            // only when the row would actually differ, so a phone sitting on
            // the home screen isn't writing the same row every minute.
            if let progress = try context.fetch(FetchDescriptor<AchievementProgress>()).first {
                let row = AchievementSyncRow(progress, userID: uid)
                if changed("achievements", row.signature) {
                    try await upsert(table: "achievements", conflict: "user_id", rows: [row])
                    pushedSignatures["achievements"] = row.signature
                }
            }

            if let profile = try context.fetch(FetchDescriptor<LeaderboardProfile>()).first,
               let stats = try context.fetch(FetchDescriptor<PlayerStats>()).first {
                let row = LeaderboardSyncRow(profile, stats: stats, userID: uid)
                if changed("leaderboard_entries", row.signature) {
                    try await upsert(table: "leaderboard_entries", conflict: "user_id", rows: [row])
                    pushedSignatures["leaderboard_entries"] = row.signature
                }
            }
        } catch {
            print("⚠️ record push failed: \(error.localizedDescription)")
        }
    }

    /// Local row counts already reconciled during this launch.
    ///
    /// Deliberately in memory rather than persisted: a device that hasn't
    /// played since the last push makes no requests, but every fresh launch
    /// re-checks once, which is what heals a write that failed while the app
    /// was closed.
    private var reconciledCounts: [String: Int] = [:]

    /// The last value pushed for each single-row table, so an unchanged row
    /// isn't rewritten on every sync. Same lifetime and reasoning as
    /// `reconciledCounts`.
    private var pushedSignatures: [String: Int] = [:]

    private func changed(_ table: String, _ signature: Int) -> Bool {
        pushedSignatures[table] != signature
    }

    /// Sends only the rows the server is missing.
    private func reconcile(table: String, userID: String, rows: [some SyncableRow]) async throws {
        guard !rows.isEmpty else { return }
        guard reconciledCounts[table] != rows.count else { return }

        let client = AccountManager.shared.supabase

        let existing: [SyncedRowID] = try await client
            .from(table)
            .select("id")
            .eq("user_id", value: userID)
            .execute()
            .value

        let known = Set(existing.map { $0.id.lowercased() })
        let missing = rows.filter { !known.contains($0.id.lowercased()) }

        for chunk in stride(from: 0, to: missing.count, by: Self.uploadChunkSize) {
            let slice = Array(missing[chunk ..< min(chunk + Self.uploadChunkSize, missing.count)])
            try await upsert(table: table, conflict: "id", rows: slice)
        }

        // Recorded only on success — a thrown error above leaves the count
        // unchanged so the next push retries instead of assuming it landed.
        reconciledCounts[table] = rows.count
    }

    private func upsert(table: String, conflict: String, rows: [some Encodable & Sendable]) async throws {
        // `.minimal` so the server doesn't echo every row back; on a first sync
        // of a long history that echo is the bulk of the traffic.
        try await AccountManager.shared.supabase
            .from(table)
            .upsert(rows, onConflict: conflict, returning: .minimal)
            .execute()
    }

    /// Pulls at launch when this device looks like it has nothing.
    ///
    /// Signing in triggers a pull, which covers a new phone — but not a delete
    /// and reinstall. The Supabase session lives in the keychain, which
    /// survives app deletion, so that user comes back already signed in, with
    /// an empty local store and no linking step to hang a pull off.
    ///
    /// Gated on an empty history so an established device never pays for this.
    func pullIfDeviceIsEmpty() async {
        guard let context = modelContext else { return }
        guard !AccountManager.shared.isAnonymousAccount else { return }
        let local = (try? context.fetchCount(FetchDescriptor<CaseHistoryEntry>())) ?? 0
        guard local == 0 else { return }
        await pullAndMerge()
    }

    /// Brings down records this device has never seen.
    ///
    /// Only ever inserts. The server holds the union of every device's history,
    /// so anything already local is by definition the same row — and deleting
    /// local rows because the server lacks them would let a stale device wipe
    /// history it simply hadn't uploaded yet.
    private func pullRecords() async {
        guard let context = modelContext,
              let userID = AccountManager.shared.authUserID else { return }
        let uid = userID.uuidString
        let client = AccountManager.shared.supabase

        // A pull follows a sign-in, which means the account under us may have
        // changed. The cached counts were reconciled against the previous id,
        // so drop them and let the next push verify against the new one.
        reconciledCounts.removeAll()
        pushedSignatures.removeAll()

        do {
            let remoteHistory: [CaseHistorySyncRow] = try await client
                .from("case_history").select().eq("user_id", value: uid)
                .execute().value
            let localHistory = Set(try context.fetch(FetchDescriptor<CaseHistoryEntry>())
                .map { $0.id.uuidString.lowercased() })
            for row in remoteHistory where !localHistory.contains(row.id.lowercased()) {
                if let entry = row.makeEntry() { context.insert(entry) }
            }

            let remoteMisses: [MissedItemSyncRow] = try await client
                .from("missed_items").select().eq("user_id", value: uid)
                .execute().value
            let localMisses = Set(try context.fetch(FetchDescriptor<MissedItem>())
                .map { $0.id.uuidString.lowercased() })
            for row in remoteMisses where !localMisses.contains(row.id.lowercased()) {
                if let item = row.makeItem() { context.insert(item) }
            }

            let remoteDDx: [DDxSessionSyncRow] = try await client
                .from("ddx_sessions").select().eq("user_id", value: uid)
                .execute().value
            let localDDx = Set(try context.fetch(FetchDescriptor<DDxSession>())
                .map { $0.id.uuidString.lowercased() })
            for row in remoteDDx where !localDDx.contains(row.id.lowercased()) {
                if let session = row.makeSession() { context.insert(session) }
            }

            // Only when this device has no profile of its own — the local one
            // is what the user last chose here, and it is already on its way up.
            if try context.fetch(FetchDescriptor<LeaderboardProfile>()).first == nil {
                let remoteEntry: [LeaderboardSyncRow] = try await client
                    .from("leaderboard_entries").select().eq("user_id", value: uid).limit(1)
                    .execute().value
                if let row = remoteEntry.first, !row.display_name.isEmpty {
                    context.insert(row.makeProfile())
                }
            }

            // Achievements merge rather than replace: unlocks are a union and
            // the counters only ever grow, so a device that is behind can't
            // take badges away from one that is ahead.
            let remoteAchievements: [AchievementSyncRow] = try await client
                .from("achievements").select().eq("user_id", value: uid).limit(1)
                .execute().value
            if let remote = remoteAchievements.first {
                // Fetch-or-create, matching how GameView reaches for it, so a
                // device that has never finished a case still lands the badges
                // the account already earned.
                let local: AchievementProgress
                if let existing = try context.fetch(FetchDescriptor<AchievementProgress>()).first {
                    local = existing
                } else {
                    local = AchievementProgress()
                    context.insert(local)
                }
                remote.merge(into: local)
            }

            try context.save()
        } catch {
            print("⚠️ record pull failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Wire types

struct ProgressSnapshot: Encodable {
    let gamesPlayed: Int
    let gamesWon: Int
    let totalScore: Int
    let currentStreak: Int
    let maxStreak: Int
    let guessDistribution: [Int]
    let completedCaseIDs: [String]
    let lastPlayedDate: Date?
    let lastDailyCasePlayed: String?
    let deviceUpdatedAt: Date
}

/// A row whose identity the server and the device agree on, so reconciliation
/// is a set difference rather than a replay.
nonisolated protocol SyncableRow: Encodable, Sendable {
    var id: String { get }
}

/// Just enough of a row to answer "do you already have this one?".
nonisolated struct SyncedRowID: Decodable, Sendable {
    let id: String
}

/// Timestamp conversion for the synced tables.
///
/// Dates cross the wire as strings rather than relying on the client's date
/// encoding strategy, which differs between the encoder PostgREST uses for
/// writes and what Postgres returns on reads.
nonisolated enum SyncTime {
    // nonisolated(unsafe) because these are shared from nonisolated row
    // initializers. Formatting and parsing on ISO8601DateFormatter is
    // thread-safe once configured, and nothing mutates these after setup —
    // the alternative is rebuilding a CFDateFormatter per row, which on a
    // three-hundred-case first sync is the most expensive thing in the path.
    nonisolated(unsafe) private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    nonisolated(unsafe) private static let isoWhole: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func string(from date: Date) -> String { iso.string(from: date) }

    static func date(from raw: String) -> Date? {
        // Postgres returns microseconds ("…T12:00:00.123456+00:00");
        // ISO8601DateFormatter only accepts milliseconds and returns nil for
        // anything longer, so trim the fraction before parsing.
        var text = raw
        if let dot = text.firstIndex(of: "."),
           let zoneStart = text[text.index(after: dot)...].firstIndex(where: { $0 == "+" || $0 == "-" || $0 == "Z" }) {
            let fraction = text[text.index(after: dot)..<zoneStart]
            if fraction.count > 3 {
                text.replaceSubrange(text.index(after: dot)..<zoneStart, with: fraction.prefix(3))
            }
        }
        return iso.date(from: text) ?? isoWhole.date(from: text) ?? isoWhole.date(from: raw)
    }
}

// MARK: - Record rows

nonisolated struct CaseHistorySyncRow: Codable, SyncableRow {
    let id: String
    let user_id: String
    let case_id: String
    let diagnosis: String
    let category: String
    let difficulty: Int
    let was_correct: Bool
    let guess_count: Int
    let score: Int
    let hints_used: Int
    let guesses: [String]
    let was_daily_case: Bool
    let played_at: String

    @MainActor init(_ entry: CaseHistoryEntry, userID: String) {
        id = entry.id.uuidString
        user_id = userID
        case_id = entry.caseID.uuidString
        diagnosis = entry.diagnosis
        category = entry.category
        difficulty = entry.difficulty
        was_correct = entry.wasCorrect
        guess_count = entry.guessCount
        score = entry.score
        hints_used = entry.hintsUsed
        guesses = entry.guesses
        was_daily_case = entry.wasDailyCase
        played_at = SyncTime.string(from: entry.playedAt)
    }

    /// Rebuilds the local record, preserving the server's id and timestamp —
    /// the initializer generates fresh ones, which would make every pull
    /// duplicate the history it just downloaded.
    @MainActor func makeEntry() -> CaseHistoryEntry? {
        guard let rowID = UUID(uuidString: id), let caseUUID = UUID(uuidString: case_id) else { return nil }
        let entry = CaseHistoryEntry(
            caseID: caseUUID,
            diagnosis: diagnosis,
            category: category,
            difficulty: difficulty,
            wasCorrect: was_correct,
            guessCount: guess_count,
            score: score,
            hintsUsed: hints_used,
            guesses: guesses,
            wasDailyCase: was_daily_case
        )
        entry.id = rowID
        entry.playedAt = SyncTime.date(from: played_at) ?? entry.playedAt
        return entry
    }
}

nonisolated struct MissedItemSyncRow: Codable, SyncableRow {
    let id: String
    let user_id: String
    let source: String
    let topic: String
    let item: String
    let detail: String
    let reviewed: Bool
    let occurred_at: String

    @MainActor init(_ missed: MissedItem, userID: String) {
        id = missed.id.uuidString
        user_id = userID
        source = missed.source
        topic = missed.topic
        item = missed.item
        detail = missed.detail
        reviewed = missed.reviewed
        occurred_at = SyncTime.string(from: missed.timestamp)
    }

    @MainActor func makeItem() -> MissedItem? {
        guard let rowID = UUID(uuidString: id) else { return nil }
        // The model stores `source` as a raw string, so an unrecognised value
        // from a newer build round-trips intact instead of being dropped.
        let missed = MissedItem(source: MissSource(rawValue: source) ?? .dailyCase,
                                topic: topic, item: item, detail: detail)
        missed.id = rowID
        missed.source = source
        missed.reviewed = reviewed
        missed.timestamp = SyncTime.date(from: occurred_at) ?? missed.timestamp
        return missed
    }
}

nonisolated struct DDxSessionSyncRow: Codable, SyncableRow {
    let id: String
    let user_id: String
    let findings: String
    let context: String
    let chief_complaint: String
    let system: String
    let result: DifferentialResult?
    let created_at: String

    @MainActor init(_ session: DDxSession, userID: String) {
        id = session.id.uuidString
        user_id = userID
        findings = session.findings
        context = session.context
        chief_complaint = session.chiefComplaint
        system = session.system
        result = session.result
        created_at = SyncTime.string(from: session.timestamp)
    }

    @MainActor func makeSession() -> DDxSession? {
        guard let rowID = UUID(uuidString: id), let result else { return nil }
        let session = DDxSession(findings: findings, context: context, result: result)
        session.id = rowID
        session.timestamp = SyncTime.date(from: created_at) ?? session.timestamp
        return session
    }
}

nonisolated struct AchievementSyncRow: Codable, Sendable {
    let user_id: String
    let unlocked: [String]
    let first_hint_win_count: Int
    let category_stats: [String: CategoryStat]
    let streak_freezes_available: Int
    let last_streak_freeze_reset: String?
    let updated_at: String

    @MainActor init(_ progress: AchievementProgress, userID: String) {
        user_id = userID
        unlocked = progress.unlockedAchievements
        first_hint_win_count = progress.firstHintWinCount
        category_stats = progress.categoryStats
        streak_freezes_available = progress.streakFreezesAvailable
        last_streak_freeze_reset = progress.lastStreakFreezeReset.map(SyncTime.string(from:))
        updated_at = SyncTime.string(from: Date())
    }

    /// Everything except the timestamp, which changes on every construction
    /// and would defeat the point of comparing.
    var signature: Int {
        var hasher = Hasher()
        hasher.combine(unlocked.sorted())
        hasher.combine(first_hint_win_count)
        hasher.combine(streak_freezes_available)
        for key in category_stats.keys.sorted() {
            hasher.combine(key)
            hasher.combine(category_stats[key])
        }
        return hasher.finalize()
    }

    /// Folds the server's copy into the local one. Unlocks are a union and
    /// counters take the max, matching how `sync_progress` merges stats, so
    /// syncing from a device that is behind never removes anything.
    ///
    /// The weekly streak-freeze allowance is deliberately left alone. It is a
    /// spendable Pro benefit, not a record of something earned, and taking the
    /// max would refill it by signing in on a second device.
    @MainActor func merge(into progress: AchievementProgress) {
        let combined = Set(progress.unlockedAchievements).union(unlocked)
        if combined.count != progress.unlockedAchievements.count {
            progress.unlockedAchievements = Array(combined).sorted()
        }
        progress.firstHintWinCount = max(progress.firstHintWinCount, first_hint_win_count)

        for (category, remote) in category_stats {
            let local = progress.categoryStats[category]
            progress.categoryStats[category] = CategoryStat(
                totalCases: max(local?.totalCases ?? 0, remote.totalCases),
                wins: max(local?.wins ?? 0, remote.wins)
            )
        }
    }
}

nonisolated struct LeaderboardSyncRow: Codable, Sendable {
    let user_id: String
    let display_name: String
    let school_id: String
    let school_name: String
    let state: String
    let country: String
    let is_international: Bool
    let visibility: String
    let total_score: Int
    let games_played: Int
    let games_won: Int
    let legacy_player_id: String?
    let updated_at: String

    @MainActor init(_ profile: LeaderboardProfile, stats: PlayerStats, userID: String) {
        user_id = userID
        display_name = profile.displayName
        school_id = profile.schoolID
        school_name = profile.schoolName
        state = profile.state
        country = profile.country
        is_international = profile.isInternational
        // The column is constrained to these three; anything else would fail
        // the whole upsert rather than just this field.
        visibility = ["private", "school", "global"].contains(profile.visibilityLevelRaw)
            ? profile.visibilityLevelRaw : "school"
        total_score = max(0, stats.totalScore)
        games_played = max(0, stats.gamesPlayed)
        games_won = max(0, stats.gamesWon)
        // Lets a later cleanup match this entry to the CloudKit record it
        // replaces, including the duplicates one player accumulated there.
        legacy_player_id = profile.playerID
        updated_at = SyncTime.string(from: Date())
    }

    /// Everything except the timestamp, which changes on every construction
    /// and would defeat the point of comparing.
    var signature: Int {
        var hasher = Hasher()
        // Included so that removing a leaderboard profile and building a new
        // one always re-pushes: the replacement gets a fresh playerID, which
        // would otherwise be the only difference and get skipped.
        hasher.combine(legacy_player_id)
        hasher.combine(display_name)
        hasher.combine(school_id)
        hasher.combine(state)
        hasher.combine(country)
        hasher.combine(visibility)
        hasher.combine(total_score)
        hasher.combine(games_played)
        hasher.combine(games_won)
        return hasher.finalize()
    }

    /// Restores the leaderboard identity on a device that has none, so a new
    /// phone keeps the player's school and display name instead of dropping
    /// them off the standings until they set it up again.
    @MainActor func makeProfile() -> LeaderboardProfile {
        LeaderboardProfile(
            playerID: legacy_player_id.flatMap { $0.isEmpty ? nil : $0 } ?? UUID().uuidString,
            displayName: display_name,
            schoolID: school_id,
            schoolName: school_name,
            state: state,
            country: country,
            isInternational: is_international,
            visibilityLevel: LeaderboardVisibility(rawValue: visibility) ?? .schoolOnly
        )
    }
}

struct RemoteProgress: Decodable {
    let gamesPlayed: Int
    let gamesWon: Int
    let totalScore: Int
    let currentStreak: Int
    let maxStreak: Int
    let guessDistribution: [Int]
    let completedCaseIDs: [String]
    let lastPlayedDate: Date?

    enum CodingKeys: String, CodingKey {
        case gamesPlayed = "games_played"
        case gamesWon = "games_won"
        case totalScore = "total_score"
        case currentStreak = "current_streak"
        case maxStreak = "max_streak"
        case guessDistribution = "guess_distribution"
        case completedCaseIDs = "completed_case_ids"
        case lastPlayedDate = "last_played_date"
    }
}
