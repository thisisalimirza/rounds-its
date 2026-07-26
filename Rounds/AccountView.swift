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
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            List {
                syncSection
                proSection
                inviteSection
                redeemSection
                accountIDSection
                betaSection
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
                // Warning banner first: the risk has to land before the ask.
                // Without it "Sync across devices" reads as an optional
                // convenience rather than "your progress is not backed up".
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Your progress isn't backed up")
                            .font(.subheadline.weight(.semibold))
                        Text("If you delete Rounds or change phones, your streak, stats and Pro access are gone. Signing in takes a few seconds and fixes it permanently.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)

                AccountLinkingControls()
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
            } header: {
                Label("Sync across devices", systemImage: "icloud.and.arrow.up")
            } footer: {
                Text("Your data stays exactly where it is — signing in only adds a backup.")
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
    // MARK: - Beta controls

    /// Beta-only Pro/free override, surfaced here because this is the screen
    /// you actually reach (Settings → Account). It previously lived only in
    /// SubscriptionSettingsView, which nothing links to except a row inside
    /// About — effectively undiscoverable.
    ///
    /// Absent entirely from App Store builds: `isBetaBuild` is false there and
    /// `hasProAccess()` ignores the flag regardless.
    @ViewBuilder
    private var betaSection: some View {
        if subscription.isBetaBuild {
            Section {
                Toggle(isOn: Binding(
                    get: { subscription.isSimulatingFreeUser },
                    set: { subscription.isSimulatingFreeUser = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Simulate Free User")
                        Text("Lock Pro features so you can see the free experience")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Label("Beta testing", systemImage: "hammer.fill")
            } footer: {
                Text("TestFlight auto-grants Pro to every tester, so this is the only way to check the free tier and the paywalls. Not present in App Store builds. Reopen a screen if it looks stale after toggling.")
            }
        }
    }

    private var proSection: some View {
        Section {
            if subscription.isProUser {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill").font(.title2).foregroundStyle(.yellow).frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rounds Pro is active").font(.body).fontWeight(.medium)
                        Text(subscription.getSubscriptionSource())
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Button {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Manage subscription", systemImage: "creditcard")
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

            Button {
                Task { await restore() }
            } label: {
                HStack {
                    Label("Restore purchases", systemImage: "arrow.clockwise")
                    Spacer()
                    if isRestoring { ProgressView() }
                }
            }
            .disabled(isRestoring)
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        _ = try? await subscription.restorePurchases()
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
/// Apple / email account linking.
///
/// Self-contained rather than a set of loose `List` rows. The previous version
/// emitted three sibling rows — an Apple button with zeroed insets, a bare
/// TextField, and a Button whose label was plain text — so inside a grouped
/// List the Apple button's corners clipped oddly against the section, and the
/// submit button was visually indistinguishable from the text field above it.
/// A person could not tell what was tappable.
///
/// Now: one clearly primary path (Apple), a labelled divider, then a bordered
/// field paired with a filled button that unmistakably reads as a button.
///
/// Present it in a row with cleared insets and background:
///     .listRowInsets(EdgeInsets())
///     .listRowBackground(Color.clear)
struct AccountLinkingControls: View {
    private var account: AccountManager { AccountManager.shared }

    @State private var emailEntry = ""
    @State private var isLinkingEmail = false
    @State private var emailLinkSent = false
    @State private var errorMessage: String?
    @FocusState private var emailFocused: Bool

    private var emailIsValid: Bool {
        let t = emailEntry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let at = t.firstIndex(of: "@") else { return false }
        let domain = t[t.index(after: at)...]
        return at != t.startIndex && domain.contains(".") && !domain.hasSuffix(".")
    }

    var body: some View {
        if emailLinkSent {
            sentConfirmation
        } else {
            VStack(spacing: 16) {
                if AppFeatures.signInWithAppleEnabled {
                    SignInWithAppleButton(.signIn) { request in
                        account.configureAppleRequest(request)
                    } onCompletion: { result in
                        Task { await account.handleAppleSignIn(result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    HStack(spacing: 12) {
                        Rectangle().fill(.quaternary).frame(height: 1)
                        Text("or")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Rectangle().fill(.quaternary).frame(height: 1)
                    }
                }

                VStack(spacing: 10) {
                    TextField("your@email.com", text: $emailEntry)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .focused($emailFocused)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(emailFocused ? Color.accentColor : Color(.separator),
                                        lineWidth: emailFocused ? 2 : 1)
                        )

                    Button {
                        emailFocused = false
                        Task { await linkEmail() }
                    } label: {
                        HStack(spacing: 8) {
                            if isLinkingEmail {
                                ProgressView().tint(.white)
                            }
                            Text(isLinkingEmail ? "Sending…" : "Email me a sign-in link")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(emailIsValid && !isLinkingEmail
                                      ? AnyShapeStyle(LinearGradient(colors: [.blue, .purple],
                                                                     startPoint: .leading,
                                                                     endPoint: .trailing))
                                      : AnyShapeStyle(Color.gray.opacity(0.4)))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!emailIsValid || isLinkingEmail)
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var sentConfirmation: some View {
        VStack(spacing: 12) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 34))
                .foregroundStyle(.green)
            Text("Check your email")
                .font(.headline)
            Text("We sent a link to \(emailEntry). Open it on any device — tapping it finishes securing your account.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Use a different email") {
                emailLinkSent = false
                errorMessage = nil
            }
            .font(.footnote)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func linkEmail() async {
        isLinkingEmail = true
        errorMessage = nil
        defer { isLinkingEmail = false }
        do {
            try await account.linkEmail(emailEntry)
            emailLinkSent = true
        } catch {
            // Previously this failure was only printed, so a user whose email
            // was already taken or malformed saw the button spin and then
            // nothing at all.
            errorMessage = "We couldn't send that link. Check the address and try again."
            print("⚠️ linkEmail error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AccountView()
}
