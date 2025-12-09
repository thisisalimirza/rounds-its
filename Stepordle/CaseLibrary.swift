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
