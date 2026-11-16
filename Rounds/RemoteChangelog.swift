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

nonisolated struct RemoteChangelogEntry: Codable, Equatable, Sendable {
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
        // A failed select (the public read exists only after web PR 200) falls
        // through to the disk cache, then the compiled notes.
        if let fresh = try? await fetch() {
            let rows = Self.publishable(fresh)
            if !rows.isEmpty {
                if let data = try? JSONEncoder().encode(rows) {
                    try? data.write(to: cacheURL, options: [.atomic])
                }
                return Self.notes(from: rows)
            }
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

    /// Drops blank versions. `version` is `text not null default ''` on the server.
    nonisolated static func publishable(_ entries: [RemoteChangelogEntry]) -> [RemoteChangelogEntry] {
        entries.filter { !$0.version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    nonisolated static func notes(from entries: [RemoteChangelogEntry]) -> WhatsNewData? {
        let rows = publishable(entries)
        guard let newest = rows.max(by: { older, newer in
            switch (older.publishedAt, newer.publishedAt) {
            case let (left?, right?) where !left.isEmpty && !right.isEmpty:
                return left < right
            default:
                return WhatsNewManager.compareVersions(older.version, isLessThan: newer.version)
            }
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
