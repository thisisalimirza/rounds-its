//
//  GameModels.swift
//  Rounds
//
//  Created by Ali Mirza on 12/9/25.
//

import Foundation
import SwiftData
import CryptoKit

// MARK: - Medical Case
@Model
final class MedicalCase {
    var id: UUID = UUID()
    var diagnosis: String = ""
    var alternativeNames: [String] = [] // Accept alternative spellings/names
    var hints: [String] = [] // 5 progressive hints
    var category: String = "" // e.g., "Cardiology", "Neurology"
    var difficulty: Int = 3 // 1-5
    var dateAdded: Date = Date()
    
    init(diagnosis: String, alternativeNames: [String] = [], hints: [String], category: String, difficulty: Int = 3) {
        // Generate a deterministic UUID from the diagnosis so the same case always has the same ID
        self.id = Self.deterministicID(for: diagnosis)
        self.diagnosis = diagnosis
        self.alternativeNames = alternativeNames
        
        // Ensure we have exactly 5 hints (pad with empty strings or truncate if needed)
        if hints.count < 5 {
            self.hints = hints + Array(repeating: "Additional clue coming soon", count: 5 - hints.count)
        } else if hints.count > 5 {
            self.hints = Array(hints.prefix(5))
        } else {
            self.hints = hints
        }
        
        self.category = category
        self.difficulty = max(1, min(5, difficulty)) // Clamp difficulty between 1-5
        self.dateAdded = Date()
    }
    
    /// Generate a deterministic UUID from the diagnosis string
    /// This ensures the same case always has the same ID across app launches
    static func deterministicID(for diagnosis: String) -> UUID {
        // Create a consistent hash from the diagnosis using SHA256 (deterministic)
        let normalizedDiagnosis = diagnosis.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let inputString = "rounds.case.\(normalizedDiagnosis)"
        let inputData = Data(inputString.utf8)
        
        // Use CryptoKit SHA256 for deterministic hashing
        let hash = SHA256.hash(data: inputData)
        let hashBytes = Array(hash)
        
        // Use first 16 bytes of SHA256 hash for UUID
        return UUID(uuid: (hashBytes[0], hashBytes[1], hashBytes[2], hashBytes[3],
                          hashBytes[4], hashBytes[5], hashBytes[6], hashBytes[7],
                          hashBytes[8], hashBytes[9], hashBytes[10], hashBytes[11],
                          hashBytes[12], hashBytes[13], hashBytes[14], hashBytes[15]))
    }
    
    func isCorrectDiagnosis(_ guess: String) -> Bool {
        // Normalize: lowercase, trim whitespace, remove extra spaces
        let normalizedGuess = guess.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        guard !normalizedGuess.isEmpty else { return false }
        
        let normalizedDiagnosis = diagnosis.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        if normalizedGuess == normalizedDiagnosis {
            return true
        }
        
        // Check alternative names with same normalization
        return alternativeNames.contains { alt in
            let normalizedAlt = alt.lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            return normalizedAlt == normalizedGuess
        }
    }
}

// MARK: - Game State
enum GameState: String, Codable, Equatable, Sendable {
    case playing
    case won
    case lost
}

// MARK: - Guess Result
struct GuessResult: Identifiable, Codable {
    let id: UUID
    let guess: String
    let isCorrect: Bool
    let timestamp: Date
    
    init(guess: String, isCorrect: Bool) {
        self.id = UUID()
        self.guess = guess
        self.isCorrect = isCorrect
        self.timestamp = Date()
    }
}

// MARK: - Game Session
@Model
final class GameSession {
    var id: UUID = UUID()
    var caseID: UUID = UUID()
    var guesses: [String] = [] // Store guess strings
    var hintsRevealed: Int = 1
    var hintsRevealedAtWin: Int = 0 // Track how many hints were visible when they won (for scoring)
    var gameStateRaw: String = "playing" // Store as String for CloudKit compatibility
    var timestamp: Date = Date()
    var score: Int = 0 // Points based on guesses used

    var maxGuesses: Int {
        return 5
    }

    var maxHints: Int {
        return 5
    }

