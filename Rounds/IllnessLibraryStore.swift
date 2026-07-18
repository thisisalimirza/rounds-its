//
//  IllnessLibraryStore.swift
//  Rounds
//
//  Makes Illness Scripts feel instant. The browsable catalog and every script
//  the user has opened are cached locally on device (persisted to disk), so
//  reopening a script is immediate with no network. Only the first time a
//  condition is needed anywhere does it hit the server (which itself serves
//  from the global shared cache when possible).
//

import Foundation
import Observation

/// Deterministic normalization that mirrors the edge function's key, so a
/// locally-cached script matches what the server stored.
enum IllnessKey {
    static func normalize(_ s: String) -> String {
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
        let mapped = String(folded.map { ch -> Character in
            if ch == " " { return " " }
            if ch.isASCII && (ch.isLetter || ch.isNumber) { return ch }
            return " "
        })
        return mapped.split(separator: " ").joined(separator: " ")
    }
}

@MainActor
@Observable
final class IllnessLibraryStore {
    static let shared = IllnessLibraryStore()

    /// The global browsable library (summaries), most-missed first.
    private(set) var catalog: [IllnessScriptSummary] = []
    private(set) var isRefreshingCatalog = false

    /// Full scripts cached by normalized key (input key and canonical key both).
    private var scripts: [String: IllnessScript] = [:]

    private let dir: URL
    private let catalogURL: URL
    private let scriptsURL: URL

    private init() {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        dir = base.appendingPathComponent("IllnessLibrary", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        catalogURL = dir.appendingPathComponent("catalog.json")
        scriptsURL = dir.appendingPathComponent("scripts.json")
        load()
    }

    var count: Int { catalog.count }

    /// Fetch the latest global catalog (cheap select). Falls back to cache on failure.
    func refreshCatalog() async {
        if isRefreshingCatalog { return }
        isRefreshingCatalog = true
        defer { isRefreshingCatalog = false }
        do {
            let fresh = try await AccountManager.shared.fetchIllnessLibrary()
            catalog = fresh
            persistCatalog()
        } catch {
            print("⚠️ refreshCatalog: \(error.localizedDescription)")
        }
    }

    /// A locally-cached script for a condition, if we already have it (instant).
    func cachedScript(for condition: String) -> IllnessScript? {
        scripts[IllnessKey.normalize(condition)]
    }

    /// Get a script — instant from local cache, otherwise fetch (server resolves
    /// aliases/typos + global cache), then cache locally under input + canonical.
    func script(for condition: String, reason: String = "review") async throws -> IllnessScript {
        let inputKey = IllnessKey.normalize(condition)
        if let cached = scripts[inputKey] { return cached }

        let fetched = try await AccountManager.shared.illnessScript(condition: condition, reason: reason)
        let canonicalKey = IllnessKey.normalize(fetched.condition)

        scripts[inputKey] = fetched
        scripts[canonicalKey] = fetched
        persistScripts()

        // Reflect newly-generated conditions in the catalog immediately.
        if !catalog.contains(where: { $0.conditionKey == canonicalKey }) {
            catalog.insert(IllnessScriptSummary(condition: fetched.condition, conditionKey: canonicalKey,
                                                system: fetched.system, oneLiner: fetched.definition, missCount: 0),
                           at: 0)
            persistCatalog()
        }
        return fetched
    }

    // MARK: - Persistence

    private func persistCatalog() {
        if let data = try? JSONEncoder().encode(catalog) { try? data.write(to: catalogURL) }
    }
    private func persistScripts() {
        if let data = try? JSONEncoder().encode(scripts) { try? data.write(to: scriptsURL) }
    }
    private func load() {
        if let d = try? Data(contentsOf: catalogURL),
           let c = try? JSONDecoder().decode([IllnessScriptSummary].self, from: d) { catalog = c }
        if let d = try? Data(contentsOf: scriptsURL),
           let s = try? JSONDecoder().decode([String: IllnessScript].self, from: d) { scripts = s }
    }
}
