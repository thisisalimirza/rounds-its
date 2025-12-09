import Foundation

public struct DiagnosisLexicon {
    public static let all: [String] = [
        // Cardiology
        "Myocardial Infarction", "MI", "STEMI", "NSTEMI", "Unstable Angina", "Stable Angina", "Heart Failure", "CHF", "HFrEF", "HFpEF",
        "Atrial Fibrillation", "Atrial Flutter", "SVT", "AVNRT", "Ventricular Tachycardia", "Ventricular Fibrillation", "Torsades de Pointes",
        "Aortic Stenosis", "Aortic Regurgitation", "Mitral Stenosis", "Mitral Regurgitation", "Tricuspid Regurgitation", "Tricuspid Stenosis",
        "Pulmonic Stenosis", "Pulmonic Regurgitation", "Endocarditis", "Infective Endocarditis", "Pericarditis", "Acute Pericarditis",
        "Cardiac Tamponade", "Beck Triad", "Aortic Dissection", "Hypertension", "Hypertensive Emergency", "Hypertensive Urgency",
        "Hyperlipidemia", "Peripheral Artery Disease", "Deep Vein Thrombosis", "DVT", "Pulmonary Embolism", "PE",
        "Wolff-Parkinson-White Syndrome", "WPW", "Long QT Syndrome", "Brugada Syndrome",

        // Neurology
        "Ischemic Stroke", "Hemorrhagic Stroke", "TIA", "Transient Ischemic Attack", "Subarachnoid Hemorrhage", "SAH",
        "Epidural Hematoma", "Subdural Hematoma", "Multiple Sclerosis", "MS", "Guillain-Barre Syndrome", "GBS",
        "Myasthenia Gravis", "MG", "Parkinson Disease", "Alzheimer Disease", "Frontotemporal Dementia", "Lewy Body Dementia",
        "Huntington Disease", "Amyotrophic Lateral Sclerosis", "ALS", "Seizure", "Epilepsy", "Status Epilepticus",
        "Migraine", "Cluster Headache", "Tension Headache", "Trigeminal Neuralgia", "Carpal Tunnel Syndrome",
        "Peripheral Neuropathy", "Bells Palsy", "Bell Palsy",

        // Pulmonology
        "Asthma", "Asthma Exacerbation", "Status Asthmaticus", "COPD", "Chronic Bronchitis", "Emphysema",
        "Pneumonia", "Community-Acquired Pneumonia", "Hospital-Acquired Pneumonia", "Atypical Pneumonia",
        "Pulmonary Embolism", "PE", "Pneumothorax", "Tension Pneumothorax", "Pleural Effusion",
        "Sarcoidosis", "Idiopathic Pulmonary Fibrosis", "IPF", "Obstructive Sleep Apnea", "OSA",
        "Acute Respiratory Distress Syndrome", "ARDS",

        // Gastroenterology
        "Gastroesophageal Reflux Disease", "GERD", "Peptic Ulcer Disease", "PUD", "Gastritis", "H. pylori Infection",
        "Celiac Disease", "Lactose Intolerance", "Irritable Bowel Syndrome", "IBS", "Inflammatory Bowel Disease", "IBD",
        "Crohn's Disease", "Ulcerative Colitis", "Appendicitis", "Acute Pancreatitis", "Chronic Pancreatitis",
        "Cholelithiasis", "Cholecystitis", "Choledocholithiasis", "Ascending Cholangitis", "Primary Sclerosing Cholangitis", "PSC",
        "Primary Biliary Cholangitis", "PBC", "Cirrhosis", "Hepatitis A", "Hepatitis B", "Hepatitis C", "Nonalcoholic Fatty Liver Disease", "NAFLD",
        "Hepatocellular Carcinoma", "HCC", "Upper GI Bleed", "Lower GI Bleed",

        // Endocrinology
        "Diabetes Mellitus", "Type 1 Diabetes", "Type 2 Diabetes", "Diabetic Ketoacidosis", "DKA", "Hyperosmolar Hyperglycemic State", "HHS",
        "Hypoglycemia", "Hyperthyroidism", "Graves Disease", "Thyroid Storm", "Hypothyroidism", "Hashimoto Thyroiditis",
        "Subacute Thyroiditis", "De Quervain Thyroiditis", "Cushing Syndrome", "Cushing Disease", "Addison Disease", "Primary Adrenal Insufficiency",
        "Pheochromocytoma", "Hyperaldosteronism", "Conn Syndrome", "Acromegaly", "Gigantism",
        "Hyperparathyroidism", "Hypoparathyroidism", "Hypercalcemia", "Hypocalcemia", "Phenylketonuria", "PKU", "Maple Syrup Urine Disease", "MSUD",

        // Nephrology
        "Acute Kidney Injury", "AKI", "Chronic Kidney Disease", "CKD", "Nephrotic Syndrome", "Nephritic Syndrome",
        "Minimal Change Disease", "Focal Segmental Glomerulosclerosis", "FSGS", "Membranous Nephropathy",
        "IgA Nephropathy", "Berger Disease", "Poststreptococcal Glomerulonephritis", "PSGN", "RPGN",
        "Acute Interstitial Nephritis", "AIN", "Pyelonephritis", "Urinary Tract Infection", "UTI",
        "Kidney Stones", "Nephrolithiasis", "Hydronephrosis",

        // Hematology/Oncology
        "Iron Deficiency Anemia", "Anemia of Chronic Disease", "Sideroblastic Anemia", "Thalassemia", "Alpha Thalassemia", "Beta Thalassemia",
        "Sickle Cell Disease", "Sickle Cell Crisis", "G6PD Deficiency", "Hereditary Spherocytosis",
        "Autoimmune Hemolytic Anemia", "Cold Agglutinin Disease", "Warm Agglutinin Disease",
        "Aplastic Anemia", "Polycythemia Vera", "Essential Thrombocythemia",
        "Acute Lymphoblastic Leukemia", "ALL", "Acute Myelogenous Leukemia", "AML", "Acute Promyelocytic Leukemia", "APL",
        "Chronic Lymphocytic Leukemia", "CLL", "Chronic Myelogenous Leukemia", "CML",
        "Hodgkin Lymphoma", "Non-Hodgkin Lymphoma", "Multiple Myeloma",
        "Immune Thrombocytopenic Purpura", "ITP", "Thrombotic Thrombocytopenic Purpura", "TTP", "Hemolytic Uremic Syndrome", "HUS",
        "Hemophilia A", "Hemophilia B", "von Willebrand Disease",

        // Infectious Disease
        "Sepsis", "Cellulitis", "Osteomyelitis", "Bacterial Meningitis", "Viral Meningitis", "Encephalitis",
        "Tuberculosis", "Latent TB", "Pneumocystis Pneumonia", "PCP", "HIV", "AIDS",
        "Syphilis", "Primary Syphilis", "Secondary Syphilis", "Tertiary Syphilis",
        "Gonorrhea", "Chlamydia", "Pelvic Inflammatory Disease", "PID",
        "Lyme Disease", "Rocky Mountain Spotted Fever", "RMSF", "Malaria", "Toxoplasmosis",
        "Candidiasis", "Aspergillosis", "Histoplasmosis", "Coccidioidomycosis", "Blastomycosis",
        "COVID-19", "Influenza", "Mononucleosis",
        "Tetanus", "Botulism", "Diphtheria", "Pertussis",

        // Rheumatology
        "Rheumatoid Arthritis", "Osteoarthritis", "Gout", "Pseudogout", "Systemic Lupus Erythematosus", "SLE",
        "Scleroderma", "Systemic Sclerosis", "Polymyalgia Rheumatica", "Temporal Arteritis", "Giant Cell Arteritis", "GCA",
        "Polymyositis", "Dermatomyositis", "Ankylosing Spondylitis", "Reactive Arthritis", "Reiter Syndrome",
        "Sjogren Syndrome", "Vasculitis", "Granulomatosis with Polyangiitis", "Wegener",
        "Microscopic Polyangiitis", "Eosinophilic Granulomatosis with Polyangiitis", "Churg-Strauss",

        // Psychiatry
        "Major Depressive Disorder", "Depression", "MDD", "Bipolar Disorder", "Generalized Anxiety Disorder", "GAD",
        "Panic Disorder", "Agoraphobia", "Social Anxiety Disorder", "PTSD", "Obsessive-Compulsive Disorder", "OCD",
        "Schizophrenia", "Schizoaffective Disorder", "Delusional Disorder",
        "Anorexia Nervosa", "Bulimia Nervosa", "Binge Eating Disorder",

        // Dermatology
        "Psoriasis", "Atopic Dermatitis", "Eczema", "Seborrheic Dermatitis", "Contact Dermatitis",
        "Impetigo", "Cellulitis", "Erysipelas", "Scabies", "Tinea Corporis", "Tinea Capitis",
        "Acne Vulgaris", "Rosacea", "Urticaria",

        // OB/GYN
        "Ectopic Pregnancy", "Spontaneous Abortion", "Preeclampsia", "Eclampsia", "Placental Abruption", "Placenta Previa",
        "Gestational Diabetes", "HELLP Syndrome", "Preterm Labor",
        "Polycystic Ovary Syndrome", "PCOS", "Endometriosis", "Uterine Fibroids", "Leiomyoma",
        "Cervical Cancer", "Endometrial Cancer", "Ovarian Cancer",
        "Pelvic Inflammatory Disease", "PID",

        // Pediatrics
        "Kawasaki Disease", "Measles", "Mumps", "Rubella", "Varicella", "Roseola", "Fifth Disease",
        "Croup", "Bronchiolitis", "Pyloric Stenosis", "Intussusception", "Hirschsprung Disease",
        "Developmental Dysplasia of the Hip", "Slipped Capital Femoral Epiphysis", "SCFE",
        "Osgood-Schlatter Disease", "Croup", "Epiglottitis",

        // Endocrine/Metabolic Genetics
        "Galactosemia", "Homocystinuria", "Alkaptonuria", "Glycogen Storage Disease Type I", "Von Gierke Disease",
        "Glycogen Storage Disease Type II", "Pompe Disease", "McArdle Disease",

        // Urology/Nephrology overlap
        "Benign Prostatic Hyperplasia", "BPH", "Prostate Cancer", "Testicular Torsion", "Varicocele", "Hydrocele",

        // Ophthalmology/ENT
        "Acute Angle-Closure Glaucoma", "Open-Angle Glaucoma", "Cataracts", "Macular Degeneration",
        "Acute Otitis Media", "Acute Otitis Externa", "Sinusitis",

        // Musculoskeletal/Ortho
        "Osteoporosis", "Osteomalacia", "Rickets", "Paget Disease of Bone",
        "Septic Arthritis", "Bursitis", "Tendinitis",

        // Surgery/Emergency
        "Aortic Dissection", "Ruptured Abdominal Aortic Aneurysm", "AAA", "Compartment Syndrome",
        "Necrotizing Fasciitis", "Burns", "Shock", "Hypovolemic Shock", "Cardiogenic Shock", "Distributive Shock",

        // Toxicology
        "Acetaminophen Toxicity", "Salicylate Toxicity", "Opioid Overdose", "Benzodiazepine Overdose", "Cocaine Intoxication",
        "Alcohol Withdrawal", "Delirium Tremens",

        // Immunology/Allergy
        "Anaphylaxis", "Urticaria", "Angioedema", "Serum Sickness", "Arthus Reaction",

        // End of list placeholders to ensure ~200 items
        "Hypermagnesemia", "Hypomagnesemia", "Hypernatremia", "Hyponatremia", "Hyperkalemia", "Hypokalemia",
        "Metabolic Acidosis", "Metabolic Alkalosis", "Respiratory Acidosis", "Respiratory Alkalosis",
        "DKA", "HHS", "Thyroid Storm", "Myxedema Coma",
        "Pulmonary Hypertension", "Primary Biliary Cholangitis", "Primary Sclerosing Cholangitis",
        "Hemochromatosis", "Wilson Disease", "Alpha-1 Antitrypsin Deficiency",
        "Beriberi", "Wernicke Encephalopathy", "Korsakoff Syndrome",
        "Scurvy", "Rickets", "Osteogenesis Imperfecta",
        "Marfan Syndrome", "Ehlers-Danlos Syndrome",
        "Lupus Nephritis", "Diabetic Nephropathy", "Hypertensive Nephrosclerosis",
        "Preeclampsia", "HELLP Syndrome",
        "Gestational Hypertension",
        "Placental Abruption", "Placenta Previa",
        "Testicular Cancer", "Seminoma", "Nonseminomatous Germ Cell Tumor",
        "Hydatidiform Mole", "Choriocarcinoma",
        "Dermatomyositis", "Polymyositis",
        "Temporal Arteritis", "Takayasu Arteritis",
        "Polyarteritis Nodosa", "PAN",
        "Henoch-Schonlein Purpura", "IgA Vasculitis",
        "Goodpasture Syndrome",
        "Granulomatosis with Polyangiitis", "Microscopic Polyangiitis",
        "Eosinophilic Granulomatosis with Polyangiitis",
        "Buerger Disease", "Thromboangiitis Obliterans",
        "Raynaud Phenomenon",
        "Hypersensitivity Pneumonitis",
        "Farmer Lung",
        "Asbestosis", "Silicosis", "Coal Workers' Pneumoconiosis",
        "Lead Poisoning", "Mercury Poisoning",
        "Organophosphate Poisoning",
        "Hypertriglyceridemia", "Familial Hypercholesterolemia",
        "Typhoid Fever", "Shigellosis", "Campylobacter Enteritis",
        "Vibrio Cholerae", "Traveler's Diarrhea",
        "Giardiasis", "Amebiasis",
        "Strongyloidiasis", "Enterobiasis",
        "Pinworm Infection",
        "Scabies", "Lice Infestation",
        "Herpes Zoster", "Shingles", "Herpes Simplex", "HSV", "Varicella",
        "EBV Mononucleosis", "CMV Infection",
        "Toxoplasmosis", "Cryptosporidiosis",
        "Zika Virus", "Dengue Fever",
        "Yellow Fever", "Ebola",
        "Hantavirus Pulmonary Syndrome",
        "Rabies",
        "Brucellosis",
        "Leptospirosis",
        "Q Fever",
        "Psittacosis",
        "Cat Scratch Disease",
        "Bartonella Henselae",
        "Actinomycosis",
        "Nocardiosis",
        "Whipple Disease",
        "Clostridioides difficile Infection", "C. diff",
        "Necrotizing Enterocolitis",
        "Volvulus",
        "Small Bowel Obstruction",
        "Large Bowel Obstruction",
        "Mesenteric Ischemia",
        "Ischemic Colitis",
        "Diverticulitis",
        "Hemorrhoids",
        "Anal Fissure",
        "Pilonidal Disease"
    ]

    public static func suggestions(matching query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lower = trimmed.lowercased()
        var seen = Set<String>()
        var results: [String] = []
        for term in all {
            let lowerTerm = term.lowercased()
            if lowerTerm.contains(lower) && !seen.contains(lowerTerm) {
                seen.insert(lowerTerm)
                results.append(term)
                if results.count == 10 { break }
            }
        }
        return results
    }
}
