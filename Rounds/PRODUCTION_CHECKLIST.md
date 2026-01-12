# 🚀 Production Release Checklist for RevenueCat

Use this checklist before releasing your app to the App Store.

---

## Pre-Release Checklist

### 🔑 API Configuration

- [ ] **Replace test API key with production key**
  ```swift
  // In SubscriptionManager.swift, line ~29
  private let apiKey = "appl_xxxxxxxxxxxxxxxxxxxxxxxx" // Production key
  ```
  - Get from: https://app.revenuecat.com → Project Settings → API Keys
  - Use the key that starts with `appl_` (not `test_`)

- [ ] **Verify correct entitlement ID**
  ```swift
  private let proEntitlementID = "Rounds Pro"
  ```
  - Must match exactly with RevenueCat Dashboard

- [ ] **Disable debug logging in production**
  ```swift
  #if DEBUG
  Purchases.logLevel = .debug
  #else
  Purchases.logLevel = .error  // ✅ Only errors in production
  #endif
  ```

---

### 🏪 App Store Connect

- [ ] **All 3 in-app purchases created**
  - [ ] `monthly` - Auto-renewable subscription (1 month)
  - [ ] `yearly` - Auto-renewable subscription (1 year)
  - [ ] `lifetime` - Non-consumable purchase

- [ ] **Product IDs match exactly**
  - RevenueCat Dashboard ↔️ App Store Connect ↔️ Your code

- [ ] **Prices set for all regions**
  - Primary storefront: United States
  - Enable all relevant countries

- [ ] **Localizations added**
  - [ ] English (required)
  - [ ] Additional languages as needed

- [ ] **Subscription group configured** (for monthly/yearly)
  - Name: "Rounds Pro Subscriptions"
  - Upgrade/downgrade paths set

- [ ] **Products submitted for review**
  - Status: "Ready to Submit" or "Approved"
  - Note: Can test while "Waiting for Review"

- [ ] **App metadata includes subscription info**
  - Auto-renewable subscriptions listed
  - Prices shown
  - Billing terms clear

---

### 🎛️ RevenueCat Dashboard

- [ ] **All products configured**
  - [ ] `monthly` → App Store → Product added
  - [ ] `yearly` → App Store → Product added
  - [ ] `lifetime` → App Store → Product added

- [ ] **Entitlement created**
  - [ ] Name: "Rounds Pro"
  - [ ] All 3 products attached

- [ ] **Offering configured**
  - [ ] Identifier: `default`
  - [ ] All 3 packages added
  - [ ] Default package: `yearly` (recommended)

- [ ] **Paywall designed** (optional but recommended)
  - [ ] Template selected
  - [ ] Customized with branding
  - [ ] Features listed
  - [ ] Attached to offering

- [ ] **Webhooks configured** (optional)
  - For backend integrations
  - URL: Your server endpoint

- [ ] **Production API key generated**
  - Separate from test key
  - Starts with `appl_`

---

### 🧪 Testing

#### On Simulator (StoreKit Configuration)

- [ ] **StoreKit Configuration file created**
  - File → New → StoreKit Configuration File
  - All 3 products added

- [ ] **Test purchase flows**
  - [ ] Monthly subscription works
  - [ ] Yearly subscription works
  - [ ] Lifetime purchase works
  - [ ] Restore purchases works

- [ ] **Test feature gating**
  - [ ] Free users see limits
  - [ ] Pro users have unlimited access
  - [ ] Locked features show paywall

- [ ] **Test UI**
  - [ ] Paywall displays correctly
  - [ ] Customer Center works
  - [ ] Settings integration works
  - [ ] Pro badges appear

#### On Physical Device (Sandbox)

- [ ] **Sandbox account created**
  - App Store Connect → Users and Access → Sandbox Testers
  - Different email from your real Apple ID

- [ ] **Device configured**
  - Settings → App Store → Sandbox Account
  - Signed in with test account

- [ ] **Test all purchase types**
  - [ ] Monthly subscription
  - [ ] Yearly subscription
  - [ ] Lifetime purchase
  - [ ] Restore purchases
  - [ ] Subscription management

- [ ] **Test subscription lifecycle**
  - [ ] Purchase subscription
  - [ ] Verify pro access granted
  - [ ] Cancel subscription
  - [ ] Verify access continues until expiration
  - [ ] Verify access removed after expiration
  - [ ] Restore subscription
  - [ ] Verify pro access restored

- [ ] **Test edge cases**
  - [ ] No internet connection
  - [ ] Slow network
  - [ ] Purchase cancellation
  - [ ] Invalid product
  - [ ] App restart with active subscription

#### TestFlight Testing

- [ ] **Upload build to TestFlight**
  - Archive → Distribute → App Store Connect
  - Process takes 5-30 minutes

- [ ] **Test with real App Store environment**
  - Uses production StoreKit
  - Tests real purchase flow
  - Verifies receipt validation

- [ ] **Recruit beta testers**
  - Internal testers (fast approval)
  - External testers (requires review)

- [ ] **Monitor feedback**
  - Check crash reports
  - Watch for purchase issues
  - Verify all flows work

---

### 📱 App Features

- [ ] **Feature gates implemented**
  - [ ] Case limits (5 free, unlimited pro)
  - [ ] Daily limits (3 per day free, unlimited pro)
  - [ ] Advanced statistics (pro only)
  - [ ] Any other pro features

