//
//  OnboardingView.swift
//  Rounds
//
//  First-launch onboarding experience
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)

                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        OnboardingPageView(page: onboardingPages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Buttons
                VStack(spacing: 12) {
                    if currentPage == onboardingPages.count - 1 {
                        // Last page - Get Started button
                        Button {
                            completeOnboarding()
                        } label: {
                            HStack {
                                Text("Get Started")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .cornerRadius(14)
                        }
                    } else {
                        // Next button
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            HStack {
                                Text("Continue")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(14)
                        }

                        // Skip button
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true

        // Request notification permission and schedule smart reminders
        SmartNotificationManager.shared.requestAuthorization { granted in
            if granted {
                // Schedule with default time (7 PM) - context will be nil for new users
                SmartNotificationManager.shared.scheduleSmartReminder()
            }
        }

        AnalyticsManager.shared.track("onboarding_completed")
        dismiss()
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPageData

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)

                // Icon or Custom Content
                if let customContent = page.customContent {
                    customContent
                } else {
                    // Default icon display
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [page.iconColor.opacity(0.3), page.iconColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: page.icon)
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [page.iconColor, page.iconColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }

                VStack(spacing: 12) {
                    // Title
                    Text(page.title)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)

                    // Description
                    Text(page.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Optional bullet points
                if let bulletPoints = page.bulletPoints {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(bulletPoints, id: \.text) { point in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: point.icon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(point.color)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(point.text)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if let subtitle = point.subtitle {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal, 24)
                }

                Spacer()
                    .frame(height: 100)
            }
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Onboarding Data Models

struct OnboardingPageData {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    var bulletPoints: [BulletPoint]? = nil
    var customContent: AnyView? = nil
}

struct BulletPoint {
    let icon: String
    let color: Color
    let text: String
    var subtitle: String? = nil
}

// MARK: - Onboarding Pages Content

let onboardingPages: [OnboardingPageData] = [
    // Page 1: Welcome
    OnboardingPageData(
        icon: "cross.case.fill",
        iconColor: .blue,
        title: "Welcome to Rounds!",
        description: "Master clinical diagnosis through daily case challenges. Think like a physician and solve real-world medical cases.",
        bulletPoints: [
            BulletPoint(icon: "brain.head.profile", color: .purple, text: "Train clinical reasoning", subtitle: "Practice diagnostic thinking daily"),
            BulletPoint(icon: "graduationcap.fill", color: .blue, text: "USMLE Step 1 prep", subtitle: "Cases aligned with board content"),
            BulletPoint(icon: "chart.line.uptrend.xyaxis", color: .green, text: "Track your progress", subtitle: "See your improvement over time")
        ]
    ),

    // Page 2: How to Play
    OnboardingPageData(
        icon: "lightbulb.fill",
        iconColor: .yellow,
        title: "How to Play",
        description: "Each case presents progressive clinical clues. Use your medical knowledge to diagnose the condition.",
        bulletPoints: [
            BulletPoint(icon: "1.circle.fill", color: .blue, text: "Read the first clue", subtitle: "Start with limited information"),
            BulletPoint(icon: "text.bubble.fill", color: .purple, text: "Make your guess", subtitle: "Type in your diagnosis"),
            BulletPoint(icon: "arrow.right.circle.fill", color: .orange, text: "Wrong? Get another clue", subtitle: "Each wrong guess reveals more hints"),
            BulletPoint(icon: "checkmark.circle.fill", color: .green, text: "Diagnose correctly to win!", subtitle: "The fewer hints needed, the better")
        ]
    ),

    // Page 3: Scoring System
    OnboardingPageData(
        icon: "star.fill",
        iconColor: .orange,
        title: "Scoring System",
        description: "Earn points based on how quickly you diagnose the case. Fewer guesses and hints mean higher scores!",
        customContent: AnyView(ScoringExplanationView())
    ),

    // Page 4: Daily Challenge & Streaks
    OnboardingPageData(
        icon: "flame.fill",
        iconColor: .orange,
        title: "Daily Challenges",
        description: "Play the daily case to build your streak. Everyone worldwide gets the same case each day!",
        bulletPoints: [
            BulletPoint(icon: "calendar", color: .blue, text: "New case every day", subtitle: "Same case for all players globally"),
            BulletPoint(icon: "flame.fill", color: .orange, text: "Build your streak", subtitle: "Play daily to keep it growing"),
            BulletPoint(icon: "trophy.fill", color: .yellow, text: "Compete globally", subtitle: "See how you rank on leaderboards")
        ]
    ),

    // Page 5: Features
    OnboardingPageData(
        icon: "sparkles",
        iconColor: .purple,
        title: "Powerful Features",
        description: "Everything you need to master clinical diagnosis and track your medical education journey.",
        bulletPoints: [
            BulletPoint(icon: "medal.fill", color: .orange, text: "Leaderboards", subtitle: "Compete with your school & globally"),
            BulletPoint(icon: "trophy.fill", color: .yellow, text: "Achievement badges", subtitle: "Unlock rewards as you progress"),
            BulletPoint(icon: "chart.pie.fill", color: .indigo, text: "Category analytics", subtitle: "See strengths by specialty"),
            BulletPoint(icon: "crown.fill", color: .purple, text: "Pro: Unlimited cases", subtitle: "Browse & play any case anytime")
        ]
    ),

    // Page 6: Get Started
    OnboardingPageData(
        icon: "hand.thumbsup.fill",
        iconColor: .green,
        title: "You're Ready!",
        description: "Start with today's daily case and begin your journey to diagnostic mastery. Good luck, future physician!",
        bulletPoints: [
            BulletPoint(icon: "lightbulb.fill", color: .yellow, text: "Tip: Read clues carefully", subtitle: "Key details are often subtle"),
            BulletPoint(icon: "brain", color: .purple, text: "Tip: Think systematically", subtitle: "Consider differential diagnoses"),
            BulletPoint(icon: "clock.fill", color: .blue, text: "Tip: Play daily", subtitle: "Consistency builds expertise")
        ]
    )
]

// MARK: - Scoring Explanation View

struct ScoringExplanationView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Visual scoring breakdown
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 16) {
                // Base score
                ScoreRow(
                    icon: "gift.fill",
                    color: .green,
                    label: "Base Score",
                    value: "500 pts",
                    description: "Starting points for each case"
                )

                // Guess penalty
                ScoreRow(
                    icon: "minus.circle.fill",
                    color: .red,
                    label: "Per Guess",
                    value: "-100 pts",
                    description: "Penalty for each wrong guess"
                )

                // Hint penalty
                ScoreRow(
                    icon: "lightbulb.fill",
                    color: .orange,
                    label: "Per Extra Hint",
                    value: "-50 pts",
                    description: "First hint is free, then -50 each"
                )

                Divider()
                    .padding(.vertical, 4)

                // Example
                HStack {
                    VStack(alignment: .leading) {
                        Text("Example: Perfect Round")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("1 guess, 1 hint = 400 pts")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal, 24)
        }
    }
}

struct ScoreRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                }
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
