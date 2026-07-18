//
//  StudyPlanStore.swift
//  Rounds
//
//  Keeps the personalized study plan warm so it's INSTANT for the user. The
//  plan is cached locally and only regenerated (silently, in the background)
//  when the underlying weak-spot data actually changes — detected via a stable
//  signature. Triggered on app launch and whenever the Study Plan is opened.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class StudyPlanStore {
    static let shared = StudyPlanStore()

    private(set) var plan: StudyPlanResult?
    private(set) var isRefreshing = false
    private(set) var lastError: String?
    /// True once we've generated at least one plan (so we can distinguish
    /// "never generated" from "generating an update").
    var hasPlan: Bool { plan != nil }

    private var signature: String = ""

    private let planKey = "studyPlan.cached"
    private let sigKey = "studyPlan.signature"

    private init() { load() }

    // MARK: - Refresh

    /// Regenerate the plan if the weak-spot data changed since the cached plan.
    /// No-op for free users or when nothing has changed. Runs silently.
    func refreshIfNeeded(context: ModelContext, isPro: Bool, force: Bool = false) async {
        guard isPro else { return }

        let weak = Self.aggregateWeakSpots(context: context)
        let practiced = Self.aggregatePracticed(context: context)
        guard !weak.isEmpty || !practiced.isEmpty else { return }

        let sig = Self.signature(weak: weak, practiced: practiced)
        if !force && sig == signature && plan != nil { return }   // already current
        if isRefreshing { return }

        isRefreshing = true
        lastError = nil
        defer { isRefreshing = false }

        do {
            let result = try await AccountManager.shared.requestStudyPlan(weakSpots: weak, practiced: practiced)
            plan = result
            signature = sig
            save()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Aggregation (shared with the view)

    static func aggregateWeakSpots(context: ModelContext) -> [StudyWeakSpot] {
        let all = (try? context.fetch(FetchDescriptor<MissedItem>())) ?? []
        let wrong = all.filter { MissSource(rawValue: $0.source)?.isWrongAnswer ?? true }
        return Dictionary(grouping: wrong, by: { "\($0.topic)||\($0.item)" })
            .compactMap { _, group -> StudyWeakSpot? in
                guard let first = group.first else { return nil }
                let sources = Array(Set(group.compactMap { MissSource(rawValue: $0.source)?.displayName }))
                return StudyWeakSpot(topic: first.topic.isEmpty ? "General" : first.topic,
                                     item: first.item, count: group.count, sources: sources)
            }
            .sorted { $0.count > $1.count }
    }

    static func aggregatePracticed(context: ModelContext) -> [StudyPracticed] {
        let all = (try? context.fetch(FetchDescriptor<DDxSession>())) ?? []
        return Dictionary(grouping: all) { $0.chiefComplaint.lowercased() }
            .compactMap { _, group -> StudyPracticed? in
                guard let latest = group.max(by: { $0.timestamp < $1.timestamp }) else { return nil }
                return StudyPracticed(complaint: latest.chiefComplaint, system: latest.system, count: group.count)
            }
    }

    /// Stable content signature — changes only when the weak-spot data changes.
    private static func signature(weak: [StudyWeakSpot], practiced: [StudyPracticed]) -> String {
        let w = weak.map { "\($0.topic)|\($0.item)|\($0.count)" }.sorted().joined(separator: ";")
        let p = practiced.map { "\($0.complaint)|\($0.count)" }.sorted().joined(separator: ";")
        return "W[\(w)]P[\(p)]"
    }

    // MARK: - Persistence

    private func save() {
        if let plan, let data = try? JSONEncoder().encode(plan) {
            UserDefaults.standard.set(data, forKey: planKey)
            UserDefaults.standard.set(signature, forKey: sigKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: planKey),
           let cached = try? JSONDecoder().decode(StudyPlanResult.self, from: data) {
            plan = cached
            signature = UserDefaults.standard.string(forKey: sigKey) ?? ""
        }
    }
}
