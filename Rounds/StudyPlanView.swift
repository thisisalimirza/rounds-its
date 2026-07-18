//
//  StudyPlanView.swift
//  Rounds
//
//  The Analytics feature (Pro): a targeted, componentized study plan built from
//  the student's weak spots. Served instantly from a background-refreshed cache
//  (StudyPlanStore) — the user never waits. Structured into small UI pieces
//  (no walls of text), with progressive disclosure per focus area.
//

import SwiftUI
import SwiftData

struct StudyPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var misses: [MissedItem]
    @Query private var sessions: [DDxSession]

    @State private var store = StudyPlanStore.shared
    @State private var expanded: Set<String> = []
    @State private var showingPaywall = false
    @State private var selectedCondition: ConditionRef?

    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    private var hasData: Bool {
        misses.contains { $0.sourceKind?.isWrongAnswer ?? true } || !sessions.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color.indigo.opacity(0.08), Color.purple.opacity(0.08)],
                               startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                content
            }
            .navigationTitle("Study Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } }
                if subscriptionManager.isProUser, store.hasPlan {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button { Task { await store.refreshIfNeeded(context: modelContext, isPro: true, force: true) } } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(store.isRefreshing)
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) { RoundsPaywallView() }
            .sheet(item: $selectedCondition) { ref in
                IllnessScriptSheet(condition: ref.name, reason: "review")
            }
            .task {
                await store.refreshIfNeeded(context: modelContext, isPro: subscriptionManager.isProUser)
                // Expand the top focus area by default so there's immediate signal.
                if let first = store.plan?.focusAreas.first?.id { expanded.insert(first) }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !subscriptionManager.isProUser {
            proGate
        } else if let plan = store.plan {
            planView(plan)
        } else if store.isRefreshing {
            loadingView
        } else if !hasData {
            noData
        } else if let err = store.lastError {
            errorView(err)
        } else {
            loadingView
        }
    }

    // MARK: Plan

    private func planView(_ plan: StudyPlanResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Headline
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "list.bullet.clipboard.fill").foregroundStyle(.indigo).font(.title3)
                    Text(plan.headline)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

                if store.isRefreshing {
                    Label("Updating your plan…", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                Text("FOCUS AREAS").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                ForEach(plan.focusAreas) { area in
                    focusCard(area)
                }

                Text("Built from your activity. An educational aid — always cross-check with your curriculum.")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 4)
            }
            .padding()
            .padding(.bottom, 24)
        }
    }

    private func focusCard(_ area: StudyFocusArea) -> some View {
        let tint = priorityTint(area.priority)
        let isOpen = expanded.contains(area.id)
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isOpen { expanded.remove(area.id) } else { expanded.insert(area.id) }
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(area.area).font(.subheadline.weight(.bold)).foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 6)
                        Text(area.priority.capitalized)
                            .font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(tint)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(tint.opacity(0.15)))
                        Image(systemName: "chevron.down").font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary).rotationEffect(.degrees(isOpen ? 180 : 0))
                    }
                    Text(area.summary).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .contentShape(Rectangle())
                .padding(12)
            }
            .buttonStyle(.plain)

            if isOpen {
                Divider().padding(.horizontal, 12)
                VStack(alignment: .leading, spacing: 12) {
                    bulletSection("Know this", icon: "lightbulb.fill", tint: .indigo, items: area.keyFacts)
                    if !area.cantMiss.isEmpty {
                        bulletSection("Can't miss", icon: "exclamationmark.triangle.fill", tint: .red, items: area.cantMiss, tappable: true)
                    }
                    if !area.review.isEmpty {
                        bulletSection("Review", icon: "book.fill", tint: tint, items: area.review)
                    }
                    // Future: per-area practice questions render here.
                }
                .padding(12)
            }
        }
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(tint.opacity(0.18), lineWidth: 1))
    }

    private func bulletSection(_ title: String, icon: String, tint: Color, items: [String], tappable: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: icon).font(.caption2.weight(.bold)).foregroundStyle(tint)
            ForEach(items, id: \.self) { item in
                if tappable {
                    Button {
                        selectedCondition = ConditionRef(name: item)
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill").font(.system(size: 4)).foregroundStyle(tint).padding(.top, 6)
                            Text(item).font(.caption).foregroundStyle(.primary.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 4)
                            Image(systemName: "book.closed.fill").font(.system(size: 9)).foregroundStyle(tint.opacity(0.7))
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill").font(.system(size: 4)).foregroundStyle(tint).padding(.top, 6)
                        Text(item).font(.caption).foregroundStyle(.primary.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func priorityTint(_ p: String) -> Color {
        p == "high" ? .red : (p == "medium" ? .orange : .blue)
    }

    // MARK: States

    private var proGate: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard.fill")
                .font(.system(size: 52))
                .foregroundStyle(LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom))
            Text("Your personal study plan")
                .font(.system(.title3, design: .rounded).weight(.bold))
            Text("Rounds Pro turns everything you've missed into a prioritized study plan — what to focus on, why, and the high-yield knowledge for each weak area.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Button { showingPaywall = true } label: {
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
            Text("Not enough data yet").font(.system(.headline, design: .rounded))
            Text("Play a few cases and build some differentials. Your study plan builds itself in the background as you go.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }
        .padding()
    }

    private var loadingView: some View {
        VStack(spacing: 18) {
            ProgressView().scaleEffect(1.4)
            Text("Building your study plan…")
                .font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundStyle(.secondary)
        }
        .padding(40)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 40)).foregroundStyle(.orange)
            Text("Couldn't build your plan").font(.system(.headline, design: .rounded))
            Text(message).font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
            Button("Try again") { Task { await store.refreshIfNeeded(context: modelContext, isPro: true, force: true) } }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 24).padding(.vertical, 10)
                .background(Capsule().fill(Color(.secondarySystemBackground)))
        }
        .padding(40)
    }
}

#Preview {
    StudyPlanView()
}
