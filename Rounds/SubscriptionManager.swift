//
//  SubscriptionManager.swift
//  Rounds
//
//  RevenueCat subscription management - Clean implementation
//

import Foundation
import RevenueCat
import SwiftUI

/// Manages all RevenueCat subscription operations for Rounds
@MainActor
@Observable
final class SubscriptionManager {
    
    // MARK: - Singleton
    
    // nonisolated(unsafe) allows cross-actor access to the singleton
    // The instance itself is @MainActor protected
    nonisolated(unsafe) static let shared = SubscriptionManager()
    
    // MARK: - Observable Properties
    
    private(set) var customerInfo: CustomerInfo?
    private(set) var isProSubscriber: Bool = false
    private(set) var currentOffering: Offering?
    private(set) var subscriptionStatus: SubscriptionStatus = .free

    /// Computed property that includes TestFlight check
    var isProUser: Bool {
        return hasProAccess()
    }

    // MARK: - Beta overrides

    /// UserDefaults key backing the "simulate free user" override.
    static let simulateFreeUserKey = "debug_simulate_free_user"

    /// True for builds where beta-only overrides are honoured: local DEBUG
    /// builds and TestFlight. False for App Store builds, which must never let
    /// a stale UserDefaults value affect what a paying customer sees.
    var isBetaBuild: Bool {
        #if DEBUG
        return true
        #else
        return isTestFlightBuild()
        #endif
    }

    /// Stored mirror of the UserDefaults flag.
    ///
    /// @Observable tracks stored properties, not UserDefaults, so reading the
    /// defaults directly would let the toggle flip without any view re-rendering
    /// — the app would keep showing Pro until something else happened to
    /// invalidate. Keeping a stored copy is what makes the switch take effect
    /// immediately; UserDefaults is only for persistence across launches.
    private var simulateFreeUserStorage: Bool =
        UserDefaults.standard.bool(forKey: "debug_simulate_free_user")

    /// Whether the free-user simulation is currently on. Setting it is a no-op
    /// outside beta builds.
    var isSimulatingFreeUser: Bool {
        get { isBetaBuild && simulateFreeUserStorage }
        set {
            guard isBetaBuild else { return }
            simulateFreeUserStorage = newValue
            UserDefaults.standard.set(newValue, forKey: Self.simulateFreeUserKey)
        }
    }
    
    // MARK: - Constants (nonisolated for cross-actor access)
    
    private nonisolated static let apiKey = "appl_FxQcTJBUrEzLFLjEcowArMgLKcp"
    nonisolated static let proEntitlementID = "Rounds Pro"
    
    // MARK: - Product Identifiers
    
    enum ProductID: String, CaseIterable, Sendable {
        case monthly = "monthly"
        case yearly = "yearly"
        case lifetime = "lifetime"
    }
    
    // MARK: - Subscription Status
    
    enum SubscriptionStatus: String, Sendable {
        case free
        case monthly
        case yearly
        case lifetime
        
        var displayName: String {
            switch self {
            case .free: return "Free"
            case .monthly: return "Pro Monthly"
            case .yearly: return "Pro Yearly"
            case .lifetime: return "Pro Lifetime"
            }
        }
        
        var isProActive: Bool {
            self != .free
        }
    }
    
    // MARK: - Initialization
    
    private nonisolated init() {}
    
    // MARK: - Configuration
    
    /// Configure RevenueCat SDK - Call this at app launch
    nonisolated func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .error
        #endif
        Purchases.configure(withAPIKey: Self.apiKey)
        
        // Set up delegate
        Purchases.shared.delegate = RevenueCatDelegate.shared
        
