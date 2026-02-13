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
        let cases: [MedicalCase] = [
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
            // CARDIOLOGY (10 cases)
            MedicalCase(
                diagnosis: "Hypertrophic Cardiomyopathy",
                alternativeNames: ["HCM", "HOCM"],
                hints: [
                    "Young athlete with syncope during exercise",
                    "Systolic crescendo-decrescendo murmur at apex",
                    "Murmur decreases with squatting, increases with Valsalva",
                    "Echocardiogram shows asymmetric septal hypertrophy",
                    "Family history of sudden cardiac death"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Atrial Fibrillation",
                alternativeNames: ["AFib", "AF"],
                hints: [
                    "Elderly patient with irregular pulse and palpitations",
                    "ECG shows irregularly irregular rhythm without P waves",
                    "Risk factors include hypertension and hyperthyroidism",
                    "Increased risk of thromboembolism and stroke",
                    "Anticoagulation needed if CHA2DS2-VASc score ≥2"
                ],
                category: "Cardiology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Acute Rheumatic Fever",
                alternativeNames: ["ARF"],
                hints: [
                    "Child with recent Group A Strep pharyngitis",
                    "Migratory polyarthritis affecting large joints",
                    "Erythema marginatum rash and subcutaneous nodules",
                    "Sydenham chorea (involuntary movements)",
                    "Elevated ASO titers, prolonged PR interval on ECG"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Cardiac Tamponade",
                alternativeNames: ["Pericardial Tamponade"],
                hints: [
                    "Patient with hypotension and jugular venous distension",
                    "Beck's triad: muffled heart sounds, hypotension, JVD",
                    "Pulsus paradoxus >10 mmHg",
                    "Electrical alternans on ECG",
                    "Echocardiogram shows pericardial effusion with diastolic collapse"
                ],
                category: "Cardiology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Dilated Cardiomyopathy",
                alternativeNames: ["DCM"],
                hints: [
                    "Middle-aged patient with progressive dyspnea and fatigue",
                    "History of chronic alcohol abuse or viral myocarditis",
                    "S3 gallop and bilateral crackles on exam",
                    "Echocardiogram shows dilated ventricles with reduced EF",
                    "Elevated BNP levels"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Mitral Regurgitation",
                alternativeNames: ["MR", "Mitral Insufficiency"],
                hints: [
                    "Patient with holosystolic murmur at apex",
                    "Murmur radiates to axilla",
                    "Associated with rheumatic heart disease or MVP",
                    "S3 may be present in severe cases",
                    "Echocardiogram shows regurgitant jet"
                ],
                category: "Cardiology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Aortic Stenosis",
                alternativeNames: ["AS"],
                hints: [
                    "Elderly patient with syncope, angina, and dyspnea (SAD triad)",
                    "Crescendo-decrescendo systolic murmur at right sternal border",
                    "Murmur radiates to carotids",
                    "Delayed and diminished carotid upstroke (pulsus parvus et tardus)",
                    "Echocardiogram shows calcified valve with reduced opening"
                ],
                category: "Cardiology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Ventricular Septal Defect",
                alternativeNames: ["VSD"],
                hints: [
                    "Infant with failure to thrive and recurrent infections",
                    "Harsh holosystolic murmur at left lower sternal border",
                    "Thrill palpable at left sternal border",
                    "Increased pulmonary blood flow can lead to Eisenmenger syndrome",
                    "Associated with fetal alcohol syndrome and Down syndrome"
                ],
                category: "Cardiology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Coarctation of the Aorta",
                alternativeNames: ["Aortic Coarctation"],
                hints: [
                    "Child with upper extremity hypertension, lower extremity hypotension",
                    "Weak or delayed femoral pulses",
                    "Rib notching on chest X-ray from collateral circulation",
                    "Continuous murmur heard over the back",
                    "Associated with Turner syndrome and bicuspid aortic valve"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Tetralogy of Fallot",
                alternativeNames: ["TOF", "Tet Spells"],
                hints: [
                    "Cyanotic infant who squats after exertion",
                    "Boot-shaped heart on chest X-ray",
                    "Harsh systolic murmur due to pulmonary stenosis",
                    "Four defects: VSD, pulmonary stenosis, overriding aorta, RVH",
                    "Tet spells relieved by squatting or knee-chest position"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            
            // PULMONOLOGY (10 cases)
            MedicalCase(
                diagnosis: "Chronic Obstructive Pulmonary Disease",
                alternativeNames: ["COPD", "Emphysema", "Chronic Bronchitis"],
                hints: [
                    "Long-term smoker with progressive dyspnea",
                    "Barrel chest and prolonged expiratory phase",
                    "Decreased breath sounds and hyperresonance",
                    "FEV1/FVC ratio <0.7 on spirometry",
                    "Pink puffer (emphysema) or blue bloater (chronic bronchitis)"
                ],
                category: "Pulmonology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Tension Pneumothorax",
                alternativeNames: ["Tension PTX"],
                hints: [
                    "Trauma patient with severe respiratory distress",
                    "Tracheal deviation away from affected side",
                    "Absent breath sounds and hyperresonance on affected side",
                    "Jugular venous distension and hypotension",
                    "Immediate needle decompression required"
                ],
                category: "Pulmonology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Cystic Fibrosis",
                alternativeNames: ["CF"],
                hints: [
                    "Child with recurrent pulmonary infections and failure to thrive",
                    "Meconium ileus in newborn period",
                    "Salty-tasting skin",
                    "Positive sweat chloride test >60 mEq/L",
                    "CFTR gene mutation, autosomal recessive"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Idiopathic Pulmonary Fibrosis",
                alternativeNames: ["IPF", "Usual Interstitial Pneumonia"],
                hints: [
                    "Older adult with progressive dyspnea and dry cough",
                    "Bibasilar inspiratory crackles (Velcro rales)",
                    "Clubbing of fingers",
                    "Honeycomb pattern on CT scan",
                    "Restrictive pattern on pulmonary function tests"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Community-Acquired Pneumonia",
                alternativeNames: ["CAP", "Pneumonia"],
                hints: [
                    "Patient with fever, productive cough, and pleuritic chest pain",
                    "Dullness to percussion and increased tactile fremitus",
                    "Lobar consolidation on chest X-ray",
                    "Most commonly caused by Streptococcus pneumoniae",
                    "Rusty-colored sputum"
                ],
                category: "Pulmonology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Tuberculosis",
                alternativeNames: ["TB", "Pulmonary TB"],
                hints: [
                    "Immigrant with chronic cough, night sweats, and hemoptysis",
                    "Apical cavitary lesions on chest X-ray",
                    "AFB smear positive, positive PPD test",
                    "Granulomas with central caseating necrosis",
                    "Requires multi-drug therapy (RIPE)"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Sleep Apnea",
                alternativeNames: ["Obstructive Sleep Apnea", "OSA"],
                hints: [
                    "Obese patient with daytime somnolence and loud snoring",
                    "Partner reports apneic episodes during sleep",
                    "Morning headaches and poor concentration",
                    "Polysomnography shows apnea-hypopnea index >5",
                    "Risk of pulmonary hypertension and right heart failure"
                ],
                category: "Pulmonology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Lung Adenocarcinoma",
                alternativeNames: ["Lung Cancer", "Bronchogenic Carcinoma"],
                hints: [
                    "Smoker with chronic cough and weight loss",
                    "Peripheral lung mass on chest X-ray",
                    "Most common lung cancer in non-smokers and women",
                    "Glandular differentiation on histology",
                    "May present with hypertrophic osteoarthropathy"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Alpha-1 Antitrypsin Deficiency",
                alternativeNames: ["A1AT Deficiency"],
                hints: [
                    "Young patient with COPD and no smoking history",
                    "Basilar emphysema on imaging",
                    "Liver disease (cirrhosis) may coexist",
                    "Low serum alpha-1 antitrypsin levels",
                    "PiZZ genotype most severe"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Aspiration Pneumonia",
                alternativeNames: ["Chemical Pneumonitis"],
                hints: [
                    "Elderly patient with stroke or dementia",
                    "Witnessed aspiration event or found down",
                    "Right lower lobe infiltrate (most common location)",
                    "Anaerobic bacteria or mixed flora",
                    "Foul-smelling sputum if abscess forms"
                ],
                category: "Pulmonology",
                difficulty: 2
            ),
            
            // GASTROENTEROLOGY (10 cases)
            MedicalCase(
                diagnosis: "Ulcerative Colitis",
                alternativeNames: ["UC"],
                hints: [
                    "Young adult with bloody diarrhea and tenesmus",
                    "Continuous inflammation starting in rectum",
                    "Loss of haustra (lead pipe colon) on barium enema",
                    "Crypt abscesses and pseudopolyps on colonoscopy",
                    "Increased risk of colorectal cancer"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Celiac Disease",
                alternativeNames: ["Celiac Sprue", "Gluten-Sensitive Enteropathy"],
                hints: [
                    "Patient with chronic diarrhea and bloating after eating wheat",
                    "Dermatitis herpetiformis (itchy vesicular rash)",
                    "Positive anti-tissue transglutaminase antibodies",
                    "Villous atrophy on small bowel biopsy",
                    "Associated with HLA-DQ2/DQ8"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Acute Cholecystitis",
                alternativeNames: ["Cholecystitis"],
                hints: [
                    "Middle-aged woman with RUQ pain after fatty meal",
                    "Murphy's sign positive (inspiratory arrest)",
                    "Fever and leukocytosis",
                    "Ultrasound shows thickened gallbladder wall and pericholecystic fluid",
                    "4 F's: Fat, Forty, Female, Fertile"
                ],
                category: "Gastroenterology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Hepatic Encephalopathy",
                alternativeNames: ["Hepatic Coma"],
                hints: [
                    "Cirrhotic patient with altered mental status",
                    "Asterixis (flapping tremor) present",
                    "Elevated ammonia levels",
                    "Precipitated by GI bleed, infection, or protein load",
                    "Treated with lactulose and rifaximin"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Peptic Ulcer Disease",
                alternativeNames: ["PUD", "Gastric Ulcer", "Duodenal Ulcer"],
                hints: [
                    "Patient with epigastric pain relieved by food (duodenal) or worsened by food (gastric)",
                    "Associated with H. pylori infection or NSAID use",
                    "Complications include bleeding, perforation, obstruction",
                    "Urea breath test positive for H. pylori",
                    "Treated with PPI and antibiotics if H. pylori positive"
                ],
                category: "Gastroenterology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Esophageal Varices",
                alternativeNames: ["Variceal Bleeding"],
                hints: [
                    "Cirrhotic patient with massive hematemesis",
                    "History of chronic alcohol use or hepatitis",
                    "Signs of portal hypertension: ascites, splenomegaly",
                    "Emergent upper endoscopy for diagnosis and band ligation",
                    "Treated with octreotide and prophylactic antibiotics"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Diverticulitis",
                alternativeNames: ["Colonic Diverticulitis"],
                hints: [
                    "Elderly patient with LLQ pain and fever",
                    "Change in bowel habits",
                    "CT shows inflamed diverticula with fat stranding",
                    "Low-fiber diet increases risk",
                    "Complications include abscess, perforation, fistula"
                ],
                category: "Gastroenterology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Appendicitis",
                alternativeNames: ["Acute Appendicitis"],
                hints: [
                    "Adolescent with periumbilical pain migrating to RLQ",
                    "McBurney's point tenderness",
                    "Rovsing's sign and psoas sign positive",
                    "Anorexia, nausea, and low-grade fever",
                    "Leukocytosis with left shift"
                ],
                category: "Gastroenterology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Primary Sclerosing Cholangitis",
                alternativeNames: ["PSC"],
                hints: [
                    "Patient with ulcerative colitis and progressive jaundice",
                    "Pruritus and fatigue",
                    "Elevated alkaline phosphatase",
                    "ERCP shows beading of bile ducts",
                    "Increased risk of cholangiocarcinoma"
                ],
                category: "Gastroenterology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Alcoholic Hepatitis",
                alternativeNames: ["Alcoholic Liver Disease"],
                hints: [
                    "Heavy drinker with jaundice and RUQ pain",
                    "AST:ALT ratio >2:1",
                    "Tender hepatomegaly",
                    "Fever and leukocytosis",
                    "Mallory bodies on liver biopsy"
                ],
                category: "Gastroenterology",
                difficulty: 2
            ),
            
            // NEPHROLOGY (10 cases)
            MedicalCase(
                diagnosis: "Nephrotic Syndrome",
                alternativeNames: ["Nephrosis"],
                hints: [
                    "Child with periorbital edema and frothy urine",
                    "Proteinuria >3.5 g/day",
                    "Hypoalbuminemia and hyperlipidemia",
                    "Hypercoagulable state (loss of antithrombin III)",
                    "Minimal change disease most common in children"
                ],
                category: "Nephrology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "IgA Nephropathy",
                alternativeNames: ["Berger Disease"],
                hints: [
                    "Young male with gross hematuria during URI",
                    "Episodic hematuria coinciding with infections",
                    "IgA deposits in mesangium on immunofluorescence",
                    "Most common cause of glomerulonephritis worldwide",
                    "Variable prognosis, may progress to ESRD"
                ],
                category: "Nephrology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Acute Tubular Necrosis",
                alternativeNames: ["ATN"],
                hints: [
                    "Post-surgical patient with oliguria",
                    "Muddy brown casts on urinalysis",
                    "FENa >2%",
                    "Ischemic or nephrotoxic injury (contrast, aminoglycosides)",
                    "Usually reversible with supportive care"
                ],
                category: "Nephrology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Polycystic Kidney Disease",
                alternativeNames: ["PKD", "ADPKD"],
                hints: [
                    "Adult with bilateral flank masses and hypertension",
                    "Family history of kidney disease",
                    "Associated with berry aneurysms and mitral valve prolapse",
                    "Ultrasound shows multiple bilateral kidney cysts",
                    "PKD1 or PKD2 gene mutations"
                ],
                category: "Nephrology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Goodpasture Syndrome",
                alternativeNames: ["Anti-GBM Disease"],
                hints: [
                    "Young male with hemoptysis and acute kidney injury",
                    "Linear IgG deposits on glomerular basement membrane",
                    "Anti-GBM antibodies positive",
                    "Pulmonary hemorrhage and rapidly progressive glomerulonephritis",
                    "Treated with plasmapheresis and immunosuppression"
                ],
                category: "Nephrology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Acute Interstitial Nephritis",
                alternativeNames: ["AIN"],
                hints: [
                    "Patient recently started on antibiotics or NSAIDs",
                    "Fever, rash, and eosinophilia (allergic triad)",
                    "WBC casts and eosinophils in urine",
                    "Acute kidney injury with preserved urine output",
                    "Drug-induced hypersensitivity reaction"
                ],
                category: "Nephrology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Renal Artery Stenosis",
                alternativeNames: ["RAS"],
                hints: [
                    "Young woman with severe hypertension (fibromuscular dysplasia)",
                    "Or elderly patient with atherosclerotic disease",
                    "Abdominal bruit on exam",
                    "Flash pulmonary edema",
                    "Captopril renal scan shows decreased perfusion"
                ],
                category: "Nephrology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Nephrolithiasis",
                alternativeNames: ["Kidney Stones", "Renal Calculi"],
                hints: [
                    "Patient with severe colicky flank pain radiating to groin",
                    "Hematuria on urinalysis",
                    "Non-contrast CT shows radiopaque stone",
                    "Calcium oxalate stones most common",
                    "Struvite stones associated with Proteus UTI"
                ],
                category: "Nephrology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Membranous Nephropathy",
                alternativeNames: ["Membranous GN"],
                hints: [
                    "Adult with nephrotic syndrome",
                    "Subepithelial immune complex deposits (spike and dome)",
                    "Associated with hepatitis B, SLE, solid tumors",
                    "Anti-PLA2R antibodies in primary disease",
                    "Gradual progression to chronic kidney disease"
                ],
                category: "Nephrology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Hemolytic Uremic Syndrome",
                alternativeNames: ["HUS"],
                hints: [
                    "Child with bloody diarrhea followed by acute kidney injury",
                    "Microangiopathic hemolytic anemia and thrombocytopenia",
                    "Schistocytes on blood smear",
                    "Recent E. coli O157:H7 infection",
                    "Supportive treatment, avoid antibiotics"
                ],
                category: "Nephrology",
                difficulty: 3
            ),
            
            // ENDOCRINOLOGY (10 cases)
            MedicalCase(
                diagnosis: "Hypothyroidism",
                alternativeNames: ["Hashimoto Thyroiditis"],
                hints: [
                    "Woman with fatigue, weight gain, and cold intolerance",
                    "Constipation and dry skin",
                    "Elevated TSH, low T4",
                    "Anti-TPO and anti-thyroglobulin antibodies",
                    "Myxedema if severe"
                ],
                category: "Endocrinology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Graves Disease",
                alternativeNames: ["Hyperthyroidism", "Thyrotoxicosis"],
                hints: [
                    "Woman with weight loss, heat intolerance, and palpitations",
                    "Exophthalmos and pretibial myxedema",
                    "Diffuse goiter with bruit",
                    "Low TSH, elevated T4 and T3",
                    "TSI antibodies positive, increased radioiodine uptake"
                ],
                category: "Endocrinology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Cushing Syndrome",
                alternativeNames: ["Hypercortisolism"],
                hints: [
                    "Patient with central obesity and moon facies",
                    "Purple striae, buffalo hump, easy bruising",
                    "Hyperglycemia and hypertension",
                    "Loss of diurnal cortisol variation",
                    "Dexamethasone suppression test abnormal"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Addison Disease",
                alternativeNames: ["Primary Adrenal Insufficiency"],
                hints: [
                    "Patient with fatigue, weight loss, and hypotension",
                    "Hyperpigmentation in skin creases and mucous membranes",
                    "Hyponatremia and hyperkalemia",
                    "Low cortisol, high ACTH",
                    "Autoimmune destruction of adrenal glands most common"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Diabetes Insipidus",
                alternativeNames: ["DI"],
                hints: [
                    "Patient with polyuria and polydipsia",
                    "Hypernatremia and elevated serum osmolality",
                    "Low urine specific gravity (<1.006)",
                    "Water deprivation test shows inability to concentrate urine",
                    "Central DI responds to desmopressin, nephrogenic does not"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "SIADH",
                alternativeNames: ["Syndrome of Inappropriate ADH"],
                hints: [
                    "Patient with euvolemic hyponatremia",
                    "Low serum osmolality, high urine osmolality",
                    "Urine sodium >40 mEq/L",
                    "Associated with small cell lung cancer, CNS disorders, drugs",
                    "Treated with fluid restriction"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Pheochromocytoma",
                alternativeNames: ["Adrenal Paraganglioma"],
                hints: [
                    "Patient with episodic headaches, palpitations, and sweating",
                    "Paroxysmal hypertension",
                    "Elevated plasma and urine metanephrines",
                    "Adrenal mass on CT or MRI",
                    "Rule of 10s: 10% bilateral, 10% malignant, 10% extra-adrenal"
                ],
                category: "Endocrinology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Hyperparathyroidism",
                alternativeNames: ["Primary Hyperparathyroidism"],
                hints: [
                    "Patient with kidney stones and bone pain",
                    "Hypercalcemia and hypophosphatemia",
                    "Elevated or inappropriately normal PTH",
                    "Osteoporosis or osteitis fibrosa cystica",
                    "Stones, bones, groans, psychiatric overtones"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Acromegaly",
                alternativeNames: ["Growth Hormone Excess"],
                hints: [
                    "Adult with enlarged hands, feet, and facial features",
                    "Prognathism and macroglossia",
                    "Glucose intolerance and hypertension",
                    "Elevated IGF-1 levels",
                    "Pituitary adenoma on MRI"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Type 2 Diabetes Mellitus",
                alternativeNames: ["T2DM", "Diabetes"],
                hints: [
                    "Obese patient with polyuria and polydipsia",
                    "Fasting glucose ≥126 mg/dL or HbA1c ≥6.5%",
                    "Acanthosis nigricans suggests insulin resistance",
                    "Complications include retinopathy, nephropathy, neuropathy",
                    "First-line treatment is metformin"
                ],
                category: "Endocrinology",
                difficulty: 2
            ),
            
            // NEUROLOGY (10 cases)
            MedicalCase(
                diagnosis: "Parkinson Disease",
                alternativeNames: ["PD", "Parkinsonism"],
                hints: [
                    "Elderly patient with resting tremor and bradykinesia",
                    "Cogwheel rigidity and shuffling gait",
                    "Masked facies and micrographia",
                    "Loss of dopaminergic neurons in substantia nigra",
                    "Treated with levodopa/carbidopa"
                ],
                category: "Neurology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Alzheimer Disease",
                alternativeNames: ["AD", "Dementia"],
                hints: [
                    "Elderly patient with progressive memory loss",
                    "Impaired activities of daily living",
                    "Temporal and hippocampal atrophy on MRI",
                    "Beta-amyloid plaques and neurofibrillary tangles",
                    "ApoE4 allele increases risk"
                ],
                category: "Neurology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Ischemic Stroke",
                alternativeNames: ["CVA", "Cerebrovascular Accident"],
                hints: [
                    "Patient with sudden onset focal neurologic deficit",
                    "MCA stroke: contralateral hemiparesis and aphasia",
                    "Hypodensity on CT after 6-24 hours",
                    "Risk factors: atrial fibrillation, hypertension, diabetes",
                    "tPA within 4.5 hours if eligible"
                ],
                category: "Neurology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Migraine",
                alternativeNames: ["Migraine Headache"],
                hints: [
                    "Young woman with recurrent unilateral throbbing headache",
                    "Photophobia and phonophobia",
                    "Aura may precede headache (visual scotomas)",
                    "Nausea and vomiting",
                    "Treated with triptans for acute attacks"
                ],
                category: "Neurology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Temporal Arteritis",
                alternativeNames: ["Giant Cell Arteritis", "GCA"],
                hints: [
                    "Elderly patient with new-onset headache and jaw claudication",
                    "Temporal artery tenderness",
                    "Vision loss risk (ophthalmic artery involvement)",
                    "Elevated ESR and CRP",
                    "Temporal artery biopsy shows granulomatous inflammation"
                ],
                category: "Neurology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Seizure Disorder",
                alternativeNames: ["Epilepsy"],
                hints: [
                    "Patient with recurrent unprovoked seizures",
                    "Tonic-clonic movements with loss of consciousness",
                    "Postictal confusion and Todd's paralysis",
                    "EEG shows epileptiform discharges",
                    "Treated with anti-epileptic drugs"
                ],
                category: "Neurology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Huntington Disease",
                alternativeNames: ["HD"],
                hints: [
                    "Middle-aged patient with chorea and dementia",
                    "Progressive behavioral and psychiatric changes",
                    "Caudate atrophy on MRI",
                    "CAG repeat expansion in HTT gene",
                    "Autosomal dominant inheritance with anticipation"
                ],
                category: "Neurology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Bell's Palsy",
                alternativeNames: ["Idiopathic Facial Nerve Palsy"],
                hints: [
                    "Acute onset unilateral facial weakness",
                    "Unable to close eye or wrinkle forehead on affected side",
                    "Hyperacusis and loss of taste in anterior 2/3 of tongue",
                    "Associated with HSV reactivation",
                    "Most recover spontaneously, steroids may help"
                ],
                category: "Neurology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Amyotrophic Lateral Sclerosis",
                alternativeNames: ["ALS", "Lou Gehrig Disease"],
                hints: [
                    "Adult with progressive muscle weakness and atrophy",
                    "Both upper and lower motor neuron signs",
                    "Fasciculations and hyperreflexia",
                    "Bulbar symptoms: dysarthria and dysphagia",
                    "Riluzole may slow progression"
                ],
                category: "Neurology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Pseudotumor Cerebri",
                alternativeNames: ["Idiopathic Intracranial Hypertension"],
                hints: [
                    "Obese woman of childbearing age with headaches",
                    "Papilledema on fundoscopy",
                    "Vision changes (enlarged blind spot)",
                    "Normal brain imaging, elevated opening pressure on LP",
                    "Associated with vitamin A, tetracyclines, oral contraceptives"
                ],
                category: "Neurology",
                difficulty: 3
            ),
            
            // HEMATOLOGY/ONCOLOGY (10 cases)
            MedicalCase(
                diagnosis: "Iron Deficiency Anemia",
                alternativeNames: ["IDA"],
                hints: [
                    "Woman with fatigue and pallor",
                    "Microcytic hypochromic anemia",
                    "Low ferritin, low iron, high TIBC",
                    "Koilonychia (spoon nails) and pica",
                    "Most common cause is chronic blood loss"
                ],
                category: "Hematology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Vitamin B12 Deficiency",
                alternativeNames: ["Pernicious Anemia"],
                hints: [
                    "Elderly patient with macrocytic anemia",
                    "Neurologic symptoms: paresthesias, ataxia, dementia",
                    "Glossitis and angular cheilitis",
                    "Elevated methylmalonic acid and homocysteine",
                    "Anti-intrinsic factor antibodies in pernicious anemia"
                ],
                category: "Hematology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Acute Myeloid Leukemia",
                alternativeNames: ["AML"],
                hints: [
                    "Adult with fatigue, infections, and bleeding",
                    "Pancytopenia with circulating blasts",
                    "Auer rods on blood smear",
                    ">20% blasts in bone marrow",
                    "Associated with Down syndrome and prior chemotherapy"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Acute Lymphoblastic Leukemia",
                alternativeNames: ["ALL"],
                hints: [
                    "Child with bone pain and fever",
                    "Mediastinal mass on chest X-ray (T-cell type)",
                    "Lymphoblasts with TdT positive",
                    "CNS prophylaxis required",
                    "Best prognosis in children age 2-10"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Chronic Myeloid Leukemia",
                alternativeNames: ["CML"],
                hints: [
                    "Middle-aged patient with leukocytosis and splenomegaly",
                    "Philadelphia chromosome t(9;22), BCR-ABL fusion",
                    "Low leukocyte alkaline phosphatase",
                    "Basophilia on blood smear",
                    "Treated with tyrosine kinase inhibitors (imatinib)"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Hodgkin Lymphoma",
                alternativeNames: ["Hodgkin Disease"],
                hints: [
                    "Young adult with painless cervical lymphadenopathy",
                    "B symptoms: fever, night sweats, weight loss",
                    "Reed-Sternberg cells on biopsy",
                    "Bimodal age distribution (20s and 60s)",
                    "Associated with EBV infection"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Non-Hodgkin Lymphoma",
                alternativeNames: ["NHL"],
                hints: [
                    "Adult with generalized lymphadenopathy",
                    "Extranodal involvement common",
                    "Diffuse large B-cell most common subtype",
                    "Follicular lymphoma has t(14;18) BCL2 translocation",
                    "Burkitt lymphoma has t(8;14) MYC translocation"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Hemophilia A",
                alternativeNames: ["Factor VIII Deficiency"],
                hints: [
                    "Male child with excessive bleeding and hemarthrosis",
                    "X-linked recessive inheritance",
                    "Prolonged PTT, normal PT",
                    "Low factor VIII levels",
                    "Treated with factor VIII replacement"
                ],
                category: "Hematology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Von Willebrand Disease",
                alternativeNames: ["vWD"],
                hints: [
                    "Patient with mucosal bleeding and easy bruising",
                    "Most common inherited bleeding disorder",
                    "Prolonged bleeding time and PTT",
                    "Low vWF antigen and activity",
                    "Treated with desmopressin (DDAVP)"
                ],
                category: "Hematology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Disseminated Intravascular Coagulation",
                alternativeNames: ["DIC"],
                hints: [
                    "Critically ill patient with bleeding and thrombosis",
                    "Prolonged PT, PTT, low platelets, low fibrinogen",
                    "Elevated D-dimer and fibrin split products",
                    "Schistocytes on blood smear",
                    "Underlying triggers: sepsis, malignancy, trauma"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            // RHEUMATOLOGY/IMMUNOLOGY (10 cases)
            MedicalCase(
                diagnosis: "Rheumatoid Arthritis",
                alternativeNames: ["RA"],
                hints: [
                    "Woman with symmetric polyarthritis of small joints",
                    "Morning stiffness lasting >1 hour",
                    "Ulnar deviation and boutonniere deformity",
                    "Positive rheumatoid factor and anti-CCP antibodies",
                    "X-ray shows juxta-articular osteopenia and erosions"
                ],
                category: "Rheumatology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Osteoarthritis",
                alternativeNames: ["OA", "Degenerative Joint Disease"],
                hints: [
                    "Elderly patient with joint pain worse with activity",
                    "Morning stiffness <30 minutes",
                    "Heberden and Bouchard nodes",
                    "X-ray shows joint space narrowing and osteophytes",
                    "Non-inflammatory: normal ESR and CRP"
                ],
                category: "Rheumatology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Gout",
                alternativeNames: ["Gouty Arthritis"],
                hints: [
                    "Man with acute onset red, swollen, painful big toe",
                    "Podagra (MTP joint most common)",
                    "Hyperuricemia and tophi",
                    "Needle-shaped negatively birefringent crystals",
                    "Precipitated by alcohol, purines, diuretics"
                ],
                category: "Rheumatology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Pseudogout",
                alternativeNames: ["CPPD", "Calcium Pyrophosphate Deposition"],
                hints: [
                    "Elderly patient with acute knee pain and swelling",
                    "Chondrocalcinosis on X-ray",
                    "Rhomboid positively birefringent crystals",
                    "Associated with hyperparathyroidism and hemochromatosis",
                    "Treated with NSAIDs and colchicine"
                ],
                category: "Rheumatology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Ankylosing Spondylitis",
                alternativeNames: ["AS"],
                hints: [
                    "Young man with chronic lower back pain and stiffness",
                    "Improves with exercise, worse with rest",
                    "Limited spinal mobility and reduced chest expansion",
                    "HLA-B27 positive",
                    "Bamboo spine on X-ray, anterior uveitis"
                ],
                category: "Rheumatology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Reactive Arthritis",
                alternativeNames: ["Reiter Syndrome"],
                hints: [
                    "Young man with arthritis following GI or GU infection",
                    "Classic triad: urethritis, conjunctivitis, arthritis",
                    "Keratoderma blennorrhagicum and circinate balanitis",
                    "HLA-B27 positive",
                    "Can't see, can't pee, can't climb a tree"
                ],
                category: "Rheumatology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Sjogren Syndrome",
                alternativeNames: ["Sjogren's"],
                hints: [
                    "Middle-aged woman with dry eyes and dry mouth",
                    "Parotid gland enlargement",
                    "Positive anti-Ro (SSA) and anti-La (SSB) antibodies",
                    "Schirmer test shows decreased tear production",
                    "Increased risk of B-cell lymphoma"
                ],
                category: "Rheumatology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Polymyalgia Rheumatica",
                alternativeNames: ["PMR"],
                hints: [
                    "Elderly patient with bilateral shoulder and hip pain",
                    "Morning stiffness and constitutional symptoms",
                    "Elevated ESR and CRP",
                    "Normal muscle enzymes (distinguishes from myositis)",
                    "Dramatic response to low-dose prednisone"
                ],
                category: "Rheumatology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Scleroderma",
                alternativeNames: ["Systemic Sclerosis"],
                hints: [
                    "Woman with skin thickening and Raynaud phenomenon",
                    "CREST syndrome: Calcinosis, Raynaud, Esophageal dysmotility, Sclerodactyly, Telangiectasia",
                    "Anti-centromere antibodies (limited) or anti-Scl-70 (diffuse)",
                    "Pulmonary fibrosis and renal crisis in diffuse type",
                    "Esophageal dysmotility and digital ulcers"
                ],
                category: "Rheumatology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Dermatomyositis",
                alternativeNames: ["DM"],
                hints: [
                    "Patient with proximal muscle weakness",
                    "Heliotrope rash around eyes and Gottron papules on knuckles",
                    "Elevated CK and aldolase",
                    "EMG shows myopathic pattern",
                    "Associated with malignancy in adults"
                ],
                category: "Rheumatology",
                difficulty: 3
            ),
            
            // INFECTIOUS DISEASE (10 cases)
            MedicalCase(
                diagnosis: "HIV/AIDS",
                alternativeNames: ["Human Immunodeficiency Virus"],
                hints: [
                    "Patient with recurrent infections and weight loss",
                    "CD4 count <200 cells/μL defines AIDS",
                    "Opportunistic infections: PCP, CMV, toxoplasmosis",
                    "ELISA screening, Western blot confirmation",
                    "Highly active antiretroviral therapy (HAART)"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Infectious Mononucleosis",
                alternativeNames: ["Mono", "Kissing Disease"],
                hints: [
                    "Teenager with fever, pharyngitis, and fatigue",
                    "Posterior cervical lymphadenopathy",
                    "Splenomegaly (avoid contact sports)",
                    "Atypical lymphocytes on blood smear",
                    "Positive Monospot test, EBV infection"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Lyme Disease",
                alternativeNames: ["Borreliosis"],
                hints: [
                    "Patient with erythema migrans (bulls-eye rash)",
                    "History of tick bite in endemic area",
                    "Early disseminated: facial nerve palsy, AV block",
                    "Late: arthritis and neurologic symptoms",
                    "Caused by Borrelia burgdorferi, treated with doxycycline"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Septic Arthritis",
                alternativeNames: ["Bacterial Arthritis"],
                hints: [
                    "Patient with acute monoarticular joint pain and fever",
                    "Joint is hot, swollen, and tender with limited ROM",
                    "Synovial fluid WBC >50,000 with >90% neutrophils",
                    "Gram stain and culture positive",
                    "Most common: Staph aureus, Neisseria in young adults"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Clostridium difficile Colitis",
                alternativeNames: ["C. diff", "Pseudomembranous Colitis"],
                hints: [
                    "Patient with watery diarrhea after antibiotic use",
                    "Abdominal pain and fever",
                    "Stool positive for C. diff toxin",
                    "Pseudomembranes on colonoscopy",
                    "Treated with vancomycin or fidaxomicin"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Toxic Shock Syndrome",
                alternativeNames: ["TSS"],
                hints: [
                    "Young woman with high fever and hypotension",
                    "Diffuse erythematous rash with desquamation",
                    "Multi-organ involvement",
                    "Associated with tampon use or wound infection",
                    "Staph aureus TSST-1 toxin"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Rocky Mountain Spotted Fever",
                alternativeNames: ["RMSF"],
                hints: [
                    "Patient with fever, headache after tick bite",
                    "Petechial rash starting on wrists and ankles, spreading centrally",
                    "Palms and soles involved",
                    "Rickettsia rickettsii, treated with doxycycline",
                    "Can be fatal if untreated"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Osteomyelitis",
                alternativeNames: ["Bone Infection"],
                hints: [
                    "Patient with fever and bone pain",
                    "Local tenderness and swelling over affected bone",
                    "Elevated ESR and CRP",
                    "MRI shows bone marrow edema",
                    "Staph aureus most common, Salmonella in sickle cell"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Candidiasis",
                alternativeNames: ["Thrush", "Yeast Infection"],
                hints: [
                    "Immunocompromised patient with white plaques in mouth",
                    "Can be scraped off revealing erythematous base",
                    "KOH prep shows budding yeast and pseudohyphae",
                    "Risk factors: diabetes, antibiotics, steroids, HIV",
                    "Treated with nystatin or fluconazole"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Pneumocystis Pneumonia",
                alternativeNames: ["PCP", "PJP"],
                hints: [
                    "HIV patient with CD4 <200 and progressive dyspnea",
                    "Dry cough and fever",
                    "Ground-glass opacities on chest X-ray",
                    "BAL with silver stain shows cysts",
                    "Treated with TMP-SMX"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            // DERMATOLOGY (5 cases)
            MedicalCase(
                diagnosis: "Psoriasis",
                alternativeNames: ["Plaque Psoriasis"],
                hints: [
                    "Patient with well-demarcated erythematous plaques",
                    "Silvery scales, Auspitz sign (pinpoint bleeding when scraped)",
                    "Extensor surfaces commonly involved",
                    "Nail pitting and onycholysis",
                    "Associated with psoriatic arthritis"
                ],
                category: "Dermatology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Melanoma",
                alternativeNames: ["Malignant Melanoma"],
                hints: [
                    "Changing pigmented lesion with irregular borders",
                    "ABCDE: Asymmetry, Border irregularity, Color variation, Diameter >6mm, Evolution",
                    "Risk factors: UV exposure, fair skin, dysplastic nevi",
                    "Breslow thickness determines prognosis",
                    "Sentinel lymph node biopsy for staging"
                ],
                category: "Dermatology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Basal Cell Carcinoma",
                alternativeNames: ["BCC"],
                hints: [
                    "Elderly patient with pearly papule with telangiectasias",
                    "Central ulceration (rodent ulcer)",
                    "Sun-exposed areas most common",
                    "Most common skin cancer but rarely metastasizes",
                    "Treated with excision or Mohs surgery"
                ],
                category: "Dermatology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Eczema",
                alternativeNames: ["Atopic Dermatitis"],
                hints: [
                    "Child with pruritic erythematous patches",
                    "Flexural surfaces commonly involved",
                    "Lichenification from chronic scratching",
                    "Associated with asthma and allergic rhinitis (atopic triad)",
                    "Elevated IgE levels"
                ],
                category: "Dermatology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Stevens-Johnson Syndrome",
                alternativeNames: ["SJS", "Toxic Epidermal Necrolysis"],
                hints: [
                    "Patient with painful skin blisters and mucosal involvement",
                    "Recent drug exposure (sulfonamides, anticonvulsants, allopurinol)",
                    "Positive Nikolsky sign",
                    "Targetoid lesions with epidermal detachment",
                    "Medical emergency requiring ICU care"
                ],
                category: "Dermatology",
                difficulty: 4
            ),
            
            // OPHTHALMOLOGY (3 cases)
            MedicalCase(
                diagnosis: "Glaucoma",
                alternativeNames: ["Open-Angle Glaucoma", "Angle-Closure Glaucoma"],
                hints: [
                    "Patient with progressive peripheral vision loss",
                    "Elevated intraocular pressure",
                    "Optic disc cupping on fundoscopy",
                    "Acute angle-closure: severe eye pain, halos, fixed dilated pupil",
                    "Leading cause of irreversible blindness"
                ],
                category: "Ophthalmology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Cataract",
                alternativeNames: ["Lens Opacity"],
                hints: [
                    "Elderly patient with gradual vision loss and glare",
                    "Opacity of lens visible on examination",
                    "Risk factors: aging, diabetes, steroids, UV exposure",
                    "Treated with surgical lens replacement",
                    "Most common cause of reversible blindness worldwide"
                ],
                category: "Ophthalmology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Retinal Detachment",
                alternativeNames: ["RD"],
                hints: [
                    "Patient with sudden floaters and flashes of light",
                    "Curtain or shadow over visual field",
                    "Risk factors: myopia, trauma, prior eye surgery",
                    "Ophthalmoscopy shows detached retina",
                    "Surgical emergency to prevent permanent vision loss"
                ],
                category: "Ophthalmology",
                difficulty: 3
            ),
            
            // OBSTETRICS/GYNECOLOGY (5 cases)
            MedicalCase(
                diagnosis: "Preeclampsia",
                alternativeNames: ["Toxemia of Pregnancy"],
                hints: [
                    "Pregnant woman >20 weeks with hypertension and proteinuria",
                    "Headache, visual changes, RUQ pain",
                    "Hyperreflexia and edema",
                    "Risk of eclampsia (seizures) and HELLP syndrome",
                    "Definitive treatment is delivery"
                ],
                category: "Obstetrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Ectopic Pregnancy",
                alternativeNames: ["Tubal Pregnancy"],
                hints: [
                    "Woman with positive pregnancy test and abdominal pain",
                    "Vaginal bleeding",
                    "Risk factors: PID, prior ectopic, IUD",
                    "β-hCG not doubling appropriately",
                    "Empty uterus on ultrasound, adnexal mass"
                ],
                category: "Obstetrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Polycystic Ovary Syndrome",
                alternativeNames: ["PCOS"],
                hints: [
                    "Woman with oligomenorrhea and infertility",
                    "Hirsutism and acne",
                    "Insulin resistance and obesity",
                    "Elevated LH:FSH ratio",
                    "Multiple ovarian cysts on ultrasound"
                ],
                category: "Gynecology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Endometriosis",
                alternativeNames: [],
                hints: [
                    "Woman with cyclic pelvic pain worse during menstruation",
                    "Dysmenorrhea, dyspareunia, dyschezia",
                    "Chocolate cysts (endometriomas) on ovaries",
                    "Laparoscopy shows ectopic endometrial tissue",
                    "Treated with NSAIDs, OCPs, or surgery"
                ],
                category: "Gynecology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Placenta Previa",
                alternativeNames: [],
                hints: [
                    "Pregnant woman with painless vaginal bleeding in third trimester",
                    "Placenta covering internal cervical os on ultrasound",
                    "No cervical exam (can precipitate hemorrhage)",
                    "Risk factors: prior C-section, multiparity",
                    "Delivery by C-section required"
                ],
                category: "Obstetrics",
                difficulty: 3
            ),
            
            // PEDIATRICS (7 cases)
            MedicalCase(
                diagnosis: "Kawasaki Disease",
                alternativeNames: ["Mucocutaneous Lymph Node Syndrome"],
                hints: [
                    "Child with high fever >5 days unresponsive to antibiotics",
                    "Bilateral conjunctivitis, strawberry tongue, oral mucositis",
                    "Polymorphous rash and cervical lymphadenopathy",
                    "Desquamation of hands and feet",
                    "Risk of coronary artery aneurysms, treated with IVIG and aspirin"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Croup",
                alternativeNames: ["Laryngotracheobronchitis"],
                hints: [
                    "Toddler with barking cough and stridor",
                    "Preceded by URI symptoms",
                    "Steeple sign on neck X-ray",
                    "Parainfluenza virus most common cause",
                    "Treated with dexamethasone and cool mist"
                ],
                category: "Pediatrics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Epiglottitis",
                alternativeNames: ["Supraglottitis"],
                hints: [
                    "Child with high fever, drooling, and difficulty swallowing",
                    "Tripod positioning and muffled voice",
                    "Thumbprint sign on lateral neck X-ray",
                    "Haemophilus influenzae type B historically",
                    "Medical emergency, secure airway"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Intussusception",
                alternativeNames: [],
                hints: [
                    "Infant with colicky abdominal pain and vomiting",
                    "Currant jelly stools",
                    "Sausage-shaped mass on palpation",
                    "Target sign on ultrasound",
                    "Air or contrast enema for diagnosis and treatment"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Pyloric Stenosis",
                alternativeNames: ["Infantile Hypertrophic Pyloric Stenosis"],
                hints: [
                    "6-week-old with projectile non-bilious vomiting",
                    "Olive-shaped mass in epigastrium",
                    "Hypochloremic hypokalemic metabolic alkalosis",
                    "Ultrasound shows thickened pylorus",
                    "Treated with pyloromyotomy"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Respiratory Distress Syndrome",
                alternativeNames: ["RDS", "Hyaline Membrane Disease"],
                hints: [
                    "Premature infant with respiratory distress at birth",
                    "Tachypnea, grunting, nasal flaring, retractions",
                    "Ground-glass appearance on chest X-ray",
                    "Surfactant deficiency",
                    "Prevented with antenatal corticosteroids"
                ],
                category: "Pediatrics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Neonatal Jaundice",
                alternativeNames: ["Hyperbilirubinemia of the Newborn"],
                hints: [
                    "Newborn with yellow skin and sclera",
                    "Physiologic jaundice peaks at 3-5 days",
                    "Pathologic if <24 hours, bilirubin >12-15 mg/dL",
                    "Risk of kernicterus if severe",
                    "Treated with phototherapy or exchange transfusion"
                ],
                category: "Pediatrics",
                difficulty: 2
            ),
            
            // PSYCHIATRY (5 cases)
            MedicalCase(
                diagnosis: "Schizophrenia",
                alternativeNames: [],
                hints: [
                    "Young adult with delusions and hallucinations",
                    "Disorganized speech and behavior",
                    "Negative symptoms: flat affect, alogia, avolition",
                    "Symptoms >6 months",
                    "Treated with antipsychotic medications"
                ],
                category: "Psychiatry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Bipolar Disorder",
                alternativeNames: ["Manic Depression"],
                hints: [
                    "Patient with episodes of mania and depression",
                    "Manic episode: elevated mood, decreased need for sleep, grandiosity",
                    "Pressured speech and flight of ideas",
                    "Risky behavior and poor judgment",
                    "Treated with mood stabilizers (lithium, valproate)"
                ],
                category: "Psychiatry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Generalized Anxiety Disorder",
                alternativeNames: ["GAD"],
                hints: [
                    "Patient with excessive worry for >6 months",
                    "Difficulty controlling anxiety",
                    "Restlessness, fatigue, difficulty concentrating",
                    "Muscle tension and sleep disturbance",
                    "Treated with SSRIs and CBT"
                ],
                category: "Psychiatry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Panic Disorder",
                alternativeNames: ["Panic Attacks"],
                hints: [
                    "Patient with recurrent unexpected panic attacks",
                    "Palpitations, sweating, trembling, shortness of breath",
                    "Fear of dying or losing control",
                    "Persistent worry about future attacks",
                    "Treated with SSRIs and benzodiazepines for acute attacks"
                ],
                category: "Psychiatry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Anorexia Nervosa",
                alternativeNames: ["Anorexia"],
                hints: [
                    "Young woman with excessive weight loss and fear of gaining weight",
                    "Distorted body image",
                    "Amenorrhea and lanugo",
                    "Bradycardia and hypotension",
                    "Medical complications: osteoporosis, cardiac arrhythmias"
                ],
                category: "Psychiatry",
                difficulty: 2
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
            // CARDIOLOGY (8 cases)
            MedicalCase(
                diagnosis: "Restrictive Cardiomyopathy",
                alternativeNames: ["RCM"],
                hints: [
                    "Patient with heart failure symptoms but preserved ejection fraction",
                    "Jugular venous distension with Kussmaul sign",
                    "Biatrial enlargement on echocardiogram",
                    "Causes include amyloidosis, sarcoidosis, hemochromatosis",
                    "Diastolic dysfunction with preserved systolic function"
                ],
                category: "Cardiology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Takotsubo Cardiomyopathy",
                alternativeNames: ["Stress Cardiomyopathy", "Broken Heart Syndrome"],
                hints: [
                    "Postmenopausal woman with chest pain after emotional stress",
                    "ECG changes mimicking MI but normal coronary arteries",
                    "Apical ballooning on ventriculography",
                    "Elevated troponins and BNP",
                    "Usually reversible within weeks"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Mitral Stenosis",
                alternativeNames: ["MS"],
                hints: [
                    "Patient with dyspnea and hemoptysis",
                    "Opening snap followed by diastolic rumble at apex",
                    "Loud S1, malar flush",
                    "Most commonly due to rheumatic heart disease",
                    "Atrial fibrillation common complication"
                ],
                category: "Cardiology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Aortic Regurgitation",
                alternativeNames: ["AR", "Aortic Insufficiency"],
                hints: [
                    "Patient with bounding pulses and wide pulse pressure",
                    "High-pitched diastolic decrescendo murmur at LSB",
                    "De Musset sign (head bobbing), Quincke sign (nail bed pulsations)",
                    "Austin Flint murmur (functional MS)",
                    "Causes include endocarditis, aortic dissection, Marfan syndrome"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Atrial Septal Defect",
                alternativeNames: ["ASD"],
                hints: [
                    "Young adult with fixed split S2",
                    "Soft systolic ejection murmur at left upper sternal border",
                    "Right ventricular heave",
                    "Paradoxical embolism can cause stroke",
                    "Eisenmenger syndrome if untreated"
                ],
                category: "Cardiology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Patent Ductus Arteriosus",
                alternativeNames: ["PDA"],
                hints: [
                    "Infant with continuous machine-like murmur",
                    "Bounding peripheral pulses",
                    "Wide pulse pressure",
                    "Associated with congenital rubella syndrome",
                    "Indomethacin closes PDA in neonates"
                ],
                category: "Cardiology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Dressler Syndrome",
                alternativeNames: ["Post-MI Pericarditis"],
                hints: [
                    "Patient with chest pain 2-10 weeks after MI",
                    "Pleuritic pain and pericardial friction rub",
                    "Fever and elevated ESR",
                    "Autoimmune reaction to myocardial antigens",
                    "Treated with NSAIDs or colchicine"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Myocarditis",
                alternativeNames: ["Viral Myocarditis"],
                hints: [
                    "Young patient with heart failure after viral illness",
                    "Chest pain, dyspnea, and arrhythmias",
                    "Elevated troponins and dilated ventricles",
                    "Most commonly caused by Coxsackie B virus",
                    "Endomyocardial biopsy shows lymphocytic infiltration"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            
            // PULMONOLOGY (8 cases)
            MedicalCase(
                diagnosis: "Pulmonary Hypertension",
                alternativeNames: ["PH", "PAH"],
                hints: [
                    "Patient with progressive dyspnea and fatigue",
                    "Loud P2, right ventricular heave",
                    "Right heart catheterization shows mPAP >20 mmHg",
                    "Associated with scleroderma, chronic PE, COPD",
                    "Treated with prostacyclin analogs and endothelin antagonists"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Bronchiectasis",
                alternativeNames: [],
                hints: [
                    "Patient with chronic productive cough with copious sputum",
                    "Recurrent infections and hemoptysis",
                    "Coarse crackles on exam",
                    "Tram-track sign on chest X-ray",
                    "Associated with CF, primary ciliary dyskinesia, prior TB"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Hypersensitivity Pneumonitis",
                alternativeNames: ["Extrinsic Allergic Alveolitis"],
                hints: [
                    "Farmer or bird keeper with dyspnea hours after exposure",
                    "Fever, cough, and malaise after antigen exposure",
                    "Upper lobe fibrosis on CT",
                    "Examples: farmer's lung, bird fancier's lung",
                    "Removal of antigen is key to treatment"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Acute Respiratory Distress Syndrome",
                alternativeNames: ["ARDS"],
                hints: [
                    "Critically ill patient with acute hypoxemic respiratory failure",
                    "Bilateral infiltrates on chest X-ray",
                    "PaO2/FiO2 ratio <300",
                    "Non-cardiogenic pulmonary edema",
                    "Causes include sepsis, aspiration, trauma, pancreatitis"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Silicosis",
                alternativeNames: ["Pneumoconiosis"],
                hints: [
                    "Sandblaster or miner with progressive dyspnea",
                    "Eggshell calcification of hilar nodes",
                    "Upper lobe nodules on chest X-ray",
                    "Increased risk of TB and lung cancer",
                    "Progressive massive fibrosis in advanced cases"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Asbestosis",
                alternativeNames: [],
                hints: [
                    "Shipyard worker with progressive dyspnea",
                    "Bibasilar crackles and clubbing",
                    "Pleural plaques on chest X-ray",
                    "Increased risk of mesothelioma and lung cancer",
                    "Restrictive lung disease pattern"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Small Cell Lung Cancer",
                alternativeNames: ["SCLC", "Oat Cell Carcinoma"],
                hints: [
                    "Heavy smoker with mediastinal mass",
                    "Paraneoplastic syndromes: SIADH, Lambert-Eaton syndrome",
                    "Small blue cells on histology",
                    "Central location, early metastasis",
                    "Treated with chemotherapy and radiation"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Goodpasture Syndrome",
                alternativeNames: ["Anti-GBM Disease"],
                hints: [
                    "Young male with hemoptysis and hematuria",
                    "Pulmonary hemorrhage and glomerulonephritis",
                    "Linear IgG deposits on kidney and lung biopsy",
                    "Anti-GBM antibodies",
                    "Treated with plasmapheresis and immunosuppression"
                ],
                category: "Pulmonology",
                difficulty: 4
            ),
            
            // GASTROENTEROLOGY (10 cases)
            MedicalCase(
                diagnosis: "Achalasia",
                alternativeNames: [],
                hints: [
                    "Patient with progressive dysphagia to solids and liquids",
                    "Food regurgitation and weight loss",
                    "Bird beak appearance on barium swallow",
                    "Absent peristalsis and failure of LES relaxation",
                    "Increased risk of esophageal squamous cell carcinoma"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Mallory-Weiss Tear",
                alternativeNames: [],
                hints: [
                    "Patient with hematemesis after forceful vomiting",
                    "History of alcohol use or bulimia",
                    "Longitudinal mucosal tear at GE junction",
                    "Usually self-limited bleeding",
                    "Boerhaave syndrome is full-thickness perforation"
                ],
                category: "Gastroenterology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Zenker Diverticulum",
                alternativeNames: ["Pharyngeal Pouch"],
                hints: [
                    "Elderly patient with dysphagia and halitosis",
                    "Food regurgitation and gurgling sounds",
                    "Outpouching between thyropharyngeal and cricopharyngeal muscles",
                    "Aspiration risk",
                    "Barium swallow shows posterior pharyngeal pouch"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Barrett Esophagus",
                alternativeNames: ["Barrett's"],
                hints: [
                    "Patient with chronic GERD",
                    "Metaplasia from squamous to columnar epithelium",
                    "Increased risk of esophageal adenocarcinoma",
                    "Requires surveillance endoscopy",
                    "Salmon-colored mucosa on endoscopy"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Primary Biliary Cholangitis",
                alternativeNames: ["PBC", "Primary Biliary Cirrhosis"],
                hints: [
                    "Middle-aged woman with pruritus and fatigue",
                    "Elevated alkaline phosphatase",
                    "Anti-mitochondrial antibodies positive",
                    "Destruction of intrahepatic bile ducts",
                    "Associated with other autoimmune diseases"
                ],
                category: "Gastroenterology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Whipple Disease",
                alternativeNames: [],
                hints: [
                    "Patient with weight loss, diarrhea, and arthralgias",
                    "Neurologic symptoms and cardiac involvement",
                    "Tropheryma whipplei infection",
                    "PAS-positive macrophages in small intestine",
                    "Treated with long-term antibiotics"
                ],
                category: "Gastroenterology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Hemochromatosis",
                alternativeNames: ["Iron Overload"],
                hints: [
                    "Patient with bronze diabetes: skin hyperpigmentation and diabetes",
                    "Hepatomegaly and arthropathy",
                    "Elevated ferritin and transferrin saturation",
                    "HFE gene mutation (C282Y)",
                    "Treated with phlebotomy"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Wilson Disease",
                alternativeNames: ["Hepatolenticular Degeneration"],
                hints: [
                    "Young patient with liver disease and neuropsychiatric symptoms",
                    "Kayser-Fleischer rings on slit-lamp exam",
                    "Low ceruloplasmin, elevated urinary copper",
                    "ATP7B gene mutation",
                    "Treated with chelators (penicillamine) or zinc"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Budd-Chiari Syndrome",
                alternativeNames: ["Hepatic Vein Thrombosis"],
                hints: [
                    "Patient with acute hepatomegaly, ascites, and abdominal pain",
                    "Nutmeg liver appearance",
                    "Associated with hypercoagulable states",
                    "Hepatic vein thrombosis on imaging",
                    "May require TIPS or anticoagulation"
                ],
                category: "Gastroenterology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Spontaneous Bacterial Peritonitis",
                alternativeNames: ["SBP"],
                hints: [
                    "Cirrhotic patient with fever and abdominal pain",
                    "Ascitic fluid PMN >250 cells/μL",
                    "Most commonly E. coli or Klebsiella",
                    "Prophylaxis with fluoroquinolones after first episode",
                    "Elevated serum-ascites albumin gradient >1.1 g/dL"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            // NEPHROLOGY (8 cases)
            MedicalCase(
                diagnosis: "Alport Syndrome",
                alternativeNames: ["Hereditary Nephritis"],
                hints: [
                    "Young male with hematuria and progressive renal failure",
                    "Sensorineural hearing loss",
                    "Anterior lenticonus and retinal abnormalities",
                    "Basket-weave appearance of GBM on EM",
                    "X-linked mutation in collagen IV"
                ],
                category: "Nephrology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Fanconi Syndrome",
                alternativeNames: [],
                hints: [
                    "Patient with polyuria and bone pain",
                    "Proximal tubule dysfunction with multiple losses",
                    "Glucosuria, aminoaciduria, phosphaturia",
                    "Type 2 RTA (proximal)",
                    "Causes include multiple myeloma, heavy metals, drugs"
                ],
                category: "Nephrology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Bartter Syndrome",
                alternativeNames: [],
                hints: [
                    "Child with growth retardation and weakness",
                    "Hypokalemic metabolic alkalosis",
                    "Elevated renin and aldosterone with normal BP",
                    "Defect in thick ascending limb Na-K-2Cl cotransporter",
                    "Like chronic loop diuretic use"
                ],
                category: "Nephrology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Gitelman Syndrome",
                alternativeNames: [],
                hints: [
                    "Young adult with muscle cramps and tetany",
                    "Hypokalemia, hypomagnesemia, hypocalciuria",
                    "Metabolic alkalosis",
                    "Defect in distal convoluted tubule NaCl cotransporter",
                    "Like chronic thiazide use, usually benign"
                ],
                category: "Nephrology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Minimal Change Disease",
                alternativeNames: ["MCD"],
                hints: [
                    "Child with sudden onset nephrotic syndrome",
                    "Selective proteinuria (mostly albumin)",
                    "Normal light microscopy, podocyte effacement on EM",
                    "Excellent response to corticosteroids",
                    "May be triggered by infections or immunizations"
                ],
                category: "Nephrology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Focal Segmental Glomerulosclerosis",
                alternativeNames: ["FSGS"],
                hints: [
                    "Young adult with nephrotic syndrome",
                    "Associated with HIV, heroin use, obesity",
                    "Segmental sclerosis on biopsy",
                    "Poor response to steroids",
                    "Leading cause of nephrotic syndrome in African Americans"
                ],
                category: "Nephrology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Post-Streptococcal Glomerulonephritis",
                alternativeNames: ["PSGN"],
                hints: [
                    "Child with hematuria 2 weeks after pharyngitis",
                    "Periorbital edema and hypertension",
                    "Low C3 complement levels",
                    "Subepithelial immune complex deposits (humps)",
                    "Positive ASO titers"
                ],
                category: "Nephrology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Liddle Syndrome",
                alternativeNames: ["Pseudohyperaldosteronism"],
                hints: [
                    "Young patient with early-onset hypertension",
                    "Hypokalemia and metabolic alkalosis",
                    "Low aldosterone and low renin",
                    "Increased ENaC activity in collecting duct",
                    "Treated with amiloride or triamterene"
                ],
                category: "Nephrology",
                difficulty: 4
            ),
            
            // ENDOCRINOLOGY (8 cases)
            MedicalCase(
                diagnosis: "Conn Syndrome",
                alternativeNames: ["Primary Hyperaldosteronism"],
                hints: [
                    "Patient with hypertension and hypokalemia",
                    "Metabolic alkalosis",
                    "High aldosterone, low renin",
                    "Adrenal adenoma or bilateral hyperplasia",
                    "Treated with spironolactone or surgery"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Hyperaldosteronism Secondary",
                alternativeNames: ["Secondary Hyperaldosteronism"],
                hints: [
                    "Patient with edema and heart failure",
                    "High aldosterone AND high renin",
                    "Activation of RAAS system",
                    "Causes include renal artery stenosis, heart failure, cirrhosis",
                    "Both aldosterone and renin elevated"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Carcinoid Syndrome",
                alternativeNames: ["Carcinoid Tumor"],
                hints: [
                    "Patient with episodic flushing and diarrhea",
                    "Wheezing and right-sided heart valve disease",
                    "Elevated 5-HIAA in 24-hour urine",
                    "Serotonin-producing neuroendocrine tumor",
                    "Pellagra-like symptoms (niacin deficiency)"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Zollinger-Ellison Syndrome",
                alternativeNames: ["Gastrinoma"],
                hints: [
                    "Patient with refractory peptic ulcers",
                    "Diarrhea due to gastric acid hypersecretion",
                    "Elevated fasting gastrin >1000 pg/mL",
                    "Gastrin-secreting tumor in pancreas or duodenum",
                    "Associated with MEN1 syndrome"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Multiple Endocrine Neoplasia Type 1",
                alternativeNames: ["MEN1", "Wermer Syndrome"],
                hints: [
                    "Patient with hyperparathyroidism, pituitary adenoma, and pancreatic tumors",
                    "Three P's: Parathyroid, Pituitary, Pancreas",
                    "Menin gene mutation",
                    "Autosomal dominant inheritance",
                    "Gastrinoma most common pancreatic tumor"
                ],
                category: "Endocrinology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Multiple Endocrine Neoplasia Type 2",
                alternativeNames: ["MEN2"],
                hints: [
                    "Patient with medullary thyroid cancer and pheochromocytoma",
                    "MEN2A: parathyroid adenoma also present",
                    "MEN2B: marfanoid habitus, mucosal neuromas",
                    "RET proto-oncogene mutation",
                    "Prophylactic thyroidectomy recommended"
                ],
                category: "Endocrinology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Sheehan Syndrome",
                alternativeNames: ["Postpartum Pituitary Necrosis"],
                hints: [
                    "Woman unable to lactate after postpartum hemorrhage",
                    "Panhypopituitarism symptoms",
                    "Amenorrhea, cold intolerance, fatigue",
                    "Ischemic necrosis of pituitary",
                    "Low levels of all pituitary hormones"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Craniopharyngioma",
                alternativeNames: [],
                hints: [
                    "Child with growth failure and vision problems",
                    "Bitemporal hemianopsia from optic chiasm compression",
                    "Calcified suprasellar mass on CT",
                    "Hypopituitarism and diabetes insipidus",
                    "Derived from Rathke's pouch remnant"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            // NEUROLOGY (10 cases)
            MedicalCase(
                diagnosis: "Normal Pressure Hydrocephalus",
                alternativeNames: ["NPH"],
                hints: [
                    "Elderly patient with wet, wobbly, wacky triad",
                    "Urinary incontinence, ataxia, dementia",
                    "Enlarged ventricles with normal opening pressure",
                    "Reversible with ventriculoperitoneal shunt",
                    "Magnetic gait (feet stuck to floor)"
                ],
                category: "Neurology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Wernicke Encephalopathy",
                alternativeNames: ["Wernicke-Korsakoff Syndrome"],
                hints: [
                    "Chronic alcoholic with confusion and ataxia",
                    "Classic triad: confusion, ophthalmoplegia, ataxia",
                    "Thiamine (B1) deficiency",
                    "Mammillary body hemorrhage",
                    "Give thiamine before glucose to prevent precipitation"
                ],
                category: "Neurology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Central Pontine Myelinolysis",
                alternativeNames: ["Osmotic Demyelination Syndrome"],
                hints: [
                    "Patient with acute quadriplegia after rapid Na correction",
                    "Locked-in syndrome",
                    "Demyelination of basis pontis",
                    "Occurs when hyponatremia corrected too quickly (>10-12 mEq/day)",
                    "MRI shows hyperintense lesion in pons"
                ],
                category: "Neurology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Trigeminal Neuralgia",
                alternativeNames: ["Tic Douloureux"],
                hints: [
                    "Patient with lancinating facial pain",
                    "Triggered by light touch, chewing, or talking",
                    "Affects V2/V3 distribution most commonly",
                    "MRI may show vascular compression of CN V",
                    "Treated with carbamazepine"
                ],
                category: "Neurology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Creutzfeldt-Jakob Disease",
                alternativeNames: ["CJD", "Prion Disease"],
                hints: [
                    "Rapid progressive dementia with myoclonus",
                    "Startle myoclonus",
                    "Periodic sharp wave complexes on EEG",
                    "14-3-3 protein in CSF",
                    "Spongiform encephalopathy, invariably fatal"
                ],
                category: "Neurology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Friedreich Ataxia",
                alternativeNames: [],
                hints: [
                    "Teenager with progressive ataxia and dysarthria",
                    "Loss of position and vibration sense",
                    "Kyphoscoliosis and pes cavus",
                    "Hypertrophic cardiomyopathy",
                    "GAA trinucleotide repeat in frataxin gene"
                ],
                category: "Neurology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Charcot-Marie-Tooth Disease",
                alternativeNames: ["Hereditary Motor and Sensory Neuropathy"],
                hints: [
                    "Young patient with foot drop and distal weakness",
                    "Stork leg or inverted champagne bottle appearance",
                    "Pes cavus and hammer toes",
                    "Onion bulb formation on nerve biopsy",
                    "Most common inherited neuropathy"
                ],
                category: "Neurology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Syringomyelia",
                alternativeNames: ["Syrinx"],
                hints: [
                    "Patient with cape-like loss of pain and temperature sensation",
                    "Preserved touch and proprioception",
                    "Upper extremity weakness and atrophy",
                    "Fluid-filled cavity in central spinal cord",
                    "Associated with Chiari malformation"
                ],
                category: "Neurology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Posterior Fossa Malformations - Chiari",
                alternativeNames: ["Chiari Malformation"],
                hints: [
                    "Patient with headaches worse with Valsalva",
                    "Downward displacement of cerebellar tonsils",
                    "Type I: asymptomatic or syringomyelia",
                    "Type II: associated with myelomeningocele",
                    "May cause hydrocephalus"
                ],
                category: "Neurology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Lambert-Eaton Myasthenic Syndrome",
                alternativeNames: ["LEMS"],
                hints: [
                    "Patient with proximal muscle weakness improving with use",
                    "Associated with small cell lung cancer",
                    "Antibodies against presynaptic calcium channels",
                    "Decreased DTRs that improve with repeated testing",
                    "Autonomic dysfunction common"
                ],
                category: "Neurology",
                difficulty: 4
            ),
            
            // HEMATOLOGY/ONCOLOGY (10 cases)
            MedicalCase(
                diagnosis: "Thalassemia",
                alternativeNames: ["Beta-Thalassemia"],
                hints: [
                    "Mediterranean or Asian patient with microcytic anemia",
                    "Target cells on blood smear",
                    "Elevated HbF and HbA2 on electrophoresis",
                    "Thalassemia major: severe anemia, hepatosplenomegaly",
                    "Crew-cut skull on X-ray from marrow expansion"
                ],
                category: "Hematology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Glucose-6-Phosphate Dehydrogenase Deficiency",
                alternativeNames: ["G6PD Deficiency"],
                hints: [
                    "Male with episodic hemolytic anemia after oxidant stress",
                    "Triggers include fava beans, sulfa drugs, antimalarials",
                    "Bite cells and Heinz bodies on smear",
                    "X-linked recessive inheritance",
                    "Protection against malaria"
                ],
                category: "Hematology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Hereditary Spherocytosis",
                alternativeNames: [],
                hints: [
                    "Patient with jaundice and splenomegaly",
                    "Spherocytes on blood smear",
                    "Positive osmotic fragility test",
                    "Spectrin or ankyrin deficiency",
                    "Splenectomy is curative"
                ],
                category: "Hematology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Paroxysmal Nocturnal Hemoglobinuria",
                alternativeNames: ["PNH"],
                hints: [
                    "Patient with dark urine in morning",
                    "Intravascular hemolysis and pancytopenia",
                    "Absent CD55 and CD59 on flow cytometry",
                    "Increased risk of thrombosis (Budd-Chiari, cerebral veins)",
                    "Eculizumab blocks complement"
                ],
                category: "Hematology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Polycythemia Vera",
                alternativeNames: ["PV"],
                hints: [
                    "Patient with elevated hemoglobin and pruritus after bathing",
                    "Plethoric appearance and splenomegaly",
                    "JAK2 V617F mutation",
                    "Low erythropoietin levels",
                    "Risk of thrombosis and transformation to AML"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Essential Thrombocythemia",
                alternativeNames: ["ET"],
                hints: [
                    "Patient with platelet count >450,000",
                    "Bleeding and thrombosis despite high platelets",
                    "JAK2 mutation in ~50% of cases",
                    "Treated with hydroxyurea or anagrelide",
                    "May transform to myelofibrosis or AML"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Myelofibrosis",
                alternativeNames: ["Primary Myelofibrosis"],
                hints: [
                    "Patient with massive splenomegaly and fatigue",
                    "Leukoerythroblastic blood smear",
                    "Teardrop cells and dry bone marrow tap",
                    "JAK2 mutation common",
                    "Extramedullary hematopoiesis"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Multiple Myeloma",
                alternativeNames: ["Plasma Cell Myeloma"],
                hints: [
                    "Elderly patient with back pain and anemia",
                    "CRAB: Calcium elevated, Renal failure, Anemia, Bone lesions",
                    "Monoclonal spike on SPEP",
                    "Bence Jones protein in urine",
                    "Rouleaux formation on blood smear"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Waldenstrom Macroglobulinemia",
                alternativeNames: [],
                hints: [
                    "Elderly patient with hyperviscosity symptoms",
                    "Visual changes, bleeding, neurologic symptoms",
                    "IgM monoclonal gammopathy",
                    "Lymphoplasmacytic lymphoma",
                    "Treated with plasmapheresis acutely"
                ],
                category: "Hematology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Thrombotic Thrombocytopenic Purpura",
                alternativeNames: ["TTP"],
                hints: [
                    "Patient with fever, neurologic changes, and purpura",
                    "Pentad: fever, thrombocytopenia, microangiopathic hemolytic anemia, renal failure, neurologic symptoms",
                    "Schistocytes and elevated LDH",
                    "Deficiency of ADAMTS13",
                    "Treated with plasmapheresis"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            // RHEUMATOLOGY/IMMUNOLOGY (6 cases)
            MedicalCase(
                diagnosis: "Behçet Disease",
                alternativeNames: ["Behcet's"],
                hints: [
                    "Young adult with recurrent oral and genital ulcers",
                    "Uveitis and skin lesions",
                    "Positive pathergy test",
                    "Vasculitis of small and large vessels",
                    "Common in Middle East and Asia"
                ],
                category: "Rheumatology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Kawasaki Disease",
                alternativeNames: ["Mucocutaneous Lymph Node Syndrome"],
                hints: [
                    "Child with persistent fever >5 days",
                    "Conjunctivitis, strawberry tongue, cervical lymphadenopathy",
                    "Desquamating rash on hands and feet",
                    "Risk of coronary artery aneurysms",
                    "Treated with IVIG and aspirin"
                ],
                category: "Rheumatology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Mixed Connective Tissue Disease",
                alternativeNames: ["MCTD"],
                hints: [
                    "Patient with features of SLE, scleroderma, and polymyositis",
                    "Raynaud phenomenon and swollen hands",
                    "Anti-U1 RNP antibodies",
                    "Generally good prognosis",
                    "Overlap syndrome"
                ],
                category: "Rheumatology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Giant Cell Arteritis",
                alternativeNames: ["Temporal Arteritis", "GCA"],
                hints: [
                    "Elderly with new headache and jaw claudication",
                    "Risk of blindness from anterior ischemic optic neuropathy",
                    "Markedly elevated ESR (often >100)",
                    "Temporal artery biopsy shows granulomatous inflammation",
                    "Start steroids immediately, don't wait for biopsy"
                ],
                category: "Rheumatology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Takayasu Arteritis",
                alternativeNames: ["Pulseless Disease"],
                hints: [
                    "Young Asian woman with decreased pulses",
                    "Claudication and blood pressure discrepancies",
                    "Granulomatous vasculitis of aorta and major branches",
                    "Constitutional symptoms and elevated ESR",
                    "Treated with corticosteroids"
                ],
                category: "Rheumatology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Polyarteritis Nodosa",
                alternativeNames: ["PAN"],
                hints: [
                    "Patient with fever, weight loss, and multisystem involvement",
                    "Skin nodules and livedo reticularis",
                    "Associated with hepatitis B",
                    "Angiography shows microaneurysms",
                    "Spares lungs, ANCA negative"
                ],
                category: "Rheumatology",
                difficulty: 4
            ),
            
            // INFECTIOUS DISEASE (6 cases)
            MedicalCase(
                diagnosis: "Malaria",
                alternativeNames: ["Plasmodium Infection"],
                hints: [
                    "Traveler from endemic area with cyclic fevers",
                    "Fever spikes every 48-72 hours",
                    "Splenomegaly and hemolytic anemia",
                    "Ring forms and banana gametocytes on blood smear",
                    "P. falciparum most severe, causes cerebral malaria"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Toxoplasmosis",
                alternativeNames: [],
                hints: [
                    "HIV patient with multiple ring-enhancing lesions on MRI",
                    "Encephalitis with seizures and focal deficits",
                    "IgG antibodies positive",
                    "Associated with cats and undercooked meat",
                    "Treated with pyrimethamine and sulfadiazine"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Cryptococcal Meningitis",
                alternativeNames: ["Cryptococcosis"],
                hints: [
                    "HIV patient with headache and altered mental status",
                    "India ink stain shows encapsulated yeast",
                    "Positive cryptococcal antigen",
                    "Soap bubble lesions in brain",
                    "Treated with amphotericin B and flucytosine"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Histoplasmosis",
                alternativeNames: [],
                hints: [
                    "Patient from Ohio/Mississippi River Valley with pneumonia",
                    "Exposure to bird or bat droppings",
                    "Granulomas with intracellular yeast",
                    "Calcified granulomas resemble TB",
                    "Disseminated form in immunocompromised"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Coccidioidomycosis",
                alternativeNames: ["Valley Fever"],
                hints: [
                    "Patient from Southwest US with pneumonia",
                    "Erythema nodosum and arthralgias",
                    "Spherules with endospores on microscopy",
                    "Can cause chronic cavitary disease",
                    "Higher risk in pregnant women and immunocompromised"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Blastomycosis",
                alternativeNames: [],
                hints: [
                    "Patient from Great Lakes region with pneumonia",
                    "Skin lesions with verrucous appearance",
                    "Broad-based budding yeast",
                    "Can disseminate to bone and CNS",
                    "Treated with itraconazole or amphotericin B"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            // DERMATOLOGY (4 cases)
            MedicalCase(
                diagnosis: "Squamous Cell Carcinoma",
                alternativeNames: ["SCC"],
                hints: [
                    "Elderly patient with ulcerated nodule on sun-exposed skin",
                    "Arises from actinic keratosis",
                    "Can metastasize unlike BCC",
                    "Keratin pearls on histology",
                    "Higher risk on lip, ear, genitals"
                ],
                category: "Dermatology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Pemphigus Vulgaris",
                alternativeNames: [],
                hints: [
                    "Patient with painful oral erosions and flaccid skin blisters",
                    "Positive Nikolsky sign",
                    "IgG antibodies against desmoglein 3",
                    "Acantholysis on histology (tombstone cells)",
                    "Treated with corticosteroids and immunosuppressants"
                ],
                category: "Dermatology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Bullous Pemphigoid",
                alternativeNames: [],
                hints: [
                    "Elderly patient with tense bullae and pruritus",
                    "Oral mucosa usually spared",
                    "IgG antibodies against hemidesmosomes",
                    "Linear IgG and C3 at basement membrane on immunofluorescence",
                    "Better prognosis than pemphigus vulgaris"
                ],
                category: "Dermatology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Erythema Multiforme",
                alternativeNames: ["EM"],
                hints: [
                    "Patient with target lesions after HSV infection",
                    "Palms and soles involved",
                    "May have mucosal involvement",
                    "Self-limited, usually resolves in 2-4 weeks",
                    "Distinguished from SJS by <10% body surface area"
                ],
                category: "Dermatology",
                difficulty: 2
            ),
            
            // PEDIATRICS (6 cases)
            MedicalCase(
                diagnosis: "Hirschsprung Disease",
                alternativeNames: ["Congenital Aganglionic Megacolon"],
                hints: [
                    "Newborn with failure to pass meconium in first 48 hours",
                    "Chronic constipation and abdominal distension",
                    "Absence of ganglion cells in rectum",
                    "Transition zone on barium enema",
                    "Associated with Down syndrome"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Necrotizing Enterocolitis",
                alternativeNames: ["NEC"],
                hints: [
                    "Premature infant with feeding intolerance and bloody stools",
                    "Abdominal distension and pneumatosis intestinalis",
                    "Portal venous gas on X-ray",
                    "Can lead to perforation and sepsis",
                    "NPO, antibiotics, surgical resection if perforated"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Retinopathy of Prematurity",
                alternativeNames: ["ROP"],
                hints: [
                    "Premature infant with abnormal retinal vascularization",
                    "Caused by excessive oxygen supplementation",
                    "Can lead to retinal detachment and blindness",
                    "Screening exams required in at-risk infants",
                    "Treated with laser photocoagulation"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "DiGeorge Syndrome",
                alternativeNames: ["22q11.2 Deletion Syndrome"],
                hints: [
                    "Infant with tetany from hypocalcemia",
                    "CATCH-22: Cardiac defects, Abnormal facies, Thymic aplasia, Cleft palate, Hypocalcemia",
                    "Absent thymic shadow on chest X-ray",
                    "T-cell immunodeficiency",
                    "Chromosome 22q11 deletion"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Wiskott-Aldrich Syndrome",
                alternativeNames: ["WAS"],
                hints: [
                    "Male infant with eczema, thrombocytopenia, and recurrent infections",
                    "Small platelets on blood smear",
                    "X-linked recessive",
                    "Increased IgA and IgE, decreased IgM",
                    "Risk of lymphoma and autoimmune disease"
                ],
                category: "Pediatrics",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Tetralogy of Fallot - Tet Spell",
                alternativeNames: ["Hypercyanotic Spell"],
                hints: [
                    "Infant with known TOF develops sudden cyanosis and dyspnea",
                    "Triggered by crying, feeding, or defecation",
                    "Increased right-to-left shunting",
                    "Child instinctively squats to increase SVR",
                    "Treated acutely with knee-chest position, oxygen, morphine"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            
            // OPHTHALMOLOGY (2 cases)
            MedicalCase(
                diagnosis: "Macular Degeneration",
                alternativeNames: ["Age-Related Macular Degeneration", "AMD"],
                hints: [
                    "Elderly patient with central vision loss",
                    "Drusen on fundoscopy",
                    "Dry type (geographic atrophy) or wet type (neovascularization)",
                    "Amsler grid shows distortion",
                    "Anti-VEGF therapy for wet AMD"
                ],
                category: "Ophthalmology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Diabetic Retinopathy",
                alternativeNames: [],
                hints: [
                    "Diabetic patient with gradual vision loss",
                    "Cotton-wool spots and microaneurysms",
                    "Proliferative stage: neovascularization",
                    "Macular edema can occur",
                    "Leading cause of blindness in working-age adults"
                ],
                category: "Ophthalmology",
                difficulty: 2
            ),
            
            // PSYCHIATRY (2 cases)
            MedicalCase(
                diagnosis: "Obsessive-Compulsive Disorder",
                alternativeNames: ["OCD"],
                hints: [
                    "Patient with intrusive thoughts causing anxiety",
                    "Repetitive behaviors (compulsions) to reduce anxiety",
                    "Insight that behaviors are excessive",
                    "Significantly impairs daily functioning",
                    "Treated with SSRIs and exposure therapy"
                ],
                category: "Psychiatry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Post-Traumatic Stress Disorder",
                alternativeNames: ["PTSD"],
                hints: [
                    "Patient with flashbacks and nightmares after trauma",
                    "Avoidance of trauma-related stimuli",
                    "Hypervigilance and exaggerated startle response",
                    "Symptoms >1 month",
                    "Treated with trauma-focused psychotherapy and SSRIs"
                ],
                category: "Psychiatry",
                difficulty: 2
            ),
            
            // OBSTETRICS (2 cases)
            MedicalCase(
                diagnosis: "HELLP Syndrome",
                alternativeNames: [],
                hints: [
                    "Pregnant woman with severe preeclampsia and abdominal pain",
                    "Hemolysis, Elevated Liver enzymes, Low Platelets",
                    "RUQ pain from hepatic subcapsular hematoma",
                    "Risk of hepatic rupture and DIC",
                    "Delivery is definitive treatment"
                ],
                category: "Obstetrics",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Placental Abruption",
                alternativeNames: ["Abruptio Placentae"],
                hints: [
                    "Pregnant woman with painful vaginal bleeding",
                    "Tender, firm uterus (board-like)",
                    "Risk factors: hypertension, trauma, cocaine use",
                    "Fetal distress on monitoring",
                    "Emergency delivery required"
                ],
                category: "Obstetrics",
                difficulty: 3
            ),
            // CARDIOLOGY (7 cases)
            MedicalCase(
                diagnosis: "Tricuspid Regurgitation",
                alternativeNames: ["TR"],
                hints: [
                    "Patient with pulsatile liver and prominent v waves in JVP",
                    "Holosystolic murmur at left lower sternal border",
                    "Increases with inspiration (Carvallo sign)",
                    "Associated with IV drug use (endocarditis)",
                    "Pansystolic murmur radiating to right"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Pulmonic Stenosis",
                alternativeNames: ["PS"],
                hints: [
                    "Patient with systolic ejection click that decreases with inspiration",
                    "Crescendo-decrescendo murmur at left upper sternal border",
                    "Wide splitting of S2",
                    "Associated with Noonan syndrome and rubella",
                    "Right ventricular hypertrophy on ECG"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Brugada Syndrome",
                alternativeNames: [],
                hints: [
                    "Young patient with sudden cardiac death or syncope",
                    "Pseudo-right bundle branch block on ECG",
                    "ST elevation in V1-V3 (coved or saddleback pattern)",
                    "Sodium channel mutation (SCN5A)",
                    "ICD placement recommended"
                ],
                category: "Cardiology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Long QT Syndrome",
                alternativeNames: ["LQTS"],
                hints: [
                    "Young patient with syncope during exercise or stress",
                    "Prolonged QT interval corrected for heart rate (QTc >460 ms)",
                    "Risk of torsades de pointes",
                    "Can be congenital or drug-induced",
                    "Treated with beta-blockers, avoid QT-prolonging drugs"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Transposition of Great Arteries",
                alternativeNames: ["TGA", "D-TGA"],
                hints: [
                    "Cyanotic newborn with egg-on-string appearance on X-ray",
                    "Aorta arises from RV, pulmonary artery from LV",
                    "PDA and ASD/VSD needed for survival",
                    "Prostaglandin E1 to keep ductus open",
                    "Arterial switch operation required"
                ],
                category: "Cardiology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Eisenmenger Syndrome",
                alternativeNames: [],
                hints: [
                    "Adult with history of uncorrected VSD now with cyanosis",
                    "Reversal of left-to-right shunt due to pulmonary hypertension",
                    "Clubbing and polycythemia",
                    "Differential cyanosis if PDA (pink fingers, blue toes)",
                    "Contraindication to surgical repair at this stage"
                ],
                category: "Cardiology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Sick Sinus Syndrome",
                alternativeNames: ["Sinus Node Dysfunction"],
                hints: [
                    "Elderly patient with alternating bradycardia and tachycardia",
                    "Syncope and lightheadedness",
                    "Sinus pauses on ECG",
                    "Tachy-brady syndrome",
                    "Requires pacemaker placement"
                ],
                category: "Cardiology",
                difficulty: 3
            ),
            
            // PULMONOLOGY (7 cases)
            MedicalCase(
                diagnosis: "Mesothelioma",
                alternativeNames: ["Malignant Mesothelioma"],
                hints: [
                    "Patient with asbestos exposure and dyspnea",
                    "Unilateral pleural thickening and effusion",
                    "Chest pain and weight loss",
                    "Psammoma bodies on biopsy",
                    "Very poor prognosis, not related to smoking"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Pancoast Tumor",
                alternativeNames: ["Superior Sulcus Tumor"],
                hints: [
                    "Smoker with shoulder pain radiating down arm",
                    "Horner syndrome (ptosis, miosis, anhidrosis)",
                    "Apical lung mass invading brachial plexus",
                    "C8-T1 nerve root involvement",
                    "Usually non-small cell lung cancer"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Wegener Granulomatosis",
                alternativeNames: ["Granulomatosis with Polyangiitis", "GPA"],
                hints: [
                    "Patient with sinusitis, hemoptysis, and hematuria",
                    "Saddle nose deformity and perforation of nasal septum",
                    "c-ANCA (anti-PR3) positive",
                    "Necrotizing granulomas and vasculitis",
                    "Treated with cyclophosphamide and steroids"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Churg-Strauss Syndrome",
                alternativeNames: ["Eosinophilic Granulomatosis with Polyangiitis", "EGPA"],
                hints: [
                    "Asthmatic patient with peripheral neuropathy",
                    "Eosinophilia and pulmonary infiltrates",
                    "p-ANCA (anti-MPO) positive in 50%",
                    "Vasculitis affecting multiple organs",
                    "Associated with leukotriene inhibitor use"
                ],
                category: "Pulmonology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Kartagener Syndrome",
                alternativeNames: ["Primary Ciliary Dyskinesia"],
                hints: [
                    "Patient with chronic sinusitis, bronchiectasis, and infertility",
                    "Situs inversus totalis",
                    "Immotile sperm and recurrent otitis media",
                    "Dynein arm defect in cilia",
                    "Autosomal recessive inheritance"
                ],
                category: "Pulmonology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Hamartoma",
                alternativeNames: ["Pulmonary Hamartoma"],
                hints: [
                    "Incidental coin lesion on chest X-ray",
                    "Popcorn calcification pattern",
                    "Benign tumor containing cartilage, fat, and connective tissue",
                    "Most common benign lung tumor",
                    "Usually asymptomatic"
                ],
                category: "Pulmonology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Loeffler Syndrome",
                alternativeNames: ["Simple Pulmonary Eosinophilia"],
                hints: [
                    "Patient with transient pulmonary infiltrates and eosinophilia",
                    "Associated with parasitic infections (Ascaris)",
                    "Mild respiratory symptoms or asymptomatic",
                    "Self-limited, resolves spontaneously",
                    "Migratory infiltrates on chest X-ray"
                ],
                category: "Pulmonology",
                difficulty: 3
            ),
            
            // GASTROENTEROLOGY (8 cases)
            MedicalCase(
                diagnosis: "Peutz-Jeghers Syndrome",
                alternativeNames: ["PJS"],
                hints: [
                    "Patient with perioral freckling and pigmented macules",
                    "Multiple hamartomatous polyps throughout GI tract",
                    "Intussusception risk",
                    "Increased risk of GI and other cancers",
                    "Autosomal dominant (STK11 gene)"
                ],
                category: "Gastroenterology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Familial Adenomatous Polyposis",
                alternativeNames: ["FAP"],
                hints: [
                    "Young patient with hundreds of colonic polyps",
                    "100% progression to colorectal cancer by age 40",
                    "APC gene mutation",
                    "Prophylactic colectomy required",
                    "Associated with Gardner syndrome and Turcot syndrome"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Lynch Syndrome",
                alternativeNames: ["Hereditary Nonpolyposis Colorectal Cancer", "HNPCC"],
                hints: [
                    "Family history of early-onset colorectal cancer",
                    "DNA mismatch repair gene defect",
                    "Right-sided colon cancers more common",
                    "Microsatellite instability",
                    "Increased risk of endometrial and ovarian cancer"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Ogilvie Syndrome",
                alternativeNames: ["Acute Colonic Pseudo-obstruction"],
                hints: [
                    "Hospitalized patient with massive colonic distension",
                    "No mechanical obstruction",
                    "Associated with surgery, medications, or critical illness",
                    "Cecal diameter >12 cm risks perforation",
                    "Treated with neostigmine or decompression"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Tropical Sprue",
                alternativeNames: [],
                hints: [
                    "Traveler with chronic diarrhea and malabsorption",
                    "Folate and B12 deficiency",
                    "Villous atrophy similar to celiac disease",
                    "Endemic in Caribbean, India, Southeast Asia",
                    "Responds to antibiotics and folate"
                ],
                category: "Gastroenterology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Ischemic Colitis",
                alternativeNames: [],
                hints: [
                    "Elderly patient with sudden onset bloody diarrhea and abdominal pain",
                    "Watershed areas most vulnerable (splenic flexure)",
                    "Thumbprinting on abdominal X-ray",
                    "Colonoscopy shows segmental inflammation",
                    "Usually self-limited"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Carcinoid Tumor",
                alternativeNames: ["Neuroendocrine Tumor"],
                hints: [
                    "Patient with intermittent diarrhea and facial flushing",
                    "Most commonly in appendix or small bowel",
                    "Elevated 5-HIAA in urine",
                    "Carcinoid syndrome if liver metastases present",
                    "Treated with octreotide"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Mesenteric Ischemia",
                alternativeNames: ["Acute Mesenteric Ischemia"],
                hints: [
                    "Elderly patient with severe periumbilical pain out of proportion to exam",
                    "Pain after eating (intestinal angina) if chronic",
                    "Atrial fibrillation is risk factor for embolic type",
                    "Elevated lactate and metabolic acidosis",
                    "Requires urgent revascularization"
                ],
                category: "Gastroenterology",
                difficulty: 3
            ),
            
            // NEPHROLOGY (7 cases)
            MedicalCase(
                diagnosis: "Rapidly Progressive Glomerulonephritis",
                alternativeNames: ["RPGN", "Crescentic GN"],
                hints: [
                    "Patient with acute kidney injury over days to weeks",
                    "Hematuria and RBC casts",
                    "Crescents on kidney biopsy",
                    "Types: anti-GBM, immune complex, pauci-immune (ANCA)",
                    "Requires urgent treatment to prevent ESRD"
                ],
                category: "Nephrology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Diabetic Nephropathy",
                alternativeNames: ["Diabetic Kidney Disease"],
                hints: [
                    "Diabetic patient with progressive proteinuria",
                    "Microalbuminuria is earliest sign",
                    "Kimmelstiel-Wilson nodules on biopsy",
                    "Leading cause of ESRD in United States",
                    "ACE inhibitors slow progression"
                ],
                category: "Nephrology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Hypertensive Nephropathy",
                alternativeNames: ["Hypertensive Nephrosclerosis"],
                hints: [
                    "Patient with long-standing hypertension and CKD",
                    "Benign: arteriosclerosis with gradual decline",
                    "Malignant: acute renal failure with BP >180/120",
                    "Onion-skinning of arterioles in malignant type",
                    "Second leading cause of ESRD"
                ],
                category: "Nephrology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Contrast-Induced Nephropathy",
                alternativeNames: ["CIN"],
                hints: [
                    "Patient with rise in creatinine 24-48 hours after contrast",
                    "Risk factors: CKD, diabetes, volume depletion",
                    "Usually non-oliguric",
                    "Prevented with IV hydration",
                    "Usually reversible"
                ],
                category: "Nephrology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Rhabdomyolysis",
                alternativeNames: [],
                hints: [
                    "Patient with muscle pain, weakness, and dark urine after exertion",
                    "Markedly elevated CK (>5000)",
                    "Myoglobinuria without RBCs",
                    "Risk of AKI from tubular obstruction",
                    "Treated with aggressive IV hydration"
                ],
                category: "Nephrology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Tumor Lysis Syndrome",
                alternativeNames: ["TLS"],
                hints: [
                    "Cancer patient with AKI after starting chemotherapy",
                    "Hyperkalemia, hyperphosphatemia, hyperuricemia, hypocalcemia",
                    "Most common with hematologic malignancies",
                    "Can cause cardiac arrhythmias and seizures",
                    "Prevented with allopurinol or rasburicase and hydration"
                ],
                category: "Nephrology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Medullary Sponge Kidney",
                alternativeNames: [],
                hints: [
                    "Young adult with recurrent kidney stones",
                    "Dilated collecting ducts in renal pyramids",
                    "Bouquet of flowers appearance on IVP",
                    "Hematuria and nephrocalcinosis",
                    "Usually benign prognosis"
                ],
                category: "Nephrology",
                difficulty: 3
            ),
            
            // ENDOCRINOLOGY (7 cases)
            MedicalCase(
                diagnosis: "Insulinoma",
                alternativeNames: [],
                hints: [
                    "Patient with Whipple triad: symptoms of hypoglycemia, low glucose, relief with food",
                    "Elevated insulin and C-peptide during hypoglycemia",
                    "Most common pancreatic neuroendocrine tumor",
                    "Treated with surgical resection",
                    "Part of MEN1 syndrome"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Glucagonoma",
                alternativeNames: [],
                hints: [
                    "Patient with diabetes and necrolytic migratory erythema",
                    "Weight loss and diarrhea",
                    "Elevated glucagon levels",
                    "4 D's: Dermatitis, Diabetes, DVT, Depression",
                    "Pancreatic alpha cell tumor"
                ],
                category: "Endocrinology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "VIPoma",
                alternativeNames: ["Verner-Morrison Syndrome"],
                hints: [
                    "Patient with massive watery diarrhea (>3L/day)",
                    "WDHA syndrome: Watery Diarrhea, Hypokalemia, Achlorhydria",
                    "Elevated VIP levels",
                    "Pancreatic islet cell tumor",
                    "Treated with octreotide"
                ],
                category: "Endocrinology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Congenital Adrenal Hyperplasia",
                alternativeNames: ["CAH"],
                hints: [
                    "Newborn with ambiguous genitalia or salt-wasting crisis",
                    "21-hydroxylase deficiency most common",
                    "Elevated 17-hydroxyprogesterone",
                    "Virilization in females, early puberty in males",
                    "Treated with corticosteroids"
                ],
                category: "Endocrinology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Klinefelter Syndrome",
                alternativeNames: ["47,XXY"],
                hints: [
                    "Tall male with small testes and gynecomastia",
                    "Infertility and decreased testosterone",
                    "Elevated FSH and LH",
                    "Increased risk of breast cancer and autoimmune diseases",
                    "Diagnosed by karyotype showing XXY"
                ],
                category: "Endocrinology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Turner Syndrome",
                alternativeNames: ["45,X"],
                hints: [
                    "Short female with webbed neck and shield chest",
                    "Primary amenorrhea and streak ovaries",
                    "Coarctation of aorta and bicuspid aortic valve",
                    "Lymphedema at birth",
                    "Horseshoe kidney"
                ],
                category: "Endocrinology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Prolactinoma",
                alternativeNames: ["Pituitary Adenoma"],
                hints: [
                    "Woman with amenorrhea, galactorrhea, and infertility",
                    "Visual field defects if macroadenoma",
                    "Elevated prolactin levels",
                    "MRI shows pituitary mass",
                    "Treated with dopamine agonists (cabergoline, bromocriptine)"
                ],
                category: "Endocrinology",
                difficulty: 2
            ),
            
            // NEUROLOGY (8 cases)
            MedicalCase(
                diagnosis: "Vertebrobasilar Insufficiency",
                alternativeNames: ["Posterior Circulation Stroke"],
                hints: [
                    "Patient with vertigo, diplopia, and ataxia",
                    "Drop attacks without loss of consciousness",
                    "Dysphagia and dysarthria",
                    "Crossed findings: ipsilateral CN deficit, contralateral motor/sensory",
                    "Subclavian steal syndrome if related to subclavian stenosis"
                ],
                category: "Neurology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Cavernous Sinus Thrombosis",
                alternativeNames: ["CST"],
                hints: [
                    "Patient with periorbital edema and ophthalmoplegia",
                    "Recent facial infection or sinusitis",
                    "CN III, IV, V1, V2, and VI involvement",
                    "Proptosis and dilated pupil",
                    "Life-threatening, requires urgent antibiotics"
                ],
                category: "Neurology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Subdural Hematoma",
                alternativeNames: ["SDH"],
                hints: [
                    "Elderly patient with progressive headache after minor head trauma",
                    "Crescentic hyperdensity on CT not crossing midline",
                    "Can cross suture lines",
                    "Caused by tearing of bridging veins",
                    "More common in elderly and alcoholics"
                ],
                category: "Neurology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Epidural Hematoma",
                alternativeNames: ["EDH"],
                hints: [
                    "Patient with lucid interval after head trauma",
                    "Lens-shaped (biconvex) hyperdensity on CT",
                    "Does not cross suture lines",
                    "Middle meningeal artery rupture",
                    "Surgical emergency"
                ],
                category: "Neurology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Transient Ischemic Attack",
                alternativeNames: ["TIA", "Mini-Stroke"],
                hints: [
                    "Patient with temporary focal neurologic deficit",
                    "Symptoms resolve within 24 hours (usually <1 hour)",
                    "No infarction on imaging",
                    "High risk for subsequent stroke",
                    "Requires urgent workup and antiplatelet therapy"
                ],
                category: "Neurology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Benign Essential Tremor",
                alternativeNames: ["Essential Tremor"],
                hints: [
                    "Patient with bilateral postural and kinetic tremor",
                    "Improves with alcohol consumption",
                    "Family history common (autosomal dominant)",
                    "No rigidity or bradykinesia",
                    "Treated with propranolol or primidone"
                ],
                category: "Neurology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Neurofibromatosis Type 1",
                alternativeNames: ["NF1", "Von Recklinghausen Disease"],
                hints: [
                    "Patient with café-au-lait spots and neurofibromas",
                    "Lisch nodules (iris hamartomas)",
                    "Axillary/inguinal freckling",
                    "Optic gliomas and increased tumor risk",
                    "Autosomal dominant, chromosome 17"
                ],
                category: "Neurology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Tuberous Sclerosis",
                alternativeNames: ["TSC"],
                hints: [
                    "Child with seizures and developmental delay",
                    "Ash-leaf spots and shagreen patches",
                    "Facial angiofibromas (adenoma sebaceum)",
                    "Cortical tubers and subependymal giant cell astrocytomas",
                    "Cardiac rhabdomyomas and renal angiomyolipomas"
                ],
                category: "Neurology",
                difficulty: 3
            ),
            
            // HEMATOLOGY/ONCOLOGY (8 cases)
            MedicalCase(
                diagnosis: "Aplastic Anemia",
                alternativeNames: ["Bone Marrow Failure"],
                hints: [
                    "Patient with pancytopenia and hypocellular bone marrow",
                    "No hepatosplenomegaly",
                    "Causes include benzene, chloramphenicol, radiation",
                    "Fanconi anemia is inherited form",
                    "Treated with immunosuppression or bone marrow transplant"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Myelodysplastic Syndrome",
                alternativeNames: ["MDS", "Preleukemia"],
                hints: [
                    "Elderly patient with refractory cytopenias",
                    "Hypercellular bone marrow with dysplastic changes",
                    "Ringed sideroblasts may be present",
                    "Risk of transformation to AML",
                    "Treated with azacitidine or bone marrow transplant"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Hairy Cell Leukemia",
                alternativeNames: ["HCL"],
                hints: [
                    "Middle-aged male with pancytopenia and splenomegaly",
                    "Hairy projections on lymphocytes",
                    "TRAP stain positive",
                    "Dry tap on bone marrow aspiration",
                    "Treated with cladribine"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Chronic Lymphocytic Leukemia",
                alternativeNames: ["CLL"],
                hints: [
                    "Elderly patient with asymptomatic lymphocytosis",
                    "Smudge cells on blood smear",
                    "CD5+ B cells",
                    "Most common leukemia in Western adults",
                    "May transform to Richter syndrome (aggressive lymphoma)"
                ],
                category: "Hematology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Langerhans Cell Histiocytosis",
                alternativeNames: ["Histiocytosis X"],
                hints: [
                    "Child with lytic bone lesions and diabetes insipidus",
                    "Eosinophilic granuloma (bone), Hand-Schuller-Christian, Letterer-Siwe",
                    "Birbeck granules (tennis racket) on EM",
                    "CD1a and S100 positive",
                    "Ranges from benign to aggressive"
                ],
                category: "Hematology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Bernard-Soulier Syndrome",
                alternativeNames: [],
                hints: [
                    "Patient with mucosal bleeding and large platelets",
                    "Deficiency of GPIb receptor",
                    "Impaired platelet adhesion to vWF",
                    "Prolonged bleeding time, normal PT/PTT",
                    "Ristocetin cofactor assay abnormal"
                ],
                category: "Hematology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Glanzmann Thrombasthenia",
                alternativeNames: [],
                hints: [
                    "Patient with mucosal bleeding and normal platelet count",
                    "Deficiency of GPIIb/IIIa receptor",
                    "Impaired platelet aggregation",
                    "Prolonged bleeding time, normal PT/PTT",
                    "Blood smear shows no platelet clumping"
                ],
                category: "Hematology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Factor V Leiden",
                alternativeNames: ["Activated Protein C Resistance"],
                hints: [
                    "Young patient with recurrent DVTs",
                    "Most common inherited thrombophilia",
                    "Mutation makes Factor V resistant to degradation",
                    "Increased risk with oral contraceptives",
                    "Autosomal dominant inheritance"
                ],
                category: "Hematology",
                difficulty: 3
            ),
            
            // RHEUMATOLOGY/IMMUNOLOGY (7 cases)
            MedicalCase(
                diagnosis: "Relapsing Polychondritis",
                alternativeNames: [],
                hints: [
                    "Patient with recurrent episodes of cartilage inflammation",
                    "Red, painful, swollen ears (sparing lobule)",
                    "Saddle nose deformity and tracheal involvement",
                    "Associated with autoimmune diseases",
                    "Treated with corticosteroids"
                ],
                category: "Rheumatology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Adult-Onset Still Disease",
                alternativeNames: ["AOSD"],
                hints: [
                    "Young adult with high spiking fevers and evanescent salmon-colored rash",
                    "Arthritis and sore throat",
                    "Markedly elevated ferritin",
                    "Diagnosis of exclusion",
                    "Responds to NSAIDs or corticosteroids"
                ],
                category: "Rheumatology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Felty Syndrome",
                alternativeNames: [],
                hints: [
                    "Long-standing RA patient with splenomegaly",
                    "Neutropenia and recurrent infections",
                    "Leg ulcers",
                    "Positive rheumatoid factor",
                    "May require splenectomy"
                ],
                category: "Rheumatology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Henoch-Schönlein Purpura",
                alternativeNames: ["IgA Vasculitis"],
                hints: [
                    "Child with palpable purpura on buttocks and legs",
                    "Abdominal pain and GI bleeding",
                    "Arthritis and glomerulonephritis",
                    "IgA deposition in vessels",
                    "Often follows upper respiratory infection"
                ],
                category: "Rheumatology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Microscopic Polyangiitis",
                alternativeNames: ["MPA"],
                hints: [
                    "Patient with pulmonary-renal syndrome",
                    "p-ANCA (anti-MPO) positive",
                    "Necrotizing vasculitis without granulomas",
                    "Distinguishes from Wegener by absence of granulomas",
                    "Treated with cyclophosphamide"
                ],
                category: "Rheumatology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Cryoglobulinemia",
                alternativeNames: [],
                hints: [
                    "Patient with palpable purpura, arthralgias, and weakness",
                    "Associated with hepatitis C",
                    "Immunoglobulins precipitate in cold",
                    "Low complement levels",
                    "Can cause membranoproliferative GN"
                ],
                category: "Rheumatology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Antiphospholipid Syndrome",
                alternativeNames: ["APS"],
                hints: [
                    "Patient with recurrent thromboses and miscarriages",
                    "Prolonged PTT that doesn't correct with mixing study",
                    "Anticardiolipin and anti-beta-2-glycoprotein antibodies",
                    "Lupus anticoagulant positive",
                    "Treated with anticoagulation"
                ],
                category: "Rheumatology",
                difficulty: 3
            ),
            
            // INFECTIOUS DISEASE (7 cases)
            MedicalCase(
                diagnosis: "Actinomycosis",
                alternativeNames: [],
                hints: [
                    "Patient with cervicofacial abscess and sulfur granules",
                    "Draining sinus tracts",
                    "Gram-positive filamentous branching rods",
                    "Anaerobic bacteria, normal oral flora",
                    "Treated with prolonged penicillin"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Nocardiosis",
                alternativeNames: [],
                hints: [
                    "Immunocompromised patient with pulmonary infection",
                    "Brain abscesses common",
                    "Weakly acid-fast, branching filaments",
                    "Aerobic bacteria from soil",
                    "Treated with TMP-SMX"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Cat Scratch Disease",
                alternativeNames: ["Bartonella Henselae"],
                hints: [
                    "Child with regional lymphadenopathy after cat scratch",
                    "Papule at inoculation site",
                    "Granulomatous inflammation",
                    "Self-limited in immunocompetent",
                    "Bacillary angiomatosis in HIV patients"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Erythema Migrans",
                alternativeNames: ["Lyme Disease Primary"],
                hints: [
                    "Patient with expanding erythematous rash with central clearing",
                    "Bulls-eye or target lesion",
                    "History of tick bite in endemic area",
                    "First stage of Lyme disease",
                    "Treated with doxycycline"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Scarlet Fever",
                alternativeNames: ["Scarlatina"],
                hints: [
                    "Child with sandpaper-like rash and strawberry tongue",
                    "Follows Group A Strep pharyngitis",
                    "Pastia lines in skin folds",
                    "Circumoral pallor",
                    "Desquamation follows rash"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Roseola Infantum",
                alternativeNames: ["Exanthem Subitum", "Sixth Disease"],
                hints: [
                    "Infant with high fever for 3-5 days",
                    "Rash appears as fever resolves",
                    "Rose-pink maculopapular rash on trunk",
                    "HHV-6 infection",
                    "Febrile seizures common"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Hand-Foot-Mouth Disease",
                alternativeNames: ["HFMD"],
                hints: [
                    "Child with vesicles on hands, feet, and mouth",
                    "Painful oral ulcers",
                    "Coxsackievirus A16 most common",
                    "Self-limited illness",
                    "Highly contagious"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            // DERMATOLOGY (5 cases)
            MedicalCase(
                diagnosis: "Acanthosis Nigricans",
                alternativeNames: [],
                hints: [
                    "Patient with velvety hyperpigmentation in skin folds",
                    "Neck, axillae, and groin involvement",
                    "Associated with insulin resistance and obesity",
                    "Can be sign of underlying malignancy (gastric)",
                    "Improved with weight loss"
                ],
                category: "Dermatology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Pityriasis Rosea",
                alternativeNames: [],
                hints: [
                    "Patient with herald patch followed by Christmas tree distribution",
                    "Oval lesions with collarette of scale",
                    "Self-limited, resolves in 6-8 weeks",
                    "May follow viral illness",
                    "Treated symptomatically"
                ],
                category: "Dermatology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Seborrheic Keratosis",
                alternativeNames: [],
                hints: [
                    "Elderly patient with stuck-on waxy papules",
                    "Horn cysts visible on dermoscopy",
                    "Most common benign skin tumor",
                    "No malignant potential",
                    "Sign of Leser-Trélat: sudden appearance with malignancy"
                ],
                category: "Dermatology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Actinic Keratosis",
                alternativeNames: ["Solar Keratosis"],
                hints: [
                    "Elderly patient with rough, scaly patches on sun-exposed skin",
                    "Sandpaper-like texture",
                    "Precancerous lesion",
                    "Can progress to squamous cell carcinoma",
                    "Treated with cryotherapy or 5-FU cream"
                ],
                category: "Dermatology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Dermatitis Herpetiformis",
                alternativeNames: [],
                hints: [
                    "Patient with intensely pruritic vesicles on extensor surfaces",
                    "Associated with celiac disease",
                    "IgA deposits at dermal papillae",
                    "Responds to gluten-free diet",
                    "Treated with dapsone"
                ],
                category: "Dermatology",
                difficulty: 3
            ),
            
            // PEDIATRICS (6 cases)
            MedicalCase(
                diagnosis: "Bronchiolitis",
                alternativeNames: ["RSV"],
                hints: [
                    "Infant with wheezing and respiratory distress",
                    "Preceded by URI symptoms",
                    "Most commonly caused by RSV",
                    "Hyperinflation on chest X-ray",
                    "Treatment is supportive"
                ],
                category: "Pediatrics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Kernicterus",
                alternativeNames: ["Bilirubin Encephalopathy"],
                hints: [
                    "Newborn with severe jaundice and neurologic symptoms",
                    "Unconjugated bilirubin >25-30 mg/dL",
                    "Choreoathetosis and hearing loss",
                    "Basal ganglia damage",
                    "Prevented with phototherapy or exchange transfusion"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Erb Palsy",
                alternativeNames: ["Erb-Duchenne Palsy"],
                hints: [
                    "Newborn with arm in waiter's tip position",
                    "Shoulder dystocia during delivery",
                    "C5-C6 nerve root injury",
                    "Loss of shoulder abduction and elbow flexion",
                    "Most recover with physical therapy"
                ],
                category: "Pediatrics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Tracheoesophageal Fistula",
                alternativeNames: ["TEF"],
                hints: [
                    "Newborn with excessive drooling and coughing with feeds",
                    "Unable to pass NG tube",
                    "Air in stomach on X-ray (if distal fistula)",
                    "Associated with VACTERL",
                    "Requires surgical repair"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Hypertrophic Pyloric Stenosis - Late Presentation",
                alternativeNames: ["Pyloric Stenosis"],
                hints: [
                    "6-week-old with projectile vomiting now lethargic",
                    "Severe dehydration and electrolyte abnormalities",
                    "Metabolic alkalosis from chronic vomiting",
                    "Paradoxical aciduria",
                    "Correct electrolytes before surgery"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Congenital Hypothyroidism",
                alternativeNames: ["Cretinism"],
                hints: [
                    "Newborn with prolonged jaundice and umbilical hernia",
                    "Large fontanelles and macroglossia",
                    "Poor feeding and constipation",
                    "Detected on newborn screening",
                    "Requires immediate thyroid replacement"
                ],
                category: "Pediatrics",
                difficulty: 2
            ),
            
            // OPHTHALMOLOGY (2 cases)
            MedicalCase(
                diagnosis: "Central Retinal Artery Occlusion",
                alternativeNames: ["CRAO"],
                hints: [
                    "Patient with sudden painless vision loss",
                    "Cherry-red spot on macula",
                    "Pale retina due to ischemia",
                    "Embolic or thrombotic occlusion",
                    "Medical emergency, poor prognosis"
                ],
                category: "Ophthalmology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Papilledema",
                alternativeNames: ["Optic Disc Swelling"],
                hints: [
                    "Patient with bilateral optic disc swelling",
                    "Loss of venous pulsations",
                    "Sign of elevated intracranial pressure",
                    "Causes include mass, hydrocephalus, idiopathic intracranial HTN",
                    "Vision usually preserved initially"
                ],
                category: "Ophthalmology",
                difficulty: 2
            ),
            
            // PSYCHIATRY (3 cases)
            MedicalCase(
                diagnosis: "Somatization Disorder",
                alternativeNames: ["Somatic Symptom Disorder"],
                hints: [
                    "Patient with multiple unexplained physical symptoms",
                    "Symptoms involve multiple organ systems",
                    "Extensive workup reveals no organic cause",
                    "Significant distress and impairment",
                    "Treated with psychotherapy and reassurance"
                ],
                category: "Psychiatry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Conversion Disorder",
                alternativeNames: ["Functional Neurological Disorder"],
                hints: [
                    "Patient with neurologic symptoms incompatible with medical condition",
                    "Blindness, paralysis, or seizures without organic cause",
                    "Precipitated by psychological stress",
                    "La belle indifférence (lack of concern)",
                    "Symptoms are not intentionally produced"
                ],
                category: "Psychiatry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Tourette Syndrome",
                alternativeNames: ["TS"],
                hints: [
                    "Child with multiple motor and vocal tics",
                    "Onset before age 18",
                    "Coprolalia in minority of cases",
                    "Associated with OCD and ADHD",
                    "Treated with behavioral therapy or antipsychotics"
                ],
                category: "Psychiatry",
                difficulty: 2
            ),
            
            // OBSTETRICS (2 cases)
            MedicalCase(
                diagnosis: "Gestational Trophoblastic Disease",
                alternativeNames: ["Molar Pregnancy", "Hydatidiform Mole"],
                hints: [
                    "Patient with vaginal bleeding and uterus larger than dates",
                    "Markedly elevated β-hCG",
                    "Snowstorm appearance on ultrasound",
                    "Risk of choriocarcinoma",
                    "Treated with dilation and curettage"
                ],
                category: "Obstetrics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Chorioamnionitis",
                alternativeNames: ["Intraamniotic Infection"],
                hints: [
                    "Laboring patient with fever and tachycardia",
                    "Uterine tenderness and foul-smelling amniotic fluid",
                    "Maternal and fetal tachycardia",
                    "Risk factor for neonatal sepsis",
                    "Treated with antibiotics and delivery"
                ],
                category: "Obstetrics",
                difficulty: 2
            ),
            
            // MUSCULOSKELETAL (5 cases)
            MedicalCase(
                diagnosis: "Osgood-Schlatter Disease",
                alternativeNames: [],
                hints: [
                    "Adolescent with anterior knee pain and tibial tubercle tenderness",
                    "Worse with activity and kneeling",
                    "Traction apophysitis from repetitive quadriceps contraction",
                    "Self-limited, resolves with skeletal maturity",
                    "Treated with rest and NSAIDs"
                ],
                category: "Orthopedics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Slipped Capital Femoral Epiphysis",
                alternativeNames: ["SCFE"],
                hints: [
                    "Obese adolescent with hip or knee pain and limp",
                    "Limited internal rotation of hip",
                    "Frog-leg lateral X-ray shows posterior displacement",
                    "Risk of avascular necrosis",
                    "Requires surgical pinning"
                ],
                category: "Orthopedics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Legg-Calvé-Perthes Disease",
                alternativeNames: ["Perthes Disease"],
                hints: [
                    "Young child with insidious onset hip pain and limp",
                    "Avascular necrosis of femoral head",
                    "X-ray shows increased density and fragmentation",
                    "More common in boys age 4-8",
                    "Treated with observation or bracing"
                ],
                category: "Orthopedics",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Developmental Dysplasia of the Hip",
                alternativeNames: ["DDH", "Congenital Hip Dislocation"],
                hints: [
                    "Infant with asymmetric skin folds and limited hip abduction",
                    "Positive Ortolani and Barlow signs",
                    "Risk factors: breech, female, firstborn",
                    "Ultrasound shows shallow acetabulum",
                    "Treated with Pavlik harness"
                ],
                category: "Orthopedics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Compartment Syndrome",
                alternativeNames: ["Acute Compartment Syndrome"],
                hints: [
                    "Patient with severe pain out of proportion after trauma or reperfusion",
                    "Pain with passive stretch",
                    "Paresthesias and pallor (late findings)",
                    "Elevated compartment pressure >30 mmHg",
                    "Surgical emergency requiring fasciotomy"
                ],
                category: "Orthopedics",
                difficulty: 3
            ),
            // BIOCHEMISTRY/GENETICS - AMINO ACID DISORDERS (10 cases)
            MedicalCase(
                diagnosis: "Phenylketonuria",
                alternativeNames: ["PKU"],
                hints: [
                    "Infant with intellectual disability and musty odor",
                    "Fair skin, eczema, and seizures",
                    "Deficiency of phenylalanine hydroxylase",
                    "Elevated phenylalanine, decreased tyrosine",
                    "Treated with phenylalanine-restricted diet"
                ],
                category: "Biochemistry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Maple Syrup Urine Disease",
                alternativeNames: ["MSUD"],
                hints: [
                    "Newborn with sweet-smelling urine and lethargy",
                    "Poor feeding and vomiting",
                    "Deficiency of branched-chain alpha-ketoacid dehydrogenase",
                    "Elevated leucine, isoleucine, valine",
                    "Causes severe neurologic damage if untreated"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Homocystinuria",
                alternativeNames: [],
                hints: [
                    "Child with intellectual disability and lens dislocation (downward)",
                    "Tall with long limbs (marfanoid habitus)",
                    "Deficiency of cystathionine synthase",
                    "Thrombosis and osteoporosis",
                    "Treated with B6, B12, folate, and methionine restriction"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Alkaptonuria",
                alternativeNames: ["Ochronosis"],
                hints: [
                    "Patient with dark urine that turns black on standing",
                    "Dark pigmentation of cartilage and sclera",
                    "Deficiency of homogentisate oxidase",
                    "Arthritis in later life",
                    "Benign condition, no treatment needed"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Cystinuria",
                alternativeNames: [],
                hints: [
                    "Young patient with recurrent kidney stones",
                    "Hexagonal crystals in urine",
                    "Defect in renal tubular reabsorption of cystine",
                    "Also affects ornithine, lysine, arginine (COLA)",
                    "Treated with hydration and urinary alkalinization"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Hartnup Disease",
                alternativeNames: [],
                hints: [
                    "Child with pellagra-like symptoms and cerebellar ataxia",
                    "Defect in neutral amino acid transporter",
                    "Decreased tryptophan absorption",
                    "Niacin deficiency symptoms",
                    "Treated with high-protein diet and niacin"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Albinism",
                alternativeNames: ["Oculocutaneous Albinism"],
                hints: [
                    "Patient with absent pigmentation in skin, hair, and eyes",
                    "Photophobia and nystagmus",
                    "Defect in tyrosinase (inability to make melanin)",
                    "Increased skin cancer risk",
                    "Vision problems from lack of retinal pigment"
                ],
                category: "Biochemistry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Tyrosinemia Type I",
                alternativeNames: [],
                hints: [
                    "Infant with liver failure and cabbage-like odor",
                    "Renal tubular dysfunction (Fanconi syndrome)",
                    "Deficiency of fumarylacetoacetate hydrolase",
                    "Elevated succinylacetone",
                    "High risk of hepatocellular carcinoma"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Methylmalonic Acidemia",
                alternativeNames: ["MMA"],
                hints: [
                    "Infant with poor feeding, vomiting, and lethargy",
                    "Metabolic acidosis and hyperammonemia",
                    "Defect in methylmalonyl-CoA mutase",
                    "Elevated methylmalonic acid",
                    "Treated with B12 supplementation and protein restriction"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Propionic Acidemia",
                alternativeNames: [],
                hints: [
                    "Newborn with vomiting and severe ketoacidosis",
                    "Odd-smelling sweat",
                    "Deficiency of propionyl-CoA carboxylase",
                    "Elevated propionic acid and glycine",
                    "Can cause cardiomyopathy and pancreatitis"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            // BIOCHEMISTRY/GENETICS - CARBOHYDRATE DISORDERS (8 cases)
            MedicalCase(
                diagnosis: "Galactosemia",
                alternativeNames: [],
                hints: [
                    "Newborn with jaundice, vomiting after milk feeds",
                    "Hepatomegaly and cataracts",
                    "Deficiency of galactose-1-phosphate uridyltransferase",
                    "E. coli sepsis in neonates",
                    "Treated with galactose and lactose-free diet"
                ],
                category: "Biochemistry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Hereditary Fructose Intolerance",
                alternativeNames: [],
                hints: [
                    "Infant with hypoglycemia and vomiting after fruit introduction",
                    "Aversion to sweet foods",
                    "Deficiency of aldolase B",
                    "Accumulation of fructose-1-phosphate inhibits gluconeogenesis",
                    "Treated by avoiding fructose and sucrose"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Essential Fructosuria",
                alternativeNames: [],
                hints: [
                    "Asymptomatic patient with fructose in urine",
                    "Deficiency of fructokinase",
                    "Benign condition",
                    "No treatment needed",
                    "Distinguished from hereditary fructose intolerance by being benign"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Von Gierke Disease",
                alternativeNames: ["Glycogen Storage Disease Type I"],
                hints: [
                    "Infant with severe fasting hypoglycemia and hepatomegaly",
                    "Doll-like face and protuberant abdomen",
                    "Deficiency of glucose-6-phosphatase",
                    "Elevated lactate, uric acid, and triglycerides",
                    "Frequent feeding required"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Pompe Disease",
                alternativeNames: ["Glycogen Storage Disease Type II"],
                hints: [
                    "Infant with cardiomegaly and hypotonia",
                    "Exercise intolerance and muscle weakness",
                    "Deficiency of acid maltase (alpha-1,4-glucosidase)",
                    "Glycogen accumulation in lysosomes",
                    "Fatal in infantile form without enzyme replacement"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Cori Disease",
                alternativeNames: ["Glycogen Storage Disease Type III"],
                hints: [
                    "Child with hepatomegaly and fasting hypoglycemia",
                    "Milder than Von Gierke disease",
                    "Deficiency of debranching enzyme",
                    "Normal lactate levels (unlike Von Gierke)",
                    "Better prognosis than Type I"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "McArdle Disease",
                alternativeNames: ["Glycogen Storage Disease Type V"],
                hints: [
                    "Young adult with muscle cramps and myoglobinuria with exercise",
                    "Second wind phenomenon (improvement with continued exercise)",
                    "Deficiency of muscle phosphorylase",
                    "Flat venous lactate curve during exercise",
                    "Increased CK at rest"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Lactase Deficiency",
                alternativeNames: ["Lactose Intolerance"],
                hints: [
                    "Patient with bloating and diarrhea after dairy consumption",
                    "Osmotic diarrhea from undigested lactose",
                    "Most common in African, Asian, Native American populations",
                    "Positive hydrogen breath test",
                    "Treated with lactose avoidance or lactase supplements"
                ],
                category: "Biochemistry",
                difficulty: 2
            ),
            
            // BIOCHEMISTRY/GENETICS - LIPID DISORDERS (8 cases)
            MedicalCase(
                diagnosis: "Familial Hypercholesterolemia",
                alternativeNames: ["FH"],
                hints: [
                    "Young patient with xanthomas and early MI",
                    "Corneal arcus before age 45",
                    "Defective or absent LDL receptors",
                    "LDL cholesterol >190 mg/dL",
                    "Autosomal dominant, heterozygotes common"
                ],
                category: "Biochemistry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Familial Dysbetalipoproteinemia",
                alternativeNames: ["Type III Hyperlipoproteinemia"],
                hints: [
                    "Patient with palmar xanthomas and tuberoeruptive xanthomas",
                    "Elevated cholesterol and triglycerides",
                    "ApoE2/E2 genotype",
                    "Premature atherosclerosis",
                    "Treated with fibrates"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Tangier Disease",
                alternativeNames: [],
                hints: [
                    "Patient with orange tonsils and hepatosplenomegaly",
                    "Very low or absent HDL",
                    "Defective ABCA1 transporter",
                    "Peripheral neuropathy",
                    "Cholesterol accumulation in macrophages"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Gaucher Disease",
                alternativeNames: [],
                hints: [
                    "Patient with hepatosplenomegaly and bone pain",
                    "Gaucher cells (wrinkled paper appearance)",
                    "Deficiency of glucocerebrosidase",
                    "Most common lysosomal storage disease",
                    "Treated with enzyme replacement therapy"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Niemann-Pick Disease",
                alternativeNames: [],
                hints: [
                    "Infant with hepatosplenomegaly and cherry-red spot",
                    "Progressive neurodegeneration",
                    "Deficiency of sphingomyelinase",
                    "Foam cells (lipid-laden macrophages)",
                    "Type A most severe, fatal in childhood"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Tay-Sachs Disease",
                alternativeNames: [],
                hints: [
                    "Ashkenazi Jewish infant with developmental regression",
                    "Cherry-red spot on macula",
                    "Deficiency of hexosaminidase A",
                    "GM2 ganglioside accumulation",
                    "Fatal by age 4-5"
                ],
                category: "Biochemistry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Fabry Disease",
                alternativeNames: [],
                hints: [
                    "Male with angiokeratomas and acroparesthesias",
                    "Renal failure and cardiac disease",
                    "Deficiency of alpha-galactosidase A",
                    "X-linked recessive",
                    "Treated with enzyme replacement"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Krabbe Disease",
                alternativeNames: ["Globoid Cell Leukodystrophy"],
                hints: [
                    "Infant with developmental delay and peripheral neuropathy",
                    "Optic atrophy and demyelination",
                    "Deficiency of galactocerebrosidase",
                    "Globoid cells in white matter",
                    "Progressive and fatal"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            // BIOCHEMISTRY/GENETICS - PURINE/PYRIMIDINE DISORDERS (4 cases)
            MedicalCase(
                diagnosis: "Lesch-Nyhan Syndrome",
                alternativeNames: [],
                hints: [
                    "Boy with self-mutilation and intellectual disability",
                    "Dystonia and gouty arthritis",
                    "Deficiency of HGPRT",
                    "Elevated uric acid",
                    "Orange crystal diaper in infancy"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Orotic Aciduria",
                alternativeNames: [],
                hints: [
                    "Child with megaloblastic anemia that doesn't respond to B12/folate",
                    "Growth retardation",
                    "Deficiency of UMP synthase",
                    "Elevated orotic acid in urine",
                    "Treated with oral uridine"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Adenosine Deaminase Deficiency",
                alternativeNames: ["ADA Deficiency"],
                hints: [
                    "Infant with recurrent severe infections",
                    "Toxic accumulation of dATP inhibits ribonucleotide reductase",
                    "T and B cell deficiency (SCID)",
                    "Absence of thymic shadow",
                    "First gene therapy success"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Xeroderma Pigmentosum",
                alternativeNames: ["XP"],
                hints: [
                    "Child with severe sunburn and freckling in infancy",
                    "Multiple skin cancers at young age",
                    "Defect in nucleotide excision repair",
                    "Unable to repair UV-induced thymine dimers",
                    "Must avoid all sun exposure"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            // BIOCHEMISTRY/GENETICS - MITOCHONDRIAL/OTHER (5 cases)
            MedicalCase(
                diagnosis: "MELAS Syndrome",
                alternativeNames: ["Mitochondrial Encephalomyopathy"],
                hints: [
                    "Patient with stroke-like episodes and lactic acidosis",
                    "Seizures and dementia",
                    "Mitochondrial DNA mutation",
                    "Maternal inheritance",
                    "Ragged red fibers on muscle biopsy"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Kartagener Syndrome Ciliary Defect",
                alternativeNames: ["Primary Ciliary Dyskinesia"],
                hints: [
                    "Patient with chronic sinusitis and bronchiectasis",
                    "Situs inversus and male infertility",
                    "Dynein arm defect",
                    "Immotile cilia and sperm",
                    "Autosomal recessive"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Chediak-Higashi Syndrome",
                alternativeNames: [],
                hints: [
                    "Child with recurrent pyogenic infections and albinism",
                    "Progressive neurologic dysfunction",
                    "Giant granules in neutrophils and lysosomes",
                    "Defect in lysosomal trafficking regulator",
                    "Increased risk of lymphoma"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Menkes Disease",
                alternativeNames: ["Kinky Hair Disease"],
                hints: [
                    "Infant with kinky hair and hypotonia",
                    "Seizures and developmental delay",
                    "Defect in ATP7A copper transporter",
                    "Low serum copper and ceruloplasmin",
                    "X-linked, fatal in early childhood"
                ],
                category: "Biochemistry",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Mucopolysaccharidosis Type I",
                alternativeNames: ["Hurler Syndrome"],
                hints: [
                    "Child with coarse facial features and corneal clouding",
                    "Hepatosplenomegaly and developmental delay",
                    "Deficiency of alpha-L-iduronidase",
                    "Dermatan and heparan sulfate accumulation",
                    "Gargoyle-like appearance"
                ],
                category: "Biochemistry",
                difficulty: 3
            ),
            
            // IMMUNODEFICIENCIES (12 cases)
            MedicalCase(
                diagnosis: "Severe Combined Immunodeficiency",
                alternativeNames: ["SCID", "Bubble Boy Disease"],
                hints: [
                    "Infant with severe recurrent infections by 3 months",
                    "Absent T and B cells",
                    "Absent thymic shadow on chest X-ray",
                    "Fatal without bone marrow transplant",
                    "Multiple genetic causes (IL-2R, ADA deficiency)"
                ],
                category: "Immunology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "X-Linked Agammaglobulinemia",
                alternativeNames: ["Bruton Agammaglobulinemia"],
                hints: [
                    "Boy with recurrent sinopulmonary infections after 6 months",
                    "Absent or low B cells, absent immunoglobulins",
                    "Defect in BTK tyrosine kinase",
                    "Absent tonsils and lymph nodes",
                    "Treated with IVIG replacement"
                ],
                category: "Immunology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Common Variable Immunodeficiency",
                alternativeNames: ["CVID"],
                hints: [
                    "Adult with recurrent sinopulmonary infections",
                    "Low IgG, IgA, and/or IgM",
                    "Normal or low B cell count with poor function",
                    "Increased risk of autoimmune disease and lymphoma",
                    "Treated with IVIG"
                ],
                category: "Immunology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Selective IgA Deficiency",
                alternativeNames: [],
                hints: [
                    "Patient with recurrent sinopulmonary and GI infections",
                    "Most common primary immunodeficiency",
                    "IgA <7 mg/dL with normal IgG and IgM",
                    "Often asymptomatic",
                    "Anaphylaxis risk with blood transfusions"
                ],
                category: "Immunology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Hyper-IgM Syndrome",
                alternativeNames: [],
                hints: [
                    "Boy with recurrent sinopulmonary infections",
                    "Elevated IgM, low IgG, IgA, IgE",
                    "Defect in CD40L (X-linked form)",
                    "Cannot class switch from IgM",
                    "Opportunistic infections including Pneumocystis"
                ],
                category: "Immunology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Chronic Granulomatous Disease",
                alternativeNames: ["CGD"],
                hints: [
                    "Child with recurrent catalase-positive organism infections",
                    "Staph aureus, Aspergillus, Burkholderia, Serratia, Nocardia",
                    "Defect in NADPH oxidase",
                    "Negative nitroblue tetrazolium test",
                    "Granulomas in multiple organs"
                ],
                category: "Immunology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Leukocyte Adhesion Deficiency",
                alternativeNames: ["LAD"],
                hints: [
                    "Infant with delayed umbilical cord separation",
                    "Recurrent bacterial infections without pus",
                    "Defect in CD18 (integrin)",
                    "Neutrophils cannot adhere to endothelium",
                    "Severe periodontitis"
                ],
                category: "Immunology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Job Syndrome",
                alternativeNames: ["Hyper-IgE Syndrome"],
                hints: [
                    "Patient with cold (non-inflamed) abscesses",
                    "Eczema and retained primary teeth",
                    "Very high IgE levels (>2000)",
                    "Recurrent Staph aureus infections",
                    "Coarse facial features"
                ],
                category: "Immunology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Ataxia-Telangiectasia",
                alternativeNames: [],
                hints: [
                    "Child with progressive cerebellar ataxia",
                    "Telangiectasias on conjunctiva and skin",
                    "Defect in ATM gene (DNA repair)",
                    "Low IgA, IgG, and IgE",
                    "Increased risk of lymphoma and leukemia"
                ],
                category: "Immunology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Complement C5-C9 Deficiency",
                alternativeNames: ["Terminal Complement Deficiency"],
                hints: [
                    "Patient with recurrent Neisseria infections",
                    "Deficiency in membrane attack complex",
                    "Meningococcal meningitis risk",
                    "CH50 low or absent",
                    "Vaccinate against encapsulated organisms"
                ],
                category: "Immunology",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Hereditary Angioedema",
                alternativeNames: ["C1 Esterase Inhibitor Deficiency"],
                hints: [
                    "Patient with recurrent episodes of angioedema without urticaria",
                    "Abdominal pain from bowel wall edema",
                    "Low C4 levels",
                    "Airway compromise risk",
                    "Treated with C1 inhibitor concentrate or bradykinin antagonist"
                ],
                category: "Immunology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "IL-12 Receptor Deficiency",
                alternativeNames: [],
                hints: [
                    "Patient with disseminated mycobacterial infections",
                    "Poor Th1 response",
                    "Cannot form granulomas",
                    "Susceptible to atypical mycobacteria and Salmonella",
                    "Low IFN-gamma production"
                ],
                category: "Immunology",
                difficulty: 4
            ),
            
            // INFECTIOUS DISEASE - STIs (10 cases)
            MedicalCase(
                diagnosis: "Primary Syphilis",
                alternativeNames: ["Syphilis Stage 1"],
                hints: [
                    "Patient with painless chancre on genitals",
                    "Firm, indurated ulcer with clean base",
                    "Resolves spontaneously in 3-6 weeks",
                    "Treponema pallidum on dark-field microscopy",
                    "Treated with benzathine penicillin G"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Secondary Syphilis",
                alternativeNames: ["Syphilis Stage 2"],
                hints: [
                    "Patient with diffuse maculopapular rash including palms and soles",
                    "Condylomata lata (flat wart-like lesions)",
                    "Patchy alopecia and mucous patches",
                    "Constitutional symptoms and lymphadenopathy",
                    "Highly contagious"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Tertiary Syphilis",
                alternativeNames: ["Syphilis Stage 3"],
                hints: [
                    "Patient with aortitis and aortic regurgitation",
                    "Gummas (granulomatous lesions)",
                    "Tabes dorsalis (posterior column damage)",
                    "Argyll Robertson pupil (accommodates but doesn't react)",
                    "Occurs years after initial infection"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Gonorrhea",
                alternativeNames: ["Neisseria Gonorrhoeae"],
                hints: [
                    "Male with purulent urethral discharge and dysuria",
                    "Gram-negative intracellular diplococci",
                    "Can cause disseminated infection with arthritis and tenosynovitis",
                    "Fitz-Hugh-Curtis syndrome (perihepatitis) in women",
                    "Treated with ceftriaxone plus azithromycin"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Chlamydia Trachomatis",
                alternativeNames: ["Chlamydia"],
                hints: [
                    "Most common bacterial STI in US",
                    "Often asymptomatic or mild symptoms",
                    "Can cause PID, ectopic pregnancy, infertility",
                    "Lymphogranuloma venereum (L serovars)",
                    "Treated with azithromycin or doxycycline"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Chancroid",
                alternativeNames: ["Haemophilus Ducreyi"],
                hints: [
                    "Patient with painful genital ulcer with ragged edges",
                    "School of fish appearance on Gram stain",
                    "Painful inguinal lymphadenopathy (buboes)",
                    "Rare in US, more common in developing countries",
                    "Treated with azithromycin or ceftriaxone"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Lymphogranuloma Venereum",
                alternativeNames: ["LGV"],
                hints: [
                    "Patient with painless genital ulcer followed by painful inguinal lymphadenopathy",
                    "Groove sign (lymph nodes above and below inguinal ligament)",
                    "Caused by Chlamydia trachomatis L1, L2, L3",
                    "Can cause proctocolitis in MSM",
                    "Treated with doxycycline for 3 weeks"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Granuloma Inguinale",
                alternativeNames: ["Donovanosis"],
                hints: [
                    "Patient with painless, beefy red ulcer that bleeds easily",
                    "Donovan bodies (bipolar staining) on biopsy",
                    "Caused by Klebsiella granulomatis",
                    "Rare, seen in tropical regions",
                    "Treated with azithromycin or doxycycline"
                ],
                category: "Infectious Disease",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Genital Herpes",
                alternativeNames: ["HSV-2"],
                hints: [
                    "Patient with painful grouped vesicles on erythematous base",
                    "Recurrent outbreaks with prodrome of tingling",
                    "Tzanck smear shows multinucleated giant cells",
                    "Can cause aseptic meningitis",
                    "Treated with acyclovir or valacyclovir"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Human Papillomavirus",
                alternativeNames: ["HPV", "Genital Warts"],
                hints: [
                    "Patient with cauliflower-like lesions on genitals",
                    "Types 6 and 11 cause condyloma acuminata",
                    "Types 16 and 18 cause cervical cancer",
                    "Koilocytes on Pap smear",
                    "Treated with cryotherapy, imiquimod, or podophyllin"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            // INFECTIOUS DISEASE - HEPATITIS (8 cases)
            MedicalCase(
                diagnosis: "Hepatitis A",
                alternativeNames: ["HAV"],
                hints: [
                    "Patient with jaundice after travel or contaminated food",
                    "Fecal-oral transmission",
                    "Self-limited, no chronic infection",
                    "IgM anti-HAV positive in acute infection",
                    "Prevented by vaccine"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Hepatitis B - Acute",
                alternativeNames: ["HBV"],
                hints: [
                    "Patient with jaundice and elevated transaminases",
                    "HBsAg and anti-HBc IgM positive",
                    "Transmitted through blood and sexual contact",
                    "Most adults clear infection spontaneously",
                    "Window period: anti-HBc IgM only marker"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Hepatitis B - Chronic",
                alternativeNames: ["Chronic HBV"],
                hints: [
                    "Patient with persistent HBsAg >6 months",
                    "Risk of cirrhosis and hepatocellular carcinoma",
                    "HBeAg positive indicates high infectivity",
                    "90% of neonates become chronic carriers",
                    "Treated with tenofovir or entecavir"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Hepatitis C",
                alternativeNames: ["HCV"],
                hints: [
                    "Patient with asymptomatic elevated transaminases",
                    "Most common chronic bloodborne infection in US",
                    "80% develop chronic infection",
                    "Leading indication for liver transplant",
                    "Cured with direct-acting antivirals"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Hepatitis D",
                alternativeNames: ["HDV", "Delta Hepatitis"],
                hints: [
                    "HBV patient with acute worsening of hepatitis",
                    "Requires HBV for replication (defective virus)",
                    "Coinfection or superinfection patterns",
                    "Increases risk of fulminant hepatitis",
                    "Prevented by HBV vaccination"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Hepatitis E",
                alternativeNames: ["HEV"],
                hints: [
                    "Pregnant woman with acute hepatitis after travel",
                    "Fecal-oral transmission",
                    "Self-limited except in pregnancy",
                    "High mortality in pregnant women (20%)",
                    "Endemic in developing countries"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Fulminant Hepatic Failure",
                alternativeNames: ["Acute Liver Failure"],
                hints: [
                    "Patient with jaundice, encephalopathy, and coagulopathy",
                    "Occurs within 8 weeks of initial liver injury",
                    "Causes: acetaminophen, viral hepatitis, Wilson disease",
                    "Elevated ammonia and prolonged PT/INR",
                    "Requires urgent liver transplant evaluation"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Autoimmune Hepatitis",
                alternativeNames: [],
                hints: [
                    "Young woman with elevated transaminases and hypergammaglobulinemia",
                    "Type 1: ANA and anti-smooth muscle antibodies",
                    "Type 2: anti-LKM1 antibodies",
                    "Interface hepatitis on biopsy",
                    "Treated with corticosteroids and azathioprine"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            // TOXICOLOGY (15 cases)
            MedicalCase(
                diagnosis: "Acetaminophen Toxicity",
                alternativeNames: ["Tylenol Overdose"],
                hints: [
                    "Patient with nausea and vomiting 24 hours post-ingestion",
                    "Elevated transaminases at 24-72 hours",
                    "Acute liver failure risk",
                    "Rumack-Matthew nomogram guides treatment",
                    "Treated with N-acetylcysteine"
                ],
                category: "Toxicology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Salicylate Toxicity",
                alternativeNames: ["Aspirin Overdose"],
                hints: [
                    "Patient with tinnitus, hyperventilation, and altered mental status",
                    "Mixed respiratory alkalosis and metabolic acidosis",
                    "Hyperthermia and hypoglycemia",
                    "Treated with sodium bicarbonate and hemodialysis",
                    "Ferric chloride test turns urine purple"
                ],
                category: "Toxicology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Opioid Overdose",
                alternativeNames: ["Heroin Overdose"],
                hints: [
                    "Unresponsive patient with respiratory depression",
                    "Pinpoint pupils (miosis)",
                    "Decreased bowel sounds",
                    "Treated with naloxone (Narcan)",
                    "Pulmonary edema can occur"
                ],
                category: "Toxicology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Benzodiazepine Overdose",
                alternativeNames: [],
                hints: [
                    "Patient with sedation and respiratory depression",
                    "Ataxia and slurred speech",
                    "Synergistic effect with alcohol",
                    "Treated with flumazenil (caution: seizure risk)",
                    "Generally supportive care"
                ],
                category: "Toxicology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Tricyclic Antidepressant Toxicity",
                alternativeNames: ["TCA Overdose"],
                hints: [
                    "Patient with anticholinergic symptoms and cardiac arrhythmias",
                    "Wide QRS complex and prolonged QT",
                    "Seizures and hypotension",
                    "Treated with sodium bicarbonate",
                    "3 C's: Convulsions, Coma, Cardiotoxicity"
                ],
                category: "Toxicology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Organophosphate Poisoning",
                alternativeNames: ["Insecticide Toxicity"],
                hints: [
                    "Farmer with excessive salivation, lacrimation, urination",
                    "SLUDGE: Salivation, Lacrimation, Urination, Defecation, GI upset, Emesis",
                    "Miosis and bronchospasm",
                    "Inhibits acetylcholinesterase",
                    "Treated with atropine and pralidoxime"
                ],
                category: "Toxicology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Carbon Monoxide Poisoning",
                alternativeNames: ["CO Poisoning"],
                hints: [
                    "Patient with headache and cherry-red skin",
                    "Exposure to smoke, car exhaust, or faulty heater",
                    "Carboxyhemoglobin levels elevated",
                    "Pulse oximetry falsely normal",
                    "Treated with 100% oxygen or hyperbaric oxygen"
                ],
                category: "Toxicology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Cyanide Poisoning",
                alternativeNames: [],
                hints: [
                    "Patient with altered mental status and bitter almond breath",
                    "Severe lactic acidosis",
                    "Inhibits cytochrome c oxidase",
                    "Exposure to smoke, nitroprusside, or cassava",
                    "Treated with hydroxocobalamin or sodium thiosulfate"
                ],
                category: "Toxicology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Methanol Toxicity",
                alternativeNames: [],
                hints: [
                    "Patient with vision changes (snowstorm vision) and abdominal pain",
                    "Metabolized to formic acid causing optic neuritis",
                    "Elevated anion gap metabolic acidosis",
                    "Exposure from moonshine or antifreeze",
                    "Treated with fomepizole and hemodialysis"
                ],
                category: "Toxicology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Ethylene Glycol Toxicity",
                alternativeNames: ["Antifreeze Poisoning"],
                hints: [
                    "Patient with altered mental status and flank pain",
                    "Metabolized to oxalic acid causing calcium oxalate crystals",
                    "Envelope-shaped crystals in urine",
                    "Acute kidney injury",
                    "Treated with fomepizole and hemodialysis"
                ],
                category: "Toxicology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Lead Poisoning",
                alternativeNames: ["Plumbism"],
                hints: [
                    "Child with developmental delay and abdominal pain",
                    "Microcytic anemia with basophilic stippling",
                    "Lead lines on X-ray and gingiva",
                    "Wrist drop and foot drop (peripheral neuropathy)",
                    "Treated with EDTA or succimer"
                ],
                category: "Toxicology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Mercury Poisoning",
                alternativeNames: [],
                hints: [
                    "Patient with tremor, gingivitis, and erethism",
                    "Mad hatter syndrome (neuropsychiatric changes)",
                    "Acrodynia (pink disease) in children",
                    "Acute exposure causes GI and renal toxicity",
                    "Treated with dimercaprol or succimer"
                ],
                category: "Toxicology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Arsenic Poisoning",
                alternativeNames: [],
                hints: [
                    "Patient with garlic breath and painful neuropathy",
                    "GI symptoms: rice water stools",
                    "Mees lines (transverse white lines on nails)",
                    "QT prolongation and torsades de pointes",
                    "Treated with dimercaprol"
                ],
                category: "Toxicology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Iron Toxicity",
                alternativeNames: ["Iron Overdose"],
                hints: [
                    "Child with bloody diarrhea and shock after ingesting pills",
                    "Five stages: GI, latent, shock, hepatotoxicity, scarring",
                    "Radiopaque pills on X-ray",
                    "High anion gap metabolic acidosis",
                    "Treated with deferoxamine"
                ],
                category: "Toxicology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Isoniazid Toxicity",
                alternativeNames: ["INH Overdose"],
                hints: [
                    "TB patient with refractory seizures",
                    "Depletes pyridoxine (B6)",
                    "Elevated anion gap metabolic acidosis",
                    "Seizures, coma, and lactic acidosis",
                    "Treated with pyridoxine (vitamin B6)"
                ],
                category: "Toxicology",
                difficulty: 3
            ),
            
            // VITAMIN/MINERAL DEFICIENCIES (15 cases)
            MedicalCase(
                diagnosis: "Vitamin A Deficiency",
                alternativeNames: ["Retinol Deficiency"],
                hints: [
                    "Child with night blindness and dry eyes",
                    "Bitot spots (foamy patches on conjunctiva)",
                    "Xerophthalmia and keratomalacia",
                    "Leading cause of preventable blindness worldwide",
                    "Follicular hyperkeratosis"
                ],
                category: "Nutrition",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Vitamin B1 Deficiency",
                alternativeNames: ["Thiamine Deficiency", "Beriberi"],
                hints: [
                    "Patient with peripheral neuropathy and heart failure",
                    "Wet beriberi: high-output heart failure",
                    "Dry beriberi: peripheral neuropathy",
                    "Common in alcoholics",
                    "Wernicke-Korsakoff if CNS involvement"
                ],
                category: "Nutrition",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Vitamin B2 Deficiency",
                alternativeNames: ["Riboflavin Deficiency"],
                hints: [
                    "Patient with angular cheilitis and glossitis",
                    "Magenta tongue",
                    "Seborrheic dermatitis",
                    "Corneal vascularization",
                    "Rare in developed countries"
                ],
                category: "Nutrition",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Vitamin B3 Deficiency",
                alternativeNames: ["Niacin Deficiency", "Pellagra"],
                hints: [
                    "Patient with 3 D's: Diarrhea, Dermatitis, Dementia",
                    "Casal necklace (hyperpigmented rash on neck)",
                    "Broad collar distribution of rash",
                    "Associated with carcinoid syndrome and Hartnup disease",
                    "Can lead to death if untreated"
                ],
                category: "Nutrition",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Vitamin B5 Deficiency",
                alternativeNames: ["Pantothenic Acid Deficiency"],
                hints: [
                    "Patient with burning feet syndrome",
                    "Adrenal insufficiency symptoms",
                    "Extremely rare",
                    "Dermatitis and enteritis",
                    "Part of CoA and fatty acid synthase"
                ],
                category: "Nutrition",
                difficulty: 4
            ),
            
            MedicalCase(
                diagnosis: "Vitamin B6 Deficiency",
                alternativeNames: ["Pyridoxine Deficiency"],
                hints: [
                    "Patient with peripheral neuropathy and seizures",
                    "Sideroblastic anemia",
                    "Caused by isoniazid use",
                    "Seborrheic dermatitis and glossitis",
                    "Supplemented with INH therapy"
                ],
                category: "Nutrition",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Vitamin B7 Deficiency",
                alternativeNames: ["Biotin Deficiency"],
                hints: [
                    "Patient with alopecia and dermatitis",
                    "Caused by eating raw egg whites (avidin)",
                    "Lactic acidosis and organic aciduria",
                    "Neurologic symptoms",
                    "Rare except in specific conditions"
                ],
                category: "Nutrition",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Vitamin B9 Deficiency",
                alternativeNames: ["Folate Deficiency"],
                hints: [
                    "Patient with macrocytic anemia",
                    "Hypersegmented neutrophils",
                    "Glossitis but no neurologic symptoms",
                    "Causes neural tube defects in pregnancy",
                    "Seen in alcoholics and pregnancy"
                ],
                category: "Nutrition",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Vitamin C Deficiency",
                alternativeNames: ["Scurvy"],
                hints: [
                    "Patient with poor wound healing and bleeding gums",
                    "Perifollicular hemorrhages",
                    "Corkscrew hairs",
                    "Swollen, bleeding gums",
                    "Required for collagen synthesis (hydroxylation)"
                ],
                category: "Nutrition",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Vitamin D Deficiency",
                alternativeNames: ["Rickets", "Osteomalacia"],
                hints: [
                    "Child with bowed legs and rachitic rosary",
                    "Hypocalcemia and elevated alkaline phosphatase",
                    "Craniotabes (soft skull)",
                    "Adults: osteomalacia with bone pain",
                    "Treated with vitamin D supplementation"
                ],
                category: "Nutrition",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Vitamin E Deficiency",
                alternativeNames: ["Tocopherol Deficiency"],
                hints: [
                    "Patient with hemolytic anemia and peripheral neuropathy",
                    "Posterior column and spinocerebellar tract degeneration",
                    "Acanthocytosis",
                    "Seen in fat malabsorption syndromes",
                    "Antioxidant, protects RBC membranes"
                ],
                category: "Nutrition",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Vitamin K Deficiency",
                alternativeNames: [],
                hints: [
                    "Newborn with bleeding or patient with elevated PT/INR",
                    "Easy bruising and GI bleeding",
                    "Seen in newborns, malabsorption, or antibiotic use",
                    "Required for factors II, VII, IX, X",
                    "Treated with vitamin K (phytonadione)"
                ],
                category: "Nutrition",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Zinc Deficiency",
                alternativeNames: [],
                hints: [
                    "Patient with delayed wound healing and hypogeusia",
                    "Acrodermatitis enteropathica (periorificial dermatitis)",
                    "Alopecia and diarrhea",
                    "Impaired immune function",
                    "Seen in TPN, malabsorption, or acrodermatitis enteropathica"
                ],
                category: "Nutrition",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Copper Deficiency",
                alternativeNames: [],
                hints: [
                    "Patient with anemia and neutropenia",
                    "Sideroblastic anemia (looks like iron deficiency)",
                    "Myelopathy and neuropathy",
                    "Seen in gastric bypass or excessive zinc",
                    "Required for ceruloplasmin and cytochrome c oxidase"
                ],
                category: "Nutrition",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Selenium Deficiency",
                alternativeNames: ["Keshan Disease"],
                hints: [
                    "Patient with cardiomyopathy and muscle pain",
                    "Keshan disease (endemic cardiomyopathy in China)",
                    "Kashin-Beck disease (osteoarthropathy)",
                    "Part of glutathione peroxidase",
                    "Rare in US except in TPN"
                ],
                category: "Nutrition",
                difficulty: 4
            ),
            // PARASITOLOGY (15 cases)
            MedicalCase(
                diagnosis: "Giardiasis",
                alternativeNames: ["Giardia Lamblia"],
                hints: [
                    "Hiker with foul-smelling, greasy diarrhea after drinking stream water",
                    "Bloating and flatulence",
                    "Trophozoites with falling leaf motility",
                    "Pear-shaped flagellated protozoa",
                    "Treated with metronidazole or tinidazole"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Cryptosporidiosis",
                alternativeNames: ["Cryptosporidium"],
                hints: [
                    "HIV patient with severe watery diarrhea",
                    "Acid-fast oocysts in stool",
                    "Resistant to chlorination",
                    "Self-limited in immunocompetent",
                    "No effective treatment in AIDS patients"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Amebiasis",
                alternativeNames: ["Entamoeba Histolytica"],
                hints: [
                    "Traveler with bloody diarrhea and RUQ pain",
                    "Flask-shaped ulcers in colon",
                    "Trophozoites with ingested RBCs",
                    "Can cause liver abscess (anchovy paste pus)",
                    "Treated with metronidazole plus paromomycin"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Trichomoniasis",
                alternativeNames: ["Trichomonas Vaginalis"],
                hints: [
                    "Woman with frothy, yellow-green vaginal discharge",
                    "Strawberry cervix on exam",
                    "Motile flagellated protozoa on wet mount",
                    "Fishy odor",
                    "Treated with metronidazole (treat partner)"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Pinworm Infection",
                alternativeNames: ["Enterobiasis", "Enterobius Vermicularis"],
                hints: [
                    "Child with perianal itching, worse at night",
                    "Scotch tape test shows eggs",
                    "Female worm migrates to perianal area at night",
                    "Most common helminth in US",
                    "Treated with albendazole or pyrantel pamoate"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Ascariasis",
                alternativeNames: ["Ascaris Lumbricoides"],
                hints: [
                    "Child with abdominal pain and intestinal obstruction",
                    "Loeffler syndrome (pulmonary eosinophilia)",
                    "Large roundworm visible in stool or vomitus",
                    "Can migrate to bile duct causing obstruction",
                    "Treated with albendazole or mebendazole"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Hookworm Infection",
                alternativeNames: ["Ancylostoma", "Necator"],
                hints: [
                    "Patient with iron deficiency anemia and abdominal pain",
                    "Ground itch at site of skin penetration",
                    "Larvae migrate through lungs causing cough",
                    "Adult worms attach to intestinal mucosa",
                    "Treated with albendazole or mebendazole"
                ],
                category: "Infectious Disease",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Neurocysticercosis",
                alternativeNames: ["Taenia Solium", "Cysticercosis"],
                hints: [
                    "Patient with new-onset seizures and multiple brain cysts",
                    "Pork tapeworm larval infection",
                    "CT shows calcified cysts with scolex (swiss cheese brain)",
                    "Most common parasitic CNS infection worldwide",
                    "Treated with albendazole plus steroids"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Schistosomiasis",
                alternativeNames: ["Bilharzia"],
                hints: [
                    "Traveler with hematuria after swimming in African lake",
                    "Swimmer's itch after cercariae penetration",
                    "Eggs with terminal spine (S. haematobium) in urine",
                    "Can cause portal hypertension and bladder cancer",
                    "Treated with praziquantel"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Leishmaniasis - Visceral",
                alternativeNames: ["Kala-azar"],
                hints: [
                    "Patient with fever, hepatosplenomegaly, and pancytopenia",
                    "Gray-brown skin pigmentation (kala-azar means black fever)",
                    "Sandfly vector transmission",
                    "Amastigotes within macrophages",
                    "Treated with liposomal amphotericin B"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Cutaneous Leishmaniasis",
                alternativeNames: [],
                hints: [
                    "Traveler with painless skin ulcer at sandfly bite site",
                    "Ulcer with raised borders",
                    "Amastigotes in macrophages on biopsy",
                    "Self-healing but leaves scar",
                    "Treated with pentavalent antimony compounds"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Chagas Disease",
                alternativeNames: ["American Trypanosomiasis"],
                hints: [
                    "Patient from South America with dilated cardiomyopathy",
                    "Romana sign (unilateral periorbital edema) in acute phase",
                    "Megacolon and megaesophagus in chronic phase",
                    "Trypomastigotes in blood, reduviid bug vector",
                    "Treated with benznidazole in acute phase"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "African Sleeping Sickness",
                alternativeNames: ["African Trypanosomiasis"],
                hints: [
                    "African traveler with somnolence and neurologic symptoms",
                    "Painful chancre at tsetse fly bite site",
                    "Posterior cervical lymphadenopathy (Winterbottom sign)",
                    "Trypomastigotes in blood or CSF",
                    "Treated with suramin (early) or melarsoprol (CNS)"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Strongyloidiasis",
                alternativeNames: ["Strongyloides Stercoralis"],
                hints: [
                    "Immunosuppressed patient with severe diarrhea and sepsis",
                    "Hyperinfection syndrome in immunocompromised",
                    "Larva currens (rapidly migrating urticarial rash)",
                    "Rhabditiform larvae in stool",
                    "Treated with ivermectin"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Trichinellosis",
                alternativeNames: ["Trichinella Spiralis"],
                hints: [
                    "Patient with periorbital edema after eating undercooked pork",
                    "Muscle pain, fever, and eosinophilia",
                    "Larvae encyst in muscle",
                    "Splinter hemorrhages under nails",
                    "Treated with albendazole plus steroids"
                ],
                category: "Infectious Disease",
                difficulty: 3
            ),
            
            // GENETIC SYNDROMES (10 cases)
            MedicalCase(
                diagnosis: "Fragile X Syndrome",
                alternativeNames: [],
                hints: [
                    "Boy with intellectual disability and large testicles (macroorchidism)",
                    "Long face with prominent jaw and ears",
                    "Autism spectrum features",
                    "CGG repeat expansion in FMR1 gene",
                    "Most common inherited cause of intellectual disability"
                ],
                category: "Genetics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Prader-Willi Syndrome",
                alternativeNames: [],
                hints: [
                    "Child with hyperphagia and obesity",
                    "Hypotonia in infancy",
                    "Hypogonadism and intellectual disability",
                    "Deletion of paternal chromosome 15q11-13",
                    "Almond-shaped eyes"
                ],
                category: "Genetics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Angelman Syndrome",
                alternativeNames: ["Happy Puppet Syndrome"],
                hints: [
                    "Child with inappropriate laughter and ataxic gait",
                    "Severe intellectual disability",
                    "Hand-flapping movements",
                    "Deletion of maternal chromosome 15q11-13",
                    "Same region as Prader-Willi but maternal origin"
                ],
                category: "Genetics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Achondroplasia",
                alternativeNames: [],
                hints: [
                    "Child with short stature and disproportionately short limbs",
                    "Frontal bossing and midface hypoplasia",
                    "Trident hand configuration",
                    "FGFR3 gain-of-function mutation",
                    "Most common skeletal dysplasia"
                ],
                category: "Genetics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Marfan Syndrome",
                alternativeNames: [],
                hints: [
                    "Tall patient with long limbs and arachnodactyly",
                    "Lens dislocation (upward, ectopia lentis)",
                    "Aortic root dilatation and mitral valve prolapse",
                    "Fibrillin-1 mutation",
                    "Positive thumb and wrist signs"
                ],
                category: "Genetics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Ehlers-Danlos Syndrome",
                alternativeNames: ["EDS"],
                hints: [
                    "Patient with hyperextensible skin and hypermobile joints",
                    "Easy bruising and poor wound healing",
                    "Cigarette paper scars",
                    "Defect in collagen synthesis or structure",
                    "Vascular type can cause arterial rupture"
                ],
                category: "Genetics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Osteogenesis Imperfecta",
                alternativeNames: ["Brittle Bone Disease"],
                hints: [
                    "Child with multiple fractures from minimal trauma",
                    "Blue sclerae and hearing loss",
                    "Dentinogenesis imperfecta",
                    "Type I collagen defect",
                    "Types I-IV vary in severity"
                ],
                category: "Genetics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Duchenne Muscular Dystrophy",
                alternativeNames: ["DMD"],
                hints: [
                    "Boy with proximal muscle weakness by age 5",
                    "Gower sign (uses arms to stand up)",
                    "Calf pseudohypertrophy",
                    "Deleted or mutated dystrophin gene",
                    "Elevated CK, wheelchair-bound by teens"
                ],
                category: "Genetics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Becker Muscular Dystrophy",
                alternativeNames: ["BMD"],
                hints: [
                    "Male with muscle weakness in teens or 20s",
                    "Milder than Duchenne, later onset",
                    "Partially functional dystrophin",
                    "X-linked recessive",
                    "Can walk into adulthood"
                ],
                category: "Genetics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Myotonic Dystrophy",
                alternativeNames: [],
                hints: [
                    "Patient with myotonia (delayed muscle relaxation)",
                    "Cannot release handshake quickly",
                    "Frontal balding and cataracts",
                    "CTG repeat expansion",
                    "Autosomal dominant with anticipation"
                ],
                category: "Genetics",
                difficulty: 3
            ),
            
            // REPRODUCTIVE/UROLOGY (12 cases)
            MedicalCase(
                diagnosis: "Benign Prostatic Hyperplasia",
                alternativeNames: ["BPH"],
                hints: [
                    "Elderly male with difficulty initiating urination",
                    "Nocturia and incomplete bladder emptying",
                    "Enlarged, smooth prostate on DRE",
                    "Elevated post-void residual volume",
                    "Treated with alpha-blockers or 5-alpha-reductase inhibitors"
                ],
                category: "Urology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Prostate Cancer",
                alternativeNames: ["Prostate Adenocarcinoma"],
                hints: [
                    "Elderly male with elevated PSA",
                    "Hard, irregular nodule on DRE",
                    "Most common cancer in men",
                    "Bone metastases (osteoblastic)",
                    "Gleason score determines prognosis"
                ],
                category: "Urology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Testicular Seminoma",
                alternativeNames: [],
                hints: [
                    "Young male with painless testicular mass",
                    "Most common testicular cancer",
                    "Homogeneous, radiosensitive",
                    "Elevated hCG in some cases",
                    "Excellent prognosis"
                ],
                category: "Urology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Testicular Non-Seminomatous Germ Cell Tumor",
                alternativeNames: ["NSGCT"],
                hints: [
                    "Young male with testicular mass",
                    "Includes embryonal, yolk sac, choriocarcinoma, teratoma",
                    "Elevated AFP and/or hCG",
                    "More aggressive than seminoma",
                    "Yolk sac most common in children"
                ],
                category: "Urology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Ovarian Cancer",
                alternativeNames: ["Epithelial Ovarian Cancer"],
                hints: [
                    "Postmenopausal woman with abdominal distension and bloating",
                    "Pelvic mass and ascites",
                    "Elevated CA-125",
                    "Often presents at advanced stage",
                    "BRCA1/2 mutations increase risk"
                ],
                category: "Gynecology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Cervical Intraepithelial Neoplasia",
                alternativeNames: ["CIN", "Cervical Dysplasia"],
                hints: [
                    "Woman with abnormal Pap smear",
                    "HPV infection (types 16, 18)",
                    "CIN I, II, III progression",
                    "Koilocytes on cytology",
                    "Colposcopy and biopsy for diagnosis"
                ],
                category: "Gynecology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Invasive Cervical Cancer",
                alternativeNames: ["Cervical Squamous Cell Carcinoma"],
                hints: [
                    "Woman with post-coital bleeding",
                    "HPV types 16 and 18 most common",
                    "Squamous cell (80%) or adenocarcinoma",
                    "Can be prevented with HPV vaccine",
                    "Staging based on clinical exam"
                ],
                category: "Gynecology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Breast Cancer",
                alternativeNames: ["Invasive Ductal Carcinoma"],
                hints: [
                    "Woman with palpable breast mass or mammographic abnormality",
                    "Peau d'orange if dermal lymphatic invasion",
                    "Nipple retraction or discharge",
                    "Sentinel lymph node biopsy for staging",
                    "HER2, ER, PR status guide treatment"
                ],
                category: "Oncology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Epididymitis",
                alternativeNames: [],
                hints: [
                    "Young male with scrotal pain and fever",
                    "Positive Prehn sign (relief with elevation)",
                    "Urethral discharge if STI-related",
                    "Chlamydia/gonorrhea in <35 years, E. coli in older",
                    "Treated with antibiotics"
                ],
                category: "Urology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Testicular Torsion",
                alternativeNames: [],
                hints: [
                    "Adolescent with sudden severe testicular pain",
                    "Absent cremasteric reflex",
                    "Negative Prehn sign (no relief with elevation)",
                    "Bell-clapper deformity",
                    "Surgical emergency within 6 hours"
                ],
                category: "Urology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Varicocele",
                alternativeNames: [],
                hints: [
                    "Male with scrotal swelling described as bag of worms",
                    "More common on left side",
                    "Increases in size with Valsalva",
                    "Can cause infertility",
                    "Sudden right-sided varicocele suggests renal mass"
                ],
                category: "Urology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Hydrocele",
                alternativeNames: [],
                hints: [
                    "Male with painless scrotal swelling",
                    "Transilluminates with light",
                    "Fluid accumulation in tunica vaginalis",
                    "Congenital or acquired",
                    "Usually benign"
                ],
                category: "Urology",
                difficulty: 2
            ),
            
            // ENT (6 cases)
            MedicalCase(
                diagnosis: "Meniere Disease",
                alternativeNames: [],
                hints: [
                    "Patient with episodic vertigo lasting hours",
                    "Fluctuating hearing loss and tinnitus",
                    "Aural fullness",
                    "Endolymphatic hydrops",
                    "Treated with diuretics and low-salt diet"
                ],
                category: "ENT",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Vestibular Schwannoma",
                alternativeNames: ["Acoustic Neuroma"],
                hints: [
                    "Patient with unilateral hearing loss and tinnitus",
                    "Loss of corneal reflex (CN V involvement)",
                    "Mass at cerebellopontine angle",
                    "Associated with neurofibromatosis type 2",
                    "Treated with surgery or radiation"
                ],
                category: "ENT",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Acute Otitis Media",
                alternativeNames: ["AOM"],
                hints: [
                    "Child with ear pain and fever",
                    "Bulging, erythematous tympanic membrane",
                    "Most common: S. pneumoniae, H. influenzae, Moraxella",
                    "Can lead to mastoiditis if untreated",
                    "Treated with amoxicillin"
                ],
                category: "ENT",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Otitis Externa",
                alternativeNames: ["Swimmer's Ear"],
                hints: [
                    "Patient with ear pain worse with tragal manipulation",
                    "Recent swimming or water exposure",
                    "Pseudomonas most common organism",
                    "External auditory canal erythema and discharge",
                    "Treated with topical fluoroquinolone drops"
                ],
                category: "ENT",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Acute Bacterial Sinusitis",
                alternativeNames: [],
                hints: [
                    "Patient with facial pain and purulent nasal discharge",
                    "Symptoms >7-10 days or worsening after initial improvement",
                    "Maxillary tooth pain",
                    "S. pneumoniae, H. influenzae, Moraxella",
                    "Treated with amoxicillin-clavulanate"
                ],
                category: "ENT",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Allergic Rhinitis",
                alternativeNames: ["Hay Fever"],
                hints: [
                    "Patient with seasonal sneezing and nasal congestion",
                    "Clear rhinorrhea and itchy nose/eyes",
                    "Pale, boggy nasal turbinates",
                    "Allergic shiners (dark circles under eyes)",
                    "Treated with antihistamines and nasal steroids"
                ],
                category: "ENT",
                difficulty: 2
            ),
            
            // PHARMACOLOGY (20 cases)
            MedicalCase(
                diagnosis: "Warfarin Therapy",
                alternativeNames: ["Coumadin"],
                hints: [
                    "Patient on anticoagulation with elevated INR",
                    "Inhibits vitamin K epoxide reductase",
                    "Factors II, VII, IX, X affected",
                    "Reversed with vitamin K or fresh frozen plasma",
                    "Many drug-drug and drug-food interactions"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Heparin-Induced Thrombocytopenia",
                alternativeNames: ["HIT"],
                hints: [
                    "Patient on heparin with platelet count drop >50%",
                    "Paradoxical thrombosis risk",
                    "Antibodies against heparin-PF4 complex",
                    "Stop heparin, use direct thrombin inhibitor",
                    "4 T's score helps diagnosis"
                ],
                category: "Pharmacology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Statin-Induced Myopathy",
                alternativeNames: [],
                hints: [
                    "Patient on statin with muscle pain and weakness",
                    "Elevated CK levels",
                    "Risk of rhabdomyolysis if severe",
                    "Inhibits HMG-CoA reductase",
                    "More common with fibrate combination"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "ACE Inhibitor Side Effects",
                alternativeNames: [],
                hints: [
                    "Patient on lisinopril with dry cough",
                    "Can cause angioedema (contraindicated in pregnancy)",
                    "Hyperkalemia risk",
                    "Increased bradykinin causes cough",
                    "Switch to ARB if cough intolerable"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Beta-Blocker Toxicity",
                alternativeNames: [],
                hints: [
                    "Patient with bradycardia, hypotension, and bronchospasm",
                    "Masks hypoglycemia symptoms in diabetics",
                    "Contraindicated in asthma and cocaine use",
                    "Can cause sexual dysfunction",
                    "Treated with glucagon if overdose"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Digoxin Toxicity",
                alternativeNames: [],
                hints: [
                    "Elderly patient with nausea and yellow vision",
                    "Increased automaticity and AV block",
                    "Bidirectional ventricular tachycardia classic",
                    "Narrow therapeutic window",
                    "Treated with digoxin-specific antibody fragments"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Lithium Toxicity",
                alternativeNames: [],
                hints: [
                    "Bipolar patient with tremor, confusion, and seizures",
                    "Nephrogenic diabetes insipidus",
                    "Hypothyroidism with chronic use",
                    "Narrow therapeutic window (0.6-1.2 mEq/L)",
                    "Treated with hemodialysis if severe"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Phenytoin Side Effects",
                alternativeNames: ["Dilantin"],
                hints: [
                    "Epileptic patient with gingival hyperplasia",
                    "Hirsutism and coarse facial features",
                    "Megaloblastic anemia (inhibits folate absorption)",
                    "Teratogenic (fetal hydantoin syndrome)",
                    "CYP450 inducer"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Methotrexate Toxicity",
                alternativeNames: [],
                hints: [
                    "Cancer patient with mucositis and pancytopenia",
                    "Inhibits dihydrofolate reductase",
                    "Hepatotoxicity and pulmonary fibrosis",
                    "Teratogenic",
                    "Leucovorin (folinic acid) rescue"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Aminoglycoside Toxicity",
                alternativeNames: ["Gentamicin", "Tobramycin"],
                hints: [
                    "Patient with hearing loss and acute kidney injury",
                    "Ototoxicity (vestibular and cochlear)",
                    "Nephrotoxicity (dose-dependent)",
                    "Monitor trough levels",
                    "Can cause neuromuscular blockade"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Vancomycin Red Man Syndrome",
                alternativeNames: [],
                hints: [
                    "Patient with flushing and pruritus during IV infusion",
                    "Non-IgE mediated histamine release",
                    "Not true allergic reaction",
                    "Prevented by slow infusion rate",
                    "Can also cause nephrotoxicity and ototoxicity"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Rifampin Side Effects",
                alternativeNames: [],
                hints: [
                    "TB patient with orange-red discoloration of secretions",
                    "Potent CYP450 inducer (many drug interactions)",
                    "Decreases effectiveness of oral contraceptives",
                    "Hepatotoxicity",
                    "Colors tears, urine, sweat orange"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Fluoroquinolone Side Effects",
                alternativeNames: ["Ciprofloxacin", "Levofloxacin"],
                hints: [
                    "Patient with Achilles tendon pain after antibiotic",
                    "Tendon rupture risk (especially in elderly and steroid users)",
                    "Can prolong QT interval",
                    "Contraindicated in pregnancy and children",
                    "Can cause C. difficile colitis"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Sulfonamide Hypersensitivity",
                alternativeNames: ["Sulfa Allergy"],
                hints: [
                    "Patient with rash after starting TMP-SMX",
                    "Stevens-Johnson syndrome risk",
                    "Kernicterus in neonates (displaces bilirubin)",
                    "Hemolysis in G6PD deficiency",
                    "Cross-reactivity with other sulfa drugs variable"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Amphotericin B Toxicity",
                alternativeNames: ["Ampho-terrible"],
                hints: [
                    "Patient with rigors and fever during infusion",
                    "Nephrotoxicity and hypokalemia/hypomagnesemia",
                    "Premedicate with acetaminophen and diphenhydramine",
                    "Liposomal formulation less toxic",
                    "Monitor renal function and electrolytes"
                ],
                category: "Pharmacology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Bleomycin Pulmonary Toxicity",
                alternativeNames: [],
                hints: [
                    "Cancer patient with progressive dyspnea",
                    "Pulmonary fibrosis on imaging",
                    "Dose-dependent toxicity",
                    "Monitor with pulmonary function tests",
                    "Avoid supplemental oxygen if possible"
                ],
                category: "Pharmacology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Doxorubicin Cardiotoxicity",
                alternativeNames: ["Adriamycin"],
                hints: [
                    "Cancer patient with dilated cardiomyopathy",
                    "Dose-dependent cardiotoxicity",
                    "Free radical damage to myocytes",
                    "Monitor with echocardiogram",
                    "Dexrazoxane cardioprotective"
                ],
                category: "Pharmacology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Vincristine Neurotoxicity",
                alternativeNames: [],
                hints: [
                    "Leukemia patient with peripheral neuropathy",
                    "Foot drop and loss of reflexes",
                    "Inhibits microtubule polymerization",
                    "Constipation common (autonomic neuropathy)",
                    "Dose-limiting toxicity"
                ],
                category: "Pharmacology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Cisplatin Toxicity",
                alternativeNames: [],
                hints: [
                    "Cancer patient with hearing loss and neuropathy",
                    "Nephrotoxicity (dose-limiting)",
                    "Ototoxicity and peripheral neuropathy",
                    "Severe nausea and vomiting",
                    "Aggressive hydration prevents nephrotoxicity"
                ],
                category: "Pharmacology",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Cyclophosphamide Toxicity",
                alternativeNames: [],
                hints: [
                    "Patient with hemorrhagic cystitis",
                    "Acrolein metabolite damages bladder",
                    "Prevented with mesna and hydration",
                    "Myelosuppression and SIADH",
                    "Increased risk of bladder cancer"
                ],
                category: "Pharmacology",
                difficulty: 3
            ),
            
            // PSYCHIATRY/BEHAVIORAL (6 cases)
            MedicalCase(
                diagnosis: "Alcohol Withdrawal",
                alternativeNames: ["Delirium Tremens"],
                hints: [
                    "Hospitalized alcoholic with tremor and hallucinations",
                    "Autonomic hyperactivity: tachycardia, hypertension, diaphoresis",
                    "Seizures possible within 48 hours",
                    "Delirium tremens (DTs) at 48-96 hours",
                    "Treated with benzodiazepines (CIWA protocol)"
                ],
                category: "Psychiatry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Bulimia Nervosa",
                alternativeNames: [],
                hints: [
                    "Young woman with binge eating and compensatory behaviors",
                    "Dental erosion from vomiting",
                    "Russell sign (calluses on knuckles)",
                    "Parotid gland hypertrophy",
                    "Hypokalemic hypochloremic metabolic alkalosis"
                ],
                category: "Psychiatry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Attention-Deficit Hyperactivity Disorder",
                alternativeNames: ["ADHD"],
                hints: [
                    "Child with inattention and hyperactivity",
                    "Difficulty completing tasks and sitting still",
                    "Symptoms present before age 12",
                    "Impairs academic and social functioning",
                    "Treated with stimulants (methylphenidate, amphetamines)"
                ],
                category: "Psychiatry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Autism Spectrum Disorder",
                alternativeNames: ["ASD"],
                hints: [
                    "Child with impaired social communication",
                    "Repetitive behaviors and restricted interests",
                    "Symptoms present in early development",
                    "Variable intellectual functioning",
                    "Behavioral therapy is mainstay of treatment"
                ],
                category: "Psychiatry",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Neuroleptic Malignant Syndrome",
                alternativeNames: ["NMS"],
                hints: [
                    "Patient on antipsychotic with fever and rigidity",
                    "Lead-pipe rigidity and altered mental status",
                    "Elevated CK and myoglobinuria",
                    "Autonomic instability",
                    "Treated with dantrolene and bromocriptine"
                ],
                category: "Psychiatry",
                difficulty: 3
            ),
            
            MedicalCase(
                diagnosis: "Serotonin Syndrome",
                alternativeNames: [],
                hints: [
                    "Patient on SSRIs with agitation and hyperthermia",
                    "Hyperreflexia and clonus",
                    "Tremor and diaphoresis",
                    "Mydriasis and flushing",
                    "Treated with cyproheptadine and supportive care"
                ],
                category: "Psychiatry",
                difficulty: 3
            ),
            
            // VASCULAR (8 cases)
            MedicalCase(
                diagnosis: "Deep Vein Thrombosis",
                alternativeNames: ["DVT"],
                hints: [
                    "Patient with unilateral leg swelling and pain",
                    "Positive Homan sign (calf pain with dorsiflexion)",
                    "Risk factors: immobility, surgery, malignancy, hypercoagulable state",
                    "Duplex ultrasound for diagnosis",
                    "Treated with anticoagulation"
                ],
                category: "Vascular",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Peripheral Arterial Disease",
                alternativeNames: ["PAD"],
                hints: [
                    "Patient with claudication (calf pain with walking)",
                    "Decreased or absent pulses",
                    "Low ankle-brachial index (<0.9)",
                    "Hair loss and shiny skin on legs",
                    "Risk factors: smoking, diabetes, hyperlipidemia"
                ],
                category: "Vascular",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Abdominal Aortic Aneurysm",
                alternativeNames: ["AAA"],
                hints: [
                    "Elderly male with pulsatile abdominal mass",
                    "Often asymptomatic until rupture",
                    "Rupture triad: hypotension, back pain, pulsatile mass",
                    "Screen men 65-75 who have smoked",
                    "Repair if >5.5 cm or symptomatic"
                ],
                category: "Vascular",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Varicose Veins",
                alternativeNames: [],
                hints: [
                    "Patient with dilated, tortuous superficial veins",
                    "Leg pain and heaviness worse at end of day",
                    "Risk factors: pregnancy, prolonged standing, obesity",
                    "Incompetent venous valves",
                    "Can lead to venous stasis ulcers"
                ],
                category: "Vascular",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Hypovolemic Shock",
                alternativeNames: [],
                hints: [
                    "Patient with hypotension and tachycardia after trauma",
                    "Cold, clammy skin",
                    "Decreased urine output",
                    "Narrow pulse pressure",
                    "Treated with fluid resuscitation"
                ],
                category: "Critical Care",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Cardiogenic Shock",
                alternativeNames: [],
                hints: [
                    "Patient with hypotension and pulmonary edema after MI",
                    "Elevated JVP and S3 gallop",
                    "Decreased cardiac output",
                    "Cool extremities",
                    "Requires inotropic support"
                ],
                category: "Critical Care",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Septic Shock",
                alternativeNames: ["Distributive Shock"],
                hints: [
                    "Febrile patient with hypotension refractory to fluids",
                    "Warm extremities initially (high cardiac output)",
                    "Elevated lactate",
                    "Requires vasopressors (norepinephrine)",
                    "Source control and broad-spectrum antibiotics"
                ],
                category: "Critical Care",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Obstructive Shock",
                alternativeNames: [],
                hints: [
                    "Patient with hypotension and elevated JVP",
                    "Causes: tension pneumothorax, PE, tamponade",
                    "Muffled heart sounds if tamponade",
                    "Decreased cardiac output from obstruction",
                    "Requires relief of obstruction"
                ],
                category: "Critical Care",
                difficulty: 2
            ),
            
            // EMBRYOLOGY (6 cases)
            MedicalCase(
                diagnosis: "Patent Foramen Ovale",
                alternativeNames: ["PFO"],
                hints: [
                    "Young patient with stroke without risk factors",
                    "Paradoxical embolism through atrial defect",
                    "Present in 25% of population",
                    "Usually asymptomatic",
                    "Bubble study on echocardiogram"
                ],
                category: "Cardiology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Meckel Diverticulum",
                alternativeNames: [],
                hints: [
                    "Child with painless rectal bleeding",
                    "Rule of 2's: 2 feet from ileocecal valve, 2 inches long, 2% population",
                    "Contains ectopic gastric mucosa",
                    "Technetium-99m scan (Meckel scan)",
                    "Most common congenital GI anomaly"
                ],
                category: "Gastroenterology",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Omphalocele",
                alternativeNames: [],
                hints: [
                    "Newborn with abdominal contents in sac at umbilicus",
                    "Covered by peritoneum and amnion",
                    "Associated with chromosomal abnormalities",
                    "Liver may be in sac",
                    "Better prognosis than gastroschisis"
                ],
                category: "Pediatrics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Gastroschisis",
                alternativeNames: [],
                hints: [
                    "Newborn with intestines protruding through abdominal wall",
                    "No covering membrane",
                    "Lateral to umbilicus (usually right)",
                    "Not associated with chromosomal abnormalities",
                    "Requires surgical repair"
                ],
                category: "Pediatrics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Duodenal Atresia",
                alternativeNames: [],
                hints: [
                    "Newborn with bilious vomiting",
                    "Double bubble sign on X-ray",
                    "Associated with Down syndrome",
                    "Polyhydramnios during pregnancy",
                    "Requires surgical correction"
                ],
                category: "Pediatrics",
                difficulty: 2
            ),
            
            MedicalCase(
                diagnosis: "Biliary Atresia",
                alternativeNames: [],
                hints: [
                    "Infant with prolonged jaundice and acholic stools",
                    "Progressive cholestatic jaundice after 2 weeks",
                    "Direct hyperbilirubinemia",
                    "Leads to cirrhosis if untreated",
                    "Kasai procedure (hepatoportoenterostomy)"
                ],
                category: "Pediatrics",
                difficulty: 3
            ),
            MedicalCase(
                diagnosis: "Pheochromocytoma",
                alternativeNames: ["Adrenal Medulla Tumor", "10% Tumor"],
                hints: [
                    "35-year-old male with episodic headaches and palpitations",
                    "Paroxysmal spells of sweating and anxiety",
                    "Marked hypertension (200/110 mmHg) during episodes",
                    "Elevated urinary vanillylmandelic acid (VMA) and metanephrines",
                    "Chromaffin cell tumor derived from neural crest cells"
                ],
                category: "Endocrinology",
                difficulty: 3),
            
            MedicalCase(
                diagnosis: "Cystic Fibrosis",
                alternativeNames: ["Mucoviscidosis", "CF"],
                hints: [
                    "2-year-old boy with recurrent pneumonia and foul-smelling stools",
                    "Failure to thrive despite a healthy appetite",
                    "Nasal polyps and digital clubbing on exam",
                    "Sweat chloride concentration > 60 mEq/L",
                    "Phe508 deletion in the CFTR gene on chromosome 7"
                ],
                category: "Pulmonology / Genetics",
                difficulty: 2),
            
            MedicalCase(
                diagnosis: "Multiple Myeloma",
                alternativeNames: ["Plasma Cell Myeloma", "Kahler Disease"],
                hints: [
                    "68-year-old female with persistent lower back pain and fatigue",
                    "Normocytic anemia and recurrent infections",
                    "Hypercalcemia and 'punched-out' lytic bone lesions on X-ray",
                    "Serum protein electrophoresis (SPEP) shows an M-spike",
                    "Bence-Jones proteins (Ig light chains) found in urine"
                ],
                category: "Hematology / Oncology",
                difficulty: 3),
            
            MedicalCase(
                diagnosis: "Goodpasture Syndrome",
                alternativeNames: ["Anti-GBM Disease"],
                hints: [
                    "25-year-old male presenting with hemoptysis and hematuria",
                    "Shortness of breath and bilateral pulmonary infiltrates",
                    "Crescentic glomerulonephritis on renal biopsy",
                    "Linear immunofluorescence of IgG along the glomerular basement membrane",
                    "Antibodies against the alpha-3 chain of Type IV collagen"
                ],
                category: "Nephrology",
                difficulty: 4),
            
            MedicalCase(
                diagnosis: "Pyloric Stenosis",
                alternativeNames: ["Infantile Hypertrophic Pyloric Stenosis"],
                hints: [
                    "3-week-old first-born male with non-bilious, projectile vomiting",
                    "Vomiting occurs immediately after feeding; infant is 'hungry'",
                    "Palpable 'olive-shaped' mass in the epigastrium",
                    "Hypochloremic, hypokalemic metabolic alkalosis",
                    "Ultrasound showing thickening and elongation of the pylorus"
                ],
                category: "Pediatrics / GI",
                difficulty: 2),
            
            MedicalCase(
                diagnosis: "Multiple Sclerosis",
                alternativeNames: ["MS", "Demyelinating Disease"],
                hints: [
                    "28-year-old female with sudden loss of vision in one eye and pain with movement",
                    "History of transient numbness in the legs six months ago",
                    "Internuclear ophthalmoplegia (INO) and hyperreflexia",
                    "MRI showing periventricular white matter plaques (Dawson fingers)",
                    "CSF analysis revealing oligoclonal bands"
                ],
                category: "Neurology",
                difficulty: 3),
            
            MedicalCase(
                diagnosis: "Sarcoidosis",
                alternativeNames: ["Besnier-Boeck-Schaumann disease"],
                hints: [
                    "32-year-old African American female with a dry cough and skin rashes",
                    "Tender red nodules on the shins (erythema nodosum)",
                    "Bilateral hilar lymphadenopathy on chest X-ray",
                    "Elevated serum ACE levels and hypercalcemia",
                    "Non-caseating granulomas on tissue biopsy"
                ],
                category: "Pulmonology / Rheumatology",
                difficulty: 2),
            
            MedicalCase(
                diagnosis: "DiGeorge Syndrome",
                alternativeNames: ["22q11.2 Deletion Syndrome", "Catch-22"],
                hints: [
                    "Newborn with a cleft palate, low-set ears, and a small jaw",
                    "Patient develops tetany (hypocalcemic seizures) shortly after birth",
                    "Chest X-ray reveals an absent thymic shadow",
                    "Truncus arteriosus or Tetralogy of Fallot identified on echo",
                    "Failure of the 3rd and 4th pharyngeal pouches to develop"
                ],
                category: "Immunology / Genetics",
                difficulty: 4),
            
            MedicalCase(
                diagnosis: "Systemic Lupus Erythematosus",
                alternativeNames: ["SLE", "Lupus"],
                hints: [
                    "24-year-old female with joint pain and a facial rash after sun exposure",
                    "Malar (butterfly) rash sparing the nasolabial folds",
                    "Pleural effusion and proteinuria noted on workup",
                    "Positive ANA (sensitive) and Anti-dsDNA or Anti-Smith (specific)",
                    "Type III hypersensitivity reaction causing immune complex deposition"
                ],
                category: "Rheumatology",
                difficulty: 2),
            
            MedicalCase(
                diagnosis: "Graves Disease",
                alternativeNames: ["Basedow Disease", "Toxic Diffuse Goiter"],
                hints: [
                    "30-year-old female with weight loss, heat intolerance, and tremors",
                    "Proptosis (bulging eyes) and pretibial myxedema",
                    "Diffuse, painless enlargement of the thyroid gland (goiter)",
                    "Low TSH and high Free T4",
                    "Thyroid-stimulating immunoglobulin (TSI) mimicking TSH"
                ],
                category: "Endocrinology",
                difficulty: 1
            ),
            MedicalCase(
                    diagnosis: "Aortic Stenosis",
                    alternativeNames: ["AS", "Calcific Aortic Valve"],
                    hints: [
                        "72-year-old male with syncope during his daily walk",
                        "Exertional dyspnea and angina",
                        "Crescendo-decrescendo systolic murmur at the right upper sternal border",
                        "Pulsus parvus et tardus (weak, delayed carotid pulse)",
                        "SAD triad: Syncope, Angina, Dyspnea"
                    ],
                    category: "Cardiology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Wernicke Encephalopathy",
                    alternativeNames: ["Thiamine Deficiency", "Vitamin B1 Deficiency"],
                    hints: [
                        "45-year-old male with chronic alcohol use disorder",
                        "Acute onset of confusion and ataxia",
                        "Nystagmus and ophthalmoplegia on physical exam",
                        "Symptoms improve rapidly with IV thiamine administration",
                        "Classic triad: Ataxia, Confusion, Ophthalmoplegia"
                    ],
                    category: "Neurology / Nutrition",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Intussusception",
                    alternativeNames: ["Telescoping Bowel"],
                    hints: [
                        "9-month-old infant with sudden, intermittent abdominal pain",
                        "Infant draws knees to chest during episodes of crying",
                        "'Currant jelly' stools (mucus and blood)",
                        "Sausage-shaped mass palpable in the right upper quadrant",
                        "Target sign seen on ultrasound; treat with air/contrast enema"
                    ],
                    category: "Pediatrics / GI",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Giant Cell Arteritis",
                    alternativeNames: ["Temporal Arteritis", "GCA"],
                    hints: [
                        "70-year-old female with a new, unilateral headache",
                        "Jaw claudication while chewing food",
                        "Tenderness over the temporal area and sudden vision loss",
                        "Markedly elevated Erythrocyte Sedimentation Rate (ESR)",
                        "Granulomatous inflammation of large/medium arteries; risk of blindness"
                    ],
                    category: "Rheumatology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Minimal Change Disease",
                    alternativeNames: ["Nil Disease", "Lipoid Nephrosis"],
                    hints: [
                        "5-year-old boy with sudden facial puffiness and swollen ankles",
                        "Recent history of an upper respiratory infection",
                        "Heavy proteinuria (>3.5g/day) with no hematuria",
                        "Normal light microscopy; 'nil' findings",
                        "Effacement of podocyte foot processes on electron microscopy"
                    ],
                    category: "Nephrology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Pseudomembranous Colitis",
                    alternativeNames: ["C. diff Colitis", "Clostridioides difficile"],
                    hints: [
                        "60-year-old female with profuse watery diarrhea and cramping",
                        "History of recent Clindamycin use for a skin infection",
                        "Leukocytosis and fever present",
                        "Yellowish-white plaques on colonic mucosa during colonoscopy",
                        "Toxins A and B detected in the stool"
                    ],
                    category: "Infectious Disease / GI",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Wilson Disease",
                    alternativeNames: ["Hepatolenticular Degeneration"],
                    hints: [
                        "18-year-old male with tremors and new-onset jaundice",
                        "Difficulty speaking (dysarthria) and parkinsonian symptoms",
                        "Brownish-yellow rings seen in the cornea (Kayser-Fleischer rings)",
                        "Low serum ceruloplasmin and high urinary copper",
                        "Mutation in ATP7B gene causing impaired copper transport"
                    ],
                    category: "Gastroenterology / Neurology",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Zollinger-Ellison Syndrome",
                    alternativeNames: ["Gastrinoma"],
                    hints: [
                        "40-year-old male with recurrent, multiple peptic ulcers",
                        "Ulcers are refractory to PPI therapy and located in the jejunum",
                        "Chronic watery diarrhea and weight loss",
                        "Significantly elevated fasting serum gastrin levels",
                        "Positive secretin stimulation test (gastrin remains high)"
                    ],
                    category: "Gastroenterology / Endocrinology",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Kawasaki Disease",
                    alternativeNames: ["Mucocutaneous Lymph Node Syndrome"],
                    hints: [
                        "4-year-old boy with high fever for 6 days",
                        "Bright red 'strawberry tongue' and cracked lips",
                        "Bilateral conjunctival injection without exudate",
                        "Desquamation of the skin on hands and feet",
                        "CRASH and Burn: Conjunctivitis, Rash, Adenopathy, Strawberry tongue, Hand/foot changes + Fever"
                    ],
                    category: "Pediatrics / Cardiology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Pneumocystis Jirovecii Pneumonia",
                    alternativeNames: ["PCP", "Pneumocystosis"],
                    hints: [
                        "35-year-old male with HIV and a CD4 count of 150",
                        "Progressive exertional dyspnea and non-productive cough",
                        "Bilateral 'ground-glass' opacities on chest X-ray",
                        "Silver stain (GMS) of induced sputum shows disc-shaped cysts",
                        "Prophylaxis and treatment with Trimethoprim-Sulfamethoxazole"
                    ],
                    category: "Infectious Disease",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Huntington Disease",
                    alternativeNames: ["Huntington Chorea"],
                    hints: [
                        "40-year-old male with involuntary jerky movements (chorea)",
                        "Recent onset of aggression, depression, and dementia",
                        "Family history of similar symptoms at a young age",
                        "Atrophy of the caudate nucleus and putamen on MRI",
                        "CAG trinucleotide repeat expansion in the HTT gene"
                    ],
                    category: "Neurology / Genetics",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Acromegaly",
                    alternativeNames: ["Growth Hormone Excess"],
                    hints: [
                        "45-year-old female noticing her rings and shoes no longer fit",
                        "Coarsening of facial features and a prominent jaw (prognathism)",
                        "New-onset hypertension and Type 2 Diabetes",
                        "Elevated Insulin-like Growth Factor 1 (IGF-1)",
                        "Failure to suppress Growth Hormone (GH) after oral glucose load"
                    ],
                    category: "Endocrinology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Achalasia",
                    alternativeNames: ["Cardiospasm"],
                    hints: [
                        "50-year-old male with progressive dysphagia to both solids and liquids",
                        "Regurgitation of undigested food and weight loss",
                        "Barium swallow shows a 'bird's beak' appearance of the esophagus",
                        "Manometry shows failure of the lower esophageal sphincter (LES) to relax",
                        "Loss of myenteric (Auerbach) plexus in the distal esophagus"
                    ],
                    category: "Gastroenterology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Celiac Disease",
                    alternativeNames: ["Gluten-Sensitive Enteropathy"],
                    hints: [
                        "30-year-old female with chronic diarrhea, bloating, and dermatitis herpetiformis",
                        "Iron deficiency anemia and vitamin D deficiency",
                        "Blunting of intestinal villi and crypt hyperplasia on biopsy",
                        "Positive anti-tissue transglutaminase (tTG) IgA antibodies",
                        "Association with HLA-DQ2 and HLA-DQ8"
                    ],
                    category: "Gastroenterology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Ewing Sarcoma",
                    alternativeNames: ["Small Blue Round Cell Tumor"],
                    hints: [
                        "12-year-old boy with localized pain and swelling in the femur",
                        "Fever, leukocytosis, and an elevated ESR",
                        "X-ray shows a 'moth-eaten' appearance and 'onion-skin' periosteal reaction",
                        "Biopsy reveals small, round, blue cells",
                        "t(11;22) translocation involving the EWS-FLI1 gene"
                    ],
                    category: "Orthopedics / Oncology",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Polycythemia Vera",
                    alternativeNames: ["Primary Polycythemia"],
                    hints: [
                        "55-year-old male with severe itching (pruritus) after a hot shower",
                        "Plethoric face (redness) and splenomegaly",
                        "Increased hematocrit and hemoglobin despite normal oxygen levels",
                        "Very low serum erythropoietin (EPO) levels",
                        "JAK2 V617F mutation in hematopoietic stem cells"
                    ],
                    category: "Hematology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Membranous Nephropathy",
                    alternativeNames: ["Membranous Glomerulonephritis"],
                    hints: [
                        "50-year-old male with generalized edema and frothy urine",
                        "Associated with Hepatitis B, NSAID use, or solid tumors",
                        "Thickened glomerular basement membrane (GBM) on light microscopy",
                        "'Spike and dome' appearance on silver stain",
                        "Granular deposition of IgG and C3 along the GBM"
                    ],
                    category: "Nephrology",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Gout",
                    alternativeNames: ["Monosodium Urate Crystal Arthropathy"],
                    hints: [
                        "55-year-old male with sudden, excruciating pain in the big toe (Podagra)",
                        "History of heavy alcohol use and high-protein diet",
                        "Joint is red, hot, and extremely tender to touch",
                        "Needle-shaped crystals under polarized light",
                        "Crystals show negative birefringence (yellow when parallel to the slow wave)"
                    ],
                    category: "Rheumatology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Pernicious Anemia",
                    alternativeNames: ["Vitamin B12 Deficiency", "Megaloblastic Anemia"],
                    hints: [
                        "60-year-old female with tingling in her feet and a smooth, sore tongue",
                        "Increased mean corpuscular volume (MCV > 100 fL)",
                        "Hypersegmented neutrophils on peripheral blood smear",
                        "Degeneration of the dorsal columns of the spinal cord",
                        "Anti-intrinsic factor or anti-parietal cell antibodies"
                    ],
                    category: "Hematology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Primary Biliary Cholangitis",
                    alternativeNames: ["PBC", "Primary Biliary Cirrhosis"],
                    hints: [
                        "45-year-old female with severe itching and fatigue",
                        "Physical exam shows xanthelasmas and hepatomegaly",
                        "Elevated Alkaline Phosphatase (ALP) and Bilirubin",
                        "Positive anti-mitochondrial antibodies (AMA)",
                        "Autoimmune destruction of intrahepatic bile ducts"
                    ],
                    category: "Gastroenterology / Hepatology",
                    difficulty: 4
            ),
            MedicalCase(
                    diagnosis: "Coarctation of the Aorta",
                    alternativeNames: ["Aortic Narrowing"],
                    hints: [
                        "15-year-old male with headaches and cold feet",
                        "Brachial-femoral pulse delay",
                        "Hypertension in arms; hypotension/weak pulses in legs",
                        "Rib notching on X-ray and '3' sign on barium swallow",
                        "Turner Syndrome association (45,XO)"
                    ],
                    category: "Cardiology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Ehlers-Danlos Syndrome",
                    alternativeNames: ["EDS", "Hypermobility Syndrome"],
                    hints: [
                        "19-year-old male with multiple joint dislocations",
                        "Hyperextensible skin and easy bruising",
                        "Velvety skin texture and 'cigarette paper' scars",
                        "Mitral valve prolapse and berry aneurysms",
                        "Defect in Type V or Type III collagen synthesis"
                    ],
                    category: "Genetics / Connective Tissue",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Polyarteritis Nodosa",
                    alternativeNames: ["PAN"],
                    hints: [
                        "45-year-old male with abdominal pain and foot drop",
                        "Livedo reticularis (net-like rash) and fever",
                        "Negative for ANCA; strongly associated with Hepatitis B",
                        "String-of-beads appearance on renal artery angiogram",
                        "Transmural necrotizing inflammation of medium-sized arteries"
                    ],
                    category: "Rheumatology / Vasculitis",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Minimal Change Disease",
                    alternativeNames: ["Lipoid Nephrosis"],
                    hints: [
                        "4-year-old with periorbital edema after a viral cold",
                        "Heavy proteinuria and fatty casts in urine",
                        "Excellent response to corticosteroid therapy",
                        "Normal light microscopy; no immune deposits",
                        "Effacement of podocyte foot processes on EM"
                    ],
                    category: "Nephrology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Hirschsprung Disease",
                    alternativeNames: ["Congenital Aganglionic Megacolon"],
                    hints: [
                        "48-hour-old newborn who has not passed meconium",
                        "Abdominal distension and bilious vomiting",
                        "Explosive release of stool on digital rectal exam",
                        "Dilated proximal colon; narrowed distal segment",
                        "Absence of ganglion cells in Meissner and Auerbach plexuses"
                    ],
                    category: "Pediatrics / GI",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Chronic Granulomatous Disease",
                    alternativeNames: ["CGD"],
                    hints: [
                        "5-year-old boy with recurrent skin abscesses",
                        "Infections with Catalase-positive organisms (S. aureus, Aspergillus)",
                        "Abnormal Dihydrorhodamine (DHR) flow cytometry",
                        "Negative Nitroblue Tetrazolium (NBT) dye test",
                        "Deficiency in NADPH oxidase"
                    ],
                    category: "Immunology",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Osteosarcoma",
                    alternativeNames: ["Osteogenic Sarcoma"],
                    hints: [
                        "16-year-old male with knee pain that wakes him at night",
                        "Swelling above the knee; no systemic fever",
                        "Codman triangle (periosteal elevation) on X-ray",
                        "'Sunburst' pattern of bone spicules",
                        "Associated with mutations in RB1 and TP53 genes"
                    ],
                    category: "Orthopedics / Oncology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Small Cell Lung Cancer",
                    alternativeNames: ["Oat Cell Carcinoma"],
                    hints: [
                        "65-year-old heavy smoker with a central lung mass",
                        "Hyponatremia (SIADH) or Cushingoid features (ACTH)",
                        "Lambert-Eaton Myasthenic Syndrome (proximal weakness)",
                        "Neuroendocrine origin; small blue cells on histology",
                        "Often treated with chemo/radiation rather than surgery"
                    ],
                    category: "Pulmonology / Oncology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Granulomatosis with Polyangiitis",
                    alternativeNames: ["Wegener Granulomatosis", "GPA"],
                    hints: [
                        "50-year-old male with chronic sinusitis and bloody sputum",
                        "Hematuria and saddle-nose deformity",
                        "C-ANCA (PR3-ANCA) positivity",
                        "Necrotizing granulomas in upper/lower respiratory tracts",
                        "Triad: Focal necrotizing vasculitis, lung granulomas, glomerulonephritis"
                    ],
                    category: "Rheumatology / Vasculitis",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Addison Disease",
                    alternativeNames: ["Primary Adrenal Insufficiency"],
                    hints: [
                        "35-year-old female with weakness and salt cravings",
                        "Hyperpigmentation of skin creases and buccal mucosa",
                        "Hypotension, hyperkalemia, and hyponatremia",
                        "Low morning cortisol; high ACTH",
                        "Autoimmune destruction of the adrenal cortex"
                    ],
                    category: "Endocrinology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Chediak-Higashi Syndrome",
                    alternativeNames: ["CHS"],
                    hints: [
                        "4-year-old with silvery-white hair (partial albinism)",
                        "Recurrent pyogenic infections and peripheral neuropathy",
                        "Giant granules in neutrophils on blood smear",
                        "Easy bruising and bleeding (platelet dysfunction)",
                        "Defect in lysosomal trafficking regulator gene (LYST)"
                    ],
                    category: "Immunology",
                    difficulty: 5),

                MedicalCase(
                    diagnosis: "Hemophilia A",
                    alternativeNames: ["Factor VIII Deficiency"],
                    hints: [
                        "8-year-old boy with painful swelling in the knee (hemarthrosis)",
                        "Prolonged bleeding after dental extractions",
                        "Isolated prolonged PTT; normal PT and bleeding time",
                        "X-linked recessive inheritance",
                        "Deficiency of coagulation Factor VIII"
                    ],
                    category: "Hematology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Diabetes Insipidus (Central)",
                    alternativeNames: ["Neurogenic DI"],
                    hints: [
                        "30-year-old following head trauma with intense thirst",
                        "Massive volumes of dilute urine (low specific gravity)",
                        "Serum hyperosmolality; urine hypoosmolality",
                        "Water deprivation test shows increase in urine osmolality after Desmopressin",
                        "ADH deficiency from the posterior pituitary"
                    ],
                    category: "Endocrinology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Marfan Syndrome",
                    alternativeNames: ["MFS"],
                    hints: [
                        "22-year-old tall male with long, thin fingers (arachnodactyly)",
                        "Upward lens subluxation (ectopia lentis)",
                        "Pectus excavatum and high-arched palate",
                        "Risk of aortic dissection or mitral valve prolapse",
                        "FBN1 gene mutation on chromosome 15 (fibrillin-1)"
                    ],
                    category: "Genetics / Cardiology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Glioblastoma Multiforme",
                    alternativeNames: ["GBM", "Grade IV Astrocytoma"],
                    hints: [
                        "60-year-old with personality changes and new headaches",
                        "Ring-enhancing lesion on MRI crossing the corpus callosum",
                        "'Butterfly glioma' appearance",
                        "Histology: Pseudopalisading necrosis and hemorrhage",
                        "Most common malignant primary brain tumor in adults"
                    ],
                    category: "Neurology / Oncology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Hereditary Spherocytosis",
                    alternativeNames: ["HS"],
                    hints: [
                        "25-year-old with jaundice and splenomegaly",
                        "Small, dark red blood cells lacking central pallor",
                        "Increased Mean Corpuscular Hemoglobin Concentration (MCHC)",
                        "Positive osmotic fragility test",
                        "Defect in ankyrin, spectrin, or band 3 proteins"
                    ],
                    category: "Hematology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Paget Disease of Bone",
                    alternativeNames: ["Osteitis Deformans"],
                    hints: [
                        "70-year-old male noticing his hat size has increased",
                        "Hearing loss and deep bone pain",
                        "Isolated elevation of Alkaline Phosphatase (ALP)",
                        "'Mosaic' pattern of lamellar bone (bone remodeling)",
                        "Increased risk of high-output heart failure and osteosarcoma"
                    ],
                    category: "Rheumatology / Orthopedics",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Minimal Change Disease",
                    alternativeNames: ["Lipoid Nephrosis"],
                    hints: [
                        "4-year-old with puffy eyes and generalized edema",
                        "Recent viral infection or immunization",
                        "Selective albuminuria (>3.5g/day)",
                        "Normal light microscopy findings",
                        "Effacement of podocyte foot processes on EM"
                    ],
                    category: "Nephrology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Burkitt Lymphoma",
                    alternativeNames: ["B-cell Non-Hodgkin Lymphoma"],
                    hints: [
                        "8-year-old African boy with a rapidly growing jaw mass",
                        "EBV association (endemic form)",
                        "Histology: 'Starry sky' appearance (tingible body macrophages)",
                        "High mitotic index and Ki-67 staining",
                        "t(8;14) translocation of the c-myc gene"
                    ],
                    category: "Hematology / Oncology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Duchenne Muscular Dystrophy",
                    alternativeNames: ["DMD"],
                    hints: [
                        "4-year-old boy using hands to 'climb up' his legs to stand",
                        "Pseudohypertrophy of the calves",
                        "Gowers sign and waddling gait",
                        "Markedly elevated Creatine Kinase (CK)",
                        "Frameshift mutation leading to absent dystrophin protein"
                    ],
                    category: "Neurology / Genetics",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Primary Sclerosing Cholangitis",
                    alternativeNames: ["PSC"],
                    hints: [
                        "35-year-old male with ulcerative colitis and jaundice",
                        "Itching, fatigue, and dark urine",
                        "ERCP showing 'beading' of the bile ducts",
                        "Histology: 'Onion-skin' periductal fibrosis",
                        "p-ANCA positivity in 60-80% of cases"
                    ],
                    category: "Hepatology / GI",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Von Willebrand Disease",
                    alternativeNames: ["vWD"],
                    hints: [
                        "18-year-old female with heavy menses and frequent nosebleeds",
                        "Bleeding after dental work",
                        "Increased bleeding time; normal or slightly prolonged PTT",
                        "Abnormal ristocetin cofactor assay",
                        "Most common inherited bleeding disorder"
                    ],
                    category: "Hematology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Cushing Syndrome",
                    alternativeNames: ["Hypercortisolism"],
                    hints: [
                        "40-year-old with 'moon facies' and 'buffalo hump'",
                        "Purple abdominal striae and central obesity",
                        "Hypertension and hyperglycemia (diabetes)",
                        "Elevated 24-hour urinary free cortisol",
                        "Can be caused by exogenous steroids or ACTH-secreting tumor"
                    ],
                    category: "Endocrinology",
                    difficulty: 1),

                MedicalCase(
                    diagnosis: "Zenker Diverticulum",
                    alternativeNames: ["Pharyngoesophageal Diverticulum"],
                    hints: [
                        "75-year-old male with halitosis (bad breath) and dysphagia",
                        "Regurgitation of undigested food while lying down",
                        "A mass in the neck that gurgles",
                        "Barium swallow shows a pouch in the upper esophagus",
                        "Herniation through Killian's triangle (false diverticulum)"
                    ],
                    category: "Gastroenterology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Whipple Disease",
                    alternativeNames: ["Tropheryma whipplei infection"],
                    hints: [
                        "55-year-old male with weight loss, diarrhea, and joint pain",
                        "Hyperpigmentation and cardiac symptoms",
                        "PAS-positive macrophages in the lamina propria",
                        "Gram-positive rod-shaped intracellular bacteria",
                        "Treatment usually involves long-term Ceftriaxone or TMP-SMX"
                    ],
                    category: "Infectious Disease / GI",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Psoriasis",
                    alternativeNames: ["Psoriasis Vulgaris"],
                    hints: [
                        "30-year-old with silver scales on red plaques on the elbows",
                        "Auspitz sign (pinpoint bleeding when scales are removed)",
                        "Nail pitting and oil spots",
                        "Histology: Munro microabscesses (neutrophils in stratum corneum)",
                        "Association with HLA-Cw6 and psoriatic arthritis"
                    ],
                    category: "Dermatology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Scleroderma (Diffuse)",
                    alternativeNames: ["Systemic Sclerosis"],
                    hints: [
                        "45-year-old female with stiff, tight skin on the chest and arms",
                        "Raynaud phenomenon and heartburn (GERD)",
                        "Pulmonary fibrosis or renal crisis",
                        "Anti-Scl-70 (anti-DNA topoisomerase I) antibodies",
                        "Widespread collagen deposition in skin and internal organs"
                    ],
                    category: "Rheumatology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Hypertrophic Cardiomyopathy",
                    alternativeNames: ["HCM", "HOCM"],
                    hints: [
                        "18-year-old athlete collapses and dies during a game",
                        "Systolic murmur that decreases with squatting",
                        "Murmur increases with Valsalva or standing",
                        "Asymmetric septal hypertrophy on echo",
                        "Mutations in sarcomeric proteins (beta-myosin heavy chain)"
                    ],
                    category: "Cardiology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Minimal Change Disease",
                    alternativeNames: ["Lipoid Nephrosis"],
                    hints: [
                        "6-year-old presenting with massive generalized edema",
                        "Urinalysis shows 4+ protein and oval fat bodies",
                        "Rapid response to Prednisone therapy",
                        "Normal glomeruli on light microscopy",
                        "Effacement of foot processes on EM"
                    ],
                    category: "Nephrology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Gardner Syndrome",
                    alternativeNames: ["FAP with Extra-intestinal Manifestations"],
                    hints: [
                        "20-year-old with hundreds of polyps on colonoscopy",
                        "Multiple osteomas of the jaw and skull",
                        "Hypertrophy of retinal pigment epithelium (CHRPE)",
                        "Desmoid tumors and impacted teeth",
                        "Autosomal dominant mutation of the APC gene"
                    ],
                    category: "Gastroenterology / Genetics",
                    difficulty: 4
            ),
            MedicalCase(
                    diagnosis: "Tetralogy of Fallot",
                    alternativeNames: ["ToF"],
                    hints: [
                        "Infant with cyanosis that improves when squatting ('tet spells')",
                        "Boot-shaped heart on chest X-ray",
                        "Right ventricular hypertrophy, Overriding aorta, VSD, Pulmonary stenosis",
                        "Crescendo-decrescendo systolic murmur at left upper sternal border",
                        "Derived from abnormal neural crest cell migration"
                    ],
                    category: "Pediatrics / Cardiology",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Cystic Fibrosis",
                    alternativeNames: ["CF"],
                    hints: [
                        "Child with recurrent pulmonary infections and foul-smelling steatorrhea",
                        "Meconium ileus noted at birth",
                        "Chloride levels >60 mEq/L in sweat test",
                        "PHE508 deletion in the CFTR gene on chromosome 7",
                        "Infertility in males due to bilateral absence of vas deferens"
                    ],
                    category: "Genetics / Pulmonology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "DiGeorge Syndrome",
                    alternativeNames: ["22q11.2 Deletion Syndrome"],
                    hints: [
                        "Neonate with hypocalcemic tetany (seizures) and cleft palate",
                        "Absent thymic shadow on X-ray",
                        "Recurrent viral and fungal infections (T-cell deficiency)",
                        "Truncus arteriosus or interrupted aortic arch",
                        "Failure of 3rd and 4th pharyngeal pouches to develop"
                    ],
                    category: "Immunology / Genetics",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Pheochromocytoma",
                    alternativeNames: ["Adrenal Medulla Tumor"],
                    hints: [
                        "Adult with episodic 'Pounding' headache, 'Palpitations', and 'Perspiration'",
                        "Severe hypertension that is paroxysmal",
                        "Elevated urinary metanephrines and vanillylmandelic acid (VMA)",
                        "Chromaffin cell tumor derived from neural crest",
                        "Associated with MEN 2A and 2B"
                    ],
                    category: "Endocrinology",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Gaucher Disease",
                    alternativeNames: ["Glucocerebrosidase Deficiency"],
                    hints: [
                        "Child with hepatosplenomegaly, bone pain, and pancytopenia",
                        "Histology: Macrophages with 'crinkled paper' cytoplasm",
                        "Most common lysosomal storage disease",
                        "Deficiency of Glucocerebrosidase",
                        "Accumulation of Glucocerebroside"
                    ],
                    category: "Genetics / Biochemistry",
                    difficulty: 5),

                MedicalCase(
                    diagnosis: "Tay-Sachs Disease",
                    alternativeNames: ["Hexosaminidase A Deficiency"],
                    hints: [
                        "6-month-old infant with developmental regression and exaggerated startle reflex",
                        "'Cherry-red' spot on the macula",
                        "No hepatosplenomegaly (distinguishes from Niemann-Pick)",
                        "Lysosomes with 'onion-skin' appearance",
                        "Deficiency of Hexosaminidase A; accumulation of GM2 ganglioside"
                    ],
                    category: "Genetics / Biochemistry",
                    difficulty: 5),

                MedicalCase(
                    diagnosis: "Turner Syndrome",
                    alternativeNames: ["45,X"],
                    hints: [
                        "Teenage girl with short stature and primary amenorrhea",
                        "Webbed neck (cystic hygroma) and widely spaced nipples",
                        "Bicuspid aortic valve or pre-ductal coarctation of the aorta",
                        "'Streak ovaries' leading to low estrogen and high LH/FSH",
                        "Loss of one X chromosome (non-disjunction during meiosis)"
                    ],
                    category: "Genetics / OBGYN",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Klinefelter Syndrome",
                    alternativeNames: ["47,XXY"],
                    hints: [
                        "Tall male with small, firm testes and gynecomastia",
                        "Infertility and increased risk of breast cancer",
                        "Barr body present on buccal smear",
                        "Low testosterone; elevated LH and FSH",
                        "Dysgenesis of seminiferous tubules"
                    ],
                    category: "Genetics / Urology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Primary Hyperparathyroidism",
                    alternativeNames: ["Parathyroid Adenoma"],
                    hints: [
                        "50-year-old with 'stones, bones, groans, and psychic overtones'",
                        "Hypercalcemia, hypophosphatemia, and elevated ALP",
                        "Subperiosteal bone resorption and brown tumors (osteitis fibrosa cystica)",
                        "Increased urinary cAMP",
                        "Usually caused by a single parathyroid adenoma"
                    ],
                    category: "Endocrinology",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Wilson Disease",
                    alternativeNames: ["Hepatolenticular Degeneration"],
                    hints: [
                        "Young patient with liver failure and parkinsonian tremors",
                        "Kayser-Fleischer rings in the cornea",
                        "Low serum ceruloplasmin; high urinary copper",
                        "Basal ganglia atrophy (lenticular nucleus)",
                        "Defect in ATP7B copper-transporting ATPase"
                    ],
                    category: "Gastroenterology / Neurology",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Multiple Myeloma",
                    alternativeNames: ["Plasma Cell Dyscrasia"],
                    hints: [
                        "Elderly male with bone pain and 'punched-out' lytic lesions on X-ray",
                        "Hypercalcemia, Renal failure, Anemia, Bone lesions (CRAB)",
                        "M-protein spike on serum protein electrophoresis",
                        "Bence-Jones proteins in urine (Ig light chains)",
                        "Rouleaux formation on peripheral blood smear"
                    ],
                    category: "Hematology / Oncology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Pyloric Stenosis",
                    alternativeNames: ["Infantile Hypertrophic Pyloric Stenosis"],
                    hints: [
                        "3-week-old male with non-bilious, projectile vomiting",
                        "'Olive-shaped' mass palpable in the epigastrium",
                        "Hypochloremic, hypokalemic metabolic alkalosis",
                        "String sign on barium swallow",
                        "Hypertrophy of the pyloric sphincter"
                    ],
                    category: "Pediatrics / GI",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Goodpasture Syndrome",
                    alternativeNames: ["Anti-GBM Disease"],
                    hints: [
                        "Young man with hemoptysis and hematuria",
                        "Linear IgG and C3 deposition on glomerular basement membrane",
                        "Type II hypersensitivity reaction",
                        "Antibodies against alpha-3 chain of Type IV collagen",
                        "Rapidly progressive glomerulonephritis (RPGN) with crescents"
                    ],
                    category: "Nephrology / Pulmonology",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Polycystic Kidney Disease (ADPKD)",
                    alternativeNames: ["Adult PKD"],
                    hints: [
                        "40-year-old with flank pain, hematuria, and hypertension",
                        "Bilateral palpable flank masses",
                        "Associated with berry aneurysms and liver cysts",
                        "Mutation in PKD1 (chromosome 16) or PKD2 (chromosome 4)",
                        "Progressive renal failure by age 50"
                    ],
                    category: "Nephrology / Genetics",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Myasthenia Gravis",
                    alternativeNames: ["MG"],
                    hints: [
                        "Woman with ptosis and diplopia that worsen at the end of the day",
                        "Symptoms improve with ice pack or rest",
                        "Antibodies against postsynaptic ACh receptors",
                        "Associated with thymoma or thymic hyperplasia",
                        "Edrophonium (Tensilon) test used for historical diagnosis"
                    ],
                    category: "Neurology / Immunology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Lambert-Eaton Myasthenic Syndrome",
                    alternativeNames: ["LEMS"],
                    hints: [
                        "Patient with proximal muscle weakness that improves with use",
                        "Associated with Small Cell Lung Cancer",
                        "Antibodies against presynaptic voltage-gated calcium channels",
                        "Autonomic dysfunction (dry mouth, impotence)",
                        "Minimal response to AChE inhibitors"
                    ],
                    category: "Neurology / Oncology",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Hemochromatosis",
                    alternativeNames: ["Bronze Diabetes"],
                    hints: [
                        "Middle-aged male with skin hyperpigmentation, diabetes, and cirrhosis",
                        "High serum iron, high ferritin, and low TIBC",
                        "HFE gene mutation (C282Y)",
                        "Increased risk of hepatocellular carcinoma",
                        "Treatment involves periodic therapeutic phlebotomy"
                    ],
                    category: "Gastroenterology / Genetics",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Marfan Syndrome",
                    alternativeNames: ["MFS"],
                    hints: [
                        "Tall patient with long fingers, pectus excavatum, and lens dislocation",
                        "Aortic root dilation and risk of dissection",
                        "Mitral valve prolapse (holosystolic murmur with click)",
                        "Defect in Fibrillin-1 (FBN1) on chromosome 15",
                        "Cystic medial necrosis of the aorta"
                    ],
                    category: "Genetics / Cardiology",
                    difficulty: 2),

                MedicalCase(
                    diagnosis: "Fragile X Syndrome",
                    alternativeNames: ["CGG Repeat Disorder"],
                    hints: [
                        "Male child with intellectual disability and large ears",
                        "Macroorchidism (enlarged testes) post-puberty",
                        "Long face with a prominent jaw",
                        "CGG trinucleotide repeat expansion in the FMR1 gene",
                        "X-linked dominant inheritance with anticipation"
                    ],
                    category: "Genetics / Psychiatry",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Neurofibromatosis Type 1",
                    alternativeNames: ["von Recklinghausen Disease"],
                    hints: [
                        "Child with café-au-lait spots and axillary freckling",
                        "Lisch nodules (pigmented hamartomas of the iris)",
                        "Multiple cutaneous neurofibromas",
                        "Optic gliomas and pheochromocytomas",
                        "NF1 gene mutation on chromosome 17"
                    ],
                    category: "Genetics / Dermatology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Von Hippel-Lindau Disease",
                    alternativeNames: ["VHL"],
                    hints: [
                        "Patient with hemangioblastomas in the cerebellum and retina",
                        "Bilateral renal cell carcinomas (clear cell)",
                        "Pheochromocytomas",
                        "Deletion of VHL gene on chromosome 3",
                        "VHL protein normally targets HIF-1a for degradation"
                    ],
                    category: "Genetics / Oncology",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Sjögren Syndrome",
                    alternativeNames: ["Sicca Syndrome"],
                    hints: [
                        "Woman with dry eyes (xerophthalmia) and dry mouth (xerostomia)",
                        "Dental caries and bilateral parotid gland enlargement",
                        "Anti-Ro (SS-A) and Anti-La (SS-B) antibodies",
                        "Lymphocytic infiltration of exocrine glands",
                        "Increased risk of B-cell (MALT) lymphoma"
                    ],
                    category: "Rheumatology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Pemphigus Vulgaris",
                    alternativeNames: ["Acantholysis"],
                    hints: [
                        "Patient with painful, flaccid bullae and oral ulcers",
                        "Positive Nikolsky sign (skin sloughs with pressure)",
                        "Antibodies against Desmoglein-1 and Desmoglein-3",
                        "Histology: 'Tombstone' appearance of the basal layer",
                        "Immunofluorescence shows 'fishnet' pattern"
                    ],
                    category: "Dermatology",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Bullous Pemphigoid",
                    alternativeNames: [],
                    hints: [
                        "Elderly patient with tense bullae; no oral involvement",
                        "Negative Nikolsky sign",
                        "Antibodies against hemidesmosomes (BP180/230)",
                        "Subepidermal blisters on histology",
                        "Immunofluorescence shows linear pattern at the epidermal-dermal junction"
                    ],
                    category: "Dermatology",
                    difficulty: 3),

                MedicalCase(
                    diagnosis: "Lesch-Nyhan Syndrome",
                    alternativeNames: ["HGPRT Deficiency"],
                    hints: [
                        "Male child with intellectual disability and self-mutilation (lip/finger biting)",
                        "Orange 'sand' in the diaper (uric acid crystals)",
                        "Gouty arthritis and choreoathetosis",
                        "Deficiency of HGPRT (salvage pathway)",
                        "Excessive production of uric acid"
                    ],
                    category: "Biochemistry / Genetics",
                    difficulty: 5),

                MedicalCase(
                    diagnosis: "Von Gierke Disease",
                    alternativeNames: ["GSD Type I"],
                    hints: [
                        "Infant with doll-like face, thin extremities, and massive hepatomegaly",
                        "Severe fasting hypoglycemia and lactic acidosis",
                        "Elevated uric acid (gout) and triglycerides",
                        "Deficiency of Glucose-6-phosphatase",
                        "Liver does not respond to glucagon"
                    ],
                    category: "Biochemistry",
                    difficulty: 5),

                MedicalCase(
                    diagnosis: "Pompe Disease",
                    alternativeNames: ["GSD Type II"],
                    hints: [
                        "Infant with hypertrophic cardiomyopathy and hypotonia ('floppy baby')",
                        "Early death due to heart failure",
                        "Deficiency of lysosomal alpha-1,4-glucosidase (acid maltase)",
                        "PAS-positive material in lysosomes",
                        "Pompe trashes the Pump (heart)"
                    ],
                    category: "Biochemistry",
                    difficulty: 5),

                MedicalCase(
                    diagnosis: "Alkaptonuria",
                    alternativeNames: ["Homogentisic Acid Oxidase Deficiency"],
                    hints: [
                        "Patient with dark connective tissue and brown-pigmented sclera",
                        "Urine turns black when left standing",
                        "Severe arthritis later in life",
                        "Deficiency of homogentisate oxidase",
                        "Disruption of tyrosine metabolism"
                    ],
                    category: "Biochemistry",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Galactosemia",
                    alternativeNames: ["Classic Galactosemia"],
                    hints: [
                        "Neonate with jaundice, hepatomegaly, and cataracts shortly after starting milk",
                        "Increased risk of E. coli sepsis",
                        "Absence of galactose-1-phosphate uridyltransferase (GALT)",
                        "Reducing substances in the urine (not glucose)",
                        "Requires exclusion of galactose and lactose from diet"
                    ],
                    category: "Biochemistry / Pediatrics",
                    difficulty: 4),

                MedicalCase(
                    diagnosis: "Wiskott-Aldrich Syndrome",
                    alternativeNames: ["WAS"],
                    hints: [
                        "Male infant with eczema, recurrent infections, and small platelets",
                        "Bleeding (thrombocytopenic purpura)",
                        "Low IgM; high IgA and IgE",
                        "Mutation in the WAS gene; actin cytoskeleton defect",
                        "WATER: Wiskott-Aldrich, Thrombocytopenia, Eczema, Recurrent infections"
                    ],
                    category: "Immunology",
                    difficulty: 5
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
        return cases
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
