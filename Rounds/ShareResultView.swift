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

    /// Generate share text to accompany the rich share card image.
    /// Includes a deep link so existing users jump straight to the case,
    /// and an App Store link so new users can download the app first.
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
        let hook = won ? "Think you can diagnose it faster? 🩺" : "This case stumped me — can you get it? 🩺"
        let appStoreLink = "apps.apple.com/app/id6740487567"

        if let caseID, !isDailyCase {
            // Non-daily: deep link opens the exact case; App Store link for new users
            return """
            \(hook)
            Have Rounds? rounds://case/\(caseID)
            New here? \(appStoreLink)
            """
        } else {
            // Daily case: just open the app — today's case will be there
            return "\(hook)\n\(appStoreLink)"
        }
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

// MARK: - Social Story Card (portrait 9:16 for Instagram Stories, TikTok, etc.)

/// A mystery-case card designed for social media stories.
/// Shows 1–2 clinical hints and the sharer's score while hiding the diagnosis,
/// challenging viewers to guess before downloading the app.
struct SocialStoryCard: View {
    let firstHint: String
    let secondHint: String?
    let category: String
    let score: Int
    let won: Bool
    let isDailyCase: Bool
    let dailyCaseNumber: Int?

    private var scoreMessage: String {
        won ? "I scored \(score) pts — can you beat me?" : "This one stumped me 😅 can you get it?"
    }

    var body: some View {
        ZStack {
            // Dark gradient background — looks great in dark mode stories
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.12),
                    Color(red: 0.05, green: 0.11, blue: 0.30),
                    Color(red: 0.10, green: 0.04, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────────────
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "cross.case.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                        Text("Rounds")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    if isDailyCase, let num = dailyCaseNumber {
                        Text("Case #\(num)")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(.white.opacity(0.12))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 56)

                Spacer()

                // ── Challenge headline ───────────────────────────────────────
                VStack(spacing: 10) {
                    Text("Can you guess\nthe diagnosis?")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text(category.uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(3)
                }
                .padding(.horizontal, 28)

                Spacer()

                // ── Clue cards ───────────────────────────────────────────────
                VStack(spacing: 10) {
                    HintTeaseCard(number: 1, text: firstHint)
                    if let hint2 = secondHint {
                        HintTeaseCard(number: 2, text: hint2)
                    }

                    // Hidden diagnosis placeholder
                    HStack(spacing: 10) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.4))
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(.white.opacity(0.18))
                                    .frame(height: 18)
                            }
                        }
                        Image(systemName: "questionmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.06))
                    .cornerRadius(12)

                    Text("diagnosis hidden")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                        .tracking(1)
                }
                .padding(.horizontal, 28)

                Spacer()

                // ── Score badge + CTA ────────────────────────────────────────
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: won ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .font(.body)
                            .foregroundStyle(won ? Color.green : Color.red)
                        Text(scoreMessage)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.10))
                    .cornerRadius(14)

                    Text("Download Rounds • rounds.app")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 60)
            }
        }
        // Portrait 9:16 — fills an iPhone screen / Instagram Story frame
        .frame(width: 390, height: 693)
    }
}

struct HintTeaseCard: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Social Story Share Button

struct SocialShareButton: View {
    let firstHint: String
    let secondHint: String?
    let category: String
    let score: Int
    let won: Bool
    let isDailyCase: Bool
    let caseID: String?

    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []

    private var dailyCaseNumber: Int {
        let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let today = Calendar.current.startOfDay(for: Date())
        return (Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0) + 1
    }

    var body: some View {
        Button {
            buildAndShare()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.subheadline.weight(.semibold))
                Text("Share to Stories")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.88, green: 0.20, blue: 0.55), // Instagram pink
                        Color(red: 0.93, green: 0.49, blue: 0.18)  // Instagram orange
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .cornerRadius(10)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
    }

    @MainActor
    private func buildAndShare() {
        HapticManager.shared.buttonTap()
        AnalyticsManager.shared.track("social_story_share_initiated", properties: [
            "won": won,
            "score": score,
            "is_daily": isDailyCase
        ])

        let caseNum = isDailyCase ? dailyCaseNumber : nil
        let card = SocialStoryCard(
            firstHint: firstHint,
            secondHint: secondHint,
            category: category,
            score: score,
            won: won,
            isDailyCase: isDailyCase,
            dailyCaseNumber: caseNum
        )

        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        // 3× scale produces a crisp image at Instagram's story resolution
        renderer.scale = 3.0

        var items: [Any] = []
        if let image = renderer.uiImage {
            items.append(image)
        }

        // Include deep link text so the image caption auto-populates
        let appStoreLink = "apps.apple.com/app/id6740487567"
        if let caseID, !isDailyCase {
            items.append("rounds://case/\(caseID)\nNew? \(appStoreLink)")
        } else {
            items.append(appStoreLink)
        }

        shareItems = items
        Task { @MainActor in
            showingShareSheet = true
        }
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

