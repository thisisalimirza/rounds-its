//
//  SupabaseLeaderboard.swift
//  Rounds
//
//  The leaderboard's second source, during the move off CloudKit.
//
//  The public CloudKit database has been the only home for standings. It has
//  two problems that are not fixable in place: a failed record fetch falls back
//  to creating a record with an auto-generated id, so one player can hold
//  several rows (see LeaderboardManager.syncProfile), and every device fetches
//  the whole table and sorts it itself, so "your rank" is really "your rank
//  according to your phone".
//
//  `public.leaderboard_entries` fixes both by construction: the primary key is
//  the account, so duplicates are impossible, and Postgres ranks once.
//
//  Both stores are read for now. A player only appears in Supabase after they
//  install a build that writes it, so reading Supabase alone would empty the
//  standings on release day. Entries are merged on identity — a Supabase row
//  carries `legacy_player_id`, which is exactly the CloudKit `playerID` — and
//  ranked over the union. Once adoption is high enough, the CloudKit half comes
//  out and ranking moves to the `leaderboard_ranked` view.
//

import Foundation
import Supabase

/// One row of `public.leaderboard_entries`.
nonisolated struct RemoteLeaderboardRow: Decodable, Sendable {
    let user_id: String
    let display_name: String
    let school_id: String
    let school_name: String
    let state: String
    let country: String
    let visibility: String
    let total_score: Int
    let games_played: Int
    let games_won: Int
    /// The CloudKit `playerID` this row replaces, when there is one. This is
    /// what lets the two stores be merged without showing a player twice.
    let legacy_player_id: String?

    /// Stable across both stores: the same human read from either store
    /// produces the same key.
    var identity: String {
        if let legacy = legacy_player_id?.trimmingCharacters(in: .whitespacesAndNewlines),
           !legacy.isEmpty {
            return legacy.lowercased()
        }
        return "uid:\(user_id.lowercased())"
    }
}

/// A leaderboard query expressed once, so the two stores cannot drift apart.
///
/// They had already drifted in a smaller way: CloudKit's public database has no
/// OR support, so every scope above "school" silently shows only players who
/// opted into global visibility. That behaviour is reproduced here deliberately
/// rather than fixed, so switching stores doesn't quietly change who appears.
enum LeaderboardFilter {
    case school(String)
    case state(String)
    case country(String)
    case national
    case global
}

/// MainActor-isolated because it reaches for `AccountManager.shared`, which is.
/// The isolation costs nothing here — the only work is a network round trip,
/// which releases the actor while it waits.
@MainActor
enum SupabaseLeaderboard {

    /// Reads matching entries. Ranking happens in `LeaderboardManager`, over
    /// the union of both stores — ranking here would be ranking half the field.
    static func fetch(_ filter: LeaderboardFilter, limit: Int = 100) async throws -> [RemoteLeaderboardRow] {
        let global = LeaderboardVisibility.global.rawValue

        var query = AccountManager.shared.supabase
            .from("leaderboard_entries")
            .select("user_id, display_name, school_id, school_name, state, country, visibility, total_score, games_played, games_won, legacy_player_id")

        switch filter {
        case .school(let schoolID):
            // The one scope that includes school-only players — that is what
            // choosing "School Only" means.
            query = query.eq("school_id", value: schoolID)
        case .state(let state):
            query = query.eq("state", value: state).eq("visibility", value: global)
        case .country(let country):
            query = query.eq("country", value: country).eq("visibility", value: global)
        case .national:
            query = query.eq("country", value: "US").eq("visibility", value: global)
        case .global:
            query = query.eq("visibility", value: global)
        }

        return try await query
            .order("total_score", ascending: false)
            .limit(limit)
            .execute()
            .value
    }
}
