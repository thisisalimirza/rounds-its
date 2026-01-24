# PostHog Events Tracking - Complete Summary

## ✅ All Essential Events Now Tracked!

Your 6 essential events are now fully integrated into Rounds:

| Event | Status | Location | Properties Tracked |
|-------|--------|----------|-------------------|
| `app_launched` | ✅ Tracked | `RoundsApp.swift` | None |
| `case_started` | ✅ Tracked | `GameView.swift` init | `case_id`, `is_daily` |
| `hint_revealed` | ✅ **ADDED** | `GameView.swift` hint button | `hint_index`, `case_id` |
| `diagnosis_submitted` | ✅ **ADDED** | `GameView.swift` submitGuess() | `case_id`, `is_correct`, `guess_number`, `hints_revealed`, `is_daily` |
| `case_completed` | ✅ Tracked | `GameView.swift` updateStats() | `case_id`, `won`, `guesses`, `hints_used`, `score`, `is_daily` |
| `paywall_viewed` | ✅ **ADDED** | `PaywallView.swift` onAppear | `source` |

---

## 📊 Complete Event Catalog

### Core Lifecycle Events
```swift
// App Launch
track("app_launched")

// Session Management
track("session_started", properties: ["session_number": Int])
track("session_ended", properties: ["duration_seconds": Int, "session_number": Int])
```

### Gameplay Events
```swift
// Case Started
track("case_started", properties: [
    "case_id": String,
    "is_daily": Bool
])

// Hint Revealed (NEW!)
track("hint_revealed", properties: [
    "hint_index": Int,
    "case_id": String
])

// Diagnosis Submitted (NEW!)
track("diagnosis_submitted", properties: [
    "case_id": String,
    "is_correct": Bool,
    "guess_number": Int,
    "hints_revealed": Int,
    "is_daily": Bool
])

// Case Completed
track("case_completed", properties: [
    "case_id": String,
    "won": Bool,
    "guesses": Int,
    "hints_used": Int,
    "score": Int,
    "is_daily": Bool
])

// Milestone
track("streak_milestone", properties: [
    "streak_count": Int
])

// Sharing
track("share_results", properties: [
    "won": Bool,
    "score": Int
])
```

### Subscription Events
```swift
// Paywall Viewed (NEW!)
track("paywall_viewed", properties: [
    "source": String  // "app", "daily_case_completed", etc.
])

// Purchase Flow
track("subscription_purchase_started", properties: [
    "product_id": String
])

track("subscription_purchase_completed", properties: [
    "product_id": String
])

track("subscription_purchase_failed", properties: [
    "product_id": String,
    "error": String
])

track("subscription_restored")
```

### Onboarding Events
```swift
track("onboarding_completed")

track("onboarding_skipped", properties: [
    "step": Int
])
```

### App Store Events
```swift
track("review_prompt_shown")
track("review_prompt_manual")
```

### Feature Usage
```swift
track("feature_used", properties: [
    "feature": String
])
```

---

## 🎯 Key Funnel Analysis

With these events, you can now track complete user funnels:

### 1. **Daily Case Funnel**
```
app_launched
  ↓
case_started (is_daily: true)
  ↓
hint_revealed (0 to N times)
  ↓
diagnosis_submitted (1 to N times)
  ↓
case_completed (won: true/false)
  ↓
share_results (optional)
```

### 2. **Subscription Conversion Funnel**
```
app_launched
  ↓
case_completed (multiple times)
  ↓
paywall_viewed (source: varies)
  ↓
subscription_purchase_started
  ↓
subscription_purchase_completed
```

### 3. **User Engagement Funnel**
```
app_launched
  ↓
session_started
  ↓
case_started (multiple)
  ↓
streak_milestone
  ↓
session_ended
```

---

## 📈 Recommended PostHog Insights to Create

### 1. **Win Rate by Hints Used**
**Type:** Breakdown  
**Event:** `case_completed`  
**Filter:** `won = true`  
**Breakdown by:** `hints_used`

**Question Answered:** Do users who use fewer hints win more?

---

### 2. **Daily Case Participation Rate**
**Type:** Trend  
**Event:** `case_started`  
**Filter:** `is_daily = true`  
**Group by:** Day

**Question Answered:** How many users play the daily case each day?

