//
//  RevenueCatTestingExamples.swift
//  Rounds
//
//  Created by Ali Mirza on 1/11/26.
//

import SwiftUI
import RevenueCat

/// Example views demonstrating how to test RevenueCat integration
struct RevenueCatTestingView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var customerInfo: CustomerInfo?
    @State private var offerings: Offerings?
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationStack {
            List {
                // User Status Section
                Section {
                    HStack {
                        Text("User ID:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Purchases.shared.appUserID)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    
                    HStack {
                        Text("Is Anonymous:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Purchases.shared.isAnonymous ? "Yes" : "No")
                    }
                    
                    HStack {
                        Text("Pro Status:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack {
                            Circle()
                                .fill(subscriptionManager.hasProAccess() ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(subscriptionManager.hasProAccess() ? "Active" : "Inactive")
                        }
                    }
                } header: {
                    Text("User Status")
                }
                
                // Entitlements Section
                Section {
                    if let info = customerInfo {
                        if info.entitlements.active.isEmpty {
                            Text("No active entitlements")
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            ForEach(Array(info.entitlements.active.keys), id: \.self) { key in
                                if let entitlement = info.entitlements[key] {
                                    EntitlementRow(entitlement: entitlement)
                                }
                            }
                        }
                    } else {
                        Text("Loading...")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Active Entitlements")
                }
                
                // Offerings Section
                Section {
                    if let offerings = offerings {
                        if let current = offerings.current {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Offering: \(current.identifier)")
                                    .font(.headline)
                                
                                ForEach(current.availablePackages, id: \.identifier) { package in
                                    PackageRow(package: package)
                                }
                            }
                        } else {
                            Text("No current offering")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Loading...")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Offerings")
                }
                
                // Actions Section
                Section {
                    Button {
                        showingPaywall = true
                    } label: {
                        Label("Show Paywall", systemImage: "creditcard")
                    }
                    
                    Button {
                        Task {
                            await refreshData()
                        }
                    } label: {
                        Label("Refresh Customer Info", systemImage: "arrow.clockwise")
                    }
                    
                    Button {
                        Task {
                            await testRestore()
                        }
                    } label: {
                        Label("Test Restore", systemImage: "arrow.counterclockwise")
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await resetUser()
                        }
                    } label: {
                        Label("Reset User (Logout)", systemImage: "person.crop.circle.badge.xmark")
                    }
                } header: {
                    Text("Test Actions")
                }
                
                // Debug Info Section
                Section {
                    if let info = customerInfo {
                        NavigationLink {
                            CustomerInfoDebugView(customerInfo: info)
                        } label: {
                            Label("View Full Customer Info", systemImage: "info.circle")
                        }
                    }
                } header: {
                    Text("Debug")
                }
            }
            .navigationTitle("RevenueCat Testing")
            .sheet(isPresented: $showingPaywall) {
                RoundsPaywallView(
                    onPurchaseCompleted: { info in
                        print("✅ Purchase completed!")
                        customerInfo = info
                    },
                    onRestoreCompleted: { info in
                        print("✅ Restore completed!")
                        customerInfo = info
                    }
                )
            }
        }
        .task {
            await loadData()
        }
    }
    
    // MARK: - Functions
    
    private func loadData() async {
        await refreshData()
        await loadOfferings()
    }
    
    private func refreshData() async {
        await subscriptionManager.refreshCustomerInfo()
        customerInfo = subscriptionManager.customerInfo
    }
    
    private func loadOfferings() async {
        do {
            offerings = try await subscriptionManager.fetchOfferings()
        } catch {
            print("Error loading offerings:", error)
        }
    }
    
    private func testRestore() async {
        do {
            let info = try await subscriptionManager.restorePurchases()
            customerInfo = info
            print("✅ Restore successful")
        } catch {
            print("❌ Restore failed:", error)
        }
    }
    
    private func resetUser() async {
        do {
            let info = try await Purchases.shared.logOut()
            customerInfo = info
            await refreshData()
            print("✅ User logged out")
        } catch {
            print("❌ Logout failed:", error)
        }
    }
}

// MARK: - Entitlement Row

struct EntitlementRow: View {
    let entitlement: EntitlementInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entitlement.identifier)
                    .font(.headline)
                
                Spacer()
                
                if entitlement.isActive {
                    Text("ACTIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(4)
                }
            }
            
            Group {
                if let productId = entitlement.productIdentifier {
                    DetailText(label: "Product ID", value: productId)
                }
                
                if let purchaseDate = entitlement.latestPurchaseDate {
                    DetailText(label: "Purchase Date", value: purchaseDate.formatted())
                }
                
                if let expirationDate = entitlement.expirationDate {
                    DetailText(label: "Expires", value: expirationDate.formatted())
                } else {
                    DetailText(label: "Expires", value: "Never (Lifetime)")
                }
                
                DetailText(
                    label: "Will Renew",
                    value: entitlement.willRenew ? "Yes" : "No"
                )
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Package Row

struct PackageRow: View {
    let package: Package
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(package.storeProduct.localizedTitle)
                    .font(.subheadline)
                Text(package.identifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(package.localizedPriceString)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail Text

struct DetailText: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundStyle(.secondary)
            Text(value)
        }
    }
}

// MARK: - Customer Info Debug View

struct CustomerInfoDebugView: View {
    let customerInfo: CustomerInfo
    
    var body: some View {
        List {
            Section("Basic Info") {
                DetailRow(title: "User ID", value: customerInfo.originalAppUserId)
                DetailRow(title: "Request Date", value: customerInfo.requestDate.formatted())
                DetailRow(title: "Original App User ID", value: customerInfo.originalAppUserId)
            }
            
            Section("Active Subscriptions") {
                if customerInfo.activeSubscriptions.isEmpty {
                    Text("None")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(customerInfo.activeSubscriptions), id: \.self) { subscription in
                        Text(subscription)
                    }
                }
            }
            
            Section("All Purchased Product IDs") {
                if customerInfo.allPurchasedProductIdentifiers.isEmpty {
                    Text("None")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(customerInfo.allPurchasedProductIdentifiers), id: \.self) { productId in
                        Text(productId)
                    }
                }
            }
            
            Section("Non-Subscription Purchases") {
                if customerInfo.nonSubscriptionTransactions.isEmpty {
                    Text("None")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(customerInfo.nonSubscriptionTransactions, id: \.transactionIdentifier) { transaction in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(transaction.productIdentifier)
                                .font(.headline)
                            Text("Purchased: \(transaction.purchaseDate.formatted())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("All Entitlements") {
                ForEach(Array(customerInfo.entitlements.all.keys), id: \.self) { key in
                    if let entitlement = customerInfo.entitlements[key] {
                        NavigationLink {
                            EntitlementDetailView(entitlement: entitlement)
                        } label: {
                            HStack {
                                Text(entitlement.identifier)
                                Spacer()
                                if entitlement.isActive {
                                    Text("Active")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Customer Info Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Entitlement Detail View

struct EntitlementDetailView: View {
    let entitlement: EntitlementInfo
    
    var body: some View {
        List {
            Section("Status") {
                DetailRow(title: "Identifier", value: entitlement.identifier)
                DetailRow(title: "Is Active", value: entitlement.isActive ? "Yes" : "No")
                DetailRow(title: "Will Renew", value: entitlement.willRenew ? "Yes" : "No")
            }
            
            Section("Product") {
                if let productId = entitlement.productIdentifier {
                    DetailRow(title: "Product ID", value: productId)
                }
                if let planId = entitlement.productPlanIdentifier {
                    DetailRow(title: "Plan ID", value: planId)
                }
            }
            
            Section("Dates") {
                if let purchaseDate = entitlement.latestPurchaseDate {
                    DetailRow(title: "Purchase Date", value: purchaseDate.formatted(date: .long, time: .shortened))
                }
                
                if let originalPurchaseDate = entitlement.originalPurchaseDate {
                    DetailRow(title: "Original Purchase", value: originalPurchaseDate.formatted(date: .long, time: .shortened))
                }
                
                if let expirationDate = entitlement.expirationDate {
                    DetailRow(title: "Expiration Date", value: expirationDate.formatted(date: .long, time: .shortened))
                } else {
                    DetailRow(title: "Expiration Date", value: "Never (Lifetime)")
                }
            }
            
            Section("Billing") {
                DetailRow(title: "Is Sandbox", value: entitlement.isSandbox ? "Yes" : "No")
                DetailRow(title: "Store", value: entitlement.store.rawValue)
                DetailRow(title: "Period Type", value: entitlement.periodType.rawValue)
            }
            
            if let unsubscribeDate = entitlement.unsubscribeDetectedAt {
                Section("Cancellation") {
                    DetailRow(title: "Unsubscribed At", value: unsubscribeDate.formatted(date: .long, time: .shortened))
                }
            }
            
            if let billingIssueDate = entitlement.billingIssueDetectedAt {
                Section("Issues") {
                    DetailRow(title: "Billing Issue Detected", value: billingIssueDate.formatted(date: .long, time: .shortened))
                }
            }
        }
        .navigationTitle("Entitlement Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

#Preview {
    RevenueCatTestingView()
}
