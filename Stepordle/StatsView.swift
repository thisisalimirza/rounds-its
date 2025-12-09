//
//  StatsView.swift
//  Stepordle
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
