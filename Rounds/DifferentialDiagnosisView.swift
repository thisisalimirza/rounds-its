//
//  DifferentialDiagnosisView.swift
//  Rounds
//
//  Free-text differential builder. The student types the symptoms, signs, and
//  findings they gathered on a patient; we send that to the `ddx` Supabase edge
//  function, which calls Claude (key server-side) and returns a structured
//  differential. Each diagnosis shows what the student's findings support and
//  the concrete next steps to confirm it — so they know how to move forward.
//

import SwiftUI
import SwiftData
import UIKit

/// A lightweight, restorable snapshot of a past builder session — decouples the
/// view from SwiftData so it can be handed in via a sheet.
struct DDxSnapshot: Identifiable {
    let id: UUID
    let findings: String
    let context: String
    let result: DifferentialResult
}

struct DifferentialDiagnosisView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// When set, the view opens showing this saved differential (pulled back
    /// from Weak Spots) instead of the empty input screen.
    let restore: DDxSnapshot?
    @State private var didRestore = false

    init(restore: DDxSnapshot? = nil) {
        self.restore = restore
    }

    private enum Phase: Equatable {
        case input
        case loading
        case result(DifferentialResult)
        case failed(String)

        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.input, .input), (.loading, .loading): return true
            case let (.failed(a), .failed(b)): return a == b
            case (.result, .result): return true
            default: return false
            }
        }
    }

    @State private var findings = ""
    @State private var patientContext = ""
    @State private var phase: Phase = .input
    @State private var showCopied = false
    @State private var showingPaywall = false
    @FocusState private var findingsFocused: Bool

    private var isPro: Bool { SubscriptionManager.shared.isProUser }
    private var freeUsesRemaining: Int { DifferentialAccessManager.shared.freeUsesRemaining }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.08)],
                               startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()

                switch phase {
                case .input:            inputView
                case .loading:          loadingView
                case .result(let r):    resultsView(r)
                case .failed(let msg):  errorView(msg)
                }
            }
            .navigationTitle("Differential Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } }
                if case .input = phase {
                    ToolbarItem(placement: .keyboard) {
                        HStack { Spacer(); Button("Done") { findingsFocused = false } }
                    }
                }
            }
            .overlay(alignment: .bottom) { copiedToast }
            .onAppear(perform: restoreIfNeeded)
            .sheet(isPresented: $showingPaywall) { RoundsPaywallView() }
        }
    }

    private func restoreIfNeeded() {
        guard let snapshot = restore, !didRestore else { return }
        didRestore = true
        findings = snapshot.findings
        patientContext = snapshot.context
        phase = .result(snapshot.result)
    }

    // MARK: - Step 1: free-text input

    private var inputView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("What did you find?")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Text("Type the symptoms, signs, and findings from your patient — however you'd say it out loud. We'll build the differential.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("FINDINGS").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                    ZStack(alignment: .topLeading) {
                        if findings.isEmpty {
                            Text("e.g. 58M, sudden crushing chest pain radiating to left arm, diaphoretic, worse on exertion, hx smoking and HTN…")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 16)
                        }
                        TextEditor(text: $findings)
                            .font(.subheadline)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 170)
                            .padding(8)
                            .focused($findingsFocused)
                    }
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("PATIENT CONTEXT").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                        Text("OPTIONAL")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.15)))
                    }
                    TextField("Age, sex, key past medical history", text: $patientContext, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(1...3)
                        .padding(12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    build()
                } label: {
                    Text("Build differential")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Capsule().fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)))
                }
                .buttonStyle(.plain)
                .disabled(findings.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(findings.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                if !isPro {
                    Text(freeUsesRemaining > 0
                         ? "\(freeUsesRemaining) free build\(freeUsesRemaining == 1 ? "" : "s") left"
                         : "You've used your free builds — upgrade to Pro to keep going")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }

                Text(disclaimer)
                    .font(.caption2).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center)
            }
            .padding()
            .padding(.bottom, 24)
        }
    }

    private func build() {
        let isPro = SubscriptionManager.shared.isProUser
        // Free trial: a handful of builds, then Pro. Guard here too so an
        // Edit→rebuild inside an already-open session can't exceed the trial.
        guard DifferentialAccessManager.shared.canUse(isPro: isPro) else {
            showingPaywall = true
            return
        }
        findingsFocused = false
        let f = findings
        let c = patientContext
        withAnimation { phase = .loading }
        Task {
            do {
                let result = try await AccountManager.shared.requestDifferential(findings: f, context: c)
                await MainActor.run {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    // Consume a free build (no-op for Pro).
                    DifferentialAccessManager.shared.recordUse(isPro: isPro)
                    // Save the full session in the background so it can be pulled
                    // back later from Weak Spots.
                    modelContext.insert(DDxSession(findings: f, context: c, result: result))
                    // Reaching for the builder means the student was shaky on this
                    // presentation — log it as a focus area (one entry per build,
                    // keyed to the complaint, not each diagnosis).
                    MistakeLog.record(modelContext, source: .ddxBuilder,
                                      topic: result.system, item: result.chiefComplaint)
                    // A completed differential is a "just did something useful"
                    // moment — a good, non-intrusive time to consider a review ask.
                    AppStoreReviewManager.shared.differentialBuilt()
                    withAnimation { phase = .result(result) }
                }
            } catch {
                await MainActor.run {
                    withAnimation { phase = .failed(error.localizedDescription) }
                }
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 18) {
            ProgressView().scaleEffect(1.4)
            Text("Reasoning through the differential…")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Weighing what your findings support and what to check next.")
                .font(.caption).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40)).foregroundStyle(.orange)
            Text("Couldn't build the differential")
                .font(.system(.headline, design: .rounded))
            Text(message)
                .font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
            Button("Try again") { withAnimation { phase = .input } }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 24).padding(.vertical, 10)
                .background(Capsule().fill(Color(.secondarySystemBackground)))
        }
        .padding(40)
    }

    // MARK: - Step 2: results

    private func resultsView(_ r: DifferentialResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Summary + edit
                HStack(alignment: .top, spacing: 8) {
                    Text(r.summary)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        withAnimation { phase = .input }
                    } label: {
                        Label("Edit", systemImage: "pencil").font(.caption.weight(.semibold)).labelStyle(.iconOnly)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color(.tertiarySystemBackground)))
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

                if !r.redFlags.isEmpty {
                    redFlagBanner(r.redFlags)
                }

                HStack {
                    Text("\(r.differential.count) DIAGNOSES").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        copyToNote(r)
                    } label: { Label("Copy for note", systemImage: "doc.on.doc").font(.caption.weight(.semibold)) }
                }
                .padding(.top, 2)

                ForEach(Array(r.differential.enumerated()), id: \.element.id) { i, dx in
                    DiagnosisCard(dx: dx, rank: i + 1, startExpanded: i == 0)
                }

                Button {
                    withAnimation { phase = .input }
                } label: {
                    Label("New patient", systemImage: "arrow.counterclockwise")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(Capsule().fill(Color(.secondarySystemBackground)))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                Text(disclaimer)
                    .font(.caption2).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 4)
            }
            .padding()
            .padding(.bottom, 24)
        }
    }

    private func redFlagBanner(_ flags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Red flags — escalate if present", systemImage: "exclamationmark.octagon.fill")
                .font(.caption.weight(.bold)).foregroundStyle(.red)
            ForEach(flags, id: \.self) { flag in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill").font(.system(size: 4)).foregroundStyle(.red).padding(.top, 6)
                    Text(flag).font(.caption).foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.22), lineWidth: 1))
    }

    // MARK: - Copy for A&P

    private func copyToNote(_ r: DifferentialResult) {
        var lines: [String] = []
        lines.append("Summary: \(r.summary)")
        lines.append("")
        lines.append("Differential:")
        for (i, dx) in r.differential.enumerated() {
            lines.append("\(i + 1). \(dx.diagnosis)\(dx.cantMiss ? " (can't-miss)" : "") — \(dx.likelihood) likelihood")
            if !dx.supporting.isEmpty { lines.append("   Supported by: " + dx.supporting.joined(separator: "; ")) }
            if !dx.toConfirm.isEmpty { lines.append("   To confirm: " + dx.toConfirm.joined(separator: "; ")) }
        }
        if !r.redFlags.isEmpty {
            lines.append("")
            lines.append("Red flags: " + r.redFlags.joined(separator: "; "))
        }
        UIPasteboard.general.string = lines.joined(separator: "\n")
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { showCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { withAnimation { showCopied = false } }
    }

    @ViewBuilder
    private var copiedToast: some View {
        if showCopied {
            Label("Copied for your note", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Capsule().fill(Color.green))
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private let disclaimer = "Educational study aid — automatically generated and may be incomplete or wrong. Not a diagnostic device. Always use clinical judgment and supervision."
}

// MARK: - Diagnosis card

private struct DiagnosisCard: View {
    let dx: DifferentialDx
    let rank: Int
    let startExpanded: Bool

    @State private var expanded: Bool

    init(dx: DifferentialDx, rank: Int, startExpanded: Bool) {
        self.dx = dx
        self.rank = rank
        self.startExpanded = startExpanded
        _expanded = State(initialValue: startExpanded)
    }

    private var likelihoodTint: Color {
        switch dx.likelihood.lowercased() {
        case "high":     return .blue
        case "moderate": return .orange
        default:         return .secondary
        }
    }

    private var collapsedSubtitle: String {
        var parts: [String] = []
        if !dx.supporting.isEmpty { parts.append("\(dx.supporting.count) supporting") }
        if !dx.toConfirm.isEmpty { parts.append("\(dx.toConfirm.count) to confirm") }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Text("\(rank)")
                        .font(.system(.subheadline, design: .rounded).weight(.bold)).foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(dx.diagnosis)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 6) {
                            Text(dx.likelihood.capitalized)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(likelihoodTint)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(likelihoodTint.opacity(0.15)))
                            if dx.cantMiss {
                                Label("CAN'T MISS", systemImage: "exclamationmark.triangle.fill")
                                    .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.white)
                                    .padding(.horizontal, 7).padding(.vertical, 3)
                                    .background(Capsule().fill(Color.red))
                            }
                            if !expanded && !collapsedSubtitle.isEmpty {
                                Text(collapsedSubtitle)
                                    .font(.caption2).foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    Image(systemName: "chevron.down").font(.caption.weight(.bold))
                        .foregroundStyle(.secondary).rotationEffect(.degrees(expanded ? 180 : 0))
                        .padding(.top, 6)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                if !dx.rationale.isEmpty {
                    Text(dx.rationale)
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !dx.supporting.isEmpty {
                    section(title: "Supported by your findings", icon: "checkmark.seal.fill", tint: .green,
                            items: dx.supporting, bullet: "checkmark")
                }

                if !dx.toConfirm.isEmpty {
                    section(title: "To confirm — next steps", icon: "arrow.right.circle.fill", tint: .blue,
                            items: dx.toConfirm, bullet: "arrow.right")
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(rank == 1 ? Color.blue.opacity(0.06) : Color(.secondarySystemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(dx.cantMiss ? Color.red.opacity(0.28) : (rank == 1 ? Color.blue.opacity(0.2) : Color.clear), lineWidth: 1)
        )
    }

    private func section(title: String, icon: String, tint: Color, items: [String], bullet: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.bold)).foregroundStyle(tint)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: bullet).font(.system(size: 10, weight: .bold))
                        .foregroundStyle(tint).frame(width: 14).padding(.top, 2)
                    Text(item).font(.caption).foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Flow layout (wrapping chips) — also used by WeakSpotsView

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(widest, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    DifferentialDiagnosisView()
}
