//
//  SubscriptionSettingsView.swift
//  Rounds
//
//  Created by Ali Mirza on 1/11/26.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

/// View for managing subscription settings with RevenueCat Customer Center
struct SubscriptionSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
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

/// Custom subscription management view (alternative to Customer Center)
struct CustomSubscriptionSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var showingCancelAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // Current Plan Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: subscriptionManager.isProSubscriber ? "crown.fill" : "person.crop.circle")
                                .font(.title)
                                .foregroundStyle(subscriptionManager.isProSubscriber ? .yellow : .secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(subscriptionManager.subscriptionStatus.displayName)
                                    .font(.headline)
                                
                                if subscriptionManager.isProSubscriber {
                                    if let expirationDate = subscriptionManager.getExpirationDate() {
                                        if subscriptionManager.willRenew() {
                                            Text("Renews \(expirationDate, style: .date)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("Expires \(expirationDate, style: .date)")
                                                .font(.caption)
                                                .foregroundStyle(.orange)
                                        }
                                    } else if subscriptionManager.subscriptionStatus == .lifetime {
                                        Text("Lifetime Access")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                } else {
                                    Text("Limited access")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Current Plan")
                }
                
                // Subscription Actions
                if !subscriptionManager.isProSubscriber {
                    Section {
                        Button {
                            // Show paywall
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
                
                // Management Section
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
                                Text("Manage Subscription")
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
                    Text("Restore purchases you've made on other devices or with a different Apple ID.")
                }
                
                // Subscription Details
                if subscriptionManager.isProSubscriber,
                   let customerInfo = subscriptionManager.customerInfo,
                   let entitlement = customerInfo.entitlements["Rounds Pro"] {
                    Section {
                        DetailRow(title: "Status", value: entitlement.isActive ? "Active" : "Inactive")
                        
                        if let productId = entitlement.productIdentifier {
                            DetailRow(title: "Product", value: productId)
                        }
                        
                        if let purchaseDate = entitlement.originalPurchaseDate {
                            DetailRow(title: "Purchase Date", value: purchaseDate.formatted(date: .long, time: .omitted))
                        }
                        
                        if let expirationDate = entitlement.expirationDate {
                            DetailRow(title: "Expiration Date", value: expirationDate.formatted(date: .long, time: .omitted))
                        }
                        
                        DetailRow(
                            title: "Auto-Renew",
                            value: entitlement.willRenew ? "On" : "Off"
                        )
                    } header: {
                        Text("Subscription Details")
                    }
                }
                
                // Support Section
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
            .refreshable {
                await refreshSubscription()
            }
        }
    }
    
    // MARK: - Functions
    
    private func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await subscriptionManager.restorePurchases()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func refreshSubscription() async {
        await subscriptionManager.refreshCustomerInfo()
    }
}

// MARK: - Detail Row

struct DetailRow: View {
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

#Preview("Customer Center") {
    SubscriptionSettingsView()
}

#Preview("Custom Settings") {
    CustomSubscriptionSettingsView()
}
