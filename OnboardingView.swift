//
//  OnboardingView.swift
//  Stepordle
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
            
            VStack {
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 40)
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        OnboardingPage(page: onboardingPages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Buttons
                VStack(spacing: 12) {
                    if currentPage == onboardingPages.count - 1 {
                        // Last page - Get Started button
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Get Started")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                    } else {
                        // Next button
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Next")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        
                        // Skip button
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        
        // Request notification permission
        NotificationManager.requestAuthorization { granted in
            if granted {
                NotificationManager.scheduleDailyReminder()
            }
        }
        
        AnalyticsManager.shared.track("onboarding_completed")
        dismiss()
    }
}

// MARK: - Onboarding Page

struct OnboardingPage: View {
    let page: OnboardingPageData
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 16) {
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
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

// MARK: - Onboarding Data

struct OnboardingPageData {
    let icon: String
    let title: String
    let description: String
}

let onboardingPages: [OnboardingPageData] = [
    OnboardingPageData(
        icon: "cross.case.fill",
        title: "Welcome to Stepordle!",
        description: "Master USMLE Step 1 through daily clinical case challenges. Learn diagnosis by doing!"
    ),
    OnboardingPageData(
        icon: "brain.head.profile",
        title: "Progressive Clinical Clues",
        description: "Each case reveals hints one at a time. Use clinical reasoning to diagnose before all clues are shown."
    ),
    OnboardingPageData(
        icon: "flame.fill",
        title: "Build Your Streak",
        description: "Play daily to maintain your streak! Track your progress and see your improvement over time."
    ),
    OnboardingPageData(
        icon: "chart.bar.fill",
        title: "Track Your Progress",
        description: "Monitor your win rate, scores, and master different medical specialties with detailed statistics."
    )
]

#Preview {
    OnboardingView()
}
