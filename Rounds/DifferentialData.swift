//
//  DifferentialData.swift
//  Rounds
//
//  Input-driven differential-diagnosis frameworks. The user picks a presenting
//  complaint and toggles the patient's findings; each diagnosis lists the
//  features that argue for and against it, and the list re-ranks by match.
//
//  Curated for teaching the *approach* — not an exhaustive or diagnostic tool.
//

import Foundation

/// A toggleable patient feature (demographic, symptom, sign, or red flag).
struct DDxFinding: Identifiable, Hashable {
    let id: String
    let label: String
}

struct DDxDiagnosis: Identifiable {
    let id: String
    let name: String
    let isCantMiss: Bool
    /// Finding ids that support this diagnosis.
    let supports: [String]
    /// Finding ids that argue against this diagnosis.
    let against: [String]
    var note: String? = nil
}

struct DDxPresentation: Identifiable {
    let id: String
    let complaint: String
    let system: String
    let icon: String
    let approach: String
    let keyQuestions: [String]
    let findings: [DDxFinding]
    let diagnoses: [DDxDiagnosis]
    var keywords: [String] = []

    func matches(_ query: String) -> Bool {
        let q = query.lowercased()
        return complaint.lowercased().contains(q)
            || system.lowercased().contains(q)
            || keywords.contains { $0.lowercased().contains(q) }
    }

    func label(for id: String) -> String { findings.first { $0.id == id }?.label ?? id }

    /// Simple match score: supporting findings present minus opposing findings present.
    func score(_ dx: DDxDiagnosis, selected: Set<String>) -> Int {
        dx.supports.filter { selected.contains($0) }.count - dx.against.filter { selected.contains($0) }.count
    }

    /// Diagnoses ranked for the selected findings (curated order when nothing selected).
    func ranked(selected: Set<String>) -> [DDxDiagnosis] {
        guard !selected.isEmpty else { return diagnoses }
        return diagnoses.enumerated().sorted { a, b in
            let sa = score(a.element, selected: selected), sb = score(b.element, selected: selected)
            return sa == sb ? a.offset < b.offset : sa > sb
        }.map { $0.element }
    }
}

enum DifferentialLibrary {
    static let disclaimer = "For education only. A real differential depends on the full history, exam, and clinical judgment."

    static func filtered(_ query: String) -> [DDxPresentation] {
        query.isEmpty ? all : all.filter { $0.matches(query) }
    }

    static let all: [DDxPresentation] = [chestPain, dyspnea, abdPain, headache, syncope, backPain]

    // MARK: Chest pain

    private static let chestPain = DDxPresentation(
        id: "chestpain", complaint: "Chest Pain", system: "Cardiopulmonary", icon: "heart.fill",
        approach: "Rule out the life-threats first (ACS, PE, dissection, pneumothorax, tamponade, esophageal rupture), then work through common causes.",
        keyQuestions: ["Exertional or at rest?", "Radiation to arm/jaw/back?", "Tearing or migrating?", "Pleuritic?", "Cardiac risk factors?"],
        findings: [
            .init(id: "exertional", label: "Provoked by exertion"),
            .init(id: "radiation", label: "Radiates to arm/jaw"),
            .init(id: "diaphoresis", label: "Diaphoresis / nausea"),
            .init(id: "cadrisk", label: "CAD risk factors"),
            .init(id: "pleuritic", label: "Pleuritic (worse breathing in)"),
            .init(id: "dyspnea", label: "Associated dyspnea"),
            .init(id: "dvtrisk", label: "DVT risk / immobility / cancer"),
            .init(id: "tearing", label: "Tearing pain to the back"),
            .init(id: "reproducible", label: "Reproducible with palpation"),
            .init(id: "positional", label: "Better leaning forward"),
            .init(id: "postemesis", label: "After forceful vomiting"),
            .init(id: "burning", label: "Burning / postprandial")
        ],
        diagnoses: [
            .init(id: "acs", name: "Acute coronary syndrome", isCantMiss: true,
                  supports: ["exertional", "radiation", "diaphoresis", "cadrisk"], against: ["reproducible", "pleuritic"]),
            .init(id: "pe", name: "Pulmonary embolism", isCantMiss: true,
                  supports: ["pleuritic", "dyspnea", "dvtrisk"], against: ["reproducible", "exertional"]),
            .init(id: "dissection", name: "Aortic dissection", isCantMiss: true,
                  supports: ["tearing", "radiation"], against: ["reproducible", "pleuritic"]),
            .init(id: "boerhaave", name: "Esophageal rupture (Boerhaave)", isCantMiss: true,
                  supports: ["postemesis", "dyspnea"], against: ["exertional", "reproducible"]),
            .init(id: "pericarditis", name: "Pericarditis", isCantMiss: false,
                  supports: ["pleuritic", "positional"], against: ["exertional"]),
            .init(id: "gerd", name: "GERD / esophageal", isCantMiss: false,
                  supports: ["burning"], against: ["exertional", "pleuritic"]),
            .init(id: "msk", name: "Musculoskeletal", isCantMiss: false,
                  supports: ["reproducible"], against: ["diaphoresis", "dyspnea"])
        ],
        keywords: ["cardiac", "acs", "mi", "angina"]
    )

