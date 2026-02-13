//
//  CountryData.swift
//  Rounds
//
//  Country database for international student support
//

import Foundation

// MARK: - Country Model

struct Country: Identifiable, Codable, Hashable {
    let code: String      // ISO 3166-1 alpha-2
    let name: String
    let flag: String      // Emoji flag

    var id: String { code }

    var displayName: String {
        "\(flag) \(name)"
    }
}

// MARK: - Country Database

enum CountryDatabase {

    /// All countries (excluding US since US students use state-based flow)
    static let allCountries: [Country] = [
        // Major English-speaking countries (prioritized)
        Country(code: "CA", name: "Canada", flag: "🇨🇦"),
        Country(code: "GB", name: "United Kingdom", flag: "🇬🇧"),
        Country(code: "AU", name: "Australia", flag: "🇦🇺"),
        Country(code: "IE", name: "Ireland", flag: "🇮🇪"),
        Country(code: "NZ", name: "New Zealand", flag: "🇳🇿"),

        // Caribbean medical schools (popular for US students)
        Country(code: "GD", name: "Grenada", flag: "🇬🇩"),
        Country(code: "DM", name: "Dominica", flag: "🇩🇲"),
        Country(code: "KN", name: "Saint Kitts and Nevis", flag: "🇰🇳"),
        Country(code: "LC", name: "Saint Lucia", flag: "🇱🇨"),
        Country(code: "BB", name: "Barbados", flag: "🇧🇧"),
        Country(code: "JM", name: "Jamaica", flag: "🇯🇲"),
        Country(code: "CW", name: "Curaçao", flag: "🇨🇼"),
        Country(code: "AW", name: "Aruba", flag: "🇦🇼"),
        Country(code: "AN", name: "Netherlands Antilles", flag: "🇧🇶"),

        // Europe
        Country(code: "DE", name: "Germany", flag: "🇩🇪"),
        Country(code: "FR", name: "France", flag: "🇫🇷"),
        Country(code: "IT", name: "Italy", flag: "🇮🇹"),
        Country(code: "ES", name: "Spain", flag: "🇪🇸"),
        Country(code: "PT", name: "Portugal", flag: "🇵🇹"),
        Country(code: "NL", name: "Netherlands", flag: "🇳🇱"),
        Country(code: "BE", name: "Belgium", flag: "🇧🇪"),
        Country(code: "CH", name: "Switzerland", flag: "🇨🇭"),
        Country(code: "AT", name: "Austria", flag: "🇦🇹"),
        Country(code: "SE", name: "Sweden", flag: "🇸🇪"),
        Country(code: "NO", name: "Norway", flag: "🇳🇴"),
        Country(code: "DK", name: "Denmark", flag: "🇩🇰"),
        Country(code: "FI", name: "Finland", flag: "🇫🇮"),
        Country(code: "PL", name: "Poland", flag: "🇵🇱"),
        Country(code: "CZ", name: "Czech Republic", flag: "🇨🇿"),
        Country(code: "HU", name: "Hungary", flag: "🇭🇺"),
        Country(code: "RO", name: "Romania", flag: "🇷🇴"),
        Country(code: "BG", name: "Bulgaria", flag: "🇧🇬"),
        Country(code: "GR", name: "Greece", flag: "🇬🇷"),
        Country(code: "SK", name: "Slovakia", flag: "🇸🇰"),
        Country(code: "HR", name: "Croatia", flag: "🇭🇷"),
        Country(code: "SI", name: "Slovenia", flag: "🇸🇮"),
        Country(code: "RS", name: "Serbia", flag: "🇷🇸"),
        Country(code: "UA", name: "Ukraine", flag: "🇺🇦"),
        Country(code: "RU", name: "Russia", flag: "🇷🇺"),
        Country(code: "LT", name: "Lithuania", flag: "🇱🇹"),
        Country(code: "LV", name: "Latvia", flag: "🇱🇻"),
        Country(code: "EE", name: "Estonia", flag: "🇪🇪"),
        Country(code: "MT", name: "Malta", flag: "🇲🇹"),
        Country(code: "CY", name: "Cyprus", flag: "🇨🇾"),
        Country(code: "IS", name: "Iceland", flag: "🇮🇸"),
        Country(code: "LU", name: "Luxembourg", flag: "🇱🇺"),

        // Asia
        Country(code: "IN", name: "India", flag: "🇮🇳"),
        Country(code: "CN", name: "China", flag: "🇨🇳"),
        Country(code: "JP", name: "Japan", flag: "🇯🇵"),
        Country(code: "KR", name: "South Korea", flag: "🇰🇷"),
        Country(code: "TW", name: "Taiwan", flag: "🇹🇼"),
        Country(code: "HK", name: "Hong Kong", flag: "🇭🇰"),
        Country(code: "SG", name: "Singapore", flag: "🇸🇬"),
        Country(code: "MY", name: "Malaysia", flag: "🇲🇾"),
        Country(code: "TH", name: "Thailand", flag: "🇹🇭"),
        Country(code: "VN", name: "Vietnam", flag: "🇻🇳"),
        Country(code: "PH", name: "Philippines", flag: "🇵🇭"),
        Country(code: "ID", name: "Indonesia", flag: "🇮🇩"),
        Country(code: "PK", name: "Pakistan", flag: "🇵🇰"),
        Country(code: "BD", name: "Bangladesh", flag: "🇧🇩"),
        Country(code: "LK", name: "Sri Lanka", flag: "🇱🇰"),
        Country(code: "NP", name: "Nepal", flag: "🇳🇵"),

        // Middle East
        Country(code: "IL", name: "Israel", flag: "🇮🇱"),
        Country(code: "AE", name: "United Arab Emirates", flag: "🇦🇪"),
        Country(code: "SA", name: "Saudi Arabia", flag: "🇸🇦"),
        Country(code: "QA", name: "Qatar", flag: "🇶🇦"),
        Country(code: "KW", name: "Kuwait", flag: "🇰🇼"),
        Country(code: "BH", name: "Bahrain", flag: "🇧🇭"),
        Country(code: "OM", name: "Oman", flag: "🇴🇲"),
        Country(code: "JO", name: "Jordan", flag: "🇯🇴"),
        Country(code: "LB", name: "Lebanon", flag: "🇱🇧"),
        Country(code: "TR", name: "Turkey", flag: "🇹🇷"),
        Country(code: "IR", name: "Iran", flag: "🇮🇷"),
        Country(code: "IQ", name: "Iraq", flag: "🇮🇶"),

        // Africa
        Country(code: "ZA", name: "South Africa", flag: "🇿🇦"),
        Country(code: "EG", name: "Egypt", flag: "🇪🇬"),
        Country(code: "NG", name: "Nigeria", flag: "🇳🇬"),
        Country(code: "KE", name: "Kenya", flag: "🇰🇪"),
        Country(code: "GH", name: "Ghana", flag: "🇬🇭"),
        Country(code: "MA", name: "Morocco", flag: "🇲🇦"),
        Country(code: "TN", name: "Tunisia", flag: "🇹🇳"),
        Country(code: "DZ", name: "Algeria", flag: "🇩🇿"),
        Country(code: "ET", name: "Ethiopia", flag: "🇪🇹"),
        Country(code: "TZ", name: "Tanzania", flag: "🇹🇿"),
        Country(code: "UG", name: "Uganda", flag: "🇺🇬"),
        Country(code: "ZW", name: "Zimbabwe", flag: "🇿🇼"),
        Country(code: "SN", name: "Senegal", flag: "🇸🇳"),
        Country(code: "CM", name: "Cameroon", flag: "🇨🇲"),
        Country(code: "CI", name: "Côte d'Ivoire", flag: "🇨🇮"),

        // Americas (non-US)
        Country(code: "MX", name: "Mexico", flag: "🇲🇽"),
        Country(code: "BR", name: "Brazil", flag: "🇧🇷"),
        Country(code: "AR", name: "Argentina", flag: "🇦🇷"),
        Country(code: "CO", name: "Colombia", flag: "🇨🇴"),
        Country(code: "CL", name: "Chile", flag: "🇨🇱"),
        Country(code: "PE", name: "Peru", flag: "🇵🇪"),
        Country(code: "VE", name: "Venezuela", flag: "🇻🇪"),
        Country(code: "EC", name: "Ecuador", flag: "🇪🇨"),
        Country(code: "GT", name: "Guatemala", flag: "🇬🇹"),
        Country(code: "CR", name: "Costa Rica", flag: "🇨🇷"),
        Country(code: "PA", name: "Panama", flag: "🇵🇦"),
        Country(code: "DO", name: "Dominican Republic", flag: "🇩🇴"),
        Country(code: "TT", name: "Trinidad and Tobago", flag: "🇹🇹"),
        Country(code: "CU", name: "Cuba", flag: "🇨🇺"),
        Country(code: "HT", name: "Haiti", flag: "🇭🇹"),
        Country(code: "PR", name: "Puerto Rico", flag: "🇵🇷"),

        // Oceania
        Country(code: "FJ", name: "Fiji", flag: "🇫🇯"),
        Country(code: "PG", name: "Papua New Guinea", flag: "🇵🇬"),
        Country(code: "WS", name: "Samoa", flag: "🇼🇸"),
        Country(code: "TO", name: "Tonga", flag: "🇹🇴"),
        Country(code: "VU", name: "Vanuatu", flag: "🇻🇺")
    ]

    /// Countries sorted alphabetically by name
    static var sortedByName: [Country] {
        allCountries.sorted { $0.name < $1.name }
    }

    /// Search countries by name
    static func search(_ query: String) -> [Country] {
        guard !query.isEmpty else { return sortedByName }
        let lowercased = query.lowercased()
        return sortedByName.filter { country in
            country.name.lowercased().contains(lowercased) ||
            country.code.lowercased() == lowercased
        }
    }

    /// Find country by code
    static func country(withCode code: String) -> Country? {
        allCountries.first { $0.code == code }
    }

    /// Popular countries shown at top of picker (English-speaking + Caribbean med schools)
    static var popularCountries: [Country] {
        let popularCodes = ["CA", "GB", "AU", "IE", "GD", "DM", "IN", "NG", "PH"]
        return popularCodes.compactMap { code in
            allCountries.first { $0.code == code }
        }
    }
}
