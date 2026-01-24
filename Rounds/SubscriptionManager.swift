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
        if let entitlement = proEntitlement, entitlement.isActive {
            let productId = entitlement.productIdentifier
            if productId.contains("lifetime") || (entitlement.expirationDate == nil && !entitlement.willRenew) {
                self.subscriptionStatus = .lifetime
            } else if productId.contains("yearly") {
                self.subscriptionStatus = .yearly
            } else if productId.contains("monthly") {
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
    
    // MARK: - Entitlement Helpers
    
    /// Check if user has active Pro subscription
    /// Note: This is @MainActor isolated - call from SwiftUI views or main thread only
    func hasProAccess() -> Bool {
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
