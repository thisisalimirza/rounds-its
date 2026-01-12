//
//  CaseBrowserView.swift
//  Rounds
//
//  Created by Ali Mirza on 12/9/25.
//

import SwiftUI
import SwiftData

struct CaseBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var caseHistory: [CaseHistoryEntry]
    @State private var selectedCategory: String = "All"
    @State private var searchText = ""
    @State private var selectedCase: MedicalCase?
    @State private var showingGame = false
    @State private var showingPaywall = false
    @State private var showingConfetti = false
    @State private var showingCompletedAlert = false
    
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    private let allCases: [MedicalCase] = CaseLibrary.getSampleCases()
    
    /// Set of case IDs that have been completed
    private var completedCaseIDs: Set<UUID> {
        Set(caseHistory.map { $0.caseID })
    }
    
    /// Set of diagnosis names that have been completed (fallback for old entries)
    private var completedDiagnoses: Set<String> {
        Set(caseHistory.map { $0.diagnosis.lowercased() })
    }
    
    /// Check if a case has been completed (by ID or diagnosis name)
    private func isCaseCompleted(_ medicalCase: MedicalCase) -> Bool {
        // Check by ID first (for new deterministic IDs)
        if completedCaseIDs.contains(medicalCase.id) {
            return true
        }
        // Fallback: check by diagnosis name (for old random IDs)
        return completedDiagnoses.contains(medicalCase.diagnosis.lowercased())
    }
    
    /// Get the history entry for a completed case
    private func historyEntry(for medicalCase: MedicalCase) -> CaseHistoryEntry? {
        // Try by ID first
        if let entry = caseHistory.first(where: { $0.caseID == medicalCase.id }) {
            return entry
        }
        // Fallback: try by diagnosis name
        return caseHistory.first { $0.diagnosis.lowercased() == medicalCase.diagnosis.lowercased() }
    }
    
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
        
        // Filter by search text (only search by category, not diagnosis to keep it mysterious)
        if !searchText.isEmpty {
            cases = cases.filter { medicalCase in
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
                    List(Array(filteredCases.enumerated()), id: \.element.id) { index, medicalCase in
                        let isCompleted = isCaseCompleted(medicalCase)
                        let historyItem = historyEntry(for: medicalCase)
                        
                        Button {
                            if isCompleted {
                                // Case already completed - show alert
                                selectedCase = medicalCase
                                showingCompletedAlert = true
                            } else if subscriptionManager.isProSubscriber {
                                selectedCase = medicalCase
                                showingGame = true
                            } else {
                                showingPaywall = true
                            }
                        } label: {
                            CaseRow(
                                medicalCase: medicalCase,
                                caseNumber: index + 1,
                                isLocked: !subscriptionManager.isProSubscriber,
                                isCompleted: isCompleted,
                                wasCorrect: historyItem?.wasCorrect
                            )
                        }
                        .disabled(isCompleted)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Browse Cases")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search categories...")
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
            .sheet(isPresented: $showingPaywall) {
                RoundsPaywallView(
                    onPurchaseCompleted: { _ in
                        showingConfetti = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showingConfetti = false
                        }
                    },
                    onRestoreCompleted: { _ in
                        if subscriptionManager.isProSubscriber {
                            showingConfetti = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showingConfetti = false
                            }
                        }
                    }
                )
            }
            .overlay {
                ConfettiView(isActive: $showingConfetti)
            }
            .alert("Case Already Completed", isPresented: $showingCompletedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let selectedCase = selectedCase {
                    Text("You've already completed this case (\(selectedCase.diagnosis)). Check your Case History to review it!")
                } else {
                    Text("You've already completed this case. Check your Case History to review it!")
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
    let caseNumber: Int
    var isLocked: Bool = false
    var isCompleted: Bool = false
    var wasCorrect: Bool? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Show "Case #" instead of diagnosis
                HStack(spacing: 8) {
                    Text("Case \(caseNumber)")
                        .font(.headline)
                        .foregroundStyle(isCompleted ? .secondary : .primary)
                    
                    // Status indicator
                    if isCompleted {
                        // Completed indicator
                        Image(systemName: wasCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(wasCorrect == true ? .green : .red)
                    } else if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    } else {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
                
                Spacer()
                
                // Right side indicator
                if isCompleted {
                    Text("Completed")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                } else if isLocked {
                    ProBadge(size: .small)
                } else {
                    // Difficulty indicator
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < medicalCase.difficulty ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(index < medicalCase.difficulty ? .yellow : .gray)
                        }
                    }
                }
            }
            
            HStack(spacing: 8) {
                Text(medicalCase.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(getCategoryColor(medicalCase.category).opacity(isCompleted ? 0.1 : (isLocked ? 0.1 : 0.2)))
                    .foregroundStyle(getCategoryColor(medicalCase.category).opacity(isCompleted ? 0.5 : (isLocked ? 0.6 : 1)))
                    .cornerRadius(6)
                
                // Show diagnosis if completed (no longer a mystery!)
                if isCompleted {
                    Text(medicalCase.diagnosis)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Show first hint as preview (not the diagnosis!)
            if !isCompleted {
                Text(medicalCase.hints.first ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .opacity(isLocked ? 0.6 : 1)
            }
        }
        .padding(.vertical, 4)
        .opacity(isCompleted ? 0.7 : (isLocked ? 0.85 : 1))
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
