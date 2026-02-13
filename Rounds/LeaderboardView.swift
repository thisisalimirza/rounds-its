//
//  LeaderboardView.swift
//  Rounds
//
//  Main leaderboard view with scope tabs
//

import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [LeaderboardProfile]

    @State private var selectedScope: LeaderboardScope = .school
    @State private var viewMode: LeaderboardViewMode = .individuals
    @State private var showingProfileSetup = false
    @State private var isRefreshing = false

    private var profile: LeaderboardProfile? {
        profiles.first
    }

    private let manager = LeaderboardManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profile {
                    leaderboardContent(profile: profile)
                } else {
                    noProfileView
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if profile != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task {
                                await refreshLeaderboard()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(manager.isLoading)
                    }
                }
            }
            .sheet(isPresented: $showingProfileSetup) {
                LeaderboardProfileSetupView { newProfile in
                    // Profile created - sync to CloudKit first, then fetch leaderboard
                    Task {
                        // Get player stats to sync
                        let descriptor = FetchDescriptor<PlayerStats>()
                        if let stats = try? modelContext.fetch(descriptor).first {
                            await LeaderboardManager.shared.syncScoreIfNeeded(
                                profile: newProfile,
                                totalScore: stats.totalScore,
                                gamesPlayed: stats.gamesPlayed,
                                gamesWon: stats.gamesWon
                            )
                        } else {
                            // No stats yet, sync with zeros to create CloudKit record
                            await LeaderboardManager.shared.syncScoreIfNeeded(
                                profile: newProfile,
                                totalScore: 0,
                                gamesPlayed: 0,
                                gamesWon: 0
                            )
                        }
                        // Then fetch the leaderboard to show updated data
                        await fetchLeaderboard(for: selectedScope, profile: newProfile)
                    }
                }
            }
        }
    }

    // MARK: - Leaderboard Content

    @ViewBuilder
    private func leaderboardContent(profile: LeaderboardProfile) -> some View {
        VStack(spacing: 0) {
            // Scope picker
            scopePicker(profile: profile)
                .padding(.horizontal)
                .padding(.top, 8)

            // View mode picker (only show for scopes that support school rankings)
            if supportsSchoolRankings {
                viewModePicker
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            // Content
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewMode == .individuals {
                        // Individual rankings
                        // Current user card (if they're on the leaderboard)
                        if let currentUserEntry = currentUserEntry {
                            LeaderboardRankCard(entry: currentUserEntry, scope: selectedScope)
                                .padding(.horizontal)
                                .padding(.top, 16)
                        }

                        // Leaderboard entries
                        if manager.isLoading && currentEntries.isEmpty {
                            loadingView
                        } else if currentEntries.isEmpty {
                            emptyStateView(profile: profile)
                        } else {
                            leaderboardList
                        }
                    } else {
                        // School rankings
                        if let currentUserSchoolEntry = currentUserSchoolEntry {
                            SchoolRankCard(entry: currentUserSchoolEntry, scope: selectedScope)
                                .padding(.horizontal)
                                .padding(.top, 16)
                        }

                        if manager.isLoading && currentSchoolEntries.isEmpty {
                            loadingView
                        } else if currentSchoolEntries.isEmpty {
                            schoolEmptyStateView(profile: profile)
                        } else {
                            schoolLeaderboardList
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .refreshable {
                await refreshLeaderboard()
            }
        }
        .task {
            // Initial fetch
            if currentEntries.isEmpty {
                await fetchLeaderboard(for: selectedScope, profile: profile)
            }
        }
        .onChange(of: selectedScope) { _, newScope in
            // Reset to individuals view when switching scopes (school scope doesn't support school rankings)
            if newScope == .school {
                viewMode = .individuals
            }
            Task {
                await fetchLeaderboard(for: newScope, profile: profile)
            }
        }
    }

    // MARK: - View Mode Picker

    private var viewModePicker: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(LeaderboardViewMode.allCases, id: \.self) { mode in
                Label(mode.rawValue, systemImage: mode.icon)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    /// Whether current scope supports school rankings (school scope doesn't make sense for inter-school competition)
    private var supportsSchoolRankings: Bool {
        selectedScope != .school && selectedScope != .country
    }

    // MARK: - Scope Picker

    @ViewBuilder
    private func scopePicker(profile: LeaderboardProfile) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(profile.availableScopes, id: \.self) { scope in
                    ScopeButton(
                        scope: scope,
                        isSelected: selectedScope == scope,
                        profile: profile
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedScope = scope
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading leaderboard...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Empty State

    @ViewBuilder
    private func emptyStateView(profile: LeaderboardProfile) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text(emptyStateTitle)
                .font(.headline)

            Text(emptyStateMessage(profile: profile))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let error = manager.error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var emptyStateTitle: String {
        switch selectedScope {
        case .school: return "No classmates yet"
        case .state: return "No one in your state yet"
        case .country: return "No one in your country yet"
        case .national: return "No US students yet"
        case .global: return "Be the first!"
        }
    }

    private func emptyStateMessage(profile: LeaderboardProfile) -> String {
        switch selectedScope {
        case .school:
            return "Be the first from \(profile.schoolName) to join the leaderboard!"
        case .state:
            let stateName = USStates.fullName(for: profile.state) ?? profile.state
            return "No students from \(stateName) have joined yet."
        case .country:
            let countryName = CountryDatabase.country(withCode: profile.country)?.name ?? profile.country
            return "No students from \(countryName) have joined yet."
        case .national:
            return "No US medical students have joined the leaderboard yet."
        case .global:
            return "Play games to earn points and climb the global rankings!"
        }
    }

    // MARK: - Leaderboard List

    private var leaderboardList: some View {
        VStack(spacing: 8) {
            ForEach(currentEntries) { entry in
                LeaderboardRow(
                    entry: entry,
                    showSchool: selectedScope != .school,
                    currentScope: selectedScope
                )
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    // MARK: - School Leaderboard List

    private var schoolLeaderboardList: some View {
        VStack(spacing: 8) {
            ForEach(currentSchoolEntries) { entry in
                SchoolLeaderboardRow(entry: entry, currentScope: selectedScope)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    // MARK: - School Empty State

    @ViewBuilder
    private func schoolEmptyStateView(profile: LeaderboardProfile) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "building.columns")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No school data yet")
                .font(.headline)

            Text(schoolEmptyStateMessage(profile: profile))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let error = manager.error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func schoolEmptyStateMessage(profile: LeaderboardProfile) -> String {
        switch selectedScope {
        case .school:
            return "School rankings aren't available at school level."
        case .state:
            let stateName = USStates.fullName(for: profile.state) ?? profile.state
            return "No schools from \(stateName) have enough students on the leaderboard yet."
        case .country:
            return "Country-level school rankings aren't available yet."
        case .national:
            return "No US schools have enough students on the leaderboard yet."
        case .global:
            return "No schools have enough students on the global leaderboard yet."
        }
    }

    // MARK: - No Profile View

    private var noProfileView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 70))
                .foregroundStyle(.yellow)

            VStack(spacing: 8) {
                Text("Join the Leaderboard")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Compete with classmates and students nationwide to see who has the best diagnostic skills!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showingProfileSetup = true
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Helpers

    private var currentEntries: [LeaderboardEntry] {
        manager.leaderboard(for: selectedScope)
    }

    private var currentUserEntry: LeaderboardEntry? {
        currentEntries.first { $0.isCurrentUser }
    }

    private var currentSchoolEntries: [SchoolRankingEntry] {
        manager.schoolRankings(for: selectedScope)
    }

    private var currentUserSchoolEntry: SchoolRankingEntry? {
        currentSchoolEntries.first { $0.isCurrentUserSchool }
    }

    private func fetchLeaderboard(for scope: LeaderboardScope, profile: LeaderboardProfile) async {
        await manager.fetchLeaderboard(for: scope, profile: profile)
    }

    private func refreshLeaderboard() async {
        guard let profile = profile else { return }
        isRefreshing = true
        await fetchLeaderboard(for: selectedScope, profile: profile)
        isRefreshing = false
    }
}

// MARK: - Scope Button

private struct ScopeButton: View {
    let scope: LeaderboardScope
    let isSelected: Bool
    let profile: LeaderboardProfile
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: scope.icon)
                    .font(.caption)
                Text(displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private var displayName: String {
        switch scope {
        case .school:
            // Shorten school name if too long
            let name = profile.schoolName
            if name.count > 15 {
                return "My School"
            }
            return name
        case .state:
            return USStates.fullName(for: profile.state) ?? profile.state
        case .country:
            return CountryDatabase.country(withCode: profile.country)?.name ?? profile.country
        case .national:
            return "USA"
        case .global:
            return "Global"
        }
    }
}

// MARK: - School Rank Card

private struct SchoolRankCard: View {
    let entry: SchoolRankingEntry
    let scope: LeaderboardScope

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your School")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(entry.schoolName)
                        .font(.headline)
                        .lineLimit(1)

                    Text("\(entry.studentCount) student\(entry.studentCount == 1 ? "" : "s") competing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("#\(entry.rank)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)

                    Text("\(entry.totalScore) pts")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            // Stats row
            HStack(spacing: 24) {
                StatItem(
                    icon: "gamecontroller.fill",
                    value: "\(entry.totalGamesPlayed)",
                    label: "Games"
                )

                StatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(entry.totalGamesWon)",
                    label: "Wins"
                )

                StatItem(
                    icon: "percent",
                    value: entry.winRate,
                    label: "Win Rate"
                )

                StatItem(
                    icon: "chart.bar.fill",
                    value: entry.avgScorePerStudent,
                    label: "Avg/Student"
                )
            }
            .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

private struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                Text(value)
                    .fontWeight(.medium)
            }
            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - School Leaderboard Row

struct SchoolLeaderboardRow: View {
    let entry: SchoolRankingEntry
    let currentScope: LeaderboardScope

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if entry.rank <= 3 {
                    Circle()
                        .fill(medalColor)
                        .frame(width: 32, height: 32)
                } else {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 32, height: 32)
                }

                Text("\(entry.rank)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(entry.rank <= 3 ? .white : .primary)
            }

            // School info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.schoolName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if entry.isCurrentUserSchool {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }

                HStack(spacing: 8) {
                    // Location info
                    if currentScope == .national || currentScope == .global {
                        Text(entry.state.isEmpty ? entry.country : entry.state)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(entry.studentCount) student\(entry.studentCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.totalScore)")
                    .font(.subheadline)
                    .fontWeight(.bold)

                Text(entry.avgScorePerStudent + " avg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(entry.isCurrentUserSchool ? Color.blue.opacity(0.1) : Color(.systemGray6))
        )
    }

    private var medalColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return Color(.systemGray)
        case 3: return .orange
        default: return Color(.systemGray5)
        }
    }
}

// MARK: - Preview

#Preview {
    LeaderboardView()
}