    // MARK: Dyspnea

    private static let dyspnea = DDxPresentation(
        id: "dyspnea", complaint: "Shortness of Breath", system: "Cardiopulmonary", icon: "lungs.fill",
        approach: "Split into cardiac vs pulmonary vs other, and acute vs chronic. Assess oxygenation and work of breathing first.",
        keyQuestions: ["Sudden or gradual?", "Orthopnea / PND?", "Wheeze, fever, or cough?", "Leg swelling or chest pain?", "Known heart/lung disease?"],
        findings: [
            .init(id: "sudden", label: "Sudden onset"),
            .init(id: "pleuritic", label: "Pleuritic chest pain"),
            .init(id: "dvtrisk", label: "DVT risk / immobility"),
            .init(id: "orthopnea", label: "Orthopnea / PND"),
            .init(id: "edema", label: "Leg edema / weight gain"),
            .init(id: "wheeze", label: "Wheeze"),
            .init(id: "fever", label: "Fever / productive cough"),
            .init(id: "urticaria", label: "Urticaria / known trigger"),
            .init(id: "knownlung", label: "Known asthma / COPD"),
            .init(id: "pallor", label: "Pallor / fatigue")
        ],
        diagnoses: [
            .init(id: "pe", name: "Pulmonary embolism", isCantMiss: true,
                  supports: ["sudden", "pleuritic", "dvtrisk"], against: ["wheeze", "fever"]),
            .init(id: "edema", name: "Pulmonary edema / ACS", isCantMiss: true,
                  supports: ["orthopnea", "edema", "sudden"], against: ["wheeze"]),
            .init(id: "anaphylaxis", name: "Anaphylaxis", isCantMiss: true,
                  supports: ["urticaria", "sudden", "wheeze"], against: ["fever", "orthopnea"]),
            .init(id: "copd", name: "Asthma / COPD exacerbation", isCantMiss: false,
                  supports: ["wheeze", "knownlung"], against: ["orthopnea", "edema"]),
            .init(id: "pna", name: "Pneumonia", isCantMiss: false,
                  supports: ["fever"], against: ["sudden", "orthopnea"]),
            .init(id: "chf", name: "Heart failure", isCantMiss: false,
                  supports: ["orthopnea", "edema"], against: ["sudden", "fever"]),
            .init(id: "anemia", name: "Anemia", isCantMiss: false,
                  supports: ["pallor"], against: ["sudden", "wheeze"])
        ],
        keywords: ["sob", "breathless", "hypoxia", "respiratory"]
    )

    // MARK: Abdominal pain

