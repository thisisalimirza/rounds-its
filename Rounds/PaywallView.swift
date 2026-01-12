//
//  PaywallView.swift
//  Rounds
//
//  RevenueCat Paywall wrapper - Clean implementation
//

import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Rounds Paywall View

/// Main paywall view using RevenueCat's built-in PaywallView
struct RoundsPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    
    var onPurchaseCompleted: ((CustomerInfo) -> Void)?
    var onRestoreCompleted: ((CustomerInfo) -> Void)?
    
    init(
        onPurchaseCompleted: ((CustomerInfo) -> Void)? = nil,
        onRestoreCompleted: ((CustomerInfo) -> Void)? = nil
    ) {
        self.onPurchaseCompleted = onPurchaseCompleted
        self.onRestoreCompleted = onRestoreCompleted
    }
    
    var body: some View {
        NavigationStack {
            RevenueCatUI.PaywallView()
                .onPurchaseCompleted { customerInfo in
                    print("✅ Purchase completed")
                    onPurchaseCompleted?(customerInfo)
                    dismiss()
                }
                .onRestoreCompleted { customerInfo in
                    print("✅ Restore completed")
                    onRestoreCompleted?(customerInfo)
                    if SubscriptionManager.shared.hasProAccess() {
                        dismiss()
                    }
                }
                .onPurchaseFailure { error in
                    print("❌ Purchase failed: \(error.localizedDescription)")
                }
                .onRestoreFailure { error in
                    print("❌ Restore failed: \(error.localizedDescription)")
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }
        }
    }
}

// MARK: - Custom Paywall View (Alternative)

/// A custom-built paywall for full UI control
struct CustomRoundsPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var offerings: Offerings?
    @State private var selectedPackage: Package?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingSuccess = false
    
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    featuresSection
                    packagesSection
                    purchaseButton
                    restoreButton
                    legalSection
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
        .alert("Welcome to Rounds Pro! 🎉", isPresented: $showingSuccess) {
            Button("Continue") {
                dismiss()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
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
    }
    
    // MARK: - Features
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            PaywallFeatureRow(
                icon: "infinity",
                title: "Unlimited Cases",
                description: "Access all medical cases without limits"
            )
            
            PaywallFeatureRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Advanced Statistics",
                description: "Track your progress with detailed analytics"
            )
            
            PaywallFeatureRow(
                icon: "star.fill",
                title: "Priority Support",
                description: "Get help faster with priority support"
            )
            
            PaywallFeatureRow(
                icon: "bell.badge.fill",
                title: "Daily Reminders",
                description: "Never miss your daily case"
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Packages
    
    private var packagesSection: some View {
        Group {
            if let offering = offerings?.current {
                VStack(spacing: 12) {
                    ForEach(offering.availablePackages, id: \.identifier) { package in
                        PaywallPackageCard(
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
        }
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
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
    }
    
    // MARK: - Restore Button
    
    private var restoreButton: some View {
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
    }
    
    // MARK: - Legal
    
    private var legalSection: some View {
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
    
    // MARK: - Functions
    
    private func loadOfferings() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            offerings = try await subscriptionManager.fetchOfferings()
            // Auto-select yearly by default
            if let offering = offerings?.current {
                selectedPackage = offering.availablePackages.first {
                    $0.identifier.contains("yearly") || $0.packageType == .annual
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
            _ = try await subscriptionManager.restorePurchases()
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

struct PaywallFeatureRow: View {
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

struct PaywallPackageCard: View {
    let package: Package
    let isSelected: Bool
    let onTap: () -> Void
    
    private var isPopular: Bool {
        package.identifier.contains("yearly") || package.packageType == .annual
    }
    
    private var periodDescription: String {
        guard let period = package.storeProduct.subscriptionPeriod else {
            return package.identifier.contains("lifetime") ? "One-time purchase" : ""
        }
        
        switch period.unit {
        case .day:
            return period.value == 1 ? "Billed daily" : "Billed every \(period.value) days"
        case .week:
            return period.value == 1 ? "Billed weekly" : "Billed every \(period.value) weeks"
        case .month:
            return period.value == 1 ? "Billed monthly" : "Billed every \(period.value) months"
        case .year:
            return period.value == 1 ? "Billed annually" : "Billed every \(period.value) years"
        @unknown default:
            return ""
        }
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
                        
                        if isPopular {
                            Text("Save 40%")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                if !periodDescription.isEmpty {
                    Text(periodDescription)
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
}

// MARK: - Previews

#Preview("RevenueCat Paywall") {
    RoundsPaywallView()
}

#Preview("Custom Paywall") {
    CustomRoundsPaywallView()
}
