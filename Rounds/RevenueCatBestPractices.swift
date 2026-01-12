//
//  RevenueCatBestPractices.swift
//  Rounds
//
//  Created by Ali Mirza on 1/11/26.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Best Practice #1: Environment-Based Configuration

/// Configure different API keys for debug and release builds
struct RevenueCatConfiguration {
    static var apiKey: String {
        #if DEBUG
        return "test_dDeBAeUiVPFXqkYLYBpRccJBmWC"
        #else
        return "appl_xxxxxxxxxxxxxxxxxxxxxxxxx" // Replace with production key
        #endif
    }
    
    static func configure() {
        Purchases.configure(withAPIKey: apiKey)
        
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .error
        #endif
    }
}

// MARK: - Best Practice #2: Graceful Error Handling

struct PurchaseErrorHandler {
    static func handlePurchaseError(_ error: Error, in view: some View) -> Alert {
        let nsError = error as NSError
        let errorCode = PurchasesErrorCode(rawValue: nsError.code)
        
        let (title, message) = getErrorMessage(for: errorCode)
        
        return Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(Text("OK"))
        )
    }
    
    private static func getErrorMessage(for errorCode: PurchasesErrorCode?) -> (String, String) {
        switch errorCode {
        case .purchaseCancelledError:
            return ("Purchase Cancelled", "You cancelled the purchase. You can try again anytime.")
            
        case .storeProblemError:
            return ("Store Error", "There was a problem connecting to the App Store. Please try again later.")
            
        case .purchaseNotAllowedError:
            return ("Purchase Not Allowed", "Purchases are not allowed on this device. Check your settings.")
            
        case .purchaseInvalidError:
            return ("Invalid Purchase", "This purchase is not available. Please try another option.")
            
        case .networkError:
            return ("Network Error", "Please check your internet connection and try again.")
            
        case .receiptAlreadyInUseError:
            return ("Already Purchased", "This subscription is already active on another account.")
            
        default:
            return ("Error", "An unexpected error occurred. Please try again.")
        }
    }
}

// MARK: - Best Practice #3: Analytics Integration

class PurchaseAnalytics {
    static func trackPaywallPresented(from source: String) {
        // Track paywall presentation
        #if DEBUG
        print("📊 Analytics: Paywall presented from \(source)")
        #endif
        
        // Integrate with your analytics service:
        // AnalyticsManager.shared.track("paywall_presented", properties: ["source": source])
    }
    
    static func trackPurchaseStarted(package: Package) {
        #if DEBUG
        print("📊 Analytics: Purchase started for \(package.identifier)")
        #endif
        
        // AnalyticsManager.shared.track("purchase_started", properties: [
        //     "package": package.identifier,
        //     "price": package.storeProduct.price
        // ])
    }
    
    static func trackPurchaseCompleted(package: Package, customerInfo: CustomerInfo) {
        #if DEBUG
        print("📊 Analytics: Purchase completed for \(package.identifier)")
        #endif
        
        // AnalyticsManager.shared.track("purchase_completed", properties: [
        //     "package": package.identifier,
        //     "price": package.storeProduct.price,
        //     "is_trial": customerInfo.entitlements.active.values.first?.periodType == .trial
        // ])
    }
    
    static func trackPurchaseFailed(package: Package, error: Error) {
        #if DEBUG
        print("📊 Analytics: Purchase failed for \(package.identifier) - \(error.localizedDescription)")
        #endif
        
        // AnalyticsManager.shared.track("purchase_failed", properties: [
        //     "package": package.identifier,
        //     "error": error.localizedDescription
        // ])
    }
}

// MARK: - Best Practice #4: Smart Paywall Presentation

struct SmartPaywallPresenter {
    /// Determine if paywall should be shown based on user behavior
    static func shouldShowPaywall(
        feature: String,
        hasSeenBefore: Bool,
        attemptCount: Int,
        isOnboarding: Bool
    ) -> Bool {
        // Don't spam users with paywalls
        if attemptCount > 3 {
            return false
        }
        
        // Show during onboarding
        if isOnboarding {
            return true
        }
        
        // Show first time accessing locked feature
        if !hasSeenBefore {
            return true
        }
        
        // Show occasionally for repeat attempts
        return attemptCount % 3 == 0
    }
    
    /// Track when paywall was shown for a feature
    static func markPaywallShown(for feature: String) {
        let key = "paywall_shown_\(feature)"
        let count = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(count + 1, forKey: key)
    }
    
    /// Get how many times paywall was shown for a feature
    static func getPaywallCount(for feature: String) -> Int {
        let key = "paywall_shown_\(feature)"
        return UserDefaults.standard.integer(forKey: key)
    }
}

// MARK: - Best Practice #5: Feature Flags with Entitlements

struct FeatureFlags {
    private let subscriptionManager = SubscriptionManager.shared
    
