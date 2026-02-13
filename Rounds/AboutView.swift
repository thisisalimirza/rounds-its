//
//  AboutView.swift
//  Rounds
//
//  Settings and About screen
//

import SwiftUI
import SwiftData
import UserNotifications

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var leaderboardProfiles: [LeaderboardProfile]
    @Query private var playerStats: [PlayerStats]
    @Query private var achievementProgress: [AchievementProgress]
    @State private var showingFeedback = false
    @State private var showingSubscription = false
    @State private var showingLeaderboardSetup = false
    @State private var showingLeaveLeaderboardAlert = false
    @State private var showingEditDisplayName = false
    @State private var editedDisplayName = ""
    @State private var notificationsEnabled = false
    @State private var selectedIntensity: NotificationIntensity = SmartNotificationManager.shared.currentIntensity
    @State private var showingNotificationPreview = false
    @State private var previewTitle = ""
    @State private var previewBody = ""
    @State private var showingHowToPlay = false
    @State private var showingWhatsNew = false
    @StateObject private var whatsNewManager = WhatsNewManager.shared
    @AppStorage("dailyReminderHour") private var reminderHour = 19
    @AppStorage("dailyReminderMinute") private var reminderMinute = 0
    @AppStorage("hideCategoryLabel") private var hideCategoryLabel = false
    @AppStorage("hasSeenLeaderboardPrompt") private var hasSeenLeaderboardPrompt = false

    private var leaderboardProfile: LeaderboardProfile? {
        leaderboardProfiles.first
    }

    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }

    // Computed property for the reminder time binding
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = components.hour ?? 19
                reminderMinute = components.minute ?? 0
                // Use smart notifications with context
                let ctx = playerStats.first.map { SmartNotificationManager.buildContext(from: $0, achievements: achievementProgress.first) }
                SmartNotificationManager.shared.scheduleSmartReminder(hour: reminderHour, minute: reminderMinute, context: ctx)
            }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Account Section
                Section {
                    subscriptionRow
                } header: {
                    Label("Account", systemImage: "person.crop.circle")
                }

                // MARK: - Leaderboard Section
                Section {
                    if let profile = leaderboardProfile {
                        leaderboardProfileRows(profile: profile)
                    } else {
                        joinLeaderboardRow
                    }
                } header: {
                    Label("Leaderboard", systemImage: "trophy.fill")
                } footer: {
                    if leaderboardProfile != nil {
                        Text("Your display name and school are visible to other players on the leaderboard.")
                    }
                }

                // MARK: - Notifications Section
                Section {
                    notificationRows
                } header: {
                    Label("Notifications", systemImage: "bell.badge.fill")
                }

                // MARK: - Gameplay Section
                Section {
                    gameplayRows
                } header: {
                    Label("Gameplay", systemImage: "gamecontroller.fill")
                }

                // MARK: - Help Section
                Section {
                    howToPlayRow
                    whatsNewRow
                    feedbackRow
                } header: {
                    Label("Help", systemImage: "questionmark.circle")
                }

                // MARK: - About Section
                Section {
                    aboutAppRow
                    supportLinksRows
                } header: {
                    Label("About", systemImage: "info.circle")
                }

                // MARK: - Legal Section
                Section {
                    legalRows
                } header: {
                    Label("Legal", systemImage: "doc.text")
                } footer: {
                    VStack(spacing: 8) {
                        Text("Made with ❤️ for medical students")
                        Text("© 2025 Brask Group LLC")
                        Text("Version 1.0")
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackSheet()
        }
        .sheet(isPresented: $showingSubscription) {
            if subscriptionManager.isProUser {
                SubscriptionSettingsView()
            } else {
                RoundsPaywallView()
            }
        }
        .sheet(isPresented: $showingLeaderboardSetup) {
            LeaderboardProfileSetupView()
        }
        .sheet(isPresented: $showingHowToPlay) {
            HowToPlaySheet()
        }
        .sheet(isPresented: $showingWhatsNew) {
            if let data = whatsNewManager.whatsNewData {
                WhatsNewView(data: data) {
                    whatsNewManager.markAsSeen()
                }
                .presentationDetents([.large])
            }
        }
        .alert("Edit Display Name", isPresented: $showingEditDisplayName) {
            TextField("Display Name", text: $editedDisplayName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveDisplayName()
            }
        } message: {
            Text("Enter your new display name for the leaderboard.")
        }
        .alert("Leave Leaderboard?", isPresented: $showingLeaveLeaderboardAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                leaveLeaderboard()
            }
        } message: {
            Text("Your scores will be removed from all leaderboards. You can rejoin anytime.")
        }
        .alert(previewTitle, isPresented: $showingNotificationPreview) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(previewBody)
        }
        .onAppear {
            checkNotificationStatus()
        }
    }

    // MARK: - Subscription Row

    private var subscriptionRow: some View {
        Button {
            showingSubscription = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: subscriptionManager.isProUser ? "crown.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(subscriptionManager.isProUser ? .yellow : .blue)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(subscriptionManager.isProUser ? "Rounds Pro" : "Upgrade to Pro")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(subscriptionManager.isProUser ? subscriptionManager.getSubscriptionSource() : "Unlock unlimited cases & features")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .listRowBackground(
            subscriptionManager.isProUser
                ? Color.yellow.opacity(0.1)
                : Color(.systemBackground)
        )
    }

    // MARK: - Leaderboard Profile Rows

    @ViewBuilder
    private func leaderboardProfileRows(profile: LeaderboardProfile) -> some View {
        // Display Name (editable)
        Button {
            editedDisplayName = profile.displayName
            showingEditDisplayName = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Display Name")
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text(profile.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Edit")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }

        // School (read-only)
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("School")
                    .font(.body)
                Text(profile.schoolName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }

        // Visibility Toggle
        Toggle(isOn: Binding(
            get: { profile.visibilityLevel == .global },
            set: { newValue in
                profile.visibilityLevel = newValue ? .global : .schoolOnly
                try? modelContext.save()
                syncProfileToCloudKit(profile: profile)
            }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Public Leaderboards")
                    .font(.body)
                Text(profile.visibilityLevel == .global
                     ? "Visible on state & national boards"
                     : "Only visible at your school")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.orange)

        // Leave Leaderboard
        Button(role: .destructive) {
            showingLeaveLeaderboardAlert = true
        } label: {
            HStack {
                Text("Leave Leaderboard")
                Spacer()
            }
        }
    }

    // MARK: - Join Leaderboard Row

    private var joinLeaderboardRow: some View {
        Button {
            showingLeaderboardSetup = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Join Leaderboard")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text("Compete with classmates & nationwide")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Notification Rows

    @ViewBuilder
    private var notificationRows: some View {
        Toggle(isOn: $notificationsEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Reminder")
                    .font(.body)
                Text("Smart reminders personalized to your streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.blue)
        .onChange(of: notificationsEnabled) { _, newValue in
            handleNotificationToggle(newValue)
        }

        if notificationsEnabled {
            // Intensity Picker - cleaner menu style
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notification Style")
                        .font(.body)
                    Text(selectedIntensity.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    ForEach(NotificationIntensity.allCases, id: \.self) { intensity in
                        Button {
                            selectedIntensity = intensity
                            SmartNotificationManager.shared.currentIntensity = intensity
                            rescheduleSmartNotification()
                        } label: {
                            Label(intensity.displayName, systemImage: intensity.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: selectedIntensity.icon)
                            .font(.subheadline)
                        Text(selectedIntensity.displayName)
                            .font(.subheadline)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            // Time Picker
            DatePicker(selection: reminderTime, displayedComponents: .hourAndMinute) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reminder Time")
                        .font(.body)
                    Text("When to send the daily reminder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.blue)

            // Preview button - shows alert with sample notification
            Button {
                previewNotification()
            } label: {
                HStack {
                    Image(systemName: "bell.badge.fill")
                    Text("Preview Notification")
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Gameplay Rows

    @ViewBuilder
    private var gameplayRows: some View {
        Toggle(isOn: $hideCategoryLabel) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hide Category Label")
                    .font(.body)
                Text("Don't show specialty (e.g., Cardiology) during cases")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.purple)
    }

    // MARK: - How to Play Row

    private var howToPlayRow: some View {
        Button {
            showingHowToPlay = true
        } label: {
            HStack {
                Label("How to Play", systemImage: "book.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - What's New Row

    private var whatsNewRow: some View {
        Button {
            Task {
                await whatsNewManager.checkForWhatsNew()
                whatsNewManager.forceShow()
                showingWhatsNew = true
            }
        } label: {
            HStack {
                Label("What's New", systemImage: "sparkles")
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Feedback Row

    private var feedbackRow: some View {
        Button {
            showingFeedback = true
        } label: {
            HStack {
                Label("Send Feedback", systemImage: "paperplane.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - About App Row

    private var aboutAppRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "cross.case.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rounds")
                    .font(.body)
                    .fontWeight(.medium)
                Text("Master USMLE Step 1 through daily clinical case challenges")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Support Links Rows

    @ViewBuilder
    private var supportLinksRows: some View {
        Link(destination: URL(string: "mailto:support@braskgroup.com?subject=Rounds%20Support")!) {
            HStack {
                Label("Contact Support", systemImage: "envelope.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }

        Link(destination: URL(string: "https://braskgroup.com")!) {
            HStack {
                Label("More from Brask Group", systemImage: "building.2.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Legal Rows

    @ViewBuilder
    private var legalRows: some View {
        Link(destination: URL(string: "https://braskgroup.com/rounds.html")!) {
            HStack {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }

        Link(destination: URL(string: "https://braskgroup.com/rounds.html")!) {
            HStack {
                Label("Terms of Service", systemImage: "doc.text.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }

        // Medical Disclaimer
        VStack(alignment: .leading, spacing: 8) {
            Label("Medical Disclaimer", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.orange)

            Text("Rounds is for educational purposes only. It is not intended to diagnose, treat, cure, or prevent any disease. Always seek professional medical advice.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helper Functions

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled {
            SmartNotificationManager.shared.requestAuthorization { granted in
                if granted {
                    rescheduleSmartNotification()
                } else {
                    notificationsEnabled = false
                }
            }
        } else {
            SmartNotificationManager.shared.cancelAll()
        }
    }

    private func rescheduleSmartNotification() {
        let context = buildNotificationContext()
        SmartNotificationManager.shared.scheduleSmartReminder(
            hour: reminderHour,
            minute: reminderMinute,
            context: context
        )
    }

    private func buildNotificationContext() -> NotificationContext? {
        guard let stats = playerStats.first else { return nil }
        return SmartNotificationManager.buildContext(
            from: stats,
            achievements: achievementProgress.first
        )
    }

    private func previewNotification() {
        // Generate a sample notification based on current context and intensity
        let sample = SmartNotificationManager.shared.generateSampleMessage(
            context: buildNotificationContext(),
            intensity: selectedIntensity
        )
        previewTitle = sample.title
        previewBody = sample.body
        showingNotificationPreview = true

        // Also reschedule to update the actual daily notification
        rescheduleSmartNotification()
    }

    private func saveDisplayName() {
        guard let profile = leaderboardProfile,
              !editedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        profile.displayName = editedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        try? modelContext.save()
        syncProfileToCloudKit(profile: profile)
    }

    private func syncProfileToCloudKit(profile: LeaderboardProfile) {
        Task {
            let statsDescriptor = FetchDescriptor<PlayerStats>()
            if let stats = try? modelContext.fetch(statsDescriptor).first {
                try? await LeaderboardManager.shared.syncProfile(
                    profile: profile,
                    totalScore: stats.totalScore,
                    gamesPlayed: stats.gamesPlayed,
                    gamesWon: stats.gamesWon
                )
            }
        }
    }

    private func leaveLeaderboard() {
        guard let profile = leaderboardProfile else { return }

        Task {
            try? await LeaderboardManager.shared.deleteProfile(profile: profile)
        }
        modelContext.delete(profile)
        try? modelContext.save()
        hasSeenLeaderboardPrompt = false
    }
}

// MARK: - How to Play Sheet

struct HowToPlaySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("How to Play Rounds")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)

                    // Instructions
                    VStack(alignment: .leading, spacing: 20) {
                        InstructionRow(
                            icon: "1.circle.fill",
                            title: "Read the Clinical Clues",
                            description: "Start with the first hint and read the patient presentation carefully."
                        )

                        InstructionRow(
                            icon: "2.circle.fill",
                            title: "Make Your Diagnosis",
                            description: "Enter your diagnosis guess. You have 5 attempts total."
                        )

                        InstructionRow(
                            icon: "3.circle.fill",
                            title: "Progressive Hints",
                            description: "After each wrong guess, a new clinical clue is revealed automatically."
                        )

                        InstructionRow(
                            icon: "4.circle.fill",
                            title: "Final Guess",
                            description: "When all hints are revealed, you get one last attempt."
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)

                    // Scoring
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Scoring")
                            .font(.headline)

                        VStack(spacing: 12) {
                            ScoreInfoRow(label: "Base Score", value: "500 pts", color: .green)
                            ScoreInfoRow(label: "Per Wrong Guess", value: "-100 pts", color: .red)
                            ScoreInfoRow(label: "Per Extra Hint", value: "-50 pts", color: .orange)
                        }

                        Text("First hint is free. Fewer guesses and hints = higher score!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)

                    // Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Medical Categories")
                            .font(.headline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            CategoryTag(name: "Cardiology", color: .red)
                            CategoryTag(name: "Neurology", color: .purple)
                            CategoryTag(name: "Pulmonology", color: .blue)
                            CategoryTag(name: "Gastroenterology", color: .orange)
                            CategoryTag(name: "Endocrinology", color: .green)
                            CategoryTag(name: "Hematology", color: .pink)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Score Info Row

struct ScoreInfoRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Category Tag

struct CategoryTag: View {
    let name: String
    let color: Color

    var body: some View {
        Text(name)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(8)
    }
}

#Preview {
    AboutView()
}
