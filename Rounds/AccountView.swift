//
//  AccountView.swift
//  Rounds
//
//  The single, unified account hub: cross-device sync (Sign in with Apple /
//  email), Pro status, Account ID (for support & comps), and the referral
//  invite + redeem flow — all in one cohesive place.
//

import SwiftUI
import AuthenticationServices
import UIKit

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss

    /// Optional code to pre-fill (e.g. from a shared rounds://invite/CODE link).
    var initialCode: String? = nil

    private var account: AccountManager { AccountManager.shared }
    private var subscription: SubscriptionManager { SubscriptionManager.shared }

    @State private var codeEntry = ""
    @State private var isRedeeming = false
    @State private var outcome: AccountManager.RedeemOutcome?
    @State private var copiedID = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            List {
                syncSection
                proSection
                inviteSection
                redeemSection
                accountIDSection
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                RoundsPaywallView()
            }
            .task {
                if let initialCode, codeEntry.isEmpty { codeEntry = initialCode }
                await account.refreshStatus()
            }
        }
    }

    // MARK: - Sync & Sign In

    @ViewBuilder
    private var syncSection: some View {
        if account.isAnonymousAccount {
            Section {
                AccountLinkingControls()
            } header: {
                Label("Sync across devices", systemImage: "icloud.and.arrow.up")
            } footer: {
                Text("Sign in so your Pro access and progress follow you to a new phone, iPad, or the web. Your data stays exactly where it is.")
            }
        } else {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2).foregroundStyle(.green).frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Synced & signed in").font(.body).fontWeight(.medium)
                        if let email = account.accountEmail {
                            Text(email).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Label("Sync across devices", systemImage: "icloud.and.arrow.up")
            } footer: {
                Text("Your Pro access and progress are tied to this account and will follow you to new devices.")
            }
        }
    }

    // MARK: - Pro status

    @ViewBuilder
    private var proSection: some View {
        Section {
            if subscription.isProUser {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill").font(.title2).foregroundStyle(.yellow).frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rounds Pro is active").font(.body).fontWeight(.medium)
                        Text("Enjoy unlimited cases and every feature.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.up.circle.fill").font(.title2).foregroundStyle(.blue).frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Rounds Pro").font(.body).fontWeight(.medium).foregroundStyle(.primary)
                            Text("Unlock unlimited cases, the Differential Builder & more")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: - Invite

    @ViewBuilder
    private var inviteSection: some View {
        Section {
            if let code = account.referralCode {
                HStack {
                    Text("Your code").foregroundStyle(.secondary)
                    Spacer()
                    Text(code)
                        .font(.system(.title3, design: .monospaced).bold())
                        .textSelection(.enabled)
                }
                if let remaining = account.invitesRemaining {
                    HStack {
                        Text("Invites left").foregroundStyle(.secondary)
                        Spacer()
                        Text("\(remaining) of \(account.maxReferrals)").fontWeight(.medium)
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
                    Text("Loading your invite code…").foregroundStyle(.secondary)
                    Spacer()
                    ProgressView()
                }
            }
        } header: {
            Label("Invite friends", systemImage: "gift.fill")
        } footer: {
            Text("Share your code with up to \(account.maxReferrals) friends. Each one unlocks Rounds Pro free.")
        }
    }

    // MARK: - Redeem

    private var redeemSection: some View {
        Section {
            TextField("Enter invite or promo code", text: $codeEntry)
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
            Label("Have a code?", systemImage: "ticket.fill")
        }
    }

    private func redeem() async {
        isRedeeming = true
        outcome = nil
        outcome = await account.redeem(code: codeEntry)
        isRedeeming = false
        if outcome?.succeeded == true { codeEntry = "" }
    }

    // MARK: - Account ID (support / comps)

    private var accountIDSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "number").font(.title2).foregroundStyle(.secondary).frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Account ID").font(.body).fontWeight(.medium)
                        if let id = account.userID {
                            Text(id)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1).truncationMode(.middle)
                                .textSelection(.enabled)
                        } else {
                            Text("Preparing your account…").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if account.userID != nil {
                        Button {
                            copyAccountID()
                        } label: {
                            Image(systemName: copiedID ? "checkmark.circle.fill" : "doc.on.doc")
                                .font(.title3)
                                .foregroundStyle(copiedID ? .green : .blue)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        } header: {
            Label("Support", systemImage: "lifepreserver")
        } footer: {
            Text("Share your Account ID with support to get help or Pro access.")
        }
    }

    private func copyAccountID() {
        guard let id = account.userID else { return }
        UIPasteboard.general.string = id
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { copiedID = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { copiedID = false }
        }
    }
}

// MARK: - Reusable linking controls (Apple + email magic link)

/// Sign in with Apple + email magic-link controls. Used in the Account hub and
/// in the one-time "secure your account" nudge so the linking UX is identical
/// everywhere.
struct AccountLinkingControls: View {
    private var account: AccountManager { AccountManager.shared }

    @State private var emailEntry = ""
    @State private var isLinkingEmail = false
    @State private var emailLinkSent = false

    var body: some View {
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
    AccountView()
}
