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

enum AppLinks {
    // MARK: - Marketing

    /// Public App Store listing for Rounds. Used in invite messages so a friend
    /// who doesn't have the app yet can install it, then redeem the code.
    static let appStoreURL = "https://apps.apple.com/us/app/rounds-step-1/id6756315417"

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