---

### 3. **Guess Accuracy by Guess Number**
**Type:** Breakdown  
**Event:** `diagnosis_submitted`  
**Formula:** `(is_correct = true) / total`  
**Breakdown by:** `guess_number`

**Question Answered:** Are users more accurate on first guess? Last guess?

---

### 4. **Conversion: Cases Played → Subscription**
**Type:** Funnel  
**Steps:**
1. `case_started`
2. `case_completed`
3. `paywall_viewed`
4. `subscription_purchase_completed`

**Question Answered:** What % of players convert to paid after completing cases?

---

### 5. **Hint Effectiveness**
**Type:** Insight  
**Events:** `hint_revealed` → `diagnosis_submitted` (next event)  
**Filter:** `is_correct = true` within 60 seconds of hint

**Question Answered:** Do hints lead to correct diagnoses?

---

### 6. **Paywall Source Performance**
**Type:** Breakdown  
**Event:** `paywall_viewed`  
**Breakdown by:** `source`  
**Next event:** `subscription_purchase_completed`

**Question Answered:** Which paywall trigger converts best?

---

### 7. **Average Guesses to Win**
**Type:** Metric  
**Event:** `case_completed`  
**Filter:** `won = true`  
**Formula:** `AVG(guesses)`

**Question Answered:** How many guesses does it typically take?

---

### 8. **Retention: D1, D7, D30**
**Type:** Retention  
**Cohort:** `app_launched`  
**Return Event:** `app_launched`  
**Periods:** 1 day, 7 days, 30 days

**Question Answered:** Do users come back after first use?

---

## 🔍 Advanced Analytics You Can Now Do

### Cohort Analysis
Group users by:
- First case completed date
- Number of hints typically used
- Win rate percentage
- Subscription status

Then analyze retention, LTV, behavior differences.

### User Properties to Set (Recommended)
```swift
// Update these as user progresses
AnalyticsManager.shared.setUserProperties([
    "total_cases_completed": stats.totalGamesPlayed,
    "current_streak": stats.currentStreak,
    "longest_streak": stats.longestStreak,
    "win_rate": stats.winRate,
    "average_score": stats.averageScore,
    "subscription_tier": subscriptionManager.subscriptionStatus.rawValue,
    "days_since_install": daysSinceInstall,
    "favorite_category": mostPlayedCategory
])
```

This lets you segment users by behavior and performance.

---

## 🎨 Example Dashboard: "Daily Operations"

### Widgets:

1. **Today's DAU** (Unique users with `app_launched`)
2. **Daily Cases Completed** (Count of `case_completed` where `is_daily = true`)
3. **Win Rate Today** (% of `case_completed` with `won = true`)
4. **New Subscribers Today** (Count of `subscription_purchase_completed`)
5. **Revenue Today** (Integrate RevenueCat webhook)
6. **Avg Guesses to Win** (Average `guesses` from `case_completed` where `won = true`)
7. **Most Common Hint Count** (Mode of `hints_used` from `case_completed`)
8. **Paywall View Rate** (% of sessions with `paywall_viewed`)

---

## 🚀 Next Steps

### 1. **Test All Events**
Run through your app and verify each event fires:
- Launch app → check `app_launched`
- Start case → check `case_started`
- Reveal hint → check `hint_revealed`
- Submit guess → check `diagnosis_submitted`
- Complete case → check `case_completed`
- View paywall → check `paywall_viewed`

### 2. **Create Your First Dashboard**
Login to PostHog and create a "Key Metrics" dashboard with:
- DAU graph
- Daily cases completed
- Win rate trend
- Subscription conversions

### 3. **Set Up Alerts** (PostHog Pro Feature)
Get notified when:
- DAU drops >20%
- Win rate falls below 50%
- Subscription conversion <1%

### 4. **Run Experiments**
Use your data to test:
- Different hint timing
- Paywall messaging
- Difficulty balancing
- UI improvements

---

## 🎉 You're All Set!

All essential events are now tracking. You have:
✅ Complete user journey visibility  
✅ Subscription funnel tracking  
✅ Gameplay behavior insights  
✅ Real-time analytics dashboard  
✅ Data-driven decision making capability  

**Go build the best medical education app! 🏥📚**
