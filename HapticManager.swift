//
//  HapticManager.swift
//  Rounds
//
//  Created by Ali Mirza on 12/17/25.
//

import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // Correct guess - success haptic
    func correctGuess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // Incorrect guess - error haptic
    func incorrectGuess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // Hint revealed - light impact
    func hintRevealed() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // Button tap - selection haptic
    func buttonTap() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // Streak milestone - success with medium impact
    func streakMilestone() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Add a second impact for extra celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
        }
    }
    
    // Case favorited - light tap
    func favoriteToggled() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
