# RevenueCat Integration Guide for Rounds App

## Step 1: Install RevenueCat SDK via Swift Package Manager

### In Xcode:

1. **Open your project in Xcode**
2. **Go to File → Add Package Dependencies...**
3. **Enter the package URL:**
   ```
   https://github.com/RevenueCat/purchases-ios-spm.git
   ```
4. **Select the following products:**
   - `RevenueCat` (required)
   - `RevenueCatUI` (for Paywall and Customer Center views)
5. **Click "Add Package"**

### Package Requirements:
```swift
// In Package.swift if using SPM for your project:
dependencies: [
    .package(url: "https://github.com/RevenueCat/purchases-ios-spm.git", from: "5.0.0")
]

// Add to your target:
.product(name: "RevenueCat", package: "purchases-ios-spm"),
.product(name: "RevenueCatUI", package: "purchases-ios-spm")
```

---

## Step 2: Configure RevenueCat Dashboard

### Before coding, set up your products in RevenueCat Dashboard:

1. **Go to:** https://app.revenuecat.com
2. **Navigate to:** Your Project → Configure → Products
3. **Add your products:**
   - **Monthly:** `monthly` (e.g., $4.99/month)
   - **Yearly:** `yearly` (e.g., $39.99/year)
   - **Lifetime:** `lifetime` (e.g., $99.99 one-time)

4. **Create Entitlement:**
   - Name: `Rounds Pro`
   - Attach all three products to this entitlement

5. **Create Offering:**
   - Identifier: `default` (or custom)
   - Add all three packages (monthly, yearly, lifetime)

6. **Configure Paywall (Optional but Recommended):**
   - Go to: Paywalls → Create Paywall
   - Design your paywall in the visual editor
   - Attach to your offering

---

## Step 3: Implementation Overview

Your app already has the correct implementation! Here's what's set up:

### ✅ Files Already Configured:

1. **SubscriptionManager.swift** - Complete subscription management
2. **SubscriptionSettingsView.swift** - Customer Center integration
3. **RoundsApp.swift** - RevenueCat configuration on launch
4. **ProFeatureExamples.swift** - Feature gating examples (needs fixes)

---

## Step 4: How Everything Works

### A. App Launch Configuration

In `RoundsApp.swift`:
```swift
init() {
    Task { @MainActor in
        SubscriptionManager.shared.configure()
    }
}
```

This initializes RevenueCat with your API key: `test_dDeBAeUiVPFXqkYLYBpRccJBmWC`

### B. Subscription Manager

The `SubscriptionManager` handles:
- ✅ SDK configuration
- ✅ Customer info fetching
- ✅ Entitlement checking (`Rounds Pro`)
- ✅ Purchase handling
- ✅ Restore purchases
- ✅ Real-time updates via `PurchasesDelegate`

### C. Paywall Presentation

RevenueCat provides a ready-to-use paywall:
```swift
import RevenueCatUI

PaywallView()  // Shows default offering with your configured paywall
```

### D. Customer Center

For subscription management:
```swift
CustomerCenterView()  // Built-in subscription management UI
```

---

## Step 5: Common Usage Patterns

### Check Pro Access:
```swift
if SubscriptionManager.shared.hasProAccess() {
    // User has pro features
} else {
    // Show paywall or limited features
}
```

### Show Paywall:
```swift
.sheet(isPresented: $showingPaywall) {
    PaywallView()
}
```

### Restore Purchases:
```swift
Task {
    try await SubscriptionManager.shared.restorePurchases()
}
```

### Get Customer Info:
```swift
await SubscriptionManager.shared.refreshCustomerInfo()
```

---

## Step 6: Testing

### Test Purchases:

1. **Use Sandbox Account:**
   - Settings → App Store → Sandbox Account
   - Sign in with a test account

2. **Test Products:**
   - Make test purchases
   - Test restore
   - Test subscription management

