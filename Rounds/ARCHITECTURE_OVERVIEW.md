# RevenueCat Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Your App                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │             SwiftUI Views                           │   │
│  │  • CaseSelectionView                                │   │
│  │  • StatisticsTabView                                │   │
│  │  • SettingsView                                     │   │
│  │  • PaywallView (RevenueCatUI)                       │   │
│  │  • CustomerCenterView (RevenueCatUI)                │   │
│  └──────────────────┬──────────────────────────────────┘   │
│                     │                                       │
│                     ↓                                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │        SubscriptionManager (Singleton)              │   │
│  │  • @Published customerInfo                          │   │
│  │  • @Published isProSubscriber                       │   │
│  │  • hasProAccess() → Bool                            │   │
│  │  • purchase(package:)                               │   │
│  │  • restorePurchases()                               │   │
│  │  • refreshCustomerInfo()                            │   │
│  └──────────────────┬──────────────────────────────────┘   │
│                     │                                       │
│                     ↓                                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │          RevenueCat SDK                             │   │
│  │  • Purchases.shared                                 │   │
│  │  • PurchasesDelegate                                │   │
│  │  • Handles StoreKit integration                     │   │
│  └──────────────────┬──────────────────────────────────┘   │
│                     │                                       │
└─────────────────────┼───────────────────────────────────────┘
                      │
                      ↓
┌─────────────────────────────────────────────────────────────┐
│                   Apple StoreKit                            │
│  • Product catalog                                          │
│  • Purchase processing                                      │
│  • Receipt validation                                       │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────────────────┐
│              RevenueCat Backend                             │
│  • Receipt validation                                       │
│  • Customer info database                                   │
│  • Entitlement management                                   │
│  • Analytics & reporting                                    │
│  • Webhook delivery                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### 1. App Launch
```
App Start
   ↓
RoundsApp.init()
   ↓
SubscriptionManager.shared.configure()
   ↓
Purchases.configure(withAPIKey: "...")
   ↓
Fetch initial CustomerInfo
   ↓
Update @Published properties
   ↓
UI reflects subscription status
```

### 2. Purchase Flow
```
User taps "Upgrade to Pro"
   ↓
Show PaywallView
   ↓
User selects package (monthly/yearly/lifetime)
   ↓
User taps "Subscribe"
   ↓
PaywallView calls purchase(package:)
   ↓
SubscriptionManager.purchase(package:)
   ↓
Purchases.shared.purchase(package:)
   ↓
StoreKit processes payment
   ↓
Receipt sent to RevenueCat backend
   ↓
RevenueCat validates receipt
   ↓
CustomerInfo updated
   ↓
SubscriptionManager updates @Published properties
   ↓
UI automatically updates (hasProAccess = true)
   ↓
Paywall dismisses
   ↓
User can access pro features
```

### 3. Entitlement Check Flow
```
User tries to access pro feature
   ↓
Check: SubscriptionManager.shared.hasProAccess()
   ↓
SubscriptionManager checks customerInfo.entitlements["Rounds Pro"]
   ↓
if isActive == true
   ↓ YES
   Allow access to feature
   
   ↓ NO
   Show paywall or lock UI
```

### 4. Restore Purchase Flow
```
User taps "Restore Purchases"
   ↓
SubscriptionManager.restorePurchases()
   ↓
Purchases.shared.restorePurchases()
   ↓
StoreKit fetches receipts
   ↓
RevenueCat validates all receipts
   ↓
CustomerInfo updated
   ↓
SubscriptionManager updates @Published properties
   ↓
UI reflects restored purchases
```

### 5. Real-Time Updates
```
Subscription status changes on another device
   ↓
RevenueCat backend detects change
   ↓
Next app launch or periodic refresh
   ↓
Purchases.shared fetches new CustomerInfo
   ↓
PurchasesDelegate.receivedUpdated(customerInfo:)
   ↓
SubscriptionManager receives update
   ↓
@Published properties update
   ↓
UI automatically reflects new status
```

---

## Component Responsibilities

### SwiftUI Views
**Responsibility:** Present UI and handle user interaction
- Display content
- Show paywalls when needed
- React to subscription state changes
- Handle user input

**Dependencies:** SubscriptionManager (via @StateObject)

---

### SubscriptionManager
**Responsibility:** Bridge between your app and RevenueCat SDK
- Manage subscription state
- Provide simple API for views
- Handle purchase operations
- Cache customer info
- Emit @Published updates

**Dependencies:** RevenueCat SDK (Purchases)

---

### RevenueCat SDK
**Responsibility:** Handle all subscription infrastructure
- StoreKit integration
- Receipt validation
- Network communication
- Customer info management
- Real-time updates

**Dependencies:** StoreKit, RevenueCat Backend

