//
//  StudyPlanView.swift
//  Rounds
//
//  The Analytics feature (Pro): turns the student's weak spots into a targeted,
//  teaching-rich study plan via the `study-plan` edge function. Prioritized
//  focus areas, why each is a gap, what to study, and the actual high-yield
//  knowledge for each area.
//

import SwiftUI
import SwiftData

struct StudyPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var misses: [MissedItem]
    @Query private var sessions: [DDxSession]

    private enum Phase: Equatable {
        case idle, loading, ready(StudyPlanResult), failed(String)
        static func == (l: Phase, r: Phase) -> Bool {
            switch (l, r) {
            case (.idle, .idle), (.loading, .loading): return true
            case let (.failed(a), .failed(b)): return a == b
            case (.ready, .ready): return true
            default: return false
            }
        }
    }

    @State private var phase: Phase = .idle
    @State private var showingPaywall = false

    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }

    private var wrongMisses: [MissedItem] { misses.filter { $0.sourceKind?.isWrongAnswer ?? true } }
    private var hasData: Bool { !wrongMisses.isEmpty || !sessions.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color.indigo.opacity(0.08), Color.purple.opacity(0.08)],
                               startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()

                if !subscriptionManager.isProUser {
                    proGate
                } else if !hasData {
                    noData
                } else {
                    switch phase {
                    case .idle, .loading: loadingView
                    case .ready(let plan): planView(plan)
                    case .failed(let msg): errorView(msg)
                    }
                }
            }
            .navigationTitle("Study Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } }
                if subscriptionManager.isProUser, case .ready = phase {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button { Task { await generate() } } label: { Image(systemName: "arrow.clockwise") }
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) { RoundsPaywallView() }
            .task {
                if subscriptionManager.isProUser, hasData, phase == .idle {
                    await generate()
                }
            }
        }
    }

    // MARK: Data → request

    private func generate() async {
        withAnimation { phase = .loading }
        let weakSpots = aggregateWeakSpots()
        let practiced = aggregatePracticed()
        do {
            let result = try await AccountManager.shared.requestStudyPlan(weakSpots: weakSpots, practiced: practiced)
            await MainActor.run { withAnimation { phase = .ready(result) } }
        } catch {
            await MainActor.run { withAnimation { phase = .failed(error.localizedDescription) } }
        }
    }

    private func aggregateWeakSpots() -> [StudyWeakSpot] {
        Dictionary(grouping: wrongMisses, by: { "\($0.topic)||\($0.item)" })
            .compactMap { _, group -> StudyWeakSpot? in
                guard let first = group.first else { return nil }
                let sources = Array(Set(group.compactMap { $0.sourceKind?.displayName }))
                return StudyWeakSpot(topic: first.topic.isEmpty ? "General" : first.topic,
                                     item: first.item, count: group.count, sources: sources)
            }
            .sorted { $0.count > $1.count }
    }

    private func aggregatePracticed() -> [StudyPracticed] {
        Dictionary(grouping: sessions) { $0.chiefComplaint.lowercased() }
            .compactMap { _, group -> StudyPracticed? in
                guard let latest = group.max(by: { $0.timestamp < $1.timestamp }) else { return nil }
                return StudyPracticed(complaint: latest.chiefComplaint, system: latest.system, count: group.count)
            }
    }

    // MARK: States

    private var proGate: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundStyle(LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom))
            Text("Your personal study plan")
                .font(.system(.title3, design: .rounded).weight(.bold))
            Text("Rounds Pro turns everything you've missed into a prioritized study plan — what to focus on, why, and the high-yield knowledge for each weak area.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Button {
                showingPaywall = true
            } label: {
                Label("Unlock with Pro", systemImage: "crown.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Capsule().fill(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32).padding(.top, 8)
        }
        .padding()
    }

    private var noData: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 48)).foregroundStyle(.secondary)
            Text("Not enough to analyze yet").font(.system(.headline, design: .rounded))
            Text("Play a few cases and build some differentials. Once you have weak spots, we'll turn them into a targeted study plan.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }
        .padding()
    }

    private var loadingView: some View {
        VStack(spacing: 18) {
            ProgressView().scaleEffect(1.4)
            Text("Analyzing your weak spots…")
                .font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundStyle(.secondary)
            Text("Building your prioritized study plan.")
                .font(.caption).foregroundStyle(.tertiary)
        }
        .padding(40)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 40)).foregroundStyle(.orange)
            Text("Couldn't build your plan").font(.system(.headline, design: .rounded))
            Text(message).font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
            Button("Try again") { Task { await generate() } }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 24).padding(.vertical, 10)
                .background(Capsule().fill(Color(.secondarySystemBackground)))
        }
        .padding(40)
    }

    private func planView(_ plan: StudyPlanResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(plan.overview)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

                Text("FOCUS AREAS").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                ForEach(plan.focusAreas) { area in
                    focusCard(area)
                }

                if !plan.nextSteps.isEmpty {
                    Text("THIS WEEK").font(.caption2.weight(.bold)).foregroundStyle(.secondary).padding(.top, 4)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(plan.nextSteps.enumerated()), id: \.offset) { i, step in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(i + 1)").font(.caption.weight(.bold)).foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Circle().fill(LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom)))
                                Text(step).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                }

                Text("Personalized study guide generated from your activity. An educational aid — always cross-check with your curriculum.")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 4)
            }
            .padding()
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func focusCard(_ area: StudyFocusArea) -> some View {
        let tint: Color = area.priority == "high" ? .red : (area.priority == "medium" ? .orange : .blue)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(area.area).font(.subheadline.weight(.bold)).fixedSize(horizontal: false, vertical: true)
                Spacer()
                Text(area.priority.capitalized)
                    .font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(tint)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(tint.opacity(0.15)))
            }
            Text(area.why).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)

            if !area.studyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Study").font(.caption2.weight(.bold)).foregroundStyle(tint)
                    ForEach(area.studyPoints, id: \.self) { p in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "circle.fill").font(.system(size: 4)).foregroundStyle(tint).padding(.top, 6)
                            Text(p).font(.caption).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Label("Know this", systemImage: "lightbulb.fill").font(.caption2.weight(.bold)).foregroundStyle(.indigo)
                Text(area.teaching).font(.caption).foregroundStyle(.primary.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(tint.opacity(0.2), lineWidth: 1))
    }
}

#Preview {
    StudyPlanView()
}
