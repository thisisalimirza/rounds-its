//
//  DDxChallengeGame.swift
//  Rounds
//
//  "Differential Challenge" game mode: read a case, pick the diagnoses that
//  belong on the differential, and get scored — with a hard penalty for
//  missing a can't-miss diagnosis.
//

import Foundation

@MainActor
@Observable
final class DDxChallengeGame {

    struct Round {
        let presentation: DDxPresentation
        let findingIDs: [String]      // the patient's findings, in display order
        let options: [DDxDiagnosis]   // shuffled candidate diagnoses to choose from
        let expected: Set<String>     // diagnosis ids that belong on the differential
    }

    struct Result {
        let correct: Set<String>
        let missed: Set<String>
        let over: Set<String>
        let missedCantMiss: Set<String>
        let roundScore: Int
        let safe: Bool
    }

    private(set) var round: Round
    private(set) var picks: Set<String> = []
    private(set) var submitted = false
    private(set) var totalScore = 0
    private(set) var roundNumber = 1
    private(set) var result: Result?

    init() { round = Self.makeRound() }

    // MARK: - Round generation

    static func makeRound() -> Round {
        let p = DifferentialLibrary.all.randomElement()!
        // Choose a target diagnosis and seed the case with its supporting findings.
        let target = p.diagnoses.filter { !$0.supports.isEmpty }.randomElement() ?? p.diagnoses.randomElement()!
        var selected = Set(target.supports)
        // Occasionally add one more finding to make the picture less obvious.
        let extras = p.findings.map(\.id).filter { !selected.contains($0) }
        if Bool.random(), let extra = extras.randomElement() { selected.insert(extra) }

        var expected = Set(p.diagnoses.filter { p.score($0, selected: selected) >= 1 }.map(\.id))
        expected.insert(target.id)

        let orderedFindings = p.findings.map(\.id).filter { selected.contains($0) }
        return Round(presentation: p, findingIDs: orderedFindings, options: p.diagnoses.shuffled(), expected: expected)
    }

    // MARK: - Play

    func toggle(_ id: String) {
        guard !submitted else { return }
        if picks.contains(id) { picks.remove(id) } else { picks.insert(id) }
    }

    func isPicked(_ id: String) -> Bool { picks.contains(id) }

    var canSubmit: Bool { !submitted && !picks.isEmpty }

    @discardableResult
    func submit() -> Result? {
        guard !submitted else { return result }
        submitted = true

        let expected = round.expected
        let cantMiss = Set(round.options.filter { $0.isCantMiss }.map(\.id))
        let correct = picks.intersection(expected)
        let missed = expected.subtracting(picks)
        let over = picks.subtracting(expected)
        let missedCantMiss = missed.intersection(cantMiss)

        var roundScore = max(0, correct.count * 10 - over.count * 3)
        let safe = missedCantMiss.isEmpty
        if !safe { roundScore = 0 } // Missing a can't-miss diagnosis fails the round.

        totalScore += roundScore
        let r = Result(correct: correct, missed: missed, over: over,
                       missedCantMiss: missedCantMiss, roundScore: roundScore, safe: safe)
        result = r
        return r
    }

    func nextRound() {
        roundNumber += 1
        picks.removeAll()
        submitted = false
        result = nil
        round = Self.makeRound()
    }

    // Display helpers
    func label(forFinding id: String) -> String { round.presentation.label(for: id) }
}
