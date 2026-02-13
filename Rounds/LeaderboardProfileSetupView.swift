//
//  LeaderboardProfileSetupView.swift
//  Rounds
//
//  Multi-step profile setup for leaderboard participation
//

import SwiftUI
import SwiftData

// MARK: - Setup Step

private enum SetupStep: Int, CaseIterable {
    case welcome = 0
    case location = 1
    case school = 2
    case displayName = 3
    case privacy = 4
    case confirmation = 5

    var title: String {
        switch self {
        case .welcome: return "Join Leaderboards"
        case .location: return "Your Location"
        case .school: return "Your School"
        case .displayName: return "Display Name"
        case .privacy: return "Privacy"
        case .confirmation: return "Confirm"
        }
    }
}

// MARK: - Profile Setup View

struct LeaderboardProfileSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var currentStep: SetupStep = .welcome
    @State private var isInternational = false
    @State private var selectedSchool: MedicalSchool?
    @State private var selectedCountry: Country?
    @State private var customSchoolName = ""
    @State private var displayName = ""
    @State private var visibilityLevel: LeaderboardVisibility = .global
    @State private var isCreatingProfile = false
    @State private var schoolSearchText = ""
    @State private var countrySearchText = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    // Callback when profile is created
    var onProfileCreated: ((LeaderboardProfile) -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator
                    ProgressView(value: Double(currentStep.rawValue + 1), total: Double(SetupStep.allCases.count))
                        .tint(.blue)
                        .padding(.horizontal)
                        .padding(.top)

                    // Step content
                    TabView(selection: $currentStep) {
                        welcomeStep.tag(SetupStep.welcome)
                        locationStep.tag(SetupStep.location)
                        schoolStep.tag(SetupStep.school)
                        displayNameStep.tag(SetupStep.displayName)
                        privacyStep.tag(SetupStep.privacy)
                        confirmationStep.tag(SetupStep.confirmation)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)

                    // Navigation buttons
                    navigationButtons
                        .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .interactiveDismissDisabled(isCreatingProfile)
        }
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
                .shadow(color: .yellow.opacity(0.3), radius: 20)

            VStack(spacing: 12) {
                Text("Compete with Classmates")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Join the leaderboard to see how you rank against students at your medical school, in your state, and across the nation.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Features list
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "building.columns.fill", color: .blue, text: "School rankings")
                FeatureRow(icon: "map.fill", color: .green, text: "State & national rankings")
                FeatureRow(icon: "globe.americas.fill", color: .purple, text: "Global competition")
                FeatureRow(icon: "lock.shield.fill", color: .orange, text: "Privacy controls")
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)

            Spacer()
        }
    }

    // MARK: - Location Step

    private var locationStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Where do you study?")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                // US School option
                Button {
                    withAnimation {
                        isInternational = false
                    }
                } label: {
                    HStack {
                        Text("🇺🇸")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("US Medical School")
                                .font(.headline)
                            Text("MD or DO program in the United States")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if !isInternational {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isInternational ? Color(.systemGray6) : Color.blue.opacity(0.1))
                            .stroke(isInternational ? Color.clear : Color.blue, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)

                // International option
                Button {
                    withAnimation {
                        isInternational = true
                    }
                } label: {
                    HStack {
                        Text("🌍")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("International")
                                .font(.headline)
                            Text("Medical school outside the United States")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isInternational {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isInternational ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            .stroke(isInternational ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - School Step

    private var schoolStep: some View {
        VStack(spacing: 16) {
            if isInternational {
                internationalSchoolSelection
            } else {
                usSchoolSelection
            }
        }
    }

    private var usSchoolSelection: some View {
        VStack(spacing: 16) {
            Text("Select your medical school")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search schools...", text: $schoolSearchText)
                    .textFieldStyle(.plain)
                if !schoolSearchText.isEmpty {
                    Button {
                        schoolSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            // School list
            ScrollView {
                LazyVStack(spacing: 8) {
                    let filteredSchools = MedicalSchoolDatabase.search(schoolSearchText)
                    let groupedSchools = Dictionary(grouping: filteredSchools, by: { $0.state })
                    let sortedStates = groupedSchools.keys.sorted()

                    ForEach(sortedStates, id: \.self) { state in
                        Section {
                            ForEach(groupedSchools[state] ?? []) { school in
                                SchoolRow(
                                    school: school,
                                    isSelected: selectedSchool?.id == school.id
                                ) {
                                    withAnimation {
                                        selectedSchool = school
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Text(USStates.fullName(for: state) ?? state)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var internationalSchoolSelection: some View {
        VStack(spacing: 16) {
            Text("Where is your school?")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top)

            // Country picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Country")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search countries...", text: $countrySearchText)
                        .textFieldStyle(.plain)
                    if !countrySearchText.isEmpty {
                        Button {
                            countrySearchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                ScrollView {
                    LazyVStack(spacing: 4) {
                        let filteredCountries = CountryDatabase.search(countrySearchText)
                        ForEach(filteredCountries) { country in
                            Button {
                                withAnimation {
                                    selectedCountry = country
                                }
                            } label: {
                                HStack {
                                    Text(country.displayName)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedCountry?.code == country.code {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                                .background(
                                    selectedCountry?.code == country.code
                                        ? Color.blue.opacity(0.1)
                                        : Color.clear
                                )
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 200)
            }

            // School name input
            VStack(alignment: .leading, spacing: 8) {
                Text("School Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                TextField("Enter your medical school name", text: $customSchoolName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }

    // MARK: - Display Name Step

    private var displayNameStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Choose a display name")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Display name", text: $displayName)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 40)

                Text("Using your real name helps classmates find you!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if displayName.count > 20 {
                    Text("Maximum 20 characters")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 40)
                }
            }

            Spacer()
        }
    }

    // MARK: - Privacy Step

    private var privacyStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)

                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)

                Text("Privacy Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Choose who can see you on leaderboards")
                    .font(.body)
                    .foregroundStyle(.secondary)

                VStack(spacing: 16) {
                    // School Only option
                    PrivacyOptionRow(
                        title: "School Only",
                        description: "Only students at \(schoolDisplayName) will see your name",
                        icon: "building.columns.fill",
                        isSelected: visibilityLevel == .schoolOnly
                    ) {
                        withAnimation {
                            visibilityLevel = .schoolOnly
                        }
                    }

                    // Global option
                    PrivacyOptionRow(
                        title: "Global",
                        description: "Your name will appear on state, national, and global leaderboards",
                        icon: "globe.americas.fill",
                        isSelected: visibilityLevel == .global
                    ) {
                        withAnimation {
                            visibilityLevel = .global
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 100)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear {
            // Dismiss keyboard when arriving at privacy step
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    // MARK: - Confirmation Step

    private var confirmationStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("Ready to join!")
                .font(.title2)
                .fontWeight(.semibold)

            // Summary
            VStack(alignment: .leading, spacing: 16) {
                SummaryRow(label: "Name", value: displayName)
                SummaryRow(label: "School", value: schoolDisplayName)
                if isInternational {
                    SummaryRow(label: "Country", value: selectedCountry?.name ?? "")
                } else {
                    SummaryRow(label: "State", value: selectedSchool?.stateFullName ?? "")
                }
                SummaryRow(label: "Visibility", value: visibilityLevel.displayName)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 24)

            Text("You can change these settings anytime from the app settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button (not on first step)
            if currentStep != .welcome {
                Button {
                    withAnimation {
                        if let prevIndex = SetupStep.allCases.firstIndex(of: currentStep),
                           prevIndex > 0 {
                            currentStep = SetupStep.allCases[prevIndex - 1]
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .cornerRadius(12)
                }
            }

            // Next/Create button
            Button {
                if currentStep == .confirmation {
                    createProfile()
                } else {
                    withAnimation {
                        if let nextIndex = SetupStep.allCases.firstIndex(of: currentStep),
                           nextIndex < SetupStep.allCases.count - 1 {
                            currentStep = SetupStep.allCases[nextIndex + 1]
                        }
                    }
                }
            } label: {
                HStack {
                    if isCreatingProfile {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(currentStep == .confirmation ? "Join Leaderboard" : "Continue")
                        if currentStep != .confirmation {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canProceed ? Color.blue : Color.gray)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .disabled(!canProceed || isCreatingProfile)
        }
    }

    // MARK: - Helpers

    private var schoolDisplayName: String {
        if isInternational {
            return customSchoolName.isEmpty ? "Your School" : customSchoolName
        } else {
            return selectedSchool?.name ?? "Your School"
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case .welcome, .location:
            return true
        case .school:
            if isInternational {
                return selectedCountry != nil && !customSchoolName.trimmingCharacters(in: .whitespaces).isEmpty
            } else {
                return selectedSchool != nil
            }
        case .displayName:
            let trimmed = displayName.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty && trimmed.count <= 20
        case .privacy, .confirmation:
            return true
        }
    }

    private func createProfile() {
        isCreatingProfile = true

        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)

        // Create the profile
        let profile: LeaderboardProfile
        if isInternational {
            let schoolID = "intl_\(UUID().uuidString.prefix(8))"
            profile = LeaderboardProfile(
                displayName: trimmedName,
                schoolID: schoolID,
                schoolName: customSchoolName.trimmingCharacters(in: .whitespaces),
                state: "INTL",
                country: selectedCountry?.code ?? "XX",
                isInternational: true,
                visibilityLevel: visibilityLevel
            )
        } else {
            guard let school = selectedSchool else {
                isCreatingProfile = false
                return
            }
            profile = LeaderboardProfile(
                displayName: trimmedName,
                schoolID: school.id,
                schoolName: school.name,
                state: school.state,
                country: "US",
                isInternational: false,
                visibilityLevel: visibilityLevel
            )
        }

        // Save to SwiftData
        modelContext.insert(profile)

        do {
            try modelContext.save()
            onProfileCreated?(profile)
            dismiss()
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            showingError = true
            isCreatingProfile = false
        }
    }
}

// MARK: - Supporting Views

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

private struct SchoolRow: View {
    let school: MedicalSchool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(school.name)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(school.type.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PrivacyOptionRow: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    LeaderboardProfileSetupView()
}
