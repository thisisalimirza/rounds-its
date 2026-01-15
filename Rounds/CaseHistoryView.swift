//
//  CaseHistoryView.swift
//  Rounds
//
//  Case history for Pro members - review past cases and learn from mistakes
//

import SwiftUI
import SwiftData

struct CaseHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CaseHistoryEntry.playedAt, order: .reverse) private var historyEntries: [CaseHistoryEntry]
    
    @State private var selectedFilter: HistoryFilter = .all
    @State private var selectedEntry: CaseHistoryEntry?
    @State private var showingDetail = false
    
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    
    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case correct = "Correct"
        case incorrect = "Missed"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .correct: return "checkmark.circle"
            case .incorrect: return "xmark.circle"
            }
        }
    }
    
    private var filteredEntries: [CaseHistoryEntry] {
        switch selectedFilter {
        case .all:
            return historyEntries
        case .correct:
            return historyEntries.filter { $0.wasCorrect }
        case .incorrect:
            return historyEntries.filter { !$0.wasCorrect }
        }
    }
    
    private var stats: (total: Int, correct: Int, incorrect: Int) {
        let correct = historyEntries.filter { $0.wasCorrect }.count
        return (historyEntries.count, correct, historyEntries.count - correct)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats Header
                statsHeader
                
                // Filter Picker
                filterPicker
                
                // History List
                if filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    historyList
                }
            }
            .navigationTitle("Case History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let entry = selectedEntry {
                    CaseHistoryDetailView(entry: entry)
                }
            }
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        HStack(spacing: 0) {
            StatBox(
                value: "\(stats.total)",
                label: "Total",
                color: .blue
            )
            
            Divider()
                .frame(height: 40)
            
            StatBox(
                value: "\(stats.correct)",
                label: "Correct",
                color: .green
            )
            
            Divider()
                .frame(height: 40)
            
            StatBox(
                value: "\(stats.incorrect)",
                label: "Missed",
                color: .red
            )
            
            Divider()
                .frame(height: 40)
            
            StatBox(
                value: stats.total > 0 ? "\(Int(Double(stats.correct) / Double(stats.total) * 100))%" : "—",
                label: "Accuracy",
                color: .purple
            )
        }
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Filter Picker
    
    private var filterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HistoryFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter,
                        count: countFor(filter)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    private func countFor(_ filter: HistoryFilter) -> Int {
        switch filter {
        case .all: return historyEntries.count
        case .correct: return stats.correct
        case .incorrect: return stats.incorrect
        }
    }
    
    // MARK: - History List
    
    private var historyList: some View {
        List {
            ForEach(filteredEntries) { entry in
                Button {
                    selectedEntry = entry
                    showingDetail = true
                } label: {
                    CaseHistoryRow(entry: entry)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete(perform: deleteEntries)
        }
        .listStyle(.plain)
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = filteredEntries[index]
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: selectedFilter == .all ? "clock.badge.questionmark" : 
                  selectedFilter == .correct ? "checkmark.circle" : "xmark.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all: return "No Cases Yet"
        case .correct: return "No Correct Cases"
        case .incorrect: return "No Missed Cases"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all: return "Your case history will appear here after you play some cases."
        case .correct: return "Cases you diagnose correctly will appear here."
        case .incorrect: return "Great job! You haven't missed any cases yet. Keep it up!"
        }
    }
}

// MARK: - Stat Box

private struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color(.systemGray5))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Case History Row

struct CaseHistoryRow: View {
    let entry: CaseHistoryEntry
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: entry.playedAt, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Result indicator
            ZStack {
                Circle()
                    .fill(entry.wasCorrect ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: entry.wasCorrect ? "checkmark" : "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(entry.wasCorrect ? .green : .red)
            }
            
            // Case info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.diagnosis)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if entry.wasDailyCase {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                HStack(spacing: 8) {
                    // Category tag
                    Text(entry.category)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor(for: entry.category).opacity(0.15))
                        .foregroundStyle(categoryColor(for: entry.category))
                        .cornerRadius(4)
                    
