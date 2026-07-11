//
//  ReferralView.swift
//  Rounds
//
//  Redeem an invite code and share your own with friends.
//

import SwiftUI
import AuthenticationServices

struct ReferralView: View {
    @Environment(\.dismiss) private var dismiss

    /// Optional code to pre-fill (e.g. from a shared rounds://invite/CODE link).
    var initialCode: String? = nil

    private var account: AccountManager { AccountManager.shared }
    private var subscription: SubscriptionManager { SubscriptionManager.shared }

    @State private var codeEntry = ""
    @State private var isRedeeming = false
    @State private var outcome: AccountManager.RedeemOutcome?

    @State private var emailEntry = ""
    @State private var isLinkingEmail = false
    @State private var emailLinkSent = false

    var body: some View {
        NavigationStack {
            List {
                if subscription.isProUser {
                    proStatusSection
                }

                redeemSection
                inviteSection

                if account.isAnonymousAccount {
                    saveAccountSection
                }
            }
            .navigationTitle("Rounds Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                if let initialCode, codeEntry.isEmpty {
                    codeEntry = initialCode
                }
                await account.refreshStatus()
            }
        }
    }

    // MARK: - Pro status

    private var proStatusSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rounds Pro is active")
                        .font(.headline)
                    Text("Enjoy unlimited cases and every feature.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Redeem

    private var redeemSection: some View {
        Section {
            TextField("Enter invite code", text: $codeEntry)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))

            Button {
                Task { await redeem() }
            } label: {
                HStack {
                    Text("Redeem code")
                    Spacer()
                    if isRedeeming { ProgressView() }
                }
            }
            .disabled(isRedeeming || codeEntry.trimmingCharacters(in: .whitespaces).isEmpty)

            if let outcome {
                Text(outcome.message)
                    .font(.callout)
                    .foregroundStyle(outcome.succeeded ? .green : .red)
            }
        } header: {
            Text("Have a code?")
        } footer: {
            Text("Redeem a friend's invite code or a promo code to unlock Rounds Pro.")
        }
    }

    private func redeem() async {
        isRedeeming = true
        outcome = nil
        outcome = await account.redeem(code: codeEntry)
        isRedeeming = false
        if outcome?.succeeded == true {
            codeEntry = ""
        }
    }

    // MARK: - Invite

    @ViewBuilder
    private var inviteSection: some View {
        Section {
            if let code = account.referralCode {
                HStack {
                    Text("Your code")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(code)
                        .font(.system(.title3, design: .monospaced).bold())
                        .textSelection(.enabled)
                }

                if let remaining = account.invitesRemaining {
                    HStack {
                        Text("Invites left")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(remaining) of \(account.maxReferrals)")
                            .fontWeight(.medium)
                    }
                }

                if let shareText = account.inviteShareText {
                    ShareLink(item: shareText) {
                        Label("Share your invite", systemImage: "square.and.arrow.up")
                    }
                    .disabled((account.invitesRemaining ?? 0) == 0)
                }
            } else {
                HStack {
                    Text("Loading your invite code…")
                        .foregroundStyle(.secondary)
                    Spacer()
                    ProgressView()
                }
            }
        } header: {
            Text("Invite friends")
        } footer: {
            Text("Share your code with up to \(account.maxReferrals) friends. Each one unlocks Rounds Pro free.")
        }
    }

    // MARK: - Save account (anonymous -> real)

    private var saveAccountSection: some View {
        Section {
            if emailLinkSent {
                Label("Check your email to confirm and secure your account.",
                      systemImage: "envelope.badge.fill")
                    .font(.callout)
                    .foregroundStyle(.green)
            } else {
                SignInWithAppleButton(.signIn) { request in
                    account.configureAppleRequest(request)
                } onCompletion: { result in
                    Task { await account.handleAppleSignIn(result) }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 44)
                .listRowInsets(EdgeInsets())

                TextField("or enter your@email.com", text: $emailEntry)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()

                Button {
                    Task { await linkEmail() }
                } label: {
                    HStack {
                        Text("Email me a magic link")
                        Spacer()
                        if isLinkingEmail { ProgressView() }
                    }
                }
                .disabled(isLinkingEmail || !emailEntry.contains("@"))
            }
        } header: {
            Text("Keep Pro on all your devices")
        } footer: {
            Text("Sign in so your Pro access and progress follow you to a new phone or the web.")
        }
    }

    private func linkEmail() async {
        isLinkingEmail = true
        defer { isLinkingEmail = false }
        do {
            try await account.linkEmail(emailEntry)
            emailLinkSent = true
        } catch {
            print("⚠️ linkEmail error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ReferralView()
}
