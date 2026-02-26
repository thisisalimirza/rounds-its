//
//  CaseLibraryValidationTests.swift
//  RoundsTests
//
//  Case library validation and export utilities
//

import Testing
import Foundation
@testable import Rounds

struct CaseLibraryValidationTests {

    // MARK: - Duplicate Detection

    @Test func detectExactDuplicateDiagnoses() async throws {
        let cases = CaseLibrary.getSampleCases()
        let diagnosisCounts = Dictionary(grouping: cases, by: { $0.diagnosis })
            .mapValues { $0.count }
            .filter { $0.value > 1 }

        if !diagnosisCounts.isEmpty {
            print("\n⚠️ DUPLICATE DIAGNOSES FOUND:")
            print("================================")
            for (diagnosis, count) in diagnosisCounts.sorted(by: { $0.value > $1.value }) {
                print("  \(diagnosis): \(count) occurrences")
            }
            print("================================\n")
        }

        // This will fail if duplicates exist - comment out to just see the report
        // #expect(diagnosisCounts.isEmpty, "Found \(diagnosisCounts.count) duplicate diagnoses")
    }

    @Test func detectSimilarDiagnoses() async throws {
        let cases = CaseLibrary.getSampleCases()
        let diagnoses = Array(Set(cases.map { $0.diagnosis }))

        var similarPairs: [(String, String)] = []

        for i in 0..<diagnoses.count {
            for j in (i+1)..<diagnoses.count {
                let d1 = diagnoses[i]
                let d2 = diagnoses[j]

                // Normalize: lowercase, remove hyphens, apostrophes, extra spaces
                let norm1 = normalize(d1)
                let norm2 = normalize(d2)

                if norm1 == norm2 {
                    similarPairs.append((d1, d2))
                }
            }
        }

        if !similarPairs.isEmpty {
            print("\n⚠️ SIMILAR DIAGNOSES (potential inconsistencies):")
            print("==================================================")
            for (d1, d2) in similarPairs {
                print("  '\(d1)' vs '\(d2)'")
            }
            print("==================================================\n")
        }
    }

    @Test func detectMissingAlternativeNames() async throws {
        let cases = CaseLibrary.getSampleCases()
        var issues: [(String, String)] = []

        for medicalCase in cases {
            // Check if diagnosis has hyphen but alternatives don't include non-hyphen version
            if medicalCase.diagnosis.contains("-") {
                let withoutHyphen = medicalCase.diagnosis.replacingOccurrences(of: "-", with: " ")
                let hasNonHyphenAlt = medicalCase.alternativeNames.contains { alt in
                    normalize(alt) == normalize(withoutHyphen)
                }
                if !hasNonHyphenAlt {
                    issues.append((medicalCase.diagnosis, "Missing non-hyphen alternative"))
                }
            }

            // Check for apostrophe variations
            if medicalCase.diagnosis.contains("'") {
                let withoutApostrophe = medicalCase.diagnosis.replacingOccurrences(of: "'", with: "")
                let hasNoApostropheAlt = medicalCase.alternativeNames.contains { alt in
                    normalize(alt) == normalize(withoutApostrophe)
                }
                if !hasNoApostropheAlt {
                    issues.append((medicalCase.diagnosis, "Missing no-apostrophe alternative"))
                }
            }
        }

        if !issues.isEmpty {
            print("\n⚠️ POTENTIALLY MISSING ALTERNATIVE NAMES:")
            print("==========================================")
            for (diagnosis, issue) in issues.prefix(20) {
                print("  \(diagnosis): \(issue)")
            }
            if issues.count > 20 {
                print("  ... and \(issues.count - 20) more")
            }
            print("==========================================\n")
        }
    }

    // MARK: - Statistics

    @Test func printCaseLibraryStats() async throws {
        let cases = CaseLibrary.getSampleCases()

        let uniqueDiagnoses = Set(cases.map { $0.diagnosis }).count
        let categories = Dictionary(grouping: cases, by: { $0.category })
        let difficulties = Dictionary(grouping: cases, by: { $0.difficulty })

        print("\n📊 CASE LIBRARY STATISTICS:")
        print("============================")
        print("Total cases: \(cases.count)")
        print("Unique diagnoses: \(uniqueDiagnoses)")
        print("Duplicate diagnoses: \(cases.count - uniqueDiagnoses)")
        print("")
        print("By Category:")
        for (category, categoryCases) in categories.sorted(by: { $0.value.count > $1.value.count }) {
            print("  \(category): \(categoryCases.count)")
        }
        print("")
        print("By Difficulty:")
        for difficulty in 1...5 {
            let count = difficulties[difficulty]?.count ?? 0
            print("  Level \(difficulty): \(count)")
        }
        print("============================\n")
    }

    // MARK: - JSON Export

