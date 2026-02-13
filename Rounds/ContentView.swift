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
    @State private var showingLeaderboard = false
    @State private var selectedTab: HomeTab = .play
    @State private var playButtonScale: CGFloat = 1.0
    @State private var showingStreakRecovery = false
    @State private var streakRecoveryChecked = false
    @State private var showingWhatsNew = false
    @StateObject private var whatsNewManager = WhatsNewManager.shared

    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }

    private var stats: PlayerStats {
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
                // Adaptive gradient background (light/dark mode)
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Compact Header
                    HStack {
                        // Logo + Title
                        HStack(spacing: 10) {
                            Image(systemName: "cross.case.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Rounds")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            if subscriptionManager.isProUser {
                                ProBadge(size: .small)
                            }
                        }

                        Spacer()

                        // Streak Pill
                        StreakPillAdaptive(streak: stats.currentStreak, freezes: stats.streakFreezesAvailable, isPro: subscriptionManager.isProUser)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    // MARK: - Main Content (Tab-based)
                    TabView(selection: $selectedTab) {
                        // PLAY TAB
                        playTabContent
                            .tag(HomeTab.play)

                        // PROGRESS TAB
                        progressTabContent
                            .tag(HomeTab.progress)

                        // MORE TAB
                        moreTabContent
                            .tag(HomeTab.more)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // MARK: - Bottom Tab Bar
                    HomeTabBar(selectedTab: $selectedTab)
                        .padding(.bottom, 8)
                }
                .adaptiveContentWidth()
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
            .sheet(isPresented: $showingLeaderboard) {
                LeaderboardView()
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
                        showingConfetti = true
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
            .overlay {
                ConfettiView(isActive: $showingConfetti)
            }
            .alert("Daily Case Complete!", isPresented: $showingDailyCompleteAlert) {
                Button("Play Random Case") {
                    startRandomGame()
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Come back tomorrow for a new challenge, or play a random case now.")
            }
            .sheet(isPresented: $showingStreakRecovery) {
                StreakRecoverySheet(
                    streak: stats.currentStreak,
                    onSaveStreak: {
                        _ = stats.saveStreakWithFreeze(isPro: subscriptionManager.isProUser)
                        try? modelContext.save()
                    }
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingWhatsNew) {
                if let data = whatsNewManager.whatsNewData {
                    WhatsNewView(data: data) {
                        whatsNewManager.markAsSeen()
                    }
                    .presentationDetents([.large])
                    .interactiveDismissDisabled()
                }
            }
            .onAppear {
                AnalyticsManager.shared.trackAppLaunch()
                SessionTracker.shared.startSession()

                // Check if user needs to save their streak (only once per app launch)
                if !streakRecoveryChecked {
                    streakRecoveryChecked = true
                    stats.checkWeeklyStreakFreezeReset(isPro: subscriptionManager.isProUser)
                    if stats.canSaveStreak(isPro: subscriptionManager.isProUser) {
                        showingStreakRecovery = true
                    }
                }

                // Check for deep linked case
                checkForDeepLinkedCase()
            }
            .task {
                // Check for What's New content (runs async on appear)
                await whatsNewManager.checkForWhatsNew()
                if whatsNewManager.shouldShowWhatsNew {
                    // Small delay to let other UI settle
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    showingWhatsNew = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Also check when app becomes active (in case opened via URL while running)
                checkForDeepLinkedCase()
            }
        }
    }

    // MARK: - Play Tab Content
    private var playTabContent: some View {
        VStack(spacing: 16) {
            Spacer()

            // Daily Case Number
            Text("Case #\(Self.getDailyCaseNumber())")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .tracking(2)

            // HERO: Daily Case Button
            Button {
                if hasPlayedDailyToday {
                    showingDailyCompleteAlert = true
                } else {
                    startNewGame()
                }
            } label: {
                HeroDailyCaseButton(
                    isCompleted: hasPlayedDailyToday,
                    streak: stats.currentStreak
                )
            }
            .scaleEffect(playButtonScale)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    playButtonScale = hasPlayedDailyToday ? 1.0 : 1.02
                }
            }

            // Secondary Actions
            HStack(spacing: 12) {
                Button {
                    if subscriptionManager.isProUser {
                        startRandomGame()
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    PunchyActionButton(
                        icon: "shuffle",
                        title: "Random Case",
                        color: .purple,
                        isLocked: !subscriptionManager.isProUser
                    )
                }

                Button {
                    showingCaseBrowser = true
                } label: {
                    PunchyActionButton(
                        icon: "list.bullet.clipboard",
                        title: "Browse Cases",
                        color: .green,
                        isLocked: !subscriptionManager.isProUser
                    )
                }
            }
            .padding(.horizontal, 20)

            // Fun Section: Leaderboard & Badges
            HStack(spacing: 12) {
                PunchyFeatureCard(
                    icon: "trophy.fill",
                    title: "Leaderboard",
                    color: .orange
                ) {
                    showingLeaderboard = true
                }

                PunchyFeatureCard(
                    icon: "medal.fill",
                    title: "Badges",
                    badgeText: achievementBadgeText,
                    color: .yellow
                ) {
                    showingAchievements = true
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    // MARK: - Progress Tab Content
    private var progressTabContent: some View {
        VStack(spacing: 16) {
            Spacer()

            // Compact Streak Display
            CompactStreakCard(stats: stats, isPro: subscriptionManager.isProUser)
                .padding(.horizontal, 20)

            // Stats Grid (3 items - Statistics, Analytics, History)
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    PunchyFeatureCard(
                        icon: "chart.bar.fill",
                        title: "Statistics",
                        color: .blue
                    ) {
                        showingStats = true
                    }

                    PunchyFeatureCard(
                        icon: "chart.pie.fill",
                        title: "Analytics",
                        color: .indigo,
                        isLocked: !subscriptionManager.isProUser
                    ) {
                        if subscriptionManager.isProUser {
                            showingCategoryAnalytics = true
                        } else {
                            showingPaywall = true
                        }
                    }
                }

                PunchyFeatureCard(
                    icon: "clock.arrow.circlepath",
                    title: "Case History",
                    color: .cyan,
                    isLocked: !subscriptionManager.isProUser
                ) {
                    if subscriptionManager.isProUser {
                        showingCaseHistory = true
                    } else {
                        showingPaywall = true
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    // MARK: - More Tab Content
    private var moreTabContent: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 12) {
                PunchyMenuItem(icon: "gearshape.fill", title: "Settings", subtitle: "Preferences & account", color: .gray) {
                    showingAbout = true
                }

                PunchyMenuItem(icon: "envelope.fill", title: "Feedback", subtitle: "Send us your thoughts", color: .green) {
                    showingFeedback = true
                }

                if !subscriptionManager.isProUser {
                    PunchyMenuItem(icon: "crown.fill", title: "Upgrade to Pro", subtitle: "Unlock all features", color: .orange) {
                        showingPaywall = true
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
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

    private func checkForDeepLinkedCase() {
        // Check if there's a pending case from a deep link
        guard let caseIDString = DeepLinkManager.shared.consumePendingCase(),
              let caseUUID = UUID(uuidString: caseIDString) else {
            return
        }

        // Find the case in the library
        let allCases = CaseLibrary.getSampleCases()
        if let linkedCase = allCases.first(where: { $0.id == caseUUID }) {
            currentCase = linkedCase
            isDailyCase = false
            showingGame = true
        }
    }
}

// MARK: - Home Tab Enum
enum HomeTab: String, CaseIterable {
    case play = "Play"
    case progress = "Progress"
    case more = "More"

    var icon: String {
        switch self {
        case .play: return "play.circle.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .more: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Home Tab Bar (Adaptive)
struct HomeTabBar: View {
    @Binding var selectedTab: HomeTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomeTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)

                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 2)
        )
        .padding(.horizontal, 40)
    }
}

// MARK: - Streak Pill Adaptive
struct StreakPillAdaptive: View {
    let streak: Int
    let freezes: Int
    let isPro: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text("🔥")
                .font(.system(size: 16))

            Text("\(streak)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.systemBackground))
                .shadow(color: .orange.opacity(0.2), radius: 4, y: 2)
        )
    }
}

// MARK: - Hero Daily Case Button (Adaptive)
struct HeroDailyCaseButton: View {
    let isCompleted: Bool
    let streak: Int

    var body: some View {
        VStack(spacing: 12) {
            if isCompleted {
                // Completed State
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.green)
                }

                Text("Daily Complete!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)

                Text("Come back tomorrow")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // Play State
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)

                    Image(systemName: "play.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .offset(x: 2)
                }

                Text("Play Daily Case")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                if streak > 0 {
                    Text("Keep your \(streak)-day streak alive!")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                } else {
                    Text("Start your streak today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: isCompleted ? .green.opacity(0.15) : .blue.opacity(0.15), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isCompleted ? Color.green.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Punchy Action Button
struct PunchyActionButton: View {
    let icon: String
    let title: String
    let color: Color
    var isLocked: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isLocked ? "lock.fill" : icon)
                .font(.system(size: 16, weight: .semibold))

            Text(title)
                .font(.system(size: 14, weight: .semibold))

            if isLocked {
                ProBadge(size: .small)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isLocked ? color.opacity(0.5) : color)
        )
        .opacity(isLocked ? 0.8 : 1)
    }
}

// MARK: - Punchy Feature Card
struct PunchyFeatureCard: View {
    let icon: String
    let title: String
    var badgeText: String? = nil
    let color: Color
    var isLocked: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            VStack(spacing: 8) {
                ZStack {
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

                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isLocked ? .secondary : .primary)
                        .lineLimit(1)

                    if let badge = badgeText {
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(color)
                    } else if isLocked {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.orange)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: color.opacity(0.15), radius: 6, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(isLocked ? 0.7 : 1)
    }
}

// MARK: - Compact Streak Card (Progress Tab)
struct CompactStreakCard: View {
    let stats: PlayerStats
    let isPro: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 12) {
                    Text("🔥")
                        .font(.system(size: 40))

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(stats.currentStreak)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("Day Streak")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                        }

                        Text(streakMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Best streak
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stats.maxStreak)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange.opacity(0.6))
                    Text("best")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Weekly Heatmap
            HStack(spacing: 6) {
                ForEach((0..<7).reversed(), id: \.self) { dayIndex in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(colorForDay(dayIndex))
                            .frame(height: 28)

                        Text(dayLabel(for: dayIndex))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Quick stats
            HStack(spacing: 0) {
                QuickStat(label: "Played", value: "\(stats.gamesPlayed)")
                    .frame(maxWidth: .infinity)
                Divider().frame(height: 24)
                QuickStat(label: "Win Rate", value: "\(stats.winPercentage)%")
                    .frame(maxWidth: .infinity)
                Divider().frame(height: 24)
                QuickStat(label: "Best", value: "\(stats.maxStreak)")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .orange.opacity(0.1), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }

    private var streakMessage: String {
        if stats.currentStreak == 0 { return "Start today! 💪" }
        else if stats.currentStreak == 1 { return "Great start! 🌟" }
        else if stats.currentStreak < 7 { return "On fire! 🚀" }
        else if stats.currentStreak < 30 { return "Amazing! 🎯" }
        else { return "Legendary! 👑" }
    }

    private func colorForDay(_ dayIndex: Int) -> Color {
        guard stats.lastPlayedDate != nil else { return Color(.systemGray5) }
        if stats.currentStreak > 0 && dayIndex < stats.currentStreak {
            let intensity = 1.0 - (Double(dayIndex) * 0.12)
            return Color.orange.opacity(max(0.6, intensity))
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

// MARK: - Punchy Menu Item
struct PunchyMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: color.opacity(0.1), radius: 6, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Streak Recovery Sheet
struct StreakRecoverySheet: View {
    @Environment(\.dismiss) private var dismiss
    let streak: Int
    let onSaveStreak: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Warning icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 100, height: 100)

                Text("🔥")
                    .font(.system(size: 50))
            }

            VStack(spacing: 8) {
                Text("Your Streak is at Risk!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text("You missed a day, but you can save your \(streak)-day streak!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                // Save streak button
                Button {
                    onSaveStreak()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                        Text("Save My Streak")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }

                // Skip button
                Button {
                    dismiss()
                } label: {
                    Text("Let it go")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 40)

            Text("Pro members get 1 streak save per week")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

// MARK: - Quick Stat View (kept for compatibility)
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

// MARK: - Legacy Views (kept for compatibility)
struct CompactStreakStatsView: View {
    let stats: PlayerStats
    var body: some View { EmptyView() }
}

struct FeatureCardButton: View {
    let icon: String
    let title: String
    let color: Color
    var isPro: Bool = false
    var isProUser: Bool = true
    var badgeText: String? = nil
    let action: () -> Void
    var body: some View { EmptyView() }
}

struct SecondaryButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    var body: some View { EmptyView() }
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

