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
    @State private var notificationsEnabled = false
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
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Stepordle")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Master USMLE Step 1")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let stats = stats {
                        HStack(spacing: 12) {
                            Image(systemName: stats.currentStreak > 0 ? "flame.fill" : "flame")
                                .foregroundStyle(stats.currentStreak > 0 ? .orange : .gray)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stats.currentStreak > 0 ? "Streak: \(stats.currentStreak)" : "Start your streak")
                                    .font(.headline)
                                Text(stats.currentStreak > 0 ? "Keep it going — play today to maintain your streak." : "Play today to begin your streak.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(action: {
                                if notificationsEnabled {
                                    NotificationManager.cancelAll()
                                    notificationsEnabled = false
                                } else {
                                    NotificationManager.requestAuthorization { granted in
                                        if granted {
                                            NotificationManager.scheduleDailyReminder()
                                            notificationsEnabled = true
                                        }
                                    }
                                }
                            }) {
                                Label(notificationsEnabled ? "On" : "Remind Me", systemImage: notificationsEnabled ? "bell.fill" : "bell")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 1)
                    }
                    
                    // Stats Summary (if available)
                    if let stats = stats, stats.gamesPlayed > 0 {
                        HStack(spacing: 24) {
                            QuickStat(label: "Played", value: "\(stats.gamesPlayed)")
                            QuickStat(label: "Win Rate", value: "\(stats.winPercentage)%")
                            QuickStat(label: "Streak", value: "\(stats.currentStreak)")
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 2)
                    }
                    
                    Spacer()
                    
                    // Main Menu Buttons
                    VStack(spacing: 16) {
                        Button {
                            startNewGame()
                        } label: {
                            Label("Play Daily Case", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
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
                                .padding()
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
                                .padding()
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        
                        HStack(spacing: 12) {
                            Button {
                                showingStats = true
                            } label: {
                                Label("Stats", systemImage: "chart.bar.fill")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundStyle(.primary)
                                    .cornerRadius(12)
                            }
                            
                            Button {
                                showingAbout = true
                            } label: {
                                Label("About", systemImage: "info.circle.fill")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundStyle(.primary)
                                    .cornerRadius(12)
                            }
                            
                            Button {
                                showingFeedback = true
                            } label: {
                                Label("Feedback", systemImage: "paperplane.fill")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundStyle(.primary)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
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
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .bold()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
        let to = "support@stepordle.app"
        let subject = "Stepordle Feedback"
        let body = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\\(to)?subject=\\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? \"\")&body=\\(body)"
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
