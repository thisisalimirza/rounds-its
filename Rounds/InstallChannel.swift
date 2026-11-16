//
//  InstallChannel.swift
//  Rounds
//
//  TestFlight is the embedded provisioning profile's beta-reports-active flag.
//  A sandbox receipt is not enough: Xcode and StoreKit testing use one too.
//  DEBUG is its own channel so a local build is never reported as TestFlight.
//

import Foundation

nonisolated enum InstallChannel {
    static var isTestFlight: Bool {
        isTestFlight(provisioningProfile: embeddedProfileText(), debugBuild: isDebugBuild)
    }

    /// `debug`, `testflight`, or `app_store`.
    static var channel: String {
        channel(provisioningProfile: embeddedProfileText(), debugBuild: isDebugBuild)
    }

    static func isTestFlight(provisioningProfile: String?, debugBuild: Bool) -> Bool {
        guard !debugBuild, let provisioningProfile else { return false }
        return marksTestFlight(provisioningProfile)
    }

    static func channel(provisioningProfile: String?, debugBuild: Bool) -> String {
        if debugBuild { return "debug" }
        if isTestFlight(provisioningProfile: provisioningProfile, debugBuild: false) {
            return "testflight"
        }
        return "app_store"
    }

    /// The next boolean after `beta-reports-active` has to be true. A development
    /// profile that merely mentions the key does not count.
    static func marksTestFlight(_ provisioning: String) -> Bool {
        guard let key = provisioning.range(of: "beta-reports-active") else { return false }
        let tail = provisioning[key.upperBound...].prefix(160)
        guard let trueAt = tail.range(of: "<true/>") else { return false }
        if let falseAt = tail.range(of: "<false/>"), falseAt.lowerBound < trueAt.lowerBound {
            return false
        }
        return true
    }

    private static var isDebugBuild: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    private static func embeddedProfileText() -> String? {
        guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return String(data: data, encoding: .ascii) ?? String(data: data, encoding: .utf8)
    }
}

nonisolated enum SyncFailureReport {
    static func describe(_ error: Error) -> (code: String, message: String) {
        let ns = error as NSError
        let message = String(ns.localizedDescription.prefix(180))
        if ns.domain == NSURLErrorDomain {
            return ("URLError.\(ns.code)", message)
        }
        let code = ns.code == 0 ? ns.domain : "\(ns.domain).\(ns.code)"
        return (String(code.prefix(80)), message)
    }
}
