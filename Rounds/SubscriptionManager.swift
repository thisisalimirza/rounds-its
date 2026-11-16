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

    /// Opt-in Pro for this device, from the hidden diagnostics screen.
    /// Off unless someone turns it on. Not tied to a sandbox receipt.
    static let diagnosticsProGrantKey = "debug_grant_pro_device"

    private var diagnosticsProGrantStorage: Bool =
        UserDefaults.standard.bool(forKey: "debug_grant_pro_device")

    var diagnosticsProGrant: Bool {
        get { diagnosticsProGrantStorage }
        set {
            diagnosticsProGrantStorage = newValue
            UserDefaults.standard.set(newValue, forKey: Self.diagnosticsProGrantKey)
        }
    }

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
    
    /// Store product identifiers.
    ///
    /// `monthly`, `yearly`, and `lifetime` are RevenueCat Test Store ids. They
    /// are not what the App Store sells. The live products are `01` (monthly,
    /// no longer sold; still recognized), `02` (annual), `03` (lifetime), and
    /// `04` (weekly, inactive). The current offering identifier is `new_pricing`.
    enum ProductID: String, CaseIterable, Sendable {
        case testMonthly = "monthly"
        case testYearly = "yearly"
        case testLifetime = "lifetime"
        case monthlyLegacy = "01"
        case annual = "02"
        case lifetime = "03"
        case weeklyInactive = "04"

        var isTestStore: Bool {
            switch self {
            case .testMonthly, .testYearly, .testLifetime: return true
            default: return false
            }
        }
    }

    /// Offering the dashboard currently serves. Paywalls use the dashboard's
    /// current offering; this is the identifier we prefer when fetching by name.
    nonisolated static let currentOfferingID = "new_pricing"
    
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

            let isWeekly = productId == ProductID.weeklyInactive.rawValue
            if isLifetime {
                self.subscriptionStatus = .lifetime
            } else if isAnnual {
                self.subscriptionStatus = .yearly
            } else if isMonthly || isWeekly {
                self.subscriptionStatus = .monthly
            } else {
                self.subscriptionStatus = .monthly
            }
        } else {
            self.subscriptionStatus = .free
        }
        reportEntitlementMismatch()
        AccountManager.shared.reportAnalyticsIdentity()
    }
    
    // MARK: - Offerings
    
    /// Fetch current offerings from RevenueCat
    func fetchOfferings() async throws -> Offerings {
        let offerings = try await Purchases.shared.offerings()
        
        if let named = offerings.offering(identifier: Self.currentOfferingID) {
            self.currentOffering = named
        } else if let current = offerings.current {
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
    
    /// Restore previous purchases. The dashboard keeps "Transfer to new App User ID".
    func restorePurchases() async throws -> CustomerInfo {
        AnalyticsManager.shared.track("restore_started")
        AnalyticsManager.shared.trackPurchaseRestored()
        do {
            let info = try await Purchases.shared.restorePurchases()
            updateCustomerInfo(info)
            let active = info.entitlements[Self.proEntitlementID]?.isActive == true
            AnalyticsManager.shared.track(active ? "restore_succeeded" : "restore_none_found")
            if active {
                await AccountManager.shared.refreshProMirror()
            }
            return info
        } catch {
            AnalyticsManager.shared.track("restore_failed", properties: [
                "error": error.localizedDescription
            ])
            throw error
        }
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
        // Opt-in only, from the hidden diagnostics screen. Default off.
        // A sandbox receipt used to grant Pro to every TestFlight install and
        // hid the cases where the entitlement never arrived.
        if isSimulatingFreeUser {
            return false
        }
        if diagnosticsProGrantStorage {
            return true
        }

        #if DEBUG
        return true
        #else
        AnalyticsManager.shared.setUserProperty(key: "subscription_status", value: subscriptionStatus.rawValue)
        // RevenueCat's live entitlement, or a server grant (a code, or a
        // subscription the webhook has mirrored). The server flag is cached
        // so a ward with no signal does not take Pro away.
        return entitlementOrServerGrant
        #endif
    }

    /// Live RevenueCat entitlement or the cached server grant. DEBUG and the
    /// diagnostics override are not included, so person properties stay honest.
    var entitlementOrServerGrant: Bool {
        isProSubscriber || serverGrantIsPro
    }

    /// Cached `has_pro` from my-status / refresh-pro. A failed fetch leaves this alone.
    private var serverGrantIsPro: Bool = UserDefaults.standard.bool(forKey: "pro.serverHasPro.v1")
    private var serverGrantKnown: Bool = UserDefaults.standard.bool(forKey: "pro.serverHasProKnown.v1")
    private var lastMismatchKey: String?

    func noteServerGrant(_ hasPro: Bool) {
        let changed = !serverGrantKnown || serverGrantIsPro != hasPro
        serverGrantKnown = true
        serverGrantIsPro = hasPro
        UserDefaults.standard.set(hasPro, forKey: "pro.serverHasPro.v1")
        UserDefaults.standard.set(true, forKey: "pro.serverHasProKnown.v1")
        if changed {
            reportEntitlementMismatch()
        }
    }

    func reportEntitlementMismatch() {
        #if DEBUG
        return
        #else
        guard serverGrantKnown, customerInfo != nil else { return }
        guard !diagnosticsProGrantStorage, !isSimulatingFreeUser else { return }
        let device = isProSubscriber
        let server = serverGrantIsPro
        guard device != server else {
            lastMismatchKey = nil
            return
        }
        let key = "\(device)-\(server)"
        guard lastMismatchKey != key else { return }
        lastMismatchKey = key
        AnalyticsManager.shared.track("entitlement_mismatch", properties: [
            "revenuecat_active": device,
            "server_has_pro": server,
        ])
        #endif
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