                    // Difficulty stars
                    HStack(spacing: 1) {
                        ForEach(0..<entry.difficulty, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.yellow)
                        }
                    }
                    
                    Spacer()
                    
                    // Time ago
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Hints indicator
            VStack(alignment: .trailing, spacing: 4) {
                // Hint pills showing how many were needed
                HStack(spacing: 3) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index < entry.hintsUsed ? hintColor(for: entry.hintsUsed) : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(hintLabel(for: entry.hintsUsed))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(hintColor(for: entry.hintsUsed))
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Cardiology": return .red
        case "Neurology": return .purple
        case "Pulmonology": return .blue
        case "Gastroenterology": return .orange
        case "Endocrinology": return .green
        case "Nephrology": return .cyan
        case "Hematology": return .pink
        case "Infectious Disease": return .yellow
        case "Rheumatology": return .indigo
        case "Psychiatry": return .mint
        default: return .gray
        }
    }
    
    private func hintColor(for hints: Int) -> Color {
        switch hints {
        case 1: return .green      // Amazing - got it on first hint!
        case 2: return .mint       // Great
        case 3: return .blue       // Good
        case 4: return .orange     // Okay
        case 5: return .red        // Needed all hints
        default: return .gray
        }
    }
    
    private func hintLabel(for hints: Int) -> String {
        switch hints {
        case 1: return "1st hint! 🔥"
        case 2: return "2 hints"
        case 3: return "3 hints"
        case 4: return "4 hints"
        case 5: return "All hints"
        default: return "\(hints) hints"
        }
    }
}

// MARK: - Case History Detail View

