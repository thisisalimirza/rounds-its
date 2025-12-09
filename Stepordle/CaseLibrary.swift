//
//  CaseLibrary.swift
//  Stepordle
//
//  Created by Ali Mirza on 12/9/25.
//

import Foundation
import SwiftData

class CaseLibrary {
    static func getSampleCases() -> [MedicalCase] {
        return [
            // Cardiology
            MedicalCase(
                diagnosis: "Myocardial Infarction",
                alternativeNames: ["MI", "Heart Attack", "Acute MI", "STEMI"],
                hints: [
                    "45-year-old male with sudden onset chest pain",
                    "Pain radiates to left arm and jaw, associated with diaphoresis",
                    "ECG shows ST-segment elevation in leads II, III, aVF",
                    "Troponin levels are significantly elevated",
                    "Patient has history of hypertension, diabetes, and smoking"
                ],
                category: "Cardiology",
                difficulty: 2
            ),
            
            // Neurology
            MedicalCase(
                diagnosis: "Multiple Sclerosis",
                alternativeNames: ["MS"],
                hints: [
                    "28-year-old female with episodes of vision loss",
                    "Patient reports numbness and tingling in lower extremities",
                    "Symptoms worsen with heat exposure (Uhthoff's phenomenon)",
                    "MRI shows periventricular white matter lesions",
                    "CSF analysis reveals oligoclonal bands"
                ],
                category: "Neurology",
                difficulty: 3
            ),
            
            // Endocrinology
            MedicalCase(
                diagnosis: "Diabetic Ketoacidosis",
                alternativeNames: ["DKA"],
                hints: [
                    "22-year-old with altered mental status and rapid breathing",
                    "Patient reports increased thirst and urination over past week",
                    "Breath has fruity odor, appears dehydrated",
                    "Labs: glucose 450 mg/dL, pH 7.1, positive serum ketones",
                    "Patient has type 1 diabetes and ran out of insulin"
                ],
                category: "Endocrinology",
                difficulty: 2
            ),
            
            // Pulmonology
            MedicalCase(
                diagnosis: "Pneumothorax",
                alternativeNames: ["Collapsed Lung"],
                hints: [
                    "Tall, thin 20-year-old male with sudden chest pain",
                    "Patient reports acute onset shortness of breath",
                    "Decreased breath sounds on right side",
                    "Hyperresonance to percussion on affected side",
                    "Chest X-ray shows absent lung markings and visible visceral pleural line"
                ],
                category: "Pulmonology",
                difficulty: 2
            ),
            
            // Gastroenterology
            MedicalCase(
                diagnosis: "Acute Pancreatitis",
                alternativeNames: ["Pancreatitis"],
                hints: [
                    "42-year-old with severe epigastric pain radiating to back",
                    "Patient has history of chronic alcohol use",
                    "Pain is constant and worsened by eating",
                    "Lipase elevated to 800 U/L (normal <160)",
                    "CT scan shows pancreatic edema and peripancreatic fluid"
                ],
                category: "Gastroenterology",
                difficulty: 2
            ),
            
            // Hematology
            MedicalCase(
                diagnosis: "Sickle Cell Crisis",
                alternativeNames: ["Sickle Cell Anemia", "Vaso-occlusive Crisis"],
                hints: [
                    "18-year-old African American with severe bone pain",
                    "Patient has history of sickle cell disease",
                    "Pain in chest, back, and extremities",
                    "Recent upper respiratory infection",
                    "Labs show hemoglobin 7 g/dL, elevated reticulocyte count"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            // Infectious Disease
            MedicalCase(
                diagnosis: "Bacterial Meningitis",
                alternativeNames: ["Meningitis"],
                hints: [
                    "19-year-old college student with severe headache and fever",
                    "Patient has neck stiffness and photophobia",
                    "Altered mental status, Kernig's and Brudzinski's signs positive",
                    "Lumbar puncture shows cloudy CSF with elevated WBC",
                    "CSF gram stain shows gram-negative diplococci"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            // Nephrology
            MedicalCase(
                diagnosis: "Acute Kidney Injury",
                alternativeNames: ["AKI", "Acute Renal Failure", "ARF"],
                hints: [
                    "65-year-old with decreased urine output",
                    "Recent cardiac surgery 3 days ago",
                    "Patient appears volume overloaded with peripheral edema",
                    "Creatinine increased from 1.0 to 3.5 mg/dL",
                    "BUN elevated, urine sodium low, FENa <1%"
                ],
                category: "Nephrology",
                difficulty: 3
            ),
            
            // Rheumatology
            MedicalCase(
                diagnosis: "Systemic Lupus Erythematosus",
                alternativeNames: ["SLE", "Lupus"],
                hints: [
                    "25-year-old female with fatigue and joint pain",
                    "Malar rash across cheeks and nose bridge",
                    "Photosensitivity and oral ulcers",
                    "Labs show positive ANA, anti-dsDNA, low complement",
                    "Proteinuria and hematuria on urinalysis"
                ],
                category: "Rheumatology",
                difficulty: 3
            ),
            
            // Psychiatry
            MedicalCase(
                diagnosis: "Major Depressive Disorder",
                alternativeNames: ["Depression", "MDD", "Clinical Depression"],
                hints: [
                    "35-year-old with persistent low mood for 2 months",
                    "Loss of interest in previously enjoyed activities",
                    "Difficulty sleeping, decreased appetite, weight loss",
                    "Poor concentration affecting work performance",
                    "Denies suicidal ideation but feels hopeless about future"
                ],
                category: "Psychiatry",
                difficulty: 2
            ),
            MedicalCase(
                diagnosis: "Aortic Dissection",
                alternativeNames: ["Dissecting Aneurysm"],
                hints: [
                    "60-year-old male with sudden tearing chest pain radiating to the back",
                    "History of long-standing uncontrolled hypertension",
                    "Unequal blood pressures in both arms",
                    "Widened mediastinum on chest X-ray",
                    "CT angiography shows intimal flap in the ascending aorta"
                ],
                category: "Cardiology",
                difficulty: 4
            ),
            MedicalCase(
                diagnosis: "Acute Pericarditis",
                alternativeNames: ["Pericarditis"],
                hints: [
                    "28-year-old with sharp pleuritic chest pain worse when supine",
                    "Pain improves when leaning forward",
                    "Pericardial friction rub on auscultation",
                    "Diffuse ST-segment elevation and PR depression on ECG",
                    "Recent viral upper respiratory infection"
                ],
                category: "Cardiology",
                difficulty: 2
            ),
            MedicalCase(
                diagnosis: "Infective Endocarditis",
                alternativeNames: ["IE", "Bacterial Endocarditis"],
                hints: [
                    "45-year-old with fever and new-onset heart murmur",
                    "History of IV drug use",
                    "Splinter hemorrhages and Janeway lesions present",
                    "Positive blood cultures for Staphylococcus aureus",
                    "Vegetations on tricuspid valve seen on echocardiogram"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Wolff-Parkinson-White Syndrome",
                alternativeNames: ["WPW"],
                hints: [
                    "Teenager with episodes of palpitations and dizziness",
                    "ECG shows short PR interval and delta wave",
                    "Orthodromic AVRT suspected",
                    "Episodes triggered by exertion or caffeine",
                    "Accessory pathway via bundle of Kent"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Subarachnoid Hemorrhage",
                alternativeNames: ["SAH"],
                hints: [
                    "35-year-old presents with sudden 'worst headache of my life'",
                    "Nuchal rigidity and photophobia",
                    "CT head without contrast shows hyperdensity in basal cisterns",
                    "If CT negative, LP shows xanthochromia",
                    "Ruptured saccular (berry) aneurysm suspected"
                ],
                category: "Neurology",
                difficulty: 4
            ),
            MedicalCase(
                diagnosis: "Myasthenia Gravis",
                alternativeNames: ["MG"],
                hints: [
                    "22-year-old woman with fluctuating ptosis and diplopia",
                    "Weakness worsens with use and improves with rest",
                    "Ice pack test transiently improves ptosis",
                    "ACh receptor antibodies positive",
                    "Associated with thymic hyperplasia or thymoma"
                ],
                category: "Neurology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Guillain-Barré Syndrome",
                alternativeNames: ["GBS", "Acute Inflammatory Demyelinating Polyradiculoneuropathy"],
                hints: [
                    "Young adult with ascending symmetric paralysis",
                    "Recent Campylobacter jejuni gastroenteritis",
                    "Areflexia on exam",
                    "CSF shows albuminocytologic dissociation",
                    "Risk of respiratory failure requiring monitoring"
                ],
                category: "Neurology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Pulmonary Embolism",
                alternativeNames: ["PE"],
                hints: [
                    "Postoperative patient with acute dyspnea and pleuritic chest pain",
                    "Tachycardia and mild hypoxemia",
                    "Elevated D-dimer",
                    "CT pulmonary angiography shows filling defect",
                    "Risk factors include immobility and DVT"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Sarcoidosis",
                alternativeNames: [],
                hints: [
                    "African American woman with dry cough and dyspnea",
                    "Bilateral hilar lymphadenopathy on chest X-ray",
                    "Noncaseating granulomas on biopsy",
                    "Elevated ACE levels and hypercalcemia",
                    "Erythema nodosum on shins"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Asthma Exacerbation",
                alternativeNames: ["Status Asthmaticus"],
                hints: [
                    "Teen with wheezing and shortness of breath after allergen exposure",
                    "Prolonged expiratory phase",
                    "Decreased peak expiratory flow rate",
                    "Use of accessory muscles of respiration",
                    "Improves with inhaled beta-2 agonist"
                ],
                category: "Pulmonology",
                difficulty: 2
            ),
            MedicalCase(
                diagnosis: "Crohn's Disease",
                alternativeNames: ["Crohn Disease", "Regional Enteritis"],
                hints: [
                    "Young adult with chronic diarrhea and weight loss",
                    "Abdominal pain, worse in right lower quadrant",
                    "Skip lesions on endoscopy",
                    "Transmural inflammation with fistulas",
                    "Noncaseating granulomas on biopsy"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Ulcerative Colitis",
                alternativeNames: ["UC"],
                hints: [
                    "Young adult with bloody diarrhea and abdominal pain",
                    "Involves rectum and extends proximally in a continuous pattern",
                    "Mucosal and submucosal inflammation",
                    "Pseudopolyps on colonoscopy",
                    "Risk of primary sclerosing cholangitis"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Acute Appendicitis",
                alternativeNames: ["Appendicitis"],
                hints: [
                    "Teenager with periumbilical pain migrating to right lower quadrant",
                    "Anorexia, nausea, and low-grade fever",
                    "McBurney point tenderness",
                    "Leukocytosis with left shift",
                    "Ultrasound shows noncompressible tubular structure"
                ],
                category: "Gastroenterology",
                difficulty: 2
            ),
            MedicalCase(
                diagnosis: "Graves Disease",
                alternativeNames: ["Hyperthyroidism"],
                hints: [
                    "30-year-old woman with weight loss and palpitations",
                    "Heat intolerance and tremor",
                    "Diffuse goiter and ophthalmopathy",
                    "Low TSH, elevated T3/T4",
                    "TSI antibodies stimulate TSH receptor"
                ],
                category: "Endocrinology",
                difficulty: 2
            ),
            MedicalCase(
                diagnosis: "Hashimoto Thyroiditis",
                alternativeNames: ["Chronic Lymphocytic Thyroiditis", "Hypothyroidism"],
                hints: [
                    "Middle-aged woman with fatigue and weight gain",
                    "Cold intolerance, constipation, dry skin",
                    "Painless enlarged thyroid",
                    "Anti-TPO and anti-thyroglobulin antibodies",
                    "Hurthle cells on histology"
                ],
                category: "Endocrinology",
                difficulty: 2
            ),
            MedicalCase(
                diagnosis: "Cushing Syndrome",
                alternativeNames: [],
                hints: [
                    "Patient with central obesity and purple striae",
                    "Proximal muscle weakness and hypertension",
                    "Glucose intolerance",
                    "Elevated cortisol levels not suppressed by low-dose dexamethasone",
                    "ACTH-dependent vs independent workup needed"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Addison Disease",
                alternativeNames: ["Primary Adrenal Insufficiency"],
                hints: [
                    "Patient with fatigue, weight loss, and hyperpigmentation",
                    "Hypotension and hyponatremia",
                    "Hyperkalemia",
                    "Low cortisol with high ACTH",
                    "Autoimmune destruction of adrenal cortex"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Minimal Change Disease",
                alternativeNames: ["Lipoid Nephrosis"],
                hints: [
                    "Child with periorbital edema and frothy urine",
                    "Selective albuminuria (nephrotic syndrome)",
                    "Normal light microscopy",
                    "Effacement of podocyte foot processes on EM",
                    "Responds to corticosteroids"
                ],
                category: "Nephrology",
                difficulty: 2
            ),
            MedicalCase(
                diagnosis: "Poststreptococcal Glomerulonephritis",
                alternativeNames: ["PSGN"],
                hints: [
                    "Child with cola-colored urine and periorbital edema",
                    "History of recent skin or throat infection",
                    "Hypertension and mild proteinuria",
                    "Elevated ASO titers and low C3",
                    "Subepithelial humps on EM"
                ],
                category: "Nephrology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Iron Deficiency Anemia",
                alternativeNames: [],
                hints: [
                    "Woman with fatigue and pica",
                    "Microcytic, hypochromic anemia",
                    "Low ferritin and high TIBC",
                    "Spoon nails (koilonychia)",
                    "Often due to chronic blood loss"
                ],
                category: "Hematology",
                difficulty: 2
            ),
            MedicalCase(
                diagnosis: "Acute Promyelocytic Leukemia",
                alternativeNames: ["APL", "M3 AML"],
                hints: [
                    "Patient with fatigue, bleeding, and infections",
                    "Auer rods seen on smear",
                    "t(15;17) PML-RARA translocation",
                    "DIC common at presentation",
                    "Treat with ATRA (all-trans retinoic acid)"
                ],
                category: "Hematology",
                difficulty: 4
            ),
            MedicalCase(
                diagnosis: "Immune Thrombocytopenic Purpura",
                alternativeNames: ["ITP"],
                hints: [
                    "Young woman with easy bruising and petechiae",
                    "Isolated thrombocytopenia",
                    "Normal PT and aPTT",
                    "Autoantibodies against platelet GPIIb/IIIa",
                    "Increased megakaryocytes in bone marrow"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Tuberculosis",
                alternativeNames: ["TB"],
                hints: [
                    "Immigrant with chronic cough, night sweats, and weight loss",
                    "Hemoptysis present",
                    "Upper lobe cavitary lesion on chest imaging",
                    "AFB-positive sputum",
                    "Caseating granulomas with Langhans giant cells"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Lyme Disease",
                alternativeNames: [],
                hints: [
                    "Hiker from Northeast with expanding erythema migrans rash",
                    "Flu-like symptoms and arthralgias",
                    "History of tick bite",
                    "Facial nerve palsy (Bell palsy)",
                    "Borrelia burgdorferi via Ixodes tick"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            MedicalCase(
                diagnosis: "Rocky Mountain Spotted Fever",
                alternativeNames: ["RMSF"],
                hints: [
                    "Camper with fever, headache, and rash starting at wrists/ankles",
                    "History of tick exposure in Southeast US",
                    "Thrombocytopenia and hyponatremia",
                    "Rickettsia rickettsii",
                    "Treat empirically with doxycycline"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Gout",
                alternativeNames: ["Gouty Arthritis"],
                hints: [
                    "Middle-aged man with acute monoarthritis of first MTP joint",
                    "Severe pain, redness, and swelling",
                    "Negatively birefringent, needle-shaped crystals",
                    "Hyperuricemia",
                    "Triggers include alcohol and purine-rich foods"
                ],
                category: "Rheumatology",
                difficulty: 2
            ),
            MedicalCase(
                diagnosis: "Temporal Arteritis",
                alternativeNames: ["Giant Cell Arteritis", "GCA"],
                hints: [
                    "Elderly woman with new-onset headache and jaw claudication",
                    "Scalp tenderness over temporal artery",
                    "Elevated ESR",
                    "Risk of irreversible vision loss",
                    "Granulomatous inflammation of branches of carotid artery"
                ],
                category: "Rheumatology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Ankylosing Spondylitis",
                alternativeNames: ["AS"],
                hints: [
                    "Young man with chronic back pain improving with exercise",
                    "Limited spine mobility and morning stiffness",
                    "HLA-B27 positive",
                    "Bamboo spine on imaging",
                    "Associated with uveitis"
                ],
                category: "Rheumatology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Generalized Anxiety Disorder",
                alternativeNames: ["GAD"],
                hints: [
                    "Adult with excessive worry for >6 months",
                    "Restlessness, fatigue, difficulty concentrating",
                    "Muscle tension and sleep disturbance",
                    "Symptoms cause impairment",
                    "No specific triggers identified"
                ],
                category: "Psychiatry",
                difficulty: 1
            ),
            MedicalCase(
                diagnosis: "Schizophrenia",
                alternativeNames: [],
                hints: [
                    "Young adult with hallucinations and delusions",
                    "Disorganized speech and behavior",
                    "Negative symptoms: flat affect, avolition",
                    "Symptoms >6 months with functional decline",
                    "Increased dopaminergic activity in mesolimbic pathway"
                ],
                category: "Psychiatry",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Ectopic Pregnancy",
                alternativeNames: [],
                hints: [
                    "Woman with amenorrhea, abdominal pain, and vaginal bleeding",
                    "Positive pregnancy test",
                    "Adnexal tenderness on exam",
                    "Transvaginal ultrasound shows empty uterus",
                    "Most commonly implanted in ampulla of fallopian tube"
                ],
                category: "Obstetrics & Gynecology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Polycystic Ovary Syndrome",
                alternativeNames: ["PCOS"],
                hints: [
                    "Young woman with irregular menses and infertility",
                    "Obesity and hirsutism",
                    "Elevated LH:FSH ratio",
                    "Insulin resistance",
                    "Enlarged, cystic ovaries on ultrasound"
                ],
                category: "Obstetrics & Gynecology",
                difficulty: 2
            ),
            MedicalCase(
                diagnosis: "Testicular Torsion",
                alternativeNames: [],
                hints: [
                    "Teenage boy with sudden severe unilateral scrotal pain",
                    "High-riding testis with horizontal lie",
                    "Absent cremasteric reflex",
                    "Nausea and vomiting",
                    "Doppler ultrasound shows decreased blood flow"
                ],
                category: "Urology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Osteomyelitis",
                alternativeNames: [],
                hints: [
                    "Child with fever and localized bone pain",
                    "Elevated ESR and CRP",
                    "Commonly due to Staphylococcus aureus",
                    "MRI is most sensitive early imaging",
                    "Metaphysis of long bones commonly affected"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            MedicalCase(
                diagnosis: "Psoriasis",
                alternativeNames: [],
                hints: [
                    "Adult with well-demarcated erythematous plaques with silvery scale",
                    "Extensor surfaces and scalp involved",
                    "Auspitz sign (pinpoint bleeding when scale removed)",
                    "Nail pitting",
                    "Associated with arthritis"
                ],
                category: "Dermatology",
                difficulty: 2
            ),
            MedicalCase(
                diagnosis: "Phenylketonuria",
                alternativeNames: ["PKU"],
                hints: [
                    "Infant with intellectual disability and seizures if untreated",
                    "Musty body odor",
                    "Fair skin, eczema",
                    "Deficiency of phenylalanine hydroxylase",
                    "Dietary restriction of phenylalanine required"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Maple Syrup Urine Disease",
                alternativeNames: ["MSUD"],
                hints: [
                    "Infant with poor feeding, vomiting, and lethargy",
                    "Sweet-smelling urine",
                    "Branched-chain alpha-ketoacid dehydrogenase deficiency",
                    "Elevated leucine, isoleucine, valine",
                    "Treat with dietary restriction and thiamine"
                ],
                category: "Endocrinology",
                difficulty: 4
            ),
            MedicalCase(
                diagnosis: "Kawasaki Disease",
                alternativeNames: [],
                hints: [
                    "Child with persistent fever >5 days",
                    "Conjunctivitis, rash, adenopathy, strawberry tongue",
                    "Erythema and edema of hands/feet",
                    "Risk of coronary artery aneurysms",
                    "Treat with IVIG and aspirin"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Septic Arthritis",
                alternativeNames: [],
                hints: [
                    "Acute monoarticular joint pain, swelling, and fever",
                    "Warm, erythematous joint with limited ROM",
                    "Elevated WBC in synovial fluid (>50,000)",
                    "Most commonly Staphylococcus aureus",
                    "Requires urgent drainage and antibiotics"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Tetanus",
                alternativeNames: [],
                hints: [
                    "Patient with muscle spasms following puncture wound",
                    "Trismus (lockjaw) and risus sardonicus",
                    "Spastic paralysis due to toxin blocking glycine and GABA release",
                    "History of incomplete vaccination",
                    "Treat with immunoglobulin and vaccine"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Botulism",
                alternativeNames: [],
                hints: [
                    "Adult with diplopia, dysphagia, and descending paralysis",
                    "History of improperly canned food",
                    "Toxin prevents ACh release at neuromuscular junction",
                    "Floppy baby syndrome in infants from honey",
                    "Treat with antitoxin"
                ],
                category: "Infectious Disease",
                difficulty: 4
            )
        ]
    }
    
    static func getRandomCase(excluding: [UUID] = []) -> MedicalCase? {
        let cases = getSampleCases().filter { !excluding.contains($0.id) }
        return cases.randomElement()
    }
    
    static func getCasesByCategory(_ category: String) -> [MedicalCase] {
        return getSampleCases().filter { $0.category == category }
    }
    
    static func getAllCategories() -> [String] {
        let cases = getSampleCases()
        return Array(Set(cases.map { $0.category })).sorted()
    }
}
