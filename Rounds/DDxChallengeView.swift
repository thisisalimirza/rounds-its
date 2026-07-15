//
//  DDxChallengeView.swift
//  Rounds
//
//  "Differential Challenge" — read the case, pick your differential, get scored.
//

import SwiftUI

struct DDxChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var game = DDxChallengeGame()
    @State private var showConfetti = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        header
                        caseCard
                        optionsSection
                        if game.submitted {
                            resultSection
                        } else {
                            submitButton
                        }
                    }
                    .padding()
                }

                ConfettiView(isActive: $showConfetti)
            }
            .navigationTitle("Differential Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    private var header: some View {
        HStack {
            Label("Case \(game.roundNumber)", systemImage: "stethoscope")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(game.totalScore) pts")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(.blue)
        }
    }

    private var caseCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(game.round.presentation.complaint)
                .font(.system(.title3, design: .rounded).weight(.bold))
            Text(game.round.presentation.system)
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            ForEach(game.round.findingIDs, id: \.self) { id in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill").font(.system(size: 5)).foregroundStyle(.blue).padding(.top, 6)
                    Text(game.label(forFinding: id)).font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(game.submitted ? "Results" : "Which diagnoses belong on your differential?")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .padding(.horizontal, 4)
            ForEach(game.round.options) { dx in
                optionRow(dx)
            }
        }
    }

    private func optionRow(_ dx: DDxDiagnosis) -> some View {
        let picked = game.isPicked(dx.id)
        let expected = game.round.expected.contains(dx.id)
        // Status colors only after submit
        let status: (icon: String, tint: Color)? = {
            guard game.submitted else { return nil }
            if expected && picked { return ("checkmark.circle.fill", .green) }
            if expected && !picked { return (dx.isCantMiss ? "exclamationmark.triangle.fill" : "xmark.circle.fill", .red) }
            if !expected && picked { return ("minus.circle.fill", .orange) }
            return nil
        }()

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            game.toggle(dx.id)
        } label: {
            HStack(spacing: 10) {
                if let status {
                    Image(systemName: status.icon).foregroundStyle(status.tint)
                } else {
                    Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(picked ? .blue : .secondary)
                }
                Text(dx.name).font(.subheadline).foregroundStyle(.primary)
                if game.submitted && dx.isCantMiss {
                    Text("CAN'T MISS")
                        .font(.system(size: 9, weight: .bold, design: .rounded)).foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(12)
            .background((status?.tint ?? (picked ? Color.blue : .clear)).opacity(status == nil ? (picked ? 0.10 : 0) : 0.10),
                       in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(game.submitted)
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            Text("Submit differential")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(Capsule().fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)))
        }
        .buttonStyle(.plain)
        .disabled(!game.canSubmit)
        .opacity(game.canSubmit ? 1 : 0.5)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var resultSection: some View {
        if let r = game.result {
            VStack(spacing: 12) {
                if r.safe {
                    Text(r.over.isEmpty && r.missed.isEmpty ? "🎯 Perfect differential!" : "✅ Safe differential")
                        .font(.system(.headline, design: .rounded)).foregroundStyle(.green)
                } else {
                    VStack(spacing: 4) {
                        Text("⚠️ You missed a can't-miss diagnosis")
                            .font(.system(.headline, design: .rounded)).foregroundStyle(.red)
                        Text("Always rule out the dangerous causes first.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text("+\(r.roundScore) pts")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)

                Button {
                    game.nextRound()
                } label: {
                    Label("Next case", systemImage: "arrow.right")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Capsule().fill(Color(.secondarySystemBackground)))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
            }
        }
    }

    private func submit() {
        let r = game.submit()
        if let r {
            if r.safe {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                if r.over.isEmpty && r.missed.isEmpty {
                    showConfetti = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { showConfetti = false }
                }
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
}

#Preview {
    DDxChallengeView()
}