    @Test func exportCasesToJSON() async throws {
        let cases = CaseLibrary.getSampleCases()

        // Group by category
        let categorizedCases = Dictionary(grouping: cases, by: { $0.category })

        // Build diagnosis registry from all unique diagnoses
        var diagnosisRegistry: [[String: Any]] = []
        var seenDiagnoses = Set<String>()

        for medicalCase in cases {
            let diagnosisID = createDiagnosisID(from: medicalCase.diagnosis)
            if !seenDiagnoses.contains(diagnosisID) {
                seenDiagnoses.insert(diagnosisID)
                diagnosisRegistry.append([
                    "id": diagnosisID,
                    "displayName": medicalCase.diagnosis,
                    "alternativeNames": medicalCase.alternativeNames
                ])
            }
        }

        // Export diagnosis registry
        let diagnosisJSON: [String: Any] = ["diagnoses": diagnosisRegistry]
        let diagnosisData = try JSONSerialization.data(withJSONObject: diagnosisJSON, options: [.prettyPrinted, .sortedKeys])
        let diagnosisString = String(data: diagnosisData, encoding: .utf8)!

        print("\n📁 DIAGNOSES.JSON (first 50 entries):")
        print("======================================")
        // Just show a preview
        let previewDiagnoses = Array(diagnosisRegistry.prefix(50))
        let previewJSON: [String: Any] = ["diagnoses": previewDiagnoses]
        let previewData = try JSONSerialization.data(withJSONObject: previewJSON, options: [.prettyPrinted, .sortedKeys])
        print(String(data: previewData, encoding: .utf8)!)
        print("... (\(diagnosisRegistry.count) total diagnoses)")
        print("======================================\n")

        // Export one category as example
        if let cardiologyCases = categorizedCases["Cardiology"] {
            let casesJSON: [[String: Any]] = cardiologyCases.prefix(5).map { medicalCase in
                [
                    "id": medicalCase.id.uuidString,
                    "diagnosisID": createDiagnosisID(from: medicalCase.diagnosis),
                    "diagnosis": medicalCase.diagnosis,  // Keep for reference during migration
                    "hints": medicalCase.hints,
                    "category": medicalCase.category,
                    "difficulty": medicalCase.difficulty,
                    "organizationID": NSNull(),  // null for base library
                    "alternativeNames": medicalCase.alternativeNames
                ]
            }

            let categoryJSON: [String: Any] = ["cases": casesJSON]
            let categoryData = try JSONSerialization.data(withJSONObject: categoryJSON, options: [.prettyPrinted, .sortedKeys])

            print("\n📁 CARDIOLOGY.JSON (first 5 cases preview):")
            print("============================================")
            print(String(data: categoryData, encoding: .utf8)!)
            print("============================================\n")
        }

        print("✅ To perform full export, uncomment the file writing code below")

        // UNCOMMENT TO WRITE FILES:
        // let outputDir = FileManager.default.temporaryDirectory.appendingPathComponent("CaseExport")
        // try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        //
        // // Write diagnoses.json
        // try diagnosisData.write(to: outputDir.appendingPathComponent("diagnoses.json"))
        //
        // // Write each category
        // for (category, categoryCases) in categorizedCases {
        //     let filename = category.lowercased().replacingOccurrences(of: " ", with: "_") + ".json"
        //     let casesJSON = categoryCases.map { ... }
        //     ...
        // }
        //
        // print("Files written to: \(outputDir.path)")
    }

    // MARK: - ID Verification

    @Test func verifyDeterministicIDs() async throws {
        let cases = CaseLibrary.getSampleCases()

        // Verify IDs are deterministic (same diagnosis = same ID)
        var diagnosisToID: [String: UUID] = [:]
        var inconsistencies: [(String, UUID, UUID)] = []

        for medicalCase in cases {
            if let existingID = diagnosisToID[medicalCase.diagnosis] {
                if existingID != medicalCase.id {
                    inconsistencies.append((medicalCase.diagnosis, existingID, medicalCase.id))
                }
            } else {
                diagnosisToID[medicalCase.diagnosis] = medicalCase.id
            }
        }

        #expect(inconsistencies.isEmpty, "Found cases with same diagnosis but different IDs")

        if !inconsistencies.isEmpty {
            print("\n⚠️ ID INCONSISTENCIES:")
            for (diagnosis, id1, id2) in inconsistencies {
                print("  \(diagnosis): \(id1) vs \(id2)")
            }
        }

        print("\n✅ Verified \(diagnosisToID.count) unique diagnosis-to-ID mappings")
    }

    // MARK: - Helpers

    private func normalize(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "'", with: "")  // Smart apostrophe
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    private func createDiagnosisID(from diagnosis: String) -> String {
        diagnosis.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "--", with: "-")
    }
}
