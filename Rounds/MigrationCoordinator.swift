//
//  MigrationCoordinator.swift
//  Rounds
//
//  One-time upload of the on-device history. The local "migrated" flag is set
//  only after `confirm_migration_v2` reports the server is holding at least as
//  many rows as this phone just counted. A failure leaves the flag unset and
//  the next launch tries again. Nothing here deletes SwiftData.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class MigrationCoordinator {
    static let shared = MigrationCoordinator()

    private(set) var isConfirmed = false

    private init() {}

    func noteSession(userID: UUID?) {
        isConfirmed = Self.localFlag(for: userID)
    }

    /// Uploads are performed by `ProgressSyncManager.sync()` before this runs.
    func confirmIfNeeded(context: ModelContext) async {
        guard let userID = AccountManager.shared.authUserID else { return }
        if Self.localFlag(for: userID) {
            isConfirmed = true
            return
        }

        let history = (try? context.fetchCount(FetchDescriptor<CaseHistoryEntry>())) ?? 0
        let misses = (try? context.fetchCount(FetchDescriptor<MissedItem>())) ?? 0
        let ddx = (try? context.fetchCount(FetchDescriptor<DDxSession>())) ?? 0
        let hasAchievements = ((try? context.fetchCount(FetchDescriptor<AchievementProgress>())) ?? 0) > 0

        do {
            let result = try await AccountManager.shared.confirmMigration(
                caseHistory: history,
                missedItems: misses,
                ddxSessions: ddx,
                hasAchievements: hasAchievements
            )
            if result.confirmed {
                UserDefaults.standard.set(true, forKey: Self.key(for: userID))
                isConfirmed = true
            } else {
                isConfirmed = false
                print("⚠️ migration not confirmed: server counts \(result.serverHistory)/\(result.serverMisses)/\(result.serverDDx) vs local \(history)/\(misses)/\(ddx)")
            }
        } catch {
            isConfirmed = false
            print("⚠️ migration confirm failed: \(error.localizedDescription)")
        }
    }

    private static func key(for userID: UUID) -> String {
        "migrated_v2.\(userID.uuidString.lowercased())"
    }

    private static func localFlag(for userID: UUID?) -> Bool {
        guard let userID else { return false }
        return UserDefaults.standard.bool(forKey: key(for: userID))
    }
}
