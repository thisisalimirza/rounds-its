import Foundation

public struct DiagnosisLexicon {
    // Build lexicon from DiagnosisRegistry canonical names (deduplicated by design)
    // Falls back to CaseLibrary for any diagnoses not yet in registry
    public static let all: [String] = {
        // Primary source: Registry canonical names (already deduplicated)
        var allDiagnoses = Set(DiagnosisRegistry.autocompleteNames)

        // Secondary: Add any diagnoses from CaseLibrary not covered by registry
        // This ensures gradual migration - new cases work even if not in registry yet
        let cases = CaseLibrary.getSampleCases()
        for medicalCase in cases {
            // Only add if not already covered by registry lookup
            if DiagnosisRegistry.find(byName: medicalCase.diagnosis) == nil {
                allDiagnoses.insert(medicalCase.diagnosis)
            }
        }

        // Return sorted array for consistent ordering
        return Array(allDiagnoses).sorted()
    }()
    public static func suggestions(matching query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lower = trimmed.lowercased()
        var seen = Set<String>()
        var results: [String] = []
        
        // Prioritize exact starts, then word starts, then contains
        var exactStarts: [String] = []
        var wordStarts: [String] = []
        var contains: [String] = []
        
        for term in all {
            let lowerTerm = term.lowercased()
            guard !seen.contains(lowerTerm) else { continue }
            
            if lowerTerm.hasPrefix(lower) {
                exactStarts.append(term)
                seen.insert(lowerTerm)
            } else if lowerTerm.split(separator: " ").contains(where: { $0.hasPrefix(lower) }) {
                wordStarts.append(term)
                seen.insert(lowerTerm)
            } else if lowerTerm.contains(lower) {
                contains.append(term)
                seen.insert(lowerTerm)
            }
            
            // Stop early if we have enough results
            if exactStarts.count + wordStarts.count + contains.count >= 20 {
                break
            }
        }
        
        // Combine results in priority order and limit to 10
        results = exactStarts + wordStarts + contains
        return Array(results.prefix(10))
    }
}

