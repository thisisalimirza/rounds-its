//
//  WeakSpotsView.swift
//  Rounds
//
//  A clear, scalable review of everything the student needs to work on, split
//  into two unambiguous buckets:
//   • Got wrong  — actual wrong answers, grouped by topic, each item showing
//                  exactly which mode it came from.
//   • Practiced  — presentations they built a differential for (reopenable).
//
//  Designed to stay readable after hundreds of cases: topics collapse, and each
//  item is labeled with its source so nothing is ambiguous.
//

import SwiftUI
import SwiftData

struct WeakSpotsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MissedItem.timestamp, order: .reverse) private var misses: [MissedItem]
    @Query(sort: \DDxSession.timestamp, order: .reverse) private var sessions: [DDxSession]

    private enum Filter: String, CaseIterable, Identifiable {
        case gotWrong = "Got wrong"
        case practiced = "Practiced"
        var id: String { rawValue }
    }

    @State private var filter: Filter = .gotWrong
    @State private var expandedTopics: Set<String> = []
    @State private var selectedSnapshot: DDxSnapshot?
    @State private var showingStudyPlan = false
    @State private var selectedCondition: ConditionRef?

    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }

    // MARK: Derived data

    /// Genuine wrong answers (excludes Differential Builder "uncertainty" signal).
    private var wrongMisses: [MissedItem] { misses.filter { $0.sourceKind?.isWrongAnswer ?? true } }

    /// Wrong answers grouped by topic, most-missed topic first.
    private var topicGroups: [TopicGroup] {
        Dictionary(grouping: wrongMisses, by: { $0.topic.isEmpty ? "General" : $0.topic })
            .map { key, items in TopicGroup(topic: key, items: items) }
            .sorted { $0.total > $1.total }
    }

    /// Saved builder sessions grouped by complaint (latest first), reopenable.
    private var workedGroups: [WorkedGroup] {
        Dictionary(grouping: sessions) { $0.chiefComplaint.lowercased() }
            .compactMap { _, items -> WorkedGroup? in
                guard let latest = items.max(by: { $0.timestamp < $1.timestamp }) else { return nil }
                return WorkedGroup(complaint: latest.chiefComplaint, system: latest.system,
                                   count: items.count, latest: latest)
            }
            .sorted { $0.latest.timestamp > $1.latest.timestamp }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color.blue.opacity(0.06), Color.purple.opacity(0.06)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                Group {
                    if misses.isEmpty && sessions.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                summaryHeader
                                studyPlanCTA
                                filterPicker
                                if filter == .gotWrong { gotWrongContent } else { practicedContent }
                            }
                            .padding()
                            .padding(.bottom, 24)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Weak Spots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
            .sheet(item: $selectedSnapshot) { DifferentialDiagnosisView(restore: $0) }
            .sheet(isPresented: $showingStudyPlan) { StudyPlanView() }
            .sheet(item: $selectedCondition) { ref in
                IllnessScriptSheet(condition: ref.name, reason: "review")
            }
        }
    }

    // MARK: Header

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(wrongMisses.count + sessions.count) to review")
                .font(.system(.title2, design: .rounded).weight(.bold))
            HStack(spacing: 6) {
                Label("\(wrongMisses.count) got wrong", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.orange)
                Text("·").foregroundStyle(.secondary)
                Label("\(sessions.count) practiced", systemImage: "stethoscope")
                    .foregroundStyle(.blue)
            }
            .font(.caption.weight(.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Study plan CTA (Pro)

    private var studyPlanCTA: some View {
        Button {
            if subscriptionManager.isProUser {
                showingStudyPlan = true
            } else {
                showingStudyPlan = true // StudyPlanView shows the Pro gate itself
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.title2).foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Get my study plan")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    Text("Targeted recommendations built from your weak spots")
                        .font(.caption2).foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                if !subscriptionManager.isProUser {
                    Text("PRO").font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white).padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Capsule().fill(.white.opacity(0.25)))
                }
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.white.opacity(0.9))
            }
            .padding()
            .background(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .purple.opacity(0.25), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: Filter

    private var filterPicker: some View {
        Picker("", selection: $filter) {
            ForEach(Filter.allCases) { f in
                Text("\(f.rawValue) (\(f == .gotWrong ? wrongMisses.count : sessions.count))").tag(f)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: Got wrong

    @ViewBuilder
    private var gotWrongContent: some View {
        if topicGroups.isEmpty {
            emptyBucket(icon: "checkmark.circle", text: "Nothing wrong yet — keep playing and misses will show here.")
        } else {
            Text("Grouped by topic. Tap a topic to see each miss and where it came from.")
                .font(.caption2).foregroundStyle(.secondary)
            ForEach(topicGroups) { group in
                topicCard(group)
            }
        }
    }

    private func topicCard(_ group: TopicGroup) -> some View {
        let expanded = expandedTopics.contains(group.topic)
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expanded { expandedTopics.remove(group.topic) } else { expandedTopics.insert(group.topic) }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(group.topic.capitalized)
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Spacer()
                    Text("\(group.total)")
                        .font(.caption.weight(.bold)).foregroundStyle(.orange)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color.orange.opacity(0.12)))
                    Image(systemName: "chevron.down").font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary).rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .contentShape(Rectangle())
                .padding(12)
            }
            .buttonStyle(.plain)

            if expanded {
                Divider().padding(.horizontal, 12)
                VStack(spacing: 0) {
                    ForEach(Array(group.itemRows.enumerated()), id: \.element.id) { i, row in
                        itemRowView(row)
                        if i < group.itemRows.count - 1 { Divider().padding(.leading, 12) }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func itemRowView(_ row: ItemRow) -> some View {
        Button {
            selectedCondition = ConditionRef(name: row.name)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(row.name).font(.subheadline).foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        if row.count > 1 {
                            Text("×\(row.count)").font(.caption2.weight(.bold)).foregroundStyle(.orange)
                        }
                    }
                    // Source badges — exactly where this miss came from.
                    FlowLayout(spacing: 6) {
                        ForEach(row.sources, id: \.self) { src in
                            Label(src.displayName, systemImage: src.icon)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(Capsule().fill(Color.secondary.opacity(0.12)))
                        }
                    }
                    if !row.detail.isEmpty {
                        Text(row.detail).font(.caption2).foregroundStyle(.red)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "book.closed.fill").font(.caption2).foregroundStyle(.blue.opacity(0.6))
                    .padding(.top, 2)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: Practiced

    @ViewBuilder
    private var practicedContent: some View {
        if workedGroups.isEmpty {
            emptyBucket(icon: "stethoscope", text: "Presentations you build a differential for will show here so you can revisit them.")
        } else {
            Text("Presentations you worked through in the Differential Builder. Tap to reopen your saved differential.")
                .font(.caption2).foregroundStyle(.secondary)
            VStack(spacing: 0) {
                ForEach(Array(workedGroups.enumerated()), id: \.element.id) { i, group in
                    Button {
                        open(group.latest)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "stethoscope").font(.caption).foregroundStyle(.blue).frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.complaint.isEmpty ? "Presentation" : group.complaint.capitalized)
                                    .font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                if !group.system.isEmpty {
                                    Text(group.system.capitalized).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if group.count > 1 {
                                Text("×\(group.count)").font(.caption.weight(.bold)).foregroundStyle(.blue)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Capsule().fill(Color.blue.opacity(0.12)))
                            }
                            Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 10).padding(.horizontal, 12)
                    }
                    .buttonStyle(.plain)
                    if i < workedGroups.count - 1 { Divider().padding(.leading, 44) }
                }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func open(_ session: DDxSession) {
        guard let result = session.result else { return }
        selectedSnapshot = DDxSnapshot(id: session.id, findings: session.findings,
                                       context: session.context, result: result)
    }

    // MARK: Empty states

    private func emptyBucket(icon: String, text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 36)).foregroundStyle(.secondary)
            Text(text).font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity).padding(.top, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 54))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
            Text("No weak spots yet")
                .font(.system(.headline, design: .rounded))
            Text("As you play, anything you miss across cases and game modes — plus every presentation you build a differential for — shows up here so you can review it.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Grouping models

private struct TopicGroup: Identifiable {
    let topic: String
    let items: [MissedItem]
    var id: String { topic }
    var total: Int { items.count }

    /// Distinct missed items within the topic, each with its count + sources.
    var itemRows: [ItemRow] {
        Dictionary(grouping: items, by: { $0.item })
            .map { name, group in
                let sources = Array(Set(group.compactMap { $0.sourceKind })).sorted { $0.displayName < $1.displayName }
                let detail = group.compactMap { $0.detail.isEmpty ? nil : $0.detail }.first ?? ""
                return ItemRow(name: name, count: group.count, sources: sources,
                               lastSeen: group.map(\.timestamp).max() ?? .distantPast, detail: detail)
            }
            .sorted { $0.count == $1.count ? $0.lastSeen > $1.lastSeen : $0.count > $1.count }
    }
}

private struct ItemRow: Identifiable {
    let name: String
    let count: Int
    let sources: [MissSource]
    let lastSeen: Date
    let detail: String
    var id: String { name }
}

private struct WorkedGroup: Identifiable {
    let complaint: String
    let system: String
    let count: Int
    let latest: DDxSession
    var id: String { complaint.lowercased() }
}

/// Wrapper so a condition name can drive a `.sheet(item:)`.
struct ConditionRef: Identifiable {
    let id = UUID()
    let name: String
}

#Preview {
    WeakSpotsView()
}
