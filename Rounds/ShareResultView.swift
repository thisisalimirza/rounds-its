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

    private var dailyCaseNumber: Int {
        let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0
        return daysSinceStart + 1
    }

    var body: some View {
        Button {
            buildAndPresent()
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
    }

    @MainActor
    private func buildAndPresent() {
        HapticManager.shared.buttonTap()
        AnalyticsManager.shared.track("share_initiated", properties: [
            "won": won, "score": score, "hints_used": hintsUsed,
            "streak": streak ?? 0, "has_school_rank": schoolRank != nil
        ])

        let caseNum = isDailyCase ? dailyCaseNumber : nil
        let text = ShareTextGenerator.generateShareText(
            won: won, hintsUsed: hintsUsed, score: score, guessCount: guessCount,
            isDailyCase: isDailyCase, dailyCaseNumber: caseNum, caseID: caseID,
            streak: streak, schoolRank: schoolRank, schoolName: schoolName
        )

        let card = ShareResultCard(
            won: won, diagnosis: diagnosis, guessCount: guessCount,
            hintsUsed: hintsUsed, score: score, isDailyCase: isDailyCase,
            dailyCaseNumber: caseNum, streak: streak,
            schoolRank: schoolRank, schoolName: schoolName
        )
        let renderer = ImageRenderer(content: card.environment(\.colorScheme, .light))
        renderer.scale = UIScreen.main.scale

        var items: [Any] = []
        if let image = renderer.uiImage { items.append(image) }
        items.append(text)

        presentShareSheet(items: items)
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
    var diagnosis: String = ""

    private var dailyCaseNumber: Int {
        let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0
        return daysSinceStart + 1
    }

    var body: some View {
        Button { buildAndPresent() } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.body.weight(.medium))
        }
    }

    @MainActor
    private func buildAndPresent() {
        HapticManager.shared.buttonTap()
        AnalyticsManager.shared.track("share_initiated", properties: [
            "won": won, "score": score, "source": "compact_button"
        ])

        let caseNum = isDailyCase ? dailyCaseNumber : nil
        let text = ShareTextGenerator.generateShareText(
            won: won, hintsUsed: hintsUsed, score: score, guessCount: guessCount,
            isDailyCase: isDailyCase, dailyCaseNumber: caseNum, caseID: caseID,
            streak: streak, schoolRank: schoolRank, schoolName: schoolName
        )
        let card = ShareResultCard(
            won: won, diagnosis: diagnosis, guessCount: guessCount,
            hintsUsed: hintsUsed, score: score, isDailyCase: isDailyCase,
            dailyCaseNumber: caseNum, streak: streak,
            schoolRank: schoolRank, schoolName: schoolName
        )
        let renderer = ImageRenderer(content: card.environment(\.colorScheme, .light))
        renderer.scale = UIScreen.main.scale

        var items: [Any] = []
        if let image = renderer.uiImage { items.append(image) }
        items.append(text)

        presentShareSheet(items: items)
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

    // Brand purple used throughout
    private static let brandPurple = Color(red: 0.38, green: 0.30, blue: 0.82)
    private static let brandBlue   = Color(red: 0.22, green: 0.48, blue: 0.92)
    private static let navyText    = Color(red: 0.08, green: 0.06, blue: 0.22)

    var body: some View {
        ZStack {
            // Light lavender gradient — matches getrounds.app website background
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.92, blue: 1.00),
                    Color(red: 0.88, green: 0.84, blue: 0.98),
                    Color(red: 0.92, green: 0.87, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // ── Header ───────────────────────────────────────────────────
                HStack {
                    HStack(spacing: 10) {
                        // App icon pill (purple gradient + white cross)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [Self.brandPurple, Self.brandBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 36, height: 36)
                            Image(systemName: "cross.case.fill")
                                .font(.system(size: 17))
                                .foregroundStyle(.white)
                        }
                        Text("Rounds")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(LinearGradient(
                                colors: [Self.brandPurple, Self.brandBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    }
                    Spacer()
                    if isDailyCase, let num = dailyCaseNumber {
                        Text("Case #\(num)")
                            .font(.caption.bold())
                            .foregroundStyle(Self.brandPurple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Self.brandPurple.opacity(0.12))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 56)

                Spacer()

                // ── Challenge headline ────────────────────────────────────────
                VStack(spacing: 8) {
                    Text("Can you guess\nthe diagnosis?")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Self.navyText)
                        .multilineTextAlignment(.center)

                    Text(category.uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(Self.brandPurple.opacity(0.65))
                        .tracking(3)
                }
                .padding(.horizontal, 28)

                Spacer()

                // ── Clue cards ────────────────────────────────────────────────
                VStack(spacing: 10) {
                    HintTeaseCard(number: 1, text: firstHint)
                    if let hint2 = secondHint {
                        HintTeaseCard(number: 2, text: hint2)
                    }

                    // Hidden diagnosis row
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Self.brandPurple.opacity(0.45))
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Self.brandPurple.opacity(0.15))
                                    .frame(height: 16)
                            }
                        }
                        Image(systemName: "questionmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Self.brandPurple.opacity(0.45))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.55))
                    .cornerRadius(12)

                    Text("diagnosis hidden")
                        .font(.caption2)
                        .foregroundStyle(Self.brandPurple.opacity(0.45))
                        .tracking(1)
                }
                .padding(.horizontal, 28)

                Spacer()

                // ── Score badge + CTA ─────────────────────────────────────────
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: won ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .font(.body)
                            .foregroundStyle(won ? Color(red: 0.98, green: 0.58, blue: 0.10) : Color.red)
                        Text(scoreMessage)
                            .font(.subheadline.bold())
                            .foregroundStyle(Self.navyText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.70))
                    .cornerRadius(14)

                    Text("getrounds.app")
                        .font(.caption)
                        .foregroundStyle(Self.brandPurple.opacity(0.55))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 60)
            }
        }
        .frame(width: 390, height: 693)
    }
}

