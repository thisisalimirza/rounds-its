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
    }

    // MARK: - Snapshot

    private func currentSnapshot() -> ProgressSnapshot? {
        guard let context = modelContext else { return nil }

        do {
            guard let stats = try context.fetch(FetchDescriptor<PlayerStats>()).first else { return nil }

            // Completed cases come from finished sessions rather than a
            // dedicated list, so the mirror reflects what was actually played.
            let sessions = try context.fetch(FetchDescriptor<GameSession>())
            let completed = sessions
                .filter { $0.gameState != .playing }
                .compactMap { $0.medicalCase?.id.uuidString }

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
