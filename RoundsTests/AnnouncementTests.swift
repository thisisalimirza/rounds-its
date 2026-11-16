//
//  AnnouncementTests.swift
//  RoundsTests
//

import Testing
@testable import Rounds

struct AnnouncementTests {

    private func item(_ id: String, kind: String, priority: Int, dismissible: Bool = true) -> RemoteAnnouncement {
        let json = """
        {"id":"\(id)","title":"t","body":"b","kind":"\(kind)","priority":\(priority),"dismissible":\(dismissible)}
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(RemoteAnnouncement.self, from: json)
    }

    @Test func highestPriorityVisibleItemWins() {
        let low = item("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", kind: "banner", priority: 1)
        let high = item("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", kind: "banner", priority: 5)
        let shown = AnnouncementSelection.visible([low, high], kind: "banner", dismissed: [])
        #expect(shown?.id == high.id)
    }

    @Test func dismissedBannerStaysHiddenUnlessItCannotBeDismissed() {
        let id = "cccccccc-cccc-cccc-cccc-cccccccccccc"
        let banner = item(id, kind: "banner", priority: 1)
        let sticky = item("dddddddd-dddd-dddd-dddd-dddddddddddd", kind: "banner", priority: 0, dismissible: false)
        let dismissed: Set<String> = [id]
        #expect(AnnouncementSelection.visible([banner], kind: "banner", dismissed: dismissed) == nil)
        #expect(AnnouncementSelection.visible([sticky], kind: "banner", dismissed: dismissed)?.id == sticky.id)
    }

    @Test func changelogAdapterUsesTheNewestVersion() {
        let entries = [
            RemoteChangelogEntry(version: "1.4.0", title: "Old", body: "Earlier", publishedAt: nil),
            RemoteChangelogEntry(version: "1.6.0", title: "Notes", body: "A new case format.", publishedAt: nil),
        ]
        let notes = RemoteChangelog.notes(from: entries)
        #expect(notes?.version == "1.6.0")
        #expect(notes?.features.first?.description == "A new case format.")
    }

    @Test func versionGateBlocksOnlyBelowTheMinimum() {
        #expect(VersionGate.decide(current: "1.4", minimum: "1.5", recommended: "1.6") == .hard("1.5"))
        #expect(VersionGate.decide(current: "1.5", minimum: "1.5", recommended: "1.6") == .soft("1.6"))
        #expect(VersionGate.decide(current: "1.6", minimum: "1.5", recommended: "1.6") == .none)
    }
}
