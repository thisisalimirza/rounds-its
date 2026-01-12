//
//  RevenueCatIntegrationGuide.swift
//  Rounds
//
//  Created by Ali Mirza on 1/11/26.
//

/*
 
 REVENUECAT INTEGRATION GUIDE FOR ROUNDS
 ========================================
 
 This guide shows you how to use the RevenueCat integration throughout your app.
 
 ## SETUP COMPLETED ✅
 
 1. RevenueCat SDK installed via Swift Package Manager
 2. SubscriptionManager configured with API key: test_dDeBAeUiVPFXqkYLYBpRccJBmWC
 3. Entitlement ID: "Rounds Pro"
 4. Products configured: monthly, yearly, lifetime
 
 ## USAGE EXAMPLES
 
 ### 1. Check if User Has Pro Access
 
 ```swift
 import SwiftUI
 
 struct SomeView: View {
     @StateObject private var subscriptionManager = SubscriptionManager.shared
     
     var body: some View {
         if subscriptionManager.hasProAccess() {
             Text("Welcome, Pro User! 👑")
         } else {
             Text("Upgrade to Pro for more features")
         }
     }
 }
 ```
 
 ### 2. Gate a Feature Behind Pro Subscription
 
 ```swift
 import SwiftUI
 
 struct FeatureView: View {
     @State private var showingPaywall = false
     @StateObject private var subscriptionManager = SubscriptionManager.shared
     
     var body: some View {
         Button("Access Pro Feature") {
             if subscriptionManager.hasProAccess() {
                 // Allow access
                 performProFeature()
             } else {
                 // Show paywall
                 showingPaywall = true
             }
         }
         .sheet(isPresented: $showingPaywall) {
             PaywallView()
         }
     }
     
     func performProFeature() {
         print("Pro feature accessed!")
     }
 }
 ```
 
 ### 3. Use ProGatedButton Helper
 
 ```swift
 import SwiftUI
 
 struct MyView: View {
     var body: some View {
         ProGatedButton {
             // This only runs if user has Pro
             unlockAdvancedStats()
         } label: {
             Label("Advanced Stats", systemImage: "chart.line.uptrend.xyaxis")
         }
     }
 }
 ```
 
 ### 4. Show Different Content for Pro vs Free Users
 
 ```swift
 import SwiftUI
 
 struct StatsView: View {
     var body: some View {
         ProContentView {
             // Pro content
             DetailedStatsView()
         } placeholder: {
             // Free user content
             VStack {
                 Text("Upgrade to Pro")
                 ProBadge()
             }
         }
     }
 }
 ```
 
 ### 5. Add Pro Badge to Features
 
 ```swift
 import SwiftUI
 
 struct FeatureList: View {
     var body: some View {
         List {
             HStack {
                 Text("Unlimited Cases")
                 Spacer()
                 ProBadge()
             }
             
             HStack {
                 Text("Offline Mode")
                 Spacer()
                 ProBadge()
             }
         }
     }
 }
 ```
 
 ### 6. Show Paywall Directly
 
 ```swift
 import SwiftUI
 
 struct ContentView: View {
     @State private var showingPaywall = false
     
     var body: some View {
         Button("Upgrade to Pro") {
             showingPaywall = true
         }
         .sheet(isPresented: $showingPaywall) {
             // Use RevenueCat's pre-built paywall
             PaywallView()
             
             // OR use custom paywall
             // CustomPaywallView()
         }
     }
 }
 ```
 
 ### 7. Show Subscription Settings
 
 ```swift
 import SwiftUI
 
 struct SettingsView: View {
     @State private var showingSubscription = false
     
     var body: some View {
         Button("Manage Subscription") {
             showingSubscription = true
         }
         .sheet(isPresented: $showingSubscription) {
             // Use RevenueCat's Customer Center
             SubscriptionSettingsView()
             
             // OR use custom settings
             // CustomSubscriptionSettingsView()
         }
     }
 }
 ```
 
 ### 8. Restore Purchases
 
 ```swift
 import SwiftUI
 
 struct RestoreView: View {
     @StateObject private var subscriptionManager = SubscriptionManager.shared
     @State private var isRestoring = false
     
     var body: some View {
         Button("Restore Purchases") {
             Task {
                 isRestoring = true
                 defer { isRestoring = false }
                 
                 do {
                     _ = try await subscriptionManager.restorePurchases()
                     print("Restore successful!")
                 } catch {
                     print("Restore failed: \(error)")
                 }
             }
         }
         .disabled(isRestoring)
     }
 }
 ```
 
 ### 9. Check Subscription Details
 
 ```swift
 import SwiftUI
 
 struct SubscriptionDetailsView: View {
     @StateObject private var subscriptionManager = SubscriptionManager.shared
     
     var body: some View {
         VStack(alignment: .leading, spacing: 12) {
             Text("Subscription Status")
                 .font(.headline)
             
             Text("Type: \(subscriptionManager.subscriptionStatus.displayName)")
             
             if let expirationDate = subscriptionManager.getExpirationDate() {
                 if subscriptionManager.willRenew() {
                     Text("Renews: \(expirationDate, style: .date)")
                 } else {
                     Text("Expires: \(expirationDate, style: .date)")
                 }
             }
             
             if let period = subscriptionManager.getSubscriptionPeriod() {
                 Text("Period: \(period)")
             }
         }
     }
 }
 ```
 
 ## REVENUECAT DASHBOARD SETUP
 
 ### Step 1: Configure Products in App Store Connect
 
 1. Go to App Store Connect
 2. Navigate to your app → In-App Purchases
 3. Create three products:
    - Monthly Auto-Renewable Subscription
      - Product ID: `monthly`
      - Display Name: "Rounds Pro Monthly"
      - Price: $4.99/month (or your choice)
    
    - Yearly Auto-Renewable Subscription
      - Product ID: `yearly`
      - Display Name: "Rounds Pro Yearly"
      - Price: $39.99/year (or your choice)
    
    - Non-Consumable (for Lifetime)
      - Product ID: `lifetime`
      - Display Name: "Rounds Pro Lifetime"
      - Price: $99.99 (or your choice)
 
 ### Step 2: Configure RevenueCat Dashboard
 
 1. Go to https://app.revenuecat.com
 2. Navigate to your project
 3. Go to **Products** → Add the three products from App Store Connect
 4. Go to **Entitlements** → Create entitlement "Rounds Pro"
 5. Attach all three products to the "Rounds Pro" entitlement
 6. Go to **Offerings** → Create "Default" offering
 7. Add packages:
    - Monthly package → monthly product
    - Yearly package → yearly product
    - Lifetime package → lifetime product
 
 ### Step 3: Configure Paywalls (Optional)
 
 1. In RevenueCat Dashboard, go to **Paywalls**
 2. Create a new paywall template
 3. Customize colors, images, and text
 4. The PaywallView() in the app will automatically use this design
 
 ### Step 4: Test with Sandbox
 
 1. Create a sandbox test user in App Store Connect
 2. Sign out of App Store on your device
 3. Run your app and test purchases
 4. Sandbox purchases will show up in RevenueCat dashboard
 
 ## IMPORTANT NOTES
 
 - **API Key**: Currently using test key. Replace with production key before release.
 - **Entitlement**: Must match exactly "Rounds Pro" in RevenueCat dashboard.
 - **Product IDs**: Must match App Store Connect product identifiers.
 - **Testing**: Use sandbox environment for testing, then switch to production.
 
 ## BEST PRACTICES
 
 1. Always check subscription status on app launch (done in RoundsApp.swift)
 2. Handle errors gracefully when purchases fail
 3. Provide clear restore purchases option
 4. Show subscription status in settings
 5. Use Customer Center for easy subscription management
 6. Test all purchase flows before release
 7. Monitor RevenueCat dashboard for subscription metrics
 
 ## NEXT STEPS
 
 1. ✅ Install RevenueCat SDK
 2. ✅ Configure with API key
 3. ✅ Set up subscription manager
 4. ✅ Create paywall views
 5. ✅ Add subscription settings
 6. ✅ Integrate into app
 7. ⏳ Configure products in App Store Connect
 8. ⏳ Set up entitlements in RevenueCat dashboard
 9. ⏳ Test purchases in sandbox
 10. ⏳ Replace test API key with production key
 11. ⏳ Submit for App Review
 
 */

// This file is for documentation only - no executable code needed