struct HintTeaseCard: View {
    let number: Int
    let text: String

    private static let brandPurple = Color(red: 0.38, green: 0.30, blue: 0.82)
    private static let brandBlue   = Color(red: 0.22, green: 0.48, blue: 0.92)
    private static let navyText    = Color(red: 0.08, green: 0.06, blue: 0.22)

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Self.brandBlue, Self.brandPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Self.navyText)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white.opacity(0.70))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Self.brandBlue.opacity(0.18), lineWidth: 1)
        )
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

    private var dailyCaseNumber: Int {
        let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let today = Calendar.current.startOfDay(for: Date())
        return (Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0) + 1
    }

    var body: some View {
        Button { buildAndPresent() } label: {
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
                        Color(red: 0.88, green: 0.20, blue: 0.55),
                        Color(red: 0.93, green: 0.49, blue: 0.18)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .cornerRadius(10)
        }
    }

    @MainActor
    private func buildAndPresent() {
        HapticManager.shared.buttonTap()
        AnalyticsManager.shared.track("social_story_share_initiated", properties: [
            "won": won, "score": score, "is_daily": isDailyCase
        ])

        let caseNum = isDailyCase ? dailyCaseNumber : nil
        let card = SocialStoryCard(
            firstHint: firstHint, secondHint: secondHint, category: category,
            score: score, won: won, isDailyCase: isDailyCase, dailyCaseNumber: caseNum
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0

        var items: [Any] = []
        if let image = renderer.uiImage { items.append(image) }

        let appStoreLink = "getrounds.app"
        if let caseID, !isDailyCase {
            items.append("rounds://case/\(caseID)\nGet the app: \(appStoreLink)")
        } else {
            items.append(appStoreLink)
        }

        presentShareSheet(items: items)
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

