//
//  LeaderboardManager.swift
//  Rounds
//
//  Leaderboard standings, read from CloudKit and Supabase and ranked over the
//  union of the two.
//
//  Writes still go to CloudKit here; the Supabase entry is written by
//  ProgressSyncManager alongside the rest of the account. Reading both is a
//  transition measure — see SupabaseLeaderboard for why, and for what comes
//  out once adoption is high enough.
//

import Foundation
import CloudKit
import SwiftData
import Supabase

// MARK: - CloudKit Record Types

private enum RecordType {
    static let leaderboardEntry = "LeaderboardEntry"
}

private enum RecordField {
    static let playerID = "playerID"
    static let displayName = "displayName"
    static let schoolID = "schoolID"
    static let schoolName = "schoolName"
    static let state = "state"
    static let country = "country"
    static let totalScore = "totalScore"
    static let gamesPlayed = "gamesPlayed"
    static let gamesWon = "gamesWon"
    static let visibilityLevel = "visibilityLevel"
    static let lastUpdated = "lastUpdated"
}

// MARK: - Filters

extension LeaderboardFilter {
    /// The CloudKit half of the shared filter. Lives here, next to the field
    /// names it depends on, so `LeaderboardFilter` itself stays store-agnostic.
    ///
    /// CloudKit's public database supports no OR, which is why every scope
    /// above school matches only players who chose global visibility.
    var cloudKitPredicate: NSPredicate {
        let global = LeaderboardVisibility.global.rawValue

        switch self {
        case .school(let schoolID):
            return NSPredicate(format: "%K == %@", RecordField.schoolID, schoolID)
        case .state(let state):
            return NSPredicate(format: "%K == %@ AND %K == %@",
                               RecordField.state, state,
                               RecordField.visibilityLevel, global)
        case .country(let country):
            return NSPredicate(format: "%K == %@ AND %K == %@",
                               RecordField.country, country,
                               RecordField.visibilityLevel, global)
        case .national:
            return NSPredicate(format: "%K == %@ AND %K == %@",
                               RecordField.country, "US",
                               RecordField.visibilityLevel, global)
        case .global:
            return NSPredicate(format: "%K == %@", RecordField.visibilityLevel, global)
        }
    }
}

// MARK: - Leaderboard Manager

@Observable
@MainActor
final class LeaderboardManager {

    // MARK: - Singleton

    static let shared = LeaderboardManager()

    // MARK: - Properties

    private let container: CKContainer
    private let publicDatabase: CKDatabase

    var isLoading = false
    var error: Error?
    var lastFetchedScope: LeaderboardScope?

    // Cached leaderboard entries by scope (individual rankings)
    var schoolLeaderboard: [LeaderboardEntry] = []
    var stateLeaderboard: [LeaderboardEntry] = []
    var countryLeaderboard: [LeaderboardEntry] = []
    var nationalLeaderboard: [LeaderboardEntry] = []
    var globalLeaderboard: [LeaderboardEntry] = []

    // Cached school rankings by scope (aggregated by school)
    var stateSchoolRankings: [SchoolRankingEntry] = []
    var nationalSchoolRankings: [SchoolRankingEntry] = []
    var globalSchoolRankings: [SchoolRankingEntry] = []

    // Current user's rank by scope
    var schoolRank: Int?
    var stateRank: Int?
    var countryRank: Int?
    var nationalRank: Int?
    var globalRank: Int?

    // Current user's school rank by scope
    var stateSchoolRank: Int?
    var nationalSchoolRank: Int?
    var globalSchoolRank: Int?

    // MARK: - Initialization

    private init() {
        // Use the default container - you'll need to configure this in Xcode
        self.container = CKContainer(identifier: "iCloud.com.braskgroup.Rounds")
        self.publicDatabase = container.publicCloudDatabase
    }

    // MARK: - Profile Management

    /// Create or update leaderboard entry in CloudKit
    func syncProfile(
        profile: LeaderboardProfile,
        totalScore: Int,
        gamesPlayed: Int,
        gamesWon: Int
    ) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        let record: CKRecord

        // Every path must land on a deterministic record id.
        //
        // This previously fell back to `CKRecord(recordType:)` with no id when
        // fetching the existing record failed, which CloudKit answers by
        // generating a fresh UUID. The fetch fails on an ordinary network
        // blip, not just a missing record, so each failure minted another row
        // for the same player — which is why one playerID holds three entries
        // in the live data. Naming the record after the player makes a retry
        // overwrite instead of duplicate.
        let canonicalID = CKRecord.ID(recordName: "player_\(profile.playerID)")

