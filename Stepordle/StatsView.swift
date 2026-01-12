//
//  StatsView.swift
//  Rounds
//
//  Created by Ali Mirza on 12/9/25.
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var playerStats: [PlayerStats]
    
    private var stats: PlayerStats? {
        playerStats.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let stats = stats {
                        // Training Level Card (New!)
                        trainingLevelCard(stats: stats)
                        
                        // Overall Statistics
                        statisticsGrid(stats: stats)
                        
                        // Guess Distribution
                        guessDistribution(stats: stats)
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Training Level Card
    private func trainingLevelCard(stats: PlayerStats) -> some View {
        let currentLevel = stats.trainingLevel
        let nextLevel = MedicalTrainingLevel.nextLevel(for: stats.totalScore)
        let progress = nextLevel != nil ? Double(stats.totalScore - currentLevel.minScore) / Double(nextLevel!.minScore - currentLevel.minScore) : 1.0
        
        return VStack(spacing: 16) {
            // Header
            HStack {
                Text("Your Training Level")
                    .font(.headline)
                Spacer()
            }
            
            // Level Badge
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(colorForString(currentLevel.color).opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: currentLevel.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(colorForString(currentLevel.color))
                }
                
                // Level Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentLevel.displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(currentLevel.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(stats.totalScore) points")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Progress to next level
            if let nextLevel = nextLevel {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Next: \(nextLevel.rank) - Level \(nextLevel.level)")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(nextLevel.minScore - stats.totalScore) pts to go")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorForString(currentLevel.color))
                                .frame(width: geometry.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            } else {
                Text("🎉 Maximum Level Achieved!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(colorForString(currentLevel.color))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // Helper to convert color string to Color
    private func colorForString(_ colorString: String) -> Color {
        switch colorString {
        case "cyan": return .cyan
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "indigo": return .indigo
        case "orange": return .orange
        case "red": return .red
        case "yellow": return .yellow
        case "pink": return .pink
        case "mint": return .mint
        case "teal": return .teal
        default: return .blue
        }
    }
    
    // MARK: - Statistics Grid
    private func statisticsGrid(stats: PlayerStats) -> some View {
        VStack(spacing: 16) {
            Text("Your Performance")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Played",
                    value: "\(stats.gamesPlayed)",
                    icon: "gamecontroller.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Win %",
                    value: "\(stats.winPercentage)%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                StatCard(
                    title: "Current Streak",
                    value: "\(stats.currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Max Streak",
                    value: "\(stats.maxStreak)",
                    icon: "star.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "Total Score",
                    value: "\(stats.totalScore)",
                    icon: "trophy.fill",
                    color: .purple
                )
                
                StatCard(
                    title: "Avg Score",
                    value: "\(stats.averageScore)",
                    icon: "chart.bar.fill",
                    color: .cyan
                )
            }
        }
    }
    
    // MARK: - Guess Distribution
    private func guessDistribution(stats: PlayerStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Guess Distribution")
                .font(.headline)
            
            ForEach(0..<5, id: \.self) { index in
                let count = stats.guessDistribution[index]
                let maxCount = stats.guessDistribution.max() ?? 1
                let percentage = maxCount > 0 ? Double(count) / Double(maxCount) : 0
                
                HStack(spacing: 8) {
                    Text("\(index + 1)")
                        .font(.subheadline)
                        .frame(width: 20)
                    
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(count > 0 ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: max(30, geometry.size.width * percentage))
                            
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(height: 24)
                    
                    Text("\(count)")
                        .font(.subheadline)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("No Statistics Yet")
                .font(.title2)
                .bold()
            
            Text("Play some games to see your stats!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: PlayerStats.self, inMemory: true)
}
