//
//  GameView.swift
//  Rounds
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
    @State private var showingInputSheet = false
    @State private var showingLevelUp = false
    @State private var newLevel: MedicalTrainingLevel?
    @State private var showConfetti = false
    @FocusState private var isTextFieldFocused: Bool
    let isDailyCase: Bool
    
    init(medicalCase: MedicalCase, isDailyCase: Bool = false) {
        _currentCase = State(initialValue: medicalCase)
        _gameSession = State(initialValue: GameSession(caseID: medicalCase.id))
        self.isDailyCase = isDailyCase
        
        // Track case started
        AnalyticsManager.shared.trackCaseStarted(
            caseID: medicalCase.id.uuidString,
            isDaily: isDailyCase
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content - full screen scrollable
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
                    
                    // Result section if game is over
                    if gameSession.gameState != .playing {
                        resultSection
                            .padding(.horizontal)
                    }
                    
                    // Add bottom padding to ensure content doesn't hide behind button
                    Spacer()
                        .frame(height: gameSession.gameState == .playing ? 100 : 20)
                }
            }
            
            // Floating action buttons for input (only when playing)
            if gameSession.gameState == .playing {
                HStack(spacing: 12) {
                    // Primary Enter Diagnosis button (2/3 width, on left)
                    Button {
                        showingInputSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "stethoscope")
                                .font(.body)
                            Text(gameSession.hintsRevealed >= gameSession.maxHints ? "Make Final Guess" : "Enter Diagnosis")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(gameSession.hintsRevealed >= gameSession.maxHints ? Color.orange : Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    
                    // Reveal Hint button (1/3 width, on right, similar style)
                    if gameSession.canRevealHint() {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                gameSession.revealNextHint()
                            }
                            HapticManager.shared.hintRevealed()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.body)
                                Text("Hint")
                                    .fontWeight(.semibold)
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .frame(width: 90)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Rounds")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            ConfettiView(isActive: $showConfetti)
        )
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
        .sheet(isPresented: $showingInputSheet) {
            DiagnosisInputSheet(
                currentGuess: $currentGuess,
                suggestions: $suggestions,
                showingSuggestions: $showingSuggestions,
                onSubmit: {
                    submitGuess()
                    showingInputSheet = false
                },
                onTextChange: updateSuggestions,
                isFinalGuess: gameSession.hintsRevealed >= gameSession.maxHints
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Result", isPresented: $showingResult) {
            Button("OK") { }
        } message: {
            Text(resultMessage)
        }
        .sheet(isPresented: $showingLevelUp) {
            if let level = newLevel {
                LevelUpView(level: level)
            }
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
            
            // Final hint warning
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
            HapticManager.shared.incorrectGuess()
            resultMessage = "You've already guessed '\(trimmedGuess)'. Try a different diagnosis."
            showingResult = true
            return
        }
        
        let isCorrect = currentCase.isCorrectDiagnosis(trimmedGuess)
        let previousGuessCount = gameSession.guesses.count
        
        let isFinalChance = gameSession.hintsRevealed >= gameSession.maxHints && gameSession.gameState == .playing
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            gameSession.makeGuess(trimmedGuess, isCorrect: isCorrect)
        }
        
        // Only update stats if the guess was actually added (not a duplicate)
        if gameSession.guesses.count > previousGuessCount {
            if isCorrect {
                HapticManager.shared.correctGuess()
                resultMessage = "Correct! You diagnosed \(currentCase.diagnosis) in \(gameSession.guesses.count) guess(es)!"
                
                // Trigger confetti!
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showConfetti = false
                }
                
                updateStats(won: true)
            } else if gameSession.gameState == .lost {
                HapticManager.shared.incorrectGuess()
                resultMessage = "Game Over! The correct diagnosis was \(currentCase.diagnosis)."
                updateStats(won: false)
            } else {
                // Incorrect but game continues
                HapticManager.shared.incorrectGuess()
                // Auto-reveal next hint with haptic
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    HapticManager.shared.hintRevealed()
                }
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
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func updateStats(won: Bool) {
        // Fetch or create player stats
        let descriptor = FetchDescriptor<PlayerStats>()
        if let stats = try? modelContext.fetch(descriptor).first {
            // Check level before adding score
            let oldLevel = stats.trainingLevel
            
            stats.recordGame(won: won, guessCount: gameSession.guesses.count, score: gameSession.score)
            
            // Check if level changed
            let newLevelData = stats.trainingLevel
            if newLevelData.rank != oldLevel.rank || newLevelData.level != oldLevel.level {
                newLevel = newLevelData
                // Delay showing level up until after game completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showingLevelUp = true
                }
            }
            
            // Mark daily case as completed
            if isDailyCase {
                stats.markDailyCaseCompleted()
            }
            
            // Check for streak milestones
            if stats.currentStreak % 7 == 0 && stats.currentStreak > 0 {
                AnalyticsManager.shared.trackStreakMilestone(streak: stats.currentStreak)
                AppStoreReviewManager.shared.streakAchieved(stats.currentStreak)
            }
        } else {
            let newStats = PlayerStats()
            newStats.recordGame(won: won, guessCount: gameSession.guesses.count, score: gameSession.score)
            
            // Mark daily case as completed
            if isDailyCase {
                newStats.markDailyCaseCompleted()
            }
            
            modelContext.insert(newStats)
        }
        
        try? modelContext.save()
        
        // Track completion analytics
        AnalyticsManager.shared.trackCaseCompleted(
            caseID: currentCase.id.uuidString,
            won: won,
            guesses: gameSession.guesses.count,
            hints: gameSession.hintsRevealed,
            score: gameSession.score,
            isDaily: isDailyCase
        )
        
        // Request review after wins
        AppStoreReviewManager.shared.gameCompleted(won: won)
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
        let to = "support@braskgroup.com"
        let subject = "Rounds - Case Report: \(caseTitle)"
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
// MARK: - Diagnosis Input Sheet
struct DiagnosisInputSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var currentGuess: String
    @Binding var suggestions: [String]
    @Binding var showingSuggestions: Bool
    @FocusState private var isTextFieldFocused: Bool
    let onSubmit: () -> Void
    let onTextChange: (String) -> Void
    let isFinalGuess: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Input section at top
                VStack(spacing: 12) {
                    TextField("Enter diagnosis", text: $currentGuess)
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .focused($isTextFieldFocused)
                        .onChange(of: currentGuess) { oldValue, newValue in
                            onTextChange(newValue)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Submit button - full width
                    Button {
                        onSubmit()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isFinalGuess ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                                .font(.body)
                            Text(isFinalGuess ? "Submit Final Answer!" : "Check My Answer")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(currentGuess.isEmpty ? Color.gray : (isFinalGuess ? Color.orange : Color.blue))
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(currentGuess.isEmpty)
                    .padding(.horizontal)
                }
                .padding(.bottom, 12)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Suggestions list - takes remaining space
                if showingSuggestions && !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack {
                            Text("Suggested Diagnoses")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(suggestions.count) matches")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        
                        Divider()
                        
                        // Scrollable suggestions
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button {
                                        currentGuess = suggestion
                                        showingSuggestions = false
                                        isTextFieldFocused = false
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(suggestion)
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                                    .multilineTextAlignment(.leading)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.up.left.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(.blue)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 14)
                                        .background(Color(.systemBackground))
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                    }
                } else if currentGuess.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "text.cursor")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text("Start typing to see diagnosis suggestions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                } else {
                    // No matches
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("No matches found")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("Try a different spelling or diagnosis name")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                }
            }
            .navigationTitle("Enter Diagnosis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Level Up Celebration View
struct LevelUpView: View {
    @Environment(\.dismiss) private var dismiss
    let level: MedicalTrainingLevel
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Card
            VStack(spacing: 24) {
                // Celebration Icon
                ZStack {
                    Circle()
                        .fill(colorForString(level.color).opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: level.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(colorForString(level.color))
                }
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 30))
                        .foregroundStyle(.yellow)
                        .offset(x: -50, y: -50)
                        .rotationEffect(.degrees(-15))
                )
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundStyle(.yellow)
                        .offset(x: 50, y: -40)
                        .rotationEffect(.degrees(15))
                )
                
                VStack(spacing: 8) {
                    Text("Level Up!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(level.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(colorForString(level.color))
                    
                    Text(level.title)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Congratulations message
                Text(getCongratulatoryMessage(for: level))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Continue button
                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(colorForString(level.color))
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(32)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
    
    private func getCongratulatoryMessage(for level: MedicalTrainingLevel) -> String {
        switch level.rank {
        case "MS1", "MS2":
            return "You're building a strong foundation in medical knowledge!"
        case "MS3", "MS4":
            return "Your clinical reasoning skills are developing nicely!"
        case "Intern":
            return "You're handling cases like a true intern! Keep it up!"
        case "Resident":
            return "Your diagnostic skills are at resident level! Impressive!"
        case "Fellow":
            return "You're specializing in excellence! Outstanding work!"
        case "Attending":
            return "You're diagnosing like an attending physician! Exceptional!"
        case "Chief":
            return "Leadership level achieved! You're a medical expert!"
        case "Legend":
            return "You're a true medical legend! Simply outstanding!"
        default:
            return "Amazing progress! Keep learning and growing!"
        }
    }
    
    private func colorForString(_ colorString: String) -> Color {
        switch colorString {
        case "cyan": return .cyan
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "indigo": return .indigo
        case "orange": return .orange
        case "red": return .red
        case "yellow": return .yellow
        case "pink": return .pink
        case "mint": return .mint
        case "teal": return .teal
        default: return .blue
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                ConfettiPieceView(piece: piece)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: isActive) { oldValue, newValue in
            if newValue {
                generateConfetti()
            } else {
                confettiPieces.removeAll()
            }
        }
    }
    
    private func generateConfetti() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .pink, .purple, .cyan]
        confettiPieces = (0..<100).map { _ in
            ConfettiPiece(
                color: colors.randomElement()!,
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: -50,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.0)
            )
        }
    }
}
struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var yOffset: CGFloat = 0
    @State private var rotationAmount: Double = 0
    
    var body: some View {
        Circle()
            .fill(piece.color)
            .frame(width: 10 * piece.scale, height: 10 * piece.scale)
            .rotationEffect(.degrees(rotationAmount))
            .position(x: piece.x, y: piece.y + yOffset)
            .onAppear {
                withAnimation(
                    .easeIn(duration: Double.random(in: 1.5...3.0))
                ) {
                    yOffset = UIScreen.main.bounds.height + 100
                    rotationAmount = Double.random(in: 360...1080)
                }
            }
    }
}