    // Computed property to access as enum
    var gameState: GameState {
        get { GameState(rawValue: gameStateRaw) ?? .playing }
        set { gameStateRaw = newValue.rawValue }
    }

    init(caseID: UUID) {
        self.id = UUID()
        self.caseID = caseID
        self.guesses = []
        self.hintsRevealed = 1 // Start with first hint visible
        self.hintsRevealedAtWin = 0 // Will be set when player wins
        self.gameStateRaw = GameState.playing.rawValue
        self.timestamp = Date()
        self.score = 0
    }
    
    func makeGuess(_ guess: String, isCorrect: Bool) {
        guard gameState == .playing else { return }
        guard !guess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Avoid duplicate guesses
        let normalizedGuess = guess.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let isDuplicate = guesses.contains { existingGuess in
            existingGuess.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalizedGuess
        }

        guard !isDuplicate else { return }

        // Determine whether we're already at the final phase BEFORE this guess
        let wasAtMaxHints = hintsRevealed >= maxHints

        // Record the guess
        guesses.append(guess)

        if isCorrect {
            // Save how many hints they had when they won (for scoring)
            hintsRevealedAtWin = hintsRevealed
            
            // Reveal all remaining hints so they can see the full picture
            hintsRevealed = maxHints
            
            gameState = .won
            calculateScore()
            return
        }

        // If all hints were already revealed before this guess, this was the final chance
        if wasAtMaxHints {
            gameState = .lost
            score = 0
            return
        }

        // Otherwise, reveal the next hint (progressive hint system)
        if hintsRevealed < maxHints {
            hintsRevealed += 1
        }

        // Fallback: if we hit the max guesses limit, end the game as lost
        if guesses.count >= maxGuesses {
            gameState = .lost
            score = 0
        }
    }
    
    private func calculateScore() {
        // Score: 500 base points - (100 * guesses used) - (50 * extra hints revealed)
        // Use hintsRevealedAtWin for scoring (the actual number they saw when they won)
        let guessePenalty = guesses.count * 100
        let hintPenalty = max(0, hintsRevealedAtWin - 1) * 50 // First hint is free
        score = max(0, 500 - guessePenalty - hintPenalty)
    }
    
    func canRevealHint() -> Bool {
        return hintsRevealed < maxHints && gameState == .playing
    }
    
    func revealNextHint() {
        if canRevealHint() {
            hintsRevealed += 1
        }
    }
}

// MARK: - Player Statistics
@Model
final class PlayerStats {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var currentStreak: Int = 0
    var maxStreak: Int = 0
    var totalScore: Int = 0
    var guessDistribution: [Int] = [0, 0, 0, 0, 0] // Index = number of guesses (0-4 for 1-5 guesses)
    var lastPlayedDate: Date?
    var lastDailyCasePlayed: String? // Store date string like "2025-12-13"
    var favoriteCaseIDs: [String] = [] // Store UUIDs as strings

    // Streak Freeze (Pro Feature)
    var streakFreezesAvailable: Int = 1
    var lastStreakFreezeReset: Date?
    var streakFreezeUsedToday: Bool = false
    
    // Computed property for current training level
    var trainingLevel: MedicalTrainingLevel {
        MedicalTrainingLevel.level(for: totalScore)
    }
    
    init() {
        self.gamesPlayed = 0
        self.gamesWon = 0
        self.currentStreak = 0
        self.maxStreak = 0
        self.totalScore = 0
        self.guessDistribution = [0, 0, 0, 0, 0]
        self.lastPlayedDate = nil
        self.lastDailyCasePlayed = nil
        self.favoriteCaseIDs = []
        self.streakFreezesAvailable = 1  // Pro users get 1 per week
        self.lastStreakFreezeReset = nil
        self.streakFreezeUsedToday = false
    }
    
    // MARK: - Streak Freeze Logic
    
