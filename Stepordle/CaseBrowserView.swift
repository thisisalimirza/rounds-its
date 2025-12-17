//
//  CaseBrowserView.swift
//  Stepordle
//
//  Created by Ali Mirza on 12/9/25.
//

import SwiftUI
import SwiftData

struct CaseBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String = "All"
    @State private var searchText = ""
    @State private var selectedCase: MedicalCase?
    @State private var showingGame = false
    
    private let allCases: [MedicalCase] = CaseLibrary.getSampleCases()
    
    private var categories: [String] {
        let allCategories = Set(allCases.map { $0.category })
        return ["All"] + allCategories.sorted()
    }
    
    private var filteredCases: [MedicalCase] {
        var cases = allCases
        
        // Filter by category
        if selectedCategory != "All" {
            cases = cases.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            cases = cases.filter { medicalCase in
                medicalCase.diagnosis.localizedCaseInsensitiveContains(searchText) ||
                medicalCase.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return cases.sorted { $0.diagnosis < $1.diagnosis }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryButton(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
                
                // Cases List
                if filteredCases.isEmpty {
                    emptyStateView
                } else {
                    List(filteredCases) { medicalCase in
                        Button {
                            selectedCase = medicalCase
                            showingGame = true
                        } label: {
                            CaseRow(medicalCase: medicalCase)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Browse Cases")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search diagnoses...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showingGame) {
                if let selectedCase = selectedCase {
                    GameView(medicalCase: selectedCase)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("No Cases Found")
                .font(.title2)
                .bold()
            
            Text("Try adjusting your search or category filter")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Case Row
struct CaseRow: View {
    let medicalCase: MedicalCase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(medicalCase.diagnosis)
                    .font(.headline)
                
                Spacer()
                
                // Difficulty indicator
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < medicalCase.difficulty ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundStyle(index < medicalCase.difficulty ? .yellow : .gray)
                    }
                }
            }
            
            Text(medicalCase.category)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(getCategoryColor(medicalCase.category).opacity(0.2))
                .foregroundStyle(getCategoryColor(medicalCase.category))
                .cornerRadius(6)
            
            Text(medicalCase.hints.first ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
    
    private func getCategoryColor(_ category: String) -> Color {
        switch category {
        case "Cardiology": return .red
        case "Neurology": return .purple
        case "Pulmonology": return .blue
        case "Gastroenterology": return .orange
        case "Endocrinology": return .green
        case "Nephrology": return .cyan
        case "Hematology": return .pink
        case "Infectious Disease": return .yellow
        case "Rheumatology": return .indigo
        case "Psychiatry": return .mint
        case "Biochemistry": return .teal
        case "Nutrition": return Color(red: 0.5, green: 0.8, blue: 0.3)
        case "Toxicology": return Color(red: 0.6, green: 0.2, blue: 0.8)
        case "Immunology": return .cyan
        case "Genetics": return Color(red: 0.2, green: 0.6, blue: 0.9)
        case "Pharmacology": return Color(red: 0.9, green: 0.3, blue: 0.5)
        case "Orthopedics": return .brown
        case "ENT": return Color(red: 0.8, green: 0.6, blue: 0.2)
        case "Critical Care": return .red.opacity(0.8)
        case "Vascular": return .red.opacity(0.6)
        case "Obstetrics": return .pink.opacity(0.8)
        case "Gynecology": return .pink
        case "Obstetrics & Gynecology": return .pink
        case "Oncology": return .purple.opacity(0.7)
        case "Dermatology": return .orange.opacity(0.8)
        case "Ophthalmology": return .blue.opacity(0.7)
        case "Pediatrics": return Color(red: 0.4, green: 0.8, blue: 0.9)
        case "Urology": return .cyan.opacity(0.8)
        default: return .gray
        }
    }
}

#Preview {
    CaseBrowserView()
        .modelContainer(for: MedicalCase.self, inMemory: true)
}
