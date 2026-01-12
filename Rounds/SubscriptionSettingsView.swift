//
//  SubscriptionSettingsView.swift
//  Rounds
//
//  Subscription management with RevenueCat Customer Center
//

import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Subscription Settings View

/// View for managing subscription using RevenueCat Customer Center
struct SubscriptionSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            CustomerCenterView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Custom Subscription Settings View

/// Alternative custom subscription management view
struct CustomSubscriptionSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var showingPaywall = false
    
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    
    var body: some View {
        NavigationStack {
            List {
                currentPlanSection
                
                if !subscriptionManager.isProSubscriber {
                    upgradeSection
                }
                
                managementSection
                
                if subscriptionManager.isProSubscriber {
                    subscriptionDetailsSection
                }
                
                supportSection
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .sheet(isPresented: $showingPaywall) {
                RoundsPaywallView()
            }
            .refreshable {
                await subscriptionManager.refreshCustomerInfo()
            }
        }
    }
    
    // MARK: - Current Plan Section
    
    private var currentPlanSection: some View {
        Section {
            HStack {
                Image(systemName: subscriptionManager.isProSubscriber ? "crown.fill" : "person.crop.circle")
                    .font(.title)
                    .foregroundStyle(subscriptionManager.isProSubscriber ? .yellow : .secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscriptionManager.subscriptionStatus.displayName)
                        .font(.headline)
                    
                    if subscriptionManager.isProSubscriber {
                        statusText
                    } else {
                        Text("Limited access")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        } header: {
            Text("Current Plan")
        }
    }
    
    private var statusText: some View {
        Group {
            if subscriptionManager.subscriptionStatus == .lifetime {
                Text("Lifetime Access")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else if let expirationDate = subscriptionManager.getExpirationDate() {
                if subscriptionManager.willRenew() {
                    Text("Renews \(expirationDate, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Expires \(expirationDate, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
    
    // MARK: - Upgrade Section
    
    private var upgradeSection: some View {
        Section {
            Button {
                showingPaywall = true
            } label: {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Upgrade to Pro")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Upgrade")
        } footer: {
            Text("Unlock unlimited cases, advanced statistics, and priority support.")
        }
    }
    
    // MARK: - Management Section
    
    private var managementSection: some View {
        Section {
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Restore Purchases")
                    Spacer()
                    if isLoading {
                        ProgressView()
                    }
                }
            }
            .disabled(isLoading)
            
            if subscriptionManager.isProSubscriber && subscriptionManager.willRenew() {
                Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.blue)
                        Text("Manage in App Store")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Management")
        } footer: {
            Text("Restore purchases you've made on other devices.")
        }
    }
    
    // MARK: - Subscription Details Section
    
    @ViewBuilder
    private var subscriptionDetailsSection: some View {
        if let customerInfo = subscriptionManager.customerInfo,
           let entitlement = customerInfo.entitlements[SubscriptionManager.proEntitlementID] {
            Section {
                SubscriptionDetailRow(title: "Status", value: entitlement.isActive ? "Active" : "Inactive")
                
                SubscriptionDetailRow(title: "Product", value: entitlement.productIdentifier)
                
                if let purchaseDate = entitlement.originalPurchaseDate {
                    SubscriptionDetailRow(title: "Purchase Date", value: purchaseDate.formatted(date: .long, time: .omitted))
                }
                
                if let expirationDate = entitlement.expirationDate {
                    SubscriptionDetailRow(title: "Expiration", value: expirationDate.formatted(date: .long, time: .omitted))
                }
                
                SubscriptionDetailRow(title: "Auto-Renew", value: entitlement.willRenew ? "On" : "Off")
                
                if subscriptionManager.hasBillingIssue() {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Billing issue detected")
                            .foregroundStyle(.orange)
                    }
                }
            } header: {
                Text("Details")
            }
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        Section {
            Link(destination: URL(string: "https://braskgroup.com/rounds.html")!) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Subscription FAQ")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Link(destination: URL(string: "mailto:support@braskgroup.com?subject=Rounds%20Subscription%20Support")!) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.blue)
                    Text("Contact Support")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Support")
        }
    }
    
    // MARK: - Functions
    
    private func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await subscriptionManager.restorePurchases()
            if !subscriptionManager.hasProAccess() {
                errorMessage = "No previous purchases found"
                showingError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Detail Row

struct SubscriptionDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}

// MARK: - Previews

#Preview("Customer Center") {
    SubscriptionSettingsView()
}

#Preview("Custom Settings") {
    CustomSubscriptionSettingsView()
}
