//
//  AnalyticsManager.swift
//  Rounds
//
//  Created for launch tracking
//  Integrated with PostHog Analytics
//

import Foundation
import StoreKit
import UIKit
import PostHog

/// Analytics manager with PostHog integration
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {
        configurePostHog()
    }
    
    // MARK: - PostHog Configuration
    
    private func configurePostHog() {
        let POSTHOG_API_KEY = "phc_NVtFkrQ9hDhm7Th69dTXo8HiTOLtxPrlwPf0biV4Mql"
        let POSTHOG_HOST = "https://us.i.posthog.com"
        
        let config = PostHogConfig(apiKey: POSTHOG_API_KEY, host: POSTHOG_HOST)
        
        #if DEBUG
        config.debug = true
        print("📊 PostHog configured in DEBUG mode")
        #else
        config.debug = false
        #endif
        
        PostHogSDK.shared.setup(config)
    }
    
    // MARK: - Event Tracking
    
    /// Track a custom event
    /// - Parameters:
    ///   - event: Event name (e.g., "case_completed", "daily_streak_continued")
    ///   - properties: Optional properties dictionary
    func track(_ event: String, properties: [String: Any]? = nil) {
        #if DEBUG
        print("📊 Analytics: \(event)")
        if let properties = properties {
            print("   Properties: \(properties)")
        }
        #endif
        
        // Send to PostHog
        PostHogSDK.shared.capture(event, properties: properties)
    }
    
    // MARK: - User Identification
    
    /// Identify user with custom properties
    func identifyUser(userId: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.identify(userId, userProperties: properties)
    }
    
    /// Update user properties without changing user ID
    func setUserProperties(_ properties: [String: Any]) {
        PostHogSDK.shared.identify(PostHogSDK.shared.getDistinctId(), userProperties: properties)
    }
    
    /// Set a single user property
    func setUserProperty(key: String, value: Any) {
        setUserProperties([key: value])
    }
    
    // MARK: - Convenience Methods
    
    func trackAppLaunch() {
        track("app_launched")
    }
    
    func trackCaseStarted(caseID: String, isDaily: Bool) {
        track("case_started", properties: [
            "case_id": caseID,
            "is_daily": isDaily
        ])
    }
    
    func trackCaseCompleted(caseID: String, won: Bool, guesses: Int, hints: Int, score: Int, isDaily: Bool) {
        track("case_completed", properties: [
            "case_id": caseID,
            "won": won,
            "guesses": guesses,
            "hints_used": hints,
            "score": score,
            "is_daily": isDaily
        ])
    }
    
    func trackStreakMilestone(streak: Int) {
        track("streak_milestone", properties: [
            "streak_count": streak
        ])
    }
    
    func trackFeatureUsed(_ feature: String) {
        track("feature_used", properties: [
            "feature": feature
        ])
    }
    
    // MARK: - Subscription Tracking
    
    func trackSubscriptionEvent(_ event: String, productId: String? = nil, properties: [String: Any]? = nil) {
        var mergedProperties = properties ?? [:]
        if let productId = productId {
            mergedProperties["product_id"] = productId
        }
        track(event, properties: mergedProperties.isEmpty ? nil : mergedProperties)
    }
    
    func trackPaywallViewed(source: String) {
        track("paywall_viewed", properties: [
            "source": source
        ])
    }
    
    func trackPurchaseStarted(productId: String) {
        trackSubscriptionEvent("subscription_purchase_started", productId: productId)
    }
    
    func trackPurchaseCompleted(productId: String) {
        trackSubscriptionEvent("subscription_purchase_completed", productId: productId)
    }
    
    func trackPurchaseFailed(productId: String, error: String? = nil) {
        var props: [String: Any] = [:]
        if let error = error {
            props["error"] = error
        }
        trackSubscriptionEvent("subscription_purchase_failed", productId: productId, properties: props)
    }
    
    func trackPurchaseRestored() {
        track("subscription_restored")
    }
    
    // MARK: - Gameplay Tracking
    
    func trackHintRevealed(hintIndex: Int, caseID: String) {
        track("hint_revealed", properties: [
            "hint_index": hintIndex,
            "case_id": caseID
        ])
    }
    
    func trackDiagnosisSubmitted(guess: String, isCorrect: Bool, guessNumber: Int, hintsRevealed: Int, caseID: String, isDaily: Bool) {
        track("diagnosis_submitted", properties: [
            "case_id": caseID,
            "is_correct": isCorrect,
            "guess_number": guessNumber,
            "hints_revealed": hintsRevealed,
            "is_daily": isDaily
        ])
    }
    
    func trackShareResults(won: Bool, score: Int) {
        track("share_results", properties: [
            "won": won,
            "score": score
        ])
    }
    
    func trackOnboardingCompleted() {
        track("onboarding_completed")
    }
    
    func trackOnboardingSkipped(step: Int) {
        track("onboarding_skipped", properties: [
            "step": step
        ])
    }
}

// MARK: - App Store Review Manager

class AppStoreReviewManager {
    static let shared = AppStoreReviewManager()
    
