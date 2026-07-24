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
    private(set) var isSyncing = false

    /// Full scripts cached by normalized key (input key and canonical key both).
    private var scripts: [String: IllnessScript] = [:]

    /// Conditions the user manually saved to "My Illness Scripts" (display names,
    /// most recently added first). Missed conditions are added automatically at
    /// the view layer; these are the deliberate saves.
    private(set) var savedConditions: [String] = []

    private let cursorKey = "illnessLibrary.syncCursor"
    private let syncAtKey = "illnessLibrary.lastSyncAt"
    private var savedURL: URL { dir.appendingPathComponent("saved.json") }

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

    // MARK: - My Illness Scripts (manual saves)

    func isSaved(_ condition: String) -> Bool {
        let k = IllnessKey.normalize(condition)
        return savedConditions.contains { IllnessKey.normalize($0) == k }
    }

    func addToMyScripts(_ condition: String) {
        let name = condition.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !isSaved(name) else { return }
        savedConditions.insert(name, at: 0)
        persistSaved()
    }

    func removeFromMyScripts(_ condition: String) {
        let k = IllnessKey.normalize(condition)
        savedConditions.removeAll { IllnessKey.normalize($0) == k }
        persistSaved()
    }

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

    /// Incrementally mirror the global library onto the device so ANY script
    /// opens instantly. Downloads only current-schema scripts updated since the
    /// last sync (first run pulls everything, paginated). Pro only; throttled.
    func syncFullLibrary(isPro: Bool, force: Bool = false) async {
        guard isPro, !isSyncing else { return }
        let lastAt = (UserDefaults.standard.object(forKey: syncAtKey) as? Date) ?? .distantPast
        if !force && Date().timeIntervalSince(lastAt) < 1800 { return }   // ≤ every 30 min

        isSyncing = true
        defer { isSyncing = false }

        var cursor = UserDefaults.standard.string(forKey: cursorKey)
        let pageSize = 200
        do {
            while true {
                let batch = try await AccountManager.shared.fetchFullIllnessScripts(since: cursor, limit: pageSize)
                if batch.isEmpty { break }
                for full in batch {
                    scripts[full.conditionKey] = full.script
                    if let i = catalog.firstIndex(where: { $0.conditionKey == full.conditionKey }) {
                        catalog[i] = IllnessScriptSummary(condition: full.condition, conditionKey: full.conditionKey,
                                                          system: full.system, oneLiner: full.definition,
                                                          missCount: catalog[i].missCount)
                    } else {
                        catalog.append(full.summary)
                    }
                    cursor = full.updatedAt
                }
                persistScripts(); persistCatalog()
                if let cursor { UserDefaults.standard.set(cursor, forKey: cursorKey) }
                if batch.count < pageSize { break }
            }
            UserDefaults.standard.set(Date(), forKey: syncAtKey)
        } catch {
            print("⚠️ syncFullLibrary: \(error.localizedDescription)")
        }
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
    private func persistSaved() {
        if let data = try? JSONEncoder().encode(savedConditions) { try? data.write(to: savedURL) }
    }
    private func load() {
        if let d = try? Data(contentsOf: catalogURL),
           let c = try? JSONDecoder().decode([IllnessScriptSummary].self, from: d) { catalog = c }
        if let d = try? Data(contentsOf: scriptsURL),
           let s = try? JSONDecoder().decode([String: IllnessScript].self, from: d) { scripts = s }
        if let d = try? Data(contentsOf: savedURL),
           let s = try? JSONDecoder().decode([String].self, from: d) { savedConditions = s }
    }
}
