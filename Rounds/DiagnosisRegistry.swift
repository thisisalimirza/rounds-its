//
//  DiagnosisRegistry.swift
//  Rounds
//
//  Master registry of all diagnoses. Each diagnosis is defined once with all its
//  alternative names consolidated. Cases reference diagnoses by slug ID, allowing
//  multiple cases to share the same diagnosis (different clinical presentations).
//

import Foundation

// MARK: - Diagnosis Definition

/// A single diagnosis entry in the master registry
struct DiagnosisDefinition: Identifiable, Hashable, Sendable {
    /// Human-readable slug identifier (e.g., "giant-cell-arteritis")
    let id: String

    /// Canonical display name shown in autocomplete (e.g., "Giant Cell Arteritis")
    let canonicalName: String

    /// All accepted alternative names/spellings
    let alternativeNames: [String]

    /// Primary category for organization
    let category: String

    /// All searchable names (canonical + alternatives)
    var allNames: [String] {
        [canonicalName] + alternativeNames
    }

    /// Check if a guess matches this diagnosis (case-insensitive, whitespace-normalized)
    func matches(_ guess: String) -> Bool {
        let normalizedGuess = Self.normalize(guess)
        guard !normalizedGuess.isEmpty else { return false }
        return allNames.contains { Self.normalize($0) == normalizedGuess }
    }