    /// Check and reset weekly streak freeze for Pro users
    func checkWeeklyStreakFreezeReset(isPro: Bool) {
        guard isPro else {
            streakFreezesAvailable = 0
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Reset on Monday each week
        if let lastReset = lastStreakFreezeReset {
            let weekday = calendar.component(.weekday, from: today)
            let lastWeekday = calendar.component(.weekday, from: lastReset)
            let daysSinceReset = calendar.dateComponents([.day], from: lastReset, to: today).day ?? 0
            
            // Reset if it's Monday and we haven't reset this week, or if it's been 7+ days
            if (weekday == 2 && lastWeekday != 2) || daysSinceReset >= 7 {
                streakFreezesAvailable = 1
                lastStreakFreezeReset = today
                streakFreezeUsedToday = false
            }
        } else {
            // First time - give them a freeze
            streakFreezesAvailable = 1
            lastStreakFreezeReset = today
        }
    }
    
    /// Check if user can save their streak with a freeze
    /// Returns true if: they have a streak, missed a day, have freezes available, and are Pro
    func canSaveStreak(isPro: Bool) -> Bool {
        guard isPro,
              currentStreak > 0,
              streakFreezesAvailable > 0,
              !streakFreezeUsedToday,
              let lastPlayed = lastPlayedDate else {
            return false
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastPlayedDay = calendar.startOfDay(for: lastPlayed)
        let daysSinceLastPlayed = calendar.dateComponents([.day], from: lastPlayedDay, to: today).day ?? 0

        // Can only save if missed exactly 1 day (gap of 2 days)
        return daysSinceLastPlayed == 2
    }

    /// Manually use a streak freeze to save the streak
    /// Call this when user taps "Save My Streak" button
    /// Returns true if successful
    func saveStreakWithFreeze(isPro: Bool) -> Bool {
        guard canSaveStreak(isPro: isPro) else {
            return false
        }

        streakFreezesAvailable -= 1
        streakFreezeUsedToday = true
        // Update lastPlayedDate to yesterday so streak continues normally
        let calendar = Calendar.current
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
            lastPlayedDate = yesterday
        }
        return true
    }

    /// Check if streak is about to be lost (missed a day but no freeze used yet)
    func isStreakAtRisk() -> Bool {
        guard currentStreak > 0, let lastPlayed = lastPlayedDate else {
            return false
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastPlayedDay = calendar.startOfDay(for: lastPlayed)
        let daysSinceLastPlayed = calendar.dateComponents([.day], from: lastPlayedDay, to: today).day ?? 0

        return daysSinceLastPlayed >= 2
    }
    
    func recordGame(won: Bool, guessCount: Int, score: Int, isPro: Bool = false) {
        gamesPlayed += 1
        let today = Date()
        let calendar = Calendar.current
        let todayDay = calendar.startOfDay(for: today)
        
        // Check and reset weekly streak freeze for Pro users
        checkWeeklyStreakFreezeReset(isPro: isPro)
        
        // Reset streakFreezeUsedToday if it's a new day
        if let lastPlayed = lastPlayedDate {
            let lastPlayedDay = calendar.startOfDay(for: lastPlayed)
            if todayDay != lastPlayedDay {
                streakFreezeUsedToday = false
            }
        }
        
        if won {
            gamesWon += 1
            totalScore += score
            
            // Update streak logic - only increment once per day
            if let lastPlayed = lastPlayedDate {
                let lastPlayedDay = calendar.startOfDay(for: lastPlayed)
                let daysBetween = calendar.dateComponents([.day], from: lastPlayedDay, to: todayDay).day ?? 0
                
                if daysBetween == 0 {
                    // Already played today - don't change streak
                    // Just record the win
                } else if daysBetween == 1 {
                    // Played yesterday - continue the streak!
                    currentStreak += 1
                    maxStreak = max(maxStreak, currentStreak)
                } else if daysBetween > 1 {
                    // Gap of more than 1 day - streak breaks (unless user manually used freeze earlier)
                    // The freeze must be used BEFORE playing, not automatically during play
                    currentStreak = 1
                    maxStreak = max(maxStreak, currentStreak)
                }
            } else {
                // First game ever - start streak at 1
                currentStreak = 1
                maxStreak = 1
            }
            
            // Record guess distribution with bounds checking
            if guessCount > 0 && guessCount <= guessDistribution.count {
                guessDistribution[guessCount - 1] += 1
            }
        } else {
            // Lost game - only break streak if this is our first game today
            if let lastPlayed = lastPlayedDate {
                let lastPlayedDay = calendar.startOfDay(for: lastPlayed)
                let daysBetween = calendar.dateComponents([.day], from: lastPlayedDay, to: todayDay).day ?? 0
                
                if daysBetween == 1 || daysBetween > 1 {
                    // First game today and it's a loss - break the streak
                    currentStreak = 0
                }
                // If daysBetween == 0, we already played today, don't break streak again
            } else {
                // First game ever and it's a loss - streak stays at 0
                currentStreak = 0
                maxStreak = 0
            }
        }
        
        lastPlayedDate = today
    }
    
    var winPercentage: Int {
        guard gamesPlayed > 0 else { return 0 }
        return Int((Double(gamesWon) / Double(gamesPlayed)) * 100)
    }
    
    var averageScore: Int {
        guard gamesWon > 0 else { return 0 }
        return totalScore / gamesWon
    }
    
    // MARK: - Daily Case Tracking
    func markDailyCaseCompleted() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        lastDailyCasePlayed = formatter.string(from: Date())
    }
    
    func hasPlayedDailyCaseToday() -> Bool {
        guard let lastDaily = lastDailyCasePlayed else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        return lastDaily == todayString
    }
    
    // MARK: - Favorites
    func toggleFavorite(caseID: UUID) {
        let idString = caseID.uuidString
        if let index = favoriteCaseIDs.firstIndex(of: idString) {
            favoriteCaseIDs.remove(at: index)
        } else {
            favoriteCaseIDs.append(idString)
        }
    }
    
    func isFavorite(caseID: UUID) -> Bool {
        return favoriteCaseIDs.contains(caseID.uuidString)
    }
}

// MARK: - Case History Entry
@Model
final class CaseHistoryEntry {
    var id: UUID = UUID()
    var caseID: UUID = UUID()
    var diagnosis: String = ""
    var category: String = ""
    var difficulty: Int = 3
    var wasCorrect: Bool = false
    var guessCount: Int = 0
    var score: Int = 0
    var hintsUsed: Int = 0
    var playedAt: Date = Date()
    var guesses: [String] = []
    var wasDailyCase: Bool = false
    
