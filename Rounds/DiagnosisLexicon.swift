import Foundation

/// Explicitly MainActor, matching CaseStore, which the cache below now reads.
/// The project builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` so this
/// was already the effective isolation — stating it keeps the mutable cache
/// from looking like shared state that anything could touch.
@MainActor
public struct DiagnosisLexicon {
    private static var cached: [String] = []
    private static var cachedGeneration = -1

    /// Every string a student can be offered while typing a guess.
    ///
    /// Cached rather than recomputed, because `suggestions(matching:)` walks
    /// this on every keystroke — but keyed on the store's generation rather
    /// than computed once. It was a `static let`, which meant it was built at
    /// the first keystroke of the session and then frozen: once the library
    /// moved to Supabase, a case pulled down mid-session stayed untypeable
    /// until the app was relaunched.
    public static var all: [String] {
        let generation = CaseStore.shared.generation
        if generation == cachedGeneration { return cached }

        // Registry first — canonical names plus every accepted alternative, so
        // abbreviations and eponyms are suggestable and not just matchable.
        var names = Set(DiagnosisRegistry.autocompleteNames)

        // Then any case whose diagnosis has no registry entry, so a newly
        // imported case is playable before anyone writes its synonyms.
        for medicalCase in CaseLibrary.getSampleCases()
        where DiagnosisRegistry.find(byName: medicalCase.diagnosis) == nil {
            names.insert(medicalCase.diagnosis)
        }

        cached = names.sorted()
        cachedGeneration = generation
        return cached
    }
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