    /// Normalize text for comparison
    static func normalize(_ text: String) -> String {
        text.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

// MARK: - Diagnosis Registry

/// Master registry of all diagnoses in the app
struct DiagnosisRegistry {

    /// All registered diagnoses - the single source of truth
    static let all: [DiagnosisDefinition] = [

        // MARK: - Cardiology

        DiagnosisDefinition(
            id: "myocardial-infarction",
            canonicalName: "Myocardial Infarction",
            alternativeNames: ["MI", "Heart Attack", "Acute MI", "STEMI", "NSTEMI"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "aortic-dissection",
            canonicalName: "Aortic Dissection",
            alternativeNames: ["Dissecting Aortic Aneurysm"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "acute-pericarditis",
            canonicalName: "Acute Pericarditis",
            alternativeNames: ["Pericarditis"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "infective-endocarditis",
            canonicalName: "Infective Endocarditis",
            alternativeNames: ["IE", "Bacterial Endocarditis", "Endocarditis"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "wpw-syndrome",
            canonicalName: "Wolff-Parkinson-White Syndrome",
            alternativeNames: ["WPW", "WPW Syndrome", "Wolff Parkinson White"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "hypertrophic-cardiomyopathy",
            canonicalName: "Hypertrophic Cardiomyopathy",
            alternativeNames: ["HCM", "HOCM", "Hypertrophic Obstructive Cardiomyopathy"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "atrial-fibrillation",
            canonicalName: "Atrial Fibrillation",
            alternativeNames: ["AFib", "AF", "A-Fib"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "acute-rheumatic-fever",
            canonicalName: "Acute Rheumatic Fever",
            alternativeNames: ["Rheumatic Fever", "ARF"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "cardiac-tamponade",
            canonicalName: "Cardiac Tamponade",
            alternativeNames: ["Tamponade", "Pericardial Tamponade"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "dilated-cardiomyopathy",
            canonicalName: "Dilated Cardiomyopathy",
            alternativeNames: ["DCM"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "mitral-regurgitation",
            canonicalName: "Mitral Regurgitation",
            alternativeNames: ["MR", "Mitral Insufficiency"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "aortic-stenosis",
            canonicalName: "Aortic Stenosis",
            alternativeNames: ["AS"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "ventricular-septal-defect",
            canonicalName: "Ventricular Septal Defect",
            alternativeNames: ["VSD"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "coarctation-of-aorta",
            canonicalName: "Coarctation of the Aorta",
            alternativeNames: ["Aortic Coarctation", "CoA"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "tetralogy-of-fallot",
            canonicalName: "Tetralogy of Fallot",
            alternativeNames: ["TOF", "Tet Spell", "Tetralogy of Fallot - Tet Spell"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "restrictive-cardiomyopathy",
            canonicalName: "Restrictive Cardiomyopathy",
            alternativeNames: ["RCM"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "takotsubo-cardiomyopathy",
            canonicalName: "Takotsubo Cardiomyopathy",
            alternativeNames: ["Broken Heart Syndrome", "Stress Cardiomyopathy"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "mitral-stenosis",
            canonicalName: "Mitral Stenosis",
            alternativeNames: ["MS"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "aortic-regurgitation",
            canonicalName: "Aortic Regurgitation",
            alternativeNames: ["AR", "Aortic Insufficiency"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "atrial-septal-defect",
            canonicalName: "Atrial Septal Defect",
            alternativeNames: ["ASD"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "patent-ductus-arteriosus",
            canonicalName: "Patent Ductus Arteriosus",
            alternativeNames: ["PDA"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "dressler-syndrome",
            canonicalName: "Dressler Syndrome",
            alternativeNames: ["Post-MI Pericarditis", "Postmyocardial Infarction Syndrome"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "myocarditis",
            canonicalName: "Myocarditis",
            alternativeNames: ["Viral Myocarditis"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "pulmonary-hypertension",
            canonicalName: "Pulmonary Hypertension",
            alternativeNames: ["PH", "PAH", "Pulmonary Arterial Hypertension"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "tricuspid-regurgitation",
            canonicalName: "Tricuspid Regurgitation",
            alternativeNames: ["TR"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "pulmonic-stenosis",
            canonicalName: "Pulmonic Stenosis",
            alternativeNames: ["PS", "Pulmonary Stenosis"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "brugada-syndrome",
            canonicalName: "Brugada Syndrome",
            alternativeNames: ["Brugada"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "long-qt-syndrome",
            canonicalName: "Long QT Syndrome",
            alternativeNames: ["LQTS"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "transposition-great-arteries",
            canonicalName: "Transposition of Great Arteries",
            alternativeNames: ["TGA", "D-TGA"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "eisenmenger-syndrome",
            canonicalName: "Eisenmenger Syndrome",
            alternativeNames: ["Eisenmenger"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "sick-sinus-syndrome",
            canonicalName: "Sick Sinus Syndrome",
            alternativeNames: ["SSS", "Sinus Node Dysfunction"],
            category: "Cardiology"
        ),
        DiagnosisDefinition(
            id: "patent-foramen-ovale",
            canonicalName: "Patent Foramen Ovale",
            alternativeNames: ["PFO"],
            category: "Cardiology"
        ),

        // MARK: - Neurology

        DiagnosisDefinition(
            id: "multiple-sclerosis",
            canonicalName: "Multiple Sclerosis",
            alternativeNames: ["MS"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "subarachnoid-hemorrhage",
            canonicalName: "Subarachnoid Hemorrhage",
            alternativeNames: ["SAH"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "myasthenia-gravis",
            canonicalName: "Myasthenia Gravis",
            alternativeNames: ["MG"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "guillain-barre-syndrome",
            canonicalName: "Guillain-Barre Syndrome",
            alternativeNames: ["GBS", "Guillain Barre", "Guillain-Barre"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "parkinson-disease",
            canonicalName: "Parkinson Disease",
            alternativeNames: ["PD", "Parkinson's Disease", "Parkinsons"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "alzheimer-disease",
            canonicalName: "Alzheimer Disease",
            alternativeNames: ["AD", "Alzheimer's Disease", "Alzheimers"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "ischemic-stroke",
            canonicalName: "Ischemic Stroke",
            alternativeNames: ["Stroke", "CVA", "Cerebrovascular Accident"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "migraine",
            canonicalName: "Migraine",
            alternativeNames: ["Migraine Headache"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "seizure-disorder",
            canonicalName: "Seizure Disorder",
            alternativeNames: ["Epilepsy", "Seizures"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "huntington-disease",
            canonicalName: "Huntington Disease",
            alternativeNames: ["HD", "Huntington's Disease", "Huntingtons"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "bells-palsy",
            canonicalName: "Bell's Palsy",
            alternativeNames: ["Bells Palsy", "Bell Palsy"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "als",
            canonicalName: "Amyotrophic Lateral Sclerosis",
            alternativeNames: ["ALS", "Lou Gehrig Disease", "Lou Gehrig's Disease"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "pseudotumor-cerebri",
            canonicalName: "Pseudotumor Cerebri",
            alternativeNames: ["Idiopathic Intracranial Hypertension", "IIH"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "normal-pressure-hydrocephalus",
            canonicalName: "Normal Pressure Hydrocephalus",
            alternativeNames: ["NPH"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "wernicke-encephalopathy",
            canonicalName: "Wernicke Encephalopathy",
            alternativeNames: ["Wernicke's Encephalopathy", "Wernicke-Korsakoff"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "central-pontine-myelinolysis",
            canonicalName: "Central Pontine Myelinolysis",
            alternativeNames: ["CPM", "Osmotic Demyelination Syndrome"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "trigeminal-neuralgia",
            canonicalName: "Trigeminal Neuralgia",
            alternativeNames: ["Tic Douloureux"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "creutzfeldt-jakob-disease",
            canonicalName: "Creutzfeldt-Jakob Disease",
            alternativeNames: ["CJD", "Creutzfeldt Jakob"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "friedreich-ataxia",
            canonicalName: "Friedreich Ataxia",
            alternativeNames: ["Friedreich's Ataxia"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "charcot-marie-tooth",
            canonicalName: "Charcot-Marie-Tooth Disease",
            alternativeNames: ["CMT"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "syringomyelia",
            canonicalName: "Syringomyelia",
            alternativeNames: ["Syrinx"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "chiari-malformation",
            canonicalName: "Posterior Fossa Malformations - Chiari",
            alternativeNames: ["Chiari Malformation", "Arnold-Chiari"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "lambert-eaton",
            canonicalName: "Lambert-Eaton Myasthenic Syndrome",
            alternativeNames: ["LEMS", "Lambert Eaton"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "vertebrobasilar-insufficiency",
            canonicalName: "Vertebrobasilar Insufficiency",
            alternativeNames: ["VBI"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "cavernous-sinus-thrombosis",
            canonicalName: "Cavernous Sinus Thrombosis",
            alternativeNames: ["CST"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "subdural-hematoma",
            canonicalName: "Subdural Hematoma",
            alternativeNames: ["SDH"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "epidural-hematoma",
            canonicalName: "Epidural Hematoma",
            alternativeNames: ["EDH"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "tia",
            canonicalName: "Transient Ischemic Attack",
            alternativeNames: ["TIA", "Mini Stroke"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "essential-tremor",
            canonicalName: "Benign Essential Tremor",
            alternativeNames: ["Essential Tremor"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "neurofibromatosis-1",
            canonicalName: "Neurofibromatosis Type 1",
            alternativeNames: ["NF1", "Von Recklinghausen Disease"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "tuberous-sclerosis",
            canonicalName: "Tuberous Sclerosis",
            alternativeNames: ["TSC"],
            category: "Neurology"
        ),
        DiagnosisDefinition(
            id: "glioblastoma",
            canonicalName: "Glioblastoma Multiforme",
            alternativeNames: ["GBM", "Grade IV Astrocytoma", "Glioblastoma"],
            category: "Neurology"
        ),

        // MARK: - Pulmonology

        DiagnosisDefinition(
            id: "pulmonary-embolism",
            canonicalName: "Pulmonary Embolism",
            alternativeNames: ["PE"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "sarcoidosis",
            canonicalName: "Sarcoidosis",
            alternativeNames: ["Sarcoid"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "asthma-exacerbation",
            canonicalName: "Asthma Exacerbation",
            alternativeNames: ["Asthma Attack", "Acute Asthma"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "pneumothorax",
            canonicalName: "Pneumothorax",
            alternativeNames: ["Collapsed Lung"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "tension-pneumothorax",
            canonicalName: "Tension Pneumothorax",
            alternativeNames: [],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "copd",
            canonicalName: "Chronic Obstructive Pulmonary Disease",
            alternativeNames: ["COPD", "Emphysema", "Chronic Bronchitis"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "cystic-fibrosis",
            canonicalName: "Cystic Fibrosis",
            alternativeNames: ["CF"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "idiopathic-pulmonary-fibrosis",
            canonicalName: "Idiopathic Pulmonary Fibrosis",
            alternativeNames: ["IPF"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "community-acquired-pneumonia",
            canonicalName: "Community-Acquired Pneumonia",
            alternativeNames: ["CAP", "Pneumonia"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "sleep-apnea",
            canonicalName: "Sleep Apnea",
            alternativeNames: ["OSA", "Obstructive Sleep Apnea"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "lung-adenocarcinoma",
            canonicalName: "Lung Adenocarcinoma",
            alternativeNames: ["Lung Cancer", "NSCLC"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "alpha-1-antitrypsin-deficiency",
            canonicalName: "Alpha-1 Antitrypsin Deficiency",
            alternativeNames: ["A1AT Deficiency", "Alpha-1"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "aspiration-pneumonia",
            canonicalName: "Aspiration Pneumonia",
            alternativeNames: [],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "bronchiectasis",
            canonicalName: "Bronchiectasis",
            alternativeNames: [],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "hypersensitivity-pneumonitis",
            canonicalName: "Hypersensitivity Pneumonitis",
            alternativeNames: ["HP", "Extrinsic Allergic Alveolitis"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "ards",
            canonicalName: "Acute Respiratory Distress Syndrome",
            alternativeNames: ["ARDS"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "silicosis",
            canonicalName: "Silicosis",
            alternativeNames: [],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "asbestosis",
            canonicalName: "Asbestosis",
            alternativeNames: [],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "small-cell-lung-cancer",
            canonicalName: "Small Cell Lung Cancer",
            alternativeNames: ["SCLC"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "mesothelioma",
            canonicalName: "Mesothelioma",
            alternativeNames: ["Malignant Mesothelioma"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "pancoast-tumor",
            canonicalName: "Pancoast Tumor",
            alternativeNames: ["Superior Sulcus Tumor"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "granulomatosis-with-polyangiitis",
            canonicalName: "Granulomatosis with Polyangiitis",
            alternativeNames: ["Wegener Granulomatosis", "Wegener's Granulomatosis", "GPA"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "churg-strauss-syndrome",
            canonicalName: "Churg-Strauss Syndrome",
            alternativeNames: ["Eosinophilic Granulomatosis with Polyangiitis", "EGPA", "Churg Strauss Syndrome"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "kartagener-syndrome",
            canonicalName: "Kartagener Syndrome",
            alternativeNames: ["Primary Ciliary Dyskinesia", "Kartagener Syndrome Ciliary Defect"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "hamartoma",
            canonicalName: "Hamartoma",
            alternativeNames: ["Pulmonary Hamartoma"],
            category: "Pulmonology"
        ),
        DiagnosisDefinition(
            id: "loeffler-syndrome",
            canonicalName: "Loeffler Syndrome",
            alternativeNames: ["Loffler Syndrome", "Simple Pulmonary Eosinophilia"],
            category: "Pulmonology"
        ),

        // MARK: - Gastroenterology

        DiagnosisDefinition(
            id: "crohns-disease",
            canonicalName: "Crohn's Disease",
            alternativeNames: ["Crohn Disease", "Crohns", "Regional Enteritis"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "ulcerative-colitis",
            canonicalName: "Ulcerative Colitis",
            alternativeNames: ["UC"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "appendicitis",
            canonicalName: "Appendicitis",
            alternativeNames: ["Acute Appendicitis"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "celiac-disease",
            canonicalName: "Celiac Disease",
            alternativeNames: ["Celiac Sprue", "Gluten Enteropathy"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "acute-cholecystitis",
            canonicalName: "Acute Cholecystitis",
            alternativeNames: ["Cholecystitis"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "hepatic-encephalopathy",
            canonicalName: "Hepatic Encephalopathy",
            alternativeNames: ["HE"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "peptic-ulcer-disease",
            canonicalName: "Peptic Ulcer Disease",
            alternativeNames: ["PUD", "Gastric Ulcer", "Duodenal Ulcer"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "esophageal-varices",
            canonicalName: "Esophageal Varices",
            alternativeNames: ["Varices"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "diverticulitis",
            canonicalName: "Diverticulitis",
            alternativeNames: ["Acute Diverticulitis"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "primary-sclerosing-cholangitis",
            canonicalName: "Primary Sclerosing Cholangitis",
            alternativeNames: ["PSC"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "alcoholic-hepatitis",
            canonicalName: "Alcoholic Hepatitis",
            alternativeNames: [],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "acute-pancreatitis",
            canonicalName: "Acute Pancreatitis",
            alternativeNames: ["Pancreatitis"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "achalasia",
            canonicalName: "Achalasia",
            alternativeNames: [],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "mallory-weiss-tear",
            canonicalName: "Mallory-Weiss Tear",
            alternativeNames: ["Mallory Weiss Syndrome"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "zenker-diverticulum",
            canonicalName: "Zenker Diverticulum",
            alternativeNames: ["Zenker's Diverticulum", "Pharyngeal Pouch"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "barrett-esophagus",
            canonicalName: "Barrett Esophagus",
            alternativeNames: ["Barrett's Esophagus"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "primary-biliary-cholangitis",
            canonicalName: "Primary Biliary Cholangitis",
            alternativeNames: ["PBC", "Primary Biliary Cirrhosis"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "whipple-disease",
            canonicalName: "Whipple Disease",
            alternativeNames: ["Whipple's Disease"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "hemochromatosis",
            canonicalName: "Hemochromatosis",
            alternativeNames: ["Iron Overload", "Hereditary Hemochromatosis"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "wilson-disease",
            canonicalName: "Wilson Disease",
            alternativeNames: ["Wilson's Disease", "Hepatolenticular Degeneration"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "budd-chiari-syndrome",
            canonicalName: "Budd-Chiari Syndrome",
            alternativeNames: ["Budd Chiari", "Hepatic Vein Thrombosis"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "spontaneous-bacterial-peritonitis",
            canonicalName: "Spontaneous Bacterial Peritonitis",
            alternativeNames: ["SBP"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "peutz-jeghers-syndrome",
            canonicalName: "Peutz-Jeghers Syndrome",
            alternativeNames: ["PJS"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "familial-adenomatous-polyposis",
            canonicalName: "Familial Adenomatous Polyposis",
            alternativeNames: ["FAP"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "lynch-syndrome",
            canonicalName: "Lynch Syndrome",
            alternativeNames: ["HNPCC", "Hereditary Nonpolyposis Colorectal Cancer"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "ogilvie-syndrome",
            canonicalName: "Ogilvie Syndrome",
            alternativeNames: ["Acute Colonic Pseudo-obstruction"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "tropical-sprue",
            canonicalName: "Tropical Sprue",
            alternativeNames: [],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "ischemic-colitis",
            canonicalName: "Ischemic Colitis",
            alternativeNames: [],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "carcinoid-tumor",
            canonicalName: "Carcinoid Tumor",
            alternativeNames: ["Carcinoid"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "mesenteric-ischemia",
            canonicalName: "Mesenteric Ischemia",
            alternativeNames: ["Acute Mesenteric Ischemia"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "pseudomembranous-colitis",
            canonicalName: "Pseudomembranous Colitis",
            alternativeNames: ["C. diff Colitis"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "clostridium-difficile-colitis",
            canonicalName: "Clostridium difficile Colitis",
            alternativeNames: ["C. diff", "CDI", "C difficile Infection"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "meckel-diverticulum",
            canonicalName: "Meckel Diverticulum",
            alternativeNames: ["Meckel's Diverticulum"],
            category: "Gastroenterology"
        ),
        DiagnosisDefinition(
            id: "gardner-syndrome",
            canonicalName: "Gardner Syndrome",
            alternativeNames: ["FAP with Extra-intestinal Manifestations"],
            category: "Gastroenterology"
        ),

        // MARK: - Nephrology

        DiagnosisDefinition(
            id: "acute-kidney-injury",
            canonicalName: "Acute Kidney Injury",
            alternativeNames: ["AKI", "Acute Renal Failure", "ARF"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "nephrotic-syndrome",
            canonicalName: "Nephrotic Syndrome",
            alternativeNames: [],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "iga-nephropathy",
            canonicalName: "IgA Nephropathy",
            alternativeNames: ["Berger Disease", "Berger's Disease"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "acute-tubular-necrosis",
            canonicalName: "Acute Tubular Necrosis",
            alternativeNames: ["ATN"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "polycystic-kidney-disease",
            canonicalName: "Polycystic Kidney Disease",
            alternativeNames: ["PKD", "ADPKD", "Polycystic Kidney Disease (ADPKD)", "Adult Polycystic Kidney Disease", "Adult PKD"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "goodpasture-syndrome",
            canonicalName: "Goodpasture Syndrome",
            alternativeNames: ["Anti-GBM Disease", "Goodpasture's Syndrome"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "acute-interstitial-nephritis",
            canonicalName: "Acute Interstitial Nephritis",
            alternativeNames: ["AIN"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "renal-artery-stenosis",
            canonicalName: "Renal Artery Stenosis",
            alternativeNames: ["RAS"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "nephrolithiasis",
            canonicalName: "Nephrolithiasis",
            alternativeNames: ["Kidney Stones", "Renal Calculi"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "membranous-nephropathy",
            canonicalName: "Membranous Nephropathy",
            alternativeNames: ["Membranous Glomerulonephritis"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "hemolytic-uremic-syndrome",
            canonicalName: "Hemolytic Uremic Syndrome",
            alternativeNames: ["HUS"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "alport-syndrome",
            canonicalName: "Alport Syndrome",
            alternativeNames: [],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "fanconi-syndrome",
            canonicalName: "Fanconi Syndrome",
            alternativeNames: [],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "bartter-syndrome",
            canonicalName: "Bartter Syndrome",
            alternativeNames: [],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "gitelman-syndrome",
            canonicalName: "Gitelman Syndrome",
            alternativeNames: [],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "focal-segmental-glomerulosclerosis",
            canonicalName: "Focal Segmental Glomerulosclerosis",
            alternativeNames: ["FSGS"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "psgn",
            canonicalName: "Poststreptococcal Glomerulonephritis",
            alternativeNames: ["PSGN", "Post-Streptococcal Glomerulonephritis", "Post Streptococcal Glomerulonephritis"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "liddle-syndrome",
            canonicalName: "Liddle Syndrome",
            alternativeNames: ["Pseudohyperaldosteronism"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "rpgn",
            canonicalName: "Rapidly Progressive Glomerulonephritis",
            alternativeNames: ["RPGN", "Crescentic Glomerulonephritis"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "diabetic-nephropathy",
            canonicalName: "Diabetic Nephropathy",
            alternativeNames: ["Diabetic Kidney Disease"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "hypertensive-nephropathy",
            canonicalName: "Hypertensive Nephropathy",
            alternativeNames: ["Hypertensive Kidney Disease"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "contrast-induced-nephropathy",
            canonicalName: "Contrast-Induced Nephropathy",
            alternativeNames: ["CIN", "Contrast Nephropathy"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "rhabdomyolysis",
            canonicalName: "Rhabdomyolysis",
            alternativeNames: [],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "tumor-lysis-syndrome",
            canonicalName: "Tumor Lysis Syndrome",
            alternativeNames: ["TLS"],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "medullary-sponge-kidney",
            canonicalName: "Medullary Sponge Kidney",
            alternativeNames: [],
            category: "Nephrology"
        ),
        DiagnosisDefinition(
            id: "minimal-change-disease",
            canonicalName: "Minimal Change Disease",
            alternativeNames: ["MCD", "Nil Disease"],
            category: "Nephrology"
        ),

        // MARK: - Endocrinology

        DiagnosisDefinition(
            id: "diabetic-ketoacidosis",
            canonicalName: "Diabetic Ketoacidosis",
            alternativeNames: ["DKA"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "graves-disease",
            canonicalName: "Graves Disease",
            alternativeNames: ["Graves' Disease", "Basedow Disease", "Hyperthyroidism", "Thyrotoxicosis", "Toxic Diffuse Goiter"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "hashimoto-thyroiditis",
            canonicalName: "Hashimoto Thyroiditis",
            alternativeNames: ["Hashimoto's Thyroiditis", "Chronic Lymphocytic Thyroiditis"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "cushing-syndrome",
            canonicalName: "Cushing Syndrome",
            alternativeNames: ["Cushing's Syndrome", "Hypercortisolism"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "addison-disease",
            canonicalName: "Addison Disease",
            alternativeNames: ["Addison's Disease", "Primary Adrenal Insufficiency"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "hypothyroidism",
            canonicalName: "Hypothyroidism",
            alternativeNames: ["Underactive Thyroid"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "diabetes-insipidus",
            canonicalName: "Diabetes Insipidus",
            alternativeNames: ["DI", "Central Diabetes Insipidus", "Diabetes Insipidus (Central)", "Neurogenic DI"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "siadh",
            canonicalName: "SIADH",
            alternativeNames: ["Syndrome of Inappropriate ADH", "Syndrome of Inappropriate Antidiuretic Hormone"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "pheochromocytoma",
            canonicalName: "Pheochromocytoma",
            alternativeNames: ["Pheo"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "hyperparathyroidism",
            canonicalName: "Hyperparathyroidism",
            alternativeNames: ["Primary Hyperparathyroidism"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "acromegaly",
            canonicalName: "Acromegaly",
            alternativeNames: [],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "type-2-diabetes",
            canonicalName: "Type 2 Diabetes Mellitus",
            alternativeNames: ["T2DM", "Type 2 Diabetes", "Diabetes Mellitus"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "conn-syndrome",
            canonicalName: "Conn Syndrome",
            alternativeNames: ["Primary Hyperaldosteronism"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "secondary-hyperaldosteronism",
            canonicalName: "Hyperaldosteronism Secondary",
            alternativeNames: ["Secondary Hyperaldosteronism"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "carcinoid-syndrome",
            canonicalName: "Carcinoid Syndrome",
            alternativeNames: [],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "zollinger-ellison-syndrome",
            canonicalName: "Zollinger-Ellison Syndrome",
            alternativeNames: ["ZES", "Gastrinoma"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "men-1",
            canonicalName: "Multiple Endocrine Neoplasia Type 1",
            alternativeNames: ["MEN1", "MEN 1"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "men-2",
            canonicalName: "Multiple Endocrine Neoplasia Type 2",
            alternativeNames: ["MEN2", "MEN 2"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "sheehan-syndrome",
            canonicalName: "Sheehan Syndrome",
            alternativeNames: ["Postpartum Hypopituitarism"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "craniopharyngioma",
            canonicalName: "Craniopharyngioma",
            alternativeNames: [],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "insulinoma",
            canonicalName: "Insulinoma",
            alternativeNames: [],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "glucagonoma",
            canonicalName: "Glucagonoma",
            alternativeNames: [],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "vipoma",
            canonicalName: "VIPoma",
            alternativeNames: ["Verner-Morrison Syndrome", "WDHA Syndrome"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "congenital-adrenal-hyperplasia",
            canonicalName: "Congenital Adrenal Hyperplasia",
            alternativeNames: ["CAH"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "klinefelter-syndrome",
            canonicalName: "Klinefelter Syndrome",
            alternativeNames: ["47 XXY", "XXY"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "turner-syndrome",
            canonicalName: "Turner Syndrome",
            alternativeNames: ["45 XO", "XO"],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "prolactinoma",
            canonicalName: "Prolactinoma",
            alternativeNames: [],
            category: "Endocrinology"
        ),
        DiagnosisDefinition(
            id: "congenital-hypothyroidism",
            canonicalName: "Congenital Hypothyroidism",
            alternativeNames: ["Cretinism"],
            category: "Endocrinology"
        ),

        // MARK: - Rheumatology (CONSOLIDATED DUPLICATES)

        DiagnosisDefinition(
            id: "systemic-lupus-erythematosus",
            canonicalName: "Systemic Lupus Erythematosus",
            alternativeNames: ["SLE", "Lupus"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "giant-cell-arteritis",
            canonicalName: "Giant Cell Arteritis",
            alternativeNames: ["Temporal Arteritis", "GCA", "Cranial Arteritis"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "ankylosing-spondylitis",
            canonicalName: "Ankylosing Spondylitis",
            alternativeNames: ["AS"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "gout",
            canonicalName: "Gout",
            alternativeNames: ["Gouty Arthritis"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "rheumatoid-arthritis",
            canonicalName: "Rheumatoid Arthritis",
            alternativeNames: ["RA"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "osteoarthritis",
            canonicalName: "Osteoarthritis",
            alternativeNames: ["OA", "Degenerative Joint Disease"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "pseudogout",
            canonicalName: "Pseudogout",
            alternativeNames: ["CPPD", "Calcium Pyrophosphate Deposition Disease"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "reactive-arthritis",
            canonicalName: "Reactive Arthritis",
            alternativeNames: ["Reiter Syndrome"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "sjogren-syndrome",
            canonicalName: "Sjogren Syndrome",
            alternativeNames: ["Sjögren Syndrome", "Sjogren's Syndrome", "Sjögren's Syndrome", "Sicca Syndrome", "Sjogren's"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "polymyalgia-rheumatica",
            canonicalName: "Polymyalgia Rheumatica",
            alternativeNames: ["PMR"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "systemic-sclerosis",
            canonicalName: "Scleroderma",
            alternativeNames: ["Systemic Sclerosis", "Scleroderma (Diffuse)", "Diffuse Scleroderma", "SSc"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "dermatomyositis",
            canonicalName: "Dermatomyositis",
            alternativeNames: ["DM"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "behcet-disease",
            canonicalName: "Behcet Disease",
            alternativeNames: ["Behçet Disease", "Behcet's Disease"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "mixed-connective-tissue-disease",
            canonicalName: "Mixed Connective Tissue Disease",
            alternativeNames: ["MCTD"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "takayasu-arteritis",
            canonicalName: "Takayasu Arteritis",
            alternativeNames: ["Pulseless Disease"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "polyarteritis-nodosa",
            canonicalName: "Polyarteritis Nodosa",
            alternativeNames: ["PAN"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "relapsing-polychondritis",
            canonicalName: "Relapsing Polychondritis",
            alternativeNames: [],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "adult-onset-still-disease",
            canonicalName: "Adult-Onset Still Disease",
            alternativeNames: ["AOSD", "Adult Still Disease"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "felty-syndrome",
            canonicalName: "Felty Syndrome",
            alternativeNames: [],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "henoch-schonlein-purpura",
            canonicalName: "Henoch-Schonlein Purpura",
            alternativeNames: ["HSP", "IgA Vasculitis", "Henoch-Schönlein Purpura"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "microscopic-polyangiitis",
            canonicalName: "Microscopic Polyangiitis",
            alternativeNames: ["MPA"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "cryoglobulinemia",
            canonicalName: "Cryoglobulinemia",
            alternativeNames: [],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "antiphospholipid-syndrome",
            canonicalName: "Antiphospholipid Syndrome",
            alternativeNames: ["APS", "APLS"],
            category: "Rheumatology"
        ),
        DiagnosisDefinition(
            id: "septic-arthritis",
            canonicalName: "Septic Arthritis",
            alternativeNames: ["Infectious Arthritis"],
            category: "Rheumatology"
        ),

        // MARK: - Hematology

        DiagnosisDefinition(
            id: "sickle-cell-crisis",
            canonicalName: "Sickle Cell Crisis",
            alternativeNames: ["Sickle Cell Disease", "SCD", "Vaso-occlusive Crisis"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "iron-deficiency-anemia",
            canonicalName: "Iron Deficiency Anemia",
            alternativeNames: ["IDA"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "apl",
            canonicalName: "Acute Promyelocytic Leukemia",
            alternativeNames: ["APL", "M3 AML"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "itp",
            canonicalName: "Immune Thrombocytopenic Purpura",
            alternativeNames: ["ITP", "Idiopathic Thrombocytopenic Purpura"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "vitamin-b12-deficiency",
            canonicalName: "Vitamin B12 Deficiency",
            alternativeNames: ["B12 Deficiency", "Cobalamin Deficiency"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "aml",
            canonicalName: "Acute Myeloid Leukemia",
            alternativeNames: ["AML"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "all",
            canonicalName: "Acute Lymphoblastic Leukemia",
            alternativeNames: ["ALL"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "cml",
            canonicalName: "Chronic Myeloid Leukemia",
            alternativeNames: ["CML"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "hodgkin-lymphoma",
            canonicalName: "Hodgkin Lymphoma",
            alternativeNames: ["Hodgkin's Lymphoma", "Hodgkin Disease"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "non-hodgkin-lymphoma",
            canonicalName: "Non-Hodgkin Lymphoma",
            alternativeNames: ["NHL"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "hemophilia-a",
            canonicalName: "Hemophilia A",
            alternativeNames: ["Factor VIII Deficiency"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "von-willebrand-disease",
            canonicalName: "Von Willebrand Disease",
            alternativeNames: ["vWD"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "dic",
            canonicalName: "Disseminated Intravascular Coagulation",
            alternativeNames: ["DIC"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "thalassemia",
            canonicalName: "Thalassemia",
            alternativeNames: ["Beta Thalassemia", "Alpha Thalassemia"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "g6pd-deficiency",
            canonicalName: "Glucose-6-Phosphate Dehydrogenase Deficiency",
            alternativeNames: ["G6PD Deficiency"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "hereditary-spherocytosis",
            canonicalName: "Hereditary Spherocytosis",
            alternativeNames: ["HS"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "pnh",
            canonicalName: "Paroxysmal Nocturnal Hemoglobinuria",
            alternativeNames: ["PNH"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "polycythemia-vera",
            canonicalName: "Polycythemia Vera",
            alternativeNames: ["PV"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "essential-thrombocythemia",
            canonicalName: "Essential Thrombocythemia",
            alternativeNames: ["ET"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "myelofibrosis",
            canonicalName: "Myelofibrosis",
            alternativeNames: ["Primary Myelofibrosis"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "multiple-myeloma",
            canonicalName: "Multiple Myeloma",
            alternativeNames: ["MM", "Plasma Cell Myeloma"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "waldenstrom-macroglobulinemia",
            canonicalName: "Waldenstrom Macroglobulinemia",
            alternativeNames: ["WM", "Waldenström Macroglobulinemia"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "ttp",
            canonicalName: "Thrombotic Thrombocytopenic Purpura",
            alternativeNames: ["TTP"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "aplastic-anemia",
            canonicalName: "Aplastic Anemia",
            alternativeNames: [],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "myelodysplastic-syndrome",
            canonicalName: "Myelodysplastic Syndrome",
            alternativeNames: ["MDS"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "hairy-cell-leukemia",
            canonicalName: "Hairy Cell Leukemia",
            alternativeNames: ["HCL"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "cll",
            canonicalName: "Chronic Lymphocytic Leukemia",
            alternativeNames: ["CLL"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "langerhans-cell-histiocytosis",
            canonicalName: "Langerhans Cell Histiocytosis",
            alternativeNames: ["LCH", "Histiocytosis X"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "bernard-soulier-syndrome",
            canonicalName: "Bernard-Soulier Syndrome",
            alternativeNames: [],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "glanzmann-thrombasthenia",
            canonicalName: "Glanzmann Thrombasthenia",
            alternativeNames: [],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "factor-v-leiden",
            canonicalName: "Factor V Leiden",
            alternativeNames: ["FVL"],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "pernicious-anemia",
            canonicalName: "Pernicious Anemia",
            alternativeNames: [],
            category: "Hematology"
        ),
        DiagnosisDefinition(
            id: "burkitt-lymphoma",
            canonicalName: "Burkitt Lymphoma",
            alternativeNames: ["Burkitt's Lymphoma"],
            category: "Hematology"
        ),

        // MARK: - Infectious Disease

        DiagnosisDefinition(
            id: "bacterial-meningitis",
            canonicalName: "Bacterial Meningitis",
            alternativeNames: ["Meningitis"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "tuberculosis",
            canonicalName: "Tuberculosis",
            alternativeNames: ["TB"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "lyme-disease",
            canonicalName: "Lyme Disease",
            alternativeNames: ["Lyme Borreliosis"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "rocky-mountain-spotted-fever",
            canonicalName: "Rocky Mountain Spotted Fever",
            alternativeNames: ["RMSF"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "hiv-aids",
            canonicalName: "HIV/AIDS",
            alternativeNames: ["HIV", "AIDS"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "infectious-mononucleosis",
            canonicalName: "Infectious Mononucleosis",
            alternativeNames: ["Mono", "EBV Infection"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "toxic-shock-syndrome",
            canonicalName: "Toxic Shock Syndrome",
            alternativeNames: ["TSS"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "candidiasis",
            canonicalName: "Candidiasis",
            alternativeNames: ["Candida Infection", "Thrush"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "pneumocystis-pneumonia",
            canonicalName: "Pneumocystis Pneumonia",
            alternativeNames: ["PCP", "Pneumocystis Jirovecii Pneumonia", "PJP"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "malaria",
            canonicalName: "Malaria",
            alternativeNames: [],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "toxoplasmosis",
            canonicalName: "Toxoplasmosis",
            alternativeNames: ["Toxoplasma Infection"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "cryptococcal-meningitis",
            canonicalName: "Cryptococcal Meningitis",
            alternativeNames: ["Cryptococcosis"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "histoplasmosis",
            canonicalName: "Histoplasmosis",
            alternativeNames: [],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "coccidioidomycosis",
            canonicalName: "Coccidioidomycosis",
            alternativeNames: ["Valley Fever"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "blastomycosis",
            canonicalName: "Blastomycosis",
            alternativeNames: [],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "actinomycosis",
            canonicalName: "Actinomycosis",
            alternativeNames: [],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "nocardiosis",
            canonicalName: "Nocardiosis",
            alternativeNames: [],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "cat-scratch-disease",
            canonicalName: "Cat Scratch Disease",
            alternativeNames: ["Bartonella Infection"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "erythema-migrans",
            canonicalName: "Erythema Migrans",
            alternativeNames: [],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "scarlet-fever",
            canonicalName: "Scarlet Fever",
            alternativeNames: ["Scarlatina"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "roseola-infantum",
            canonicalName: "Roseola Infantum",
            alternativeNames: ["Sixth Disease", "Exanthem Subitum"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "hand-foot-mouth-disease",
            canonicalName: "Hand-Foot-Mouth Disease",
            alternativeNames: ["HFMD"],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "botulism",
            canonicalName: "Botulism",
            alternativeNames: [],
            category: "Infectious Disease"
        ),
        DiagnosisDefinition(
            id: "tetanus",
            canonicalName: "Tetanus",
            alternativeNames: ["Lockjaw"],
            category: "Infectious Disease"
        ),

        // MARK: - Psychiatry

        DiagnosisDefinition(
            id: "major-depressive-disorder",
            canonicalName: "Major Depressive Disorder",
            alternativeNames: ["MDD", "Depression", "Major Depression"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "generalized-anxiety-disorder",
            canonicalName: "Generalized Anxiety Disorder",
            alternativeNames: ["GAD", "Anxiety"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "schizophrenia",
            canonicalName: "Schizophrenia",
            alternativeNames: [],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "bipolar-disorder",
            canonicalName: "Bipolar Disorder",
            alternativeNames: ["Bipolar", "Manic Depression"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "panic-disorder",
            canonicalName: "Panic Disorder",
            alternativeNames: ["Panic Attacks"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "anorexia-nervosa",
            canonicalName: "Anorexia Nervosa",
            alternativeNames: ["Anorexia"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "ocd",
            canonicalName: "Obsessive-Compulsive Disorder",
            alternativeNames: ["OCD"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "ptsd",
            canonicalName: "Post-Traumatic Stress Disorder",
            alternativeNames: ["PTSD"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "alcohol-withdrawal",
            canonicalName: "Alcohol Withdrawal",
            alternativeNames: ["Delirium Tremens", "DTs"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "bulimia-nervosa",
            canonicalName: "Bulimia Nervosa",
            alternativeNames: ["Bulimia"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "adhd",
            canonicalName: "Attention-Deficit Hyperactivity Disorder",
            alternativeNames: ["ADHD", "ADD"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "autism-spectrum-disorder",
            canonicalName: "Autism Spectrum Disorder",
            alternativeNames: ["ASD", "Autism"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "neuroleptic-malignant-syndrome",
            canonicalName: "Neuroleptic Malignant Syndrome",
            alternativeNames: ["NMS"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "serotonin-syndrome",
            canonicalName: "Serotonin Syndrome",
            alternativeNames: [],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "somatization-disorder",
            canonicalName: "Somatization Disorder",
            alternativeNames: ["Somatic Symptom Disorder"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "conversion-disorder",
            canonicalName: "Conversion Disorder",
            alternativeNames: ["Functional Neurological Disorder"],
            category: "Psychiatry"
        ),
        DiagnosisDefinition(
            id: "tourette-syndrome",
            canonicalName: "Tourette Syndrome",
            alternativeNames: ["Tourette's Syndrome"],
            category: "Psychiatry"
        ),

        // MARK: - Dermatology

        DiagnosisDefinition(
            id: "psoriasis",
            canonicalName: "Psoriasis",
            alternativeNames: [],
            category: "Dermatology"
        ),
        DiagnosisDefinition(
            id: "melanoma",
            canonicalName: "Melanoma",
            alternativeNames: ["Malignant Melanoma"],
            category: "Dermatology"
        ),
        DiagnosisDefinition(
            id: "basal-cell-carcinoma",
            canonicalName: "Basal Cell Carcinoma",
            alternativeNames: ["BCC"],
            category: "Dermatology"
        ),
        DiagnosisDefinition(
            id: "eczema",
            canonicalName: "Eczema",
            alternativeNames: ["Atopic Dermatitis"],
            category: "Dermatology"
        ),
        DiagnosisDefinition(
            id: "stevens-johnson-syndrome",
            canonicalName: "Stevens-Johnson Syndrome",
            alternativeNames: ["SJS", "TEN", "Toxic Epidermal Necrolysis"],
            category: "Dermatology"
        ),
        DiagnosisDefinition(
            id: "squamous-cell-carcinoma",
            canonicalName: "Squamous Cell Carcinoma",
            alternativeNames: ["SCC"],
            category: "Dermatology"
        ),
        DiagnosisDefinition(
            id: "pemphigus-vulgaris",
            canonicalName: "Pemphigus Vulgaris",
            alternativeNames: [],
            category: "Dermatology"
        ),
        DiagnosisDefinition(
            id: "bullous-pemphigoid",
            canonicalName: "Bullous Pemphigoid",
            alternativeNames: [],
            category: "Dermatology"
        ),
        DiagnosisDefinition(
            id: "erythema-multiforme",
            canonicalName: "Erythema Multiforme",
            alternativeNames: ["EM"],
            category: "Dermatology"
        ),
        DiagnosisDefinition(
            id: "acanthosis-nigricans",
            canonicalName: "Acanthosis Nigricans",
            alternativeNames: [],
            category: "Dermatology"
        ),
        DiagnosisDefinition(
            id: "pityriasis-rosea",
            canonicalName: "Pityriasis Rosea",
            alternativeNames: [],
            category: "Dermatology"
        ),
        DiagnosisDefinition(
            id: "seborrheic-keratosis",
            canonicalName: "Seborrheic Keratosis",
            alternativeNames: [],
            category: "Dermatology"
        ),
        DiagnosisDefinition(
            id: "actinic-keratosis",
            canonicalName: "Actinic Keratosis",
            alternativeNames: ["Solar Keratosis"],
            category: "Dermatology"
        ),
        DiagnosisDefinition(
            id: "dermatitis-herpetiformis",
            canonicalName: "Dermatitis Herpetiformis",
            alternativeNames: ["DH"],
            category: "Dermatology"
        ),

        // MARK: - Pediatrics

        DiagnosisDefinition(
            id: "kawasaki-disease",
            canonicalName: "Kawasaki Disease",
            alternativeNames: ["Mucocutaneous Lymph Node Syndrome"],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "croup",
            canonicalName: "Croup",
            alternativeNames: ["Laryngotracheobronchitis"],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "epiglottitis",
            canonicalName: "Epiglottitis",
            alternativeNames: [],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "intussusception",
            canonicalName: "Intussusception",
            alternativeNames: [],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "pyloric-stenosis",
            canonicalName: "Pyloric Stenosis",
            alternativeNames: ["Hypertrophic Pyloric Stenosis", "Hypertrophic Pyloric Stenosis - Late Presentation"],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "respiratory-distress-syndrome",
            canonicalName: "Respiratory Distress Syndrome",
            alternativeNames: ["RDS", "Hyaline Membrane Disease"],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "neonatal-jaundice",
            canonicalName: "Neonatal Jaundice",
            alternativeNames: ["Physiologic Jaundice", "Hyperbilirubinemia"],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "hirschsprung-disease",
            canonicalName: "Hirschsprung Disease",
            alternativeNames: ["Congenital Megacolon"],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "necrotizing-enterocolitis",
            canonicalName: "Necrotizing Enterocolitis",
            alternativeNames: ["NEC"],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "retinopathy-of-prematurity",
            canonicalName: "Retinopathy of Prematurity",
            alternativeNames: ["ROP"],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "digeorge-syndrome",
            canonicalName: "DiGeorge Syndrome",
            alternativeNames: ["22q11.2 Deletion Syndrome", "Velocardiofacial Syndrome"],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "wiskott-aldrich-syndrome",
            canonicalName: "Wiskott-Aldrich Syndrome",
            alternativeNames: ["WAS"],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "bronchiolitis",
            canonicalName: "Bronchiolitis",
            alternativeNames: ["RSV Bronchiolitis"],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "kernicterus",
            canonicalName: "Kernicterus",
            alternativeNames: ["Bilirubin Encephalopathy"],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "erb-palsy",
            canonicalName: "Erb Palsy",
            alternativeNames: ["Erb's Palsy", "Erb-Duchenne Palsy"],
            category: "Pediatrics"
        ),
        DiagnosisDefinition(
            id: "tracheoesophageal-fistula",
            canonicalName: "Tracheoesophageal Fistula",
            alternativeNames: ["TEF", "Esophageal Atresia"],
            category: "Pediatrics"
        ),

        // MARK: - Obstetrics/Gynecology

        DiagnosisDefinition(
            id: "ectopic-pregnancy",
            canonicalName: "Ectopic Pregnancy",
            alternativeNames: ["Tubal Pregnancy"],
            category: "Obstetrics/Gynecology"
        ),
        DiagnosisDefinition(
            id: "pcos",
            canonicalName: "Polycystic Ovary Syndrome",
            alternativeNames: ["PCOS"],
            category: "Obstetrics/Gynecology"
        ),
        DiagnosisDefinition(
            id: "preeclampsia",
            canonicalName: "Preeclampsia",
            alternativeNames: ["Pre-eclampsia", "Toxemia of Pregnancy"],
            category: "Obstetrics/Gynecology"
        ),
        DiagnosisDefinition(
            id: "endometriosis",
            canonicalName: "Endometriosis",
            alternativeNames: [],
            category: "Obstetrics/Gynecology"
        ),
        DiagnosisDefinition(
            id: "placenta-previa",
            canonicalName: "Placenta Previa",
            alternativeNames: [],
            category: "Obstetrics/Gynecology"
        ),
        DiagnosisDefinition(
            id: "hellp-syndrome",
            canonicalName: "HELLP Syndrome",
            alternativeNames: [],
            category: "Obstetrics/Gynecology"
        ),
        DiagnosisDefinition(
            id: "placental-abruption",
            canonicalName: "Placental Abruption",
            alternativeNames: ["Abruptio Placentae"],
            category: "Obstetrics/Gynecology"
        ),
        DiagnosisDefinition(
            id: "gestational-trophoblastic-disease",
            canonicalName: "Gestational Trophoblastic Disease",
            alternativeNames: ["Molar Pregnancy", "Hydatidiform Mole"],
            category: "Obstetrics/Gynecology"
        ),
        DiagnosisDefinition(
            id: "chorioamnionitis",
            canonicalName: "Chorioamnionitis",
            alternativeNames: ["Intra-amniotic Infection"],
            category: "Obstetrics/Gynecology"
        ),

        // MARK: - Urology

        DiagnosisDefinition(
            id: "testicular-torsion",
            canonicalName: "Testicular Torsion",
            alternativeNames: [],
            category: "Urology"
        ),
        DiagnosisDefinition(
            id: "bph",
            canonicalName: "Benign Prostatic Hyperplasia",
            alternativeNames: ["BPH", "Enlarged Prostate"],
            category: "Urology"
        ),
        DiagnosisDefinition(
            id: "prostate-cancer",
            canonicalName: "Prostate Cancer",
            alternativeNames: [],
            category: "Urology"
        ),
        DiagnosisDefinition(
            id: "testicular-seminoma",
            canonicalName: "Testicular Seminoma",
            alternativeNames: ["Seminoma"],
            category: "Urology"
        ),
        DiagnosisDefinition(
            id: "testicular-nsgct",
            canonicalName: "Testicular Non-Seminomatous Germ Cell Tumor",
            alternativeNames: ["NSGCT"],
            category: "Urology"
        ),
        DiagnosisDefinition(
            id: "epididymitis",
            canonicalName: "Epididymitis",
            alternativeNames: [],
            category: "Urology"
        ),
        DiagnosisDefinition(
            id: "varicocele",
            canonicalName: "Varicocele",
            alternativeNames: [],
            category: "Urology"
        ),
        DiagnosisDefinition(
            id: "hydrocele",
            canonicalName: "Hydrocele",
            alternativeNames: [],
            category: "Urology"
        ),

        // MARK: - Orthopedics

        DiagnosisDefinition(
            id: "osteomyelitis",
            canonicalName: "Osteomyelitis",
            alternativeNames: [],
            category: "Orthopedics"
        ),
        DiagnosisDefinition(
            id: "osgood-schlatter",
            canonicalName: "Osgood-Schlatter Disease",
            alternativeNames: ["Osgood Schlatter"],
            category: "Orthopedics"
        ),
        DiagnosisDefinition(
            id: "scfe",
            canonicalName: "Slipped Capital Femoral Epiphysis",
            alternativeNames: ["SCFE"],
            category: "Orthopedics"
        ),
        DiagnosisDefinition(
            id: "legg-calve-perthes",
            canonicalName: "Legg-Calve-Perthes Disease",
            alternativeNames: ["Legg Calve Perthes", "Perthes Disease"],
            category: "Orthopedics"
        ),
        DiagnosisDefinition(
            id: "developmental-dysplasia-hip",
            canonicalName: "Developmental Dysplasia of the Hip",
            alternativeNames: ["DDH", "Hip Dysplasia"],
            category: "Orthopedics"
        ),
        DiagnosisDefinition(
            id: "compartment-syndrome",
            canonicalName: "Compartment Syndrome",
            alternativeNames: [],
            category: "Orthopedics"
        ),
        DiagnosisDefinition(
            id: "osteosarcoma",
            canonicalName: "Osteosarcoma",
            alternativeNames: [],
            category: "Orthopedics"
        ),
        DiagnosisDefinition(
            id: "ewing-sarcoma",
            canonicalName: "Ewing Sarcoma",
            alternativeNames: ["Ewing's Sarcoma"],
            category: "Orthopedics"
        ),
        DiagnosisDefinition(
            id: "paget-disease-bone",
            canonicalName: "Paget Disease of Bone",
            alternativeNames: ["Paget's Disease"],
            category: "Orthopedics"
        ),

        // MARK: - Ophthalmology

        DiagnosisDefinition(
            id: "glaucoma",
            canonicalName: "Glaucoma",
            alternativeNames: ["Open-Angle Glaucoma", "Acute Angle-Closure Glaucoma"],
            category: "Ophthalmology"
        ),
        DiagnosisDefinition(
            id: "cataract",
            canonicalName: "Cataract",
            alternativeNames: [],
            category: "Ophthalmology"
        ),
        DiagnosisDefinition(
            id: "retinal-detachment",
            canonicalName: "Retinal Detachment",
            alternativeNames: [],
            category: "Ophthalmology"
        ),
        DiagnosisDefinition(
            id: "macular-degeneration",
            canonicalName: "Macular Degeneration",
            alternativeNames: ["AMD", "Age-Related Macular Degeneration"],
            category: "Ophthalmology"
        ),
        DiagnosisDefinition(
            id: "diabetic-retinopathy",
            canonicalName: "Diabetic Retinopathy",
            alternativeNames: [],
            category: "Ophthalmology"
        ),
        DiagnosisDefinition(
            id: "central-retinal-artery-occlusion",
            canonicalName: "Central Retinal Artery Occlusion",
            alternativeNames: ["CRAO"],
            category: "Ophthalmology"
        ),
        DiagnosisDefinition(
            id: "papilledema",
            canonicalName: "Papilledema",
            alternativeNames: [],
            category: "Ophthalmology"
        ),

        // MARK: - ENT

        DiagnosisDefinition(
            id: "meniere-disease",
            canonicalName: "Meniere Disease",
            alternativeNames: ["Ménière Disease", "Meniere's Disease"],
            category: "ENT"
        ),
        DiagnosisDefinition(
            id: "vestibular-schwannoma",
            canonicalName: "Vestibular Schwannoma",
            alternativeNames: ["Acoustic Neuroma"],
            category: "ENT"
        ),
        DiagnosisDefinition(
            id: "acute-otitis-media",
            canonicalName: "Acute Otitis Media",
            alternativeNames: ["AOM", "Ear Infection"],
            category: "ENT"
        ),
        DiagnosisDefinition(
            id: "otitis-externa",
            canonicalName: "Otitis Externa",
            alternativeNames: ["Swimmer's Ear"],
            category: "ENT"
        ),
        DiagnosisDefinition(
            id: "acute-bacterial-sinusitis",
            canonicalName: "Acute Bacterial Sinusitis",
            alternativeNames: ["Sinusitis"],
            category: "ENT"
        ),
        DiagnosisDefinition(
            id: "allergic-rhinitis",
            canonicalName: "Allergic Rhinitis",
            alternativeNames: ["Hay Fever"],
            category: "ENT"
        ),

        // MARK: - Vascular

        DiagnosisDefinition(
            id: "dvt",
            canonicalName: "Deep Vein Thrombosis",
            alternativeNames: ["DVT"],
            category: "Vascular"
        ),
        DiagnosisDefinition(
            id: "peripheral-arterial-disease",
            canonicalName: "Peripheral Arterial Disease",
            alternativeNames: ["PAD", "Peripheral Vascular Disease"],
            category: "Vascular"
        ),
        DiagnosisDefinition(
            id: "aaa",
            canonicalName: "Abdominal Aortic Aneurysm",
            alternativeNames: ["AAA"],
            category: "Vascular"
        ),
        DiagnosisDefinition(
            id: "varicose-veins",
            canonicalName: "Varicose Veins",
            alternativeNames: [],
            category: "Vascular"
        ),

        // MARK: - Genetics

        DiagnosisDefinition(
            id: "phenylketonuria",
            canonicalName: "Phenylketonuria",
            alternativeNames: ["PKU"],
            category: "Genetics"
        ),
        DiagnosisDefinition(
            id: "maple-syrup-urine-disease",
            canonicalName: "Maple Syrup Urine Disease",
            alternativeNames: ["MSUD"],
            category: "Genetics"
        ),
        DiagnosisDefinition(
            id: "fragile-x-syndrome",
            canonicalName: "Fragile X Syndrome",
            alternativeNames: [],
            category: "Genetics"
        ),
        DiagnosisDefinition(
            id: "prader-willi-syndrome",
            canonicalName: "Prader-Willi Syndrome",
            alternativeNames: ["PWS"],
            category: "Genetics"
        ),
        DiagnosisDefinition(
            id: "angelman-syndrome",
            canonicalName: "Angelman Syndrome",
            alternativeNames: [],
            category: "Genetics"
        ),
        DiagnosisDefinition(
            id: "achondroplasia",
            canonicalName: "Achondroplasia",
            alternativeNames: [],
            category: "Genetics"
        ),
        DiagnosisDefinition(
            id: "marfan-syndrome",
            canonicalName: "Marfan Syndrome",
            alternativeNames: [],
            category: "Genetics"
        ),
        DiagnosisDefinition(
            id: "ehlers-danlos-syndrome",
            canonicalName: "Ehlers-Danlos Syndrome",
            alternativeNames: ["EDS"],
            category: "Genetics"
        ),
        DiagnosisDefinition(
            id: "osteogenesis-imperfecta",
            canonicalName: "Osteogenesis Imperfecta",
            alternativeNames: ["OI", "Brittle Bone Disease"],
            category: "Genetics"
        ),
        DiagnosisDefinition(
            id: "duchenne-muscular-dystrophy",
            canonicalName: "Duchenne Muscular Dystrophy",
            alternativeNames: ["DMD"],
            category: "Genetics"
        ),
        DiagnosisDefinition(
            id: "becker-muscular-dystrophy",
            canonicalName: "Becker Muscular Dystrophy",
            alternativeNames: ["BMD"],
            category: "Genetics"
        ),
        DiagnosisDefinition(
            id: "myotonic-dystrophy",
            canonicalName: "Myotonic Dystrophy",
            alternativeNames: ["DM1", "Steinert Disease"],
            category: "Genetics"
        ),
        DiagnosisDefinition(
            id: "von-hippel-lindau",
            canonicalName: "Von Hippel-Lindau Disease",
            alternativeNames: ["VHL", "Von Hippel Lindau Disease"],
            category: "Genetics"
        ),

        // MARK: - Oncology

        DiagnosisDefinition(
            id: "ovarian-cancer",
            canonicalName: "Ovarian Cancer",
            alternativeNames: [],
            category: "Oncology"
        ),
        DiagnosisDefinition(
            id: "cin",
            canonicalName: "Cervical Intraepithelial Neoplasia",
            alternativeNames: ["CIN"],
            category: "Oncology"
        ),
        DiagnosisDefinition(
            id: "cervical-cancer",
            canonicalName: "Invasive Cervical Cancer",
            alternativeNames: ["Cervical Cancer"],
            category: "Oncology"
        ),
        DiagnosisDefinition(
            id: "breast-cancer",
            canonicalName: "Breast Cancer",
            alternativeNames: [],
            category: "Oncology"
        ),

        // Note: Many more diagnoses exist in the full CaseLibrary
        // This registry includes consolidated versions of all known duplicates
        // and common diagnoses. Additional entries can be added as needed.
    ]

    // MARK: - Lookup Methods

    /// Lookup diagnosis by slug ID
    static func find(bySlug slug: String) -> DiagnosisDefinition? {
        all.first { $0.id == slug }
    }

    /// Lookup diagnosis by any name (case-insensitive)
    static func find(byName name: String) -> DiagnosisDefinition? {
        let normalized = DiagnosisDefinition.normalize(name)
        return all.first { definition in
            definition.allNames.contains { DiagnosisDefinition.normalize($0) == normalized }
        }
    }

    /// All canonical names for autocomplete (deduplicated by design)
    static var autocompleteNames: [String] {
        all.map { $0.canonicalName }.sorted()
    }

    /// Generate a slug from a diagnosis string (for migration/debugging)
    static func generateSlug(from diagnosis: String) -> String {
        diagnosis.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
