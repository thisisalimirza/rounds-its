//
//  ContentView.swift
//  Rounds
//
//  Created by Ali Mirza on 12/9/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var playerStats: [PlayerStats]
    @Query private var achievementProgressList: [AchievementProgress]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentCase: MedicalCase?
    @State private var isDailyCase = false
    @State private var showingGame = false
    @State private var showingStats = false
    @State private var showingAbout = false
    @State private var showingCaseBrowser = false
    @State private var showingFeedback = false
    @State private var showingDailyCompleteAlert = false
    @State private var showingPaywall = false
    @State private var showingConfetti = false
    @State private var showingCaseHistory = false
    @State private var showingAchievements = false
    @State private var showingCategoryAnalytics = false
    @State private var showOnboarding = false
    @State private var hasCheckedOnboarding = false // Track if we've already checked this session
    
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    
    private var stats: PlayerStats {
        // Ensure stats exist, create if needed
        if let existingStats = playerStats.first {
            return existingStats
        } else {
            let newStats = PlayerStats()
            modelContext.insert(newStats)
            try? modelContext.save()
            return newStats
        }
    }
    
    private var hasPlayedDailyToday: Bool {
        stats.hasPlayedDailyCaseToday()
    }
    
    private var achievementBadgeText: String {
        let unlockedCount = achievementProgressList.first?.unlockedAchievements.count ?? 0
        let totalCount = Achievement.allCases.count
        return "\(unlockedCount)/\(totalCount)"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo and Title
                    VStack(spacing: 6) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        HStack(spacing: 8) {
                            Text("Rounds")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            if subscriptionManager.isProUser {
                                ProBadge(size: .medium)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        
                        Text("Master USMLE Step 1")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: subscriptionManager.isProUser)
                    
                    Spacer()
                        .frame(height: 16)
                    
                    // Combined Streak & Stats Card
                    CompactStreakStatsView(stats: stats)
                        .padding(.horizontal)
                        .id(stats.currentStreak) // Force refresh when streak changes
                    
                    Spacer()
                        .frame(height: 14)
                    
                    // Main Menu Buttons
                    VStack(spacing: 12) {
                        Button {
                            if hasPlayedDailyToday {
                                showingDailyCompleteAlert = true
                            } else {
                                startNewGame()
                            }
                        } label: {
                            if hasPlayedDailyToday {
                                // Completed state
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                    Text("Daily Case Complete")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.green.opacity(0.15))
                                .foregroundStyle(.green)
                                .cornerRadius(12)
                            } else {
                                // Play state
                                Label("Play Daily Case", systemImage: "play.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Button {
                            if subscriptionManager.isProUser {
                                startRandomGame()
                            } else {
                                showingPaywall = true
                            }
                        } label: {
                            HStack {
                                Label("Random Case", systemImage: "shuffle")
                                if !subscriptionManager.isProUser {
                                    ProBadge(size: .small)
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(subscriptionManager.isProUser ? Color.purple : Color.purple.opacity(0.5))
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        
                        Button {
                            showingCaseBrowser = true
                        } label: {
                            HStack {
                                Label("Browse Cases", systemImage: "list.bullet.clipboard")
                                if !subscriptionManager.isProUser {
                                    ProBadge(size: .small)
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(subscriptionManager.isProUser ? Color.green : Color.green.opacity(0.5))
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                        .frame(height: 12)
                    
                    // Feature Cards Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        // Case History
                        FeatureCardButton(
                            icon: "clock.arrow.circlepath",
                            title: "History",
                            color: .cyan,
                            isPro: true,
                            isProUser: subscriptionManager.isProUser
                        ) {
                            if subscriptionManager.isProUser {
                                showingCaseHistory = true
                            } else {
                                showingPaywall = true
                            }
                        }
                        
                        // Category Analytics
                        FeatureCardButton(
                            icon: "chart.pie.fill",
                            title: "Analytics",
                            color: .indigo,
                            isPro: true,
                            isProUser: subscriptionManager.isProUser
                        ) {
                            if subscriptionManager.isProUser {
                                showingCategoryAnalytics = true
                            } else {
                                showingPaywall = true
                            }
                        }
                        
                        // Achievements
                        FeatureCardButton(
                            icon: "trophy.fill",
                            title: "Badges",
                            color: .yellow,
                            badgeText: achievementBadgeText
                        ) {
                            showingAchievements = true
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                        .frame(height: 12)
                    
                    // Bottom Action Buttons (secondary)
                    HStack(spacing: 8) {
                        SecondaryButton(
                            icon: "chart.bar.fill",
                            title: "Stats",
                            color: .blue
                        ) {
                            showingStats = true
                        }
                        
                        SecondaryButton(
                            icon: "gearshape.fill",
                            title: "Settings",
                            color: .gray
                        ) {
                            showingAbout = true
                        }
                        
                        SecondaryButton(
                            icon: "envelope.fill",
                            title: "Feedback",
                            color: .green
                        ) {
                            showingFeedback = true
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .adaptiveContentWidth() // Apply iPad-friendly centering
            }
            .navigationDestination(isPresented: $showingGame) {
                if let currentCase = currentCase {
                    GameView(medicalCase: currentCase, isDailyCase: isDailyCase)
                }
            }
            .sheet(isPresented: $showingStats) {
                StatsView()
            }
            .sheet(isPresented: $showingCaseHistory) {
                CaseHistoryView()
            }
            .sheet(isPresented: $showingAchievements) {
                AchievementsView()
            }
            .sheet(isPresented: $showingCategoryAnalytics) {
                CategoryAnalyticsView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingCaseBrowser) {
                CaseBrowserView()
            }
            .sheet(isPresented: $showingFeedback) {
                FeedbackSheet()
            }
            .sheet(isPresented: $showingPaywall) {
                RoundsPaywallView(
                    onPurchaseCompleted: { _ in
                        // Show confetti celebration
                        showingConfetti = true
                        // Hide confetti after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showingConfetti = false
                        }
                    },
                    onRestoreCompleted: { _ in
                        if subscriptionManager.isProUser {
                            showingConfetti = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showingConfetti = false
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
                    .interactiveDismissDisabled() // Prevent accidental swipe to dismiss
            }
            .overlay {
                ConfettiView(isActive: $showingConfetti)
            }
            .alert("Daily Case Complete! ✅", isPresented: $showingDailyCompleteAlert) {
                Button("View Stats") {
                    showingStats = true
                }
                Button("Play Random Case") {
                    startRandomGame()
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("You've already completed today's daily case! Come back tomorrow for a new challenge, or play a random case now.")
            }
            .onAppear {
                // Track analytics
                AnalyticsManager.shared.trackAppLaunch()
                SessionTracker.shared.startSession()
                
                // Show onboarding for first-time users (only check once per app launch)
                if !hasCompletedOnboarding && !hasCheckedOnboarding {
                    hasCheckedOnboarding = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showOnboarding = true
                    }
                }
            }
        }
    }
    
    @MainActor
    private func trackAppLaunchSafely() async {
        // Track analytics in a safe, non-blocking way
        AnalyticsManager.shared.trackAppLaunch()
        SessionTracker.shared.startSession()
    }
    
    private func startNewGame() {
        // Use deterministic seed based on current date for "daily" case
        // This ensures ALL users get the same case on the same day
        let seed = Self.getDailyCaseSeed()
        var generator = SeededRandomNumberGenerator(seed: seed)
        
        let cases = CaseLibrary.getSampleCases()
        if let randomCase = cases.randomElement(using: &generator) {
            currentCase = randomCase
            isDailyCase = true
            showingGame = true
        }
    }
    
    /// Generate a deterministic seed from the current date
    /// This is the same for all users worldwide on the same calendar day
    static func getDailyCaseSeed() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        // Create a deterministic integer: YYYYMMDD format
        let year = components.year ?? 2025
        let month = components.month ?? 1
        let day = components.day ?? 1
        return year * 10000 + month * 100 + day
    }
    
    /// Get the daily case number (days since Jan 1, 2025)
    static func getDailyCaseNumber() -> Int {
        guard let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1)) else {
            // Fallback: use a simple day-of-year calculation
            let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            let yearsSince2025 = (components.year ?? 2025) - 2025
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
            return yearsSince2025 * 365 + dayOfYear
        }
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0
        return daysSinceStart + 1
    }
    
    private func startRandomGame() {
        if let randomCase = CaseLibrary.getRandomCase() {
            currentCase = randomCase
            isDailyCase = false
            showingGame = true
        }
    }
}

// MARK: - Quick Stat View
struct QuickStat: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .bold()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Feature Card Button
struct FeatureCardButton: View {
    let icon: String
    let title: String
    let color: Color
    var isPro: Bool = false
    var isProUser: Bool = true
    var badgeText: String? = nil
    let action: () -> Void
    
    private var isLocked: Bool {
        isPro && !isProUser
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    // Background circle with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: isLocked ? "lock.fill" : icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isLocked ? .gray : color)
                }
                
                // Title with optional badge/indicator inline
                HStack(spacing: 4) {
                    Text(title)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(isLocked ? .secondary : .primary)
                        .lineLimit(1)
                    
                    // Small badge or PRO indicator inline
                    if let badge = badgeText {
                        Text(badge)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(color)
                    } else if isLocked {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.orange)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: color.opacity(0.15), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(isLocked ? 0.7 : 1.0)
    }
}

// MARK: - Secondary Button (for Stats, Settings, Feedback)
struct SecondaryButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6).opacity(0.8))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Streak & Stats View
struct CompactStreakStatsView: View {
    let stats: PlayerStats
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    
    var body: some View {
        VStack(spacing: 10) {
            // Streak Section - Compact
            HStack(spacing: 10) {
                // Fire emoji
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.3), .red.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Text("🔥")
                        .font(.system(size: 30))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(stats.currentStreak)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("Day Streak")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Text(streakMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        // Streak Freeze indicator for Pro users
                        if subscriptionManager.isProUser && stats.streakFreezesAvailable > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "snowflake")
                                    .font(.system(size: 10))
                                Text("\(stats.streakFreezesAvailable)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.cyan.opacity(0.15))
                            .cornerRadius(6)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Compact Heatmap
            if stats.gamesPlayed > 0 {
                HStack(spacing: 4) {
                    ForEach((0..<7).reversed(), id: \.self) { dayIndex in
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colorForDay(dayIndex, stats: stats))
                                .frame(width: 36, height: 36)
                            
                            Text(dayLabel(for: dayIndex))
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Stats Row - Compact
            HStack(spacing: 0) {
                QuickStat(label: "Played", value: "\(stats.gamesPlayed)")
                    .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 30)
                
                QuickStat(label: "Win Rate", value: "\(stats.winPercentage)%")
                    .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 30)
                
                QuickStat(label: "Best", value: "\(stats.maxStreak)")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        )
    }
    
    private var streakMessage: String {
        if stats.currentStreak == 0 {
            return "Start today! 💪"
        } else if stats.currentStreak == 1 {
            return "Great start! 🌟"
        } else if stats.currentStreak < 7 {
            return "On fire! 🚀"
        } else if stats.currentStreak < 30 {
            return "Amazing! 🎯"
        } else {
            return "Legendary! 👑"
        }
    }
    
    private func colorForDay(_ dayIndex: Int, stats: PlayerStats) -> Color {
        // dayIndex 0 = today, 1 = yesterday, 2 = 2 days ago, etc.
        
        guard let lastPlayed = stats.lastPlayedDate else {
            return Color(.systemGray5)
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastPlayedDay = calendar.startOfDay(for: lastPlayed)
        let daysSinceLastPlayed = calendar.dateComponents([.day], from: lastPlayedDay, to: today).day ?? 0
        
        // If current streak is active
        if stats.currentStreak > 0 {
            // Show the last N days as active where N = currentStreak
            // For example: if streak is 3, show today, yesterday, and 2 days ago as active
            if dayIndex < stats.currentStreak {
                // More recent days are brighter
                let intensity = 1.0 - (Double(dayIndex) * 0.12)
                return Color.orange.opacity(max(0.6, intensity))
            }
        } else {
            // No streak, but we might have played recently
            // Show last played day if within the 7-day window
            if dayIndex == daysSinceLastPlayed && dayIndex < 7 {
                return Color.gray.opacity(0.5)
            }
        }
        
        return Color(.systemGray5)
    }
    
    private func dayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -index, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).prefix(1).uppercased()
    }
}

// MARK: - Gamified Streak Card (Keep for backwards compatibility)
struct StreakCardView: View {
    let stats: PlayerStats
    
    var body: some View {
        CompactStreakStatsView(stats: stats)
    }
}

// MARK: - Stats Card (Keep for backwards compatibility)
struct StatsCardView: View {
    let stats: PlayerStats
    
    var body: some View {
        EmptyView()
    }
}

// MARK: - Activity Heatmap (Keep for backwards compatibility)
struct ActivityHeatmapView: View {
    let stats: PlayerStats
    
    var body: some View {
        EmptyView()
    }
}

// MARK: - Seeded Random Number Generator
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: Int) {
        state = UInt64(truncatingIfNeeded: seed)
    }
    
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PlayerStats.self], inMemory: true)
}

// MARK: - Achievement Progress Badge

struct AchievementProgressBadge: View {
    @Query private var progressList: [AchievementProgress]
    
    private var progress: AchievementProgress? {
        progressList.first
    }
    
    private var unlockedCount: Int {
        progress?.unlockedAchievements.count ?? 0
    }
    
    private var totalCount: Int {
        Achievement.allCases.count
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "trophy.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
            
            Text("\(unlockedCount)/\(totalCount)")
                .font(.caption)
                .fontWeight(.semibold)
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - Streak Freeze Indicator

struct StreakFreezeIndicator: View {
    let freezesAvailable: Int
    let isPro: Bool
    
    var body: some View {
        if isPro && freezesAvailable > 0 {
            HStack(spacing: 4) {
                Image(systemName: "snowflake")
                    .font(.caption2)
                Text("\(freezesAvailable)")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.cyan)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.cyan.opacity(0.15))
            .cornerRadius(8)
        }
    }
}

import MessageUI

struct FeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""

    private var mailtoURL: URL? {
        let to = "support@braskgroup.com"
        let subject = "Rounds Feedback"
        let body = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(to)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body)"
        return URL(string: urlString)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tell us what you think")
                    .font(.headline)

                TextEditor(text: $message)
                    .frame(height: 180)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))

                Button {
                    if let url = mailtoURL {
                        UIApplication.shared.open(url)
                    }
                    dismiss()
                } label: {
                    Label("Send via Mail", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Feedback")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

