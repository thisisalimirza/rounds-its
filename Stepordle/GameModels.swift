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
        self.hints = hints
        self.category = category
        self.difficulty = difficulty
        self.dateAdded = Date()
    }
    
    func isCorrectDiagnosis(_ guess: String) -> Bool {
        let normalizedGuess = guess.lowercased().trimmingCharacters(in: .whitespaces)
        let normalizedDiagnosis = diagnosis.lowercased()
        
        if normalizedGuess == normalizedDiagnosis {
            return true
        }
        
        // Check alternative names
        return alternativeNames.contains { alt in
            alt.lowercased() == normalizedGuess
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
        
        guesses.append(guess)
        
        if isCorrect {
            gameState = .won
            calculateScore()
        } else if guesses.count >= maxGuesses {
            gameState = .lost
            score = 0
        } else {
            // Reveal next hint after incorrect guess
            if hintsRevealed < maxHints {
                hintsRevealed += 1
            }
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
    
    init() {
        self.gamesPlayed = 0
        self.gamesWon = 0
        self.currentStreak = 0
        self.maxStreak = 0
        self.totalScore = 0
        self.guessDistribution = [0, 0, 0, 0, 0]
        self.lastPlayedDate = nil
    }
    
    func recordGame(won: Bool, guessCount: Int, score: Int) {
        gamesPlayed += 1
        
        if won {
            gamesWon += 1
            totalScore += score
            
            if let lastPlayed = lastPlayedDate, Calendar.current.isDateInYesterday(lastPlayed) {
                currentStreak += 1
            } else if lastPlayedDate == nil || (lastPlayedDate != nil && !Calendar.current.isDateInToday(lastPlayedDate!)) {
                currentStreak = 1
            }
            
            maxStreak = max(maxStreak, currentStreak)
            
            if guessCount > 0 && guessCount <= 5 {
                guessDistribution[guessCount - 1] += 1
            }
        } else {
            currentStreak = 0
        }
        
        lastPlayedDate = Date()
    }
    
    var winPercentage: Int {
        guard gamesPlayed > 0 else { return 0 }
        return Int((Double(gamesWon) / Double(gamesPlayed)) * 100)
    }
    
    var averageScore: Int {
        guard gamesWon > 0 else { return 0 }
        return totalScore / gamesWon
    }
}
