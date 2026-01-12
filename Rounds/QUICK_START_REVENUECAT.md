# RevenueCat Quick Start Guide for Rounds

## 🚀 Your Integration Status

### ✅ Already Complete:
1. **SubscriptionManager.swift** - Fully implemented
2. **SubscriptionSettingsView.swift** - Customer Center integration
3. **RoundsApp.swift** - SDK configuration on launch
4. **ProFeatureExamples.swift** - Feature gating examples (now fixed)
5. **RoundsPaywallView.swift** - Custom paywall wrapper
6. **ProBadge.swift** - UI components

### 📦 To Do:

#### 1. Install RevenueCat SDK (5 minutes)

**In Xcode:**
1. Go to **File → Add Package Dependencies...**
2. Paste: `https://github.com/RevenueCat/purchases-ios-spm.git`
3. Select version: **5.0.0** or later
4. Add both products:
   - ✅ **RevenueCat**
   - ✅ **RevenueCatUI**
5. Click **Add Package**

#### 2. Configure RevenueCat Dashboard (10 minutes)

**Go to:** https://app.revenuecat.com

##### A. Create Products
Navigate to: **Configure → Products**

Add three products:
```
1. Monthly Subscription
   - Product ID: monthly
   - Type: Auto-Renewable Subscription
   - Duration: 1 month
   - Price: $4.99 (or your price)

2. Yearly Subscription
   - Product ID: yearly
   - Type: Auto-Renewable Subscription
   - Duration: 1 year
   - Price: $39.99 (or your price)

3. Lifetime Purchase
   - Product ID: lifetime
   - Type: Non-Consumable
   - Price: $99.99 (or your price)
```

##### B. Create Entitlement
Navigate to: **Configure → Entitlements**

```
Name: Rounds Pro
Description: Pro features for Rounds app
Attach products: monthly, yearly, lifetime
```

##### C. Create Offering
Navigate to: **Configure → Offerings**

```
Identifier: default
Display Name: Standard Offering
Packages:
  - monthly (Monthly)
  - yearly (Annual) ⭐ Mark as default
  - lifetime (Lifetime)
```

##### D. Design Paywall (Optional - Highly Recommended)
Navigate to: **Paywalls → Create Paywall**

1. Choose a template
2. Customize:
   - Title: "Upgrade to Rounds Pro"
   - Subtitle: "Unlock unlimited cases"
   - Features list
   - Colors and branding
3. Attach to **default** offering

#### 3. Set Up App Store Connect (15 minutes)

**Go to:** https://appstoreconnect.apple.com

##### A. Create In-App Purchases

For each product (monthly, yearly, lifetime):

1. Go to your app → **Monetization → In-App Purchases**
2. Click **+** to add new
3. For subscriptions:
   - Type: **Auto-Renewable Subscription**
   - Create subscription group if needed
4. Configure:
   - **Product ID:** Must match RevenueCat exactly (`monthly`, `yearly`, `lifetime`)
   - **Reference Name:** "Rounds Pro - Monthly" (or relevant)
   - **Subscription Group:** "Rounds Pro Subscriptions"
   - **Duration:** 1 month / 1 year
   - **Price:** Set your price point

5. Add localization (at least English)
6. Submit for review (can test while "Waiting for Review")

##### B. Configure Subscription Pricing

For best results:
- **Monthly:** $4.99
- **Yearly:** $39.99 (saves ~33%)
- **Lifetime:** $99.99

#### 4. Create StoreKit Configuration File (Testing - 5 minutes)

**In Xcode:**

1. **File → New → File → StoreKit Configuration File**
2. Name it: `Rounds.storekit`
3. Add your 3 products matching App Store Connect:
   ```
   - monthly: $4.99/month subscription
   - yearly: $39.99/year subscription
   - lifetime: $99.99 non-consumable
   ```
4. **Edit Scheme → Run → Options → StoreKit Configuration**
5. Select: `Rounds.storekit`

This allows testing without real purchases!

#### 5. Test Your Integration (10 minutes)

##### A. Build and Run

The app should:
1. ✅ Launch without errors
2. ✅ Initialize RevenueCat (check console logs)
3. ✅ Load customer info

##### B. Test Paywall

Add this to any view to test:
```swift
Button("Show Paywall") {
    showPaywall = true
}
.sheet(isPresented: $showPaywall) {
    PaywallView()
}
```

