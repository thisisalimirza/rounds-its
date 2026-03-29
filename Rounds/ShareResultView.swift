//
//  ShareResultView.swift
//  Rounds
//
//  Share card for viral loop functionality
//

import SwiftUI
import UIKit

// MARK: - Share Result Card
struct ShareResultCard: View {
    let won: Bool
    let diagnosis: String
    let guessCount: Int
    let hintsUsed: Int
    let score: Int
    let isDailyCase: Bool
    let dailyCaseNumber: Int?
    var streak: Int? = nil
    var schoolRank: Int? = nil
    var schoolName: String? = nil

    private var hintEmojis: String {
        // Red = hints used (bad), Green = hints remaining (good) - more intuitive
        let used = String(repeating: "🟥", count: min(hintsUsed, 5))
        let unused = String(repeating: "🟩", count: max(0, 5 - hintsUsed))
        return used + unused
    }

    private var resultEmoji: String {
        if !won { return "❌" }
        switch hintsUsed {
        case 1: return "💎"
        case 2: return "🔥"
        case 3: return "⭐️"
        case 4: return "✨"
        default: return "✅"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "cross.case.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Rounds")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Spacer()

                if isDailyCase, let caseNum = dailyCaseNumber {
                    Text("#\(caseNum)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(6)
                }
            }

            Divider()

            // Result
            VStack(spacing: 12) {
                Text(won ? "Diagnosed! \(resultEmoji)" : "Missed it \(resultEmoji)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(won ? .green : .red)

                // Hint visualization
                Text(hintEmojis)
                    .font(.title2)
                    .tracking(4)

                // Score and stats
                if won {
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("\(score)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("points")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if let streak = streak, streak > 1 {
                            VStack(spacing: 2) {
                                HStack(spacing: 2) {
                                    Text("\(streak)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Image(systemName: "flame.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.orange)
                                }
                                Text("streak")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let rank = schoolRank, rank <= 10 {
                            VStack(spacing: 2) {
                                Text("#\(rank)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.purple)
                                Text("at school")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text("Used all hints")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)

            Divider()

            // Challenge
            VStack(spacing: 6) {
                Text("Can you beat my score?")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("Download Rounds and try today's case!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .frame(width: 300)
    }
}

// MARK: - Share Text Generator
struct ShareTextGenerator {

    /// Generate share text with optional streak and rank info for viral sharing
    static func generateShareText(
        won: Bool,
        hintsUsed: Int,
        score: Int,
        guessCount: Int,
        isDailyCase: Bool,
        dailyCaseNumber: Int?,
        caseID: String? = nil,
        streak: Int? = nil,
        schoolRank: Int? = nil,
        schoolName: String? = nil
    ) -> String {
        // Wordle-style grid: 🟩 = unused hints (good), 🟥 = used hints
        // Fewer red squares = better performance (more intuitive)
        let usedSquares = String(repeating: "🟥", count: min(hintsUsed, 5))
        let unusedSquares = String(repeating: "🟩", count: max(0, 5 - hintsUsed))
        let hintGrid = usedSquares + unusedSquares

        var text = "🩺 Rounds"

        if isDailyCase, let caseNum = dailyCaseNumber {
            text += " #\(caseNum)"
        }

        text += "\n\n"
        text += hintGrid

        if won {
            text += " \(score)pts"

            // Add streak for bragging rights
            if let streak = streak, streak > 1 {
                text += " 🔥\(streak)"
            }

            text += "\n\n"

            // Performance message based on hints
            switch hintsUsed {
            case 1:
                text += "💎 First-hint diagnosis!"
            case 2:
                text += "🔥 Solved in 2 hints!"
            case 3:
                text += "⭐️ Got it in 3!"
            case 4:
                text += "✨ Figured it out!"
            default:
                text += "✅ Diagnosed!"
            }

            // Add school rank if impressive (top 10)
            if let rank = schoolRank, rank <= 10, let school = schoolName {
                text += "\n📊 #\(rank) at \(school)"
            }
        } else {
            text += "\n\n❌ This one stumped me"
        }

        text += "\n\nCan you beat my score?"

        // Add app link
        if isDailyCase {
            text += "\n🔗 apps.apple.com/app/id6740487567"
        } else if let caseID = caseID {
            text += "\n🔗 rounds://case/\(caseID)"
        }

        return text
    }

    /// Generate a compact share text for Instagram/TikTok stories
    static func generateCompactShareText(
        won: Bool,
        hintsUsed: Int,
        score: Int,
        dailyCaseNumber: Int?,
        streak: Int? = nil
    ) -> String {
        let usedSquares = String(repeating: "🟥", count: min(hintsUsed, 5))
        let unusedSquares = String(repeating: "🟩", count: max(0, 5 - hintsUsed))
        let hintGrid = usedSquares + unusedSquares

        var text = "🩺 Rounds"
        if let caseNum = dailyCaseNumber {
            text += " #\(caseNum)"
        }
        text += "\n\(hintGrid)"

        if won {
            text += " \(score)pts"
            if let streak = streak, streak > 1 {
                text += " 🔥\(streak)"
            }
        } else {
            text += " ❌"
        }

        return text
    }
}

// MARK: - Share Sheet Controller
// Note: Using the existing ShareSheet from ShareManager.swift

// MARK: - Share Button View
struct ShareResultButton: View {
    let won: Bool
    let diagnosis: String
    let guessCount: Int
    let hintsUsed: Int
    let score: Int
    let isDailyCase: Bool
    var caseID: String? = nil
    var streak: Int? = nil
    var schoolRank: Int? = nil
    var schoolName: String? = nil

    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []

    private var dailyCaseNumber: Int {
        let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0
        return daysSinceStart + 1
    }

    var body: some View {
        Button {
            buildShareItemsAndPresent()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "paperplane.fill")
                    .font(.subheadline.weight(.semibold))
                Text("Challenge a Friend")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .cornerRadius(10)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
                .presentationDetents([.medium])
        }
    }

    @MainActor
    private func buildShareItemsAndPresent() {
        HapticManager.shared.buttonTap()
        AnalyticsManager.shared.track("share_initiated", properties: [
            "won": won,
            "score": score,
            "hints_used": hintsUsed,
            "streak": streak ?? 0,
            "has_school_rank": schoolRank != nil
        ])

        let caseNum = isDailyCase ? dailyCaseNumber : nil
        let text = ShareTextGenerator.generateShareText(
            won: won,
            hintsUsed: hintsUsed,
            score: score,
            guessCount: guessCount,
            isDailyCase: isDailyCase,
            dailyCaseNumber: caseNum,
            caseID: caseID,
            streak: streak,
            schoolRank: schoolRank,
            schoolName: schoolName
        )

        // Render the card to a UIImage so receivers see a rich visual alongside the text
        let card = ShareResultCard(
            won: won,
            diagnosis: diagnosis,
            guessCount: guessCount,
            hintsUsed: hintsUsed,
            score: score,
            isDailyCase: isDailyCase,
            dailyCaseNumber: caseNum,
            streak: streak,
            schoolRank: schoolRank,
            schoolName: schoolName
        )
        let renderer = ImageRenderer(content: card.environment(\.colorScheme, .light))
        renderer.scale = UIScreen.main.scale
        // Image first so messaging apps (iMessage, WhatsApp) use it as the preview thumbnail
        if let image = renderer.uiImage {
            shareItems = [image, text]
        } else {
            shareItems = [text]
        }

        // Present on the next run-loop tick so SwiftUI commits the shareItems state
        // update before the sheet body is evaluated. Without this, the sheet captures
        // the stale empty-array value and shows a blank UIActivityViewController.
        Task { @MainActor in
            showingShareSheet = true
        }
    }
}

// MARK: - Compact Share Button (for toolbar or smaller areas)
struct CompactShareButton: View {
    let won: Bool
    let hintsUsed: Int
    let score: Int
    let guessCount: Int
    let isDailyCase: Bool
    var caseID: String? = nil
    var streak: Int? = nil
    var schoolRank: Int? = nil
    var schoolName: String? = nil
    // diagnosis is needed to render the card image
    var diagnosis: String = ""

    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []

    private var dailyCaseNumber: Int {
        let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0
        return daysSinceStart + 1
    }

    var body: some View {
        Button {
            buildShareItemsAndPresent()
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.body.weight(.medium))
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
                .presentationDetents([.medium])
        }
    }

    @MainActor
    private func buildShareItemsAndPresent() {
        HapticManager.shared.buttonTap()
        AnalyticsManager.shared.track("share_initiated", properties: [
            "won": won,
            "score": score,
            "source": "compact_button"
        ])

        let caseNum = isDailyCase ? dailyCaseNumber : nil
        let text = ShareTextGenerator.generateShareText(
            won: won,
            hintsUsed: hintsUsed,
            score: score,
            guessCount: guessCount,
            isDailyCase: isDailyCase,
            dailyCaseNumber: caseNum,
            caseID: caseID,
            streak: streak,
            schoolRank: schoolRank,
            schoolName: schoolName
        )

        let card = ShareResultCard(
            won: won,
            diagnosis: diagnosis,
            guessCount: guessCount,
            hintsUsed: hintsUsed,
            score: score,
            isDailyCase: isDailyCase,
            dailyCaseNumber: caseNum,
            streak: streak,
            schoolRank: schoolRank,
            schoolName: schoolName
        )
        let renderer = ImageRenderer(content: card.environment(\.colorScheme, .light))
        renderer.scale = UIScreen.main.scale
        if let image = renderer.uiImage {
            shareItems = [image, text]
        } else {
            shareItems = [text]
        }

        Task { @MainActor in
            showingShareSheet = true
        }
    }
}

// MARK: - Copy to Clipboard Button (for quick sharing)
struct CopyShareButton: View {
    let won: Bool
    let hintsUsed: Int
    let score: Int
    let dailyCaseNumber: Int?
    var streak: Int? = nil

    @State private var copied = false

    var body: some View {
        Button {
            let text = ShareTextGenerator.generateCompactShareText(
                won: won,
                hintsUsed: hintsUsed,
                score: score,
                dailyCaseNumber: dailyCaseNumber,
                streak: streak
            )
            UIPasteboard.general.string = text
            copied = true
            HapticManager.shared.correctGuess()

            AnalyticsManager.shared.track("share_copied", properties: [
                "won": won,
                "score": score
            ])

            // Reset after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                copied = false
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.subheadline.weight(.medium))
                Text(copied ? "Copied!" : "Copy")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
            .foregroundStyle(copied ? .green : .primary)
            .cornerRadius(8)
        }
        .animation(.easeInOut(duration: 0.2), value: copied)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Perfect score with streak
            ShareResultCard(
                won: true,
                diagnosis: "Myocardial Infarction",
                guessCount: 1,
                hintsUsed: 1,
                score: 400,
                isDailyCase: true,
                dailyCaseNumber: 42,
                streak: 14,
                schoolRank: 3,
                schoolName: "Harvard Medical"
            )

            // Good score
            ShareResultCard(
                won: true,
                diagnosis: "Pneumonia",
                guessCount: 2,
                hintsUsed: 3,
                score: 250,
                isDailyCase: true,
                dailyCaseNumber: 42,
                streak: 7
            )

            // Loss
            ShareResultCard(
                won: false,
                diagnosis: "Pulmonary Embolism",
                guessCount: 5,
                hintsUsed: 5,
                score: 0,
                isDailyCase: true,
                dailyCaseNumber: 42
            )

            // Share text preview
            Text(ShareTextGenerator.generateShareText(
                won: true,
                hintsUsed: 2,
                score: 350,
                guessCount: 2,
                isDailyCase: true,
                dailyCaseNumber: 42,
                streak: 14,
                schoolRank: 3,
                schoolName: "Harvard Medical"
            ))
            .font(.system(.caption, design: .monospaced))
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(8)

            // Copy button
            CopyShareButton(
                won: true,
                hintsUsed: 2,
                score: 350,
                dailyCaseNumber: 42,
                streak: 14
            )
        }
        .padding()
    }
    .background(Color(.systemGray6))
}

