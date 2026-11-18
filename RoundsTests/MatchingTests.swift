//
//  MatchingTests.swift
//  RoundsTests
//
//  Shared answer-matching cases. The web app runs the same list in
//  scripts/matching.test.ts; keep the two in step.
//

import Testing
@testable import Rounds

struct MatchingTests {

    static let same: [(String, String)] = [
        ("Crohn's disease", "Crohn\u{2019}s disease"),
        ("Crohn's disease", "crohns disease"),
        ("Guillain-Barré syndrome", "guillain barre syndrome"),
        ("Henoch\u{2013}Schönlein purpura", "henoch schonlein purpura"),
        ("HELLP syndrome.", "hellp syndrome"),
        ("  Type 1  diabetes ", "type 1 diabetes"),
        ("Wolff-Parkinson-White", "wolff parkinson white"),
        ("B12 (cobalamin) deficiency", "b12 cobalamin deficiency"),
    ]

    static let different: [(String, String)] = [
        ("Type 1 diabetes", "Type 2 diabetes"),
        ("Hepatitis A", "Hepatitis B"),
    ]

    @Test func normalizeFoldsAccentsApostrophesAndPunctuation() {
        for (a, b) in Self.same {
            #expect(DiagnosisDefinition.normalize(a) == DiagnosisDefinition.normalize(b), "\(a) vs \(b)")
        }
        for (a, b) in Self.different {
            #expect(DiagnosisDefinition.normalize(a) != DiagnosisDefinition.normalize(b), "\(a) vs \(b)")
        }
    }
}