    @UserDefaultsWrapper(key: "gamesCompletedCount", defaultValue: 0)
    private var gamesCompleted: Int
    
    @UserDefaultsWrapper(key: "hasRequestedReview", defaultValue: false)
    private var hasRequestedReview: Bool
    
    @UserDefaultsWrapper(key: "lastReviewRequestDate", defaultValue: nil)
    private var lastReviewRequestDate: Date?
    
    private init() {}
    
    /// Call this after each successful game completion
    @MainActor
    func gameCompleted(won: Bool) {
        guard won else { return } // Only count wins
        gamesCompleted += 1
        
        // Request review after 3 wins or 7 day streak
        if shouldRequestReview() {
            requestReview()
        }
    }
    
    /// Call this when user achieves a milestone streak
    @MainActor
    func streakAchieved(_ streak: Int) {
        if streak >= 7 && shouldRequestReview() {
            requestReview()
        }
    }
    
    private func shouldRequestReview() -> Bool {
        // Don't request if already requested in last 90 days
        if let lastRequest = lastReviewRequestDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastRequest, to: Date()).day ?? 0
            guard daysSince >= 90 else { return false }
        }
        
        // Request after 3 completed games minimum
        return gamesCompleted >= 3
    }
    
    @MainActor
    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            // Use modern AppStore API (iOS 16+)
            AppStore.requestReview(in: scene)
            lastReviewRequestDate = Date()
            hasRequestedReview = true
            
            AnalyticsManager.shared.track("review_prompt_shown")
        }
    }
    
    /// Manually trigger review request (e.g., from Settings)
    @MainActor
    func manualReviewRequest() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            AppStore.requestReview(in: scene)
            AnalyticsManager.shared.track("review_prompt_manual")
        }
    }
}

// MARK: - UserDefaults Property Wrapper

@propertyWrapper
struct UserDefaultsWrapper<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

// MARK: - Session Tracking

@MainActor
class SessionTracker {
    static let shared = SessionTracker()
    
    private var sessionStart: Date?
    
    @UserDefaultsWrapper(key: "totalSessions", defaultValue: 0)
    private var totalSessions: Int
    
    private init() {}
    
    func startSession() {
        sessionStart = Date()
        totalSessions += 1
        
        // Track analytics synchronously since we're already on MainActor
        AnalyticsManager.shared.track("session_started", properties: [
            "session_number": totalSessions
        ])
    }
    
    func endSession() {
        guard let start = sessionStart else { return }
        let duration = Date().timeIntervalSince(start)
        
        // Track analytics synchronously since we're already on MainActor
        AnalyticsManager.shared.track("session_ended", properties: [
            "duration_seconds": Int(duration),
            "session_number": totalSessions
        ])
        
        sessionStart = nil
    }
}

// MARK: - Usage Instructions

/*
 HOW TO USE:
 
 1. In RoundsApp.swift, add to .onAppear:
    AnalyticsManager.shared.trackAppLaunch()
    SessionTracker.shared.startSession()
 
 2. In GameView, when game starts:
    AnalyticsManager.shared.trackCaseStarted(
        caseID: currentCase.id.uuidString,
        isDaily: isDailyCase
    )
 
 3. In GameView, when game completes:
    AnalyticsManager.shared.trackCaseCompleted(
        caseID: currentCase.id.uuidString,
        won: won,
        guesses: gameSession.guesses.count,
        hints: gameSession.hintsRevealed,
        score: gameSession.score,
        isDaily: isDailyCase
    )
    
    AppStoreReviewManager.shared.gameCompleted(won: won)
 
 4. In ContentView, when streak milestones hit:
    if stats.currentStreak % 7 == 0 && stats.currentStreak > 0 {
        AnalyticsManager.shared.trackStreakMilestone(streak: stats.currentStreak)
        AppStoreReviewManager.shared.streakAchieved(stats.currentStreak)
    }
 
 5. To integrate with a service like TelemetryDeck:
    - Add package dependency in Xcode
    - Import TelemetryDeck in this file
    - Replace track() implementation with TelemetryDeck.signal()
    - Add configuration in StepordleApp with your App ID
 
 RECOMMENDED SERVICES:
 
 • TelemetryDeck (Privacy-focused, GDPR-compliant)
   https://telemetrydeck.com
   - No personal data collection
   - Anonymous user tracking
   - $10/month for 100K signals
   
 • Firebase Analytics (Free, powerful)
   https://firebase.google.com/products/analytics
   - More features but collects more data
   - Requires privacy policy updates
   
 • Mixpanel (Advanced, paid)
   https://mixpanel.com
   - User analytics and funnels
   - Free tier available
 
 TESTFLIGHT PRO ACCESS TRACKING:
 
 • TestFlight users automatically get Pro access (see SubscriptionManager)
 • Analytics tracks this via user properties:
   - "is_testflight": true/false
   - "subscription_status": free/monthly/yearly/lifetime
 
 • Use PostHog to filter analytics by user type:
   - TestFlight beta testers (exclude from revenue)
   - Production subscribers (actual customers)
   - Free users (conversion funnel)
 
 */
