//
//  DifferentialDiagnosisView.swift
//  Rounds
//
//  A guided, rapid-fire "symptom brain dump": pick the complaint, then tap
//  through each finding (Present / Not present) one card at a time — no
//  scrolling. Ends in a ranked differential with pertinent positives and
//  negatives, ready to present and to write an A&P.
//

import SwiftUI
import UIKit

struct DifferentialDiagnosisView: View {
    @Environment(\.dismiss) private var dismiss

    private enum Answer { case present, absent }

    @State private var presentation: DDxPresentation? = nil
    @State private var answers: [String: Answer] = [:]
    @State private var index = 0
    @State private var showResults = false
    @State private var showCopied = false

    private var selected: Set<String> { Set(answers.filter { $0.value == .present }.map(\.key)) }
    private var absent: Set<String> { Set(answers.filter { $0.value == .absent }.map(\.key)) }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.08)],
                               startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()

                if let p = presentation {
                    if showResults { resultsView(p) } else { loggingView(p) }
                } else {
                    complaintGrid
                }
            }
            .navigationTitle("Differential Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
            .overlay(alignment: .bottom) { copiedToast }
        }
    }

    // MARK: - Step 1: pick a complaint

    private var complaintGrid: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("What's the presenting complaint?")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(DifferentialLibrary.all) { p in
                        Button {
                            start(p)
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: p.icon)
                                    .font(.system(size: 30))
                                    .foregroundStyle(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Circle().fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)))
                                Text(p.complaint)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 130)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
    }

    private func start(_ p: DDxPresentation) {
        presentation = p
        answers = [:]
        index = 0
        showResults = false
    }

    // MARK: - Step 2: rapid-fire logging

    private func loggingView(_ p: DDxPresentation) -> some View {
        let finding = p.findings[min(index, p.findings.count - 1)]
        return VStack(spacing: 0) {
            // top bar
            HStack {
                Button {
                    if index > 0 { withAnimation { index -= 1 } } else { presentation = nil }
                } label: {
                    Image(systemName: "chevron.left").font(.headline).foregroundStyle(.secondary)
                        .frame(width: 40, height: 40)
                }
                Spacer()
                Text("\(index + 1) of \(p.findings.count)")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                Button("Differential") { withAnimation { showResults = true } }
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 8)

            ProgressView(value: Double(index), total: Double(p.findings.count))
                .tint(.blue)
                .padding(.horizontal)
                .padding(.top, 4)

            Spacer()

            Text(p.complaint)
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(finding.label)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 6)
                .id(finding.id)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)))

            Spacer()

            HStack(spacing: 14) {
                answerButton(title: "Not present", icon: "xmark", tint: .secondary) { answer(finding.id, .absent) }
                answerButton(title: "Present", icon: "checkmark", tint: .green) { answer(finding.id, .present) }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private func answerButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title2.weight(.bold))
                Text(title).font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .foregroundStyle(tint == .secondary ? Color.secondary : .white)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(tint == .secondary ? AnyShapeStyle(Color(.secondarySystemBackground)) : AnyShapeStyle(tint))
            )
        }
        .buttonStyle(.plain)
    }

    private func answer(_ id: String, _ value: Answer) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        answers[id] = value
        guard let p = presentation else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            if index + 1 >= p.findings.count { showResults = true } else { index += 1 }
        }
    }

    // MARK: - Step 3: results

    private func resultsView(_ p: DDxPresentation) -> some View {
        let ranked = p.ranked(selected: selected)
        let leading = selected.isEmpty ? ranked : ranked.filter { p.score($0, selected: selected) >= 1 }
        let alsoConsider = selected.isEmpty ? [] : ranked.filter { p.score($0, selected: selected) < 1 }

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // header + edit
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.complaint).font(.system(.title3, design: .rounded).weight(.bold))
                        Text("\(selected.count) positive · \(absent.count) negative")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        withAnimation { showResults = false; index = 0 }
                    } label: { Label("Edit", systemImage: "slider.horizontal.3").font(.caption.weight(.semibold)) }
                }

                pertinentSummary

                HStack {
                    Text(selected.isEmpty ? "DIFFERENTIAL" : "LEADING DIFFERENTIAL")
                        .font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        copyToNote(p, ordered: leading + alsoConsider)
                    } label: { Label("Copy for note", systemImage: "doc.on.doc").font(.caption.weight(.semibold)) }
                }

                if leading.isEmpty {
                    Text("No strong differential yet — log more findings.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else {
                    ForEach(Array(leading.enumerated()), id: \.element.id) { i, dx in
                        DiagnosisCard(presentation: p, dx: dx, selected: selected, rank: i + 1, emphasized: i == 0)
                    }
                }

                if !alsoConsider.isEmpty {
                    Text("ALSO CONSIDER").font(.caption2.weight(.bold)).foregroundStyle(.secondary).padding(.top, 4)
                    ForEach(alsoConsider) { dx in
                        DiagnosisCard(presentation: p, dx: dx, selected: selected, rank: nil, emphasized: false)
                    }
                }

                Text(DifferentialLibrary.disclaimer)
                    .font(.caption2).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 4)
            }
            .padding()
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private var pertinentSummary: some View {
        if let p = presentation, (!selected.isEmpty || !absent.isEmpty) {
            VStack(alignment: .leading, spacing: 8) {
                if !selected.isEmpty {
                    chipRow(title: "Positives", ids: p.findings.map(\.id).filter { selected.contains($0) }, tint: .green, p: p)
                }
                if !absent.isEmpty {
                    chipRow(title: "Negatives", ids: p.findings.map(\.id).filter { absent.contains($0) }, tint: .secondary, p: p)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func chipRow(title: String, ids: [String], tint: Color, p: DDxPresentation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(.caption2.weight(.bold)).foregroundStyle(tint == .secondary ? .secondary : tint)
            FlowLayout(spacing: 6) {
                ForEach(ids, id: \.self) { id in
                    Text(p.label(for: id))
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(tint == .secondary ? Color.secondary.opacity(0.12) : tint.opacity(0.15)))
                        .foregroundStyle(tint == .secondary ? .secondary : tint)
                }
            }
        }
    }

    // MARK: - Copy for A&P

    private func copyToNote(_ p: DDxPresentation, ordered: [DDxDiagnosis]) {
        var lines: [String] = ["Chief complaint: \(p.complaint)"]
        let pos = p.findings.filter { selected.contains($0.id) }.map(\.label)
        let neg = p.findings.filter { absent.contains($0.id) }.map(\.label)
        if !pos.isEmpty { lines.append("Pertinent positives: " + pos.joined(separator: "; ")) }
        if !neg.isEmpty { lines.append("Pertinent negatives: " + neg.joined(separator: "; ")) }
        lines.append("")
        lines.append("Differential:")
        for (i, dx) in ordered.enumerated() {
            lines.append("\(i + 1). \(dx.name)\(dx.isCantMiss ? " (can't-miss)" : "")")
            let sup = dx.supports.filter { selected.contains($0) }.map { p.label(for: $0) }
            let ag = dx.against.filter { selected.contains($0) }.map { p.label(for: $0) }
            if !sup.isEmpty { lines.append("   Supports: " + sup.joined(separator: ", ")) }
            if !ag.isEmpty { lines.append("   Against: " + ag.joined(separator: ", ")) }
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
}

// MARK: - Diagnosis card

private struct DiagnosisCard: View {
    let presentation: DDxPresentation
    let dx: DDxDiagnosis
    let selected: Set<String>
    let rank: Int?
    let emphasized: Bool

    @State private var expanded = false
    private var matchedSupports: [String] { dx.supports.filter { selected.contains($0) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    if let rank {
                        Text("\(rank)")
                            .font(.system(.subheadline, design: .rounded).weight(.bold)).foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)))
                    }
                    Text(dx.name).font(.subheadline.weight(.bold)).foregroundStyle(.primary)
                    if dx.isCantMiss {
                        Text("CAN'T MISS")
                            .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.red))
                    }
                    Spacer()
                    Image(systemName: "chevron.down").font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary).rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !matchedSupports.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(matchedSupports, id: \.self) { id in
                        Text(presentation.label(for: id))
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                            .foregroundStyle(.green)
                    }
                }
            }

            if expanded {
                Divider()
                featureList("Supports", ids: dx.supports, tint: .green)
                featureList("Against", ids: dx.against, tint: .red)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(emphasized ? Color.blue.opacity(0.06) : Color(.secondarySystemBackground)))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(dx.isCantMiss ? Color.red.opacity(0.25) : (emphasized ? Color.blue.opacity(0.2) : Color.clear), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func featureList(_ title: String, ids: [String], tint: Color) -> some View {
        if !ids.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(tint)
                ForEach(ids, id: \.self) { id in
                    let present = selected.contains(id)
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: present ? (tint == .green ? "checkmark" : "xmark") : "circle")
                            .font(.system(size: present ? 9 : 5, weight: .bold))
                            .foregroundStyle(present ? tint : .secondary)
                            .frame(width: 12).padding(.top, 3)
                        Text(presentation.label(for: id))
                            .font(.caption).fontWeight(present ? .semibold : .regular)
                            .foregroundStyle(present ? .primary : .secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Flow layout (wrapping chips)

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