    private static let abdPain = DDxPresentation(
        id: "abdpain", complaint: "Abdominal Pain", system: "GI / Surgical", icon: "pills.fill",
        approach: "Localize the pain and always check a pregnancy test in anyone who can be pregnant. Look for peritoneal and vascular emergencies first.",
        keyQuestions: ["Where, and does it radiate?", "Vomiting, fever, or GI bleeding?", "Last menstrual period?", "Peritoneal signs?", "Vascular risk factors?"],
        findings: [
            .init(id: "ruq", label: "RUQ / postprandial"),
            .init(id: "epigastric", label: "Epigastric"),
            .init(id: "rlq", label: "RLQ / migrated from umbilicus"),
            .init(id: "flank", label: "Flank → groin"),
            .init(id: "diffuse", label: "Diffuse / sudden severe"),
            .init(id: "peritoneal", label: "Rigid / rebound / guarding"),
            .init(id: "pregnancy", label: "Possible pregnancy (positive hCG)"),
            .init(id: "vascular", label: "Older + vascular risk / AFib"),
            .init(id: "outofproportion", label: "Pain out of proportion to exam"),
            .init(id: "distension", label: "Distension / vomiting / no flatus"),
            .init(id: "diarrhea", label: "Diarrhea")
        ],
        diagnoses: [
            .init(id: "aaa", name: "Ruptured AAA", isCantMiss: true,
                  supports: ["diffuse", "vascular", "flank"], against: ["diarrhea", "ruq"]),
            .init(id: "mesenteric", name: "Mesenteric ischemia", isCantMiss: true,
                  supports: ["outofproportion", "vascular"], against: ["peritoneal"]),
            .init(id: "perforation", name: "Perforated viscus", isCantMiss: true,
                  supports: ["diffuse", "peritoneal"], against: ["diarrhea"]),
            .init(id: "ectopic", name: "Ectopic pregnancy", isCantMiss: true,
                  supports: ["pregnancy", "rlq"], against: ["ruq"]),
            .init(id: "obstruction", name: "Bowel obstruction", isCantMiss: true,
                  supports: ["distension"], against: ["diarrhea"]),
            .init(id: "appendicitis", name: "Appendicitis", isCantMiss: true,
                  supports: ["rlq"], against: ["ruq"]),
            .init(id: "cholecystitis", name: "Biliary colic / cholecystitis", isCantMiss: false,
                  supports: ["ruq"], against: ["rlq", "flank"]),
            .init(id: "renalcolic", name: "Renal colic", isCantMiss: false,
                  supports: ["flank"], against: ["ruq", "peritoneal"]),
            .init(id: "gastro", name: "Gastroenteritis", isCantMiss: false,
                  supports: ["diffuse", "diarrhea"], against: ["peritoneal"])
        ],
        keywords: ["belly", "stomach", "acute abdomen"]
    )

    // MARK: Headache

    private static let headache = DDxPresentation(
        id: "headache", complaint: "Headache", system: "Neurology", icon: "brain.head.profile",
        approach: "Separate primary headaches (migraine, tension, cluster) from dangerous secondary causes. Screen red flags before anchoring on 'just a migraine.'",
        keyQuestions: ["Thunderclap onset?", "Fever / neck stiffness?", "New focal deficit or vision change?", "Worse lying down / Valsalva?", "Age > 50 or immunocompromised?"],
        findings: [
            .init(id: "thunderclap", label: "Thunderclap (max in seconds)"),
            .init(id: "fever", label: "Fever / neck stiffness"),
            .init(id: "focal", label: "New focal neuro deficit"),
            .init(id: "positional", label: "Worse lying down / Valsalva"),
            .init(id: "over50", label: "Age > 50 / jaw claudication"),
            .init(id: "prothrombotic", label: "Prothrombotic state"),
            .init(id: "redeye", label: "Painful red eye / halos"),
            .init(id: "unilateralthrob", label: "Unilateral, throbbing, photophobia"),
            .init(id: "bandlike", label: "Bilateral, band-like"),
            .init(id: "autonomic", label: "Orbital + tearing / rhinorrhea")
        ],
        diagnoses: [
            .init(id: "sah", name: "Subarachnoid hemorrhage", isCantMiss: true,
                  supports: ["thunderclap"], against: ["bandlike"]),
            .init(id: "meningitis", name: "Meningitis / encephalitis", isCantMiss: true,
                  supports: ["fever", "focal"], against: ["unilateralthrob"]),
            .init(id: "mass", name: "Mass lesion / raised ICP", isCantMiss: true,
                  supports: ["positional", "focal"], against: ["bandlike"]),
            .init(id: "gca", name: "Giant cell arteritis", isCantMiss: true,
                  supports: ["over50"], against: ["autonomic"]),
            .init(id: "cvst", name: "Cerebral venous sinus thrombosis", isCantMiss: true,
                  supports: ["prothrombotic", "positional"], against: ["autonomic"]),
            .init(id: "glaucoma", name: "Acute angle-closure glaucoma", isCantMiss: true,
                  supports: ["redeye"], against: ["bandlike"]),
            .init(id: "migraine", name: "Migraine", isCantMiss: false,
                  supports: ["unilateralthrob"], against: ["fever", "focal", "thunderclap"]),
            .init(id: "tension", name: "Tension-type", isCantMiss: false,
                  supports: ["bandlike"], against: ["thunderclap", "focal"]),
            .init(id: "cluster", name: "Cluster headache", isCantMiss: false,
                  supports: ["autonomic"], against: ["fever"])
        ],
        keywords: ["migraine", "sah", "cephalgia"]
    )

    // MARK: Syncope

