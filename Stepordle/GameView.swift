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
    
    init(medicalCase: MedicalCase) {
        _currentCase = State(initialValue: medicalCase)
        _gameSession = State(initialValue: GameSession(caseID: medicalCase.id))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Hints Section
                hintsSection
                
                // Previous Guesses
                if !gameSession.guesses.isEmpty {
                    previousGuessesSection
                }
                
                // Input Section
                if gameSession.gameState == .playing {
                    inputSection
                } else {
                    resultSection
                }
            }
            .padding()
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
        }
        .sheet(isPresented: $showingStats) {
            StatsView()
        }
        .alert("Result", isPresented: $showingResult) {
            Button("OK") { }
        } message: {
            Text(resultMessage)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Label("\(gameSession.guesses.count)/\(gameSession.maxGuesses)", systemImage: "brain.head.profile")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label("\(gameSession.hintsRevealed)/\(gameSession.maxHints)", systemImage: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text(currentCase.category)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .foregroundStyle(.blue)
                .cornerRadius(8)
        }
    }
    
    // MARK: - Hints Section
    private var hintsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Previous Guesses Section
    private var previousGuessesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Previous Guesses")
                .font(.headline)
            
            ForEach(Array(gameSession.guesses.enumerated()), id: \.offset) { index, guess in
                let isLastGuess = index == gameSession.guesses.count - 1
                let isCorrectGuess = gameSession.gameState == .won && isLastGuess
                
                HStack {
                    Image(systemName: isCorrectGuess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrectGuess ? .green : .red)
                    Text(guess)
                        .font(.body)
                    Spacer()
                }
                .padding()
                .background(isCorrectGuess ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(spacing: 16) {
            Text("What's your diagnosis?")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("Enter diagnosis", text: $currentGuess)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .onChange(of: currentGuess) { oldValue, newValue in
                        updateSuggestions(for: newValue)
                    }
                
                // Suggestions
                if showingSuggestions && !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                currentGuess = suggestion
                                showingSuggestions = false
                            } label: {
                                Text(suggestion)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            
                            if suggestion != suggestions.last {
                                Divider()
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 4)
                }
            }
            
            Button {
                submitGuess()
            } label: {
                Text("Submit Diagnosis")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(currentGuess.isEmpty ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
            .disabled(currentGuess.isEmpty)
        }
    }
    
    // MARK: - Result Section
    private var resultSection: some View {
        VStack(spacing: 20) {
            if gameSession.gameState == .won {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    
                    Text("Correct Diagnosis!")
                        .font(.title2)
                        .bold()
                    
                    Text(currentCase.diagnosis)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.green)
                        .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    HStack(spacing: 32) {
                        VStack(spacing: 4) {
                            Text("\(gameSession.score)")
                                .font(.title)
                                .bold()
                            Text("Score")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(gameSession.guesses.count)")
                                .font(.title)
                                .bold()
                            Text("Guesses")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(gameSession.hintsRevealed)")
                                .font(.title)
                                .bold()
                            Text("Hints Used")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                    
                    Text("Out of Guesses")
                        .font(.title2)
                        .bold()
                    
                    Text("The correct diagnosis was:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(currentCase.diagnosis)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.blue)
                        .padding(.horizontal)
                    
                    if !currentCase.alternativeNames.isEmpty {
                        VStack(spacing: 4) {
                            Text("Also accepted:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(currentCase.alternativeNames.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            
            Button {
                // This will be handled by parent view
            } label: {
                Text("Play Again")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
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
        
        currentGuess = ""
        showingSuggestions = false
    }
    
    private func updateSuggestions(for text: String) {
        guard !text.isEmpty else {
            suggestions = []
            showingSuggestions = false
            return
        }
        
        // Simple suggestion system - in a real app, you'd have a comprehensive diagnosis database
        let commonDiagnoses = [
            "Myocardial Infarction", "Stroke", "Pneumonia", "Diabetes Mellitus",
            "Hypertension", "Heart Failure", "Asthma", "COPD", "Multiple Sclerosis",
            "Parkinson's Disease", "Alzheimer's Disease", "Epilepsy", "Migraine",
            "Gastroesophageal Reflux Disease", "Peptic Ulcer", "Crohn's Disease",
            "Ulcerative Colitis", "Cirrhosis", "Hepatitis", "Pancreatitis",
            "Appendicitis", "Cholecystitis", "Acute Kidney Injury", "Chronic Kidney Disease",
            "Urinary Tract Infection", "Pyelonephritis", "Pneumothorax", "Pulmonary Embolism",
            "Deep Vein Thrombosis", "Atrial Fibrillation", "Ventricular Tachycardia",
            "Diabetic Ketoacidosis", "Hyperthyroidism", "Hypothyroidism", "Cushing's Syndrome",
            "Addison's Disease", "Rheumatoid Arthritis", "Osteoarthritis", "Gout",
            "Systemic Lupus Erythematosus", "Scleroderma", "Anemia", "Leukemia",
            "Lymphoma", "Sickle Cell Disease", "Hemophilia", "Bacterial Meningitis",
            "Viral Meningitis", "Encephalitis", "Cellulitis", "Sepsis",
            "Major Depressive Disorder", "Bipolar Disorder", "Schizophrenia", "Anxiety Disorder"
        ]
        
        suggestions = commonDiagnoses.filter { diagnosis in
            diagnosis.lowercased().contains(text.lowercased())
        }.prefix(5).map { $0 }
        
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
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .frame(width: 32, height: 32)
                .background(isRevealed ? Color.blue : Color.gray)
                .foregroundStyle(.white)
                .clipShape(Circle())
            
            if isRevealed {
                Text(hint)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.gray)
                    Text("Locked")
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(isRevealed ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        GameView(medicalCase: CaseLibrary.getSampleCases()[0])
            .modelContainer(for: [GameSession.self, PlayerStats.self], inMemory: true)
    }
}