struct CaseHistoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: CaseHistoryEntry
    
    @State private var showingReplayConfirm = false
    @State private var replayCase: MedicalCase?
    @State private var showingGame = false
    
    // Get the full case with all hints
    private var fullCase: MedicalCase? {
        let allCases = CaseLibrary.getSampleCases()
        return allCases.first { $0.id == entry.caseID }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Result Header
                    resultHeader
                    
                    // Stats Card
                    statsCard
                    
                    // Your Guesses
                    guessesCard
                    
                    // All Hints Card (Educational - show all hints)
                    if let medicalCase = fullCase {
                        allHintsCard(hints: medicalCase.hints)
                    }
                    
                    // Replay Button (for missed cases)
                    if !entry.wasCorrect {
                        replayButton
                    }
                }
                .padding()
            }
            .navigationTitle("Case Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Replay This Case?", isPresented: $showingReplayConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Replay") {
                    if let caseToReplay = fullCase {
                        replayCase = caseToReplay
                        showingGame = true
                    }
                }
            } message: {
                Text("You can try this case again to practice. Your score won't be recorded.")
            }
            .navigationDestination(isPresented: $showingGame) {
                if let caseToReplay = replayCase {
                    GameView(medicalCase: caseToReplay, isDailyCase: false)
                }
            }
        }
    }
    
    // MARK: - Result Header
    
    private var resultHeader: some View {
        VStack(spacing: 16) {
            // Result icon
            ZStack {
                Circle()
                    .fill(entry.wasCorrect ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: entry.wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(entry.wasCorrect ? .green : .red)
            }
            
            // Diagnosis - tappable to open AMBOSS
            Button {
                openAMBOSS(for: entry.diagnosis)
            } label: {
                HStack(spacing: 6) {
                    Text(entry.diagnosis)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.subheadline)
                }
                .foregroundStyle(entry.wasCorrect ? .green : .red)
            }
            .buttonStyle(.plain)
            
            Text("Tap to learn more on AMBOSS")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            // Category & Difficulty
            HStack(spacing: 12) {
                // Category
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.caption)
                    Text(entry.category)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                // Difficulty
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < entry.difficulty ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(index < entry.difficulty ? .yellow : .gray)
                    }
                }
                
                if entry.wasDailyCase {
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("Daily")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.orange)
                }
            }
            
            // Date played
            Text("Played \(entry.playedAt.formatted(date: .long, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance")
                .font(.headline)
            
            // Hints visualization - the main metric
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(index < entry.hintsUsed ? hintColorForDetail(entry.hintsUsed) : Color(.systemGray5))
                                    .frame(width: 36, height: 36)
                                
                                if index < entry.hintsUsed {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                }
                            }
                            
                            Text("\(index + 1)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Text(hintMessageForDetail(entry.hintsUsed))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(hintColorForDetail(entry.hintsUsed))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            
            Divider()
            
            // Secondary stats
            HStack(spacing: 0) {
                DetailStatBox(
                    icon: "number",
                    value: "\(entry.guessCount)",
                    label: "Guesses",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 40)
                
                DetailStatBox(
                    icon: "star.fill",
                    value: entry.wasCorrect ? "+\(entry.score)" : "0",
                    label: "Points",
                    color: entry.wasCorrect ? .green : .gray
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func hintColorForDetail(_ hints: Int) -> Color {
        switch hints {
        case 1: return .green
        case 2: return .mint
        case 3: return .blue
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }
    
    private func hintMessageForDetail(_ hints: Int) -> String {
        switch hints {
        case 1: return "Amazing! Got it on the first hint! 🔥"
        case 2: return "Great job! Only needed 2 hints"
        case 3: return "Good work with 3 hints"
        case 4: return "Solved with 4 hints"
        case 5: return "Used all 5 hints"
        default: return "Used \(hints) hints"
        }
    }
    
    // MARK: - Guesses Card
    
    private var guessesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Guesses")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(Array(entry.guesses.enumerated()), id: \.offset) { index, guess in
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(guessColor(for: index, total: entry.guesses.count))
                            .cornerRadius(12)
                        
                        Text(guess)
                            .font(.body)
                        
                        Spacer()
                        
                        if index == entry.guesses.count - 1 && entry.wasCorrect {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
            }
            
            if !entry.wasCorrect {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    
                    Text("The correct answer was: **\(entry.diagnosis)**")
                        .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func guessColor(for index: Int, total: Int) -> Color {
        if index == total - 1 && entry.wasCorrect {
            return .green
        }
        return .gray.opacity(0.6)
    }
    
    // MARK: - All Hints Card
    
    private func allHintsCard(hints: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Clinical Clues")
                    .font(.headline)
            }
            
            Text("Review all diagnostic hints for this case to deepen your understanding.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                ForEach(Array(hints.enumerated()), id: \.offset) { index, hint in
                    HStack(alignment: .top, spacing: 12) {
                        // Hint number badge
                        ZStack {
                            Circle()
                                .fill(hintBadgeColor(for: index))
                                .frame(width: 32, height: 32)
                            
                            Text("\(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        
                        // Hint text
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hint)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Show if user revealed this hint during play
                            if index < entry.hintsUsed {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption2)
                                    Text("Revealed during play")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.green)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "eye.slash.fill")
                                        .font(.caption2)
                                    Text("Not revealed")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(index < entry.hintsUsed ? Color.yellow.opacity(0.05) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(index < entry.hintsUsed ? Color.yellow.opacity(0.3) : Color(.systemGray5), lineWidth: 1)
                    )
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func hintBadgeColor(for index: Int) -> Color {
        // Color gradient from green (first hint) to red (last hint) to show progression
        switch index {
        case 0: return .green
        case 1: return .mint
        case 2: return .blue
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }
    
    // MARK: - Replay Button
    
    private var replayButton: some View {
        Button {
            showingReplayConfirm = true
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("Try Again")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
    }
    
    private func openAMBOSS(for diagnosis: String) {
        let query = diagnosis.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? diagnosis
        if let url = URL(string: "https://next.amboss.com/us/search?q=\(query)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Detail Stat Box

private struct DetailStatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    CaseHistoryView()
        .modelContainer(for: [CaseHistoryEntry.self, PlayerStats.self], inMemory: true)
}

