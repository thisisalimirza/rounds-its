//
//  ProIdentityPlanner.swift
//  Rounds
//
//  RevenueCat only aliases a customer when logIn is called from $RCAnonymousID.
//  logIn from one Supabase id to another switches, and does not move purchases
//  or promotional grants. syncPurchases uploads this device's receipt. With
//  the dashboard set to "Transfer to new App User ID" that moves a store
//  purchase onto the id that doesn't have one yet — which is what we want
//  once, and what ping-pongs Pro if we do it when the id is already entitled.
//

import Foundation

nonisolated enum ProIdentityPlanner {

    struct Plan: Equatable, Sendable {
        /// Upload the device receipt after this logIn.
        var syncPurchases: Bool
    }

    /// True when the current RevenueCat user is still the SDK's anonymous id,
    /// so the next logIn will alias rather than switch.
    static func willAlias(currentAppUserID: String) -> Bool {
        currentAppUserID.hasPrefix("$RCAnonymousID")
    }

    /// Sync only when the id we just logged into has no active entitlement.
    /// An id that already has one must not pull the receipt off another id.
    static func afterLogIn(newIdentityHasActiveEntitlement: Bool) -> Plan {
        Plan(syncPurchases: !newIdentityHasActiveEntitlement)
    }
}
