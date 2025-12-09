//
//  StepordleApp.swift
//  Stepordle
//
//  Created by Ali Mirza on 12/9/25.
//

import SwiftUI
import SwiftData

@main
struct StepordleApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MedicalCase.self,
            GameSession.self,
            PlayerStats.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Seed initial data if needed
            seedDataIfNeeded(container: container)
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
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
