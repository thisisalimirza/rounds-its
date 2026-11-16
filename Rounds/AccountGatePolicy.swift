//
//  AccountGatePolicy.swift
//  Rounds
//
//  Decides whether anonymous play may continue. Existing players are asked
//  only after their history is confirmed on the server. New players get a
//  short free run, then the same gate, and only while the device is online.
//  The thresholds come from app_config, with compiled defaults underneath.
//

import Foundation

nonisolated enum AccountCohort: String, Equatable, Sendable {
    case grandfathered
    case trial
}

nonisolated enum AccountGateKind: Equatable, Sendable {
    case none
    case nudge
    case grandfathered
    case trialLimit
}

nonisolated struct AccountGateContext: Equatable, Sendable {
    var isAnonymous: Bool
    var isOnline: Bool
    var hasSession: Bool
    var backfillConfirmed: Bool
    var cohort: AccountCohort
    var casesCompleted: Int
    var gateEnabled: Bool
    var grandfatheredEnabled: Bool
    var freeCases: Int
    var playingCase: Bool
    var nudgeAlreadyShown: Bool
}

nonisolated enum AccountGatePolicy {
    static func decision(_ context: AccountGateContext) -> AccountGateKind {
        guard context.isAnonymous, context.gateEnabled, context.hasSession else { return .none }

        let limit = max(0, context.freeCases)

        if context.cohort == .grandfathered {
            // The grandfathered switch is independent of the trial. Turning it
            // off must not drop existing players into the trial gate.
            guard context.grandfatheredEnabled else { return .none }
            guard context.isOnline, context.backfillConfirmed, !context.playingCase else { return .none }
            return .grandfathered
        }

        if context.casesCompleted >= limit {
            guard context.isOnline, !context.playingCase else { return .none }
            return .trialLimit
        }

        if !context.nudgeAlreadyShown,
           context.casesCompleted >= 1,
           context.casesCompleted < limit,
           !context.playingCase {
            return .nudge
        }
        return .none
    }
}

/// Cohort is fixed the first time this build sees the install. A phone that
/// already has finished cases is an existing player; a fresh install is a trial.
nonisolated enum AccountCohortStore {
    static let cohortKey = "accountGate.cohort.v1"
    static let nudgeKey = "accountGate.nudgeShown.v1"

    static func establishIfNeeded(hasPriorProgress: Bool) {
        guard UserDefaults.standard.string(forKey: cohortKey) == nil else { return }
        let value: AccountCohort = hasPriorProgress ? .grandfathered : .trial
        UserDefaults.standard.set(value.rawValue, forKey: cohortKey)
    }

    static var cohort: AccountCohort {
        AccountCohort(rawValue: UserDefaults.standard.string(forKey: cohortKey) ?? "") ?? .trial
    }

    static var nudgeShown: Bool {
        UserDefaults.standard.bool(forKey: nudgeKey)
    }

    static func markNudgeShown() {
        UserDefaults.standard.set(true, forKey: nudgeKey)
    }
}
