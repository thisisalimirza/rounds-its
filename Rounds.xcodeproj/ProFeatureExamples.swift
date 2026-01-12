//
//  ProFeatureExamples.swift
//  Rounds
//
//  Created by Ali Mirza on 1/11/26.
//

import SwiftUI

// MARK: - Example 1: Limit Cases for Free Users

struct CaseSelectionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    
    let cases: [MedicalCase]
    let freeCaseLimit = 5
    
    var body: some View {
        List {
            ForEach(Array(cases.enumerated()), id: \.element.id) { index, medicalCase in
                let isLocked = !subscriptionManager.hasProAccess() && index >= freeCaseLimit
                
                Button {
                    if isLocked {
                        showingPaywall = true
                    } else {
                        startCase(medicalCase)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(medicalCase.diagnosis)
                                .font(.headline)
                            Text(medicalCase.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                }
                .disabled(isLocked)
                .opacity(isLocked ? 0.6 : 1.0)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    func startCase(_ medicalCase: MedicalCase) {
        // Start the case
    }
}

// MARK: - Example 2: Pro-Only Statistics Tab

struct StatisticsTabView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    
    var body: some View {
        Group {
            if subscriptionManager.hasProAccess() {
                AdvancedStatisticsView()
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("Advanced Statistics")
                        .font(.title2)
                        .bold()
                    
                    Text("Unlock detailed analytics, performance tracking, and category breakdowns")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    ProBadge()
                    
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
                    .padding(.horizontal)
                }
                .sheet(isPresented: $showingPaywall) {
                    PaywallView()
                }
            }
        }
    }
}

struct AdvancedStatisticsView: View {
    var body: some View {
        Text("Advanced Stats Content")
    }
}

// MARK: - Example 3: Daily Case Limit for Free Users

@MainActor
class GameAccessManager: ObservableObject {
    @Published var dailyCasesPlayed: Int {
        didSet {
            UserDefaults.standard.set(dailyCasesPlayed, forKey: "dailyCasesPlayed")
            UserDefaults.standard.set(Date(), forKey: "lastPlayDate")
        }
    }
    
    private let freeDailyLimit = 3
    private let subscriptionManager = SubscriptionManager.shared
    
    init() {
        // Check if it's a new day
        let lastPlayDate = UserDefaults.standard.object(forKey: "lastPlayDate") as? Date ?? Date.distantPast
        let calendar = Calendar.current
        
        if calendar.isDateInToday(lastPlayDate) {
            dailyCasesPlayed = UserDefaults.standard.integer(forKey: "dailyCasesPlayed")
        } else {
            dailyCasesPlayed = 0
        }
    }
    
    func canPlayCase() -> Bool {
        // Pro users can always play
        if subscriptionManager.hasProAccess() {
            return true
        }
        
        // Free users limited to daily cases
        return dailyCasesPlayed < freeDailyLimit
    }
    
    func remainingCases() -> Int? {
        if subscriptionManager.hasProAccess() {
            return nil // Unlimited
        }
        
        return max(0, freeDailyLimit - dailyCasesPlayed)
    }
    
    func incrementCasePlayed() {
        dailyCasesPlayed += 1
    }
}

struct DailyCaseLimitView: View {
    @StateObject private var accessManager = GameAccessManager()
    @State private var showingPaywall = false
    
    var body: some View {
        VStack(spacing: 16) {
            if let remaining = accessManager.remainingCases() {
                Text("\(remaining) cases remaining today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if remaining == 0 {
                    VStack(spacing: 16) {
                        Text("Daily Limit Reached")
                            .font(.headline)
                        
                        Text("Upgrade to Pro for unlimited daily cases")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            showingPaywall = true
                        } label: {
                            Text("Upgrade Now")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            } else {
                HStack {
                    Image(systemName: "infinity")
                    Text("Unlimited Cases")
                        .bold()
                }
                .foregroundStyle(.green)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Example 4: Feature Unlock Banner

struct ProFeaturePromoBanner: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    
    var body: some View {
        if !subscriptionManager.hasProAccess() {
            Button {
                showingPaywall = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upgrade to Pro")
                            .font(.headline)
                        Text("Unlimited cases & advanced features")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(radius: 4)
            }
            .padding()
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
}

// MARK: - Example 5: Settings Integration

struct ProSettingsSection: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingSubscription = false
    
    var body: some View {
        Section {
            Button {
                showingSubscription = true
            } label: {
                HStack {
                    Label(
                        subscriptionManager.isProSubscriber ? "Manage Subscription" : "Upgrade to Pro",
                        systemImage: subscriptionManager.isProSubscriber ? "crown.fill" : "arrow.up.circle.fill"
                    )
                    .foregroundStyle(subscriptionManager.isProSubscriber ? .yellow : .blue)
                    
                    Spacer()
                    
                    if subscriptionManager.isProSubscriber {
                        Text(subscriptionManager.subscriptionStatus.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Subscription")
        } footer: {
            if !subscriptionManager.isProSubscriber {
                Text("Unlock unlimited cases, advanced statistics, and priority support.")
            }
        }
        .sheet(isPresented: $showingSubscription) {
            if subscriptionManager.isProSubscriber {
                SubscriptionSettingsView()
            } else {
                PaywallView()
            }
        }
    }
}

#Preview {
    ProFeaturePromoBanner()
}