    /// Check if a specific feature is unlocked
    func isFeatureUnlocked(_ feature: Feature) -> Bool {
        switch feature {
        case .unlimitedCases, .advancedStats, .prioritySupport:
            return subscriptionManager.hasProAccess()
        case .basicCases:
            return true // Always available
        }
    }
    
    /// Get the limit for a feature (nil = unlimited)
    func getFeatureLimit(_ feature: Feature) -> Int? {
        if subscriptionManager.hasProAccess() {
            return nil // Unlimited for pro
        }
        
        switch feature {
        case .unlimitedCases:
            return 5 // Free users get 5 cases
        case .advancedStats:
            return 0 // Not available for free users
        case .prioritySupport:
            return 0 // Not available for free users
        case .basicCases:
            return nil // Always unlimited
        }
    }
    
    enum Feature {
        case unlimitedCases
        case advancedStats
        case prioritySupport
        case basicCases
    }
}

// MARK: - Best Practice #6: Offline Support

class OfflineEntitlementCache {
    private let lastKnownStatusKey = "last_known_pro_status"
    private let lastCheckDateKey = "last_entitlement_check"
    private let cacheValidityDays = 7
    
    /// Save current pro status for offline use
    func cacheProStatus(_ hasProAccess: Bool) {
        UserDefaults.standard.set(hasProAccess, forKey: lastKnownStatusKey)
        UserDefaults.standard.set(Date(), forKey: lastCheckDateKey)
    }
    
    /// Get cached pro status if valid
    func getCachedProStatus() -> Bool? {
        guard let lastCheck = UserDefaults.standard.object(forKey: lastCheckDateKey) as? Date else {
            return nil
        }
        
        let daysSinceCheck = Calendar.current.dateComponents([.day], from: lastCheck, to: Date()).day ?? 0
        
        // Cache is valid for 7 days
        guard daysSinceCheck < cacheValidityDays else {
            return nil
        }
        
        return UserDefaults.standard.bool(forKey: lastKnownStatusKey)
    }
    
    /// Check if cache should be refreshed
    func shouldRefreshCache() -> Bool {
        guard let lastCheck = UserDefaults.standard.object(forKey: lastCheckDateKey) as? Date else {
            return true
        }
        
        // Refresh every day
        let daysSinceCheck = Calendar.current.dateComponents([.day], from: lastCheck, to: Date()).day ?? 0
        return daysSinceCheck >= 1
    }
}

// MARK: - Best Practice #7: Subscription Status Monitoring

class SubscriptionStatusMonitor: ObservableObject {
    @Published var expirationWarning: ExpirationWarning?
    
    private let subscriptionManager = SubscriptionManager.shared
    
    enum ExpirationWarning {
        case expiringSoon(daysLeft: Int)
        case expired
        case billingIssue
        
        var title: String {
            switch self {
            case .expiringSoon(let days):
                return "Subscription Expiring Soon"
            case .expired:
                return "Subscription Expired"
            case .billingIssue:
                return "Billing Issue"
            }
        }
        
        var message: String {
            switch self {
            case .expiringSoon(let days):
                return "Your subscription expires in \(days) day\(days == 1 ? "" : "s"). Renew now to continue enjoying Pro features."
            case .expired:
                return "Your subscription has expired. Renew now to restore access to Pro features."
            case .billingIssue:
                return "There's an issue with your subscription billing. Please update your payment method."
            }
        }
    }
    
    func checkSubscriptionStatus() {
        guard let customerInfo = subscriptionManager.customerInfo else { return }
        guard let entitlement = customerInfo.entitlements["Rounds Pro"] else { return }
        
        // Check for billing issues
        if entitlement.billingIssueDetectedAt != nil {
            expirationWarning = .billingIssue
            return
        }
        
        // Check if expired
        if !entitlement.isActive {
            expirationWarning = .expired
            return
        }
        
        // Check for expiring soon (within 7 days)
        if let expirationDate = entitlement.expirationDate,
           entitlement.willRenew == false {
            let daysUntilExpiration = Calendar.current.dateComponents(
                [.day],
                from: Date(),
                to: expirationDate
            ).day ?? 0
            
            if daysUntilExpiration <= 7 && daysUntilExpiration > 0 {
                expirationWarning = .expiringSoon(daysLeft: daysUntilExpiration)
                return
            }
        }
        
        // No warning needed
        expirationWarning = nil
    }
}

// MARK: - Best Practice #8: User Identification

