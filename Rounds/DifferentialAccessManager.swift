//
//  DifferentialAccessManager.swift
//  Rounds
//
//  Tracks the free trial for the Differential Diagnosis Builder: every user
//  gets a handful of free builds, after which it becomes a Pro feature. The
//  count is tracked quietly (UserDefaults) and surfaced subtly in the UI.
//

import Foundation
import Observation

@Observable
@MainActor
final class DifferentialAccessManager {
    static let shared = DifferentialAccessManager()

    /// Free builds a non-Pro user gets before the paywall.
    static let freeLimit = 5

    private let usedKey = "differentialFreeUsesUsed"
    private(set) var freeUsesUsed: Int

    private init() {
        freeUsesUsed = UserDefaults.standard.integer(forKey: usedKey)
    }

    /// Free builds still available (0 once exhausted).
    var freeUsesRemaining: Int { max(0, Self.freeLimit - freeUsesUsed) }

    /// Whether the user may build a differential right now.
    func canUse(isPro: Bool) -> Bool {
        isPro || freeUsesRemaining > 0
    }

    /// Record one successful build. No-op for Pro users (unlimited).
    func recordUse(isPro: Bool) {
        guard !isPro else { return }
        freeUsesUsed += 1
        UserDefaults.standard.set(freeUsesUsed, forKey: usedKey)
    }
}
