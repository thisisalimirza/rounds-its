//
//  WhatsNewView.swift
//  Rounds
//
//  A beautiful modal to display new features to users
//

import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    let data: WhatsNewData
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                // App icon or decorative element
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

                Text(data.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Text("Version \(data.version)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)

            // Features list
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(data.features.enumerated()), id: \.element.id) { index, feature in
                        WhatsNewFeatureRow(feature: feature)
                            .opacity(appeared ? 1 : 0)
                            .offset(x: appeared ? 0 : -30)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.1 + 0.3),
                                value: appeared
                            )
                    }
                }
                .padding(.horizontal, 24)
            }

            // Footer
            VStack(spacing: 16) {
                if let footer = data.footer {
                    Text(footer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Dismiss button
                Button {
                    onDismiss()
                    dismiss()
                } label: {
                    Text(data.dismissButtonText ?? "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: appeared)
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - Feature Row

struct WhatsNewFeatureRow: View {
    let feature: WhatsNewFeature

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.15), .purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: feature.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Preview

#Preview {
    WhatsNewView(
        data: WhatsNewData(
            version: "1.3.0",
            lastUpdated: "2025-02-12",
            showToVersionsBelow: "1.3.0",
            title: "What's New in Rounds",
            features: [
                WhatsNewFeature(
                    icon: "trophy.fill",
                    title: "Global Leaderboard",
                    description: "Compete with medical students worldwide! See rankings by school."
                ),
                WhatsNewFeature(
                    icon: "square.and.arrow.up",
                    title: "Challenge Friends",
                    description: "Share cases directly with friends via deep links."
                ),
                WhatsNewFeature(
                    icon: "flame.fill",
                    title: "Streak Freezes",
                    description: "Pro users get weekly streak freezes to protect progress."
                )
            ],
            footer: "Thanks for playing Rounds!",
            dismissButtonText: "Let's Go!"
        ),
        onDismiss: {}
    )
}
