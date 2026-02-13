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

    private init() {}

    func handleURL(_ url: URL) -> Bool {
        // Handle rounds://case/{caseID}
        guard url.scheme == "rounds",
              url.host == "case",
              let caseID = url.pathComponents.last,
              !caseID.isEmpty,
              caseID != "/" else {
            return false
        }

        pendingCaseID = caseID
        return true
    }

    func consumePendingCase() -> String? {
        let caseID = pendingCaseID
        pendingCaseID = nil
        return caseID
    }
}

@main
struct RoundsApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

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
            LeaderboardProfile.self
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

