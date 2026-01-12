//
//  ShareManager.swift
//  Rounds
//
//  Created by Ali Mirza on 12/17/25.
//

import UIKit
import SwiftUI

class ShareManager {
    static let shared = ShareManager()
    
    private init() {}
    
    func generateShareText(
        won: Bool,
        guessCount: Int,
        hintsUsed: Int,
        isDailyCase: Bool,
        score: Int
    ) -> String {
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        let caseType = isDailyCase ? "Daily Case" : "Random Case"
        
        // Generate emoji grid
        let emojiGrid = generateEmojiGrid(won: won, guessCount: guessCount, hintsUsed: hintsUsed)
        
        let statusEmoji = won ? "✅" : "❌"
        let guessText = won ? "\(guessCount)/5" : "X/5"
        
        return """
        Rounds \(caseType) \(statusEmoji)
        \(date)
        
        Guesses: \(guessText)
        Hints: \(hintsUsed)/5
        Score: \(score)
        
        \(emojiGrid)
        
        Can you diagnose the case? 🩺
        """
    }
    
    private func generateEmojiGrid(won: Bool, guessCount: Int, hintsUsed: Int) -> String {
        var grid = ""
        
        // Show incorrect guesses
        for i in 1..<guessCount {
            grid += "❌ " + String(repeating: "🔒", count: min(i, hintsUsed)) + "\n"
        }
        
        // Show final guess
        if won {
            grid += "✅ " + String(repeating: "🔒", count: hintsUsed)
        } else if guessCount > 0 {
            grid += "❌ " + String(repeating: "🔒", count: hintsUsed)
        }
        
        return grid
    }
    
    func share(text: String, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        // For iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityVC, animated: true)
    }
}

// SwiftUI wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
