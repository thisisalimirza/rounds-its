//
//  DifferentialDiagnosisView.swift
//  Rounds
//
//  Fast bedside differential: pick a complaint, tap the findings that are
//  present, and get a ranked differential with supporting / refuting features
//  for each — ready to present and to write up an A&P.
//

import SwiftUI
import UIKit

struct DifferentialDiagnosisView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var presentation: DDxPresentation? = nil
    @State private var selected: Set<String> = []
    @State private var showApproach = false
    @State private var showAlsoConsider = false
    @State private var showCopied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    complaintPicker

                    if let p = presentation {
                        approachDisclosure(p)
                        findingsSection(p)
                        differentialSection(p)
                    } else {
                        emptyPrompt
                    }
                }
                .padding()
                .padding(.bottom, 24)
            }
            .background(
                LinearGradient(colors: [Color.blue.opacity(0.06), Color.purple.opacity(0.06)],
                               startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            )
            .navigationTitle("Differential Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } }
            }
            .overlay(alignment: .bottom) { copiedToast }
        }
    }

    // MARK: - Complaint picker

    private var complaintPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PRESENTING COMPLAINT")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DifferentialLibrary.all) { p in
                        let isSel = presentation?.id == p.id
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                presentation = p
                                selected.removeAll()
                                showAlsoConsider = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: p.icon).font(.caption)
                                Text(p.complaint).font(.subheadline.weight(.semibold))
                            }
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(
                                isSel ? AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                                      : AnyShapeStyle(Color(.secondarySystemBackground)),
                                in: Capsule()
                            )
                            .foregroundStyle(isSel ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var emptyPrompt: some View {
        VStack(spacing: 10) {
            Image(systemName: "stethoscope.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
            Text("Pick a presenting complaint to start")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Approach (collapsible, out of the way)

    private func approachDisclosure(_ p: DDxPresentation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showApproach.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill").font(.caption).foregroundStyle(.blue)
                    Text("How to approach \(p.complaint.lowercased())")
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.down").font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary).rotationEffect(.degrees(showApproach ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if showApproach {
                Text(p.approach).font(.footnote).foregroundStyle(.secondary)
                    .padding(.top, 8).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Findings chips

    private func findingsSection(_ p: DDxPresentation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("FINDINGS PRESENT")
                    .font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                Spacer()
                if !selected.isEmpty {
                    Button("Clear") { withAnimation { selected.removeAll() } }
                        .font(.caption)
                }
            }
            FlowLayout(spacing: 8) {
                ForEach(p.findings) { f in
                    Chip(label: f.label, selected: selected.contains(f.id)) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if selected.contains(f.id) { selected.remove(f.id) } else { selected.insert(f.id) }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Differential

    private func differentialSection(_ p: DDxPresentation) -> some View {
        let ranked = p.ranked(selected: selected)
        let hasInput = !selected.isEmpty
        let leading = hasInput ? ranked.filter { p.score($0, selected: selected) >= 1 } : ranked
        let alsoConsider = hasInput ? ranked.filter { p.score($0, selected: selected) < 1 } : []

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(hasInput ? "LEADING DIFFERENTIAL" : "DIFFERENTIAL")
                    .font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                Spacer()
                if hasInput && !leading.isEmpty {
                    Button {
                        copyToNote(p, ordered: leading + alsoConsider)
                    } label: {
                        Label("Copy for note", systemImage: "doc.on.doc")
                            .font(.caption.weight(.semibold))
                    }
                }
            }

            if leading.isEmpty {
                Text("Add findings above to build the differential.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                ForEach(Array(leading.enumerated()), id: \.element.id) { index, dx in
                    DiagnosisCard(presentation: p, dx: dx, selected: selected, rank: index + 1, emphasized: index == 0)
                }
            }

            if !alsoConsider.isEmpty {
                Button {
                    withAnimation { showAlsoConsider.toggle() }
                } label: {
                    HStack {
                        Text("Also consider (\(alsoConsider.count))")
                            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        Image(systemName: "chevron.down").font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary).rotationEffect(.degrees(showAlsoConsider ? 180 : 0))
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if showAlsoConsider {
                    ForEach(alsoConsider) { dx in
                        DiagnosisCard(presentation: p, dx: dx, selected: selected, rank: nil, emphasized: false)
                    }
                }
            }

            Text(DifferentialLibrary.disclaimer)
                .font(.caption2).foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 4)
        }
    }

    // MARK: - Copy for A&P

    private func copyToNote(_ p: DDxPresentation, ordered: [DDxDiagnosis]) {
        var lines: [String] = []
        lines.append("Chief complaint: \(p.complaint)")
        let findings = p.findings.filter { selected.contains($0.id) }.map(\.label)
        if !findings.isEmpty { lines.append("Findings: " + findings.joined(separator: "; ")) }
        lines.append("")
        lines.append("Differential:")
        for (i, dx) in ordered.enumerated() {
            let cm = dx.isCantMiss ? " (can't-miss)" : ""
            lines.append("\(i + 1). \(dx.name)\(cm)")
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
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
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
    private var matchedAgainst: [String] { dx.against.filter { selected.contains($0) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    if let rank {
                        Text("\(rank)")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
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

            // Matched supporting findings (the headline "why")
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
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(emphasized ? Color.blue.opacity(0.06) : Color(.secondarySystemBackground))
        )
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
                            .font(.caption)
                            .fontWeight(present ? .semibold : .regular)
                            .foregroundStyle(present ? .primary : .secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Chip

private struct Chip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(
                    selected ? AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                             : AnyShapeStyle(Color(.secondarySystemBackground)),
                    in: Capsule()
                )
                .foregroundStyle(selected ? .white : .primary)
                .overlay(Capsule().stroke(Color.blue.opacity(selected ? 0 : 0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
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
            if x + size.width > maxWidth && x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
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
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    DifferentialDiagnosisView()
}
