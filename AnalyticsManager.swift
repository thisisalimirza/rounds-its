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

    // MARK: - Leaderboard & Competitive Tracking

    func trackLeaderboardViewed(scope: String, userRank: Int?) {
        track("leaderboard_viewed", properties: [
            "scope": scope,
            "user_rank": userRank ?? -1,
            "has_rank": userRank != nil
        ])
    }

    func trackLeaderboardJoined(schoolName: String, state: String) {
        track("leaderboard_joined", properties: [
            "school_name": schoolName,
            "state": state
        ])
    }

    func trackRankChange(oldRank: Int, newRank: Int, scope: String) {
        let direction = newRank < oldRank ? "up" : "down"
        track("rank_changed", properties: [
            "old_rank": oldRank,
            "new_rank": newRank,
            "direction": direction,
            "change_amount": abs(newRank - oldRank),
            "scope": scope
        ])
    }

    func trackCompetitiveNotificationSent(type: String, rank: Int) {
        track("competitive_notification_sent", properties: [
            "type": type,
            "rank": rank
        ])
    }

    // MARK: - Viral Loop Tracking

    func trackShareInitiated(source: String, won: Bool, score: Int, hasStreak: Bool, hasSchoolRank: Bool) {
        track("share_initiated", properties: [
            "source": source,
            "won": won,
            "score": score,
            "has_streak": hasStreak,
            "has_school_rank": hasSchoolRank
        ])
    }

    func trackShareCompleted(destination: String?) {
        track("share_completed", properties: [
            "destination": destination ?? "unknown"
        ])
    }

    func trackDeepLinkOpened(caseID: String, source: String?) {
        track("deep_link_opened", properties: [
            "case_id": caseID,
            "source": source ?? "unknown"
        ])
    }

    func trackReferralReceived(referrerID: String?) {
        track("referral_received", properties: [
            "has_referrer": referrerID != nil
        ])
    }
}

// MARK: - App Store Review Manager

class AppStoreReviewManager {
    static let shared = AppStoreReviewManager()

    @UserDefaultsWrapper(key: "gamesCompletedCount", defaultValue: 0)
    private var gamesCompleted: Int

    @UserDefaultsWrapper(key: "gamesWonCount", defaultValue: 0)
    private var gamesWon: Int

    @UserDefaultsWrapper(key: "perfectScoresCount", defaultValue: 0)
    private var perfectScores: Int

    @UserDefaultsWrapper(key: "hasRequestedReview", defaultValue: false)
    private var hasRequestedReview: Bool

    @UserDefaultsWrapper(key: "lastReviewRequestDate", defaultValue: nil)
    private var lastReviewRequestDate: Date?

    @UserDefaultsWrapper(key: "reviewPromptsThisYear", defaultValue: 0)
    private var reviewPromptsThisYear: Int

    @UserDefaultsWrapper(key: "lastReviewPromptYear", defaultValue: 0)
    private var lastReviewPromptYear: Int

    // Streak milestones that should trigger review consideration
    private let streakMilestones: Set<Int> = [7, 14, 21, 30, 50, 100]

    private init() {
        // Reset yearly counter if new year
        let currentYear = Calendar.current.component(.year, from: Date())
        if lastReviewPromptYear != currentYear {
            reviewPromptsThisYear = 0
            lastReviewPromptYear = currentYear
        }
    }

    /// Call this after each game completion with detailed info
    @MainActor
    func gameCompleted(won: Bool, hintsUsed: Int = 5, isFirstWin: Bool = false) {
        gamesCompleted += 1

        guard won else { return }
        gamesWon += 1

        // Track perfect scores (1-hint diagnosis)
        if hintsUsed == 1 {
            perfectScores += 1
            // Perfect score is a peak happiness moment!
            if shouldRequestReview(reason: "perfect_score") {
                requestReview(reason: "perfect_score")
                return
            }
        }

        // First ever win is special
        if isFirstWin || gamesWon == 1 {
            if shouldRequestReview(reason: "first_win") {
                requestReview(reason: "first_win")
                return
            }
        }

        // After 5 wins, user is engaged
        if gamesWon == 5 {
            if shouldRequestReview(reason: "five_wins") {
                requestReview(reason: "five_wins")
                return
            }
        }
    }

    /// Call this when user achieves a streak milestone
    @MainActor
    func streakAchieved(_ streak: Int) {
        // Only trigger on milestone streaks
        guard streakMilestones.contains(streak) else { return }

        if shouldRequestReview(reason: "streak_\(streak)") {
            requestReview(reason: "streak_\(streak)")
        }
    }

    /// Call when user returns after being away and wins
    @MainActor
    func returningUserWon(daysSinceLastPlay: Int) {
        // User came back after 3+ days and won - they're re-engaged!
        if daysSinceLastPlay >= 3 && shouldRequestReview(reason: "returning_user") {
            requestReview(reason: "returning_user")
        }
    }

    private func shouldRequestReview(reason: String) -> Bool {
        // Apple limits to 3 prompts per 365-day period
        guard reviewPromptsThisYear < 3 else {
            print("📊 Review: Skipping (\(reason)) - hit yearly limit")
            return false
        }

        // Don't request if already requested in last 60 days
        if let lastRequest = lastReviewRequestDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastRequest, to: Date()).day ?? 0
            guard daysSince >= 60 else {
                print("📊 Review: Skipping (\(reason)) - too recent (\(daysSince) days)")
                return false
            }
        }

        // Minimum engagement: at least 3 games played
        guard gamesCompleted >= 3 else {
            print("📊 Review: Skipping (\(reason)) - not enough games (\(gamesCompleted))")
            return false
        }

        return true
    }

    @MainActor
    private func requestReview(reason: String) {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            // Use modern AppStore API (iOS 16+)
            AppStore.requestReview(in: scene)
            lastReviewRequestDate = Date()
            hasRequestedReview = true
            reviewPromptsThisYear += 1

            AnalyticsManager.shared.track("review_prompt_shown", properties: [
                "reason": reason,
                "games_completed": gamesCompleted,
                "games_won": gamesWon,
                "perfect_scores": perfectScores,
                "prompts_this_year": reviewPromptsThisYear
            ])

            print("📊 Review: Requested (reason: \(reason), prompts this year: \(reviewPromptsThisYear))")
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

    /// Check if we should prompt (for UI indicators)
    var canPromptForReview: Bool {
        return reviewPromptsThisYear < 3 && gamesCompleted >= 3
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
