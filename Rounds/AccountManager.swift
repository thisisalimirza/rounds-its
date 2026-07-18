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

    // Internal (not private) so other backend-facing services — e.g. the
    // feedback / feature-request board — can reuse the same authenticated
    // anonymous session instead of spinning up a second client.
    let supabase = SupabaseClient(
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

    // MARK: - "Secure your account" nudge (one-time)

    private static let securePromptedKey = "hasPromptedSecureAccount"

    /// True when we should gently nudge the user to link email/Apple: they're
    /// still anonymous and we haven't nudged them before.
    var shouldOfferAccountSecuring: Bool {
        isAnonymousAccount && !UserDefaults.standard.bool(forKey: Self.securePromptedKey)
    }

    /// Records that we've shown the secure-account nudge (so it never nags again).
    func markAccountSecuringPrompted() {
        UserDefaults.standard.set(true, forKey: Self.securePromptedKey)
    }

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

    // MARK: - Differential diagnosis (Claude, via the `ddx` edge function)

    /// Sends free-text clinical findings to the `ddx` edge function, which calls
    /// Claude server-side (the API key lives as a Supabase secret, never in the
    /// app) and returns a structured differential. The authenticated client
    /// attaches the user's JWT automatically, so the function can gate on a
    /// signed-in user.
    func requestDifferential(findings: String, context: String? = nil) async throws -> DifferentialResult {
        let ctx = context?.trimmingCharacters(in: .whitespacesAndNewlines)
        return try await supabase.functions.invoke(
            "ddx",
            options: .init(body: DifferentialRequest(
                findings: findings.trimmingCharacters(in: .whitespacesAndNewlines),
                context: (ctx?.isEmpty ?? true) ? nil : ctx
            ))
        )
    }

    // MARK: - Study plan (Claude, via the `study-plan` edge function)

    /// Sends the user's aggregated weak spots to the `study-plan` edge function,
    /// which calls Claude server-side and returns a targeted, teaching-rich plan.
    func requestStudyPlan(weakSpots: [StudyWeakSpot], practiced: [StudyPracticed]) async throws -> StudyPlanResult {
        return try await supabase.functions.invoke(
            "study-plan",
            options: .init(body: StudyPlanRequest(weakSpots: weakSpots, practiced: practiced))
        )
    }

    // MARK: - Illness scripts (globally cached; Claude via `illness-script`)

    /// Fetch (or, on the first global request, generate) the illness script for
    /// a condition. `reason` = "miss" attributes the request to a missed case
    /// (feeds the global difficulty counter). Served from the shared cache when
    /// available, so repeat requests across users cost no API call.
    func illnessScript(condition: String, reason: String = "review") async throws -> IllnessScript {
        return try await supabase.functions.invoke(
            "illness-script",
            options: .init(body: IllnessScriptRequest(condition: condition, reason: reason))
        )
    }

    /// The comprehensive library of already-generated scripts, most-missed first.
    func fetchIllnessLibrary(limit: Int = 300) async throws -> [IllnessScriptSummary] {
        return try await supabase
            .from("illness_scripts")
            .select("condition, condition_key, system, one_liner, miss_count")
            .order("miss_count", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    // MARK: - Feedback & feature requests (Supabase)

    private static var appVersionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    /// Submit private feedback / a bug report. Insert-only; you read these in the
    /// Supabase dashboard.
    func submitFeedback(category: String, message: String) async throws {
        struct Row: Encodable { let category: String; let message: String; let app_version: String }
        try await supabase.from("feedback")
            .insert(Row(category: category,
                        message: message.trimmingCharacters(in: .whitespacesAndNewlines),
                        app_version: Self.appVersionString))
            .execute()
    }

    /// Load the public feature-request board plus this user's own votes.
    func fetchFeatureRequests() async throws -> (requests: [FeatureRequest], myVotes: [String: Int]) {
        let requests: [FeatureRequest] = try await supabase
            .from("feature_requests")
            .select("id,title,detail,status,upvotes,downvotes,score")
            .order("score", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        let voteRows: [FeatureVoteRow] = try await supabase
            .from("feature_votes")
            .select("request_id,value")
            .execute()
            .value
        var votes: [String: Int] = [:]
        for row in voteRows { votes[row.request_id] = row.value }
        return (requests, votes)
    }

    /// Submit a new idea to the public board.
    func submitFeatureRequest(title: String, detail: String) async throws {
        struct Row: Encodable { let title: String; let detail: String? }
        let d = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        try await supabase.from("feature_requests")
            .insert(Row(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                        detail: d.isEmpty ? nil : d))
            .execute()
    }

    /// Cast (or toggle off) a vote. Pass the user's current vote for this
    /// request so tapping the same direction again clears it.
    func voteFeatureRequest(id: String, value: Int, current: Int?) async throws {
        if current == value {
            try await supabase.from("feature_votes").delete().eq("request_id", value: id).execute()
        } else {
            guard let uid = userID else { return }
            struct Row: Encodable { let request_id: String; let user_id: String; let value: Int }
            try await supabase.from("feature_votes")
                .upsert(Row(request_id: id, user_id: uid, value: value), onConflict: "request_id,user_id")
                .execute()
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

    /// Text to share when inviting friends. Leads with the App Store link so a
    /// friend who doesn't have Rounds yet can install it first, then redeem the
    /// code — the old deep link did nothing without the app installed.
    var inviteShareText: String? {
        guard let code = referralCode else { return nil }
        return """
        Join me on Rounds — the daily medical case game for med students.

        1. Download the app: \(AppLinks.appStoreURL)
        2. Open Rounds → Account → Redeem, and enter my code: \(code)

        That unlocks Rounds Pro for you, free. 🎉
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

// MARK: - Differential diagnosis types

nonisolated struct DifferentialRequest: Encodable {
    let findings: String
    let context: String?
}

/// The structured differential returned by the `ddx` edge function. Keys match
/// the JSON Schema the function constrains Claude to (camelCase, no key mapping).
nonisolated struct DifferentialResult: Codable, Sendable {
    let summary: String
    let chiefComplaint: String
    let system: String
    let differential: [DifferentialDx]
    let redFlags: [String]
}

nonisolated struct DifferentialDx: Codable, Sendable, Identifiable {
    var id: String { diagnosis }
    let diagnosis: String
    let likelihood: String            // "high" | "moderate" | "low"
    let cantMiss: Bool
    let supporting: [String]          // findings the student mentioned that support this dx
    let toConfirm: [String]           // next steps to raise suspicion / confirm this dx
    let rationale: String
}

// MARK: - Study plan types

nonisolated struct StudyWeakSpot: Encodable, Sendable {
    let topic: String
    let item: String
    let count: Int
    let sources: [String]
}

nonisolated struct StudyPracticed: Encodable, Sendable {
    let complaint: String
    let system: String
    let count: Int
}

nonisolated struct StudyPlanRequest: Encodable {
    let weakSpots: [StudyWeakSpot]
    let practiced: [StudyPracticed]
}

nonisolated struct StudyPlanResult: Codable, Sendable {
    let headline: String
    let focusAreas: [StudyFocusArea]
}

nonisolated struct StudyFocusArea: Codable, Sendable, Identifiable {
    var id: String { area }
    let area: String
    let priority: String          // high | medium | low
    let summary: String
    let keyFacts: [String]
    let cantMiss: [String]
    let review: [String]
}

// MARK: - Illness script types

nonisolated struct IllnessScriptRequest: Encodable {
    let condition: String
    let reason: String
}

nonisolated struct IllnessScript: Codable, Sendable {
    let condition: String
    let system: String
    let definition: String
    let predisposing: [String]
    let pathophysiology: [String]
    let presentation: [String]
    let diagnostics: [String]
    let management: [String]
    let pivots: [IllnessPivot]
}

nonisolated struct IllnessPivot: Codable, Sendable, Identifiable {
    var id: String { condition }
    let condition: String
    let distinguisher: String
}

nonisolated struct IllnessScriptSummary: Codable, Sendable, Identifiable {
    var id: String { conditionKey }
    let condition: String
    let conditionKey: String
    let system: String?
    let oneLiner: String?
    let missCount: Int

    enum CodingKeys: String, CodingKey {
        case condition
        case conditionKey = "condition_key"
        case system
        case oneLiner = "one_liner"
        case missCount = "miss_count"
    }
}
