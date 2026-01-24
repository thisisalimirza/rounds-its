# PostHog Quick Start 🚀

## ✅ Integration Complete!

PostHog is now fully integrated into Rounds. Here's what you need to know:

---

## 🎯 What's Automatically Tracked

Your app is already tracking these events without any additional code needed:

### Core Events
- `app_launched` - Every time the app starts
- `session_started` / `session_ended` - User sessions with duration
- `case_started` - When a medical case begins
- `case_completed` - With win/loss, score, guesses, hints
- `streak_milestone` - When users hit streak goals
- `review_prompt_shown` - App Store review requests

### Subscription Events (via SubscriptionManager)
- `subscription_purchase_started` - User clicks subscribe
- `subscription_purchase_completed` - Successful purchase
- `subscription_purchase_failed` - Failed purchase with error
- `subscription_restored` - Restored purchases

---

## 📱 View Your Data Now

1. **Go to:** https://app.posthog.com
2. **Login** with your account
3. **Click:** "Activity" → "Live Events" to see events in real-time

---

## 🧪 Test It Right Now

1. **Build and run** your app
2. **Check Xcode console** - You should see:
   ```
   📊 PostHog configured in DEBUG mode
   📊 Analytics: app_launched
   📊 Analytics: session_started
   ```
3. **Play a case** - Check console for events
4. **Wait ~30 seconds**
5. **Check PostHog dashboard** - Events should appear!

---

## 🎨 Recommended First Dashboard

Create an "Overview" dashboard with these insights:

1. **Daily Active Users** (DAU)
   - Event: `session_started`
   - Filter: Unique users per day

2. **Cases Completed**
   - Event: `case_completed`
   - Count per day

3. **Win Rate**
   - Event: `case_completed`
   - Filter: `won = true`
   - Formula: (wins / total) × 100

4. **Subscription Conversion**
   - Funnel: `app_launched` → `paywall_viewed` → `subscription_purchase_completed`

5. **Daily Case Participation**
   - Event: `case_started`
   - Filter: `is_daily = true`

---

## 💡 Add More Tracking (Optional)

Want to track more? Add these to your views:

### Track Screen Views
```swift
// In any view's .onAppear
AnalyticsManager.shared.track("screen_viewed", properties: [
    "screen": "statistics"
])
```

### Track Button Clicks
```swift
Button("Some Action") {
    AnalyticsManager.shared.track("button_clicked", properties: [
        "button": "share_results"
    ])
    // ... your action
}
```

### Track User Properties
```swift
// When user reaches a milestone
AnalyticsManager.shared.setUserProperties([
    "total_cases_completed": stats.totalGamesPlayed,
    "current_streak": stats.currentStreak,
    "subscription_tier": SubscriptionManager.shared.subscriptionStatus.rawValue
])
```

---

## 🔍 Key Metrics to Monitor

### Engagement
- **Daily Active Users (DAU)** - How many users open the app daily
- **Weekly Active Users (WAU)** - Unique users per week
- **Session Length** - Average time spent in app
- **Retention Rate** - % of users who return after 1/7/30 days

### Product
- **Cases Completed** - Total cases finished
- **Win Rate** - % of cases won
- **Average Hints Used** - How many hints per case
- **Daily Case Completion Rate** - % of users who play daily case

### Monetization
- **Paywall View Rate** - % of sessions that see paywall
- **Conversion Rate** - % of paywall views → purchases
- **Revenue** - Total subscription revenue (connect RevenueCat)
- **ARPU** - Average Revenue Per User

---

## 🛠️ Troubleshooting

### Not seeing events in PostHog?

1. ✅ Check console for `📊 PostHog configured in DEBUG mode`
2. ✅ Wait 30-60 seconds - events are batched
3. ✅ Check your internet connection
4. ✅ Verify API key is correct
5. ✅ Try force-flushing: `PostHogSDK.shared.flush()`

### Want to reset during testing?

```swift
PostHogSDK.shared.reset()  // Creates new anonymous user
```

---

## 📊 Next Steps

1. **Build and test** - Make sure events are flowing
2. **Create your first dashboard** - Visualize key metrics
3. **Set up alerts** - Get notified of drops/spikes
4. **Explore features:**
   - Session Recordings (see how users interact)
   - Feature Flags (remote config without app updates)
   - A/B Testing (test different UX variations)
   - Cohort Analysis (group users by behavior)

---

## 🎉 You're All Set!

PostHog is now tracking user behavior in Rounds. Start making data-driven decisions to improve your app!

**Questions?** Check the full guide: `POSTHOG_INTEGRATION.md`

**PostHog Docs:** https://posthog.com/docs
**Your Dashboard:** https://app.posthog.com
