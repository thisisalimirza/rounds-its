//
//  GameView.swift
//  Stepordle
//
//  Created by Ali Mirza on 12/9/25.
//

import SwiftUI
import SwiftData

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentCase: MedicalCase
    @State private var gameSession: GameSession
    @State private var currentGuess = ""
    @State private var showingResult = false
    @State private var resultMessage = ""
    @State private var showingStats = false
    @State private var suggestions: [String] = []
    @State private var showingSuggestions = false
    @State private var showingReport = false
    
    init(medicalCase: MedicalCase) {
        _currentCase = State(initialValue: medicalCase)
        _gameSession = State(initialValue: GameSession(caseID: medicalCase.id))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Scrollable hints section
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerView
                        .padding(.horizontal)
                        .padding(.top, 12)
                    
                    // Hints Section
                    hintsSection
                        .padding(.horizontal)
                    
                    // Previous Guesses
                    if !gameSession.guesses.isEmpty && gameSession.gameState == .playing {
                        previousGuessesSection
                            .padding(.horizontal)
                    }
                    
                    // Add bottom padding to ensure content doesn't hide behind input
                    Spacer()
                        .frame(height: 20)
                }
            }
            
            // Fixed input/result section at bottom
            Divider()
            
            if gameSession.gameState == .playing {
                inputSection
                    .padding()
                    .background(Color(.systemBackground))
            } else {
                resultSection
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .navigationTitle("Stepordle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingStats = true
                } label: {
                    Image(systemName: "chart.bar.fill")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingReport = true
                } label: {
                    Image(systemName: "flag")
                }
            }
        }
        .sheet(isPresented: $showingStats) {
            StatsView()
        }
        .sheet(isPresented: $showingReport) {
            ReportCaseSheet(caseTitle: currentCase.diagnosis)
        }
        .alert("Result", isPresented: $showingResult) {
            Button("OK") { }
        } message: {
            Text(resultMessage)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Label("\(gameSession.guesses.count)/\(gameSession.maxGuesses)", systemImage: "brain.head.profile")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(currentCase.category)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .foregroundStyle(.blue)
                .cornerRadius(8)
            
            Spacer()
            
            Label("\(gameSession.hintsRevealed)/\(gameSession.maxHints)", systemImage: "lightbulb.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Hints Section
    private var hintsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Clinical Clues")
                .font(.headline)
            
            // Show revealed hints with bounds checking
            ForEach(0..<min(gameSession.hintsRevealed, currentCase.hints.count), id: \.self) { index in
                if index < currentCase.hints.count {
                    HintCard(
                        number: index + 1,
                        hint: currentCase.hints[index],
                        isRevealed: true
                    )
                }
            }
            
            // Show locked hints with bounds checking
            ForEach(gameSession.hintsRevealed..<currentCase.hints.count, id: \.self) { index in
                if index < currentCase.hints.count {
                    HintCard(
                        number: index + 1,
                        hint: "",
                        isRevealed: false
                    )
                }
            }
            
            // Manual reveal button
            if gameSession.canRevealHint() && gameSession.hintsRevealed < currentCase.hints.count {
                Button {
                    withAnimation {
                        gameSession.revealNextHint()
                    }
                } label: {
                    Label("Reveal Next Hint", systemImage: "eye.fill")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .cornerRadius(10)
                }
            }
            
            if gameSession.hintsRevealed >= gameSession.maxHints && gameSession.gameState == .playing {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("All hints revealed — next guess is your last!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Previous Guesses Section
    private var previousGuessesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Previous Guesses")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            ForEach(Array(gameSession.guesses.enumerated()), id: \.offset) { index, guess in
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    Text(guess)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.red.opacity(0.08))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Enter diagnosis", text: $currentGuess)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .onChange(of: currentGuess) { oldValue, newValue in
                        updateSuggestions(for: newValue)
                    }
                
                // Suggestions - overlay style
                if showingSuggestions && !suggestions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(suggestions.prefix(3), id: \.self) { suggestion in
                                Button {
                                    currentGuess = suggestion
                                    showingSuggestions = false
                                } label: {
                                    Text(suggestion)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                }
                                
                                if suggestion != suggestions.prefix(3).last {
                                    Divider()
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.1), radius: 4)
                }
            }
            
            Button {
                submitGuess()
            } label: {
                Text(gameSession.hintsRevealed >= gameSession.maxHints ? "Submit Final Guess" : "Submit Diagnosis")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(currentGuess.isEmpty ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .disabled(currentGuess.isEmpty)
        }
    }
    
    // MARK: - Result Section
    private var resultSection: some View {
        VStack(spacing: 16) {
            if gameSession.gameState == .won {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)
                    
                    Text("Correct!")
                        .font(.title2)
                        .bold()
                    
                    Text(currentCase.diagnosis)
                        .font(.body)
                        .bold()
                        .foregroundStyle(.green)
                    
                    HStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("\(gameSession.score)")
                                .font(.title3)
                                .bold()
                            Text("Score")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(gameSession.guesses.count)")
                                .font(.title3)
                                .bold()
                            Text("Guesses")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(gameSession.hintsRevealed)")
                                .font(.title3)
                                .bold()
                            Text("Hints")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.red)
                    
                    Text("Out of Guesses")
                        .font(.title2)
                        .bold()
                    
                    Text("Correct diagnosis:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(currentCase.diagnosis)
                        .font(.body)
                        .bold()
                        .foregroundStyle(.blue)
                    
                    if !currentCase.alternativeNames.isEmpty {
                        Text("Also: \(currentCase.alternativeNames.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    private func submitGuess() {
        let trimmedGuess = currentGuess.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedGuess.isEmpty else { return }
        
        // Check for duplicate guess
        let normalizedGuess = trimmedGuess.lowercased()
        let isDuplicate = gameSession.guesses.contains { existingGuess in
            existingGuess.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalizedGuess
        }
        
        if isDuplicate {
            resultMessage = "You've already guessed '\(trimmedGuess)'. Try a different diagnosis."
            showingResult = true
            return
        }
        
        let isCorrect = currentCase.isCorrectDiagnosis(trimmedGuess)
        let previousGuessCount = gameSession.guesses.count
        
        let isFinalChance = gameSession.hintsRevealed >= gameSession.maxHints && gameSession.gameState == .playing
        
        withAnimation {
            gameSession.makeGuess(trimmedGuess, isCorrect: isCorrect)
        }
        
        // Only update stats if the guess was actually added (not a duplicate)
        if gameSession.guesses.count > previousGuessCount {
            if isCorrect {
                resultMessage = "Correct! You diagnosed \(currentCase.diagnosis) in \(gameSession.guesses.count) guess(es)!"
                updateStats(won: true)
            } else if gameSession.gameState == .lost {
                resultMessage = "Game Over! The correct diagnosis was \(currentCase.diagnosis)."
                updateStats(won: false)
            }
        }
        
        if !isCorrect && isFinalChance {
            resultMessage = "Final guess incorrect. The correct diagnosis was \(currentCase.diagnosis)."
        }
        
        currentGuess = ""
        showingSuggestions = false
    }
    
    private func updateSuggestions(for text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            showingSuggestions = false
            return
        }
        // Use centralized lexicon for autocomplete
        suggestions = DiagnosisLexicon.suggestions(matching: trimmed)
        showingSuggestions = !suggestions.isEmpty
    }
    
    private func updateStats(won: Bool) {
        // Fetch or create player stats
        let descriptor = FetchDescriptor<PlayerStats>()
        if let stats = try? modelContext.fetch(descriptor).first {
            stats.recordGame(won: won, guessCount: gameSession.guesses.count, score: gameSession.score)
        } else {
            let newStats = PlayerStats()
            newStats.recordGame(won: won, guessCount: gameSession.guesses.count, score: gameSession.score)
            modelContext.insert(newStats)
        }
        
        try? modelContext.save()
    }
}

// MARK: - Hint Card
struct HintCard: View {
    let number: Int
    let hint: String
    let isRevealed: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 28, height: 28)
                .background(isRevealed ? Color.blue : Color.gray)
                .foregroundStyle(.white)
                .clipShape(Circle())
            
            if isRevealed {
                Text(hint)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text("Locked")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(isRevealed ? Color.blue.opacity(0.08) : Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Compact Hint Card
struct CompactHintCard: View {
    let number: Int
    let hint: String
    let isRevealed: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.semibold)
                .frame(width: 20, height: 20)
                .background(isRevealed ? Color.blue : Color.gray)
                .foregroundStyle(.white)
                .clipShape(Circle())
            
            if isRevealed {
                Text(hint)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                    Text("Locked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(8)
        .background(isRevealed ? Color.blue.opacity(0.08) : Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        GameView(medicalCase: CaseLibrary.getSampleCases()[0])
            .modelContainer(for: [GameSession.self, PlayerStats.self], inMemory: true)
    }
}

struct ReportCaseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let caseTitle: String
    @State private var message: String = ""

    private var mailtoURL: URL? {
        let to = "support@stepordle.app"
        let subject = "Case Report: \(caseTitle)"
        let body = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(to)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body)"
        return URL(string: urlString)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Report an issue with this case")
                    .font(.headline)

                TextEditor(text: $message)
                    .frame(height: 160)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))

                Button {
                    if let url = mailtoURL {
                        UIApplication.shared.open(url)
                    }
                    dismiss()
                } label: {
                    Label("Send via Mail", systemImage: "envelope")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Report Case")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