    private static let syncope = DDxPresentation(
        id: "syncope", complaint: "Syncope", system: "Cardiac / Neuro", icon: "bolt.heart.fill",
        approach: "Separate cardiac (dangerous) from reflex and orthostatic causes. Get an ECG on everyone.",
        keyQuestions: ["Exertional or with palpitations?", "Any prodrome?", "On standing up?", "Family history of sudden death?", "Prompt recovery?"],
        findings: [
            .init(id: "exertional", label: "During exertion"),
            .init(id: "palpitations", label: "Preceded by palpitations"),
            .init(id: "noprodrome", label: "No prodrome / sudden"),
            .init(id: "murmur", label: "Murmur / structural disease"),
            .init(id: "famsudden", label: "Family history of sudden death"),
            .init(id: "prodrome", label: "Prodrome (nausea, warmth)"),
            .init(id: "standing", label: "On standing up"),
            .init(id: "meds", label: "Antihypertensives / diuretics"),
            .init(id: "trigger", label: "Trigger (cough, micturition, pain)"),
            .init(id: "melena", label: "Melena / anemia")
        ],
        diagnoses: [
            .init(id: "arrhythmia", name: "Arrhythmia", isCantMiss: true,
                  supports: ["palpitations", "noprodrome", "famsudden"], against: ["prodrome", "standing"]),
            .init(id: "structural", name: "Structural cardiac (AS, HOCM)", isCantMiss: true,
                  supports: ["exertional", "murmur"], against: ["trigger"]),
            .init(id: "pe", name: "Pulmonary embolism", isCantMiss: true,
                  supports: ["noprodrome"], against: ["trigger", "standing"]),
            .init(id: "gib", name: "Occult GI bleed", isCantMiss: true,
                  supports: ["melena", "standing"], against: ["exertional"]),
            .init(id: "vasovagal", name: "Vasovagal", isCantMiss: false,
                  supports: ["prodrome", "trigger"], against: ["exertional", "noprodrome"]),
            .init(id: "orthostatic", name: "Orthostatic hypotension", isCantMiss: false,
                  supports: ["standing", "meds"], against: ["exertional"])
        ],
        keywords: ["fainting", "passed out", "collapse"]
    )

    // MARK: Low back pain

    private static let backPain = DDxPresentation(
        id: "backpain", complaint: "Acute Low Back Pain", system: "Musculoskeletal", icon: "figure.stand",
        approach: "Most is benign mechanical pain — but screen hard for red flags signalling a dangerous cause before reassuring.",
        keyQuestions: ["Bowel/bladder retention or incontinence?", "Saddle anesthesia or leg weakness?", "Fever or IV drug use?", "History of cancer?", "Trauma or age > 50 with night pain?"],
        findings: [
            .init(id: "retention", label: "Urinary retention / incontinence"),
            .init(id: "saddle", label: "Saddle anesthesia / bilateral sciatica"),
            .init(id: "fever", label: "Fever / IV drug use"),
            .init(id: "cancer", label: "History of cancer / weight loss"),
            .init(id: "trauma", label: "Trauma / osteoporosis / steroids"),
            .init(id: "vascular", label: "Older + pulsatile mass / vascular risk"),
            .init(id: "nightpain", label: "Night pain"),
            .init(id: "dermatomal", label: "Dermatomal radiation / +SLR"),
            .init(id: "mechanical", label: "Improves with rest, no red flags")
        ],
        diagnoses: [
            .init(id: "cauda", name: "Cauda equina syndrome", isCantMiss: true,
                  supports: ["retention", "saddle"], against: ["mechanical"]),
            .init(id: "abscess", name: "Spinal epidural abscess", isCantMiss: true,
                  supports: ["fever"], against: ["mechanical"]),
            .init(id: "malignancy", name: "Malignancy / metastasis", isCantMiss: true,
                  supports: ["cancer", "nightpain"], against: ["mechanical"]),
            .init(id: "fracture", name: "Vertebral fracture", isCantMiss: true,
                  supports: ["trauma"], against: ["dermatomal"]),
            .init(id: "aaa", name: "Abdominal aortic aneurysm", isCantMiss: true,
                  supports: ["vascular"], against: ["dermatomal", "mechanical"]),
            .init(id: "radiculopathy", name: "Disc herniation / radiculopathy", isCantMiss: false,
                  supports: ["dermatomal"], against: ["retention", "fever"]),
            .init(id: "mechanical", name: "Mechanical strain", isCantMiss: false,
                  supports: ["mechanical"], against: ["retention", "fever", "cancer"])
        ],
        keywords: ["lumbar", "sciatica", "cauda equina", "red flags"]
    )
}
