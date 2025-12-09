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
        var cases: [MedicalCase] = [
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
