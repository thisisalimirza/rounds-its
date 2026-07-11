//
//  ConnectionsGameView.swift
//  Rounds
//
//  "Case Connections" — group 16 tiles into 4 clinical concepts.
//

import SwiftUI

struct ConnectionsGameView: View {
    @Environment(\.dismiss) private var dismiss

    private var subscription: SubscriptionManager { SubscriptionManager.shared }

    @State private var selectedSpecialty: String?
    @State private var game: ConnectionsGame?
    @State private var message = ""
    @State private var showingPaywall = false
    @State private var showConfetti = false
    @State private var shakeTrigger = 0

    // Group colors (yellow / green / blue / purple), revealed when solved.
    static let palette: [Color] = [
        Color(red: 0.97, green: 0.85, blue: 0.42),
        Color(red: 0.63, green: 0.77, blue: 0.35),
        Color(red: 0.42, green: 0.68, blue: 0.90),
        Color(red: 0.73, green: 0.51, blue: 0.77),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if let game {
                    gameBoard(game)
                } else {
                    specialtyPicker
                }

                ConfettiView(isActive: $showConfetti)
            }
            .navigationTitle("Case Connections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if game != nil {
                        Button {
                            game = nil
                            selectedSpecialty = nil
                            message = ""
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                RoundsPaywallView()
            }
        }
    }

    // MARK: - Specialty picker

    private var specialtyPicker: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
                        )
                    Text("Find four groups of four")
                        .font(.system(.headline, design: .rounded))
                    Text("Group the clinical concepts. Four mistakes allowed.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)

                if !subscription.isProUser {
                    Text(ConnectionsAccess.playedToday()
                         ? "You've used today's free puzzle — go Pro for unlimited."
                         : "One free puzzle today. Pro unlocks unlimited.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(ConnectionsData.playableSpecialties, id: \.self) { specialty in
                        Button {
                            start(specialty: specialty)
                        } label: {
                            Text(specialty.capitalized)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, minHeight: 64)
                                .padding(.horizontal, 8)
                                .multilineTextAlignment(.center)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)

                Text("Inspired by Clerkship Connections by Michael Yao · MIT")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Game board

    @ViewBuilder
    private func gameBoard(_ game: ConnectionsGame) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Solved group bands
                ForEach(game.solvedGroupIndices, id: \.self) { idx in
                    if let group = game.group(at: idx) {
                        solvedBand(group)
                    }
                }

                // Remaining tiles
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(game.boardTiles) { tile in
                        tileView(tile, game: game)
                    }
                }
                .padding(.horizontal, 16)

                if !message.isEmpty {
                    Text(message)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                mistakesRow(game)

                if game.isOver {
                    resultControls(game)
                } else {
                    liveControls(game)
                }
            }
            .padding(.vertical, 16)
        }
    }

    private func solvedBand(_ group: ConnectionsGame.PuzzleGroup) -> some View {
        VStack(spacing: 2) {
            Text(group.concept)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
            Text(group.elements.joined(separator: " · "))
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.black.opacity(0.85))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Self.palette[group.colorIndex], in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .transition(.scale.combined(with: .opacity))
    }

    private func tileView(_ tile: ConnectionsGame.Tile, game: ConnectionsGame) -> some View {
        let isSelected = game.isSelected(tile.id)
        return Text(tile.text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.7)
            .lineLimit(3)
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity, minHeight: 68)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(Material.ultraThin))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.blue.opacity(isSelected ? 0 : 0.12), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 0.96 : 1)
            .modifier(ShakeEffect(animatableData: CGFloat(shakeTrigger)))
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                game.toggle(tile.id)
            }
    }

    private func mistakesRow(_ game: ConnectionsGame) -> some View {
        HStack(spacing: 8) {
            Text("Mistakes")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(0..<game.maxMistakes, id: \.self) { i in
                Circle()
                    .fill(i < game.mistakes ? Color.red.opacity(0.8) : Color.secondary.opacity(0.25))
                    .frame(width: 10, height: 10)
            }
        }
    }

    private func liveControls(_ game: ConnectionsGame) -> some View {
        HStack(spacing: 12) {
            Button("Shuffle") { withAnimation { game.shuffleBoard() } }
                .buttonStyle(.bordered)

            Button("Deselect") { game.deselectAll() }
                .buttonStyle(.bordered)
                .disabled(game.selected.isEmpty)

            Button("Submit") { submit(game) }
                .buttonStyle(.borderedProminent)
                .disabled(!game.canSubmit)
        }
        .font(.system(.subheadline, design: .rounded))
        .padding(.top, 4)
    }

    private func resultControls(_ game: ConnectionsGame) -> some View {
        VStack(spacing: 12) {
            Text(game.didWin ? "🎉 Solved it!" : "Out of guesses — answers revealed")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(game.didWin ? .green : .secondary)

            Button {
                start(specialty: game.specialty)
            } label: {
                Label("New Puzzle", systemImage: "arrow.clockwise")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
        }
        .padding(.top, 4)
    }

    // MARK: - Actions

    private func start(specialty: String) {
        guard ConnectionsAccess.canStartPuzzle() else {
            showingPaywall = true
            return
        }
        ConnectionsAccess.recordPlay()
        selectedSpecialty = specialty
        message = ""
        withAnimation { game = ConnectionsGame(specialty: specialty) }
    }

    private func submit(_ game: ConnectionsGame) {
        let result = game.submit()
        switch result {
        case .win:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { message = "" }
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { showConfetti = false }
        case .solved:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { message = "" }
        case .oneAway:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation { message = "So close — one away…" }
            withAnimation(.default) { shakeTrigger += 1 }
        case .wrong:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation { message = "Not a group — try again" }
            withAnimation(.default) { shakeTrigger += 1 }
        case .loss:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation { message = "" }
        case .ignored:
            break
        }
    }
}

// MARK: - Shake effect

private struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        let travel: CGFloat = 6
        let dx = travel * sin(animatableData * .pi * 4)
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: 0))
    }
}

#Preview {
    ConnectionsGameView()
}