    init(
        caseID: UUID,
        diagnosis: String,
        category: String,
        difficulty: Int,
        wasCorrect: Bool,
        guessCount: Int,
        score: Int,
        hintsUsed: Int,
        guesses: [String],
        wasDailyCase: Bool
    ) {
        self.id = UUID()
        self.caseID = caseID
        self.diagnosis = diagnosis
        self.category = category
        self.difficulty = difficulty
        self.wasCorrect = wasCorrect
        self.guessCount = guessCount
        self.score = score
        self.hintsUsed = hintsUsed
        self.playedAt = Date()
        self.guesses = guesses
        self.wasDailyCase = wasDailyCase
    }
}

// MARK: - Leaderboard Visibility Level

enum LeaderboardVisibility: String, Codable, CaseIterable {
    case schoolOnly = "school"
    case global = "global"

    var displayName: String {
        switch self {
        case .schoolOnly: return "School Only"
        case .global: return "Global"
        }
    }

    var description: String {
        switch self {
        case .schoolOnly:
            return "Only students at your school will see your name"
        case .global:
            return "Your name will appear on state, national, and global leaderboards"
        }
    }
}

// MARK: - Leaderboard Scope

enum LeaderboardScope: String, CaseIterable {
    case school = "School"
    case state = "State"
    case country = "Country"
    case national = "National"
    case global = "Global"

    var icon: String {
        switch self {
        case .school: return "building.columns.fill"
        case .state: return "map.fill"
        case .country: return "flag.fill"
        case .national: return "flag.filled.and.flag.crossed"
        case .global: return "globe.americas.fill"
        }
    }
}

// MARK: - Leaderboard Profile (Local Cache)

@Model
final class LeaderboardProfile {
    var playerID: String = UUID().uuidString
    var displayName: String = ""
    var schoolID: String = ""
    var schoolName: String = ""
    var state: String = ""
    var country: String = "US"
    var isInternational: Bool = false
    var visibilityLevelRaw: String = LeaderboardVisibility.schoolOnly.rawValue
    var lastSyncedScore: Int = 0
    var lastSyncedAt: Date?
    var cloudKitRecordID: String?

