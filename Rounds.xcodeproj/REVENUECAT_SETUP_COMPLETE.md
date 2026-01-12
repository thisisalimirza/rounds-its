# RevenueCat Integration - Complete Setup Guide

## ✅ What's Been Done

Your Rounds app now has a complete RevenueCat integration with the following components:

### Files Created:

1. **SubscriptionManager.swift** - Core subscription management
   - Handles all RevenueCat operations
   - Tracks subscription status
   - Manages customer info
   - Checks Pro entitlement access

2. **PaywallView.swift** - Subscription purchase UI
   - Pre-built RevenueCat paywall (recommended)
   - Custom paywall alternative
   - Package selection and purchase flow
   - Restore purchases functionality

3. **SubscriptionSettingsView.swift** - Subscription management
   - RevenueCat Customer Center integration
   - Custom settings view alternative
   - Subscription details display
   - Cancel/manage subscription links

4. **ProFeatureGate.swift** - Helper views and modifiers
   - `ProGatedButton` - Button that shows paywall if not Pro
   - `ProContentView` - Show different content based on subscription
   - `ProBadge` - Visual indicator for Pro features
   - `requiresProSubscription` modifier

5. **ProFeatureExamples.swift** - Real-world usage examples
   - Case selection with Pro limits
   - Statistics gating
   - Daily case limits
   - Promo banners
   - Settings integration

6. **RevenueCatIntegrationGuide.swift** - Complete documentation

### Files Modified:

1. **RoundsApp.swift**
   - Added RevenueCat configuration on app launch
   - Added SubscriptionManager as environment object

2. **AboutView.swift**
   - Added subscription management button
   - Shows upgrade prompt for free users
   - Shows current plan for Pro users

## 🔑 Configuration Details

- **API Key**: `test_dDeBAeUiVPFXqkYLYBpRccJBmWC` (Replace with production key before release)
- **Entitlement ID**: `Rounds Pro`
- **Products**:
  - `monthly` - Monthly subscription
  - `yearly` - Yearly subscription (marked as popular)
  - `lifetime` - Lifetime purchase

## 📋 Next Steps

### 1. Install RevenueCat SDK

In Xcode:
1. **File → Add Package Dependencies**
2. Paste URL: `https://github.com/RevenueCat/purchases-ios-spm.git`
3. Select version: **5.0.0** or later
4. Add both targets:
   - ✅ **RevenueCat**
   - ✅ **RevenueCatUI**

### 2. Configure App Store Connect

Create three in-app purchases:

#### Monthly Subscription
- Type: Auto-Renewable Subscription
- Product ID: `monthly`
- Display Name: "Rounds Pro Monthly"
- Suggested Price: $4.99/month

#### Yearly Subscription
- Type: Auto-Renewable Subscription
- Product ID: `yearly`
- Display Name: "Rounds Pro Yearly"
- Suggested Price: $39.99/year

#### Lifetime Purchase
- Type: Non-Consumable
- Product ID: `lifetime`
- Display Name: "Rounds Pro Lifetime"
- Suggested Price: $99.99

### 3. Configure RevenueCat Dashboard

Visit: https://app.revenuecat.com

#### A. Add Products
1. Go to **Products** section
2. Connect to App Store Connect
3. Import all three products

#### B. Create Entitlement
1. Go to **Entitlements**
2. Create new: `Rounds Pro`
3. Attach all three products to this entitlement

#### C. Set Up Offerings
1. Go to **Offerings**
2. Create "Default" offering
3. Add packages:
   - Monthly → monthly product
   - Yearly → yearly product (set as default)
   - Lifetime → lifetime product

#### D. Configure Paywalls (Optional)
1. Go to **Paywalls**
2. Create custom design
3. Set colors, images, text
4. The PaywallView() will automatically use it

### 4. Replace Test API Key

Before production release:

1. In RevenueCat dashboard, go to **API Keys**
2. Copy your **Production API Key**
3. In `SubscriptionManager.swift`, replace:
   ```swift
   private let apiKey = "test_dDeBAeUiVPFXqkYLYBpRccJBmWC" // Test key
   ```
   with:
   ```swift
   private let apiKey = "YOUR_PRODUCTION_API_KEY_HERE"
   ```

### 5. Test Purchases

#### Sandbox Testing:
1. Create sandbox test user in App Store Connect
2. Sign out of App Store on device
3. Run app and test purchases
4. Check RevenueCat dashboard for transactions

#### Test Scenarios:
- ✅ Purchase monthly subscription
- ✅ Purchase yearly subscription
- ✅ Purchase lifetime
- ✅ Restore purchases
- ✅ Cancel subscription (in Settings)
- ✅ Verify Pro features unlock
- ✅ Verify free tier limitations

## 🎯 How to Use in Your App

### Quick Examples:

