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
                    await AccountManager.shared.bootstrap()

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

                    // A reinstalled device restores its session from the
                    // keychain and comes back signed in but empty; this is what
                    // puts the account's history back on screen.
                    await ProgressSyncManager.shared.pullIfDeviceIsEmpty()
                    await ProgressSyncManager.shared.pushIfPossible(force: true)

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
                    } else if phase == .active {
                        // Returning to the app is also when CloudKit tends to
                        // have delivered anything it fetched while suspended.
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

        // One-time: seed the universal miss log from historical missed cases so
        // existing users' Weak Spots, Study Plan, and Illness Scripts pick up
        // everything they've already gotten wrong (not just new misses).
        backfillMissedItemsFromHistory(context: context)
    }

    /// Backfills `MissedItem` records from `CaseHistoryEntry` misses that predate
    /// the universal miss log. Runs once, deduped by diagnosis + day so it never
    /// double-counts misses that were already logged.
    private static func backfillMissedItemsFromHistory(context: ModelContext) {
        let key = "didBackfillMissedItemsFromHistory_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let missed = (try? context.fetch(
            FetchDescriptor<CaseHistoryEntry>(predicate: #Predicate { $0.wasCorrect == false })
        )) ?? []

        if missed.isEmpty {
            UserDefaults.standard.set(true, forKey: key)
            return
        }

        let existing = (try? context.fetch(FetchDescriptor<MissedItem>())) ?? []
        func dayKey(_ item: String, _ date: Date) -> String {
            "\(item.lowercased())|\(Int(Calendar.current.startOfDay(for: date).timeIntervalSince1970))"
        }
        var seen = Set(existing.map { dayKey($0.item, $0.timestamp) })

        var inserted = 0
        for entry in missed {
            let diagnosis = entry.diagnosis.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !diagnosis.isEmpty else { continue }
            let k = dayKey(diagnosis, entry.playedAt)
            if seen.contains(k) { continue }
            seen.insert(k)
            let mi = MissedItem(source: .dailyCase,
                                topic: entry.category.isEmpty ? "General" : entry.category,
                                item: diagnosis)
            mi.timestamp = entry.playedAt
            context.insert(mi)
            inserted += 1
        }
        try? context.save()
        UserDefaults.standard.set(true, forKey: key)
        print("Backfilled \(inserted) MissedItems from case history")
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

