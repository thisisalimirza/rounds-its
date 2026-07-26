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

/// Main paywall view using RevenueCat's built-in PaywallView.
/// Automatically shows the one-time retention offer when dismissed without purchasing.
///
/// **This is the paywall that ships.** Every Pro gate in the app presents this
/// type. Its layout, copy, and — importantly — its Terms of Use and Privacy
/// Policy links are configured in the **RevenueCat dashboard** paywall editor,
/// not in this file. Editing `CustomRoundsPaywallView` below has no effect on
/// what users see.
///
/// App Review (Guideline 3.1.2) checks those dashboard-configured links. If a
/// 3.1.2 rejection cites missing/duplicated legal links on the paywall, fix it
/// in RevenueCat → Paywalls, then re-publish the paywall. Keep the URLs in sync
/// with `AppLinks.termsOfUse` / `AppLinks.privacyPolicy`.
struct RoundsPaywallView: View {
    @Environment(\.dismiss) private var dismiss

    // Tracks whether this session ended in a purchase/restore — gates retention offer
    @State private var completedPurchase = false
    // Persists across app launches — retention offer is shown at most once ever
    @AppStorage("hasSeenRetentionOffer") private var hasSeenRetentionOffer: Bool = false
    @State private var showingRetentionOffer = false

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
                .onAppear {
                    AnalyticsManager.shared.trackPaywallViewed(source: "app")
                }
                .onPurchaseCompleted { customerInfo in
                    print("✅ Purchase completed")
                    completedPurchase = true
                    onPurchaseCompleted?(customerInfo)
                    dismiss()
                }
                .onRestoreCompleted { customerInfo in
                    print("✅ Restore completed")
                    onRestoreCompleted?(customerInfo)
                    if SubscriptionManager.shared.hasProAccess() {
                        completedPurchase = true
                        dismiss()
                    } else {
                        // RevenueCat's internal restore misses Apple promo/offer code redemptions.
                        // syncPurchases uploads the current receipt fresh, which catches them.
                        Task {
                            try? await SubscriptionManager.shared.syncPurchases()
                            if SubscriptionManager.shared.hasProAccess() {
                                completedPurchase = true
                                dismiss()
                            }
                        }
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
                            handleDismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }
        }
        .sheet(isPresented: $showingRetentionOffer) {
            RetentionOfferView()
        }
    }

    // MARK: - Dismiss handling

    /// Intercepts the X button. If the user never purchased and hasn't seen
    /// the retention offer yet, show it instead of dismissing immediately.
    private func handleDismiss() {
        let shouldShowRetention = !completedPurchase
            && !hasSeenRetentionOffer
            && !SubscriptionManager.shared.isProUser

        if shouldShowRetention {
            hasSeenRetentionOffer = true   // mark immediately so it never shows again
            showingRetentionOffer = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Custom Paywall View (Alternative)

/// A custom-built paywall for full UI control.
///
/// **Not currently shipped.** Nothing presents this type except the `#Preview`
/// at the bottom of this file — `RoundsPaywallView` is what every Pro gate uses.
/// It is kept as a working fallback in case we ever need to drop RevenueCatUI,
/// so its legal copy is maintained to the same 3.1.2 standard.
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
    
    /// Guideline 3.1.2 requires the subscription's title, length, and price per
    /// period to be visible next to the purchase control, alongside functional
    /// Terms of Use (EULA) and Privacy Policy links.
    private var legalSection: some View {
        VStack(spacing: 8) {
            Text(subscriptionDisclosure)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Terms of Use (EULA)", destination: AppLinks.terms)
                Text("•")
                Link("Privacy Policy", destination: AppLinks.privacy)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.bottom)
    }

    /// Human-readable "<title> — <price>/<period>, auto-renews" line for the
    /// currently selected package. Falls back to generic copy before offerings
    /// have loaded or when nothing is selected yet.
    private var subscriptionDisclosure: String {
        guard let package = selectedPackage else {
            return "Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in your App Store account settings."
        }

        let price = package.storeProduct.localizedPriceString

        switch package.packageType {
        case .lifetime:
            return "Rounds Pro Lifetime — \(price), one-time purchase. Not a subscription; nothing renews."
        default:
            let period = Self.periodDescription(for: package.packageType)
            return "Rounds Pro \(period.title) — \(price) per \(period.unit). Renews automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in your App Store account settings."
        }
    }

    /// Maps a RevenueCat package type to display copy. Kept exhaustive-by-default
    /// so a new package type degrades to neutral wording rather than lying about
    /// the billing period.
    private static func periodDescription(for type: PackageType) -> (title: String, unit: String) {
        switch type {
        case .annual:     return ("Yearly", "year")
        case .sixMonth:   return ("6-Month", "6 months")
        case .threeMonth: return ("Quarterly", "3 months")
        case .twoMonth:   return ("2-Month", "2 months")
        case .monthly:    return ("Monthly", "month")
        case .weekly:     return ("Weekly", "week")
        default:          return ("Subscription", "billing period")
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

            // Fall back to syncPurchases for Apple promo/offer code redemptions.
            if !subscriptionManager.hasProAccess() {
                _ = try await subscriptionManager.syncPurchases()
            }

            if subscriptionManager.hasProAccess() {
                showingSuccess = true
            } else {
                errorMessage = "No previous purchases found. If you redeemed a promo code, make sure it was applied in the App Store and try again."
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
