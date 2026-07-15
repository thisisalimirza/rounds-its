//
//  ClinicalCalculators.swift
//  Rounds
//
//  A library of common clinical calculators for the Practice tab.
//  Each calculator leads with a short "what it's for" tagline and teaches
//  *when* to use it — depth is one tap away to avoid overwhelming the screen.
//

import SwiftUI

// MARK: - Result severity (drives color)

enum CalcSeverity {
    case info, low, moderate, high

    var color: Color {
        switch self {
        case .info: return .blue
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Input fields

struct CalcField: Identifiable {
    struct Option: Identifiable, Hashable {
        let id = UUID()
        let label: String
        let value: Double
    }

    enum Kind {
        case toggle(points: Double)       // off = 0, on = points
        case options([Option])            // pick one; contributes its value
        case number(unit: String)         // free numeric input
    }

    let id: String
    let label: String
    var detail: String? = nil
    let kind: Kind

    var isNumber: Bool { if case .number = kind { return true }; return false }
}

// MARK: - Result

struct CalcResult {
    let value: String
    let interpretation: String
    let severity: CalcSeverity
}

// MARK: - Category

enum CalcCategory: String, CaseIterable {
    case cardiology = "Cardiology"
    case mentalHealth = "Mental Health"
    case gi = "GI & Liver"
    case pulmonary = "Pulmonary & ID"
    case clots = "Clots & Bleeding"
    case kidneyLabs = "Kidney & Labs"
    case general = "General"

    var icon: String {
        switch self {
        case .cardiology: return "heart.fill"
        case .mentalHealth: return "brain.head.profile"
        case .gi: return "pills.fill"
        case .pulmonary: return "lungs.fill"
        case .clots: return "drop.fill"
        case .kidneyLabs: return "flask.fill"
        case .general: return "figure.stand"
        }
    }
}

// MARK: - Calculator

struct ClinicalCalculator: Identifiable {
    let id: String
    let name: String
    let abbreviation: String
    /// Short "what it's for" line shown in the browser and as the default header.
    let tagline: String
    let category: CalcCategory
    let keywords: [String]
    /// The teaching — the *when* and *why* — shown when the user expands "Why & when".
    let whenToUse: String
    var pearl: String? = nil
    var comingSoon: Bool = false
    var fields: [CalcField] = []
    var compute: (([String: Double]) -> CalcResult)? = nil

    func matches(_ query: String) -> Bool {
        let q = query.lowercased()
        return name.lowercased().contains(q)
            || abbreviation.lowercased().contains(q)
            || tagline.lowercased().contains(q)
            || category.rawValue.lowercased().contains(q)
            || keywords.contains { $0.lowercased().contains(q) }
    }
}

// MARK: - Library

enum CalculatorLibrary {

    static let disclaimer = "For education only. Confirm results and any clinical decision with a licensed clinician and primary sources."

    static var all: [ClinicalCalculator] { cardiology + mentalHealth + gi + pulmonary + clots + kidneyLabs + general }

    static func grouped(matching query: String) -> [(category: CalcCategory, items: [ClinicalCalculator])] {
        let filtered = query.isEmpty ? all : all.filter { $0.matches(query) }
        return CalcCategory.allCases.compactMap { category in
            let items = filtered.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    private static func sum(_ v: [String: Double]) -> Double { v.values.reduce(0, +) }
    private static func on(_ v: [String: Double], _ key: String) -> Bool { (v[key] ?? 0) != 0 }
    private static func clamp(_ x: Double, _ lo: Double, _ hi: Double) -> Double { min(max(x, lo), hi) }

    private static let yesNoOptions: [CalcField.Option] = [.init(label: "No", value: 0), .init(label: "Yes", value: 1)]

    // MARK: Cardiology

    private static let cardiology: [ClinicalCalculator] = [
        ClinicalCalculator(
            id: "chadsvasc", name: "CHA₂DS₂-VASc Score", abbreviation: "CHA2DS2-VASc",
            tagline: "Stroke risk in atrial fibrillation",
            category: .cardiology,
            keywords: ["afib", "atrial fibrillation", "stroke", "anticoagulation", "doac", "warfarin"],
            whenToUse: "The moment you see AFib on a problem list — it estimates yearly stroke risk and tells you whether to start an anticoagulant.",
            pearl: "Men ≥1 and women ≥2 generally warrant anticoagulation; a woman scoring 1 for sex alone is still low risk.",
            fields: [
                .init(id: "chf", label: "CHF / LV dysfunction", kind: .toggle(points: 1)),
                .init(id: "htn", label: "Hypertension", kind: .toggle(points: 1)),
                .init(id: "age", label: "Age", kind: .options([.init(label: "< 65", value: 0), .init(label: "65–74", value: 1), .init(label: "≥ 75", value: 2)])),
                .init(id: "dm", label: "Diabetes", kind: .toggle(points: 1)),
                .init(id: "stroke", label: "Prior stroke / TIA / thromboembolism", kind: .toggle(points: 2)),
                .init(id: "vasc", label: "Vascular disease (MI, PAD, plaque)", kind: .toggle(points: 1)),
                .init(id: "sex", label: "Sex", kind: .options([.init(label: "Male", value: 0), .init(label: "Female", value: 1)]))
            ],
            compute: { v in
                let s = Int(sum(v))
                let sev: CalcSeverity = s == 0 ? .low : (s == 1 ? .moderate : .high)
                let interp = s == 0 ? "Low risk — anticoagulation generally not needed."
                    : (s == 1 ? "Low–moderate — consider anticoagulation (individualize)."
                              : "Elevated risk — oral anticoagulation recommended.")
                return CalcResult(value: "Score: \(s)", interpretation: interp, severity: sev)
            }
        ),
        ClinicalCalculator(
            id: "hasbled", name: "HAS-BLED Score", abbreviation: "HAS-BLED",
            tagline: "Bleeding risk on anticoagulation",
            category: .cardiology,
            keywords: ["bleeding", "anticoagulation", "afib", "warfarin"],
            whenToUse: "Alongside CHA₂DS₂-VASc when starting anticoagulation — not to withhold it, but to find and fix modifiable bleeding risks.",
            pearl: "≥3 = high risk. Address reversible factors (BP, labile INR, alcohol, interacting drugs) rather than avoiding anticoagulation.",
            fields: [
                .init(id: "htn", label: "Uncontrolled HTN (SBP > 160)", kind: .toggle(points: 1)),
                .init(id: "renal", label: "Abnormal renal function", kind: .toggle(points: 1)),
                .init(id: "liver", label: "Abnormal liver function", kind: .toggle(points: 1)),
                .init(id: "stroke", label: "Prior stroke", kind: .toggle(points: 1)),
                .init(id: "bleed", label: "Bleeding history / predisposition", kind: .toggle(points: 1)),
                .init(id: "inr", label: "Labile INR", kind: .toggle(points: 1)),
                .init(id: "elderly", label: "Elderly (> 65)", kind: .toggle(points: 1)),
                .init(id: "drugs", label: "Antiplatelet / NSAID use", kind: .toggle(points: 1)),
                .init(id: "alcohol", label: "Alcohol ≥ 8 drinks/week", kind: .toggle(points: 1))
            ],
            compute: { v in
                let s = Int(sum(v))
                let sev: CalcSeverity = s >= 3 ? .high : (s == 2 ? .moderate : .low)
                return CalcResult(value: "Score: \(s)",
                                  interpretation: s >= 3 ? "High bleeding risk — address modifiable factors, monitor closely." : "Lower bleeding risk — reassess periodically.",
                                  severity: sev)
            }
        ),
        ClinicalCalculator(
            id: "ascvd", name: "ASCVD Risk (Pooled Cohort)", abbreviation: "ASCVD",
            tagline: "10-year heart attack / stroke risk",
            category: .cardiology,
            keywords: ["cholesterol", "statin", "prevention", "cardiovascular", "lipids", "risk"],
            whenToUse: "In adults 40–75 without known ASCVD, to guide statin therapy. Knowing it before your preceptor asks is a classic foresight moment on primary care.",
            pearl: "≥ 7.5% favors a statin discussion; 5–7.5% is borderline. The 2013 equations tend to over-estimate in contemporary populations.",
            fields: [
                .init(id: "sex", label: "Sex", kind: .options([.init(label: "Male", value: 0), .init(label: "Female", value: 1)])),
                .init(id: "race", label: "Race", kind: .options([.init(label: "White / Other", value: 0), .init(label: "African American", value: 1)])),
                .init(id: "age", label: "Age", kind: .number(unit: "years")),
                .init(id: "tc", label: "Total cholesterol", kind: .number(unit: "mg/dL")),
                .init(id: "hdl", label: "HDL cholesterol", kind: .number(unit: "mg/dL")),
                .init(id: "sbp", label: "Systolic BP", kind: .number(unit: "mmHg")),
                .init(id: "treated", label: "On BP medication", kind: .toggle(points: 1)),
                .init(id: "smoker", label: "Current smoker", kind: .toggle(points: 1)),
                .init(id: "dm", label: "Diabetes", kind: .toggle(points: 1))
            ],
            compute: { v in
                let female = (v["sex"] ?? 0) == 1
                let black = (v["race"] ?? 0) == 1
                let age = clamp(v["age"] ?? 0, 40, 79)
                let tc = clamp(v["tc"] ?? 0, 130, 320)
                let hdl = clamp(v["hdl"] ?? 0, 20, 100)
                let sbp = clamp(v["sbp"] ?? 0, 90, 200)
                let treated = on(v, "treated"), smoker = on(v, "smoker"), dm = on(v, "dm")
                let lnAge = log(age), lnTC = log(tc), lnHDL = log(hdl), lnSBP = log(sbp)

                var s = 0.0, s0 = 0.0, mean = 0.0
                if female && !black {
                    s = -29.799 * lnAge + 4.884 * lnAge * lnAge + 13.540 * lnTC - 3.114 * lnAge * lnTC
                        - 13.578 * lnHDL + 3.149 * lnAge * lnHDL
                        + (treated ? 2.019 : 1.957) * lnSBP
                        + (smoker ? 7.574 - 1.665 * lnAge : 0) + (dm ? 0.661 : 0)
                    s0 = 0.9665; mean = -29.18
                } else if female && black {
                    s = 17.114 * lnAge + 0.940 * lnTC - 18.920 * lnHDL + 4.475 * lnAge * lnHDL
                        + (treated ? 29.291 * lnSBP - 6.432 * lnAge * lnSBP : 27.820 * lnSBP - 6.087 * lnAge * lnSBP)
                        + (smoker ? 0.691 : 0) + (dm ? 0.874 : 0)
                    s0 = 0.9533; mean = 86.61
                } else if !female && !black {
                    s = 12.344 * lnAge + 11.853 * lnTC - 2.664 * lnAge * lnTC - 7.990 * lnHDL + 1.769 * lnAge * lnHDL
                        + (treated ? 1.797 : 1.764) * lnSBP
                        + (smoker ? 7.837 - 1.795 * lnAge : 0) + (dm ? 0.658 : 0)
                    s0 = 0.9144; mean = 61.18
                } else {
                    s = 2.469 * lnAge + 0.302 * lnTC - 0.307 * lnHDL
                        + (treated ? 1.916 : 1.809) * lnSBP
                        + (smoker ? 0.549 : 0) + (dm ? 0.645 : 0)
                    s0 = 0.8954; mean = 19.54
                }
                let risk = (1 - pow(s0, exp(s - mean))) * 100
                let sev: CalcSeverity = risk < 5 ? .low : (risk < 7.5 ? .moderate : .high)
                let band = risk < 5 ? "Low risk" : (risk < 7.5 ? "Borderline risk" : (risk < 20 ? "Intermediate risk" : "High risk"))
                return CalcResult(value: String(format: "%.1f%%", risk), interpretation: "\(band) · 10-year ASCVD", severity: sev)
            }
        ),
        ClinicalCalculator(
            id: "prevent", name: "PREVENT CVD Risk (AHA 2023)", abbreviation: "PREVENT",
            tagline: "10 & 30-year cardiovascular risk",
            category: .cardiology,
            keywords: ["cardiovascular", "kidney", "metabolic", "prevention", "statin", "risk"],
            whenToUse: "The newer AHA equations (adding kidney and metabolic factors, no race term), increasingly preferred over the older Pooled Cohort Equations.",
            comingSoon: true
        ),
        ClinicalCalculator(
            id: "map", name: "Mean Arterial Pressure", abbreviation: "MAP",
            tagline: "Perfusion pressure to organs",
            category: .cardiology,
            keywords: ["blood pressure", "perfusion", "shock", "sepsis"],
            whenToUse: "In shock, sepsis, or any critically ill patient — MAP ≥ 65 mmHg is the classic resuscitation target.",
            fields: [
                .init(id: "sbp", label: "Systolic BP", kind: .number(unit: "mmHg")),
                .init(id: "dbp", label: "Diastolic BP", kind: .number(unit: "mmHg"))
            ],
            compute: { v in
                let map = (v["dbp"] ?? 0) + ((v["sbp"] ?? 0) - (v["dbp"] ?? 0)) / 3
                return CalcResult(value: String(format: "%.0f mmHg", map),
                                  interpretation: map < 65 ? "Below the usual 65 mmHg target." : "At or above the 65 mmHg target.",
                                  severity: map < 65 ? .high : .low)
            }
        )
    ]

    // MARK: Mental Health

    private static let phqOptions: [CalcField.Option] = [
        .init(label: "Not at all", value: 0), .init(label: "Several days", value: 1),
        .init(label: "More than half the days", value: 2), .init(label: "Nearly every day", value: 3)
    ]

    private static let mentalHealth: [ClinicalCalculator] = [
        ClinicalCalculator(
            id: "phq9", name: "PHQ-9 Depression Scale", abbreviation: "PHQ-9",
            tagline: "Depression severity",
            category: .mentalHealth,
            keywords: ["depression", "mood", "screening", "phq"],
            whenToUse: "Any adult with low mood, fatigue, or anhedonia — it screens for and grades depression. A staple of primary care and annual visits.",
            pearl: "Item 9 screens suicidal ideation — any positive answer warrants a safety assessment regardless of total.",
            fields: [
                "Little interest or pleasure in doing things",
                "Feeling down, depressed, or hopeless",
                "Trouble sleeping or sleeping too much",
                "Feeling tired or low energy",
                "Poor appetite or overeating",
                "Feeling bad about yourself / like a failure",
                "Trouble concentrating",
                "Moving/speaking slowly, or being restless",
                "Thoughts of being better off dead or self-harm"
            ].enumerated().map { CalcField(id: "q\($0)", label: $1, kind: .options(phqOptions)) },
            compute: { v in
                let s = Int(sum(v))
                let (band, sev): (String, CalcSeverity)
                switch s {
                case 0...4: (band, sev) = ("Minimal depression.", .low)
                case 5...9: (band, sev) = ("Mild depression.", .low)
                case 10...14: (band, sev) = ("Moderate depression.", .moderate)
                case 15...19: (band, sev) = ("Moderately severe depression.", .high)
                default: (band, sev) = ("Severe depression.", .high)
                }
                let flag = (v["q8"] ?? 0) > 0 ? " ⚠️ Positive self-harm item — assess safety." : ""
                return CalcResult(value: "Score: \(s)", interpretation: band + flag, severity: sev)
            }
        ),
        ClinicalCalculator(
            id: "phq2", name: "PHQ-2 Depression Pre-Screen", abbreviation: "PHQ-2",
            tagline: "Rapid depression pre-screen",
            category: .mentalHealth,
            keywords: ["depression", "screening", "phq"],
            whenToUse: "A 2-question first pass on any visit; if positive, follow with the full PHQ-9.",
            pearl: "A score ≥ 3 is a positive screen — proceed to PHQ-9.",
            fields: [
                "Little interest or pleasure in doing things",
                "Feeling down, depressed, or hopeless"
            ].enumerated().map { CalcField(id: "q\($0)", label: $1, kind: .options(phqOptions)) },
            compute: { v in
                let s = Int(sum(v))
                return CalcResult(value: "Score: \(s)",
                                  interpretation: s >= 3 ? "Positive — administer the full PHQ-9." : "Negative screen.",
                                  severity: s >= 3 ? .moderate : .low)
            }
        ),
        ClinicalCalculator(
            id: "gad7", name: "GAD-7 Anxiety Scale", abbreviation: "GAD-7",
            tagline: "Anxiety severity",
            category: .mentalHealth,
            keywords: ["anxiety", "worry", "screening", "gad"],
            whenToUse: "For worry, restlessness, or somatic complaints — screens for and grades generalized anxiety. Pairs naturally with the PHQ-9.",
            fields: [
                "Feeling nervous, anxious, or on edge",
                "Not being able to stop or control worrying",
                "Worrying too much about different things",
                "Trouble relaxing",
                "Being so restless it's hard to sit still",
                "Becoming easily annoyed or irritable",
                "Feeling afraid as if something awful might happen"
            ].enumerated().map { CalcField(id: "q\($0)", label: $1, kind: .options(phqOptions)) },
            compute: { v in
                let s = Int(sum(v))
                let (band, sev): (String, CalcSeverity)
                switch s {
                case 0...4: (band, sev) = ("Minimal anxiety.", .low)
                case 5...9: (band, sev) = ("Mild anxiety.", .low)
                case 10...14: (band, sev) = ("Moderate anxiety.", .moderate)
                default: (band, sev) = ("Severe anxiety.", .high)
                }
                return CalcResult(value: "Score: \(s)", interpretation: band, severity: sev)
            }
        ),
        ClinicalCalculator(
            id: "gad2", name: "GAD-2 Anxiety Pre-Screen", abbreviation: "GAD-2",
            tagline: "Rapid anxiety pre-screen",
            category: .mentalHealth,
            keywords: ["anxiety", "screening", "gad"],
            whenToUse: "A 2-question first pass; if positive, follow with the full GAD-7.",
            pearl: "A score ≥ 3 is a positive screen.",
            fields: [
                "Feeling nervous, anxious, or on edge",
                "Not being able to stop or control worrying"
            ].enumerated().map { CalcField(id: "q\($0)", label: $1, kind: .options(phqOptions)) },
            compute: { v in
                let s = Int(sum(v))
                return CalcResult(value: "Score: \(s)",
                                  interpretation: s >= 3 ? "Positive — administer the full GAD-7." : "Negative screen.",
                                  severity: s >= 3 ? .moderate : .low)
            }
        ),
        ClinicalCalculator(
            id: "auditc", name: "AUDIT-C Alcohol Screen", abbreviation: "AUDIT-C",
            tagline: "Hazardous alcohol use",
            category: .mentalHealth,
            keywords: ["alcohol", "drinking", "substance", "screening", "audit"],
            whenToUse: "A quick, validated screen for hazardous drinking or alcohol use disorder at any routine visit.",
            pearl: "Positive at ≥ 4 for men and ≥ 3 for women.",
            fields: [
                .init(id: "freq", label: "How often do you have a drink?", kind: .options([
                    .init(label: "Never", value: 0), .init(label: "Monthly or less", value: 1),
                    .init(label: "2–4 times/month", value: 2), .init(label: "2–3 times/week", value: 3),
                    .init(label: "≥ 4 times/week", value: 4)])),
                .init(id: "amount", label: "Drinks on a typical drinking day", kind: .options([
                    .init(label: "1–2", value: 0), .init(label: "3–4", value: 1),
                    .init(label: "5–6", value: 2), .init(label: "7–9", value: 3), .init(label: "≥ 10", value: 4)])),
                .init(id: "binge", label: "How often ≥ 6 drinks on one occasion?", kind: .options([
                    .init(label: "Never", value: 0), .init(label: "< Monthly", value: 1),
                    .init(label: "Monthly", value: 2), .init(label: "Weekly", value: 3), .init(label: "Daily", value: 4)]))
            ],
            compute: { v in
                let s = Int(sum(v))
                return CalcResult(value: "Score: \(s)",
                                  interpretation: s >= 3 ? "Possible hazardous use (≥4 men / ≥3 women) — explore further." : "Low risk.",
                                  severity: s >= 4 ? .high : (s >= 3 ? .moderate : .low))
            }
        ),
        ClinicalCalculator(
            id: "cage", name: "CAGE Alcohol Questionnaire", abbreviation: "CAGE",
            tagline: "Alcohol use disorder screen",
            category: .mentalHealth,
            keywords: ["alcohol", "substance", "screening", "cage"],
            whenToUse: "A 4-question screen for problem drinking when the history raises concern.",
            pearl: "≥ 2 'yes' answers is clinically significant and warrants a fuller assessment.",
            fields: [
                .init(id: "c", label: "Felt you should Cut down?", kind: .toggle(points: 1)),
                .init(id: "a", label: "Annoyed by criticism of your drinking?", kind: .toggle(points: 1)),
                .init(id: "g", label: "Felt Guilty about drinking?", kind: .toggle(points: 1)),
                .init(id: "e", label: "Eye-opener drink in the morning?", kind: .toggle(points: 1))
            ],
            compute: { v in
                let s = Int(sum(v))
                return CalcResult(value: "Score: \(s)",
                                  interpretation: s >= 2 ? "Clinically significant — assess for alcohol use disorder." : "Lower likelihood.",
                                  severity: s >= 2 ? .high : .low)
            }
        )
    ]

    // MARK: GI & Liver

    private static let gi: [ClinicalCalculator] = [
        ClinicalCalculator(
            id: "fib4", name: "FIB-4 Fibrosis Index", abbreviation: "FIB-4",
            tagline: "Advanced liver fibrosis (non-invasive)",
            category: .gi,
            keywords: ["liver", "fibrosis", "nafld", "mash", "hepatitis", "cirrhosis"],
            whenToUse: "First-line for fatty liver or abnormal LFTs — uses only age, AST, ALT, platelets to decide who needs elastography or hepatology.",
            pearl: "Best validated ages 35–65. < 1.45 rules out advanced fibrosis; > 3.25 makes it likely.",
            fields: [
                .init(id: "age", label: "Age", kind: .number(unit: "years")),
                .init(id: "ast", label: "AST", kind: .number(unit: "U/L")),
                .init(id: "alt", label: "ALT", kind: .number(unit: "U/L")),
                .init(id: "plt", label: "Platelets", kind: .number(unit: "×10⁹/L"))
            ],
            compute: { v in
                let alt = max(v["alt"] ?? 0, 0.0001), plt = max(v["plt"] ?? 0, 0.0001)
                let fib4 = ((v["age"] ?? 0) * (v["ast"] ?? 0)) / (plt * alt.squareRoot())
                let sev: CalcSeverity = fib4 < 1.45 ? .low : (fib4 <= 3.25 ? .moderate : .high)
                let interp = fib4 < 1.45 ? "Advanced fibrosis unlikely." : (fib4 <= 3.25 ? "Indeterminate — consider FibroScan." : "Advanced fibrosis likely — refer to hepatology.")
                return CalcResult(value: String(format: "FIB-4: %.2f", fib4), interpretation: interp, severity: sev)
            }
        ),
        ClinicalCalculator(
            id: "meldna", name: "MELD-Na Score", abbreviation: "MELD-Na",
            tagline: "Liver disease severity & mortality",
            category: .gi,
            keywords: ["liver", "cirrhosis", "transplant", "mortality", "meld"],
            whenToUse: "Grades severity of chronic liver disease and prioritizes transplant listing; estimates short-term mortality.",
            pearl: "Higher = sicker. Labs are floored at 1.0; sodium is bounded 125–137.",
            fields: [
                .init(id: "bili", label: "Bilirubin", kind: .number(unit: "mg/dL")),
                .init(id: "inr", label: "INR", kind: .number(unit: "")),
                .init(id: "cr", label: "Creatinine", kind: .number(unit: "mg/dL")),
                .init(id: "na", label: "Sodium", kind: .number(unit: "mmol/L"))
            ],
            compute: { v in
                let bili = max(v["bili"] ?? 1, 1), inr = max(v["inr"] ?? 1, 1)
                let cr = min(max(v["cr"] ?? 1, 1), 4)
                let na = clamp(v["na"] ?? 137, 125, 137)
                let meld = 3.78 * log(bili) + 11.2 * log(inr) + 9.57 * log(cr) + 6.43
                let meldNa = meld + 1.32 * (137 - na) - (0.033 * meld * (137 - na))
                let score = Int(meldNa.rounded())
                let sev: CalcSeverity = score >= 30 ? .high : (score >= 20 ? .moderate : .low)
                return CalcResult(value: "MELD-Na: \(score)",
                                  interpretation: score >= 20 ? "Significant mortality risk — hepatology / transplant evaluation." : "Lower short-term mortality.",
                                  severity: sev)
            }
        )
    ]

    // MARK: Pulmonary & ID

    private static let pulmonary: [ClinicalCalculator] = [
        ClinicalCalculator(
            id: "curb65", name: "CURB-65 Pneumonia Severity", abbreviation: "CURB-65",
            tagline: "Pneumonia severity & disposition",
            category: .pulmonary,
            keywords: ["pneumonia", "cap", "admission", "sepsis"],
            whenToUse: "On presentation with community-acquired pneumonia — decides home vs admission.",
            pearl: "0–1 outpatient · 2 consider admission · ≥3 admit, consider ICU.",
            fields: [
                .init(id: "c", label: "New confusion", kind: .toggle(points: 1)),
                .init(id: "u", label: "BUN > 19 mg/dL (urea > 7)", kind: .toggle(points: 1)),
                .init(id: "r", label: "Respiratory rate ≥ 30", kind: .toggle(points: 1)),
                .init(id: "b", label: "SBP < 90 or DBP ≤ 60", kind: .toggle(points: 1)),
                .init(id: "age", label: "Age ≥ 65", kind: .toggle(points: 1))
            ],
            compute: { v in
                let s = Int(sum(v))
                let sev: CalcSeverity = s >= 3 ? .high : (s == 2 ? .moderate : .low)
                let interp = s <= 1 ? "Low — outpatient often appropriate." : (s == 2 ? "Moderate — consider admission." : "High — admit; consider ICU.")
                return CalcResult(value: "Score: \(s)", interpretation: interp, severity: sev)
            }
        ),
        ClinicalCalculator(
            id: "centor", name: "Centor (McIsaac) Score", abbreviation: "Centor",
            tagline: "Strep throat likelihood",
            category: .pulmonary,
            keywords: ["pharyngitis", "strep", "sore throat", "antibiotics", "centor", "mcisaac"],
            whenToUse: "For a sore throat — estimates the chance it's Group A strep and whether to test or treat.",
            pearl: "≤0 no testing · 1 usually none · 2–3 rapid strep test · ≥4 test (± empiric treatment).",
            fields: [
                .init(id: "exudate", label: "Tonsillar exudate/swelling", kind: .toggle(points: 1)),
                .init(id: "nodes", label: "Tender anterior cervical nodes", kind: .toggle(points: 1)),
                .init(id: "fever", label: "Fever > 38°C (by history)", kind: .toggle(points: 1)),
                .init(id: "cough", label: "Absence of cough", kind: .toggle(points: 1)),
                .init(id: "age", label: "Age", kind: .options([.init(label: "3–14", value: 1), .init(label: "15–44", value: 0), .init(label: "≥ 45", value: -1)]))
            ],
            compute: { v in
                let s = Int(sum(v))
                let sev: CalcSeverity = s >= 4 ? .high : (s >= 2 ? .moderate : .low)
                let interp = s <= 0 ? "Very low probability — no testing needed." : (s == 1 ? "Low — testing usually not needed." : (s <= 3 ? "Intermediate — rapid strep test." : "High — test; consider empiric treatment."))
                return CalcResult(value: "Score: \(s)", interpretation: interp, severity: sev)
            }
        ),
        ClinicalCalculator(
            id: "perc", name: "PERC Rule for PE", abbreviation: "PERC",
            tagline: "Rule out PE in low-risk patients",
            category: .pulmonary,
            keywords: ["pe", "pulmonary embolism", "d-dimer", "perc", "clot"],
            whenToUse: "When your gestalt pretest probability of PE is already low (< 15%) — if all 8 criteria are negative, PE is excluded without a D-dimer.",
            pearl: "Only valid when pretest probability is low. Any 'yes' means PERC cannot rule out PE.",
            fields: [
                .init(id: "age", label: "Age ≥ 50", kind: .toggle(points: 1)),
                .init(id: "hr", label: "Heart rate ≥ 100", kind: .toggle(points: 1)),
                .init(id: "o2", label: "SaO₂ < 95%", kind: .toggle(points: 1)),
                .init(id: "leg", label: "Unilateral leg swelling", kind: .toggle(points: 1)),
                .init(id: "hemoptysis", label: "Hemoptysis", kind: .toggle(points: 1)),
                .init(id: "surgery", label: "Recent surgery/trauma (≤ 4 wk)", kind: .toggle(points: 1)),
                .init(id: "prior", label: "Prior PE or DVT", kind: .toggle(points: 1)),
                .init(id: "hormone", label: "Hormone use (estrogen)", kind: .toggle(points: 1))
            ],
            compute: { v in
                let s = Int(sum(v))
                return CalcResult(value: s == 0 ? "PERC negative" : "\(s) criteria positive",
                                  interpretation: s == 0 ? "All criteria negative — PE excluded if pretest risk is low." : "Cannot rule out PE by PERC — pursue D-dimer / imaging.",
                                  severity: s == 0 ? .low : .moderate)
            }
        ),
        ClinicalCalculator(
            id: "qsofa", name: "qSOFA Score", abbreviation: "qSOFA",
            tagline: "Bedside sepsis risk",
            category: .pulmonary,
            keywords: ["sepsis", "infection", "sofa", "mortality", "icu"],
            whenToUse: "A rapid bedside flag in a patient with suspected infection — ≥2 predicts worse outcomes and prompts escalation.",
            pearl: "qSOFA ≥ 2 → higher mortality risk; act, don't wait for labs.",
            fields: [
                .init(id: "rr", label: "Respiratory rate ≥ 22", kind: .toggle(points: 1)),
                .init(id: "ams", label: "Altered mentation (GCS < 15)", kind: .toggle(points: 1)),
                .init(id: "sbp", label: "SBP ≤ 100 mmHg", kind: .toggle(points: 1))
            ],
            compute: { v in
                let s = Int(sum(v))
                return CalcResult(value: "Score: \(s)",
                                  interpretation: s >= 2 ? "High risk — escalate assessment for sepsis." : "Lower risk — continue to monitor.",
                                  severity: s >= 2 ? .high : .low)
            }
        )
    ]

    // MARK: Clots & Bleeding

    private static let clots: [ClinicalCalculator] = [
        ClinicalCalculator(
            id: "wellsdvt", name: "Wells' Criteria for DVT", abbreviation: "Wells DVT",
            tagline: "DVT pre-test probability",
            category: .clots,
            keywords: ["dvt", "clot", "leg swelling", "d-dimer", "ultrasound", "vte"],
            whenToUse: "For suspected leg DVT — decides whether to order a D-dimer (unlikely) or go straight to ultrasound (likely).",
            pearl: "≥ 2 = DVT likely → ultrasound. ≤ 1 = unlikely → D-dimer.",
            fields: [
                .init(id: "cancer", label: "Active cancer", kind: .toggle(points: 1)),
                .init(id: "immob", label: "Paralysis/paresis or recent immobilization", kind: .toggle(points: 1)),
                .init(id: "bed", label: "Bedridden ≥ 3 d or surgery ≤ 12 wk", kind: .toggle(points: 1)),
                .init(id: "tender", label: "Tenderness along deep veins", kind: .toggle(points: 1)),
                .init(id: "swollenleg", label: "Entire leg swollen", kind: .toggle(points: 1)),
                .init(id: "calf", label: "Calf swelling > 3 cm vs other leg", kind: .toggle(points: 1)),
                .init(id: "edema", label: "Pitting edema (symptomatic leg)", kind: .toggle(points: 1)),
                .init(id: "collateral", label: "Collateral superficial veins", kind: .toggle(points: 1)),
                .init(id: "priordvt", label: "Previously documented DVT", kind: .toggle(points: 1)),
                .init(id: "altdx", label: "Alternative diagnosis as likely", kind: .toggle(points: -2))
            ],
            compute: { v in
                let s = Int(sum(v))
                let sev: CalcSeverity = s >= 2 ? .high : (s >= 1 ? .moderate : .low)
                return CalcResult(value: "Score: \(s)",
                                  interpretation: s >= 2 ? "DVT likely — obtain compression ultrasound." : "DVT unlikely — a negative D-dimer rules out.",
                                  severity: sev)
            }
        ),
        ClinicalCalculator(
            id: "wellspe", name: "Wells' Criteria for PE", abbreviation: "Wells PE",
            tagline: "PE pre-test probability",
            category: .clots,
            keywords: ["pe", "pulmonary embolism", "d-dimer", "ctpa", "vte", "chest pain"],
            whenToUse: "For suspected PE — chooses between D-dimer and CT pulmonary angiography.",
            pearl: "≤ 4 = unlikely → D-dimer (consider PERC). > 4 = likely → CTPA.",
            fields: [
                .init(id: "dvt", label: "Clinical signs of DVT", kind: .toggle(points: 3)),
                .init(id: "altdx", label: "PE is #1 or equally likely diagnosis", kind: .toggle(points: 3)),
                .init(id: "hr", label: "Heart rate > 100", kind: .toggle(points: 1.5)),
                .init(id: "immob", label: "Immobilization ≥ 3 d or surgery ≤ 4 wk", kind: .toggle(points: 1.5)),
                .init(id: "prior", label: "Previous PE or DVT", kind: .toggle(points: 1.5)),
                .init(id: "hemoptysis", label: "Hemoptysis", kind: .toggle(points: 1)),
                .init(id: "cancer", label: "Malignancy (treated ≤ 6 mo)", kind: .toggle(points: 1))
            ],
            compute: { v in
                let s = sum(v)
                let sev: CalcSeverity = s > 6 ? .high : (s >= 2 ? .moderate : .low)
                return CalcResult(value: String(format: "Score: %g", s),
                                  interpretation: s > 4 ? "PE likely — obtain CT pulmonary angiography." : "PE unlikely — D-dimer (or PERC) to rule out.",
                                  severity: sev)
            }
        )
    ]

    // MARK: Kidney & Labs

    private static let kidneyLabs: [ClinicalCalculator] = [
        ClinicalCalculator(
            id: "egfr", name: "eGFR (CKD-EPI 2021)", abbreviation: "eGFR",
            tagline: "Kidney function & CKD stage",
            category: .kidneyLabs,
            keywords: ["kidney", "creatinine", "ckd", "renal", "gfr", "dosing"],
            whenToUse: "To stage CKD and adjust drug dosing. Check it before dosing anything renally cleared. The 2021 race-free equation is standard.",
            pearl: "≥90 G1 · 60–89 G2 · 45–59 G3a · 30–44 G3b · 15–29 G4 · <15 G5.",
            fields: [
                .init(id: "sex", label: "Sex", kind: .options([.init(label: "Male", value: 0), .init(label: "Female", value: 1)])),
                .init(id: "age", label: "Age", kind: .number(unit: "years")),
                .init(id: "scr", label: "Serum creatinine", kind: .number(unit: "mg/dL"))
            ],
            compute: { v in
                let female = (v["sex"] ?? 0) == 1
                let age = v["age"] ?? 0
                let scr = max(v["scr"] ?? 0, 0.0001)
                let kappa = female ? 0.7 : 0.9
                let alpha = female ? -0.241 : -0.302
                let egfr = 142 * pow(min(scr / kappa, 1), alpha) * pow(max(scr / kappa, 1), -1.200) * pow(0.9938, age) * (female ? 1.012 : 1.0)
                let sev: CalcSeverity = egfr >= 60 ? .low : (egfr >= 30 ? .moderate : .high)
                let stage: String
                switch egfr {
                case 90...: stage = "G1 (normal)"
                case 60..<90: stage = "G2 (mildly reduced)"
                case 45..<60: stage = "G3a"
                case 30..<45: stage = "G3b"
                case 15..<30: stage = "G4 (severely reduced)"
                default: stage = "G5 (kidney failure)"
                }
                return CalcResult(value: String(format: "%.0f mL/min/1.73m²", egfr), interpretation: stage, severity: sev)
            }
        ),
        ClinicalCalculator(
            id: "aniongap", name: "Anion Gap", abbreviation: "Anion Gap",
            tagline: "Metabolic acidosis workup",
            category: .kidneyLabs,
            keywords: ["acidosis", "metabolic", "electrolytes", "mudpiles", "bmp"],
            whenToUse: "On every BMP with a low bicarbonate — a high gap points to added acid (MUDPILES).",
            pearl: "Normal ≈ 8–12. Add ~2.5 per 1 g/dL albumin below 4.",
            fields: [
                .init(id: "na", label: "Sodium", kind: .number(unit: "mmol/L")),
                .init(id: "cl", label: "Chloride", kind: .number(unit: "mmol/L")),
                .init(id: "hco3", label: "Bicarbonate", kind: .number(unit: "mmol/L"))
            ],
            compute: { v in
                let gap = (v["na"] ?? 0) - ((v["cl"] ?? 0) + (v["hco3"] ?? 0))
                return CalcResult(value: String(format: "%.0f mmol/L", gap),
                                  interpretation: gap > 12 ? "High anion gap — think MUDPILES." : "Normal anion gap.",
                                  severity: gap > 12 ? .high : .low)
            }
        ),
        ClinicalCalculator(
            id: "correctedca", name: "Corrected Calcium", abbreviation: "Corrected Ca",
            tagline: "Calcium adjusted for albumin",
            category: .kidneyLabs,
            keywords: ["calcium", "albumin", "hypocalcemia", "hypercalcemia"],
            whenToUse: "When albumin is low (hospitalized, malnourished, nephrotic) — low albumin lowers total calcium without changing the active fraction.",
            pearl: "Corrected Ca = Ca + 0.8 × (4 − albumin). When unsure, get an ionized calcium.",
            fields: [
                .init(id: "ca", label: "Measured calcium", kind: .number(unit: "mg/dL")),
                .init(id: "alb", label: "Albumin", kind: .number(unit: "g/dL"))
            ],
            compute: { v in
                let corrected = (v["ca"] ?? 0) + 0.8 * (4 - (v["alb"] ?? 0))
                let sev: CalcSeverity = (corrected < 8.5 || corrected > 10.5) ? .moderate : .low
                let interp = corrected < 8.5 ? "Corrected hypocalcemia." : (corrected > 10.5 ? "Corrected hypercalcemia." : "Within normal range.")
                return CalcResult(value: String(format: "%.1f mg/dL", corrected), interpretation: interp, severity: sev)
            }
        )
    ]

    // MARK: General

    private static let general: [ClinicalCalculator] = [
        ClinicalCalculator(
            id: "gcs", name: "Glasgow Coma Scale", abbreviation: "GCS",
            tagline: "Level of consciousness",
            category: .general,
            keywords: ["trauma", "consciousness", "head injury", "neuro", "gcs", "coma"],
            whenToUse: "For any altered or head-injured patient — a reproducible measure of consciousness that trends over time.",
            pearl: "≤ 8 → consider intubation for airway protection.",
            fields: [
                .init(id: "eye", label: "Eye opening", kind: .options([
                    .init(label: "Spontaneous (4)", value: 4), .init(label: "To voice (3)", value: 3),
                    .init(label: "To pain (2)", value: 2), .init(label: "None (1)", value: 1)])),
                .init(id: "verbal", label: "Verbal response", kind: .options([
                    .init(label: "Oriented (5)", value: 5), .init(label: "Confused (4)", value: 4),
                    .init(label: "Inappropriate words (3)", value: 3), .init(label: "Incomprehensible (2)", value: 2),
                    .init(label: "None (1)", value: 1)])),
                .init(id: "motor", label: "Motor response", kind: .options([
                    .init(label: "Obeys commands (6)", value: 6), .init(label: "Localizes pain (5)", value: 5),
                    .init(label: "Withdraws (4)", value: 4), .init(label: "Flexion (3)", value: 3),
                    .init(label: "Extension (2)", value: 2), .init(label: "None (1)", value: 1)]))
            ],
            compute: { v in
                let s = Int(sum(v))
                let sev: CalcSeverity = s <= 8 ? .high : (s <= 12 ? .moderate : .low)
                let interp = s <= 8 ? "Severe — consider airway protection." : (s <= 12 ? "Moderate impairment." : "Mild / normal.")
                return CalcResult(value: "GCS: \(s)", interpretation: interp, severity: sev)
            }
        ),
        ClinicalCalculator(
            id: "bmi", name: "Body Mass Index", abbreviation: "BMI",
            tagline: "Weight category",
            category: .general,
            keywords: ["obesity", "weight", "nutrition", "bmi"],
            whenToUse: "A quick screen anchoring counseling on nutrition, diabetes, and cardiovascular risk.",
            fields: [
                .init(id: "weight", label: "Weight", kind: .number(unit: "kg")),
                .init(id: "height", label: "Height", kind: .number(unit: "cm"))
            ],
            compute: { v in
                let h = max((v["height"] ?? 0) / 100, 0.0001)
                let bmi = (v["weight"] ?? 0) / (h * h)
                let sev: CalcSeverity = (bmi < 18.5 || bmi >= 30) ? .moderate : (bmi >= 25 ? .info : .low)
                let band = bmi < 18.5 ? "Underweight" : (bmi < 25 ? "Normal weight" : (bmi < 30 ? "Overweight" : "Obese"))
                return CalcResult(value: String(format: "%.1f kg/m²", bmi), interpretation: band, severity: sev)
            }
        )
    ]
}
