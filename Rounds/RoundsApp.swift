//
//  RoundsApp.swift
//  Rounds
//
//  Created by Ali Mirza on 12/9/25.
//

import SwiftUI
import SwiftData

// MARK: - Deep Link Manager
@Observable
class DeepLinkManager {
    static let shared = DeepLinkManager()
    var pendingCaseID: String?
    var pendingInviteCode: String?

    private init() {}

    func handleURL(_ url: URL) -> Bool {
        guard url.scheme == "rounds" else { return false }

        // Handle rounds://invite/{code}
        if url.host == "invite",
           let code = url.pathComponents.last,
           !code.isEmpty, code != "/" {
            pendingInviteCode = code
            return true
        }

        // Handle rounds://case/{caseID}
        if url.host == "case",
           let caseID = url.pathComponents.last,
           !caseID.isEmpty, caseID != "/" {
            pendingCaseID = caseID
            return true
        }

        return false
    }

    func consumePendingCase() -> String? {
        let caseID = pendingCaseID
        pendingCaseID = nil
        return caseID
    }

    func consumePendingInvite() -> String? {
        let code = pendingInviteCode
        pendingInviteCode = nil
        return code
    }
}

@main
struct RoundsApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    /// Used to flush the progress mirror when the app goes to the background.
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Configure RevenueCat on app launch
        // This is nonisolated and safe to call during init
        SubscriptionManager.shared.configure()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MedicalCase.self,
            GameSession.self,
            PlayerStats.self,
            CaseHistoryEntry.self,
            AchievementProgress.self,
            LeaderboardProfile.self,
            MissedItem.self,
            DDxSession.self
        ])

        // Use a stable URL so we can remove incompatible stores and retry
        let storeURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Rounds.store")

        // Ensure directory exists
        try? FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let persistentConfig = ModelConfiguration(schema: schema, url: storeURL)

        // 1) Try persistent store
        if let container = try? ModelContainer(for: schema, configurations: [persistentConfig]) {
            seedDataIfNeeded(container: container)
            return container
        }

        // 2) Remove incompatible/corrupted store and retry once
        try? FileManager.default.removeItem(at: storeURL)
        if let container = try? ModelContainer(for: schema, configurations: [persistentConfig]) {
            seedDataIfNeeded(container: container)
            return container
        }

        // 3) Final fallback: in-memory store so the app can launch
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let fallback = try ModelContainer(for: schema, configurations: [memoryConfig])
            return fallback
        } catch {
            // Print the actual error so we can diagnose
            print("❌ SwiftData ModelContainer Error: \(error)")
            print("❌ Error Description: \(error.localizedDescription)")
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Track app launch asynchronously to avoid concurrency issues
                    await MainActor.run {
                        AnalyticsManager.shared.trackAppLaunch()
                        SessionTracker.shared.startSession()

                        // Show onboarding for first-time users
                        if !hasCompletedOnboarding {
                            showOnboarding = true
                        }
                    }
                }
                .task {
                    // Ensure a (silent, anonymous) account exists and tie it to
                    // RevenueCat so Pro syncs across devices; loads referral status.
                    NetworkMonitor.shared.start()
                    await AccountManager.shared.bootstrap()
                    AppConfigService.shared.refresh()
                    let context = sharedModelContainer.mainContext
                    let games = (try? context.fetch(FetchDescriptor<PlayerStats>()))?.first?.gamesPlayed ?? 0
                    let history = (try? context.fetchCount(FetchDescriptor<CaseHistoryEntry>())) ?? 0
                    AccountCohortStore.establishIfNeeded(hasPriorProgress: games > 0 || history > 0)
                    MigrationCoordinator.shared.noteSession(userID: AccountManager.shared.authUserID)

                    // Mirror on-device progress to the account. The server
                    // merges rather than overwrites, so this is safe even from
                    // a device that is behind — see public.sync_progress.
                    // Content refresh is fire-and-forget and never blocks play:
                    // the library is already loaded from disk or the bundle by
                    // the time this runs.
                    CaseStore.shared.refresh()

                    ProgressSyncManager.shared.configure(modelContext: sharedModelContainer.mainContext)

                    // Before anything reads or uploads the totals. Runs even
                    // with no account, since a stale PlayerStats is wrong on
                    // the Stats tab too, not just on the web.
                    ProgressSyncManager.shared.repairLocalStats()

                    // Both directions. Pushing alone left a second device
                    // uploading forever and never receiving.
                    await ProgressSyncManager.shared.sync()
                    if let profile = try? context.fetch(FetchDescriptor<LeaderboardProfile>()).first {
                        await LeaderboardManager.shared.backfillOwnCloudKitScoreIfNeeded(profile: profile)
                    }

                    // CloudKit restores history asynchronously after launch, so
                    // the push above can only see what has arrived so far.
                    ProgressSyncManager.shared.startBackfillWatch()
                }
                .onChange(of: scenePhase) { _, phase in
                    // Backgrounding is the reliable moment to capture a
                    // session's results; pushing per-game would fire a round
                    // trip for every case played.
                    if phase == .background {
                        Task { await ProgressSyncManager.shared.pushIfPossible(force: true) }
                        Task { await PlayTelemetry.shared.flush() }
                    }
                    if phase == .active {
                        // Coming back is when another device's games are most
                        // likely to be waiting, and also when CloudKit tends to
                        // have delivered whatever it fetched while suspended.
                        NetworkMonitor.shared.start()
                        AppConfigService.shared.refresh()
                        Task { await PlayTelemetry.shared.flush() }
                        Task {
                            await SubscriptionManager.shared.refreshCustomerInfo()
                            await AccountManager.shared.refreshStatus()
                            await ProgressSyncManager.shared.sync()
                        }
                        ProgressSyncManager.shared.startBackfillWatch()
                    }
                }
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView()
                        .interactiveDismissDisabled() // Prevent accidental swipe dismissal
                }
                .onOpenURL { url in
                    // Handle deep links like rounds://case/{caseID}
                    _ = DeepLinkManager.shared.handleURL(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Seed Data & Migration
    private static func seedDataIfNeeded(container: ModelContainer) {
        let context = ModelContext(container)

        // Run one-time migration for schema changes (v1.1)
        migrateIfNeeded(context: context)

        // Check if we already have cases
        let descriptor = FetchDescriptor<MedicalCase>()
        let existingCases = (try? context.fetch(descriptor)) ?? []

        if existingCases.isEmpty {
            // Add sample cases from library
            let sampleCases = CaseLibrary.getSampleCases()
            for medicalCase in sampleCases {
                context.insert(medicalCase)
            }

            try? context.save()
        }
        else {
            // Merge new cases by diagnosis name (case-insensitive) without duplicating
            let existingDiagnoses = Set(existingCases.map { $0.diagnosis.lowercased() })
            let libraryCases = CaseLibrary.getSampleCases()
            let newOnes = libraryCases.filter { !existingDiagnoses.contains($0.diagnosis.lowercased()) }
            if !newOnes.isEmpty {
                for c in newOnes { context.insert(c) }
                try? context.save()
            }
        }

        // Initialize player stats if needed
        let statsDescriptor = FetchDescriptor<PlayerStats>()
        let existingStats = (try? context.fetch(statsDescriptor)) ?? []

        if existingStats.isEmpty {
            let newStats = PlayerStats()
            context.insert(newStats)
            try? context.save()
        }

        let gamesPlayed = (try? context.fetch(FetchDescriptor<PlayerStats>()))?.first?.gamesPlayed ?? 0
        let historyCount = (try? context.fetchCount(FetchDescriptor<CaseHistoryEntry>())) ?? 0
        AccountCohortStore.establishIfNeeded(hasPriorProgress: gamesPlayed > 0 || historyCount > 0)

        // One-time: seed the universal miss log from historical missed cases so
        // existing users' Weak Spots, Study Plan, and Illness Scripts pick up
        // everything they've already gotten wrong (not just new misses).
        backfillMissedItemsFromHistory(context: context)
    }

    /// Backfills `MissedItem` records from `CaseHistoryEntry` rows that predate
    /// the universal miss log, or that arrived via CloudKit after an earlier
    /// backfill found nothing. Includes losses and wins that needed help
    /// (`WeakSpotRule`). One row per diagnosis per local day. A row that is
    /// already there is left alone: reviewed stays reviewed and detail is not
    /// rewritten. This does not retag existing items or server rows.
    ///
    /// Only marks backfill complete (`v3`) after seeing non-empty history. An
    /// empty history can mean CloudKit hasn't delivered yet, so the flag stays
    /// unset and a later launch, or the CloudKit backfill watch, tries again.
    /// History with an empty `playSource` that was not a daily case is logged
    /// as browse. An explicit random source stays random.
    ///
    /// - Parameter force: When `true`, skips the "already done" flag check.
    ///   Used by the CloudKit backfill watch to catch history that arrives
    ///   after the initial backfill completed.
    @MainActor
    static func backfillMissedItemsFromHistory(context: ModelContext, force: Bool = false) {
        let keyV3 = "didBackfillMissedItemsFromHistory_v3"
        if !force && UserDefaults.standard.bool(forKey: keyV3) { return }

        let history = (try? context.fetch(FetchDescriptor<CaseHistoryEntry>())) ?? []

        if history.isEmpty {
            return
        }

        var inserted = 0
        for entry in history {
            let diagnosis = entry.diagnosis.trimmingCharacters(in: .whitespacesAndNewlines)
            guard WeakSpotRule.shouldLog(
                diagnosis: diagnosis,
                won: entry.wasCorrect,
                hintsUsed: entry.hintsUsed,
                guesses: entry.guessCount
            ) else { continue }
            let raw = PlayOrigin.missSourceRaw(stored: entry.playSource, wasDailyCase: entry.wasDailyCase)
            guard let source = MissSource(rawValue: raw) else { continue }
            let wrote = MistakeLog.record(
                context,
                source: source,
                topic: entry.category,
                item: diagnosis,
                detail: WeakSpotRule.detail(
                    won: entry.wasCorrect,
                    hintsUsed: entry.hintsUsed,
                    guesses: entry.guessCount
                ),
                at: entry.playedAt
            )
            if wrote { inserted += 1 }
        }

        if inserted > 0 {
            try? context.save()
            print("Backfilled \(inserted) MissedItems from case history")
        }

        UserDefaults.standard.set(true, forKey: keyV3)
    }

    // MARK: - Schema Migration

    /// Handles one-time migrations when updating from older app versions
    /// Version 1.1: GameSession.gameState renamed to gameStateRaw (String) for CloudKit compatibility
    private static func migrateIfNeeded(context: ModelContext) {
        let migrationKey = "hasCompletedMigration_v1_1"

        // Check if migration already completed
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        // Migration v1.1: Clear old GameSession records
        // The gameState property was renamed to gameStateRaw with a type change.
        // GameSession only stores in-progress games (not history), so clearing is safe.
        // User's stats, streaks, and case history are preserved in PlayerStats and CaseHistoryEntry.
        do {
            let sessionDescriptor = FetchDescriptor<GameSession>()
            let oldSessions = try context.fetch(sessionDescriptor)

            for session in oldSessions {
                context.delete(session)
            }

            try context.save()
            print("Migration v1.1: Cleared \(oldSessions.count) old game sessions")
        } catch {
            print("Migration v1.1: Error clearing sessions - \(error.localizedDescription)")
            // Continue anyway - the app should still work, old sessions just won't load properly
        }

        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}

