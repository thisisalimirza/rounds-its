//
//  RevenueCatQuickReference.swift
//  Rounds
//
//  Created by Ali Mirza on 1/11/26.
//

/*
 
 ╔══════════════════════════════════════════════════════════════╗
 ║              REVENUECAT QUICK REFERENCE CARD                 ║
 ╚══════════════════════════════════════════════════════════════╝
 
 
 ┌─────────────────────────────────────────────────────────────┐
 │ COMMON TASKS                                                │
 └─────────────────────────────────────────────────────────────┘
 
 ✅ Check if user has Pro:
    SubscriptionManager.shared.hasProAccess()
 
 ✅ Show paywall:
    .sheet(isPresented: $showPaywall) { PaywallView() }
 
 ✅ Restore purchases:
    try await SubscriptionManager.shared.restorePurchases()
 
 ✅ Get subscription status:
    SubscriptionManager.shared.subscriptionStatus
 
 ✅ Check expiration date:
    SubscriptionManager.shared.getExpirationDate()
 
 ✅ Check if will renew:
    SubscriptionManager.shared.willRenew()
 
 
 ┌─────────────────────────────────────────────────────────────┐
 │ HELPER VIEWS                                                │
 └─────────────────────────────────────────────────────────────┘
 
 🔒 Pro-Gated Button:
    ProGatedButton { action() } label: { Text("Feature") }
 
 👑 Pro Badge:
    ProBadge()
 
 📊 Conditional Content:
    ProContentView {
        /* Pro content */
    } placeholder: {
        /* Free content */
    }
 
 💳 Subscription Settings:
    SubscriptionSettingsView()
 
 💰 Paywall:
    PaywallView()
 
 
 ┌─────────────────────────────────────────────────────────────┐
 │ CONFIGURATION                                               │
 └─────────────────────────────────────────────────────────────┘
 
 API Key: test_dDeBAeUiVPFXqkYLYBpRccJBmWC
 Entitlement: Rounds Pro
 
 Products:
   - monthly   (Auto-renewable monthly)
   - yearly    (Auto-renewable yearly)
   - lifetime  (Non-consumable)
 
 
 ┌─────────────────────────────────────────────────────────────┐
 │ TYPICAL USAGE PATTERNS                                      │
 └─────────────────────────────────────────────────────────────┘
 
 Pattern 1: Feature Gate
 ───────────────────────
 if SubscriptionManager.shared.hasProAccess() {
     // Allow feature
 } else {
     showPaywall = true
 }
 
 
 Pattern 2: Settings Integration
 ────────────────────────────────
 Button("Manage Subscription") {
     showSubscription = true
 }
 .sheet(isPresented: $showSubscription) {
     if SubscriptionManager.shared.isProSubscriber {
         SubscriptionSettingsView()
     } else {
         PaywallView()
     }
 }
 
 
 Pattern 3: Daily Limits
 ────────────────────────
 func canPlay() -> Bool {
     SubscriptionManager.shared.hasProAccess() || 
     dailyPlays < 3
 }
 
 
 Pattern 4: Pro Upgrade Prompt
 ──────────────────────────────
 if !SubscriptionManager.shared.isProSubscriber {
     Button("Upgrade to Pro") {
         showPaywall = true
     }
 }
 
 
 ┌─────────────────────────────────────────────────────────────┐
 │ SUBSCRIPTION STATUS ENUM                                    │
 └─────────────────────────────────────────────────────────────┘
 
 .free      → "Free"
 .monthly   → "Pro (Monthly)"
 .yearly    → "Pro (Yearly)"
 .lifetime  → "Pro (Lifetime)"
 
 Access via:
 SubscriptionManager.shared.subscriptionStatus.displayName
 
 
 ┌─────────────────────────────────────────────────────────────┐
 │ COMMON PITFALLS                                             │
 └─────────────────────────────────────────────────────────────┘
 
 ❌ Don't hardcode Pro status - always check dynamically
 ❌ Don't forget to handle purchase errors
 ❌ Don't block restore purchases behind paywall
 ❌ Don't forget to replace test API key for production
 ❌ Don't use different entitlement names
 
 ✅ Always use SubscriptionManager.shared.hasProAccess()
 ✅ Wrap purchases in try/catch
 ✅ Provide visible restore button
 ✅ Update API key before App Store submission
 ✅ Use exact entitlement: "Rounds Pro"
 
 
 ┌─────────────────────────────────────────────────────────────┐
 │ TESTING CHECKLIST                                           │
 └─────────────────────────────────────────────────────────────┘
 
 Before Release:
 □ Test purchase monthly
 □ Test purchase yearly
 □ Test purchase lifetime
 □ Test restore purchases
 □ Test subscription cancellation
 □ Test reactivation
 □ Test on fresh install
 □ Test with sandbox account
 □ Verify Pro features unlock
 □ Verify free tier limits work
 □ Replace test API key
 □ Test Customer Center
 □ Verify paywall displays correctly
 
 
 ┌─────────────────────────────────────────────────────────────┐
 │ FILES IN THIS PROJECT                                       │
 └─────────────────────────────────────────────────────────────┘
 
 Core:
   ✓ SubscriptionManager.swift        - Subscription logic
   ✓ PaywallView.swift                - Purchase UI
   ✓ SubscriptionSettingsView.swift   - Management UI
   ✓ ProFeatureGate.swift             - Helper views
 
 Examples:
   ✓ ProFeatureExamples.swift         - Usage examples
   ✓ GameFlowWithSubscription.swift   - Game integration
 
 Docs:
   ✓ RevenueCatIntegrationGuide.swift - Full guide
   ✓ REVENUECAT_SETUP_COMPLETE.md     - Setup instructions
   ✓ RevenueCatQuickReference.swift   - This file
 
 Modified:
   ✓ RoundsApp.swift                  - App initialization
   ✓ AboutView.swift                  - Settings integration
 
 
 ┌─────────────────────────────────────────────────────────────┐
 │ USEFUL LINKS                                                │
 └─────────────────────────────────────────────────────────────┘
 
 📚 RevenueCat Docs:     revenuecat.com/docs
 🎨 Paywalls:            revenuecat.com/docs/tools/paywalls
 👥 Customer Center:     revenuecat.com/docs/tools/customer-center
 📊 Dashboard:           app.revenuecat.com
 💬 Community:           community.revenuecat.com
 📧 Support:             support@revenuecat.com
 
 
 ┌─────────────────────────────────────────────────────────────┐
 │ REVENUE TRACKING                                            │
 └─────────────────────────────────────────────────────────────┘
 
 View in RevenueCat Dashboard:
 - Active subscriptions
 - Monthly recurring revenue (MRR)
 - Annual recurring revenue (ARR)
 - Churn rate
 - Trial conversion rate
 - Revenue by product
 - Customer lifetime value (LTV)
 
 
 ╔══════════════════════════════════════════════════════════════╗
 ║  Need help? Check REVENUECAT_SETUP_COMPLETE.md for details  ║
 ╚══════════════════════════════════════════════════════════════╝
 
 */
