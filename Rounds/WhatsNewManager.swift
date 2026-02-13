//
//  WhatsNewManager.swift
//  Rounds
//
//  Manages fetching and displaying "What's New" content from GitHub
//

import Foundation

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

// MARK: - What's New Manager

@MainActor
class WhatsNewManager: ObservableObject {
    static let shared = WhatsNewManager()

    // IMPORTANT: Update this URL to your GitHub repo's raw file URL
    // Format: https://raw.githubusercontent.com/{username}/{repo}/{branch}/whats-new.json
    private let remoteURL = URL(string: "https://raw.githubusercontent.com/thisisalimirza/rounds-its/main/whats-new.json")!

    // UserDefaults keys
    private let lastSeenVersionKey = "whatsNew_lastSeenVersion"
    private let cachedDataKey = "whatsNew_cachedData"
    private let lastFetchKey = "whatsNew_lastFetch"

    @Published var whatsNewData: WhatsNewData?
    @Published var shouldShowWhatsNew = false
    @Published var isLoading = false

    private init() {}

    // MARK: - Public Methods

    /// Call this on app launch to check for and potentially show What's New
    func checkForWhatsNew() async {
        isLoading = true
        defer { isLoading = false }

        // First, try to fetch fresh data from GitHub
        if let data = await fetchRemoteData() {
            whatsNewData = data
            cacheData(data)

            // Check if we should show this to the user
            if shouldShowToUser(data: data) {
                shouldShowWhatsNew = true
            }
        } else if let cached = getCachedData() {
            // Fall back to cached data if network fails
            whatsNewData = cached
            if shouldShowToUser(data: cached) {
                shouldShowWhatsNew = true
            }
        }
    }

    /// Mark the current version as seen (call when user dismisses the sheet)
    func markAsSeen() {
        guard let data = whatsNewData else { return }
        UserDefaults.standard.set(data.version, forKey: lastSeenVersionKey)
        shouldShowWhatsNew = false
    }

    /// Force show What's New (for testing or settings menu)
    func forceShow() {
        if whatsNewData != nil {
            shouldShowWhatsNew = true
        }
    }

    /// Reset seen status (for testing)
    func resetSeenStatus() {
        UserDefaults.standard.removeObject(forKey: lastSeenVersionKey)
    }

    // MARK: - Private Methods

    private func fetchRemoteData() async -> WhatsNewData? {
        do {
            // Add cache-busting query parameter to avoid CDN caching
            var components = URLComponents(url: remoteURL, resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "t", value: String(Date().timeIntervalSince1970))]

            guard let url = components.url else { return nil }

            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("WhatsNewManager: Invalid response")
                return nil
            }

            let decoder = JSONDecoder()
            let whatsNew = try decoder.decode(WhatsNewData.self, from: data)

            // Update last fetch time
            UserDefaults.standard.set(Date(), forKey: lastFetchKey)

            return whatsNew
        } catch {
            print("WhatsNewManager: Failed to fetch - \(error.localizedDescription)")
            return nil
        }
    }

    private func shouldShowToUser(data: WhatsNewData) -> Bool {
        let lastSeenVersion = UserDefaults.standard.string(forKey: lastSeenVersionKey) ?? "0.0.0"

        // Compare versions - show if user hasn't seen this version yet
        // and if their last seen version is below the threshold
        return compareVersions(lastSeenVersion, isLessThan: data.showToVersionsBelow)
    }

    private func compareVersions(_ v1: String, isLessThan v2: String) -> Bool {
        let v1Parts = v1.split(separator: ".").compactMap { Int($0) }
        let v2Parts = v2.split(separator: ".").compactMap { Int($0) }

        // Pad arrays to same length
        let maxLength = max(v1Parts.count, v2Parts.count)
        var v1Padded = v1Parts
        var v2Padded = v2Parts

        while v1Padded.count < maxLength { v1Padded.append(0) }
        while v2Padded.count < maxLength { v2Padded.append(0) }

        for i in 0..<maxLength {
            if v1Padded[i] < v2Padded[i] { return true }
            if v1Padded[i] > v2Padded[i] { return false }
        }

        return false // Equal versions
    }

    // MARK: - Caching

    private func cacheData(_ data: WhatsNewData) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: cachedDataKey)
        }
    }

    private func getCachedData() -> WhatsNewData? {
        guard let data = UserDefaults.standard.data(forKey: cachedDataKey) else { return nil }
        return try? JSONDecoder().decode(WhatsNewData.self, from: data)
    }
}
