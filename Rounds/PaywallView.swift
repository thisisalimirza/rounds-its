//
//  PaywallView.swift
//  Rounds
//
//  Created by Ali Mirza on 1/11/26.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        PaywallView()
            .onRestoreCompleted { customerInfo in
                // Handle successful restore
                print("Restore completed: \(customerInfo)")
                if subscriptionManager.hasProAccess() {
                    dismiss()
                }
            }
            .onPurchaseCompleted { customerInfo in
                // Handle successful purchase
                print("Purchase completed: \(customerInfo)")
                dismiss()
            }
            .onPurchaseFailure { error in
                // Handle purchase failure
                print("Purchase failed: \(error.localizedDescription)")
            }
            .onPurchaseCancelled {
                // Handle cancelled purchase
                print("Purchase cancelled")
            }
            .paywallFooter {
                // Custom footer with dismiss button
                Button("Maybe Later") {
                    dismiss()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
            }
    }
}

// MARK: - Custom Paywall (Alternative)

/// A custom-built paywall if you want full control over the UI
struct CustomPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var offerings: Offerings?
    @State private var isLoading = false
    @State private var selectedPackage: Package?
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Upgrade to Rounds Pro")
                            .font(.largeTitle)
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        Text("Unlock unlimited cases and advanced features")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "infinity",
                            title: "Unlimited Cases",
                            description: "Access all medical cases without limits"
                        )
                        
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Advanced Statistics",
                            description: "Track your progress with detailed analytics"
                        )
                        
                        FeatureRow(
                            icon: "star.fill",
                            title: "Priority Support",
                            description: "Get help faster with priority support"
                        )
                        
                        FeatureRow(
                            icon: "arrow.down.circle.fill",
                            title: "Offline Access",
                            description: "Download cases to study offline"
                        )
                        
                        FeatureRow(
                            icon: "bell.badge.fill",
                            title: "Daily Notifications",
                            description: "Never miss your daily case"
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Packages
                    if let offering = offerings?.current {
                        VStack(spacing: 12) {
                            ForEach(offering.availablePackages, id: \.identifier) { package in
                                PackageCard(
                                    package: package,
                                    isSelected: selectedPackage?.identifier == package.identifier
                                ) {
                                    selectedPackage = package
                                }
                            }
                        }
                    } else if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    }
                    
                    // Purchase Button
                    Button {
                        Task {
                            await purchaseSelectedPackage()
                        }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Continue")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedPackage == nil ? Color.gray : Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(selectedPackage == nil || isLoading)
                    
                    // Restore Button
                    Button {
                        Task {
                            await restorePurchases()
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    .disabled(isLoading)
                    
                    // Legal
                    VStack(spacing: 8) {
                        Text("Subscription automatically renews unless cancelled")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            Link("Terms", destination: URL(string: "https://braskgroup.com/rounds.html")!)
                            Text("•")
                            Link("Privacy", destination: URL(string: "https://braskgroup.com/rounds.html")!)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.bottom)
                }
                .padding()
            }
            .navigationTitle("Go Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .disabled(isLoading)
                }
            }
        }
        .task {
            await loadOfferings()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .alert("Success!", isPresented: $showingSuccess) {
            Button("Continue") {
                dismiss()
            }
        } message: {
            Text("Welcome to Rounds Pro! 🎉")
        }
    }
    
    // MARK: - Functions
    
    private func loadOfferings() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            offerings = try await subscriptionManager.fetchOfferings()
            // Auto-select yearly by default
            if let offering = offerings?.current {
                selectedPackage = offering.availablePackages.first {
                    $0.identifier.contains("yearly")
                } ?? offering.availablePackages.first
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func purchaseSelectedPackage() async {
        guard let package = selectedPackage else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await subscriptionManager.purchase(package: package)
            showingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let info = try await subscriptionManager.restorePurchases()
            if subscriptionManager.hasProAccess() {
                showingSuccess = true
            } else {
                errorMessage = "No previous purchases found"
                showingError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Package Card

struct PackageCard: View {
    let package: Package
    let isSelected: Bool
    let onTap: () -> Void
    
    private var isPopular: Bool {
        package.identifier.contains("yearly")
    }
    
    private var savingsText: String? {
        guard let monthlyPrice = package.storeProduct.subscriptionPeriod?.unit == .month else {
            return nil
        }
        
        if package.identifier.contains("yearly") {
            return "Save 40%"
        } else if package.identifier.contains("lifetime") {
            return "Best Value"
        }
        
        return nil
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(package.storeProduct.localizedTitle)
                                .font(.headline)
                            
                            if isPopular {
                                Text("POPULAR")
                                    .font(.caption2)
                                    .bold()
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(package.storeProduct.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(package.localizedPriceString)
                            .font(.title3)
                            .bold()
                        
                        if let savings = savingsText {
                            Text(savings)
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                if let period = package.storeProduct.subscriptionPeriod {
                    Text(periodDescription(period))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private func periodDescription(_ period: SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            return "Billed every \(period.value) day(s)"
        case .week:
            return "Billed every \(period.value) week(s)"
        case .month:
            return period.value == 1 ? "Billed monthly" : "Billed every \(period.value) months"
        case .year:
            return period.value == 1 ? "Billed annually" : "Billed every \(period.value) years"
        @unknown default:
            return "Subscription"
        }
    }
}

#Preview {
    CustomPaywallView()
}
