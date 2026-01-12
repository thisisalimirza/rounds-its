//
//  ProFeatureGate.swift
//  Rounds
//
//  Pro subscription feature gating - Clean implementation
//

import SwiftUI
import RevenueCatUI
import Observation

// MARK: - Pro Feature Gate Modifier

/// A view modifier that gates content behind Pro subscription
struct ProFeatureGate: ViewModifier {
    @State private var showingPaywall = false
    
    let action: () -> Void
    
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                if subscriptionManager.hasProAccess() {
                    action()
                } else {
                    showingPaywall = true
                }
            }
            .sheet(isPresented: $showingPaywall) {
                RoundsPaywallView()
            }
    }
}

// MARK: - View Extension

extension View {
    /// Gate a feature behind Pro subscription
    func requiresProSubscription(action: @escaping () -> Void) -> some View {
        modifier(ProFeatureGate(action: action))
    }
    
    /// Conditionally present paywall if user doesn't have entitlement
    func presentPaywallIfNeeded() -> some View {
        self.modifier(PaywallIfNeededModifier())
    }
}

// MARK: - Paywall If Needed Modifier

private struct PaywallIfNeededModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentPaywallIfNeeded(requiredEntitlementIdentifier: SubscriptionManager.proEntitlementID) { _ in
                // Purchase completed
            }
    }
}

// MARK: - Pro Gated Button

/// A button that shows paywall if user doesn't have Pro access
struct ProGatedButton<Label: View>: View {
    @State private var showingPaywall = false
    
    let action: () -> Void
    let label: Label
    let showLockIcon: Bool
    
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    
    init(
        showLockIcon: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.showLockIcon = showLockIcon
        self.action = action
        self.label = label()
    }
    
    var body: some View {
        Button {
            if subscriptionManager.hasProAccess() {
                action()
            } else {
                showingPaywall = true
            }
        } label: {
            HStack {
                label
                
                if showLockIcon && !subscriptionManager.hasProAccess() {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            RoundsPaywallView()
        }
    }
}

// MARK: - Pro Content View

/// A view that shows different content based on Pro subscription status
struct ProContentView<ProContent: View, FreeContent: View>: View {
    let proContent: ProContent
    let freeContent: FreeContent
    
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    
    init(
        @ViewBuilder proContent: () -> ProContent,
        @ViewBuilder freeContent: () -> FreeContent
    ) {
        self.proContent = proContent()
        self.freeContent = freeContent()
    }
    
    var body: some View {
        if subscriptionManager.hasProAccess() {
            proContent
        } else {
            freeContent
        }
    }
}

// MARK: - Game Access Manager

/// Manages daily case limits for free users
@Observable
@MainActor
class GameAccessManager {
    var dailyCasesPlayed: Int = 0
    
    private let freeDailyLimit = 3
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    
    init() {
        // Check if it's a new day and reset counter
        let lastPlayDate = UserDefaults.standard.object(forKey: "lastPlayDate") as? Date ?? Date.distantPast
        let calendar = Calendar.current
        
        if calendar.isDateInToday(lastPlayDate) {
            dailyCasesPlayed = UserDefaults.standard.integer(forKey: "dailyCasesPlayed")
        } else {
            dailyCasesPlayed = 0
        }
    }
    
    /// Check if user can play a case
    func canPlayCase() -> Bool {
        if subscriptionManager.hasProAccess() {
            return true
        }
        return dailyCasesPlayed < freeDailyLimit
    }
    
    /// Get remaining cases for today (nil = unlimited)
    func remainingCases() -> Int? {
        if subscriptionManager.hasProAccess() {
            return nil
        }
        return max(0, freeDailyLimit - dailyCasesPlayed)
    }
    
    /// Increment cases played counter
    func incrementCasePlayed() {
        dailyCasesPlayed += 1
        UserDefaults.standard.set(dailyCasesPlayed, forKey: "dailyCasesPlayed")
        UserDefaults.standard.set(Date(), forKey: "lastPlayDate")
    }
}

// MARK: - Pro Upgrade Banner

/// A promotional banner for upgrading to Pro
struct ProUpgradeBanner: View {
    @State private var showingPaywall = false
    
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    
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
            .padding(.horizontal)
            .sheet(isPresented: $showingPaywall) {
                RoundsPaywallView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Pro Gated Button") {
    VStack(spacing: 20) {
        ProGatedButton {
            print("Pro feature accessed")
        } label: {
            Label("Pro Feature", systemImage: "star.fill")
        }
        
        ProBadge()
    }
    .padding()
}

#Preview("Pro Upgrade Banner") {
    ProUpgradeBanner()
}