        if let existingRecordID = profile.cloudKitRecordID {
            let recordID = CKRecord.ID(recordName: existingRecordID)
            do {
                record = try await publicDatabase.record(for: recordID)
            } catch {
                record = CKRecord(recordType: RecordType.leaderboardEntry, recordID: canonicalID)
            }
        } else {
            record = CKRecord(recordType: RecordType.leaderboardEntry, recordID: canonicalID)
        }

        // Update record fields
        record[RecordField.playerID] = profile.playerID
        record[RecordField.displayName] = profile.displayName
        record[RecordField.schoolID] = profile.schoolID
        record[RecordField.schoolName] = profile.schoolName
        record[RecordField.state] = profile.state
        record[RecordField.country] = profile.country
        record[RecordField.totalScore] = totalScore as CKRecordValue
        record[RecordField.gamesPlayed] = gamesPlayed as CKRecordValue
        record[RecordField.gamesWon] = gamesWon as CKRecordValue
        record[RecordField.visibilityLevel] = profile.visibilityLevel.rawValue
        record[RecordField.lastUpdated] = Date()

        // Save to CloudKit
        let savedRecord = try await publicDatabase.save(record)

        // Update local profile with CloudKit record ID
        profile.cloudKitRecordID = savedRecord.recordID.recordName
        profile.lastSyncedScore = totalScore
        profile.lastSyncedAt = Date()
    }

    /// Removes the player from the leaderboard, in both stores.
    ///
    /// Leaving Supabase out would make "remove me from the leaderboard" a lie
    /// as soon as the merged read landed: the CloudKit row would go and the
    /// Supabase one would keep them listed. The Supabase delete goes first, so
    /// a CloudKit failure can't leave them visible.
    func deleteProfile(profile: LeaderboardProfile) async throws {
        if let userID = AccountManager.shared.authUserID {
            try await AccountManager.shared.supabase
                .from("leaderboard_entries")
                .delete()
                .eq("user_id", value: userID.uuidString)
                .execute()
        }

        guard let recordIDName = profile.cloudKitRecordID else { return }

        let recordID = CKRecord.ID(recordName: recordIDName)
        try await publicDatabase.deleteRecord(withID: recordID)
    }

    // MARK: - Leaderboard Fetching

    /// Fetch school leaderboard
    func fetchSchoolLeaderboard(schoolID: String, currentPlayerID: String, schoolName: String? = nil) async throws {
        isLoading = true
        error = nil
        lastFetchedScope = .school

        defer { isLoading = false }

        let entries = try await fetchLeaderboard(filter: .school(schoolID), currentPlayerID: currentPlayerID)

        schoolLeaderboard = entries
        schoolRank = entries.first { $0.isCurrentUser }?.rank

        // Check for competitive notification opportunities
        if let newRank = schoolRank, let school = schoolName ?? entries.first?.schoolName {
            SmartNotificationManager.shared.checkForRankChange(
                newRank: newRank,
                schoolName: school
            )

            // Check if close to next rank
            if newRank > 1, let currentUser = entries.first(where: { $0.isCurrentUser }),
               let nextUser = entries.first(where: { $0.rank == newRank - 1 }) {
                let pointsBehind = nextUser.totalScore - currentUser.totalScore
                SmartNotificationManager.shared.scheduleCloseCompetitionNotification(
                    currentRank: newRank,
                    pointsBehind: pointsBehind,
                    schoolName: school
                )
            }
        }
    }

    /// Fetch state leaderboard (US only)
    func fetchStateLeaderboard(state: String, currentPlayerID: String, visibilityLevel: LeaderboardVisibility, currentUserSchoolID: String? = nil) async throws {
        isLoading = true
        error = nil
        lastFetchedScope = .state

        defer { isLoading = false }

        // Users who chose "School Only" privacy won't appear here (expected
        // behavior) — see LeaderboardFilter.cloudKitPredicate.
        let entries = try await fetchLeaderboard(filter: .state(state), currentPlayerID: currentPlayerID)

        stateLeaderboard = entries
        stateRank = entries.first { $0.isCurrentUser }?.rank

        // Aggregate school rankings
        stateSchoolRankings = aggregateSchoolRankings(entries: entries, currentUserSchoolID: currentUserSchoolID)
        stateSchoolRank = stateSchoolRankings.first { $0.isCurrentUserSchool }?.rank
    }

    /// Fetch country leaderboard (international students)
    func fetchCountryLeaderboard(country: String, currentPlayerID: String, visibilityLevel: LeaderboardVisibility) async throws {
        isLoading = true
        error = nil
        lastFetchedScope = .country

        defer { isLoading = false }

        let entries = try await fetchLeaderboard(filter: .country(country), currentPlayerID: currentPlayerID)

        countryLeaderboard = entries
        countryRank = entries.first { $0.isCurrentUser }?.rank
    }

    /// Fetch national leaderboard (US only)
    func fetchNationalLeaderboard(currentPlayerID: String, visibilityLevel: LeaderboardVisibility, currentUserSchoolID: String? = nil) async throws {
        isLoading = true
        error = nil
        lastFetchedScope = .national

        defer { isLoading = false }

        let entries = try await fetchLeaderboard(filter: .national, currentPlayerID: currentPlayerID)

        nationalLeaderboard = entries
        nationalRank = entries.first { $0.isCurrentUser }?.rank

        // Aggregate school rankings
        nationalSchoolRankings = aggregateSchoolRankings(entries: entries, currentUserSchoolID: currentUserSchoolID)
        nationalSchoolRank = nationalSchoolRankings.first { $0.isCurrentUserSchool }?.rank
    }

    /// Fetch global leaderboard
    func fetchGlobalLeaderboard(currentPlayerID: String, visibilityLevel: LeaderboardVisibility, currentUserSchoolID: String? = nil) async throws {
        isLoading = true
        error = nil
        lastFetchedScope = .global

        defer { isLoading = false }

        let entries = try await fetchLeaderboard(filter: .global, currentPlayerID: currentPlayerID)

        globalLeaderboard = entries
        globalRank = entries.first { $0.isCurrentUser }?.rank

        // Aggregate school rankings
        globalSchoolRankings = aggregateSchoolRankings(entries: entries, currentUserSchoolID: currentUserSchoolID)
        globalSchoolRank = globalSchoolRankings.first { $0.isCurrentUserSchool }?.rank
    }

    // MARK: - Private Helpers

    /// Reads both stores and ranks the union.
    ///
    /// See SupabaseLeaderboard for why both: a player only reaches Supabase
    /// once they install a build that writes it, so reading Supabase alone
    /// would empty the standings on release day, and reading CloudKit alone
    /// keeps the duplicates.
    ///
    /// Either store may fail on its own without failing the fetch — a leaderboard
    /// missing the half that didn't load beats an error screen. Only a double
    /// failure throws.
    private func fetchLeaderboard(filter: LeaderboardFilter, currentPlayerID: String) async throws -> [LeaderboardEntry] {
        // Only the Supabase half runs as `async let`. Its rows are Sendable, so
        // they can leave the child task; `[CKRecord]` is not, and returning it
        // out of one would be crossing an actor boundary with a mutable
        // reference type. CloudKit is awaited directly instead — still
        // concurrent, because the request above is already in flight.
        async let remoteTask = SupabaseLeaderboard.fetch(filter)

        var cloudRecords: [CKRecord] = []
        var cloudError: Error?
        do { cloudRecords = try await fetchCloudKitRecords(filter: filter) } catch { cloudError = error }

        var remoteRows: [RemoteLeaderboardRow] = []
        var remoteError: Error?
        do { remoteRows = try await remoteTask } catch { remoteError = error }

        if let cloudError, remoteError != nil {
            throw cloudError
        }

        return merge(cloudRecords: cloudRecords,
                     remoteRows: remoteRows,
                     currentPlayerID: currentPlayerID)
    }

    private func fetchCloudKitRecords(filter: LeaderboardFilter) async throws -> [CKRecord] {
        let query = CKQuery(recordType: RecordType.leaderboardEntry,
                            predicate: filter.cloudKitPredicate)
        query.sortDescriptors = [NSSortDescriptor(key: RecordField.totalScore, ascending: false)]

        let (matchResults, _) = try await publicDatabase.records(matching: query, resultsLimit: 100)

        return matchResults.compactMap { _, result in
            guard case .success(let record) = result else { return nil }
            return record
        }
    }

    /// Folds both stores into one ranked list.
    ///
    /// Keyed on the CloudKit `playerID`, which a Supabase row carries as
    /// `legacy_player_id`, so a player present in both appears once. Supabase
    /// wins where both have them: it is rewritten whenever the score changes,
    /// while a CloudKit row is only as fresh as that device's last successful
    /// save.
    ///
    /// Collapsing on that key also repairs the existing CloudKit duplicates for
    /// everyone immediately — including players still on a build with the bug —
    /// by keeping the highest-scoring row of each set.
    private func merge(
        cloudRecords: [CKRecord],
        remoteRows: [RemoteLeaderboardRow],
        currentPlayerID: String
    ) -> [LeaderboardEntry] {
        let currentUserID = AccountManager.shared.authUserID?.uuidString.lowercased()
        let currentPlayer = currentPlayerID.lowercased()

        struct Candidate {
            let playerID: String
            let displayName: String
            let schoolID: String
            let schoolName: String
            let state: String
            let country: String
            let totalScore: Int
            let gamesPlayed: Int
            let gamesWon: Int
            let isCurrentUser: Bool
        }

        var byIdentity: [String: Candidate] = [:]

        for record in cloudRecords {
            let playerID = (record[RecordField.playerID] as? String) ?? ""
            let identity = playerID.lowercased()
            guard !identity.isEmpty else { continue }

            let score = record[RecordField.totalScore] as? Int ?? 0
            if let existing = byIdentity[identity], existing.totalScore >= score { continue }

            byIdentity[identity] = Candidate(
                playerID: playerID,
                displayName: record[RecordField.displayName] as? String ?? "Unknown",
                schoolID: record[RecordField.schoolID] as? String ?? "",
                schoolName: record[RecordField.schoolName] as? String ?? "",
                state: record[RecordField.state] as? String ?? "",
                country: record[RecordField.country] as? String ?? "",
                totalScore: score,
                gamesPlayed: record[RecordField.gamesPlayed] as? Int ?? 0,
                gamesWon: record[RecordField.gamesWon] as? Int ?? 0,
                isCurrentUser: identity == currentPlayer
            )
        }

        for row in remoteRows {
            byIdentity[row.identity] = Candidate(
                playerID: row.legacy_player_id ?? row.user_id,
                displayName: row.display_name.isEmpty ? "Unknown" : row.display_name,
                schoolID: row.school_id,
                schoolName: row.school_name,
                state: row.state,
                country: row.country,
                totalScore: row.total_score,
                gamesPlayed: row.games_played,
                gamesWon: row.games_won,
                // Matching on either identifier: the account is authoritative,
                // but a device that hasn't linked one still knows its playerID.
                isCurrentUser: row.user_id.lowercased() == currentUserID
                    || row.identity == currentPlayer
            )
        }

        // Ties broken by name so the order is stable between refreshes rather
        // than following whatever the dictionary happened to hand back.
        let sorted = byIdentity
            .sorted {
                $0.value.totalScore != $1.value.totalScore
                    ? $0.value.totalScore > $1.value.totalScore
                    : $0.value.displayName.localizedCaseInsensitiveCompare($1.value.displayName) == .orderedAscending
            }
            .prefix(100)

        return sorted.enumerated().map { index, item in
            LeaderboardEntry(
                id: item.key,
                playerID: item.value.playerID,
                displayName: item.value.displayName,
                schoolID: item.value.schoolID,
                schoolName: item.value.schoolName,
                state: item.value.state,
                country: item.value.country,
                totalScore: item.value.totalScore,
                gamesPlayed: item.value.gamesPlayed,
                gamesWon: item.value.gamesWon,
                rank: index + 1,
                isCurrentUser: item.value.isCurrentUser
            )
        }
    }

    /// Get cached leaderboard for a scope
    func leaderboard(for scope: LeaderboardScope) -> [LeaderboardEntry] {
        switch scope {
        case .school: return schoolLeaderboard
        case .state: return stateLeaderboard
        case .country: return countryLeaderboard
        case .national: return nationalLeaderboard
        case .global: return globalLeaderboard
        }
    }

    /// Get rank for a scope
    func rank(for scope: LeaderboardScope) -> Int? {
        switch scope {
        case .school: return schoolRank
        case .state: return stateRank
        case .country: return countryRank
        case .national: return nationalRank
        case .global: return globalRank
        }
    }

    /// Get school rankings for a scope
    func schoolRankings(for scope: LeaderboardScope) -> [SchoolRankingEntry] {
        switch scope {
        case .school: return [] // No school rankings at school level (everyone is same school)
        case .state: return stateSchoolRankings
        case .country: return [] // Could add country school rankings if needed
        case .national: return nationalSchoolRankings
        case .global: return globalSchoolRankings
        }
    }

    /// Get current user's school rank for a scope
    func schoolRank(for scope: LeaderboardScope) -> Int? {
        switch scope {
        case .school: return nil
        case .state: return stateSchoolRank
        case .country: return nil
        case .national: return nationalSchoolRank
        case .global: return globalSchoolRank
        }
    }

    /// Aggregate entries into school rankings
    private func aggregateSchoolRankings(entries: [LeaderboardEntry], currentUserSchoolID: String?) -> [SchoolRankingEntry] {
        // Group entries by schoolID
        let grouped = Dictionary(grouping: entries) { $0.schoolID }

        // Create school ranking entries
        var schoolEntries: [(schoolID: String, totalScore: Int, entry: SchoolRankingEntry?)] = []

        for (schoolID, schoolEntries_) in grouped {
            if let entry = SchoolRankingEntry.aggregate(entries: schoolEntries_, rank: 0, currentUserSchoolID: currentUserSchoolID) {
                schoolEntries.append((schoolID, entry.totalScore, entry))
            }
        }

        // Sort by total score descending
        schoolEntries.sort { $0.totalScore > $1.totalScore }

        // Assign ranks
        return schoolEntries.enumerated().compactMap { index, item in
            guard let entry = item.entry else { return nil }
            return SchoolRankingEntry(
                id: entry.id,
                schoolID: entry.schoolID,
                schoolName: entry.schoolName,
                state: entry.state,
                country: entry.country,
                totalScore: entry.totalScore,
                studentCount: entry.studentCount,
                totalGamesPlayed: entry.totalGamesPlayed,
                totalGamesWon: entry.totalGamesWon,
                rank: index + 1,
                isCurrentUserSchool: entry.schoolID == currentUserSchoolID
            )
        }
    }

    // MARK: - CloudKit Availability

    /// Check if CloudKit is available
    func checkCloudKitAvailability() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            self.error = error
            return false
        }
    }
}

