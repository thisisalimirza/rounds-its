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
    
    private var hintEmojis: String {
        // Green = hints used, Black = hints remaining (fewer green = better!)
        let filled = String(repeating: "🟢", count: min(hintsUsed, 5))
        let empty = String(repeating: "⚫️", count: max(0, 5 - hintsUsed))
        return filled + empty
    }
    
    private var resultEmoji: String {
        if !won { return "❌" }
        switch hintsUsed {
        case 1: return "🔥"
        case 2: return "⭐️"
        case 3: return "✨"
        case 4: return "👍"
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
                    Text("Day #\(caseNum)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
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
                
                if won {
                    Text("Got it in \(hintsUsed) hint\(hintsUsed == 1 ? "" : "s")!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
    static func generateShareText(
        won: Bool,
        hintsUsed: Int,
        isDailyCase: Bool,
        dailyCaseNumber: Int?
    ) -> String {
        // Green = hints used, Black = hints remaining (fewer green = better!)
        let hintSquares = String(repeating: "🟢", count: min(hintsUsed, 5)) + String(repeating: "⚫️", count: max(0, 5 - hintsUsed))
        
        var text = "🩺 Rounds"
        
        if isDailyCase, let caseNum = dailyCaseNumber {
            text += " #\(caseNum)"
        }
        
        text += "\n\n"
        text += hintSquares
        text += "\n\n"
        
        if won {
            switch hintsUsed {
            case 1:
                text += "🔥 First hint diagnosis!"
            case 2:
                text += "⭐️ Got it in 2 hints!"
            case 3:
                text += "✨ Diagnosed in 3 hints!"
            case 4:
                text += "👍 Figured it out in 4!"
            default:
                text += "✅ Diagnosed it!"
            }
        } else {
            text += "❌ Missed this one"
        }
        
        text += "\n\nThink you can beat me? 🧠"
        text += "\nhttps://apps.apple.com/app/rounds"  // Replace with actual App Store link
        
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
    
    @State private var showingShareSheet = false
    
    private var dailyCaseNumber: Int {
        // Calculate day number since Jan 1, 2025
        let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0
        return daysSinceStart + 1
    }
    
    var body: some View {
        Button {
            showingShareSheet = true
            HapticManager.shared.buttonTap()
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
            ShareSheet(text: ShareTextGenerator.generateShareText(
                won: won,
                hintsUsed: hintsUsed,
                isDailyCase: isDailyCase,
                dailyCaseNumber: isDailyCase ? dailyCaseNumber : nil
            ))
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Compact Share Button (for toolbar or smaller areas)
struct CompactShareButton: View {
    let won: Bool
    let hintsUsed: Int
    let isDailyCase: Bool
    
    @State private var showingShareSheet = false
    
    private var dailyCaseNumber: Int {
        let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let today = Calendar.current.startOfDay(for: Date())
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0
        return daysSinceStart + 1
    }
    
    var body: some View {
        Button {
            showingShareSheet = true
            HapticManager.shared.buttonTap()
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.body.weight(.medium))
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(text: ShareTextGenerator.generateShareText(
                won: won,
                hintsUsed: hintsUsed,
                isDailyCase: isDailyCase,
                dailyCaseNumber: isDailyCase ? dailyCaseNumber : nil
            ))
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ShareResultCard(
            won: true,
            diagnosis: "Myocardial Infarction",
            guessCount: 2,
            hintsUsed: 2,
            score: 350,
            isDailyCase: true,
            dailyCaseNumber: 42
        )
        
        ShareResultCard(
            won: false,
            diagnosis: "Pulmonary Embolism",
            guessCount: 5,
            hintsUsed: 5,
            score: 0,
            isDailyCase: true,
            dailyCaseNumber: 42
        )
    }
    .padding()
    .background(Color(.systemGray6))
}

