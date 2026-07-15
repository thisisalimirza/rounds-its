//
//  DifferentialDiagnosisView.swift
//  Rounds
//
//  Pick a complaint, toggle the patient's findings, and watch the differential
//  re-rank — each diagnosis showing what argues for and against it.
//

import SwiftUI

struct DifferentialDiagnosisView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                let items = DifferentialLibrary.filtered(query)
                if items.isEmpty { ContentUnavailableView.search(text: query) }
                Section {
                    ForEach(items) { presentation in
                        NavigationLink {
                            DifferentialDetailView(presentation: presentation)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: presentation.icon)
                                    .font(.title3).foregroundStyle(.blue).frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(presentation.complaint)
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                    Text(presentation.system).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } footer: {
                    Text("Pick a complaint, toggle the patient's findings, and the differential re-ranks.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Differential Builder")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, prompt: "Search a chief complaint")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}

// MARK: - Detail

struct DifferentialDetailView: View {
    let presentation: DDxPresentation

    @State private var selected: Set<String> = []
    @State private var showApproach = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                approachCard
                findingsCard
                differentialSection
                Text(DifferentialLibrary.disclaimer)
                    .font(.caption2).foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center).padding(.top, 4)
            }
            .padding()
        }
        .background(
            LinearGradient(colors: [Color.blue.opacity(0.06), Color.purple.opacity(0.06)],
                           startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
        )
        .navigationTitle(presentation.complaint)
        .navigationBarTitleDisplayMode(.inline)
    }

    // Approach + key questions (collapsible)
    private var approachCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showApproach.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill").foregroundStyle(.blue)
                    Text("How to approach it")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showApproach ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showApproach {
                VStack(alignment: .leading, spacing: 10) {
                    Text(presentation.approach).font(.callout)
                    ForEach(presentation.keyQuestions, id: \.self) { q in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary).padding(.top, 3)
                            Text(q).font(.subheadline)
                        }
                    }
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // Toggle the patient's findings
    private var findingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Patient findings")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                Spacer()
                if !selected.isEmpty {
                    Button("Clear") { withAnimation { selected.removeAll() } }
                        .font(.caption)
                }
            }
            Text("Toggle what's present — the differential updates below.")
                .font(.caption).foregroundStyle(.secondary)

            ForEach(presentation.findings) { finding in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if selected.contains(finding.id) { selected.remove(finding.id) } else { selected.insert(finding.id) }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: selected.contains(finding.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selected.contains(finding.id) ? .blue : .secondary)
                        Text(finding.label).font(.subheadline).foregroundStyle(.primary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // Live-ranked differential
    private var differentialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Differential")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .padding(.horizontal, 4)

            ForEach(presentation.ranked(selected: selected)) { dx in
                diagnosisCard(dx)
            }
        }
    }

    private func diagnosisCard(_ dx: DDxDiagnosis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(dx.name).font(.subheadline.weight(.bold))
                if dx.isCantMiss {
                    Text("CAN'T MISS")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                }
                Spacer()
            }

            featureList(title: "Supports", ids: dx.supports, tint: .green, icon: "plus.circle.fill")
            featureList(title: "Against", ids: dx.against, tint: .red, icon: "minus.circle.fill")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(dx.isCantMiss ? Color.red.opacity(0.25) : Color.clear, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func featureList(title: String, ids: [String], tint: Color, icon: String) -> some View {
        if !ids.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Label(title, systemImage: icon)
                    .font(.caption.weight(.semibold)).foregroundStyle(tint)
                ForEach(ids, id: \.self) { id in
                    let present = selected.contains(id)
                    Text("• \(presentation.label(for: id))")
                        .font(.caption)
                        .fontWeight(present ? .semibold : .regular)
                        .foregroundStyle(present ? .primary : .secondary)
                }
            }
        }
    }
}

#Preview {
    DifferentialDiagnosisView()
}
