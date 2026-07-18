//
//  IllnessScriptsView.swift
//  Rounds
//
//  The Illness Scripts library: structured, high-yield scripts (Demographics /
//  Diagnostics / Pathophysiology / Treatment) per condition. Scripts are the
//  same for everyone, so they're generated once and cached globally server-side
//  (see the `illness-script` edge function) — cheap to serve.
//
//  Access: your OWN missed conditions are free; the full searchable library is
//  a Pro feature.
//

import SwiftUI
import SwiftData

// MARK: - Library

struct IllnessScriptsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MissedItem.timestamp, order: .reverse) private var misses: [MissedItem]

    @State private var library: [IllnessScriptSummary] = []
    @State private var isLoadingLibrary = false
    @State private var searchText = ""
    @State private var showingPaywall = false

    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }

    /// Distinct conditions the user has gotten wrong (their personal set — free).
    private var myConditions: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for m in misses where (m.sourceKind?.isWrongAnswer ?? true) {
            let name = m.item.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = name.lowercased()
            if !name.isEmpty && !seen.contains(key) { seen.insert(key); result.append(name) }
        }
        return result
    }

    private var filteredMine: [String] {
        searchText.isEmpty ? myConditions
            : myConditions.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    private var filteredLibrary: [IllnessScriptSummary] {
        searchText.isEmpty ? library
            : library.filter { $0.condition.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !filteredMine.isEmpty {
                    Section {
                        ForEach(filteredMine, id: \.self) { condition in
                            NavigationLink {
                                IllnessScriptDetailView(condition: condition, reason: "review")
                            } label: {
                                conditionRow(condition, subtitle: "From your missed cases")
                            }
                        }
                    } header: {
                        Label("Your conditions", systemImage: "target")
                    } footer: {
                        Text("Illness scripts for what you've missed — always free.")
                    }
                }

                librarySection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Illness Scripts")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search conditions")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showingPaywall) { RoundsPaywallView() }
            .task {
                if subscriptionManager.isProUser { await loadLibrary() }
            }
        }
    }

    @ViewBuilder
    private var librarySection: some View {
        if subscriptionManager.isProUser {
            Section {
                // Offer to generate an exact-typed condition not already listed.
                let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !q.isEmpty && !library.contains(where: { $0.condition.localizedCaseInsensitiveCompare(q) == .orderedSame }) {
                    NavigationLink {
                        IllnessScriptDetailView(condition: q, reason: "browse")
                    } label: {
                        Label("Get script for “\(q)”", systemImage: "sparkles")
                            .foregroundStyle(.indigo)
                    }
                }

                if isLoadingLibrary && library.isEmpty {
                    HStack { ProgressView(); Text("Loading library…").foregroundStyle(.secondary) }
                } else if filteredLibrary.isEmpty && searchText.isEmpty {
                    Text("The library fills in as conditions get generated. Search any condition to add one.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(filteredLibrary) { item in
                        NavigationLink {
                            IllnessScriptDetailView(condition: item.condition, reason: "browse")
                        } label: {
                            conditionRow(item.condition, subtitle: item.oneLiner, badge: item.missCount)
                        }
                    }
                }
            } header: {
                Label("Library", systemImage: "books.vertical.fill")
            }
        } else {
            Section {
                Button {
                    showingPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill").font(.title3).foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock the full library").font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                            Text("Search every condition with Rounds Pro").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("PRO").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)))
                    }
                }
            } header: {
                Label("Library", systemImage: "books.vertical.fill")
            }
        }
    }

    private func conditionRow(_ condition: String, subtitle: String?, badge: Int? = nil) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(condition).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            if let badge, badge > 1 {
                Text("\(badge)").font(.caption2.weight(.bold)).foregroundStyle(.orange)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.12)))
            }
        }
    }

    private func loadLibrary() async {
        isLoadingLibrary = true
        defer { isLoadingLibrary = false }
        do { library = try await AccountManager.shared.fetchIllnessLibrary() }
        catch { print("⚠️ fetchIllnessLibrary: \(error.localizedDescription)") }
    }
}

// MARK: - Detail

/// Loads (from the global cache, or generates once) and renders a single script.
struct IllnessScriptDetailView: View {
    let condition: String
    var reason: String = "review"

    private enum Phase: Equatable {
        case loading, ready(IllnessScript), failed(String)
        static func == (l: Phase, r: Phase) -> Bool {
            switch (l, r) {
            case (.loading, .loading): return true
            case let (.failed(a), .failed(b)): return a == b
            case (.ready, .ready): return true
            default: return false
            }
        }
    }

    @State private var phase: Phase = .loading

    var body: some View {
        Group {
            switch phase {
            case .loading: loadingView
            case .ready(let s): scriptView(s)
            case .failed(let m): errorView(m)
            }
        }
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private var displayTitle: String {
        if case .ready(let s) = phase { return s.condition }
        return condition
    }

    private func load() async {
        do {
            let s = try await AccountManager.shared.illnessScript(condition: condition, reason: reason)
            await MainActor.run { withAnimation { phase = .ready(s) } }
        } catch {
            await MainActor.run { withAnimation { phase = .failed(error.localizedDescription) } }
        }
    }

    private func scriptView(_ s: IllnessScript) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if !s.oneLiner.isEmpty {
                    Text(s.oneLiner)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                }
                section("Demographics", icon: "person.2.fill", tint: .blue, items: s.demographics)
                section("Diagnostics", icon: "stethoscope", tint: .teal, items: s.diagnostics)
                section("Pathophysiology", icon: "waveform.path.ecg", tint: .purple, items: s.pathophysiology)
                section("Treatment", icon: "pills.fill", tint: .green, items: s.treatment)

                Text("Educational reference — cross-check with your curriculum and clinical judgment.")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 4)
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                           startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
        )
    }

    @ViewBuilder
    private func section(_ title: String, icon: String, tint: Color, items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon).font(.subheadline.weight(.bold)).foregroundStyle(tint)
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill").font(.system(size: 4)).foregroundStyle(tint).padding(.top, 6)
                        Text(item).font(.subheadline).foregroundStyle(.primary.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.3)
            Text("Loading illness script…")
                .font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 40)).foregroundStyle(.orange)
            Text("Couldn't load this script").font(.system(.headline, design: .rounded))
            Text(message).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            Button("Try again") { phase = .loading; Task { await load() } }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 24).padding(.vertical, 10)
                .background(Capsule().fill(Color(.secondarySystemBackground)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding()
    }
}

/// Sheet wrapper for presenting a single script from contextual entry points
/// (Weak Spots items, Study Plan can't-miss diagnoses).
struct IllnessScriptSheet: View {
    let condition: String
    var reason: String = "review"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            IllnessScriptDetailView(condition: condition, reason: reason)
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

#Preview {
    IllnessScriptsView()
}