// MARK: - Convenience Extensions

extension LeaderboardManager {

    /// Fetch appropriate leaderboard based on profile and scope
    func fetchLeaderboard(for scope: LeaderboardScope, profile: LeaderboardProfile) async {
        do {
            switch scope {
            case .school:
                try await fetchSchoolLeaderboard(
                    schoolID: profile.schoolID,
                    currentPlayerID: profile.playerID,
                    schoolName: profile.schoolName
                )
            case .state:
                try await fetchStateLeaderboard(
                    state: profile.state,
                    currentPlayerID: profile.playerID,
                    visibilityLevel: profile.visibilityLevel,
                    currentUserSchoolID: profile.schoolID
                )
            case .country:
                try await fetchCountryLeaderboard(
                    country: profile.country,
                    currentPlayerID: profile.playerID,
                    visibilityLevel: profile.visibilityLevel
                )
            case .national:
                try await fetchNationalLeaderboard(
                    currentPlayerID: profile.playerID,
                    visibilityLevel: profile.visibilityLevel,
                    currentUserSchoolID: profile.schoolID
                )
            case .global:
                try await fetchGlobalLeaderboard(
                    currentPlayerID: profile.playerID,
                    visibilityLevel: profile.visibilityLevel,
                    currentUserSchoolID: profile.schoolID
                )
            }
        } catch {
            self.error = error
        }
    }

    /// Sync score to CloudKit if profile exists
    func syncScoreIfNeeded(
        profile: LeaderboardProfile?,
        totalScore: Int,
        gamesPlayed: Int,
        gamesWon: Int
    ) async {
        guard let profile = profile else { return }

        // Always sync if this profile has never been synced to CloudKit
        // (cloudKitRecordID will be nil for brand new profiles)
        let needsInitialSync = profile.cloudKitRecordID == nil

        // Only sync if score has changed OR if this is the first sync
        guard needsInitialSync || totalScore != profile.lastSyncedScore else { return }

        do {
            try await syncProfile(
                profile: profile,
                totalScore: totalScore,
                gamesPlayed: gamesPlayed,
                gamesWon: gamesWon
            )
        } catch {
            self.error = error
            print("Failed to sync score: \(error.localizedDescription)")
        }
    }
}
