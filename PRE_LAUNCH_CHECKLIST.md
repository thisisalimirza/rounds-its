# Pre-Launch Checklist for Stepordle

## ✅ Essential Items (Must Have)

### 1. **Privacy Policy & Terms** 🔒
**Status:** ⚠️ **REQUIRED**
- [ ] Create Privacy Policy
- [ ] Create Terms of Service
- [ ] Add links in AboutView
- [ ] Host on website (required by App Store)
- [ ] Include data collection disclosure
- [ ] COPPA compliance if targeting under 13

**Where to add:**
- AboutView.swift - Add links at bottom
- App Store listing - Privacy policy URL required

**Resources:**
- Use generator: [termly.io](https://termly.io), [iubenda.com](https://iubenda.com)
- Must disclose: data collected, third-party services, user rights

---

### 2. **App Store Assets** 📱
**Status:** ⚠️ **REQUIRED**

**Required Screenshots:**
- [ ] 6.7" iPhone 15 Pro Max (1290 x 2796)
- [ ] 6.5" iPhone (1284 x 2778 or 1242 x 2688)
- [ ] 5.5" iPhone (optional, but recommended)

**App Icon:**
- [ ] 1024x1024 PNG (no transparency, no alpha channel)
- [ ] Consistent across all sizes
- [ ] Professional design

**App Store Listing:**
- [ ] Compelling app description
- [ ] Keywords for ASO (App Store Optimization)
- [ ] Promotional text (170 chars)
- [ ] Support URL
- [ ] Marketing URL (optional)

**Suggested Keywords:**
`USMLE, Step 1, medical education, diagnosis, clinical cases, medical students, board exam, study, flashcards, medicine`

---

### 3. **Analytics Setup** 📊
**Status:** ⚠️ **RECOMMENDED**

**Option A: Apple Analytics (Built-in, Privacy-focused)**
- Already integrated with App Store Connect
- No code required
- Limited but useful data:
  - Downloads
  - Updates
  - App Store page views
  - Crashes (via Xcode Organizer)

**Option B: TelemetryDeck (Privacy-first, GDPR-compliant)**
- No personal data collection
- Anonymous user tracking
- Custom events
- Free tier available
- Easy to integrate

**Option C: RevenueCat (If adding subscriptions/IAP)**
- Subscription analytics
- Revenue tracking
- Customer insights

**What to Track:**
- ✅ Cases played
- ✅ Daily streak maintenance
- ✅ Win/loss rates (already tracked locally)
- ✅ Feature usage (daily vs random vs browse)
- ✅ Session length
- ❌ NO personal information
- ❌ NO user identifiers without consent

---

### 4. **Error Handling & Crash Reporting** 🐛
**Status:** ⚠️ **RECOMMENDED**

**Built-in Options:**
1. **Xcode Organizer** (Free, Apple-provided)
   - Automatic crash logs
   - No code needed
   - TestFlight users + production
   - View in Xcode > Window > Organizer > Crashes

2. **Sentry** (Advanced, optional)
   - Real-time error tracking
   - Breadcrumbs for debugging
   - Free tier available

**Current Status:**
- ✅ Basic error handling with `try?` throughout
- ✅ SwiftData fallback to in-memory
- ⚠️ Could add better error logging

---

### 5. **App Store Connect Setup** 🏪
**Status:** ⚠️ **REQUIRED**

- [ ] Create App Store Connect account ($99/year)
- [ ] Register Bundle ID
- [ ] Create App Record
- [ ] Set age rating (likely 12+ for medical content)
- [ ] Configure pricing (Free with optional IAP)
- [ ] Set up TestFlight for beta testing
- [ ] Add App Store screenshots
- [ ] Write compelling description
- [ ] Set category: Education > Medical

**Bundle ID Suggestion:**
`com.yourcompany.stepordle`

---

### 6. **Testing** 🧪
**Status:** ⚠️ **CRITICAL**

- [ ] Test on multiple iPhone sizes
  - iPhone SE (small screen)
  - iPhone 15/14 (standard)
  - iPhone 15 Pro Max (large)
- [ ] Test iOS versions
  - Minimum supported version?
  - Latest iOS
- [ ] TestFlight beta (friends, colleagues)
- [ ] Accessibility testing
  - VoiceOver
  - Dynamic Type
  - Dark Mode (already supported)
- [ ] Network offline behavior
- [ ] Low storage scenarios
- [ ] Notification permissions
- [ ] Fresh install experience

---

### 7. **App Review Guidelines Compliance** 📋
**Status:** ⚠️ **REQUIRED**

**Key Points:**
- [ ] No "beta" or "test" references
- [ ] No medical diagnosis claims
- [ ] Include disclaimer: "For educational purposes only"
- [ ] All links functional
- [ ] No broken features
- [ ] Clear value proposition
- [ ] Kids category compliance (if applicable)

**Suggested Disclaimer:**
Add to AboutView:
> "Stepordle is for educational and study purposes only. It is not intended to diagnose, treat, or provide medical advice. Always consult qualified healthcare professionals for medical decisions."

---

### 8. **Performance & Battery** ⚡
**Status:** ✅ **GOOD**

Current app is lightweight:
- ✅ No heavy animations
- ✅ No background processing
- ✅ Minimal network usage
- ✅ Efficient SwiftData storage

**Could optimize:**
- [ ] Launch time profiling
- [ ] Memory leak check in Instruments
- [ ] Battery usage test

---

### 9. **Content & Case Quality** 📚
**Status:** ⚠️ **REVIEW**

- [ ] Review all medical cases for accuracy
- [ ] Check for typos/grammar
- [ ] Verify alternative diagnoses
- [ ] Add more cases (current sample size?)
- [ ] Categorize difficulty appropriately
- [ ] Source verification (cite references?)

**Legal Note:**
Ensure cases don't violate any copyright or use protected content.

---

### 10. **Monetization Strategy** 💰
**Status:** 🤔 **DECIDE**

**Options:**
1. **Free with Ads**
   - Add AdMob or similar
   - "Remove Ads" IAP

2. **Freemium**
   - Free basic cases
   - Premium cases via subscription
   - Pro features (detailed stats, etc.)

3. **Paid Upfront**
   - $2.99 - $4.99 typical for edu apps
   - No recurring revenue

4. **Completely Free**
   - Build user base
   - Monetize later

**Recommendation:**
Start free, add optional IAP for "Premium Cases Pack" or "Pro Statistics" later.

---

## 🔧 Technical Improvements (Nice to Have)

### A. **Onboarding Flow**
Add first-launch tutorial:
```swift
@AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false

.sheet(isPresented: $showOnboarding) {
    OnboardingView()
}
```

### B. **App Version Tracking**
```swift
// Track version for future migrations
let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
```

### C. **Rate This App Prompt**
```swift
import StoreKit

// After 5 games or 3 day streak
SKStoreReviewController.requestReview()
```

### D. **Share Results**
```swift
// Add share button after winning
let activityVC = UIActivityViewController(
    activityItems: ["I scored 450 on today's Stepordle case! 🔥"],
    applicationActivities: nil
)
```

### E. **Haptic Feedback**
```swift
// On correct answer
let generator = UINotificationFeedbackGenerator()
generator.notificationOccurred(.success)
```

### F. **Deep Linking**
- Share daily case links
- Open specific cases from URLs

---

## 📱 App Store Optimization (ASO)

### App Name
**Current:** "Stepordle"
**Suggestion:** "Stepordle - USMLE Step 1 Game" (30 char limit)

### Subtitle
"Master Medical Diagnosis" (30 chars)

### Description Template
```
Master USMLE Step 1 with daily clinical cases!

Stepordle challenges you to diagnose medical cases using progressive clinical clues. Perfect for medical students preparing for board exams.

FEATURES:
• Daily medical case challenges
• Progressive hint system
• Track your streak and stats
• Hundreds of clinical scenarios
• Category-based learning
• Detailed performance analytics

IDEAL FOR:
• Medical students studying for USMLE Step 1
• Clinical knowledge assessment
• Diagnosis practice
• Board exam preparation

Download now and start your medical mastery journey!

---
Disclaimer: For educational purposes only. Not intended for medical diagnosis or treatment.
```

---

## 🚀 Launch Day Checklist

**1 Week Before:**
- [ ] Submit for App Review (7-14 day review time)
- [ ] Create social media accounts
- [ ] Prepare launch announcement
- [ ] Line up beta testers for reviews
- [ ] Screenshot final version

**Launch Day:**
- [ ] Tweet/post announcement
- [ ] Email beta testers
- [ ] Post in medical student communities (Reddit r/medicalschool, etc.)
- [ ] Monitor crash reports
- [ ] Respond to reviews
- [ ] Check analytics

**Week 1 Post-Launch:**
- [ ] Monitor user feedback
- [ ] Fix critical bugs quickly
- [ ] Prepare 1.1 update
- [ ] Respond to all reviews
- [ ] Track key metrics

---

## 📊 Key Metrics to Track

### User Engagement:
- Daily Active Users (DAU)
- Monthly Active Users (MAU)
- DAU/MAU ratio (stickiness)
- Session length
- Retention rate (Day 1, Day 7, Day 30)

### Gameplay:
- Cases completed per session
- Win rate
- Average guesses per case
- Daily case completion rate
- Streak distribution

### Growth:
- Downloads per day
- Organic vs paid traffic
- App Store conversion rate
- Review rating average
- Review count

---

## ⚠️ Critical Pre-Launch Items

**MUST DO BEFORE SUBMITTING:**
1. ✅ Privacy Policy URL
2. ✅ Support email/URL
3. ✅ App icon (all sizes)
4. ✅ Screenshots (required sizes)
5. ✅ App Store description
6. ✅ Medical disclaimer
7. ✅ TestFlight testing
8. ✅ Age rating decision
9. ✅ Category selection
10. ✅ Pricing decision

**HIGHLY RECOMMENDED:**
1. ⚠️ Analytics integration
2. ⚠️ Crash reporting
3. ⚠️ Rate app prompt
4. ⚠️ Onboarding flow
5. ⚠️ Share functionality

---

## 🎯 Success Criteria (First Month)

**Conservative:**
- 100 downloads
- 4.0+ rating
- 10+ reviews
- No critical bugs

**Optimistic:**
- 1,000 downloads
- 4.5+ rating
- 50+ reviews
- Featured in "New Apps We Love"

**Stretch:**
- 5,000+ downloads
- Medical student communities adoption
- Blog/press coverage
- 4.7+ rating

---

## 📞 Support & Maintenance

**Set up:**
- [ ] Support email (support@stepordle.app)
- [ ] FAQ page
- [ ] Bug reporting system
- [ ] Feature request tracking
- [ ] Roadmap planning

**Commit to:**
- Respond to reviews within 48 hours
- Fix critical bugs within 1 week
- Monthly updates (new cases, features)
- Quarterly major updates

---

## 🎓 Marketing Ideas

1. **Reddit:** r/medicalschool, r/step1, r/USMLE
2. **Student Discounts:** First 1000 users get premium free
3. **Medical School Partnerships:** Reach out to course directors
4. **YouTube:** Demo videos, study tips
5. **TikTok:** Quick case challenges
6. **Blog:** "How we built Stepordle"
7. **Product Hunt:** Launch post
8. **Twitter:** Daily case teasers

---

## Summary

**Must Have Before Launch:**
✅ Privacy Policy + Terms
✅ App Store assets (screenshots, icon, description)
✅ Medical disclaimer
✅ TestFlight testing
✅ Support email/URL

**Should Have:**
⚠️ Analytics (TelemetryDeck or similar)
⚠️ Crash reporting (Xcode Organizer minimum)
⚠️ Rate prompt
⚠️ Onboarding

**Nice to Have:**
💡 Share functionality
💡 Haptics
💡 Deep linking
💡 Monetization

Would you like me to implement any of these? I'd recommend starting with:
1. Adding a medical disclaimer to AboutView
2. Setting up basic analytics (I can add TelemetryDeck)
3. Adding a "Rate This App" prompt
4. Creating a simple onboarding flow
