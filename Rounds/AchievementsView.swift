//
//  AchievementsView.swift
//  Rounds
//
//  Achievement badges system - Gamification to reward progress
//

import SwiftUI
import SwiftData

// MARK: - Achievement Definition

enum Achievement: String, CaseIterable, Identifiable {
    // Getting Started
    case firstWin = "first_win"
    case firstDaily = "first_daily"
    
    // Streak Achievements
    case streak3 = "streak_3"
    case streak7 = "streak_7"
    case streak14 = "streak_14"
    case streak30 = "streak_30"
    case streak100 = "streak_100"
    
    // Mastery Achievements
    case firstHintWin = "first_hint_win"
    case perfectScore = "perfect_score"
    case speedDemon = "speed_demon"  // 10 first-hint wins
    
    // Volume Achievements
    case cases10 = "cases_10"
    case cases50 = "cases_50"
    case cases100 = "cases_100"
    case cases500 = "cases_500"
    
    // Score Achievements
    case points1000 = "points_1000"
    case points5000 = "points_5000"
    case points10000 = "points_10000"
    case points50000 = "points_50000"
    
    // Training Level Achievements
    case intern = "intern"
    case resident = "resident"
    case attending = "attending"
    
    // Special
    case categoryMaster = "category_master"  // 100% in any category (10+ cases)
    case comeback = "comeback"  // Win after using all hints
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .firstWin: return "First Diagnosis"
        case .firstDaily: return "Daily Rounds"
        case .streak3: return "Getting Started"
        case .streak7: return "Week Warrior"
        case .streak14: return "Fortnight Fighter"
        case .streak30: return "Monthly Master"
        case .streak100: return "Centurion"
        case .firstHintWin: return "Sharp Mind"
        case .perfectScore: return "Perfect Round"
        case .speedDemon: return "Speed Demon"
        case .cases10: return "Resident Ready"
        case .cases50: return "Case Veteran"
        case .cases100: return "Century Club"
        case .cases500: return "Case Commander"
        case .points1000: return "Point Collector"
        case .points5000: return "Score Seeker"
        case .points10000: return "Point Master"
        case .points50000: return "Score Legend"
        case .intern: return "Intern"
        case .resident: return "Resident"
        case .attending: return "Attending"
        case .categoryMaster: return "Specialist"
        case .comeback: return "Comeback Kid"
        }
    }
    
    var description: String {
        switch self {
        case .firstWin: return "Win your first case"
        case .firstDaily: return "Complete your first daily case"
        case .streak3: return "Achieve a 3-day streak"
        case .streak7: return "Achieve a 7-day streak"
        case .streak14: return "Achieve a 14-day streak"
        case .streak30: return "Achieve a 30-day streak"
        case .streak100: return "Achieve a 100-day streak"
        case .firstHintWin: return "Win with only the first hint"
        case .perfectScore: return "Score 400+ points in a single case"
        case .speedDemon: return "Win 10 cases on the first hint"
        case .cases10: return "Complete 10 cases"
        case .cases50: return "Complete 50 cases"
        case .cases100: return "Complete 100 cases"
        case .cases500: return "Complete 500 cases"
        case .points1000: return "Earn 1,000 total points"
        case .points5000: return "Earn 5,000 total points"
        case .points10000: return "Earn 10,000 total points"
        case .points50000: return "Earn 50,000 total points"
        case .intern: return "Reach Intern training level"
        case .resident: return "Reach Resident training level"
        case .attending: return "Reach Attending training level"
        case .categoryMaster: return "100% accuracy in a category (10+ cases)"
        case .comeback: return "Win after revealing all hints"
        }
    }
    
    var icon: String {
        switch self {
        case .firstWin: return "star.fill"
        case .firstDaily: return "calendar.badge.checkmark"
        case .streak3: return "flame"
        case .streak7: return "flame.fill"
        case .streak14: return "bolt.fill"
        case .streak30: return "crown"
        case .streak100: return "crown.fill"
        case .firstHintWin: return "brain.head.profile"
        case .perfectScore: return "target"
        case .speedDemon: return "hare.fill"
        case .cases10: return "cross.case"
        case .cases50: return "cross.case.fill"
        case .cases100: return "medal"
        case .cases500: return "medal.fill"
        case .points1000: return "bitcoinsign.circle"
        case .points5000: return "bitcoinsign.circle.fill"
        case .points10000: return "star.circle"
        case .points50000: return "star.circle.fill"
        case .intern: return "stethoscope"
        case .resident: return "stethoscope.circle"
        case .attending: return "stethoscope.circle.fill"
        case .categoryMaster: return "checkmark.seal.fill"
        case .comeback: return "arrow.uturn.up.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .firstWin, .firstDaily: return .blue
        case .streak3, .streak7: return .orange
        case .streak14, .streak30, .streak100: return .red
        case .firstHintWin, .perfectScore, .speedDemon: return .purple
        case .cases10, .cases50: return .green
        case .cases100, .cases500: return .mint
        case .points1000, .points5000: return .yellow
        case .points10000, .points50000: return .orange
        case .intern: return .cyan
        case .resident: return .indigo
        case .attending: return .pink
        case .categoryMaster: return .teal
        case .comeback: return .green
        }
    }
    
    var rarity: AchievementRarity {
        switch self {
        case .firstWin, .firstDaily, .streak3, .cases10:
            return .common
        case .streak7, .firstHintWin, .cases50, .points1000, .intern:
            return .uncommon
        case .streak14, .perfectScore, .cases100, .points5000, .resident, .comeback:
            return .rare
        case .streak30, .speedDemon, .points10000, .attending, .categoryMaster:
            return .epic
        case .streak100, .cases500, .points50000:
            return .legendary
        }
    }
}

