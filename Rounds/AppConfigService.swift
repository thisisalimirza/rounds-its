//
//  AppConfigService.swift
//  Rounds
//
//  Remote switches. The table is `app_config` (key text primary key, value jsonb),
//  readable by anon and authenticated. Names match the web contract described
//  alongside the announcements work; if a key moves, this file is the change.
//
//  A missing table, a failed request, or airplane mode leaves the compiled
//  defaults in place. The last good payload is cached on disk so a later
//  offline launch still sees what the server last said.
//

import Foundation
import Supabase

nonisolated struct AppConfigSnapshot: Equatable, Sendable, Codable {
    var maintenanceMode: Bool
    var maintenanceMessage: String
    var signupsPaused: Bool
    var paywallEnabled: Bool
    var checkoutEnabled: Bool
    var minSupportedVersionIOS: String?
    var recommendedVersionIOS: String?
    var accountGateEnabled: Bool
    var anonFreeCases: Int
    var grandfatheredGateEnabled: Bool
    /// Explicit TestFlight grant. Default off so a sandbox receipt cannot hide
    /// a broken entitlement. DEBUG builds do not consult this.
    var testflightProGrant: Bool
    var flags: [String: Bool]

    static let compiledDefaults = AppConfigSnapshot(
        maintenanceMode: false,
        maintenanceMessage: "Rounds is down for a short update. Your cases are safe on this phone.",
        signupsPaused: false,
        paywallEnabled: true,
        checkoutEnabled: true,
        minSupportedVersionIOS: nil,
        recommendedVersionIOS: nil,
        accountGateEnabled: true,
        anonFreeCases: 3,
        grandfatheredGateEnabled: true,
        testflightProGrant: false,
        flags: [:]
    )

    func flag(_ key: String, default defaultValue: Bool = false) -> Bool {
        flags[key] ?? defaultValue
    }
}

/// Decodes the jsonb `value` column without depending on a particular Supabase JSON wrapper.
nonisolated enum JSONValue: Equatable, Sendable {
    case bool(Bool)
    case int(Int)
    case string(String)
    case object([String: JSONValue])
    case array([JSONValue])
    case null
}

extension JSONValue: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .int(Int(value))
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .null
        }
    }

    var bool: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var int: Int? {
        if case .int(let value) = self { return value }
        return nil
    }

    var string: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var object: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }
}

nonisolated struct AppConfigRow: Decodable, Equatable, Sendable {
    let key: String
    let value: JSONValue
}

nonisolated enum AppConfigParser {
    /// Table and column names. One place to retarget if the web schema shifts.
    static let table = "app_config"

    static func parse(_ rows: [AppConfigRow], defaults: AppConfigSnapshot = .compiledDefaults) -> AppConfigSnapshot {
        var snapshot = defaults
        let byKey = Dictionary(rows.map { ($0.key, $0.value) }, uniquingKeysWith: { _, latest in latest })

        if let mode = maintenance(byKey["maintenance_mode"]) {
            snapshot.maintenanceMode = mode.enabled
            if let message = mode.message, !message.isEmpty {
                snapshot.maintenanceMessage = message
            }
        }
        if let value = byKey["signups_paused"]?.bool { snapshot.signupsPaused = value }
        if let value = byKey["paywall_enabled"]?.bool { snapshot.paywallEnabled = value }
        if let value = byKey["checkout_enabled"]?.bool { snapshot.checkoutEnabled = value }
        if let version = iosVersion(byKey["min_supported_version"]) {
            snapshot.minSupportedVersionIOS = version
        }
        if let version = iosVersion(byKey["recommended_version"]) {
            snapshot.recommendedVersionIOS = version
        }
        if let value = byKey["account_gate_enabled"]?.bool { snapshot.accountGateEnabled = value }
        if let value = byKey["anon_free_cases"]?.int { snapshot.anonFreeCases = max(0, value) }
        if let value = byKey["grandfathered_gate_enabled"]?.bool { snapshot.grandfatheredGateEnabled = value }
        if let value = byKey["testflight_pro_grant"]?.bool { snapshot.testflightProGrant = value }

        var flags = snapshot.flags
        for (key, value) in byKey {
            if let flag = value.bool, key.hasPrefix("enable_") || key.hasPrefix("flag_") {
                flags[key] = flag
            }
        }
        snapshot.flags = flags
        return snapshot
    }

    private static func maintenance(_ value: JSONValue?) -> (enabled: Bool, message: String?)? {
        guard let value else { return nil }
        switch value {
        case .bool(let enabled):
            return (enabled, nil)
        case .object(let object):
            let enabled = object["enabled"]?.bool ?? object["on"]?.bool ?? false
            let message = object["message"]?.string
            return (enabled, message)
        default:
            return nil
        }
    }

    /// `min_supported_version` is `{ios, android}`. A bare string is accepted as the iOS value.
    private static func iosVersion(_ value: JSONValue?) -> String? {
        guard let value else { return nil }
        switch value {
        case .string(let version):
            return version
        case .object(let object):
            return object["ios"]?.string
        default:
            return nil
        }
    }
}

@MainActor
@Observable
final class AppConfigService {
    static let shared = AppConfigService()

    private(set) var snapshot: AppConfigSnapshot = .compiledDefaults

    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    private let cacheURL: URL

    private init() {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil, create: true))
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        cacheURL = base.appendingPathComponent("app_config.json")
        if let data = try? Data(contentsOf: cacheURL),
           let cached = try? JSONDecoder().decode(AppConfigSnapshot.self, from: data) {
            snapshot = cached
        }
    }

    func refresh() {
        Task { await refreshNow() }
    }

    func refreshNow() async {
        if let refreshTask {
            await refreshTask.value
            return
        }
        let task = Task { [weak self] in
            await self?.performRefresh()
        }
        refreshTask = task
        await task.value
        refreshTask = nil
    }

    private func performRefresh() async {
        do {
            let rows: [AppConfigRow] = try await AccountManager.shared.supabase
                .from(AppConfigParser.table)
                .select("key, value")
                .execute()
                .value
            let parsed = AppConfigParser.parse(rows)
            snapshot = parsed
            if let data = try? JSONEncoder().encode(parsed) {
                try? data.write(to: cacheURL, options: .atomic)
            }
        } catch {
            // Defaults or the disk cache stay. A missing table is expected until
            // the web migration lands; play must not depend on it.
            print("⚠️ app_config refresh failed: \(error.localizedDescription)")
        }
    }
}

nonisolated enum VersionGate {
    enum Decision: Equatable {
        case none
        case soft(String)
        case hard(String)
    }

    static func decide(current: String, minimum: String?, recommended: String?) -> Decision {
        if let minimum, !minimum.isEmpty, WhatsNewManager.compareVersions(current, isLessThan: minimum) {
            return .hard(minimum)
        }
        if let recommended, !recommended.isEmpty, WhatsNewManager.compareVersions(current, isLessThan: recommended) {
            return .soft(recommended)
        }
        return .none
    }
}
