//
//  WhatsNewManager.swift
//  Rounds
//
//  Drives the "What's New" splash. Fully local + version-keyed so it's
//  self-maintaining: to ship a What's New for a release, add ONE entry to
//  `AppChangelog.releases` with a higher version string. It auto-shows once,
//  the next time the user opens the app, and never nags again.
//

import Foundation
import Combine

// MARK: - What's New Data Models

struct WhatsNewData: Codable {
    let version: String
    let lastUpdated: String
    let showToVersionsBelow: String
    let title: String
    let features: [WhatsNewFeature]
    let footer: String?
    let dismissButtonText: String?
}

struct WhatsNewFeature: Codable, Identifiable {
    var id: String { title }
    let icon: String
    let title: String
    let description: String
}

// MARK: - App Changelog (the single source of truth)
//
// ▶︎ TO ADD A "WHAT'S NEW" FOR A RELEASE:
//   1. Bump the app version in Xcode (nice to keep in sync, but not required).
//   2. Add ONE `AppRelease` to the top of `releases` with a version string
//      higher than the previous entry.
// That's it — it shows automatically on next launch for existing users, and is
// skipped for brand-new installs (they get onboarding instead).

struct AppRelease {
    let version: String
    let title: String
    let features: [WhatsNewFeature]
    var footer: String? = "Thanks for using Rounds!"

    func asWhatsNewData() -> WhatsNewData {
        WhatsNewData(
            version: version,
            lastUpdated: "",
            showToVersionsBelow: version,
            title: title,
            features: features,
            footer: footer,
            dismissButtonText: "Let's Go!"
        )
    }
}

enum AppChangelog {
    /// Newest release first.
    static let releases: [AppRelease] = [
        AppRelease(
            version: "1.4.0",
            title: "What's New in Rounds",
            features: [
                WhatsNewFeature(
                    icon: "books.vertical.fill",
                    title: "Illness Scripts Library",
                    description: "A growing reference of high-yield illness scripts — who gets it, the workup, the pathophys, treatment, and the pivot points that tell lookalikes apart. Free for conditions you've missed."
                ),
                WhatsNewFeature(
                    icon: "stethoscope",
                    title: "Differential Builder",
                    description: "Type what you found on a patient and get a structured differential — the findings that support each diagnosis and the next steps to confirm it. Five free builds, then Pro."
                ),
                WhatsNewFeature(
                    icon: "brain.head.profile",
                    title: "Weak Spots & Study Plan",
                    description: "Everything you miss across cases and challenges is tracked into your Weak Spots — and Pro turns it into a personalized study plan for exactly what to review."
                ),
                WhatsNewFeature(
                    icon: "icloud.and.arrow.up.fill",
                    title: "Cross-Device Sync",
                    description: "Sign in with Apple or email so your Pro access and progress follow you to a new phone, iPad, or the web."
                ),
                WhatsNewFeature(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Feedback & Ideas Board",
                    description: "Share feedback in-app and vote on what we build next — our roadmap is driven by what you want."
                )
            ]
        )
    ]

    static var latest: AppRelease? {
        releases.max(by: { WhatsNewManager.compareVersions($0.version, isLessThan: $1.version) })
    }
}

// MARK: - What's New Manager

@MainActor
final class WhatsNewManager: ObservableObject {
    static let shared = WhatsNewManager()

    private let lastSeenVersionKey = "whatsNew_lastSeenVersion"

    @Published var whatsNewData: WhatsNewData?
    @Published var shouldShowWhatsNew = false

    private init() {}

    // MARK: - Public API

    /// Call on app launch. Decides whether the newest release should be shown.
    func checkForWhatsNew() {
        guard let latest = AppChangelog.latest else { return }
        whatsNewData = latest.asWhatsNewData()

        let lastSeen = UserDefaults.standard.string(forKey: lastSeenVersionKey)

        // Brand-new install: don't interrupt onboarding — silently record the
        // newest version so What's New only appears after a real update.
        guard let lastSeen else {
            UserDefaults.standard.set(latest.version, forKey: lastSeenVersionKey)
            return
        }

        if Self.compareVersions(lastSeen, isLessThan: latest.version) {
            shouldShowWhatsNew = true
        }
    }

    /// Mark the current release as seen (call when the sheet is dismissed).
    func markAsSeen() {
        let version = whatsNewData?.version ?? AppChangelog.latest?.version
        if let version {
            UserDefaults.standard.set(version, forKey: lastSeenVersionKey)
        }
        shouldShowWhatsNew = false
    }

    /// Force show (Settings → "What's New").
    func forceShow() {
        if whatsNewData == nil {
            whatsNewData = AppChangelog.latest?.asWhatsNewData()
        }
        if whatsNewData != nil {
            shouldShowWhatsNew = true
        }
    }

    /// Reset seen status (debug).
    func resetSeenStatus() {
        UserDefaults.standard.removeObject(forKey: lastSeenVersionKey)
    }

    // MARK: - Version compare

    /// True when `v1` is strictly older than `v2` (dot-separated numeric).
    static func compareVersions(_ v1: String, isLessThan v2: String) -> Bool {
        let a = v1.split(separator: ".").compactMap { Int($0) }
        let b = v2.split(separator: ".").compactMap { Int($0) }
        let n = max(a.count, b.count)
        for i in 0..<n {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x < y { return true }
            if x > y { return false }
        }
        return false
    }
}
