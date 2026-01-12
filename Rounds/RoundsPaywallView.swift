//
//  RoundsPaywallView.swift
//  Rounds
//
//  Created by Ali Mirza on 1/11/26.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

/// A wrapper around RevenueCat's PaywallView with custom callbacks
struct RoundsPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var onPurchaseCompleted: ((CustomerInfo) -> Void)?
    var onRestoreCompleted: ((CustomerInfo) -> Void)?
    var onDismiss: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            PaywallView()
                .onPurchaseCompleted { customerInfo in
                    // Handle successful purchase
                    print("✅ Purchase completed!")
                    onPurchaseCompleted?(customerInfo)
                    
                    // Dismiss after short delay to show success state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
                .onRestoreCompleted { customerInfo in
                    // Handle successful restore
                    print("✅ Restore completed!")
                    onRestoreCompleted?(customerInfo)
                    
                    // Dismiss after short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
                .onPurchaseFailure { error in
                    // Handle purchase failure
                    print("❌ Purchase failed:", error.localizedDescription)
                    
                    // Don't dismiss on failure - let user retry
                }
                .onRestoreFailure { error in
                    // Handle restore failure
                    print("❌ Restore failed:", error.localizedDescription)
                    
                    // Don't dismiss on failure - let user retry
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            onDismiss?()
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

/// A custom-designed paywall if you want to build your own
struct CustomPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var offerings: Offerings?
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedPackage: Package?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.yellow)
                                .shadow(color: .yellow.opacity(0.3), radius: 10)
                            
                            Text("Upgrade to Rounds Pro")
                                .font(.system(size: 32, weight: .bold))
                                .multilineTextAlignment(.center)
                            
                            Text("Unlock unlimited cases and advanced features")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Features
                        VStack(spacing: 20) {
                            FeatureRow(
                                icon: "infinity",
                                title: "Unlimited Cases",
                                description: "Access all medical cases without daily limits"
                            )
                            
                            FeatureRow(
                                icon: "chart.bar.fill",
                                title: "Advanced Statistics",
                                description: "Detailed analytics and performance tracking"
                            )
                            
                            FeatureRow(
                                icon: "sparkles",
                                title: "Priority Support",
                                description: "Get help faster with dedicated support"
                            )
                            
                            FeatureRow(
                                icon: "arrow.triangle.2.circlepath",
                                title: "Regular Updates",
                                description: "New cases and features added regularly"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Packages
                        if let offering = offerings?.current {
                            VStack(spacing: 12) {
                                ForEach(offering.availablePackages, id: \.identifier) { package in
                                    PackageButton(
                                        package: package,
                                        isSelected: selectedPackage?.identifier == package.identifier
                                    ) {
                                        selectedPackage = package
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else if isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                        }
                        
                        // Purchase button
                        if selectedPackage != nil {
                            Button {
                                Task {
                                    await purchasePackage()
                                }
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Continue")
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(16)
                            }
                            .disabled(isLoading)
                            .padding(.horizontal)
                        }
                        
                        // Restore button
                        Button {
                            Task {
                                await restorePurchases()
                            }
                        } label: {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .disabled(isLoading)
                        
                        // Terms & Privacy
                        HStack(spacing: 16) {
                            Link("Terms", destination: URL(string: "https://braskgroup.com/rounds.html")!)
                            Text("•")
                            Link("Privacy", destination: URL(string: "https://braskgroup.com/rounds.html")!)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .task {
            await loadOfferings()
        }
    }
    
    // MARK: - Functions
    
    private func loadOfferings() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            offerings = try await subscriptionManager.fetchOfferings()
            
            // Auto-select yearly package by default
            selectedPackage = offerings?.current?.availablePackages.first { package in
                package.identifier.contains("yearly") || package.packageType == .annual
            } ?? offerings?.current?.availablePackages.first
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func purchasePackage() async {
        guard let package = selectedPackage else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await subscriptionManager.purchase(package: package)
            
            // Success - dismiss
            await MainActor.run {
                dismiss()
            }
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
            
            // If successful and now has pro access, dismiss
            if subscriptionManager.hasProAccess() {
                await MainActor.run {
                    dismiss()
                }
            } else {
                errorMessage = "No purchases found to restore"
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
        HStack(alignment: .top, spacing: 16) {
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
            
            Spacer()
        }
    }
}

// MARK: - Package Button

struct PackageButton: View {
    let package: Package
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(package.storeProduct.localizedTitle)
                            .font(.headline)
                        
                        if isBestValue {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(package.storeProduct.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(package.localizedPriceString)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if let period = getPeriod() {
                        Text(period)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var isBestValue: Bool {
        package.packageType == .annual || package.identifier.contains("yearly")
    }
    
    private func getPeriod() -> String? {
        if package.packageType == .annual {
            return "per year"
        } else if package.packageType == .monthly {
            return "per month"
        } else if package.packageType == .lifetime {
            return "one-time"
        }
        return nil
    }
}

// MARK: - Previews

#Preview("RevenueCat Paywall") {
    RoundsPaywallView()
}

#Preview("Custom Paywall") {
    CustomPaywallView()
}
