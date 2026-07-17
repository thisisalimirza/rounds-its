//
//  WeakSpotsView.swift
//  Rounds
//
//  Elegant view over the universal miss log — the topics and items the user
//  gets wrong most, across every mode. Foundation for tailored study plans.
//

import SwiftUI
import SwiftData

struct WeakSpotsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MissedItem.timestamp, order: .reverse) private var misses: [MissedItem]
    @Query(sort: \DDxSession.timestamp, order: .reverse) private var sessions: [DDxSession]

    @State private var selectedSnapshot: DDxSnapshot?

    // Genuine wrong answers vs. self-flagged uncertainty (Differential Builder use).
    private var wrongMisses: [MissedItem] { misses.filter { $0.sourceKind?.isWrongAnswer ?? true } }

    private var topics: [MissAggregate.Bucket] { MissAggregate.byTopic(misses) }
    private var wrongItems: [MissAggregate.Bucket] { MissAggregate.byItem(wrongMisses) }
    private var sources: [MissAggregate.Bucket] { MissAggregate.bySource(misses) }

    // Saved builder sessions grouped by complaint (latest first), so repeated
    // visits collapse into one tappable row with a count.
    private struct WorkedGroup: Identifiable {
        let id: String
        let complaint: String
        let system: String
        let count: Int
        let latest: DDxSession
    }

    private var workedGroups: [WorkedGroup] {
        Dictionary(grouping: sessions) { $0.chiefComplaint.lowercased() }
            .compactMap { key, items -> WorkedGroup? in
                guard let latest = items.max(by: { $0.timestamp < $1.timestamp }) else { return nil }
                return WorkedGroup(id: key, complaint: latest.chiefComplaint,
                                   system: latest.system, count: items.count, latest: latest)
            }
            .sorted { $0.latest.timestamp > $1.latest.timestamp }
    }

    var body: some View {
        NavigationStack {
            Group {
                if misses.isEmpty && sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            summaryHeader
                            topicsSection
                            if !wrongItems.isEmpty { mostMissedSection }
                            if !workedGroups.isEmpty { workedThroughSection }
                            bySourceSection
                            futureNote
                        }
                        .padding()
                        .padding(.bottom, 24)
                    }
                }
            }
            .sheet(item: $selectedSnapshot) { snapshot in
                DifferentialDiagnosisView(restore: snapshot)
            }
            .background(
                LinearGradient(colors: [Color.blue.opacity(0.06), Color.purple.opacity(0.06)],
                               startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            )
            .navigationTitle("Weak Spots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 54))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
            Text("No weak spots yet")
                .font(.system(.headline, design: .rounded))
            Text("As you play, anything you miss across cases and game modes shows up here so you can review it.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity).padding(.top, 80)
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(misses.count) to review")
                .font(.system(.title2, design: .rounded).weight(.bold))
            Text("Topics you've missed or needed help working through — your personal review list.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TOP TOPICS TO REVIEW").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            let maxCount = topics.first?.count ?? 1
            ForEach(topics.prefix(6)) { bucket in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(bucket.key.capitalized).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(bucket.count)").font(.subheadline.weight(.bold)).foregroundStyle(.blue)
                    }
                    bar(fraction: Double(bucket.count) / Double(max(maxCount, 1)))
                }
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func bar(fraction: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(6, geo.size.width * fraction))
            }
        }
        .frame(height: 8)
    }

    private var mostMissedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MOST-MISSED").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            VStack(spacing: 0) {
                let shown = Array(wrongItems.prefix(10))
                ForEach(Array(shown.enumerated()), id: \.element.id) { i, bucket in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bucket.key).font(.subheadline.weight(.semibold))
                            if let sub = bucket.subtitle {
                                Text(sub.capitalized).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text("×\(bucket.count)")
                            .font(.caption.weight(.bold)).foregroundStyle(.orange)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(Color.orange.opacity(0.12)))
                    }
                    .padding(.vertical, 10).padding(.horizontal, 12)
                    if i < shown.count - 1 { Divider().padding(.leading, 12) }
                }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // Presentations the student built a differential for — a distinct signal
    // from wrong answers: "I needed help reasoning through this." Each row
    // reopens the saved differential for targeted review of the approach.
    private var workedThroughSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PRESENTATIONS YOU WORKED THROUGH").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                Text("Tap to reopen your saved differential and revisit the approach.")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            VStack(spacing: 0) {
                let shown = Array(workedGroups.prefix(12))
                ForEach(Array(shown.enumerated()), id: \.element.id) { i, group in
                    Button {
                        open(group.latest)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "stethoscope")
                                .font(.caption).foregroundStyle(.blue)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.complaint.isEmpty ? "Presentation" : group.complaint.capitalized)
                                    .font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                if !group.system.isEmpty {
                                    Text(group.system.capitalized).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if group.count > 1 {
                                Text("×\(group.count)")
                                    .font(.caption.weight(.bold)).foregroundStyle(.blue)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Capsule().fill(Color.blue.opacity(0.12)))
                            }
                            Image(systemName: "chevron.right").font(.caption2.weight(.bold)).foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 10).padding(.horizontal, 12)
                    }
                    .buttonStyle(.plain)
                    if i < shown.count - 1 { Divider().padding(.leading, 44) }
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

    private var bySourceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BY MODE").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
            FlowLayout(spacing: 8) {
                ForEach(sources) { bucket in
                    HStack(spacing: 6) {
                        Text(bucket.key).font(.caption.weight(.medium))
                        Text("\(bucket.count)").font(.caption.weight(.bold)).foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(Color(.secondarySystemBackground)))
                }
            }
        }
    }

    private var futureNote: some View {
        Label("Personalized study plans from your weak spots are coming soon.", systemImage: "sparkles")
            .font(.caption).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
    }
}

#Preview {
    WeakSpotsView()
}
