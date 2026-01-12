import Foundation

public struct DiagnosisLexicon {
    // Automatically build lexicon from all cases in CaseLibrary
    public static let all: [String] = {
        var allDiagnoses = Set<String>()
        
        // Get all cases from CaseLibrary
        let cases = CaseLibrary.getSampleCases()
        
        // Add primary diagnosis and alternative names for each case
        for medicalCase in cases {
            allDiagnoses.insert(medicalCase.diagnosis)
            for altName in medicalCase.alternativeNames {
                allDiagnoses.insert(altName)
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

