//
//  AnalyticsManager.swift
//  Rounds
//
//  Created for launch tracking
//

import Foundation
import StoreKit
import UIKit

/// Simple analytics manager for tracking key events
/// Replace with TelemetryDeck, Firebase, or your preferred analytics service
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
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
        
        // TODO: Integrate with your analytics service
        // Examples:
        // - TelemetryDeck.signal(event, parameters: properties)
        // - Analytics.logEvent(event, parameters: properties)
        // - Mixpanel.mainInstance().track(event, properties: properties)
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

class SessionTracker {
    static let shared = SessionTracker()
    
    private var sessionStart: Date?
    
    @UserDefaultsWrapper(key: "totalSessions", defaultValue: 0)
    private var totalSessions: Int
    
    private init() {}
    
    func startSession() {
        sessionStart = Date()
        totalSessions += 1
        AnalyticsManager.shared.track("session_started", properties: [
            "session_number": totalSessions
        ])
    }
    
    func endSession() {
        guard let start = sessionStart else { return }
        let duration = Date().timeIntervalSince(start)
        
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
 
 */
