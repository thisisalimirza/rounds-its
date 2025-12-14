//
//  ContentView.swift
//  Stepordle
//
//  Created by Ali Mirza on 12/9/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentCase: MedicalCase?
    @State private var showingGame = false
    @State private var showingStats = false
    @State private var showingAbout = false
    @State private var showingCaseBrowser = false
    @State private var showingFeedback = false
    @Query private var playerStats: [PlayerStats]
    
    private var stats: PlayerStats? {
        playerStats.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo and Title
                    VStack(spacing: 6) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Stepordle")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Master USMLE Step 1")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Combined Streak & Stats Card
                    if let stats = stats {
                        CompactStreakStatsView(stats: stats)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                        .frame(height: 20)
                    
                    // Main Menu Buttons
                    VStack(spacing: 12) {
                        Button {
                            startNewGame()
                        } label: {
                            Label("Play Daily Case", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            startRandomGame()
                        } label: {
                            Label("Random Case", systemImage: "shuffle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.purple)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            showingCaseBrowser = true
                        } label: {
                            Label("Browse Cases", systemImage: "list.bullet.clipboard")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                        .frame(height: 16)
                    
                    // Bottom Action Buttons
                    HStack(spacing: 12) {
                        Button {
                            showingStats = true
                        } label: {
                            Label("Stats", systemImage: "chart.bar.fill")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .foregroundStyle(.primary)
                                .cornerRadius(10)
                        }
                        
                        Button {
                            showingAbout = true
                        } label: {
                            Label("About", systemImage: "info.circle.fill")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .foregroundStyle(.primary)
                                .cornerRadius(10)
                        }
                        
                        Button {
                            showingFeedback = true
                        } label: {
                            Label("Feedback", systemImage: "paperplane.fill")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .foregroundStyle(.primary)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showingGame) {
                if let currentCase = currentCase {
                    GameView(medicalCase: currentCase)
                }
            }
            .sheet(isPresented: $showingStats) {
                StatsView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingCaseBrowser) {
                CaseBrowserView()
            }
            .sheet(isPresented: $showingFeedback) {
                FeedbackSheet()
            }
        }
    }
    
    private func startNewGame() {
        // Use seed based on current date for "daily" case
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        var generator = SeededRandomNumberGenerator(seed: dateComponents.hashValue)
        
        let cases = CaseLibrary.getSampleCases()
        if let randomCase = cases.randomElement(using: &generator) {
            currentCase = randomCase
            showingGame = true
        }
    }
    
    private func startRandomGame() {
        if let randomCase = CaseLibrary.getRandomCase() {
            currentCase = randomCase
            showingGame = true
        }
    }
}

// MARK: - Quick Stat View
struct QuickStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .bold()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Compact Streak & Stats View
struct CompactStreakStatsView: View {
    let stats: PlayerStats
    
    var body: some View {
        VStack(spacing: 10) {
            // Streak Section - Compact
            HStack(spacing: 10) {
                // Fire emoji
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.3), .red.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Text("🔥")
                        .font(.system(size: 30))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(stats.currentStreak)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("Day Streak")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(streakMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Compact Heatmap
            if stats.gamesPlayed > 0 {
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorForDay(dayIndex, stats: stats))
                                .frame(width: 36, height: 36)
                            
                            Text(dayLabel(for: dayIndex))
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Stats Row - Compact
            HStack(spacing: 0) {
                QuickStat(label: "Played", value: "\(stats.gamesPlayed)")
                    .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 30)
                
                QuickStat(label: "Win Rate", value: "\(stats.winPercentage)%")
                    .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 30)
                
                QuickStat(label: "Best", value: "\(stats.maxStreak)")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        )
    }
    
    private var streakMessage: String {
        if stats.currentStreak == 0 {
            return "Start today! 💪"
        } else if stats.currentStreak == 1 {
            return "Great start! 🌟"
        } else if stats.currentStreak < 7 {
            return "On fire! 🚀"
        } else if stats.currentStreak < 30 {
            return "Amazing! 🎯"
        } else {
            return "Legendary! 👑"
        }
    }
    
    private func colorForDay(_ dayIndex: Int, stats: PlayerStats) -> Color {
        let daysAgo = dayIndex
        
        if let lastPlayed = stats.lastPlayedDate {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let lastPlayedDay = calendar.startOfDay(for: lastPlayed)
            let daysSinceLastPlayed = calendar.dateComponents([.day], from: lastPlayedDay, to: today).day ?? 0
            
            if stats.currentStreak > 0 {
                if daysAgo < stats.currentStreak && daysAgo <= daysSinceLastPlayed {
                    let intensity = 1.0 - (Double(daysAgo) * 0.1)
                    return Color.orange.opacity(max(0.6, intensity))
                }
            }
            
            if daysAgo == daysSinceLastPlayed {
                return Color.orange.opacity(0.8)
            }
        }
        
        return Color(.systemGray5)
    }
    
    private func dayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -index, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).prefix(1).uppercased()
    }
}

// MARK: - Gamified Streak Card (Keep for backwards compatibility)
struct StreakCardView: View {
    let stats: PlayerStats
    
    var body: some View {
        CompactStreakStatsView(stats: stats)
    }
}

// MARK: - Stats Card (Keep for backwards compatibility)
struct StatsCardView: View {
    let stats: PlayerStats
    
    var body: some View {
        EmptyView()
    }
}

// MARK: - Activity Heatmap (Keep for backwards compatibility)
struct ActivityHeatmapView: View {
    let stats: PlayerStats
    
    var body: some View {
        EmptyView()
    }
}

// MARK: - Seeded Random Number Generator
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: Int) {
        state = UInt64(truncatingIfNeeded: seed)
    }
    
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PlayerStats.self], inMemory: true)
}

import MessageUI

struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""

    private var mailtoURL: URL? {
        let to = "ali@braskgroup.com"
        let subject = "Stepordle Feedback"
        let body = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(to)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body)"
        return URL(string: urlString)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tell us what you think")
                    .font(.headline)

                TextEditor(text: $message)
                    .frame(height: 180)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))

                Button {
                    if let url = mailtoURL {
                        UIApplication.shared.open(url)
                    }
                    dismiss()
                } label: {
                    Label("Send via Mail", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Feedback")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