##### C. Test Purchase Flow

With StoreKit Configuration:
1. Tap to show paywall
2. Select a product
3. Tap purchase
4. Confirm in popup (no password needed)
5. Verify pro access is granted

##### D. Test Feature Gating

Use `ProFeatureExamples.swift`:
```swift
if SubscriptionManager.shared.hasProAccess() {
    // Show pro feature
} else {
    // Show paywall or lock
}
```

#### 6. Test with Sandbox Account (5 minutes)

**On Device:**
1. Go to **Settings → App Store → Sandbox Account**
2. Sign in with a test Apple ID from App Store Connect
3. Run app and make test purchase
4. Verify purchase works end-to-end

#### 7. Production Checklist

Before releasing:

```
□ Replace test API key with production key in SubscriptionManager.swift
  - Go to RevenueCat Dashboard → API Keys
  - Use: appl_xxxxxxxxxxxxxxxxxxxxxxxx (not test_xxx)

□ Verify all 3 products appear in paywall

□ Test purchase flow on physical device

□ Test restore purchases

□ Test Customer Center (subscription management)

□ Add privacy policy and terms links to paywall

□ Test subscription cancellation flow

□ Verify analytics in RevenueCat Dashboard

□ Set up webhooks (optional but recommended)
  - Dashboard → Integrations → Webhooks

□ Test with multiple subscription states:
  - New user (free)
  - Active monthly subscriber
  - Active yearly subscriber
  - Lifetime purchaser
  - Expired subscription

□ Verify offline behavior (should still show pro features if entitled)
```

---

## 🎯 Common Usage Examples

### Show Paywall
```swift
import RevenueCatUI

struct ContentView: View {
    @State private var showPaywall = false
    
    var body: some View {
        Button("Upgrade to Pro") {
            showPaywall = true
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}
```

### Check Pro Access
```swift
if SubscriptionManager.shared.hasProAccess() {
    // Unlock feature
} else {
    // Show lock or paywall
}
```

### Feature Gate with Lock
```swift
Button {
    if SubscriptionManager.shared.hasProAccess() {
        // Access feature
        openAdvancedStats()
    } else {
        // Show paywall
        showPaywall = true
    }
} label: {
    HStack {
        Text("Advanced Stats")
        if !SubscriptionManager.shared.hasProAccess() {
            Image(systemName: "lock.fill")
                .foregroundStyle(.yellow)
        }
    }
}
```

### Show Customer Center
```swift
import RevenueCatUI

.sheet(isPresented: $showingSettings) {
    CustomerCenterView()
}
```

### Restore Purchases
```swift
Button("Restore Purchases") {
    Task {
        try? await SubscriptionManager.shared.restorePurchases()
    }
}
```

---

## 🐛 Troubleshooting

### "No offerings found"
- ✅ Check products exist in RevenueCat Dashboard
- ✅ Verify offering is configured
- ✅ Check API key is correct
- ✅ Wait a few minutes after creating products

### "Invalid product identifiers"
- ✅ Product IDs must match exactly between:
  - App Store Connect
  - RevenueCat Dashboard
  - Your code
- ✅ Check for typos
- ✅ Verify products are "Ready to Submit" in App Store Connect

### Purchases not working
- ✅ Use StoreKit Configuration for local testing
- ✅ Use Sandbox account on device
- ✅ Check console for error messages
- ✅ Verify RevenueCat SDK is initialized before purchase

### Customer info not updating
- ✅ Check delegate is set: `Purchases.shared.delegate = self`
- ✅ Manually refresh: `await subscriptionManager.refreshCustomerInfo()`
- ✅ Check network connection

---

## 📚 Resources

- **RevenueCat Docs:** https://www.revenuecat.com/docs
- **Paywalls:** https://www.revenuecat.com/docs/tools/paywalls
- **Customer Center:** https://www.revenuecat.com/docs/tools/customer-center
- **Dashboard:** https://app.revenuecat.com
- **Community:** https://community.revenuecat.com
- **Sample Apps:** https://github.com/RevenueCat/purchases-ios

---

## 🎉 You're Ready!

Your code is already set up correctly. Just need to:
1. Install the package
2. Configure Dashboard
3. Set up App Store Connect
4. Test!

All the infrastructure is ready to go! 🚀
