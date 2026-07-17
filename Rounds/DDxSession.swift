//
//  DDxSession.swift
//  Rounds
//
//  A saved Differential Builder session. Every time the student builds a
//  differential we quietly persist the inputs and the full result here, so the
//  main flow stays uncluttered but any past workup can be pulled back later
//  (e.g. from the "Presentations you worked through" list in Weak Spots).
//

import Foundation
import SwiftData

@Model
final class DDxSession {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var findings: String = ""
    var context: String = ""
    var chiefComplaint: String = ""
    var system: String = ""
    /// JSON-encoded `DifferentialResult` — decoded on demand via `result`.
    var resultData: Data = Data()

    init(findings: String, context: String, result: DifferentialResult) {
        self.id = UUID()
        self.timestamp = Date()
        self.findings = findings
        self.context = context
        self.chiefComplaint = result.chiefComplaint
        self.system = result.system
        self.resultData = (try? JSONEncoder().encode(result)) ?? Data()
    }

    /// The saved differential, decoded from `resultData`.
    var result: DifferentialResult? {
        try? JSONDecoder().decode(DifferentialResult.self, from: resultData)
    }
}
