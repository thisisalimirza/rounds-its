//
//  LeaderboardRow.swift
//  Rounds
//
//  Individual leaderboard entry row component
//

import SwiftUI

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let showSchool: Bool
    let currentScope: LeaderboardScope

    init(entry: LeaderboardEntry, showSchool: Bool = true, currentScope: LeaderboardScope = .school) {
        self.entry = entry
        self.showSchool = showSchool
        self.currentScope = currentScope
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            rankBadge

            // Player info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(.headline)
                        .fontWeight(entry.isCurrentUser ? .bold : .semibold)
                        .foregroundStyle(entry.isCurrentUser ? .blue : .primary)

                    if entry.isCurrentUser {
                        Text("You")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }

                if showSchool {
                    HStack(spacing: 4) {
                        Text(entry.schoolName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        if currentScope == .national || currentScope == .global {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(entry.state == "INTL" ? entry.country : entry.state)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            // Score and level
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.totalScore.formatted()) pts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(entry.isCurrentUser ? .blue : .primary)

                HStack(spacing: 4) {
                    Image(systemName: entry.trainingLevel.icon)
                        .font(.caption2)
                    Text(entry.trainingLevel.rank)
                        .font(.caption2)
                }
                .foregroundStyle(levelColor)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(entry.isCurrentUser ? Color.blue.opacity(0.08) : Color(.systemGray6))
        )
    }

    // MARK: - Rank Badge

    @ViewBuilder
    private var rankBadge: some View {
        ZStack {
            if entry.rank <= 3 {
                Circle()
                    .fill(medalColor)
                    .frame(width: 36, height: 36)

                Text("\(entry.rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            } else {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 36, height: 36)

                Text("\(entry.rank)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Colors

    private var medalColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return Color(.systemGray)
        case 3: return .orange
        default: return Color(.systemGray5)
        }
    }

    private var levelColor: Color {
        switch entry.trainingLevel.color {
        case "cyan": return .cyan
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "indigo": return .indigo
        case "orange": return .orange
        case "red": return .red
        case "yellow": return .yellow
        case "pink": return .pink
        case "mint": return .mint
        case "teal": return .teal
        default: return .gray
        }
    }
}

// MARK: - Compact Rank Card (for showing current user at top)

struct LeaderboardRankCard: View {
    let entry: LeaderboardEntry
    let scope: LeaderboardScope

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Rank")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("#\(entry.rank)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)

                        Text("of \(scopeDescription)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Score")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(entry.totalScore.formatted())")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }

            // Stats row
            HStack(spacing: 24) {
                StatItem(label: "Games", value: "\(entry.gamesPlayed)")
                StatItem(label: "Win Rate", value: "\(entry.winPercentage)%")
                StatItem(label: "Level", value: entry.trainingLevel.rank)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }

    private var scopeDescription: String {
        switch scope {
        case .school: return "school"
        case .state: return "state"
        case .country: return "country"
        case .national: return "nation"
        case .global: return "global"
        }
    }
}

private struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        LeaderboardRow(
            entry: LeaderboardEntry(
                id: "1",
                playerID: "p1",
                displayName: "John Smith",
                schoolID: "harvard",
                schoolName: "Harvard Medical School",
                state: "MA",
                country: "US",
                totalScore: 12450,
                gamesPlayed: 50,
                gamesWon: 45,
                rank: 1,
                isCurrentUser: false
            ),
            showSchool: true,
            currentScope: .school
        )

        LeaderboardRow(
            entry: LeaderboardEntry(
                id: "2",
                playerID: "p2",
                displayName: "Current User",
                schoolID: "stanford",
                schoolName: "Stanford School of Medicine",
                state: "CA",
                country: "US",
                totalScore: 10200,
                gamesPlayed: 40,
                gamesWon: 35,
                rank: 5,
                isCurrentUser: true
            ),
            showSchool: true,
            currentScope: .national
        )
    }
    .padding()
}