enum AchievementRarity: String {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - Achievement Progress Model

@Model
final class AchievementProgress {
    var unlockedAchievements: [String]  // Achievement rawValues
    var firstHintWinCount: Int
    var categoryStats: [String: CategoryStat]  // Category name -> stats
    var lastStreakFreezeReset: Date?
    var streakFreezesAvailable: Int
    
    init() {
        self.unlockedAchievements = []
        self.firstHintWinCount = 0
        self.categoryStats = [:]
        self.lastStreakFreezeReset = nil
        self.streakFreezesAvailable = 0
    }
    
    func isUnlocked(_ achievement: Achievement) -> Bool {
        unlockedAchievements.contains(achievement.rawValue)
    }
    
    func unlock(_ achievement: Achievement) -> Bool {
        guard !isUnlocked(achievement) else { return false }
        unlockedAchievements.append(achievement.rawValue)
        return true
    }
    
    func recordCategoryResult(category: String, won: Bool) {
        if var stat = categoryStats[category] {
            stat.totalCases += 1
            if won { stat.wins += 1 }
            categoryStats[category] = stat
        } else {
            categoryStats[category] = CategoryStat(totalCases: 1, wins: won ? 1 : 0)
        }
    }
}

struct CategoryStat: Codable, Hashable {
    var totalCases: Int
    var wins: Int
    
    var accuracy: Double {
        guard totalCases > 0 else { return 0 }
        return Double(wins) / Double(totalCases) * 100
    }
}

// MARK: - Achievements View

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [AchievementProgress]
    @Query private var playerStats: [PlayerStats]
    
    private var progress: AchievementProgress {
        progressList.first ?? AchievementProgress()
    }
    
    private var stats: PlayerStats? {
        playerStats.first
    }
    
    private var unlockedCount: Int {
        progress.unlockedAchievements.count
    }
    
