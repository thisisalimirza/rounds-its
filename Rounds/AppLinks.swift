//
//  AppLinks.swift
//  Rounds
//
//  Central place for outward-facing links (App Store, website, legal). Keeping
//  these in one spot avoids hard-coded URLs scattered across the app — and,
//  more importantly, avoids the class of bug where Terms and Privacy silently
//  point at the same page.
//
//  App Review note: Guideline 3.1.2 requires an app offering auto-renewable
//  subscriptions to expose a functional Terms of Use (EULA) link. `termsOfUse`
//  below is that link. Do not point it at a marketing page.
//

import Foundation

/// Build-level feature switches.
enum AppFeatures {
    /// Whether "Sign in with Apple" is offered as an account-linking option.
    ///
    /// Temporarily off. Apple sign-in only exists on iOS, so an account created
    /// with it cannot be reached from the web — and with Hide My Email the
    /// address is a private relay, so emailing that user a sign-in link doesn't
    /// reach them either. Rather than ship a half-supported path, accounts are
    /// email-only for now: one identity that works on iOS, the web, and later
    /// Android.
    ///
    /// Safe to flip back on once Sign in with Apple is configured on the web
    /// (Services ID + domain verification + key in Supabase). The Swift plumbing
    /// — `AccountManager.configureAppleRequest` and `handleAppleSignIn`, and the
    /// entitlement — is deliberately left in place so re-enabling is one line.
    ///
    /// Guideline 4.8 does not require Sign in with Apple here: it only applies
    /// when an app offers *third-party* login. Email-only is first-party.
    static let signInWithAppleEnabled = false
}

enum AppLinks {
    // MARK: - Marketing

    /// The App Store numeric id for Rounds. Everything below derives from this,
    /// so there is exactly one place to change it.
    ///
    /// History: share text in ShareResultView and LeaderboardView previously
    /// hard-coded id6740487567 while this file used id6756315417. Only one can
    /// be the live listing, so every share and invite sent from those screens —
    /// the app's main organic growth loop — pointed somewhere wrong. Do not
    /// reintroduce a literal store id anywhere else.
    static let appStoreID = "6756315417"

    /// Public App Store listing for Rounds. Used in invite messages so a friend
    /// who doesn't have the app yet can install it, then redeem the code.
    static let appStoreURL = "https://apps.apple.com/us/app/rounds-step-1/id\(appStoreID)"

    /// Short form for share sheets and message bodies, where the full localized
    /// slug URL is unwieldy. Resolves to the same listing.
    static let appStoreShortURL = "https://apps.apple.com/app/id\(appStoreID)"

    /// Bare-domain form for inline prose ("New here? apps.apple.com/…"), where a
    /// scheme prefix reads as noise. Still auto-links in iMessage and most apps.
    static let appStoreDisplayURL = "apps.apple.com/app/id\(appStoreID)"

    /// Marketing site root.
    static let website = "https://getrounds.app"

    /// Parent company.
    static let company = "https://braskgroup.com"

    // MARK: - Legal

    /// Terms of Service / EULA. Referenced by the paywall and Settings → About.
    static let termsOfUse = "https://getrounds.app/terms"

    /// Privacy Policy. Must match the Privacy Policy URL set in App Store Connect.
    static let privacyPolicy = "https://getrounds.app/privacy"

    // MARK: - Convenience

    /// Non-optional `URL` accessors. Every string above is a compile-time
    /// literal we control, so force-unwrapping here is safe and keeps call
    /// sites free of `URL(string:)!` noise.
    static var appStore: URL { URL(string: appStoreURL)! }
    static var websiteURL: URL { URL(string: website)! }
    static var companyURL: URL { URL(string: company)! }
    static var terms: URL { URL(string: termsOfUse)! }
    static var privacy: URL { URL(string: privacyPolicy)! }
}
