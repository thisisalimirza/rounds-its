//
//  AccountManager.swift
//  Rounds
//
//  Account identity + referral loop, backed by Supabase and RevenueCat.
//
//  Everyone gets a silent anonymous Supabase account at launch. That account id
//  is used as the RevenueCat App User ID (via Purchases.logIn), so Pro follows
//  the person across devices and the web. Codes are redeemed and referrals are
//  tracked by Supabase edge functions; RevenueCat remains the source of truth
//  for Pro entitlement.
//

import Foundation
import SwiftUI
import Supabase
import RevenueCat
import AuthenticationServices
import CryptoKit

@MainActor
@Observable
final class AccountManager {

    // MARK: - Singleton

    static let shared = AccountManager()

    // MARK: - Supabase client
    //
    // The publishable (anon) key is designed to be shipped in the client; it is
    // NOT a secret. All privileged actions happen server-side in edge functions.

    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://gvbycponexvxsbrlaejw.supabase.co")!,
        supabaseKey: "sb_publishable_uzzk3B8lDJfrx51_Ab9iLA_7qjkJZr-"
    )

    // MARK: - Observable state (for the UI)

    private(set) var userID: String?
    private(set) var referralCode: String?
    private(set) var invitesRemaining: Int?
    private(set) var maxReferrals: Int = 3
    private(set) var proSource: String = "none"
    private(set) var accountEmail: String?
    private(set) var isReady = false

    /// Whether this account is still anonymous (no email/Apple linked yet).
    var isAnonymousAccount: Bool { accountEmail == nil }

    private init() {}

    // MARK: - Bootstrap (call once at app launch)

    /// Ensures the user has a Supabase account (creating an anonymous one if
    /// needed), ties it to RevenueCat, and loads referral status. Safe to call
    /// repeatedly; it reuses an existing session.
    func bootstrap() async {
        do {
            let session: Session
            if let existing = supabase.auth.currentSession {
                session = existing
            } else {
                session = try await supabase.auth.signInAnonymously()
            }
            await handleSignedIn(user: session.user)
        } catch {
            print("⚠️ AccountManager.bootstrap error: \(error.localizedDescription)")
        }
        isReady = true
    }

    private func handleSignedIn(user: User) async {
        let id = user.id.uuidString.lowercased()
        self.userID = id
        self.accountEmail = user.email

        // Tie RevenueCat identity to this account so Pro syncs everywhere.
        do {
            _ = try await Purchases.shared.logIn(id)
        } catch {
            print("⚠️ RevenueCat logIn error: \(error.localizedDescription)")
        }

        // Set the email attribute so this customer is searchable in RevenueCat.
        if let email = user.email {
            Purchases.shared.attribution.setEmail(email)
        }

        await SubscriptionManager.shared.refreshCustomerInfo()
        await refreshStatus()
    }

    // MARK: - Referral / Pro status

    /// Refreshes the user's referral code and remaining invites from the backend.
    func refreshStatus() async {
        do {
            let status: AccountStatusResponse = try await supabase.functions.invoke("my-status")
            self.referralCode = status.referral_code
            self.proSource = status.pro_source
            self.invitesRemaining = status.invites_remaining
            self.maxReferrals = status.max_referrals
        } catch {
            print("⚠️ my-status error: \(error.localizedDescription)")
        }
    }

    // MARK: - Redeem a code

    enum RedeemOutcome: String {
        case granted
        case alreadyPro = "already_pro"
        case invalidCode = "invalid_code"
        case ownCode = "own_code"
        case codeExhausted = "code_exhausted"
        case missingCode = "missing_code"
        case error

        var succeeded: Bool { self == .granted || self == .alreadyPro }

        var message: String {
            switch self {
            case .granted:       return "🎉 Rounds Pro unlocked!"
            case .alreadyPro:    return "You already have Rounds Pro."
            case .invalidCode:   return "That code isn't valid."
            case .ownCode:       return "You can't redeem your own invite code."
            case .codeExhausted: return "That code has already been used 3 times."
            case .missingCode:   return "Please enter a code."
            case .error:         return "Something went wrong. Please try again."
            }
        }
    }

    /// Redeems a master or referral code. On success, refreshes Pro state.
    func redeem(code: String) async -> RedeemOutcome {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .missingCode }

        do {
            let resp: RedeemCodeResponse = try await supabase.functions.invoke(
                "redeem-code",
                options: .init(body: ["code": trimmed])
            )
            let outcome = RedeemOutcome(rawValue: resp.status ?? "error") ?? .error
            if outcome.succeeded {
                await SubscriptionManager.shared.refreshCustomerInfo()
                await refreshStatus()
            }
            return outcome
        } catch {
            print("⚠️ redeem error: \(error.localizedDescription)")
            return .error
        }
    }

    // MARK: - Convert anonymous account -> real account (email magic link)

    /// Attaches an email to the current (possibly anonymous) account. Supabase
    /// sends a confirmation link; the account id is unchanged, so Pro/referrals
    /// carry over. This is the subtle anonymous → permanent conversion.
    func linkEmail(_ email: String) async throws {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        try await supabase.auth.update(user: UserAttributes(email: trimmed))
        Purchases.shared.attribution.setEmail(trimmed)
        self.accountEmail = trimmed
    }

    // MARK: - Sign in with Apple
    //
    // Signs the user in with Apple via a verified OIDC id token. This gives the
    // account a durable identity (so Pro/progress survive reinstalls and reach
    // the web). Note: if the user redeemed a code while purely anonymous and
    // then signs in to a *different* existing Apple-backed account, that grant
    // stays on the anonymous id — email linking (above) is the id-preserving
    // path. For most users who sign in early this is a non-issue.

    @ObservationIgnored private var appleSignInNonce: String?

    /// Configure the Apple authorization request (attach a hashed nonce + scopes).
    /// Call from `SignInWithAppleButton`'s `onRequest`.
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        appleSignInNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    /// Handle the result from `SignInWithAppleButton`'s `onCompletion`.
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        guard case let .success(authorization) = result,
              let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              let nonce = appleSignInNonce
        else {
            print("⚠️ Apple sign-in: missing credential or nonce")
            return
        }

        do {
            try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            if let session = supabase.auth.currentSession {
                await handleSignedIn(user: session.user)
            }
        } catch {
            print("⚠️ Apple sign-in error: \(error.localizedDescription)")
        }
        appleSignInNonce = nil
    }

    // MARK: - Sharing

    /// Text to share when inviting friends. Uses the custom deep-link scheme;
    /// swap in a universal https link once the web app exists.
    var inviteShareText: String? {
        guard let code = referralCode else { return nil }
        return """
        Join me on Rounds — the daily medical case game. \
        Use my invite code \(code) to unlock Rounds Pro free: rounds://invite/\(code)
        """
    }

    // MARK: - Nonce helpers (Sign in with Apple)

    nonisolated private static func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status == errSecSuccess, random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    nonisolated private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Backend response types
//
// File-scope (non-isolated) so their Decodable conformance is usable from the
// SDK's background decoding, per Swift 6 concurrency rules.

nonisolated private struct AccountStatusResponse: Decodable {
    let referral_code: String?
    let pro_source: String
    let is_pro: Bool
    let invites_used: Int
    let invites_remaining: Int
    let max_referrals: Int
}

nonisolated private struct RedeemCodeResponse: Decodable {
    let status: String?
    let source: String?
}
