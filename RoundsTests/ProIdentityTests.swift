//
//  ProIdentityTests.swift
//  RoundsTests
//

import Testing
@testable import Rounds

struct ProIdentityTests {

    @Test func anonymousRevenueCatIdentityAliases() {
        #expect(ProIdentityPlanner.willAlias(currentAppUserID: "$RCAnonymousID:abc"))
        #expect(!ProIdentityPlanner.willAlias(currentAppUserID: "8b3c1e2a-0000-4000-8000-000000000001"))
    }

    @Test func syncOnlyWhenTheNewIdentityHasNoEntitlement() {
        #expect(ProIdentityPlanner.afterLogIn(newIdentityHasActiveEntitlement: false).syncPurchases)
        #expect(!ProIdentityPlanner.afterLogIn(newIdentityHasActiveEntitlement: true).syncPurchases)
    }
}