    private var totalCount: Int {
        Achievement.allCases.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress Header
                    progressHeader
                    
                    // Achievement Categories
                    achievementSection(title: "Getting Started", achievements: [.firstWin, .firstDaily])
                    achievementSection(title: "Streak Master", achievements: [.streak3, .streak7, .streak14, .streak30, .streak100])
                    achievementSection(title: "Diagnostic Excellence", achievements: [.firstHintWin, .perfectScore, .speedDemon, .comeback])
                    achievementSection(title: "Case Volume", achievements: [.cases10, .cases50, .cases100, .cases500])
                    achievementSection(title: "Point Milestones", achievements: [.points1000, .points5000, .points10000, .points50000])
                    achievementSection(title: "Career Progression", achievements: [.intern, .resident, .attending, .categoryMaster])
                }
                .padding()
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Trophy icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow.opacity(0.3), .orange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            // Progress text
            VStack(spacing: 4) {
                Text("\(unlockedCount) / \(totalCount)")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Achievements Unlocked")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(unlockedCount) / CGFloat(totalCount), height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Achievement Section
    
    private func achievementSection(title: String, achievements: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementBadge(
                        achievement: achievement,
                        isUnlocked: progress.isUnlocked(achievement)
                    )
                }
            }
        }
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(spacing: 8) {
                // Badge icon
                ZStack {
                    Circle()
                        .fill(isUnlocked ? achievement.color.opacity(0.2) : Color(.systemGray5))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 26))
                        .foregroundStyle(isUnlocked ? achievement.color : .gray.opacity(0.4))
                }
                
                // Title
                Text(achievement.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 30)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            AchievementDetailSheet(achievement: achievement, isUnlocked: isUnlocked)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: Achievement
    let isUnlocked: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Badge
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.color.opacity(0.2) : Color(.systemGray5))
                    .frame(width: 100, height: 100)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(isUnlocked ? achievement.color : .gray.opacity(0.4))
            }
            .padding(.top, 20)
            
            // Title & Description
            VStack(spacing: 8) {
                Text(achievement.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(achievement.rarity.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(achievement.rarity.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(achievement.rarity.color.opacity(0.15))
                    .cornerRadius(12)
                
                Text(achievement.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Status
            if isUnlocked {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Unlocked!")
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    Text("Not yet unlocked")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Spacer()
            
            Button("Done") {
                dismiss()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

// MARK: - Achievement Unlock Toast

struct AchievementUnlockToast: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked!")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.9))
                
                Text(achievement.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(achievement.color)
        )
        .shadow(color: achievement.color.opacity(0.4), radius: 12, x: 0, y: 6)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Achievement Manager

@MainActor
class AchievementManager {
    static let shared = AchievementManager()
    
    private init() {}
    
    /// Check and unlock achievements based on current stats
    func checkAchievements(
        stats: PlayerStats,
        progress: AchievementProgress,
        lastGameWon: Bool,
        lastGameHints: Int,
        lastGameScore: Int,
        lastGameCategory: String,
        wasDailyCase: Bool,
        modelContext: ModelContext
    ) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        
        // Record category stats
        progress.recordCategoryResult(category: lastGameCategory, won: lastGameWon)
        
        // First hint win tracking
        if lastGameWon && lastGameHints == 1 {
            progress.firstHintWinCount += 1
        }
        
        // Check each achievement
        
        // First Win
        if lastGameWon && progress.unlock(.firstWin) {
            newlyUnlocked.append(.firstWin)
        }
        
        // First Daily
        if wasDailyCase && lastGameWon && progress.unlock(.firstDaily) {
            newlyUnlocked.append(.firstDaily)
        }
        
        // Streak achievements
        if stats.currentStreak >= 3 && progress.unlock(.streak3) {
            newlyUnlocked.append(.streak3)
        }
        if stats.currentStreak >= 7 && progress.unlock(.streak7) {
            newlyUnlocked.append(.streak7)
        }
        if stats.currentStreak >= 14 && progress.unlock(.streak14) {
            newlyUnlocked.append(.streak14)
        }
        if stats.currentStreak >= 30 && progress.unlock(.streak30) {
            newlyUnlocked.append(.streak30)
        }
        if stats.currentStreak >= 100 && progress.unlock(.streak100) {
            newlyUnlocked.append(.streak100)
        }
        
        // First hint win
        if lastGameWon && lastGameHints == 1 && progress.unlock(.firstHintWin) {
            newlyUnlocked.append(.firstHintWin)
        }
        
        // Perfect score (400+)
        if lastGameScore >= 400 && progress.unlock(.perfectScore) {
            newlyUnlocked.append(.perfectScore)
        }
        
        // Speed demon (10 first-hint wins)
        if progress.firstHintWinCount >= 10 && progress.unlock(.speedDemon) {
            newlyUnlocked.append(.speedDemon)
        }
        
        // Comeback (win after all hints)
        if lastGameWon && lastGameHints >= 5 && progress.unlock(.comeback) {
            newlyUnlocked.append(.comeback)
        }
        
        // Cases played
        if stats.gamesPlayed >= 10 && progress.unlock(.cases10) {
            newlyUnlocked.append(.cases10)
        }
        if stats.gamesPlayed >= 50 && progress.unlock(.cases50) {
            newlyUnlocked.append(.cases50)
        }
        if stats.gamesPlayed >= 100 && progress.unlock(.cases100) {
            newlyUnlocked.append(.cases100)
        }
        if stats.gamesPlayed >= 500 && progress.unlock(.cases500) {
            newlyUnlocked.append(.cases500)
        }
        
        // Points
        if stats.totalScore >= 1000 && progress.unlock(.points1000) {
            newlyUnlocked.append(.points1000)
        }
        if stats.totalScore >= 5000 && progress.unlock(.points5000) {
            newlyUnlocked.append(.points5000)
        }
        if stats.totalScore >= 10000 && progress.unlock(.points10000) {
            newlyUnlocked.append(.points10000)
        }
        if stats.totalScore >= 50000 && progress.unlock(.points50000) {
            newlyUnlocked.append(.points50000)
        }
        
        // Training levels
        if stats.totalScore >= 5000 && progress.unlock(.intern) {
            newlyUnlocked.append(.intern)
        }
        if stats.totalScore >= 10000 && progress.unlock(.resident) {
            newlyUnlocked.append(.resident)
        }
        if stats.totalScore >= 40000 && progress.unlock(.attending) {
            newlyUnlocked.append(.attending)
        }
        
        // Category master (100% in category with 10+ cases)
        for (_, stat) in progress.categoryStats {
            if stat.totalCases >= 10 && stat.accuracy == 100 {
                if progress.unlock(.categoryMaster) {
                    newlyUnlocked.append(.categoryMaster)
                }
                break
            }
        }
        
        try? modelContext.save()
        
        return newlyUnlocked
    }
}

// MARK: - Preview

#Preview {
    AchievementsView()
        .modelContainer(for: [AchievementProgress.self, PlayerStats.self], inMemory: true)
}