    init(
        playerID: String = UUID().uuidString,
        displayName: String,
        schoolID: String,
        schoolName: String,
        state: String,
        country: String = "US",
        isInternational: Bool = false,
        visibilityLevel: LeaderboardVisibility = .schoolOnly
    ) {
        self.playerID = playerID
        self.displayName = displayName
        self.schoolID = schoolID
        self.schoolName = schoolName
        self.state = state
        self.country = country
        self.isInternational = isInternational
        self.visibilityLevelRaw = visibilityLevel.rawValue
        self.lastSyncedScore = 0
        self.lastSyncedAt = nil
        self.cloudKitRecordID = nil
    }
}

// MARK: - LeaderboardProfile Computed Properties (Extension)
// Computed properties in extensions are NOT processed by SwiftData's schema reflection

extension LeaderboardProfile {
    /// Convenience to access visibility as enum
    var visibilityLevel: LeaderboardVisibility {
        get { LeaderboardVisibility(rawValue: visibilityLevelRaw) ?? .schoolOnly }
        set { visibilityLevelRaw = newValue.rawValue }
    }

    /// Get the appropriate scopes for this player
    var availableScopes: [LeaderboardScope] {
        if isInternational {
            return [.school, .country, .global]
        } else {
            return [.school, .state, .national, .global]
        }
    }
}

// MARK: - Leaderboard Entry (For Display)

struct LeaderboardEntry: Identifiable, Equatable {
    let id: String
    let playerID: String
    let displayName: String
    let schoolID: String
    let schoolName: String
    let state: String
    let country: String
    let totalScore: Int
    let gamesPlayed: Int
    let gamesWon: Int
    let rank: Int
    let isCurrentUser: Bool

    var winPercentage: Int {
        guard gamesPlayed > 0 else { return 0 }
        return Int((Double(gamesWon) / Double(gamesPlayed)) * 100)
    }

    var averageScore: Int {
        guard gamesWon > 0 else { return 0 }
        return totalScore / gamesWon
    }

    /// Get training level based on total score
    var trainingLevel: MedicalTrainingLevel {
        MedicalTrainingLevel.level(for: totalScore)
    }
}

// MARK: - School Ranking Entry (Aggregated)

struct SchoolRankingEntry: Identifiable, Equatable {
    let id: String // schoolID
    let schoolID: String
    let schoolName: String
    let state: String
    let country: String
    let totalScore: Int // Sum of all students' scores
    let studentCount: Int
    let totalGamesPlayed: Int
    let totalGamesWon: Int
    let rank: Int
    let isCurrentUserSchool: Bool

    var averageScore: Int {
        guard studentCount > 0 else { return 0 }
        return totalScore / studentCount
    }

    var averageGamesPlayed: Double {
        guard studentCount > 0 else { return 0 }
        return Double(totalGamesPlayed) / Double(studentCount)
    }

    var winPercentage: Int {
        guard totalGamesPlayed > 0 else { return 0 }
        return Int((Double(totalGamesWon) / Double(totalGamesPlayed)) * 100)
    }

    /// Formatted win rate for display (e.g., "75%")
    var winRate: String {
        "\(winPercentage)%"
    }

    /// Formatted average score per student for display
    var avgScorePerStudent: String {
        "\(averageScore)"
    }

    /// Create from a group of LeaderboardEntry items
    static func aggregate(entries: [LeaderboardEntry], rank: Int, currentUserSchoolID: String?) -> SchoolRankingEntry? {
        guard let first = entries.first else { return nil }

        let totalScore = entries.reduce(0) { $0 + $1.totalScore }
        let totalGamesPlayed = entries.reduce(0) { $0 + $1.gamesPlayed }
        let totalGamesWon = entries.reduce(0) { $0 + $1.gamesWon }

        return SchoolRankingEntry(
            id: first.schoolID,
            schoolID: first.schoolID,
            schoolName: first.schoolName,
            state: first.state,
            country: first.country,
            totalScore: totalScore,
            studentCount: entries.count,
            totalGamesPlayed: totalGamesPlayed,
            totalGamesWon: totalGamesWon,
            rank: rank,
            isCurrentUserSchool: first.schoolID == currentUserSchoolID
        )
    }
}

// MARK: - Leaderboard View Mode

enum LeaderboardViewMode: String, CaseIterable {
    case individuals = "Individuals"
    case schools = "Schools"