---

### RevenueCat Backend
**Responsibility:** Server-side subscription management
- Validate receipts with Apple
- Store customer data
- Manage entitlements
- Provide analytics
- Deliver webhooks

**Dependencies:** Apple App Store

---

## Key Concepts

### CustomerInfo
The central object containing all subscription data:
```swift
struct CustomerInfo {
    var entitlements: EntitlementInfos
    var activeSubscriptions: Set<String>
    var allPurchasedProductIdentifiers: Set<String>
    var requestDate: Date
    // ... and more
}
```

### Entitlement
A feature or set of features unlocked by a purchase:
```
Entitlement: "Rounds Pro"
   ↳ Products: monthly, yearly, lifetime
   ↳ Status: active/inactive
   ↳ Expiration: Date or nil
```

### Offering
A collection of products presented to users:
```
Offering: "default"
   ↳ Package: monthly ($4.99/mo)
   ↳ Package: yearly ($39.99/yr) [default]
   ↳ Package: lifetime ($99.99 once)
```

### Package
A product with presentation metadata:
```
Package {
    identifier: "yearly"
    packageType: .annual
    storeProduct: StoreProduct
    localizedPriceString: "$39.99"
}
```

---

## State Management

### Published Properties
```swift
class SubscriptionManager: ObservableObject {
    @Published var customerInfo: CustomerInfo?
    @Published var isProSubscriber: Bool = false
    @Published var subscriptionStatus: SubscriptionStatus = .free
}
```

### Automatic UI Updates
When @Published properties change:
```
SubscriptionManager.isProSubscriber = true
   ↓
SwiftUI detects change
   ↓
Any views observing SubscriptionManager
   ↓
Re-render with new state
   ↓
UI shows pro features
```

---

## Error Handling

### Purchase Errors
```
User attempts purchase
   ↓
Error occurs (network, cancelled, etc.)
   ↓
Error propagated to UI
   ↓
Show user-friendly message
   ↓
Allow retry
```

### Network Errors
```
No internet connection
   ↓
Use cached CustomerInfo
   ↓
If cache valid (< 7 days)
   ↓
Continue with cached data
   ↓
Else: Show warning
```

---

## Security

### Receipt Validation
```
User makes purchase
   ↓
StoreKit provides receipt
   ↓
Receipt sent to RevenueCat
   ↓
RevenueCat validates with Apple
   ↓
Only valid receipts grant entitlements
   ↓
Your app never sees raw receipt
```

### Benefits:
- ✅ Server-side validation (can't be bypassed)
- ✅ Real-time fraud detection
- ✅ Jailbreak protection
- ✅ No cryptographic code in your app

---

## Offline Support

### Caching Strategy
```
┌─────────────────────────────────────────────────┐
│ CustomerInfo cached locally                      │
├─────────────────────────────────────────────────┤
│ • Cache Duration: 7 days                         │
│ • Refresh: Daily when online                     │
│ • Fallback: Use cached data when offline         │
│ • Validation: Check expiration dates locally     │
└─────────────────────────────────────────────────┘
```

### Offline Behavior
```
App launches offline
   ↓
Check local cache
   ↓
if cache exists and valid
   ↓ YES
   Use cached CustomerInfo
   Grant pro features if entitled
   
   ↓ NO
   Assume free tier
   Attempt to fetch when online
```

---

## Performance

### Initialization
- Fast: < 100ms
- Non-blocking: Async fetch
- Cached: Uses local storage

### Purchase Flow
- Network dependent: 2-5 seconds
- Apple's responsibility
- RevenueCat validation adds ~100ms

### Entitlement Check
- Local only: < 1ms
- No network required
- Simple boolean check

---

## Testing Environments

### Development (Simulator + StoreKit Config)
```
Your App
   ↓
RevenueCat SDK (test key)
   ↓
Local StoreKit Configuration
   ↓
No real money
   ↓
Fast testing
```

### Sandbox (Device + Test Account)
```
Your App
   ↓
RevenueCat SDK (test key)
   ↓
StoreKit Sandbox
   ↓
No real money
   ↓
Real network flow
```

### Production
```
Your App
   ↓
RevenueCat SDK (production key)
   ↓
Real App Store
   ↓
Real money
   ↓
Full validation
```

---

## Monitoring

### RevenueCat Dashboard
- Active subscriptions
- MRR (Monthly Recurring Revenue)
- Conversion rates
- Churn analysis
- Customer details

### Your Analytics
- Paywall impressions
- Purchase attempts
- Success/failure rates
- Feature usage by tier

---

This architecture ensures:
✅ Clean separation of concerns
✅ Easy to test
✅ Scalable
✅ Secure
✅ Performant
✅ Reliable offline support