        // Fetch initial customer info
        Task { @MainActor in
            await Self.shared.refreshCustomerInfo()
        }
    }
    
    // MARK: - Customer Info
    
    /// Refresh customer info from RevenueCat
    func refreshCustomerInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            updateCustomerInfo(info)
        } catch {
            print("❌ Error fetching customer info: \(error.localizedDescription)")
        }
    }
    
    /// Update local state from customer info
    func updateCustomerInfo(_ info: CustomerInfo) {
        self.customerInfo = info
        
        // Check Pro entitlement
        let proEntitlement = info.entitlements[Self.proEntitlementID]
        self.isProSubscriber = proEntitlement?.isActive == true
        
        // Determine subscription status
        // Supports both friendly identifiers (monthly/yearly/lifetime) and
        // the short numeric App Store product IDs (01=monthly, 02=annual, 03=lifetime).
        if let entitlement = proEntitlement, entitlement.isActive {
            let productId = entitlement.productIdentifier
            let isLifetime = productId == "03"
                || productId.contains("lifetime")
                || (entitlement.expirationDate == nil && !entitlement.willRenew)
            let isAnnual = productId == "02"
                || productId.contains("yearly")
                || productId.contains("annual")
            let isMonthly = productId == "01"
                || productId.contains("monthly")

            if isLifetime {
                self.subscriptionStatus = .lifetime
            } else if isAnnual {
                self.subscriptionStatus = .yearly
            } else if isMonthly {
                self.subscriptionStatus = .monthly
            } else {
                self.subscriptionStatus = .monthly
            }
        } else {
            self.subscriptionStatus = .free
        }
    }
    
    // MARK: - Offerings
    
    /// Fetch current offerings from RevenueCat
    func fetchOfferings() async throws -> Offerings {
        let offerings = try await Purchases.shared.offerings()
        
        if let current = offerings.current {
            self.currentOffering = current
        }
        
        return offerings
    }
    
    // MARK: - Purchases
    
    /// Purchase a specific package
    func purchase(package: Package) async throws -> CustomerInfo {
        // Track purchase attempt
        AnalyticsManager.shared.trackPurchaseStarted(productId: package.identifier)
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            updateCustomerInfo(result.customerInfo)
            
            // Track successful purchase
            AnalyticsManager.shared.trackPurchaseCompleted(productId: package.identifier)
            
            return result.customerInfo
        } catch {
            // Track failed purchase
            AnalyticsManager.shared.trackPurchaseFailed(productId: package.identifier, error: error.localizedDescription)
            throw error
        }
    }
    
    /// Restore previous purchases
    func restorePurchases() async throws -> CustomerInfo {
        AnalyticsManager.shared.trackPurchaseRestored()

        let info = try await Purchases.shared.restorePurchases()
        updateCustomerInfo(info)
        return info
    }

    /// Sync purchases by uploading the current receipt to RevenueCat.
    /// Use this after an Apple promo/offer code is redeemed — restorePurchases() won't
    /// surface offer code transactions, but syncPurchases() will because it sends the
    /// fresh device receipt directly to RevenueCat's backend.
    func syncPurchases() async throws -> CustomerInfo {
        let info = try await Purchases.shared.syncPurchases()
        updateCustomerInfo(info)
        return info
    }
    
    // MARK: - Entitlement Helpers
    
    /// Check if user has active Pro subscription
    /// Note: This is @MainActor isolated - call from SwiftUI views or main thread only
    func hasProAccess() -> Bool {
        // Beta-only: allow simulating a free user for screenshots and for
        // testing the free-tier experience.
        //
        // This used to be #if DEBUG, which meant it was compiled out of
        // TestFlight builds — those are Release builds, so DEBUG is undefined.
        // Combined with the TestFlight auto-grant below, that made it
        // impossible to see the free experience on TestFlight at all. The gate
        // is now a runtime check that covers DEBUG *and* TestFlight, while
        // still ignoring the flag entirely in App Store builds.
        if isBetaBuild, simulateFreeUserStorage {
            print("🧪 Simulating free user (beta override active)")
            return false
        }

        // Auto-grant Pro access for TestFlight users
        if isTestFlightBuild() {
            print("✅ TestFlight detected - granting Pro access")

            // Track TestFlight usage in analytics
            AnalyticsManager.shared.setUserProperty(key: "is_testflight", value: true)

            return true
        }

        print("ℹ️ Not TestFlight - checking subscription: \(isProSubscriber)")

        // Track production usage
        AnalyticsManager.shared.setUserProperty(key: "is_testflight", value: false)
        AnalyticsManager.shared.setUserProperty(key: "subscription_status", value: subscriptionStatus.rawValue)

        return isProSubscriber
    }

    // MARK: - TestFlight Detection
    
    /// Detects if app is running via TestFlight
    private func isTestFlightBuild() -> Bool {
        // Method 1: Check receipt path (most reliable for TestFlight)
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            let receiptPath = receiptURL.path
            let receiptName = receiptURL.lastPathComponent
            
            #if DEBUG
            print("📦 Receipt URL: \(receiptURL)")
            print("📦 Receipt path: \(receiptPath)")
            print("📦 Receipt name: \(receiptName)")
            #endif
            
            // TestFlight builds have "sandboxReceipt"
            if receiptName == "sandboxReceipt" {
                print("🧪 TestFlight detected via receipt name")
                return true
            }
        }
        
        // Method 2: Check if installed via TestFlight (alternative)
        if isInstalledViaTestFlight() {
            print("🧪 TestFlight detected via provisioning profile")
            return true
        }
        
        #if DEBUG
        // In DEBUG builds, also grant Pro access (for Xcode testing)
        print("🔍 DEBUG build detected - granting Pro access")
        return true
        #else
        print("❌ Not a TestFlight build")
        return false
        #endif
    }
    
    /// Alternative TestFlight detection method
    private func isInstalledViaTestFlight() -> Bool {
        // Check if there's a provisioning profile (TestFlight has embedded.mobileprovision)
        guard let provisioningPath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
            return false
        }
        
        // If we can read the provisioning profile, check its contents
        guard let provisioningData = try? Data(contentsOf: URL(fileURLWithPath: provisioningPath)),
              let provisioningString = String(data: provisioningData, encoding: .ascii) else {
            return false
        }
        
        // TestFlight builds contain "beta-reports-active" in their profile
        return provisioningString.contains("beta-reports-active")
    }
    
    /// Get subscription source description for debugging
    func getSubscriptionSource() -> String {
        if isTestFlightBuild() {
            return "TestFlight (Auto-granted)"
        } else if isProSubscriber {
            return subscriptionStatus.displayName
        } else {
            return "Free"
        }
    }
    
    /// Debug info for troubleshooting
    func getDebugInfo() -> String {
        var info = """
        Build Type: \(isTestFlightBuild() ? "TestFlight" : "Production")
        Pro Access: \(hasProAccess() ? "Yes" : "No")
        Pro Subscriber: \(isProSubscriber ? "Yes" : "No")
        Subscription Status: \(subscriptionStatus.displayName)
        """
        
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            info += "\nReceipt: \(receiptURL.lastPathComponent)"
        }
        
        return info
    }
    
    /// Get subscription expiration date (nil for lifetime)
    func getExpirationDate() -> Date? {
        return customerInfo?.entitlements[Self.proEntitlementID]?.expirationDate
    }
    
    /// Check if subscription will auto-renew
    func willRenew() -> Bool {
        return customerInfo?.entitlements[Self.proEntitlementID]?.willRenew ?? false
    }
    
    /// Check if there's a billing issue
    func hasBillingIssue() -> Bool {
        return customerInfo?.entitlements[Self.proEntitlementID]?.billingIssueDetectedAt != nil
    }
}

// MARK: - RevenueCat Delegate

/// Separate delegate class to handle RevenueCat callbacks (must not be MainActor)
final class RevenueCatDelegate: NSObject, PurchasesDelegate, @unchecked Sendable {
    static let shared = RevenueCatDelegate()
    
    private override init() {
        super.init()
    }
    
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            SubscriptionManager.shared.updateCustomerInfo(customerInfo)
        }
    }
}
