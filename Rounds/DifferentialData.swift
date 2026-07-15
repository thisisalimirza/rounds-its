//
//  DifferentialData.swift
//  Rounds
//
//  Curated differential-diagnosis frameworks for common chief complaints.
//  The goal is to teach a *structured approach* (can't-miss first, then common),
//  not to be an exhaustive reference.
//

import Foundation

struct DDxItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let clue: String
}

struct DDxPresentation: Identifiable {
    let id: String
    let complaint: String
    let system: String
    let icon: String
    /// How to think about this complaint.
    let approach: String
    let keyQuestions: [String]
    let cantMiss: [DDxItem]
    let common: [DDxItem]
    var keywords: [String] = []

    func matches(_ query: String) -> Bool {
        let q = query.lowercased()
        return complaint.lowercased().contains(q)
            || system.lowercased().contains(q)
            || keywords.contains { $0.lowercased().contains(q) }
    }
}

enum DifferentialLibrary {
    static let disclaimer = "For education only. A real differential depends on the full history, exam, and clinical judgment."

    static func filtered(_ query: String) -> [DDxPresentation] {
        query.isEmpty ? all : all.filter { $0.matches(query) }
    }

    static let all: [DDxPresentation] = [
        DDxPresentation(
            id: "chestpain", complaint: "Chest Pain", system: "Cardiopulmonary", icon: "heart.fill",
            approach: "Rule out the life-threats first, then work through common causes. Ask: could this be one of the 6 killers?",
            keyQuestions: ["Exertional or at rest?", "Radiation to arm/jaw/back?", "Tearing or migrating?", "Pleuritic (worse with breathing)?", "Cardiac risk factors?"],
            cantMiss: [
                .init(name: "Acute coronary syndrome", clue: "Exertional, pressure, radiation, diaphoresis, risk factors"),
                .init(name: "Pulmonary embolism", clue: "Pleuritic, dyspnea, tachycardia, DVT risk"),
                .init(name: "Aortic dissection", clue: "Tearing pain radiating to back, BP differential"),
                .init(name: "Tension pneumothorax", clue: "Sudden dyspnea, absent breath sounds, tracheal deviation"),
                .init(name: "Cardiac tamponade", clue: "Beck's triad, pulsus paradoxus"),
                .init(name: "Esophageal rupture (Boerhaave)", clue: "After vomiting, subcutaneous emphysema")
            ],
            common: [
                .init(name: "GERD / esophageal spasm", clue: "Burning, postprandial, relieved by antacids"),
                .init(name: "Musculoskeletal / costochondritis", clue: "Reproducible with palpation"),
                .init(name: "Stable angina", clue: "Predictable with exertion, relieved by rest"),
                .init(name: "Pericarditis", clue: "Positional, pleuritic, diffuse ST elevation"),
                .init(name: "Anxiety / panic", clue: "Diagnosis of exclusion")
            ],
            keywords: ["cardiac", "acs", "mi", "angina", "pe"]
        ),
        DDxPresentation(
            id: "dyspnea", complaint: "Shortness of Breath", system: "Cardiopulmonary", icon: "lungs.fill",
            approach: "Split into cardiac vs pulmonary vs other, and acute vs chronic. Check oxygenation and work of breathing first.",
            keyQuestions: ["Sudden or gradual?", "Orthopnea / PND?", "Wheeze, cough, or fever?", "Chest pain or leg swelling?", "Known heart/lung disease?"],
            cantMiss: [
                .init(name: "Pulmonary embolism", clue: "Sudden, pleuritic, tachycardia, DVT risk"),
                .init(name: "Pulmonary edema / ACS", clue: "Orthopnea, crackles, S3, elevated JVP"),
                .init(name: "Tension pneumothorax", clue: "Unilateral absent sounds, hypotension"),
                .init(name: "Anaphylaxis", clue: "Urticaria, angioedema, exposure"),
                .init(name: "Severe asthma / COPD exacerbation", clue: "Silent chest is ominous")
            ],
            common: [
                .init(name: "Asthma / COPD", clue: "Wheeze, known disease, triggers"),
                .init(name: "Pneumonia", clue: "Fever, focal crackles, productive cough"),
                .init(name: "Heart failure", clue: "Edema, orthopnea, weight gain"),
                .init(name: "Anemia", clue: "Exertional, pallor, fatigue"),
                .init(name: "Anxiety / hyperventilation", clue: "Diagnosis of exclusion")
            ],
            keywords: ["sob", "breathless", "hypoxia", "respiratory"]
        ),
        DDxPresentation(
            id: "abdpain", complaint: "Abdominal Pain", system: "GI / Surgical", icon: "pills.fill",
            approach: "Localize the pain (RUQ, epigastric, RLQ, LLQ, diffuse) and always check a pregnancy test in anyone who can be pregnant.",
            keyQuestions: ["Where exactly, and does it radiate?", "Associated vomiting, fever, or GI bleeding?", "Last menstrual period?", "Peritoneal signs (rigid, rebound)?", "Vascular risk factors?"],
            cantMiss: [
                .init(name: "Ruptured AAA", clue: "Older, pulsatile mass, back pain, hypotension"),
                .init(name: "Mesenteric ischemia", clue: "Pain out of proportion to exam, AFib"),
                .init(name: "Perforated viscus", clue: "Sudden diffuse pain, rigid abdomen, free air"),
                .init(name: "Ectopic pregnancy", clue: "Positive hCG, adnexal pain"),
                .init(name: "Bowel obstruction", clue: "Distension, vomiting, no flatus"),
                .init(name: "Appendicitis", clue: "Periumbilical → RLQ migration")
            ],
            common: [
                .init(name: "Gastroenteritis", clue: "Diarrhea, diffuse crampy pain"),
                .init(name: "Biliary colic / cholecystitis", clue: "RUQ, postprandial, Murphy's sign"),
                .init(name: "Peptic ulcer disease", clue: "Epigastric, meal-related"),
                .init(name: "Renal colic", clue: "Flank → groin, hematuria, can't stay still"),
                .init(name: "Constipation / UTI", clue: "Common, often overlooked")
            ],
            keywords: ["belly", "stomach", "appendicitis", "acute abdomen"]
        ),
        DDxPresentation(
            id: "headache", complaint: "Headache", system: "Neurology", icon: "brain.head.profile",
            approach: "Distinguish primary (migraine, tension, cluster) from dangerous secondary causes. Screen for red flags before anchoring on 'just a migraine.'",
            keyQuestions: ["Thunderclap (max intensity in seconds)?", "Fever, neck stiffness, or rash?", "New focal deficit or vision change?", "Worse with lying down / Valsalva?", "Age > 50 or immunocompromised?"],
            cantMiss: [
                .init(name: "Subarachnoid hemorrhage", clue: "Thunderclap, 'worst headache of life'"),
                .init(name: "Meningitis / encephalitis", clue: "Fever, neck stiffness, altered mentation"),
                .init(name: "Mass lesion / raised ICP", clue: "Worse in morning, positional, papilledema"),
                .init(name: "Giant cell arteritis", clue: "Age >50, jaw claudication, high ESR"),
                .init(name: "CVST", clue: "Prothrombotic, progressive, papilledema"),
                .init(name: "Acute angle-closure glaucoma", clue: "Painful red eye, halos, mid-dilated pupil")
            ],
            common: [
                .init(name: "Migraine", clue: "Unilateral, throbbing, photophobia, aura"),
                .init(name: "Tension-type", clue: "Bilateral, band-like, non-disabling"),
                .init(name: "Cluster", clue: "Severe orbital, autonomic, male, cyclical"),
                .init(name: "Medication-overuse", clue: "Frequent analgesic use")
            ],
            keywords: ["migraine", "sah", "neuro", "cephalgia"]
        ),
        DDxPresentation(
            id: "syncope", complaint: "Syncope", system: "Cardiac / Neuro", icon: "bolt.heart.fill",
            approach: "Separate cardiac (dangerous) from reflex and orthostatic causes. Get an ECG on everyone.",
            keyQuestions: ["Exertional or preceded by palpitations?", "Any prodrome (nausea, warmth)?", "Positional (standing up)?", "Family history of sudden death?", "Prompt recovery?"],
            cantMiss: [
                .init(name: "Arrhythmia", clue: "Sudden, no prodrome, palpitations"),
                .init(name: "Structural cardiac (AS, HOCM)", clue: "Exertional, murmur"),
                .init(name: "Pulmonary embolism", clue: "Dyspnea, tachycardia, DVT risk"),
                .init(name: "Aortic dissection", clue: "Tearing chest/back pain"),
                .init(name: "Subarachnoid hemorrhage", clue: "Severe headache"),
                .init(name: "GI bleed / occult hemorrhage", clue: "Melena, orthostatic, anemia")
            ],
            common: [
                .init(name: "Vasovagal", clue: "Prodrome, triggers (pain, standing)"),
                .init(name: "Orthostatic hypotension", clue: "On standing, meds, dehydration"),
                .init(name: "Situational", clue: "Cough, micturition, defecation"),
                .init(name: "Medication effect", clue: "Antihypertensives, diuretics")
            ],
            keywords: ["fainting", "passed out", "loss of consciousness", "collapse"]
        ),
        DDxPresentation(
            id: "dizziness", complaint: "Dizziness / Vertigo", system: "Neuro / ENT", icon: "figure.walk.motion",
            approach: "Use timing and triggers (not just 'peripheral vs central'). A HINTS exam can distinguish a benign cause from a posterior stroke.",
            keyQuestions: ["Room spinning (vertigo) or light-headed?", "Triggered by head movement?", "Continuous or episodic?", "New hearing loss or neuro signs?", "Vascular risk factors?"],
            cantMiss: [
                .init(name: "Posterior circulation stroke", clue: "Central HINTS, other neuro signs, risk factors"),
                .init(name: "Vertebral artery dissection", clue: "Neck pain, young, trauma"),
                .init(name: "Cerebellar hemorrhage", clue: "Ataxia, headache, can't walk")
            ],
            common: [
                .init(name: "BPPV", clue: "Brief, positional, Dix-Hallpike positive"),
                .init(name: "Vestibular neuritis", clue: "Continuous, after viral illness, peripheral HINTS"),
                .init(name: "Ménière disease", clue: "Vertigo + hearing loss + tinnitus"),
                .init(name: "Orthostatic / medication", clue: "Light-headed on standing")
            ],
            keywords: ["vertigo", "spinning", "balance", "bppv", "hints"]
        ),
        DDxPresentation(
            id: "ams", complaint: "Altered Mental Status", system: "Neuro / Systemic", icon: "exclamationmark.brain",
            approach: "Run the AEIOU-TIPS framework and check a glucose immediately. Most AMS is metabolic, toxic, or infectious — not primary neuro.",
            keyQuestions: ["Fingerstick glucose?", "Vital signs and O₂ sat?", "New meds, toxins, or alcohol?", "Fever or signs of infection?", "Focal neuro deficit?"],
            cantMiss: [
                .init(name: "Hypoglycemia", clue: "Check glucose first — reversible"),
                .init(name: "Hypoxia / hypercarbia", clue: "Low sat, respiratory failure"),
                .init(name: "Stroke / ICH", clue: "Focal deficit, sudden onset"),
                .init(name: "Meningitis / encephalitis", clue: "Fever, neck stiffness"),
                .init(name: "Toxidrome / overdose", clue: "Pupils, vitals, exposure"),
                .init(name: "Sepsis", clue: "Fever, hypotension, source")
            ],
            common: [
                .init(name: "Delirium (infection, meds)", clue: "Fluctuating, inattention, elderly"),
                .init(name: "Metabolic (Na, uremia, hepatic)", clue: "Labs, chronic disease"),
                .init(name: "Intoxication / withdrawal", clue: "History, exam"),
                .init(name: "Postictal state", clue: "Witnessed seizure, gradual recovery")
            ],
            keywords: ["confusion", "delirium", "encephalopathy", "unresponsive"]
        ),
        DDxPresentation(
            id: "backpain", complaint: "Acute Low Back Pain", system: "Musculoskeletal", icon: "figure.stand",
            approach: "Most is benign mechanical pain — but screen hard for the red flags that signal a dangerous cause before reassuring.",
            keyQuestions: ["Bowel/bladder incontinence or retention?", "Saddle anesthesia or leg weakness?", "Fever or IV drug use?", "History of cancer?", "Trauma or age > 50 with night pain?"],
            cantMiss: [
                .init(name: "Cauda equina syndrome", clue: "Urinary retention, saddle anesthesia, bilateral sciatica"),
                .init(name: "Spinal epidural abscess", clue: "Fever, IVDU, focal tenderness"),
                .init(name: "Malignancy / metastasis", clue: "Cancer history, weight loss, night pain"),
                .init(name: "Vertebral fracture", clue: "Trauma, osteoporosis, steroids"),
                .init(name: "Abdominal aortic aneurysm", clue: "Older, pulsatile mass, vascular risk")
            ],
            common: [
                .init(name: "Mechanical / muscular strain", clue: "No red flags, improves with movement"),
                .init(name: "Disc herniation / radiculopathy", clue: "Dermatomal, positive straight-leg raise"),
                .init(name: "Degenerative / spinal stenosis", clue: "Older, neurogenic claudication")
            ],
            keywords: ["lumbar", "sciatica", "cauda equina", "red flags"]
        )
    ]
}
