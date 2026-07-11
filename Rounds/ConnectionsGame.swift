//
//  ConnectionsGame.swift
//  Rounds
//
//  Game engine for "Case Connections" — group 16 tiles into 4 clinical concepts,
//  four mistakes allowed. Logic adapted from Clerkship Connections (MIT).
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class ConnectionsGame {

    // MARK: - Types

    struct Tile: Identifiable, Hashable {
        let id = UUID()
        let text: String
        let groupIndex: Int
    }

    struct PuzzleGroup: Identifiable {
        let id = UUID()
        let concept: String
        let elements: [String]
        let colorIndex: Int
    }

    enum GuessResult {
        case solved(groupIndex: Int)
        case win
        case oneAway
        case wrong
        case loss
        case ignored
    }

    // MARK: - Config

    let maxMistakes = 4
    let specialty: String

    // MARK: - State

    private(set) var groups: [PuzzleGroup] = []
    private(set) var tiles: [Tile] = []
    private(set) var selected: Set<UUID> = []
    private(set) var solvedGroupIndices: [Int] = []
    private(set) var mistakes = 0
    private(set) var isOver = false
    private(set) var didWin = false

    var remainingMistakes: Int { maxMistakes - mistakes }
    var canSubmit: Bool { selected.count == 4 && !isOver }

    /// Tiles still on the board (belonging to unsolved groups).
    var boardTiles: [Tile] {
        tiles.filter { !solvedGroupIndices.contains($0.groupIndex) }
    }

    // MARK: - Init

    init(specialty: String) {
        self.specialty = specialty
        newPuzzle()
    }

    // MARK: - Puzzle generation

    func newPuzzle() {
        selected.removeAll()
        solvedGroupIndices.removeAll()
        mistakes = 0
        isOver = false
        didWin = false

        let pool = ConnectionsData.groups(for: specialty)
        guard pool.count >= 4 else {
            groups = []
            tiles = []
            return
        }

        // Sample 4 groups, retrying to avoid the same element appearing twice.
        var picks: [ConnectionGroup] = []
        for _ in 0..<50 {
            picks = Array(pool.shuffled().prefix(4))
            var seen = Set<String>()
            var clash = false
            for row in picks {
                for el in row.elements {
                    if seen.contains(el) { clash = true; break }
                    seen.insert(el)
                }
                if clash { break }
            }
            if !clash { break }
        }

        let colorOrder = Array(0..<4).shuffled()
        groups = picks.enumerated().map { i, row in
            PuzzleGroup(concept: row.concept, elements: row.elements, colorIndex: colorOrder[i])
        }

        var newTiles: [Tile] = []
        for (groupIndex, group) in groups.enumerated() {
            for element in group.elements {
                newTiles.append(Tile(text: element, groupIndex: groupIndex))
            }
        }
        tiles = newTiles.shuffled()
    }

    // MARK: - Selection

    func toggle(_ tileID: UUID) {
        guard !isOver else { return }
        if selected.contains(tileID) {
            selected.remove(tileID)
        } else if selected.count < 4 {
            selected.insert(tileID)
        }
    }

    func deselectAll() {
        selected.removeAll()
    }

    func shuffleBoard() {
        tiles.shuffle()
    }

    func isSelected(_ tileID: UUID) -> Bool { selected.contains(tileID) }

    // MARK: - Guessing

    func submit() -> GuessResult {
        guard canSubmit else { return .ignored }

        let selectedTiles = tiles.filter { selected.contains($0.id) }
        let groupIdxs = selectedTiles.map { $0.groupIndex }

        // Correct group?
        if let first = groupIdxs.first, groupIdxs.allSatisfy({ $0 == first }) {
            solvedGroupIndices.append(first)
            selected.removeAll()
            if solvedGroupIndices.count == 4 {
                isOver = true
                didWin = true
                return .win
            }
            return .solved(groupIndex: first)
        }

        // Wrong — count how close (for "one away").
        var counts: [Int: Int] = [:]
        for idx in groupIdxs { counts[idx, default: 0] += 1 }
        let closest = counts.values.max() ?? 0

        mistakes += 1
        if mistakes >= maxMistakes {
            isOver = true
            didWin = false
            // Reveal everything: mark all groups solved so the board shows answers.
            solvedGroupIndices = Array(0..<groups.count)
            selected.removeAll()
            return .loss
        }
        return closest == 3 ? .oneAway : .wrong
    }

    func group(at index: Int) -> PuzzleGroup? {
        groups.indices.contains(index) ? groups[index] : nil
    }
}

// MARK: - Daily-free access gate

/// Free players get one Case Connections puzzle per day; Pro is unlimited.
enum ConnectionsAccess {
    private static let lastPlayKey = "connectionsLastPlayDate"

    static func canStartPuzzle() -> Bool {
        if SubscriptionManager.shared.isProUser { return true }
        return !playedToday()
    }

    static func playedToday() -> Bool {
        guard let last = UserDefaults.standard.object(forKey: lastPlayKey) as? Date else { return false }
        return Calendar.current.isDateInToday(last)
    }

    /// Records that a free puzzle was started today (no-op for Pro users).
    static func recordPlay() {
        guard !SubscriptionManager.shared.isProUser else { return }
        UserDefaults.standard.set(Date(), forKey: lastPlayKey)
    }
}