- [ ] **Paywall triggered correctly**
  - [ ] First access to pro feature
  - [ ] After free limits reached
  - [ ] From settings menu
  - [ ] Not too frequently (avoid spam)

- [ ] **Pro badges visible**
  - [ ] On locked features
  - [ ] In settings
  - [ ] On promotional banners

- [ ] **Subscription status shown**
  - [ ] In settings
  - [ ] On profile/account screen
  - [ ] Current plan displayed
  - [ ] Expiration date shown (if applicable)

---

### 📄 Legal & Privacy

- [ ] **Privacy Policy updated**
  - [ ] Mentions subscription data collection
  - [ ] RevenueCat privacy policy linked
  - [ ] Clear about what data is collected

- [ ] **Terms of Service updated**
  - [ ] Subscription terms clear
  - [ ] Auto-renewal explained
  - [ ] Cancellation policy stated
  - [ ] Refund policy explained

- [ ] **In-app links added**
  - [ ] Privacy Policy link in paywall
  - [ ] Terms of Service link in paywall
  - [ ] Support email/contact

- [ ] **App Store metadata**
  - [ ] Privacy nutrition labels updated
  - [ ] Subscription terms in description
  - [ ] Features clearly explained

---

### 📊 Analytics

- [ ] **Analytics events tracked** (optional but recommended)
  - [ ] Paywall presented
  - [ ] Purchase started
  - [ ] Purchase completed
  - [ ] Purchase failed
  - [ ] Restore attempted
  - [ ] Feature gate encountered

- [ ] **RevenueCat Charts configured**
  - Dashboard → Charts
  - Monitor key metrics:
    - MRR (Monthly Recurring Revenue)
    - Active subscribers
    - Conversion rate
    - Churn rate

- [ ] **Custom attributes set** (optional)
  ```swift
  Purchases.shared.attribution.setAttributes([
      "specialty": "cardiology",
      "user_level": "student"
  ])
  ```

---

### 🛠️ Support Infrastructure

- [ ] **Support email set up**
  - Listed in App Store
  - Listed in app settings
  - Ready to respond to subscription questions

- [ ] **FAQ prepared**
  - How to subscribe
  - How to cancel
  - How to restore
  - Refund policy
  - Feature comparisons

- [ ] **RevenueCat Customer Center tested**
  - Subscription management works
  - Cancel flow tested
  - Billing info accessible

---

### 🔍 Code Review

- [ ] **Remove test/debug code**
  - No hardcoded test users
  - No debug print statements in production paths
  - No test mode flags enabled

- [ ] **Error handling implemented**
  - All purchase errors handled
  - User-friendly error messages
  - Network errors handled gracefully

- [ ] **Offline support verified**
  - Cached entitlements work
  - App doesn't crash without network
  - Pro features accessible offline

- [ ] **No force unwrapping**
  - All optionals safely unwrapped
  - No `!` operators that could crash

- [ ] **Memory leaks checked**
  - Retain cycles resolved
  - StateObjects used correctly
  - Delegates weakly referenced

---

### 📸 App Store Screenshots

- [ ] **Show subscription value**
  - Features available in Pro
  - Clear before/after comparison

- [ ] **Paywall screenshot** (optional)
  - Shows pricing
  - Shows features
  - Looks professional

---

### 🚦 Final Pre-Launch Checks

- [ ] **Build in Release mode**
  - Product → Scheme → Edit Scheme → Run → Release
  - Tests real performance
  - Verifies production API key

- [ ] **Test on multiple devices**
  - [ ] iPhone (various sizes)
  - [ ] iPad (if supported)
  - [ ] Different iOS versions

- [ ] **Test all iOS versions you support**
  - Minimum: iOS 15 (for RevenueCatUI)
  - Test on oldest supported version

- [ ] **Archive and validate**
  - Product → Archive
  - Validate App (checks for errors)
  - Resolve any warnings

- [ ] **Upload to App Store**
  - Distribute → App Store Connect
  - Wait for processing

- [ ] **Submit for review**
  - Add review notes about subscriptions
  - Mention test account if needed
  - Submit!

---

### 📈 Post-Launch Monitoring

#### Week 1:
- [ ] Monitor RevenueCat Dashboard daily
  - Check active subscriptions
  - Watch for failed charges
  - Monitor conversion rate

- [ ] Check App Store reviews
  - Respond to subscription questions
  - Address any confusion

- [ ] Monitor crash reports
  - Watch for purchase-related crashes
  - Fix issues quickly

#### Ongoing:
- [ ] Weekly analytics review
- [ ] Monthly revenue analysis
- [ ] Quarterly price optimization
- [ ] Regular A/B testing of paywalls

---

## ✅ Ready to Launch

When all checkboxes are complete:

1. ✅ Archive your app
2. ✅ Upload to App Store Connect
3. ✅ Submit for review
4. ✅ Wait for approval
5. ✅ Release to users!

---

## 🎉 You're Ready!

This checklist ensures your RevenueCat integration is production-ready and follows best practices.

**Good luck with your launch!** 🚀

---

## 📞 Need Help?

- **RevenueCat Support:** support@revenuecat.com
- **Documentation:** https://www.revenuecat.com/docs
- **Community:** https://community.revenuecat.com
- **Dashboard:** https://app.revenuecat.com

---

**Last Updated:** January 11, 2026
