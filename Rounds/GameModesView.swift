//
//  GameModesView.swift
//  Rounds
//
//  Hub for alternative game modes. Case Connections is live; more coming.
//

import SwiftUI

struct GameModesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingConnections = false
    @State private var showingDDxChallenge = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        GameModeCard(
                            icon: "square.grid.2x2.fill",
                            title: "Case Connections",
                            subtitle: "Group 16 terms into 4 clinical concepts",
                            colors: [.blue, .purple],
                            status: .available
                        ) { showingConnections = true }

                        GameModeCard(
                            icon: "list.bullet.rectangle.portrait.fill",
                            title: "Differential Challenge",
                            subtitle: "Read a case, pick your differential, don't miss the dangerous causes",
                            colors: [.teal, .green],
                            status: .available
                        ) { showingDDxChallenge = true }

                        GameModeCard(
                            icon: "bolt.fill",
                            title: "Rapid Fire",
                            subtitle: "Beat the clock on quick-fire diagnoses",
                            colors: [.orange, .pink],
                            status: .comingSoon
                        )

                        GameModeCard(
                            icon: "testtube.2",
                            title: "Lab Values",
                            subtitle: "Match findings to the right lab panel",
                            colors: [.mint, .cyan],
                            status: .comingSoon
                        )

                        GameModeCard(
                            icon: "photo.stack.fill",
                            title: "Image Rounds",
                            subtitle: "Read the scan, name the diagnosis",
                            colors: [.indigo, .blue],
                            status: .comingSoon
                        )

                        Text("More modes are on the way. Have an idea? Send us feedback!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .padding(.horizontal, 24)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Game Modes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showingConnections) {
                ConnectionsGameView()
            }
            .fullScreenCover(isPresented: $showingDDxChallenge) {
                DDxChallengeView()
            }
        }
    }
}

// MARK: - Game mode card

private struct GameModeCard: View {
    enum Status { case available, comingSoon }

    let icon: String
    let title: String
    let subtitle: String
    let colors: [Color]
    let status: Status
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            if status == .available { action?() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if status == .available {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Text("SOON")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .opacity(status == .available ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(status != .available)
    }
}

#Preview {
    GameModesView()
}