#### Check Pro Access
```swift
if SubscriptionManager.shared.hasProAccess() {
    // User has Pro
} else {
    // Show paywall or limit features
}
```

#### Show Paywall
```swift
@State private var showingPaywall = false

Button("Upgrade") {
    showingPaywall = true
}
.sheet(isPresented: $showingPaywall) {
    PaywallView()
}
```

#### Gate a Button
```swift
ProGatedButton {
    unlockProFeature()
} label: {
    Label("Pro Feature", systemImage: "star.fill")
}
```

#### Add Pro Badge
```swift
HStack {
    Text("Advanced Statistics")
    ProBadge()
}
```

#### Show Subscription Settings
```swift
@State private var showingSettings = false

Button("Manage Subscription") {
    showingSettings = true
}
.sheet(isPresented: $showingSettings) {
    SubscriptionSettingsView()
}
```

## 💡 Recommended Features to Gate

Based on your app, consider making these Pro-only:

1. **Unlimited Cases**
   - Free: 5 cases per day
   - Pro: Unlimited

2. **Advanced Statistics**
   - Free: Basic stats
   - Pro: Detailed analytics, trends, category breakdowns

3. **Offline Access**
   - Free: Online only
   - Pro: Download cases for offline study

4. **No Ads** (if you add ads later)
   - Free: Shows ads
   - Pro: Ad-free experience

5. **Custom Study Lists**
   - Free: Default lists
   - Pro: Create custom case collections

6. **Priority Support**
   - Free: Community support
   - Pro: Direct email support

7. **Early Access**
   - Free: Standard release
   - Pro: Beta features and new cases first

## 🐛 Troubleshooting

### "Purchases not showing up"
- Check product IDs match exactly
- Verify products are approved in App Store Connect
- Wait 24 hours after creating products
- Clear derived data and rebuild

### "Entitlement not active"
- Verify entitlement name is exactly "Rounds Pro"
- Check products are attached to entitlement in RevenueCat
- Refresh customer info: `await subscriptionManager.refreshCustomerInfo()`

### "Paywall not displaying"
- Ensure RevenueCatUI package is imported
- Check offering is configured in dashboard
- Verify at least one package exists in offering

### "Sandbox purchases failing"
- Sign out of App Store completely
- Delete and reinstall app
- Check sandbox account is valid
- Verify internet connection

## 📊 Monitor Your Subscriptions

RevenueCat Dashboard provides:
- Real-time subscription metrics
- Revenue tracking
- Churn analysis
- Cohort analysis
- Active subscriptions
- Trial conversions

Visit: https://app.revenuecat.com/charts

## 🚀 Production Checklist

Before submitting to App Store:

- [ ] Install RevenueCat SDK via SPM
- [ ] Create products in App Store Connect
- [ ] Configure entitlements in RevenueCat
- [ ] Set up offerings and packages
- [ ] Replace test API key with production key
- [ ] Test all purchase flows in sandbox
- [ ] Test restore purchases
- [ ] Test subscription management
- [ ] Add subscription details to App Store listing
- [ ] Review App Store subscription guidelines
- [ ] Test on multiple devices
- [ ] Verify analytics are tracking correctly

## 📱 App Store Review Notes

When submitting, include in Review Notes:

```
SUBSCRIPTION TESTING INSTRUCTIONS:

We use RevenueCat for subscription management.

Test Accounts:
- Use the sandbox test account provided

Available Subscriptions:
1. Rounds Pro Monthly - $X.XX/month
2. Rounds Pro Yearly - $XX.XX/year  
3. Rounds Pro Lifetime - $XX.XX (one-time)

How to Test:
1. Launch app
2. Tap "Upgrade to Pro" or "About" → "Upgrade to Pro"
3. Select subscription plan
4. Complete purchase with sandbox account
5. Verify Pro features unlock (unlimited cases, advanced stats)

To test subscription management:
1. Go to About → Manage Subscription
2. View subscription details
3. Access Customer Center for management options

Restore Purchases:
- Available in subscription settings
- Tests restoring previous purchases
```

## 🎓 Additional Resources

- [RevenueCat Documentation](https://www.revenuecat.com/docs)
- [RevenueCat Paywalls](https://www.revenuecat.com/docs/tools/paywalls)
- [Customer Center](https://www.revenuecat.com/docs/tools/customer-center)
- [iOS SDK Reference](https://sdk.revenuecat.com/ios/index.html)
- [Best Practices](https://www.revenuecat.com/docs/getting-started/quickstart)

## 💬 Support

If you need help:
- RevenueCat: support@revenuecat.com
- RevenueCat Community: https://community.revenuecat.com

---

**Your app is now fully integrated with RevenueCat! 🎉**

Just complete the setup steps above and you'll be ready to start monetizing Rounds!
