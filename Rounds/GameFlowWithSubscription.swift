//
//  GameFlowWithSubscription.swift
//  Rounds
//
//  Created by Ali Mirza on 1/11/26.
//

import SwiftUI

/*
 
 EXAMPLE: Integrating Subscription Checks into Game Flow
 
 This shows how to add Pro subscription features to your actual game.
 
*/

// MARK: - Example 1: Main Menu with Pro Status

struct MainMenuWithPro: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    @State private var showingGame = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // App Title
                Text("Rounds")
                    .font(.largeTitle)
                    .bold()
                
                // Pro Status Badge
                if subscriptionManager.isProSubscriber {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text(subscriptionManager.subscriptionStatus.displayName)
                            .font(.caption)
                            .bold()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(20)
                }
                
                // Play Button
                Button {
                    showingGame = true
                } label: {
                    Text("Play Daily Case")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Pro Upgrade Prompt (if not Pro)
                if !subscriptionManager.isProSubscriber {
                    Button {
                        showingPaywall = true
                    } label: {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Upgrade to Pro")
                                        .font(.headline)
                                    Text("Unlimited cases • Advanced stats • Offline mode")
                                        .font(.caption)
                                }
                                
                                Spacer()
                            }
                            .padding()
                        }
                        .background(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
}

// MARK: - Example 2: Case Selection with Limits

struct CaseLibraryWithLimits: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var accessManager = GameAccessManager()
    @State private var showingPaywall = false
    @State private var selectedCase: MedicalCase?
    
    let cases: [MedicalCase]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with daily limit
                if let remaining = accessManager.remainingCases() {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.blue)
                        Text("\(remaining) daily cases remaining")
                            .font(.caption)
                        
                        Spacer()
                        
                        Button("Go Pro") {
                            showingPaywall = true
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                }
                
                // Case List
                List {
                    ForEach(Array(cases.enumerated()), id: \.element.id) { index, medicalCase in
                        CaseRowWithLock(
                            medicalCase: medicalCase,
                            isLocked: !canAccessCase(at: index)
                        ) {
                            if canAccessCase(at: index) {
                                selectedCase = medicalCase
                            } else {
                                showingPaywall = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Case Library")
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(item: $selectedCase) { medicalCase in
                // Show game view with selected case
                Text("Game View for \(medicalCase.diagnosis)")
            }
        }
    }
    
    private func canAccessCase(at index: Int) -> Bool {
        // Pro users can access all cases
        if subscriptionManager.hasProAccess() {
            return true
        }
        
        // Free users limited to first 5 cases
        return index < 5
    }
}

struct CaseRowWithLock: View {
    let medicalCase: MedicalCase
    let isLocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicalCase.diagnosis)
                        .font(.headline)
                    
                    Text(medicalCase.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let difficulty = medicalCase.difficulty {
                        Text(difficulty)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                if isLocked {
                    VStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.yellow)
                        ProBadge()
                    }
                }
            }
            .padding(.vertical, 4)
            .opacity(isLocked ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Example 3: Post-Game Stats with Pro Upsell

struct GameCompleteView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    
    let score: Int
    let guesses: Int
    let isCorrect: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Result
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(isCorrect ? .green : .red)
            
            Text(isCorrect ? "Correct!" : "Game Over")
                .font(.largeTitle)
                .bold()
            
            // Stats
            VStack(spacing: 12) {
                StatRow(title: "Score", value: "\(score)")
                StatRow(title: "Guesses", value: "\(guesses)")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Pro Upgrade Prompt
            if !subscriptionManager.isProSubscriber {
                VStack(spacing: 16) {
                    Divider()
                    
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(.blue)
                            Text("Want detailed analytics?")
                                .font(.headline)
                        }
                        
                        Text("Track your progress across categories, view performance trends, and get personalized insights")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                Text("Upgrade to Pro")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            // Continue Button
            Button("Continue") {
                // Dismiss or navigate
            }
            .font(.headline)
            .foregroundStyle(.blue)
        }
        .padding()
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

// MARK: - Example 4: Settings with Subscription Section

struct SettingsViewWithSubscription: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingSubscription = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            List {
                // Subscription Section
                Section {
                    Button {
                        showingSubscription = true
                    } label: {
                        HStack {
                            if subscriptionManager.isProSubscriber {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subscriptionManager.isProSubscriber ? "Manage Subscription" : "Upgrade to Pro")
                                    .font(.headline)
                                
                                if subscriptionManager.isProSubscriber {
                                    Text(subscriptionManager.subscriptionStatus.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Unlock all features")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Subscription")
                }
                
                // App Settings
                Section {
                    Toggle("Notifications", isOn: .constant(true))
                    Toggle("Sound Effects", isOn: .constant(true))
                    Toggle("Haptic Feedback", isOn: .constant(true))
                } header: {
                    Text("App Settings")
                }
                
                // About
                Section {
                    Button {
                        showingAbout = true
                    } label: {
                        HStack {
                            Text("About")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Info")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingSubscription) {
                if subscriptionManager.isProSubscriber {
                    SubscriptionSettingsView()
                } else {
                    PaywallView()
                }
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
}

// MARK: - Example 5: Daily Limit Alert

struct DailyLimitAlert: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaywall = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.badge.exclamationmark.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("Daily Limit Reached")
                .font(.title2)
                .bold()
            
            Text("You've completed your 3 free cases for today. Come back tomorrow or upgrade to Pro for unlimited access!")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button {
                    showingPaywall = true
                } label: {
                    Text("Upgrade to Pro")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button("Maybe Later") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .padding()
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

#Preview("Main Menu") {
    MainMenuWithPro()
}

#Preview("Daily Limit Alert") {
    DailyLimitAlert()
}

#Preview("Game Complete") {
    GameCompleteView(score: 450, guesses: 2, isCorrect: true)
}
