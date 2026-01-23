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
        let result = try await Purchases.shared.purchase(package: package)
        updateCustomerInfo(result.customerInfo)
        return result.customerInfo
    }
    
    /// Restore previous purchases
    func restorePurchases() async throws -> CustomerInfo {
        let info = try await Purchases.shared.restorePurchases()
        updateCustomerInfo(info)
        return info
    }
    
    // MARK: - Entitlement Helpers
    
    /// Check if user has active Pro subscription
    /// Note: This is @MainActor isolated - call from SwiftUI views or main thread only
    func hasProAccess() -> Bool {
        return isProSubscriber
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
