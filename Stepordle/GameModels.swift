//
//  GameModels.swift
//  Stepordle
//
//  Created by Ali Mirza on 12/9/25.
//

import Foundation
import SwiftData

// MARK: - Medical Case
@Model
final class MedicalCase {
    var id: UUID
    var diagnosis: String
    var alternativeNames: [String] // Accept alternative spellings/names
    var hints: [String] // 5 progressive hints
    var category: String // e.g., "Cardiology", "Neurology"
    var difficulty: Int // 1-5
    var dateAdded: Date
    
    init(diagnosis: String, alternativeNames: [String] = [], hints: [String], category: String, difficulty: Int = 3) {
        self.id = UUID()
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
enum GameState: Codable {
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
    var id: UUID
    var caseID: UUID
    var guesses: [String] // Store guess strings
    var hintsRevealed: Int
    var gameState: GameState
    var timestamp: Date
    var score: Int // Points based on guesses used
    
    var maxGuesses: Int {
        return 5
    }
    
    var maxHints: Int {
        return 5
    }
    
    init(caseID: UUID) {
        self.id = UUID()
        self.caseID = caseID
        self.guesses = []
        self.hintsRevealed = 1 // Start with first hint visible
        self.gameState = .playing
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
        let guessePenalty = guesses.count * 100
        let hintPenalty = max(0, hintsRevealed - 1) * 50 // First hint is free
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
    var gamesPlayed: Int
    var gamesWon: Int
    var currentStreak: Int
    var maxStreak: Int
    var totalScore: Int
    var guessDistribution: [Int] // Index = number of guesses (0-4 for 1-5 guesses)
    var lastPlayedDate: Date?
    var lastDailyCasePlayed: String? // Store date string like "2025-12-13"
    
    init() {
        self.gamesPlayed = 0
        self.gamesWon = 0
        self.currentStreak = 0
        self.maxStreak = 0
        self.totalScore = 0
        self.guessDistribution = [0, 0, 0, 0, 0]
        self.lastPlayedDate = nil
        self.lastDailyCasePlayed = nil
    }
    
    func recordGame(won: Bool, guessCount: Int, score: Int) {
        gamesPlayed += 1
        let today = Date()
        let calendar = Calendar.current
        let todayDay = calendar.startOfDay(for: today)
        
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
                    // Gap of more than 1 day - reset streak to 1
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
}

