//
//  AnnouncementService.swift
//  Rounds
//
//  Reads live announcements through get_active_announcements. Column and RPC
//  names live in AnnouncementContract so a web rename is a one-file change.
//  This file does not create the tables. The web migration owns them.
//

import Foundation
import Supabase
import SwiftUI

nonisolated enum AnnouncementContract {
    static let rpc = "get_active_announcements"
    static let eventsTable = "player_announcement_events"
    static let surface = "ios"
    static let platform = "ios"
    static let dismissedKey = "announcements.dismissed.v1"
}

nonisolated struct RemoteAnnouncement: Decodable, Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let body: String
    let ctaLabel: String?
    let ctaURL: String?
    let kind: String
    let dismissible: Bool
    let priority: Int

    enum CodingKeys: String, CodingKey {
        case id, title, body, kind, dismissible, priority
        case ctaLabel = "cta_label"
        case ctaURL = "cta_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        ctaLabel = try container.decodeIfPresent(String.self, forKey: .ctaLabel)
        ctaURL = try container.decodeIfPresent(String.self, forKey: .ctaURL)
        kind = try container.decodeIfPresent(String.self, forKey: .kind) ?? "banner"
        dismissible = try container.decodeIfPresent(Bool.self, forKey: .dismissible) ?? true
        priority = try container.decodeIfPresent(Int.self, forKey: .priority) ?? 0
    }
}

nonisolated enum AnnouncementSelection {
    static func visible(
        _ items: [RemoteAnnouncement],
        kind: String,
        dismissed: Set<String>
    ) -> RemoteAnnouncement? {
        items
            .filter { $0.kind == kind }
            .filter { item in
                !item.dismissible || !dismissed.contains(item.id.uuidString.lowercased())
            }
            .max { $0.priority < $1.priority }
    }
}

@MainActor
@Observable
final class AnnouncementService {
    static let shared = AnnouncementService()

    private(set) var items: [RemoteAnnouncement] = []
    private var dismissed: Set<String> = Set(
        UserDefaults.standard.stringArray(forKey: AnnouncementContract.dismissedKey) ?? []
    )

    private init() {}

    func refresh() async {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        do {
            let rows: [RemoteAnnouncement] = try await AccountManager.shared.supabase
                .rpc(AnnouncementContract.rpc, params: [
                    "p_surface": AnyJSON.string(AnnouncementContract.surface),
                    "p_platform": AnyJSON.string(AnnouncementContract.platform),
                    "p_app_version": AnyJSON.string(version),
                ])
                .execute()
                .value
            items = rows
        } catch {
            // The RPC is not deployed until the web migration lands. Play continues.
            print("⚠️ announcements refresh failed: \(error.localizedDescription)")
        }
    }

    func banner() -> RemoteAnnouncement? {
        AnnouncementSelection.visible(items, kind: "banner", dismissed: dismissed)
            ?? AnnouncementSelection.visible(items, kind: "in_app", dismissed: dismissed)
    }

    func modal() -> RemoteAnnouncement? {
        AnnouncementSelection.visible(items, kind: "modal", dismissed: dismissed)
    }

    func dismiss(_ item: RemoteAnnouncement) {
        guard item.dismissible else { return }
        dismissed.insert(item.id.uuidString.lowercased())
        UserDefaults.standard.set(Array(dismissed), forKey: AnnouncementContract.dismissedKey)
        Task { await record(item, event: "dismiss") }
    }

    func record(_ item: RemoteAnnouncement, event: String) async {
        struct EventRow: Encodable {
            let announcement_id: String
            let event: String
            let platform: String
        }
        let row = EventRow(
            announcement_id: item.id.uuidString.lowercased(),
            event: event,
            platform: AnnouncementContract.platform
        )
        do {
            try await AccountManager.shared.supabase
                .from(AnnouncementContract.eventsTable)
                .insert(row)
                .execute()
        } catch {
            print("⚠️ announcement event failed: \(error.localizedDescription)")
        }
    }
}

struct AnnouncementCard: View {
    let item: RemoteAnnouncement
    @State private var recordedView = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
                if item.dismissible {
                    Button {
                        AnnouncementService.shared.dismiss(item)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if !item.body.isEmpty {
                Text(item.body)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            if let label = item.ctaLabel, let urlString = item.ctaURL, let url = URL(string: urlString) {
                Link(label, destination: url)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .simultaneousGesture(TapGesture().onEnded {
                        Task { await AnnouncementService.shared.record(item, event: "click") }
                    })
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.29, green: 0.565, blue: 0.886).opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
        .task {
            guard !recordedView else { return }
            recordedView = true
            await AnnouncementService.shared.record(item, event: "view")
        }
    }
}

struct MaintenanceView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 36))
                .foregroundStyle(Color(red: 0.29, green: 0.565, blue: 0.886))
            Text("Rounds will be right back")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(message)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .interactiveDismissDisabled()
    }
}
