//
//  AccountGateView.swift
//  Rounds
//
//  Full-screen account requirement. Not dismissible: anonymous play is a short
//  trial, and existing players are asked once their history is already on the
//  server. The visual language matches the rest of Rounds (blue-to-purple,
//  rounded type). Instrument Serif and DM Sans are not bundled in the iOS app;
//  this screen uses the same rounded system faces the rest of the UI uses.
//

import SwiftUI

struct AccountGateView: View {
    let kind: AccountGateKind
    var casesPlayed: Int
    var currentStreak: Int
    var unlockedAchievements: Int
    var hasPro: Bool
    var schoolName: String?
    var onFinished: () -> Void

    @State private var email = ""
    @State private var code = ""
    @State private var phase: Phase = .email
    @State private var isBusy = false
    @State private var errorMessage: String?
    @State private var successMessage = "You're all set. Your progress is saved."
    @State private var resendAvailableAt: Date?
    @State private var didTrackShown = false
    @FocusState private var emailFocused: Bool
    @FocusState private var codeFocused: Bool

    private enum Phase { case email, code, success }

    private var account: AccountManager { AccountManager.shared }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    switch phase {
                    case .email: emailStep
                    case .code: codeStep
                    case .success: successStep
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 28)
                .padding(.bottom, 36)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(red: 0.29, green: 0.565, blue: 0.886).opacity(0.08)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(true)
        .onAppear {
            guard !didTrackShown else { return }
            didTrackShown = true
            let reason = kind == .grandfathered ? "grandfathered" : "trial_limit"
            AnalyticsManager.shared.track("account_gate_shown", properties: [
                "reason": reason,
                "cases_completed": casesPlayed
            ])
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [brandBlue.opacity(0.18), brandPurple.opacity(0.18)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 84, height: 84)
                Image(systemName: kind == .trialLimit ? "flag.checkered" : "lock.heart")
                    .font(.system(size: 34))
                    .foregroundStyle(LinearGradient(colors: [brandBlue, brandPurple],
                                                    startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            Text(title)
                .font(.system(.title, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var title: String {
        switch kind {
        case .trialLimit: return "Keep what you've started"
        default: return "Save your progress"
        }
    }

    private var subtitle: String {
        if hasPro && kind != .trialLimit {
            return proLine + " " + progressLine
        }
        switch kind {
        case .trialLimit:
            return "You've finished \(casesPlayed) case\(casesPlayed == 1 ? "" : "s"). Save them to keep your streak, play on getrounds.app, and join the leaderboard."
        default:
            return progressLine + " Connect your email to keep them and play anywhere."
        }
    }

    private var progressLine: String {
        var parts: [String] = []
        if casesPlayed > 0 {
            parts.append("\(casesPlayed) case\(casesPlayed == 1 ? "" : "s")")
        }
        if currentStreak > 0 {
            parts.append("\(currentStreak)-day streak")
        }
        if unlockedAchievements > 0 {
            parts.append("\(unlockedAchievements) achievement\(unlockedAchievements == 1 ? "" : "s")")
        }
        if parts.isEmpty {
            return "Your progress is on this phone only."
        }
        return "Your \(Self.list(parts)) \(parts.count == 1 ? "is" : "are") on this phone only."
    }

    private static func list(_ parts: [String]) -> String {
        switch parts.count {
        case 0: return ""
        case 1: return parts[0]
        case 2: return "\(parts[0]) and \(parts[1])"
        default:
            return parts.dropLast().joined(separator: ", ") + ", and " + (parts.last ?? "")
        }
    }

    private var proLine: String {
        "Pro is active on this phone."
    }

    private var emailStep: some View {
        VStack(spacing: 14) {
            if let schoolName, !schoolName.isEmpty {
                Text("A \(schoolName) email is a good choice if you still have one. Any email works.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            TextField("you@school.edu", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .focused($emailFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground)))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(emailFocused ? brandBlue : Color(.separator), lineWidth: emailFocused ? 2 : 1))

            domainNote

            if let suggestion = EmailAddressHints.suggestion(for: email) {
                Button("Use \(suggestion) instead?") {
                    email = suggestion
                    errorMessage = nil
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(brandBlue)
            }

            primaryButton(title: isBusy ? "Sending…" : "Email me a code", enabled: EmailAddressHints.isValid(email) && !isBusy) {
                await sendCode()
            }

            if hasPro {
                Button("Restore purchases") { Task { await restore() } }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(brandPurple)
                    .disabled(isBusy)
            }

            Button("Already have an account? Sign in") {
                // Same code path: the email's existing account receives the code,
                // and claim folds this phone's anonymous progress into it.
                Task { await sendCode() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .disabled(!EmailAddressHints.isValid(email) || isBusy)

            if let errorMessage { errorLabel(errorMessage) }
        }
    }

    @ViewBuilder
    private var domainNote: some View {
        switch EmailAddressHints.tone(of: email) {
        case .school:
            Label("That looks like a school email.", systemImage: "checkmark.seal.fill")
                .font(.footnote)
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .personal:
            Text("A personal email works. You can switch to a school address later if you want.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .other, .invalid:
            EmptyView()
        }
    }

    private var codeStep: some View {
        VStack(spacing: 14) {
            Text("We sent a code to \(EmailAddressHints.normalized(email)).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Code", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.system(.title2, design: .monospaced).weight(.semibold))
                .focused($codeFocused)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground)))

            primaryButton(title: isBusy ? "Saving…" : "Verify and save", enabled: code.count >= 4 && !isBusy) {
                await verify()
            }

            HStack(spacing: 16) {
                Button(resendTitle) { Task { await sendCode() } }
                    .disabled(!canResend || isBusy)
                Button("Use a different email") {
                    phase = .email
                    code = ""
                    errorMessage = nil
                }
            }
            .font(.footnote)

            if let errorMessage { errorLabel(errorMessage) }
        }
    }

    private var successStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text(successMessage)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
            primaryButton(title: "Continue", enabled: true) {
                onFinished()
            }
        }
        .padding(.top, 8)
    }

    private var canResend: Bool {
        guard let resendAvailableAt else { return true }
        return Date() >= resendAvailableAt
    }

    private var resendTitle: String {
        guard let resendAvailableAt, Date() < resendAvailableAt else { return "Resend code" }
        let seconds = Int(resendAvailableAt.timeIntervalSinceNow.rounded(.up))
        return "Resend in \(max(seconds, 1))s"
    }

    private var brandBlue: Color { Color(red: 74 / 255, green: 144 / 255, blue: 226 / 255) }
    private var brandPurple: Color { Color(red: 155 / 255, green: 89 / 255, blue: 182 / 255) }

    private func primaryButton(title: String, enabled: Bool, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            Text(title)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(enabled
                              ? AnyShapeStyle(LinearGradient(colors: [brandBlue, brandPurple],
                                                             startPoint: .leading, endPoint: .trailing))
                              : AnyShapeStyle(Color.gray.opacity(0.4)))
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func errorLabel(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.circle.fill")
            .font(.footnote)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sendCode() async {
        guard EmailAddressHints.isValid(email) else { return }
        if let until = resendAvailableAt, Date() < until, phase == .code { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        let tone = EmailAddressHints.tone(of: email)
        AnalyticsManager.shared.track("account_gate_email_submitted", properties: [
            "is_school_domain": tone == .school
        ])
        do {
            try await account.sendEmailCode(email)
            phase = .code
            resendAvailableAt = Date().addingTimeInterval(45)
            codeFocused = true
        } catch {
            let text = error.localizedDescription.lowercased()
            errorMessage = text.contains("rate")
                ? "Too many emails just now. Wait a minute and try again."
                : "We couldn't send that code. Check the address and try again."
            AnalyticsManager.shared.track("account_gate_failed", properties: ["error": "send"])
        }
    }

    private func verify() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        let outcome = await account.verifyEmailCode(email, code: code)
        switch outcome {
        case .linked(let backedUp, let mergedIntoExisting, let claimFailed):
            AnalyticsManager.shared.track("account_gate_code_verified")
            successMessage = outcome.message
            if backedUp && !claimFailed {
                AnalyticsManager.shared.track("account_gate_completed", properties: [
                    "merged_existing": mergedIntoExisting
                ])
            } else {
                AnalyticsManager.shared.track("account_gate_failed", properties: ["error": "backup"])
            }
            phase = .success
            account.trackAccountLinked(method: "email_gate")
        case .invalidCode, .error:
            errorMessage = outcome.message
            AnalyticsManager.shared.track("account_gate_failed", properties: [
                "error": outcome.message
            ])
        }
    }

    private func restore() async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            _ = try await SubscriptionManager.shared.restorePurchases()
            if SubscriptionManager.shared.hasProAccess() {
                errorMessage = nil
            } else {
                errorMessage = "No purchases found. Make sure you're signed into the same Apple ID you bought with."
            }
        } catch {
            errorMessage = "Restore didn't finish. Make sure you're signed into the same Apple ID you bought with, then try again."
        }
    }
}
