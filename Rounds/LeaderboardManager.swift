//
//  LeaderboardManager.swift
//  Rounds
//
//  CloudKit-backed leaderboard manager
//

import Foundation
import CloudKit
import SwiftData

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

        // Check if we have an existing record
        if let existingRecordID = profile.cloudKitRecordID {
            let recordID = CKRecord.ID(recordName: existingRecordID)
            do {
                record = try await publicDatabase.record(for: recordID)
            } catch {
                // Record doesn't exist, create new one
                record = CKRecord(recordType: RecordType.leaderboardEntry)
            }
        } else {
            // Create new record with player ID as record name for easy lookup
            let recordID = CKRecord.ID(recordName: "player_\(profile.playerID)")
            record = CKRecord(recordType: RecordType.leaderboardEntry, recordID: recordID)
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

    /// Delete leaderboard entry from CloudKit
    func deleteProfile(profile: LeaderboardProfile) async throws {
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

        let predicate = NSPredicate(format: "%K == %@", RecordField.schoolID, schoolID)
        let entries = try await fetchLeaderboard(predicate: predicate, currentPlayerID: currentPlayerID)

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

        // CloudKit public database does NOT support OR predicates
        // Only show globally visible users on state leaderboard
        // Users who chose "School Only" privacy won't appear here (expected behavior)
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            RecordField.state, state,
            RecordField.visibilityLevel, LeaderboardVisibility.global.rawValue
        )

        let entries = try await fetchLeaderboard(predicate: predicate, currentPlayerID: currentPlayerID)

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

        // CloudKit public database does NOT support OR predicates
        // Only show globally visible users on country leaderboard
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            RecordField.country, country,
            RecordField.visibilityLevel, LeaderboardVisibility.global.rawValue
        )

        let entries = try await fetchLeaderboard(predicate: predicate, currentPlayerID: currentPlayerID)

        countryLeaderboard = entries
        countryRank = entries.first { $0.isCurrentUser }?.rank
    }

    /// Fetch national leaderboard (US only)
    func fetchNationalLeaderboard(currentPlayerID: String, visibilityLevel: LeaderboardVisibility, currentUserSchoolID: String? = nil) async throws {
        isLoading = true
        error = nil
        lastFetchedScope = .national

        defer { isLoading = false }

        // CloudKit public database does NOT support OR predicates
        // Only show globally visible US users on national leaderboard
        let predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            RecordField.country, "US",
            RecordField.visibilityLevel, LeaderboardVisibility.global.rawValue
        )

        let entries = try await fetchLeaderboard(predicate: predicate, currentPlayerID: currentPlayerID)

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

        // CloudKit public database does NOT support OR predicates
        // Only show globally visible users on global leaderboard
        let predicate = NSPredicate(
            format: "%K == %@",
            RecordField.visibilityLevel, LeaderboardVisibility.global.rawValue
        )

        let entries = try await fetchLeaderboard(predicate: predicate, currentPlayerID: currentPlayerID)

        globalLeaderboard = entries
        globalRank = entries.first { $0.isCurrentUser }?.rank

        // Aggregate school rankings
        globalSchoolRankings = aggregateSchoolRankings(entries: entries, currentUserSchoolID: currentUserSchoolID)
        globalSchoolRank = globalSchoolRankings.first { $0.isCurrentUserSchool }?.rank
    }

    // MARK: - Private Helpers

    private func fetchLeaderboard(predicate: NSPredicate, currentPlayerID: String) async throws -> [LeaderboardEntry] {
        let query = CKQuery(recordType: RecordType.leaderboardEntry, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: RecordField.totalScore, ascending: false)]

        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 100 // Limit to top 100

        var records: [CKRecord] = []

        // Fetch records
        let (matchResults, _) = try await publicDatabase.records(matching: query, resultsLimit: 100)

        for (_, result) in matchResults {
            if case .success(let record) = result {
                records.append(record)
            }
        }

        // Convert to LeaderboardEntry with ranks
        let entries = records.enumerated().map { index, record in
            LeaderboardEntry(
                id: record.recordID.recordName,
                playerID: record[RecordField.playerID] as? String ?? "",
                displayName: record[RecordField.displayName] as? String ?? "Unknown",
                schoolID: record[RecordField.schoolID] as? String ?? "",
                schoolName: record[RecordField.schoolName] as? String ?? "",
                state: record[RecordField.state] as? String ?? "",
                country: record[RecordField.country] as? String ?? "",
                totalScore: record[RecordField.totalScore] as? Int ?? 0,
                gamesPlayed: record[RecordField.gamesPlayed] as? Int ?? 0,
                gamesWon: record[RecordField.gamesWon] as? Int ?? 0,
                rank: index + 1,
                isCurrentUser: (record[RecordField.playerID] as? String) == currentPlayerID
            )
        }

        return entries
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
