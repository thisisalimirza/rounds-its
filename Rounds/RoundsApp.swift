//
//  RoundsApp.swift
//  Rounds
//
//  Created by Ali Mirza on 12/9/25.
//

import SwiftUI
import SwiftData

@main
struct RoundsApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    
    init() {
        // Configure RevenueCat on app launch (synchronous - no Task needed)
        SubscriptionManager.shared.configure()
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MedicalCase.self,
            GameSession.self,
            PlayerStats.self
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
        let fallback = try! ModelContainer(for: schema, configurations: [memoryConfig])
        return fallback
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Track app launch
                    AnalyticsManager.shared.trackAppLaunch()
                    SessionTracker.shared.startSession()
                    
                    // Show onboarding for first-time users
                    if !hasCompletedOnboarding {
                        showOnboarding = true
                    }
                }
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    // MARK: - Seed Data
    private static func seedDataIfNeeded(container: ModelContainer) {
        let context = ModelContext(container)
        
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
}