extension SubscriptionManager {
    /// Identify user with your backend user ID
    func identifyUser(userId: String) async throws {
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userId)
            await MainActor.run {
                self.updateCustomerInfo(customerInfo)
            }
        } catch {
            print("Error identifying user:", error)
            throw error
        }
    }
    
    /// Log out current user
    func logoutUser() async throws {
        do {
            let customerInfo = try await Purchases.shared.logOut()
            await MainActor.run {
                self.updateCustomerInfo(customerInfo)
            }
        } catch {
            print("Error logging out:", error)
            throw error
        }
    }
    
    /// Set custom attributes for analytics
    func setUserAttributes(_ attributes: [String: String]) {
        Purchases.shared.attribution.setAttributes(attributes)
    }
}

// MARK: - Best Practice #9: Promotional Offers

class PromotionalOfferManager {
    /// Check if user is eligible for promotional offer
    func checkPromotionalEligibility(
        for discount: StoreProductDiscount,
        product: StoreProduct
    ) async -> IntroEligibilityStatus {
        let eligibility = await Purchases.shared.checkPromotionalOfferEligibility(
            forProductDiscount: discount,
            product: product
        )
        return eligibility
    }
    
    /// Show promotional offer to eligible users
    func shouldShowPromotionalOffer(customerInfo: CustomerInfo) -> Bool {
        // Don't show to current subscribers
        guard !customerInfo.entitlements.active.isEmpty == false else {
            return false
        }
        
        // Show to users who previously subscribed but let it lapse
        guard customerInfo.entitlements.all["Rounds Pro"]?.isActive == false else {
            return false
        }
        
        return true
    }
}

// MARK: - Best Practice #10: A/B Testing Paywalls

class PaywallABTesting {
    enum PaywallVariant: String {
        case control = "control"
        case variantA = "variant_a"
        case variantB = "variant_b"
    }
    
    /// Get assigned paywall variant for user
    static func getPaywallVariant() -> PaywallVariant {
        // Check if user already has a variant assigned
        if let stored = UserDefaults.standard.string(forKey: "paywall_variant"),
           let variant = PaywallVariant(rawValue: stored) {
            return variant
        }
        
        // Assign random variant
        let variants: [PaywallVariant] = [.control, .variantA, .variantB]
        let random = variants.randomElement() ?? .control
        
        // Store for consistency
        UserDefaults.standard.set(random.rawValue, forKey: "paywall_variant")
        
        return random
    }
    
    /// Track which variant converted
    static func trackConversion(variant: PaywallVariant, package: Package) {
        #if DEBUG
        print("📊 A/B Test: Conversion for variant \(variant.rawValue) - package: \(package.identifier)")
        #endif
        
        // Track in your analytics
        // AnalyticsManager.shared.track("paywall_conversion", properties: [
        //     "variant": variant.rawValue,
        //     "package": package.identifier
        // ])
    }
}

// MARK: - Example Usage View

struct BestPracticesExampleView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var statusMonitor = SubscriptionStatusMonitor()
    @State private var showingPaywall = false
    
    let featureToUnlock = "advanced_stats"
    
    var body: some View {
        VStack(spacing: 20) {
            // Show expiration warning if needed
            if let warning = statusMonitor.expirationWarning {
                WarningBanner(warning: warning)
            }
            
            // Feature access button
            Button {
                accessFeature()
            } label: {
                Text("Access Advanced Stats")
            }
        }
        .sheet(isPresented: $showingPaywall) {
            // Use smart paywall presentation
            let variant = PaywallABTesting.getPaywallVariant()
            
            PaywallView()
                .onPurchaseCompleted { customerInfo in
                    // Track conversion
                    if let package = subscriptionManager.currentOffering?.availablePackages.first {
                        PaywallABTesting.trackConversion(variant: variant, package: package)
                    }
                }
        }
        .onAppear {
            statusMonitor.checkSubscriptionStatus()
        }
    }
    
    private func accessFeature() {
        let attemptCount = SmartPaywallPresenter.getPaywallCount(for: featureToUnlock)
        let hasSeenBefore = attemptCount > 0
        
        if subscriptionManager.hasProAccess() {
            // Access granted
            openAdvancedStats()
        } else if SmartPaywallPresenter.shouldShowPaywall(
            feature: featureToUnlock,
            hasSeenBefore: hasSeenBefore,
            attemptCount: attemptCount,
            isOnboarding: false
        ) {
            // Show paywall
            SmartPaywallPresenter.markPaywallShown(for: featureToUnlock)
            PurchaseAnalytics.trackPaywallPresented(from: featureToUnlock)
            showingPaywall = true
        } else {
            // Show alternative (e.g., upgrade banner)
            showUpgradeBanner()
        }
    }
    
    private func openAdvancedStats() {
        // Open feature
    }
    
    private func showUpgradeBanner() {
        // Show less intrusive upgrade prompt
    }
}

struct WarningBanner: View {
    let warning: SubscriptionStatusMonitor.ExpirationWarning
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(warning.title)
                    .font(.headline)
                Text(warning.message)
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding()
    }
}

// MARK: - Previews

#Preview {
    BestPracticesExampleView()
}
