//
//  RemoteChangelog.swift
//  Rounds
//
//  What's New prefers changelog_entries, which the web already renders at
//  /whats-new. The column list was not in this repo, so the mapping is this
//  one adapter. A miss, or airplane mode with no cache, falls back to the
//  compiled AppChangelog.
//
//  Guessed columns (change only this file when the web schema is confirmed):
//    id, version, title, body, published_at
//  `body` may be one paragraph. It becomes a single feature row.
//

import Foundation
import Supabase

nonisolated enum ChangelogContract {
    static let table = "changelog_entries"
    static let cacheName = "changelog_entries.json"
}

nonisolated struct RemoteChangelogEntry: Decodable, Equatable, Sendable {
    let version: String
    let title: String?
    let body: String?
    let publishedAt: String?

    enum CodingKeys: String, CodingKey {
        case version, title, body
        case publishedAt = "published_at"
    }
}

@MainActor
final class RemoteChangelog {
    static let shared = RemoteChangelog()

    private let cacheURL: URL

    private init() {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil, create: true))
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        cacheURL = base.appendingPathComponent(ChangelogContract.cacheName)
    }

    /// Newest server entry, or the disk cache. Nil means "use the compiled notes".
    func latest() async -> WhatsNewData? {
        if let fresh = try? await fetch() {
            if let data = try? JSONEncoder().encode(fresh) {
                try? data.write(to: cacheURL, options: .atomic)
            }
            return Self.notes(from: fresh)
        }
        if let data = try? Data(contentsOf: cacheURL),
           let cached = try? JSONDecoder().decode([RemoteChangelogEntry].self, from: data),
           let notes = Self.notes(from: cached) {
            return notes
        }
        return nil
    }

    private func fetch() async throws -> [RemoteChangelogEntry] {
        try await AccountManager.shared.supabase
            .from(ChangelogContract.table)
            .select("version, title, body, published_at")
            .order("published_at", ascending: false)
            .limit(5)
            .execute()
            .value
    }

    nonisolated static func notes(from entries: [RemoteChangelogEntry]) -> WhatsNewData? {
        guard let newest = entries.max(by: {
            WhatsNewManager.compareVersions($0.version, isLessThan: $1.version)
        }) else { return nil }
        let description = newest.body?.trimmingCharacters(in: .whitespacesAndNewlines)
        let feature = WhatsNewFeature(
            icon: "sparkles",
            title: newest.title?.isEmpty == false ? newest.title! : "What's new",
            description: (description?.isEmpty == false ? description! : "Updates in this version.")
        )
        return WhatsNewData(
            version: newest.version,
            lastUpdated: newest.publishedAt ?? "",
            showToVersionsBelow: newest.version,
            title: newest.title?.isEmpty == false ? newest.title! : "What's New in Rounds",
            features: [feature],
            footer: "Thanks for using Rounds!",
            dismissButtonText: "Let's Go!"
        )
    }
}
