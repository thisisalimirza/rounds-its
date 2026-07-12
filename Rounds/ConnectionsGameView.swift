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
                    Text("Choose a specialty")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Text("Pick an area to practice, then group 16 terms into 4 clinical concepts. Four mistakes allowed.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
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
                boardHeader(game)

                // Solved (and, on loss, revealed) group bands
                ForEach(game.revealedGroupIndices, id: \.self) { idx in
                    if let group = game.group(at: idx) {
                        solvedBand(group)
                    }
                }

                // Remaining tiles
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(game.boardTiles) { tile in
                        tileView(tile, game: game)
                    }
                }
                .padding(.horizontal, 16)

                if !message.isEmpty {
                    Text(message)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.orange)
                        .transition(.opacity)
                }

                if game.isOver {
                    resultControls(game)
                } else {
                    liveControls(game)
                }
            }
            .padding(.vertical, 16)
        }
    }

    // Progress + mistakes header
    private func boardHeader(_ game: ConnectionsGame) -> some View {
        VStack(spacing: 10) {
            Text(game.specialty.capitalized)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(i < game.solvedGroupIndices.count
                              ? AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                              : AnyShapeStyle(Color.secondary.opacity(0.2)))
                        .frame(width: 40, height: 7)
                }
            }

            HStack(spacing: 6) {
                Text("Mistakes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(0..<game.maxMistakes, id: \.self) { i in
                    Image(systemName: i < game.mistakes ? "heart.slash.fill" : "heart.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(i < game.mistakes ? Color.secondary.opacity(0.3) : Color.pink)
                }
            }
        }
    }

    private func solvedBand(_ group: ConnectionsGame.PuzzleGroup) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.black.opacity(0.65))
            VStack(spacing: 3) {
                Text(group.concept)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                Text(group.elements.joined(separator: " · "))
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(.black.opacity(0.85))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Self.palette[group.colorIndex])
                .shadow(color: Self.palette[group.colorIndex].opacity(0.4), radius: 6, y: 3)
        )
        .padding(.horizontal, 16)
        .transition(.scale.combined(with: .opacity))
    }

    private func tileView(_ tile: ConnectionsGame.Tile, game: ConnectionsGame) -> some View {
        let isSelected = game.isSelected(tile.id)
        return Text(tile.text)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.6)
            .lineLimit(3)
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity, minHeight: 76)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected
                          ? AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(Color(.secondarySystemBackground)))
                    .shadow(color: isSelected ? Color.purple.opacity(0.35) : Color.black.opacity(0.06),
                            radius: isSelected ? 8 : 3, y: isSelected ? 4 : 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.blue.opacity(isSelected ? 0 : 0.10), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.04 : 1)
            .modifier(ShakeEffect(animatableData: CGFloat(shakeTrigger)))
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: isSelected)
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                game.toggle(tile.id)
            }
    }

    private func liveControls(_ game: ConnectionsGame) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation { game.shuffleBoard() }
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color(.secondarySystemBackground)))
            }
            .buttonStyle(.plain)

            Button {
                game.deselectAll()
            } label: {
                Text("Deselect")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Capsule().fill(Color(.secondarySystemBackground)))
            }
            .buttonStyle(.plain)
            .disabled(game.selected.isEmpty)
            .opacity(game.selected.isEmpty ? 0.5 : 1)

            Button {
                submit(game)
            } label: {
                Text("Submit")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        Capsule().fill(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                    )
            }
            .buttonStyle(.plain)
            .disabled(!game.canSubmit)
            .opacity(game.canSubmit ? 1 : 0.5)
        }
        .padding(.horizontal, 24)
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
