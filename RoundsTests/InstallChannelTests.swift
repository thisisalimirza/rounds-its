//
//  InstallChannelTests.swift
//  RoundsTests
//

import Foundation
import Testing
@testable import Rounds

struct InstallChannelTests {
    private let testFlightProfile = """
    <key>beta-reports-active</key>
    <true/>
    """

    @Test func testFlightRequiresTheBetaReportsFlag() {
        #expect(InstallChannel.marksTestFlight(testFlightProfile))
        #expect(!InstallChannel.marksTestFlight("<key>beta-reports-active</key><false/>"))
        #expect(!InstallChannel.marksTestFlight("development profile"))
    }

    @Test func debugIsNeverTestFlight() {
        #expect(!InstallChannel.isTestFlight(provisioningProfile: testFlightProfile, debugBuild: true))
        #expect(InstallChannel.channel(provisioningProfile: testFlightProfile, debugBuild: true) == "debug")
        #expect(InstallChannel.isTestFlight(provisioningProfile: testFlightProfile, debugBuild: false))
        #expect(InstallChannel.channel(provisioningProfile: nil, debugBuild: false) == "app_store")
    }

    @Test func syncFailureKeepsTheURLErrorCode() {
        let described = SyncFailureReport.describe(URLError(.notConnectedToInternet))
        #expect(described.code == "URLError.\(URLError.notConnectedToInternet.rawValue)")
    }
}
