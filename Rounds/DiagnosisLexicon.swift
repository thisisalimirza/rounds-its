import Foundation

/// One searchable string, paired with the answer it belongs to.
///
/// The pairing is what lets the suggestion list collapse. A flat list of names
/// cannot tell that "Legg Calve Perthes", "Legg-Calve-Perthes Disease" and
/// "Legg-Calvé-Perthes Disease" are one answer wearing three hats, so it
/// offered all three as though they were different conditions.
nonisolated struct LexiconEntry: Sendable {
    let name: String
    let canonical: String
}

/// Explicitly MainActor, matching CaseStore, which the cache below reads.
/// The project builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` so this
/// was already the effective isolation — stating it keeps the mutable cache
/// from looking like shared state that anything could touch.
@MainActor
public struct DiagnosisLexicon {
    private static var cached: [LexiconEntry] = []
    private static var cachedGeneration = -1

    /// Every string a student can be offered while typing a guess, each tied to
    /// the answer it stands for.
    ///
    /// Cached rather than recomputed, because `suggestions(matching:)` walks
    /// this on every keystroke — but keyed on the store's generation rather
    /// than computed once. It was a `static let`, which meant it was built at
    /// the first keystroke of the session and then frozen: once the library
    /// moved to Supabase, a case pulled down mid-session stayed untypeable
    /// until the app was relaunched.
    static var entries: [LexiconEntry] {
        let generation = CaseStore.shared.generation
        if generation == cachedGeneration { return cached }

        var built: [LexiconEntry] = []
        var seen = Set<String>()
        var covered = Set<String>()

        func add(_ name: String, canonical: String) {
            let key = "\(DiagnosisRegistry.normalize(canonical))|\(DiagnosisRegistry.normalize(name))"
            guard !seen.contains(key) else { return }
            seen.insert(key)
            built.append(LexiconEntry(name: name, canonical: canonical))
        }

        // Registry first — canonical names plus every accepted alternative, so
        // abbreviations and eponyms are suggestable and not just matchable.
        for definition in DiagnosisRegistry.all {
            add(definition.canonicalName, canonical: definition.canonicalName)
            covered.insert(DiagnosisRegistry.normalize(definition.canonicalName))
            for alternative in definition.alternativeNames {
                add(alternative, canonical: definition.canonicalName)
            }
        }

        // Then any case whose diagnosis has no registry entry, so a newly
        // imported case is playable before anyone writes its synonyms.
        for medicalCase in CaseLibrary.getSampleCases()
        where !covered.contains(DiagnosisRegistry.normalize(medicalCase.diagnosis))
            && DiagnosisRegistry.find(byName: medicalCase.diagnosis) == nil {
            add(medicalCase.diagnosis, canonical: medicalCase.diagnosis)
        }

        cached = built.sorted { $0.name < $1.name }
        cachedGeneration = generation
        return cached
    }

    /// Suggestions for a partial query — one row per answer, best match first.
    ///
    /// Three tiers: the name starts with what was typed, some word in it starts
    /// with what was typed, or it merely contains it.
    ///
    /// The dedupe is the fix for what this looked like in practice. Typing
    /// "leg" returned "Legg Calve Perthes", "Legg-Calve-Perthes Disease" and
    /// "Legg-Calvé-Perthes Disease" as three separate options — one answer,
    /// three spellings, presented as if they were different diagnoses. Worse,
    /// only two of them were accepted, so the game offered a suggestion and
    /// then marked it wrong.
    ///
    /// Returns canonical names, so picking any row submits something the
    /// checker accepts.
    public static func suggestions(matching query: String) -> [String] {
        let needle = DiagnosisRegistry.normalize(query)
        guard !needle.isEmpty else { return [] }

        var exactStarts: [String] = []
        var wordStarts: [String] = []
        var contains: [String] = []
        var claimed = Set<String>()

        for entry in entries {
            let key = DiagnosisRegistry.normalize(entry.canonical)
            guard !claimed.contains(key) else { continue }

            // Normalized on both sides, so an accented name is reachable by
            // typing it plainly — which is how anyone actually types Behçet.
            let name = DiagnosisRegistry.normalize(entry.name)

            if name.hasPrefix(needle) {
                exactStarts.append(entry.canonical)
            } else if name.split(separator: " ").contains(where: { $0.hasPrefix(needle) }) {
                wordStarts.append(entry.canonical)
            } else if name.contains(needle) {
                contains.append(entry.canonical)
            } else {
                continue
            }

            claimed.insert(key)
            if exactStarts.count >= 10 { break }
        }

        return Array((exactStarts + wordStarts + contains).prefix(10))
    }
}
