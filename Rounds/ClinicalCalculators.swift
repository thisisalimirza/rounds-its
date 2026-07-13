//
//  ClinicalCalculators.swift
//  Rounds
//
//  A small library of common clinical calculators for the Practice tab.
//  Each calculator teaches *when* to use it, not just how to score it.
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
    let value: String          // e.g. "Score: 4" or "58 mL/min/1.73m²"
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
    let category: CalcCategory
    let keywords: [String]
    /// The teaching hook — the *when* and *why*, so students use it with foresight.
    let whenToUse: String
    var pearl: String? = nil
    var comingSoon: Bool = false
    var fields: [CalcField] = []
    var compute: (([String: Double]) -> CalcResult)? = nil

    func matches(_ query: String) -> Bool {
        let q = query.lowercased()
        return name.lowercased().contains(q)
            || abbreviation.lowercased().contains(q)
            || category.rawValue.lowercased().contains(q)
            || keywords.contains { $0.lowercased().contains(q) }
    }
}

// MARK: - Library

enum CalculatorLibrary {

    static var all: [ClinicalCalculator] { cardiology + mentalHealth + gi + pulmonary + clots + kidneyLabs + general }

    static func grouped(matching query: String) -> [(category: CalcCategory, items: [ClinicalCalculator])] {
        let filtered = query.isEmpty ? all : all.filter { $0.matches(query) }
        return CalcCategory.allCases.compactMap { category in
            let items = filtered.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    private static func sum(_ v: [String: Double]) -> Double { v.values.reduce(0, +) }

    // MARK: Cardiology

    private static let cardiology: [ClinicalCalculator] = [
        ClinicalCalculator(
            id: "chadsvasc",
            name: "CHA₂DS₂-VASc Score",
            abbreviation: "CHA2DS2-VASc",
            category: .cardiology,
            keywords: ["afib", "atrial fibrillation", "stroke", "anticoagulation", "warfarin", "doac"],
            whenToUse: "Estimate yearly stroke risk in a patient with non-valvular atrial fibrillation — and decide whether to start an anticoagulant. Reach for it the moment you see 'AFib' on a problem list.",
            pearl: "Men with a score ≥1 and women ≥2 generally warrant anticoagulation. A woman scoring 1 for sex alone is still low risk.",
            fields: [
                .init(id: "chf", label: "Congestive heart failure / LV dysfunction", kind: .toggle(points: 1)),
                .init(id: "htn", label: "Hypertension", kind: .toggle(points: 1)),
                .init(id: "age", label: "Age", kind: .options([.init(label: "< 65", value: 0), .init(label: "65–74", value: 1), .init(label: "≥ 75", value: 2)])),
                .init(id: "dm", label: "Diabetes mellitus", kind: .toggle(points: 1)),
                .init(id: "stroke", label: "Prior stroke / TIA / thromboembolism", kind: .toggle(points: 2)),
                .init(id: "vasc", label: "Vascular disease (MI, PAD, aortic plaque)", kind: .toggle(points: 1)),
                .init(id: "sex", label: "Sex", kind: .options([.init(label: "Male", value: 0), .init(label: "Female", value: 1)]))
            ],
            compute: { v in
                let s = Int(sum(v))
                let severity: CalcSeverity = s == 0 ? .low : (s == 1 ? .moderate : .high)
                let interp: String
                switch s {
                case 0: interp = "Low risk. Anticoagulation generally not needed."
                case 1: interp = "Low–moderate risk. Consider anticoagulation (individualize)."
                default: interp = "Elevated risk. Oral anticoagulation recommended."
                }
                return CalcResult(value: "Score: \(s)", interpretation: interp, severity: severity)
            }
        ),
        ClinicalCalculator(
            id: "hasbled",
            name: "HAS-BLED Score",
            abbreviation: "HAS-BLED",
            category: .cardiology,
            keywords: ["bleeding", "anticoagulation", "afib", "warfarin", "risk"],
            whenToUse: "Estimate major bleeding risk in an AFib patient you're about to anticoagulate. Use it alongside CHA₂DS₂-VASc — not to withhold anticoagulation, but to flag and fix modifiable bleeding risks.",
            pearl: "A score ≥3 means 'high risk' — address reversible factors (BP, labile INR, alcohol, interacting drugs) rather than automatically avoiding anticoagulation.",
            fields: [
                .init(id: "htn", label: "Uncontrolled hypertension (SBP > 160)", kind: .toggle(points: 1)),
                .init(id: "renal", label: "Abnormal renal function", kind: .toggle(points: 1)),
                .init(id: "liver", label: "Abnormal liver function", kind: .toggle(points: 1)),
                .init(id: "stroke", label: "Prior stroke", kind: .toggle(points: 1)),
                .init(id: "bleed", label: "Bleeding history or predisposition", kind: .toggle(points: 1)),
                .init(id: "inr", label: "Labile INR (if on warfarin)", kind: .toggle(points: 1)),
                .init(id: "elderly", label: "Elderly (age > 65)", kind: .toggle(points: 1)),
                .init(id: "drugs", label: "Drugs (antiplatelet / NSAID)", kind: .toggle(points: 1)),
                .init(id: "alcohol", label: "Alcohol ≥ 8 drinks/week", kind: .toggle(points: 1))
            ],
            compute: { v in
                let s = Int(sum(v))
                let severity: CalcSeverity = s >= 3 ? .high : (s == 2 ? .moderate : .low)
                let interp = s >= 3
                    ? "High bleeding risk. Address modifiable factors and monitor closely."
                    : "Lower bleeding risk. Reassess periodically."
                return CalcResult(value: "Score: \(s)", interpretation: interp, severity: severity)
            }
        ),
        ClinicalCalculator(
            id: "map",
            name: "Mean Arterial Pressure",
            abbreviation: "MAP",
            category: .cardiology,
            keywords: ["blood pressure", "perfusion", "shock", "sepsis", "map"],
            whenToUse: "Gauge perfusion pressure to organs, especially in shock, sepsis, or a critically ill patient. A MAP ≥ 65 mmHg is the classic resuscitation target.",
            fields: [
                .init(id: "sbp", label: "Systolic BP", kind: .number(unit: "mmHg")),
                .init(id: "dbp", label: "Diastolic BP", kind: .number(unit: "mmHg"))
            ],
            compute: { v in
                let sbp = v["sbp"] ?? 0, dbp = v["dbp"] ?? 0
                let map = dbp + (sbp - dbp) / 3
                let severity: CalcSeverity = map < 65 ? .high : .low
                let interp = map < 65 ? "Below the usual 65 mmHg perfusion target." : "At or above the usual 65 mmHg target."
                return CalcResult(value: String(format: "%.0f mmHg", map), interpretation: interp, severity: severity)
            }
        ),
        ClinicalCalculator(
            id: "ascvd",
            name: "ASCVD Risk (Pooled Cohort)",
            abbreviation: "ASCVD",
            category: .cardiology,
            keywords: ["cholesterol", "statin", "prevention", "cardiovascular", "risk", "lipids"],
            whenToUse: "Estimate 10-year risk of heart attack or stroke to guide statin therapy in adults 40–75 without known ASCVD. Knowing this before your preceptor asks is a classic 'foresight' moment on a primary-care rotation.",
            pearl: "≥ 7.5% 10-year risk generally favors a statin discussion; 5–7.5% is intermediate.",
            comingSoon: true
        ),
        ClinicalCalculator(
            id: "prevent",
            name: "PREVENT CVD Risk (AHA 2023)",
            abbreviation: "PREVENT",
            category: .cardiology,
            keywords: ["cardiovascular", "kidney", "metabolic", "risk", "prevention", "statin"],
            whenToUse: "The newer AHA equations estimating 10- and 30-year cardiovascular risk, incorporating kidney and metabolic factors. Increasingly the preferred tool over the older Pooled Cohort Equations.",
            comingSoon: true
        )
    ]

    // MARK: Mental Health

    private static func questionnaire(id: String, name: String, abbr: String, keywords: [String], whenToUse: String, pearl: String?, prompts: [String], bands: [(max: Int, label: String, severity: CalcSeverity)], suicidalItem: Int? = nil) -> ClinicalCalculator {
        let options: [CalcField.Option] = [
            .init(label: "Not at all", value: 0),
            .init(label: "Several days", value: 1),
            .init(label: "More than half the days", value: 2),
            .init(label: "Nearly every day", value: 3)
        ]
        let fields = prompts.enumerated().map { i, prompt in
            CalcField(id: "q\(i)", label: prompt, kind: .options(options))
        }
        return ClinicalCalculator(
            id: id, name: name, abbreviation: abbr, category: .mentalHealth,
            keywords: keywords, whenToUse: whenToUse, pearl: pearl,
            fields: fields,
            compute: { v in
                let score = Int(sum(v))
                let band = bands.first { score <= $0.max } ?? bands.last!
                var interp = band.label
                if let idx = suicidalItem, (v["q\(idx)"] ?? 0) > 0 {
                    interp += " ⚠️ Positive on the self-harm item — assess safety."
                }
                return CalcResult(value: "Score: \(score)", interpretation: interp, severity: band.severity)
            }
        )
    }

    private static let mentalHealth: [ClinicalCalculator] = [
        questionnaire(
            id: "phq9", name: "PHQ-9 Depression Scale", abbr: "PHQ-9",
            keywords: ["depression", "mood", "screening", "psychiatry", "phq"],
            whenToUse: "Screen for and grade the severity of depression in any adult with low mood, fatigue, or loss of interest. A staple of primary care, psych, and annual visits — great to offer before you're asked.",
            pearl: "Item 9 screens for suicidal ideation — any positive answer warrants a safety assessment regardless of total score.",
            prompts: [
                "Little interest or pleasure in doing things",
                "Feeling down, depressed, or hopeless",
                "Trouble falling/staying asleep, or sleeping too much",
                "Feeling tired or having little energy",
                "Poor appetite or overeating",
                "Feeling bad about yourself / like a failure",
                "Trouble concentrating",
                "Moving/speaking slowly, or being restless",
                "Thoughts that you would be better off dead or of self-harm"
            ],
            bands: [
                (4, "Minimal depression.", .low),
                (9, "Mild depression.", .low),
                (14, "Moderate depression.", .moderate),
                (19, "Moderately severe depression.", .high),
                (27, "Severe depression.", .high)
            ],
            suicidalItem: 8
        ),
        questionnaire(
            id: "gad7", name: "GAD-7 Anxiety Scale", abbr: "GAD-7",
            keywords: ["anxiety", "worry", "screening", "psychiatry", "gad"],
            whenToUse: "Screen for and grade generalized anxiety in a patient with worry, restlessness, or somatic complaints. Pairs naturally with the PHQ-9 at wellness visits.",
            pearl: nil,
            prompts: [
                "Feeling nervous, anxious, or on edge",
                "Not being able to stop or control worrying",
                "Worrying too much about different things",
                "Trouble relaxing",
                "Being so restless it's hard to sit still",
                "Becoming easily annoyed or irritable",
                "Feeling afraid as if something awful might happen"
            ],
            bands: [
                (4, "Minimal anxiety.", .low),
                (9, "Mild anxiety.", .low),
                (14, "Moderate anxiety.", .moderate),
                (21, "Severe anxiety.", .high)
            ]
        )
    ]

    // MARK: GI & Liver

    private static let gi: [ClinicalCalculator] = [
        ClinicalCalculator(
            id: "fib4",
            name: "FIB-4 Fibrosis Index",
            abbreviation: "FIB-4",
            category: .gi,
            keywords: ["liver", "fibrosis", "nafld", "mash", "hepatitis", "cirrhosis"],
            whenToUse: "A no-cost, first-line way to estimate advanced liver fibrosis in patients with fatty liver disease or abnormal LFTs — using only age, AST, ALT, and platelets. Use it to decide who needs elastography or hepatology referral.",
            pearl: "Best validated in ages 35–65. < 1.45 rules out advanced fibrosis; > 3.25 makes it likely.",
            fields: [
                .init(id: "age", label: "Age", kind: .number(unit: "years")),
                .init(id: "ast", label: "AST", kind: .number(unit: "U/L")),
                .init(id: "alt", label: "ALT", kind: .number(unit: "U/L")),
                .init(id: "plt", label: "Platelets", kind: .number(unit: "×10⁹/L"))
            ],
            compute: { v in
                let age = v["age"] ?? 0, ast = v["ast"] ?? 0, alt = max(v["alt"] ?? 0, 0.0001), plt = max(v["plt"] ?? 0, 0.0001)
                let fib4 = (age * ast) / (plt * alt.squareRoot())
                let severity: CalcSeverity = fib4 < 1.45 ? .low : (fib4 <= 3.25 ? .moderate : .high)
                let interp: String
                if fib4 < 1.45 { interp = "Advanced fibrosis unlikely. Reassess periodically." }
                else if fib4 <= 3.25 { interp = "Indeterminate — consider elastography (FibroScan)." }
                else { interp = "Advanced fibrosis likely — hepatology referral." }
                return CalcResult(value: String(format: "FIB-4: %.2f", fib4), interpretation: interp, severity: severity)
            }
        )
    ]

    // MARK: Pulmonary & ID

    private static let pulmonary: [ClinicalCalculator] = [
        ClinicalCalculator(
            id: "curb65",
            name: "CURB-65 Pneumonia Severity",
            abbreviation: "CURB-65",
            category: .pulmonary,
            keywords: ["pneumonia", "cap", "sepsis", "admission", "infection"],
            whenToUse: "Decide whether a patient with community-acquired pneumonia can go home or needs admission. Calculating it on presentation shows real clinical judgment on wards and in the ED.",
            pearl: "0–1 usually outpatient · 2 consider admission · ≥3 admit and consider ICU.",
            fields: [
                .init(id: "confusion", label: "New confusion", kind: .toggle(points: 1)),
                .init(id: "urea", label: "BUN > 19 mg/dL (urea > 7 mmol/L)", kind: .toggle(points: 1)),
                .init(id: "rr", label: "Respiratory rate ≥ 30", kind: .toggle(points: 1)),
                .init(id: "bp", label: "SBP < 90 or DBP ≤ 60 mmHg", kind: .toggle(points: 1)),
                .init(id: "age", label: "Age ≥ 65", kind: .toggle(points: 1))
            ],
            compute: { v in
                let s = Int(sum(v))
                let severity: CalcSeverity = s >= 3 ? .high : (s == 2 ? .moderate : .low)
                let interp: String
                switch s {
                case 0, 1: interp = "Low severity — outpatient treatment often appropriate."
                case 2: interp = "Moderate — consider short-stay or admission."
                default: interp = "High severity — admit; consider ICU."
                }
                return CalcResult(value: "Score: \(s)", interpretation: interp, severity: severity)
            }
        )
    ]

    // MARK: Clots & Bleeding

    private static let clots: [ClinicalCalculator] = [
        ClinicalCalculator(
            id: "wellsdvt",
            name: "Wells' Criteria for DVT",
            abbreviation: "Wells DVT",
            category: .clots,
            keywords: ["dvt", "clot", "leg swelling", "d-dimer", "ultrasound", "vte"],
            whenToUse: "Stratify pre-test probability of a leg DVT so you know whether to order a D-dimer (low risk) or go straight to compression ultrasound (high risk).",
            pearl: "Score ≥ 2 = DVT 'likely' → ultrasound. ≤ 1 = 'unlikely' → D-dimer.",
            fields: [
                .init(id: "cancer", label: "Active cancer", kind: .toggle(points: 1)),
                .init(id: "immob", label: "Paralysis/paresis or recent leg immobilization", kind: .toggle(points: 1)),
                .init(id: "bed", label: "Bedridden ≥ 3 days or surgery within 12 weeks", kind: .toggle(points: 1)),
                .init(id: "tender", label: "Localized tenderness along deep veins", kind: .toggle(points: 1)),
                .init(id: "swollenleg", label: "Entire leg swollen", kind: .toggle(points: 1)),
                .init(id: "calf", label: "Calf swelling > 3 cm vs other leg", kind: .toggle(points: 1)),
                .init(id: "edema", label: "Pitting edema in symptomatic leg", kind: .toggle(points: 1)),
                .init(id: "collateral", label: "Collateral superficial veins", kind: .toggle(points: 1)),
                .init(id: "priordvt", label: "Previously documented DVT", kind: .toggle(points: 1)),
                .init(id: "altdx", label: "Alternative diagnosis at least as likely", kind: .toggle(points: -2))
            ],
            compute: { v in
                let s = Int(sum(v))
                let severity: CalcSeverity = s >= 2 ? .high : (s >= 1 ? .moderate : .low)
                let interp = s >= 2 ? "DVT likely — obtain compression ultrasound." : "DVT unlikely — a negative D-dimer can rule out."
                return CalcResult(value: "Score: \(s)", interpretation: interp, severity: severity)
            }
        ),
        ClinicalCalculator(
            id: "wellspe",
            name: "Wells' Criteria for PE",
            abbreviation: "Wells PE",
            category: .clots,
            keywords: ["pe", "pulmonary embolism", "clot", "d-dimer", "ctpa", "vte", "chest pain"],
            whenToUse: "Estimate pre-test probability of pulmonary embolism to choose between D-dimer and CT pulmonary angiography in a patient with pleuritic chest pain, dyspnea, or unexplained tachycardia.",
            pearl: "≤ 4 = PE 'unlikely' → D-dimer (consider PERC). > 4 = 'likely' → CTPA.",
            fields: [
                .init(id: "dvt", label: "Clinical signs of DVT", kind: .toggle(points: 3)),
                .init(id: "altdx", label: "PE is the #1 diagnosis or equally likely", kind: .toggle(points: 3)),
                .init(id: "hr", label: "Heart rate > 100", kind: .toggle(points: 1.5)),
                .init(id: "immob", label: "Immobilization ≥ 3 days or surgery in past 4 weeks", kind: .toggle(points: 1.5)),
                .init(id: "prior", label: "Previous PE or DVT", kind: .toggle(points: 1.5)),
                .init(id: "hemoptysis", label: "Hemoptysis", kind: .toggle(points: 1)),
                .init(id: "cancer", label: "Malignancy (treated within 6 months)", kind: .toggle(points: 1))
            ],
            compute: { v in
                let s = sum(v)
                let severity: CalcSeverity = s > 6 ? .high : (s >= 2 ? .moderate : .low)
                let interp = s > 4 ? "PE likely — obtain CT pulmonary angiography." : "PE unlikely — D-dimer (or PERC) to rule out."
                return CalcResult(value: String(format: "Score: %g", s), interpretation: interp, severity: severity)
            }
        )
    ]

    // MARK: Kidney & Labs

    private static let kidneyLabs: [ClinicalCalculator] = [
        ClinicalCalculator(
            id: "egfr",
            name: "eGFR (CKD-EPI 2021)",
            abbreviation: "eGFR",
            category: .kidneyLabs,
            keywords: ["kidney", "creatinine", "ckd", "renal", "gfr", "dosing"],
            whenToUse: "Estimate kidney function to stage CKD and adjust drug dosing. The 2021 race-free equation is now the standard. Check it before dosing anything renally cleared.",
            pearl: "≥ 90 G1 · 60–89 G2 · 45–59 G3a · 30–44 G3b · 15–29 G4 · < 15 G5 (kidney failure).",
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
                let egfr = 142
                    * pow(min(scr / kappa, 1), alpha)
                    * pow(max(scr / kappa, 1), -1.200)
                    * pow(0.9938, age)
                    * (female ? 1.012 : 1.0)
                let severity: CalcSeverity = egfr >= 60 ? .low : (egfr >= 30 ? .moderate : .high)
                let stage: String
                switch egfr {
                case 90...: stage = "G1 (normal)"
                case 60..<90: stage = "G2 (mildly reduced)"
                case 45..<60: stage = "G3a"
                case 30..<45: stage = "G3b"
                case 15..<30: stage = "G4 (severely reduced)"
                default: stage = "G5 (kidney failure)"
                }
                return CalcResult(value: String(format: "%.0f mL/min/1.73m²", egfr), interpretation: stage, severity: severity)
            }
        ),
        ClinicalCalculator(
            id: "aniongap",
            name: "Anion Gap",
            abbreviation: "Anion Gap",
            category: .kidneyLabs,
            keywords: ["acidosis", "metabolic", "electrolytes", "mudpiles", "abg", "bmp"],
            whenToUse: "Work up a metabolic acidosis. A high anion gap points to added acid (MUDPILES: DKA, lactate, toxins, uremia). Calculate it on every BMP with a low bicarbonate.",
            pearl: "Normal ≈ 8–12. Correct for albumin: add ~2.5 to the gap per 1 g/dL drop below 4.",
            fields: [
                .init(id: "na", label: "Sodium", kind: .number(unit: "mmol/L")),
                .init(id: "cl", label: "Chloride", kind: .number(unit: "mmol/L")),
                .init(id: "hco3", label: "Bicarbonate", kind: .number(unit: "mmol/L"))
            ],
            compute: { v in
                let gap = (v["na"] ?? 0) - ((v["cl"] ?? 0) + (v["hco3"] ?? 0))
                let severity: CalcSeverity = gap > 12 ? .high : .low
                let interp = gap > 12 ? "High anion gap — think MUDPILES." : "Normal anion gap."
                return CalcResult(value: String(format: "%.0f mmol/L", gap), interpretation: interp, severity: severity)
            }
        ),
        ClinicalCalculator(
            id: "correctedca",
            name: "Corrected Calcium",
            abbreviation: "Corrected Ca",
            category: .kidneyLabs,
            keywords: ["calcium", "albumin", "hypocalcemia", "hypercalcemia", "electrolytes"],
            whenToUse: "Interpret a calcium level in a patient with low albumin (hospitalized, malnourished, nephrotic). Low albumin lowers total calcium without changing the physiologically active ionized fraction.",
            pearl: "Corrected Ca = measured Ca + 0.8 × (4 − albumin). When in doubt, check an ionized calcium.",
            fields: [
                .init(id: "ca", label: "Measured calcium", kind: .number(unit: "mg/dL")),
                .init(id: "alb", label: "Albumin", kind: .number(unit: "g/dL"))
            ],
            compute: { v in
                let corrected = (v["ca"] ?? 0) + 0.8 * (4 - (v["alb"] ?? 0))
                let severity: CalcSeverity = (corrected < 8.5 || corrected > 10.5) ? .moderate : .low
                let interp: String
                if corrected < 8.5 { interp = "Corrected hypocalcemia." }
                else if corrected > 10.5 { interp = "Corrected hypercalcemia." }
                else { interp = "Within normal range." }
                return CalcResult(value: String(format: "%.1f mg/dL", corrected), interpretation: interp, severity: severity)
            }
        )
    ]

    // MARK: General

    private static let general: [ClinicalCalculator] = [
        ClinicalCalculator(
            id: "bmi",
            name: "Body Mass Index",
            abbreviation: "BMI",
            category: .general,
            keywords: ["obesity", "weight", "nutrition", "bmi"],
            whenToUse: "A quick screen for under- and over-weight that anchors counseling on nutrition, diabetes, and cardiovascular risk. Part of nearly every complete note.",
            fields: [
                .init(id: "weight", label: "Weight", kind: .number(unit: "kg")),
                .init(id: "height", label: "Height", kind: .number(unit: "cm"))
            ],
            compute: { v in
                let h = max((v["height"] ?? 0) / 100, 0.0001)
                let bmi = (v["weight"] ?? 0) / (h * h)
                let severity: CalcSeverity = (bmi < 18.5 || bmi >= 30) ? .moderate : (bmi >= 25 ? .info : .low)
                let band: String
                switch bmi {
                case ..<18.5: band = "Underweight"
                case 18.5..<25: band = "Normal weight"
                case 25..<30: band = "Overweight"
                default: band = "Obese"
                }
                return CalcResult(value: String(format: "%.1f kg/m²", bmi), interpretation: band, severity: severity)
            }
        )
    ]
}