    var icon: String {
        switch self {
        case .individuals: return "person.fill"
        case .schools: return "building.columns.fill"
        }
    }
}

// MARK: - Medical Training Level System
struct MedicalTrainingLevel: Equatable {
    let rank: String
    let level: Int
    let title: String
    let minScore: Int
    let maxScore: Int
    let icon: String
    let color: String
    
    var displayTitle: String {
        "\(rank) - Level \(level)"
    }
    
    var progressToNextLevel: Double {
        guard maxScore > minScore else { return 1.0 }
        let currentProgress = Double(maxScore - minScore)
        let totalRange = Double(maxScore - minScore)
        return currentProgress / totalRange
    }
    
    static func level(for score: Int) -> MedicalTrainingLevel {
        return allLevels.last { score >= $0.minScore } ?? allLevels[0]
    }
    
    static func nextLevel(for score: Int) -> MedicalTrainingLevel? {
        let currentIndex = allLevels.firstIndex { score >= $0.minScore && score < $0.maxScore } ?? allLevels.count - 1
        guard currentIndex < allLevels.count - 1 else { return nil }
        return allLevels[currentIndex + 1]
    }
    
    static let allLevels: [MedicalTrainingLevel] = [
        // Medical Student Levels (0-4,999 points)
        MedicalTrainingLevel(rank: "MS1", level: 1, title: "Medical Student - Year 1", minScore: 0, maxScore: 499, icon: "book.fill", color: "cyan"),
        MedicalTrainingLevel(rank: "MS1", level: 2, title: "Medical Student - Year 1", minScore: 500, maxScore: 999, icon: "book.fill", color: "cyan"),
        MedicalTrainingLevel(rank: "MS2", level: 1, title: "Medical Student - Year 2", minScore: 1000, maxScore: 1499, icon: "book.fill", color: "cyan"),
        MedicalTrainingLevel(rank: "MS2", level: 2, title: "Medical Student - Year 2", minScore: 1500, maxScore: 1999, icon: "book.fill", color: "cyan"),
        MedicalTrainingLevel(rank: "MS3", level: 1, title: "Medical Student - Year 3", minScore: 2000, maxScore: 2499, icon: "stethoscope", color: "blue"),
        MedicalTrainingLevel(rank: "MS3", level: 2, title: "Medical Student - Year 3", minScore: 2500, maxScore: 2999, icon: "stethoscope", color: "blue"),
        MedicalTrainingLevel(rank: "MS4", level: 1, title: "Medical Student - Year 4", minScore: 3000, maxScore: 3499, icon: "stethoscope", color: "blue"),
        MedicalTrainingLevel(rank: "MS4", level: 2, title: "Medical Student - Year 4", minScore: 3500, maxScore: 4999, icon: "stethoscope", color: "blue"),
        
        // Intern Levels (5,000-9,999 points)
        MedicalTrainingLevel(rank: "Intern", level: 1, title: "Intern", minScore: 5000, maxScore: 5999, icon: "cross.case.fill", color: "green"),
        MedicalTrainingLevel(rank: "Intern", level: 2, title: "Intern", minScore: 6000, maxScore: 6999, icon: "cross.case.fill", color: "green"),
        MedicalTrainingLevel(rank: "Intern", level: 3, title: "Intern", minScore: 7000, maxScore: 7999, icon: "cross.case.fill", color: "green"),
        MedicalTrainingLevel(rank: "Intern", level: 4, title: "Intern", minScore: 8000, maxScore: 9999, icon: "cross.case.fill", color: "green"),
        
        // Resident Levels (10,000-24,999 points)
        MedicalTrainingLevel(rank: "Resident", level: 1, title: "Junior Resident", minScore: 10000, maxScore: 11999, icon: "heart.text.square.fill", color: "purple"),
        MedicalTrainingLevel(rank: "Resident", level: 2, title: "Junior Resident", minScore: 12000, maxScore: 13999, icon: "heart.text.square.fill", color: "purple"),
        MedicalTrainingLevel(rank: "Resident", level: 3, title: "Senior Resident", minScore: 14000, maxScore: 15999, icon: "heart.text.square.fill", color: "purple"),
        MedicalTrainingLevel(rank: "Resident", level: 4, title: "Senior Resident", minScore: 16000, maxScore: 17999, icon: "heart.text.square.fill", color: "purple"),
        MedicalTrainingLevel(rank: "Resident", level: 5, title: "Chief Resident", minScore: 18000, maxScore: 19999, icon: "star.circle.fill", color: "indigo"),
        MedicalTrainingLevel(rank: "Resident", level: 6, title: "Chief Resident", minScore: 20000, maxScore: 24999, icon: "star.circle.fill", color: "indigo"),
        
        // Fellow Levels (25,000-39,999 points)
        MedicalTrainingLevel(rank: "Fellow", level: 1, title: "Clinical Fellow", minScore: 25000, maxScore: 27999, icon: "brain.head.profile", color: "orange"),
        MedicalTrainingLevel(rank: "Fellow", level: 2, title: "Clinical Fellow", minScore: 28000, maxScore: 30999, icon: "brain.head.profile", color: "orange"),
        MedicalTrainingLevel(rank: "Fellow", level: 3, title: "Senior Fellow", minScore: 31000, maxScore: 34999, icon: "brain.head.profile", color: "orange"),
        MedicalTrainingLevel(rank: "Fellow", level: 4, title: "Senior Fellow", minScore: 35000, maxScore: 39999, icon: "brain.head.profile", color: "orange"),
        
        // Attending Levels (40,000-69,999 points)
        MedicalTrainingLevel(rank: "Attending", level: 1, title: "Junior Attending", minScore: 40000, maxScore: 44999, icon: "shield.fill", color: "red"),
        MedicalTrainingLevel(rank: "Attending", level: 2, title: "Junior Attending", minScore: 45000, maxScore: 49999, icon: "shield.fill", color: "red"),
        MedicalTrainingLevel(rank: "Attending", level: 3, title: "Attending Physician", minScore: 50000, maxScore: 54999, icon: "shield.fill", color: "red"),
        MedicalTrainingLevel(rank: "Attending", level: 4, title: "Attending Physician", minScore: 55000, maxScore: 59999, icon: "shield.fill", color: "red"),
        MedicalTrainingLevel(rank: "Attending", level: 5, title: "Senior Attending", minScore: 60000, maxScore: 69999, icon: "crown.fill", color: "yellow"),
        
        // Department Chief Levels (70,000-99,999 points)
        MedicalTrainingLevel(rank: "Chief", level: 1, title: "Division Chief", minScore: 70000, maxScore: 79999, icon: "medal.fill", color: "pink"),
        MedicalTrainingLevel(rank: "Chief", level: 2, title: "Department Chief", minScore: 80000, maxScore: 89999, icon: "medal.fill", color: "pink"),
        MedicalTrainingLevel(rank: "Chief", level: 3, title: "Chief of Medicine", minScore: 90000, maxScore: 99999, icon: "trophy.fill", color: "yellow"),
        
        // Legendary Levels (100,000+ points)
        MedicalTrainingLevel(rank: "Legend", level: 1, title: "Professor of Medicine", minScore: 100000, maxScore: 149999, icon: "graduationcap.fill", color: "mint"),
        MedicalTrainingLevel(rank: "Legend", level: 2, title: "Distinguished Professor", minScore: 150000, maxScore: 199999, icon: "star.square.fill", color: "teal"),
        MedicalTrainingLevel(rank: "Legend", level: 3, title: "Medical Luminary", minScore: 200000, maxScore: Int.max, icon: "sparkles", color: "purple")
    ]
}

