//
//  SubscriptionManager.swift
//  Rounds
//
//  Created by Ali Mirza on 1/11/26.
//

import Foundation
import RevenueCat
import SwiftUI
import Combine

/// Manages all RevenueCat subscription operations
class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    @Published var customerInfo: CustomerInfo?
    @Published var isProSubscriber: Bool = false
    @Published var currentOffering: Offering?
    @Published var subscriptionStatus: SubscriptionStatus = .free
    
    // MARK: - Constants
    private let apiKey = "test_dDeBAeUiVPFXqkYLYBpRccJBmWC"
    private let proEntitlementID = "Rounds Pro"
    
    // Product IDs
    enum ProductID: String {
        case monthly = "monthly"
        case yearly = "yearly"
        case lifetime = "lifetime"
    }
    
    enum SubscriptionStatus {
        case free
        case monthly
        case yearly
        case lifetime
        
        var displayName: String {
            switch self {
            case .free: return "Free"
            case .monthly: return "Pro (Monthly)"
            case .yearly: return "Pro (Yearly)"
            case .lifetime: return "Pro (Lifetime)"
            }
        }
    }
    
    private override init() {
        super.init()
    }
    
    // MARK: - Configuration
    
    /// Configure RevenueCat SDK - Call this at app launch
    func configure() {
        // Configure with API key
        Purchases.configure(withAPIKey: apiKey)
        
        // Enable debug logs in development
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        
        // Set up delegate for customer info updates
        Purchases.shared.delegate = self
        
        // Fetch initial customer info
        Task {
            await refreshCustomerInfo()
        }
    }
    
    // MARK: - Customer Info
    
    /// Refresh customer info from RevenueCat
    func refreshCustomerInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            await MainActor.run {
                self.updateCustomerInfo(info)
            }
        } catch {
            print("Error fetching customer info: \(error.localizedDescription)")
        }
    }
    
    /// Update customer info and subscription status
    @MainActor
    private func updateCustomerInfo(_ info: CustomerInfo) {
        self.customerInfo = info
        self.isProSubscriber = info.entitlements[proEntitlementID]?.isActive == true
        
        // Determine subscription status
        if let entitlement = info.entitlements[proEntitlementID], entitlement.isActive {
            // Check if lifetime
            if entitlement.willRenew == false && entitlement.expirationDate == nil {
                self.subscriptionStatus = .lifetime
            } else if let productId = entitlement.productIdentifier {
                // Check subscription type
                if productId.contains("yearly") {
                    self.subscriptionStatus = .yearly
                } else if productId.contains("monthly") {
                    self.subscriptionStatus = .monthly
                } else if productId.contains("lifetime") {
                    self.subscriptionStatus = .lifetime
                } else {
                    self.subscriptionStatus = .free
                }
            }
        } else {
            self.subscriptionStatus = .free
        }
    }
    
    // MARK: - Offerings
    
    /// Fetch current offerings from RevenueCat
    func fetchOfferings() async throws -> Offerings {
        let offerings = try await Purchases.shared.offerings()
        
        // Store current offering
        if let current = offerings.current {
            await MainActor.run {
                self.currentOffering = current
            }
        }
        
        return offerings
    }
    
    // MARK: - Purchases
    
    /// Purchase a specific package
    func purchase(package: Package) async throws -> CustomerInfo {
        let result = try await Purchases.shared.purchase(package: package)
        await MainActor.run {
            self.updateCustomerInfo(result.customerInfo)
        }
        return result.customerInfo
    }
    
    /// Restore previous purchases
    func restorePurchases() async throws -> CustomerInfo {
        let info = try await Purchases.shared.restorePurchases()
        await MainActor.run {
            self.updateCustomerInfo(info)
        }
        return info
    }
    
    // MARK: - Subscription Management
    
    /// Check if user has active Pro subscription
    func hasProAccess() -> Bool {
        return isProSubscriber
    }
    
    /// Get subscription expiration date
    func getExpirationDate() -> Date? {
        return customerInfo?.entitlements[proEntitlementID]?.expirationDate
    }
    
    /// Check if subscription will renew
    func willRenew() -> Bool {
        return customerInfo?.entitlements[proEntitlementID]?.willRenew ?? false
    }
    
    /// Get active subscription period type
    func getSubscriptionPeriod() -> String? {
        guard let entitlement = customerInfo?.entitlements[proEntitlementID],
              entitlement.isActive else {
            return nil
        }
        
        return entitlement.periodType.rawValue
    }
}

// MARK: - PurchasesDelegate

extension SubscriptionManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.updateCustomerInfo(customerInfo)
        }
    }
}
