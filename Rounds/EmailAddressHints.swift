//
//  EmailAddressHints.swift
//  Rounds
//
//  Light checks for the account gate. Any real address is accepted — residents,
//  graduates, and students outside the US do not all have a .edu inbox, and
//  school addresses expire. A school-looking domain is acknowledged; a personal
//  one is allowed; a obvious typo is offered as a correction, not a block.
//

import Foundation

nonisolated enum EmailAddressHints {
    static let personalDomains: Set<String> = [
        "gmail.com", "googlemail.com", "icloud.com", "me.com", "mac.com",
        "yahoo.com", "hotmail.com", "outlook.com", "live.com", "msn.com",
        "aol.com", "proton.me", "protonmail.com", "pm.me"
    ]

    /// domain-as-typed -> domain we think they meant
    static let typos: [String: String] = [
        "gmial.com": "gmail.com",
        "gmal.com": "gmail.com",
        "gamil.com": "gmail.com",
        "gnail.com": "gmail.com",
        "gmail.co": "gmail.com",
        "gmail.con": "gmail.com",
        "gmai.com": "gmail.com",
        "hotmal.com": "hotmail.com",
        "hotmai.com": "hotmail.com",
        "hotmail.co": "hotmail.com",
        "outlok.com": "outlook.com",
        "outloo.com": "outlook.com",
        "outlook.co": "outlook.com",
        "yaho.com": "yahoo.com",
        "yahooo.com": "yahoo.com",
        "yahoo.co": "yahoo.com",
        "icloud.co": "icloud.com",
        "icoud.com": "icloud.com"
    ]

    static func normalized(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func isValid(_ raw: String) -> Bool {
        let text = normalized(raw)
        guard let at = text.firstIndex(of: "@") else { return false }
        let local = text[..<at]
        let domain = text[text.index(after: at)...]
        return !local.isEmpty
            && domain.contains(".")
            && !domain.hasPrefix(".")
            && !domain.hasSuffix(".")
            && !domain.contains(" ")
    }

    static func domain(of raw: String) -> String? {
        let text = normalized(raw)
        guard let at = text.lastIndex(of: "@") else { return nil }
        let domain = String(text[text.index(after: at)...])
        return domain.isEmpty ? nil : domain
    }

    static func isSchoolDomain(_ domain: String) -> Bool {
        let value = domain.lowercased()
        let suffixes = [".edu", ".edu.au", ".edu.mx", ".edu.sg", ".ac.uk", ".ac.nz", ".ac.za"]
        return suffixes.contains { value.hasSuffix($0) }
    }

    static func isPersonalDomain(_ domain: String) -> Bool {
        personalDomains.contains(domain.lowercased())
    }

    /// A full address with the typo repaired, when we recognise one.
    static func suggestion(for raw: String) -> String? {
        guard let domain = domain(of: raw), let fixed = typos[domain.lowercased()] else { return nil }
        let text = normalized(raw)
        guard let at = text.lastIndex(of: "@") else { return nil }
        return String(text[..<at]) + "@" + fixed
    }

    enum DomainTone: Equatable, Sendable {
        case school
        case personal
        case other
        case invalid
    }

    static func tone(of raw: String) -> DomainTone {
        guard isValid(raw), let domain = domain(of: raw) else { return .invalid }
        if isSchoolDomain(domain) { return .school }
        if isPersonalDomain(domain) { return .personal }
        return .other
    }
}