3. **Debug Logging:**
   RevenueCat logs are enabled in DEBUG mode:
   ```swift
   #if DEBUG
   Purchases.logLevel = .debug
   #endif
   ```

### StoreKit Configuration File (Recommended):

1. **Create StoreKit Configuration:**
   - File → New → File → StoreKit Configuration File
   - Add your products matching App Store Connect

2. **Enable in Scheme:**
   - Edit Scheme → Run → Options
   - Select your StoreKit Configuration

---

## Step 7: Production Checklist

Before releasing:

- [ ] Replace test API key with production key
- [ ] Test all purchase flows
- [ ] Verify restore purchases works
- [ ] Test subscription management
- [ ] Verify entitlement checking
- [ ] Test offline behavior
- [ ] Review analytics in RevenueCat Dashboard
- [ ] Set up webhooks (optional)
- [ ] Configure privacy policy links
- [ ] Test Family Sharing (if enabled)

---

## Advanced Features

### A. Custom Paywall (If you want to build your own):

```swift
struct CustomPaywallView: View {
    @StateObject private var manager = SubscriptionManager.shared
    @State private var offerings: Offerings?
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if let offering = offerings?.current {
                ForEach(offering.availablePackages, id: \.identifier) { package in
                    PackageButton(package: package) {
                        await purchase(package)
                    }
                }
            }
        }
        .task {
            offerings = try? await manager.fetchOfferings()
        }
    }
    
    func purchase(_ package: Package) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await manager.purchase(package: package)
            // Handle success
        } catch {
            // Handle error
        }
    }
}
```

### B. Promotional Offers:

```swift
// Check eligibility
let eligibility = await Purchases.shared.checkPromotionalOfferEligibility(
    forProductDiscount: discount,
    product: storeProduct
)

// Present offer if eligible
if eligibility == .eligible {
    // Show promotional pricing
}
```

### C. Customer Attributes:

```swift
// Set custom attributes
Purchases.shared.attribution.setAttributes([
    "user_level": "advanced",
    "specialty": "cardiology"
])
```

### D. Identify Users:

```swift
// Link to your user system
try await Purchases.shared.logIn("user_id_123")

// Log out
try await Purchases.shared.logOut()
```

---

## Troubleshooting

### Common Issues:

1. **"No offerings found"**
   - Verify products in RevenueCat Dashboard
   - Check API key is correct
   - Ensure offering is configured

2. **"Invalid product identifiers"**
   - Product IDs must match App Store Connect exactly
   - Verify products are approved in App Store Connect

3. **Purchases not restoring**
   - Check entitlement configuration
   - Verify same Apple ID is used
   - Check product status in Dashboard

4. **Paywall not showing**
   - Ensure `RevenueCatUI` package is imported
   - Check offering exists
   - Verify paywall is configured in Dashboard

### Debug Commands:

```swift
// Get debug info
print("Customer ID:", Purchases.shared.appUserID)
print("Is Anonymous:", Purchases.shared.isAnonymous)

// Check offerings
let offerings = try await Purchases.shared.offerings()
print("Offerings:", offerings.all)

// Check customer info
let info = try await Purchases.shared.customerInfo()
print("Active entitlements:", info.entitlements.active.keys)
```

---

## Resources

- **Documentation:** https://www.revenuecat.com/docs
- **Paywalls Guide:** https://www.revenuecat.com/docs/tools/paywalls
- **Customer Center:** https://www.revenuecat.com/docs/tools/customer-center
- **Dashboard:** https://app.revenuecat.com
- **Community:** https://community.revenuecat.com

---

## Next Steps

Your integration is almost complete! Just need to:

1. ✅ Install the Swift Package (if not already done)
2. ✅ Configure products in RevenueCat Dashboard
3. ✅ Test purchase flows
4. ✅ Fix the ProFeatureExamples.swift errors (see updated file)
5. ✅ Test in production environment before release

All the code infrastructure is ready to go! 🚀
