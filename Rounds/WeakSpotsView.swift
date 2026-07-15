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

    private var topics: [MissAggregate.Bucket] { MissAggregate.byTopic(misses) }
    private var items: [MissAggregate.Bucket] { MissAggregate.byItem(misses) }
    private var sources: [MissAggregate.Bucket] { MissAggregate.bySource(misses) }

    var body: some View {
        NavigationStack {
            Group {
                if misses.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            summaryHeader
                            topicsSection
                            mostMissedSection
                            bySourceSection
                            futureNote
                        }
                        .padding()
                        .padding(.bottom, 24)
                    }
                }
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
            Text("Everything you've missed across cases and games — your personal review list.")
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
                ForEach(Array(items.prefix(10).enumerated()), id: \.element.id) { i, bucket in
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
                    if i < min(items.count, 10) - 1 { Divider().padding(.leading, 12) }
                }
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        }
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
