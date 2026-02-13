//
//  CaseBrowserView.swift
//  Rounds
//
//  Created by Ali Mirza on 12/9/25.
//

import SwiftUI
import SwiftData

// MARK: - Display Category Model

struct DisplayCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let includedCategories: [String] // Original category names that map to this display group

    var caseCount: Int = 0
    var completedCount: Int = 0

    var progress: Double {
        guard caseCount > 0 else { return 0 }
        return Double(completedCount) / Double(caseCount)
    }

    // Hashable conformance - hash by name since that's the unique identifier
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: DisplayCategory, rhs: DisplayCategory) -> Bool {
        lhs.name == rhs.name
    }
}

// MARK: - Category Mapping

struct CategoryMapper {

    /// Maps original case categories to display groups
    /// Combo categories (e.g., "Genetics / Cardiology") are assigned to their PRIMARY (first) category
    static func getDisplayCategories() -> [DisplayCategory] {
        [
            DisplayCategory(
                name: "Cardiology",
                icon: "heart.fill",
                color: .red,
                includedCategories: ["Cardiology"]
            ),
            DisplayCategory(
                name: "Pulmonology",
                icon: "lungs.fill",
                color: .blue,
                includedCategories: ["Pulmonology"]
            ),
            DisplayCategory(
                name: "Gastroenterology",
                icon: "fork.knife",
                color: .orange,
                includedCategories: ["Gastroenterology", "Hepatology / GI"]
            ),
            DisplayCategory(
                name: "Nephrology",
                icon: "drop.fill",
                color: .cyan,
                includedCategories: ["Nephrology"]
            ),
            DisplayCategory(
                name: "Neurology",
                icon: "brain.head.profile",
                color: .purple,
                includedCategories: ["Neurology"]
            ),
            DisplayCategory(
                name: "Infectious Disease",
                icon: "microbe.fill",
                color: .yellow,
                includedCategories: ["Infectious Disease"]
            ),
            DisplayCategory(
                name: "Endocrinology",
                icon: "waveform.path.ecg",
                color: .green,
                includedCategories: ["Endocrinology"]
            ),
            DisplayCategory(
                name: "Hematology & Oncology",
                icon: "drop.triangle.fill",
                color: .pink,
                includedCategories: ["Hematology", "Oncology", "Hematology / Oncology"]
            ),
            DisplayCategory(
                name: "Rheumatology",
                icon: "figure.walk",
                color: .indigo,
                includedCategories: ["Rheumatology", "Rheumatology / Vasculitis", "Rheumatology / Orthopedics"]
            ),
            DisplayCategory(
                name: "Psychiatry",
                icon: "brain",
                color: .mint,
                includedCategories: ["Psychiatry"]
            ),
            DisplayCategory(
                name: "Pediatrics",
                icon: "figure.and.child.holdinghands",
                color: Color(red: 0.4, green: 0.8, blue: 0.9),
                includedCategories: ["Pediatrics", "Pediatrics / GI", "Pediatrics / Cardiology"]
            ),
            DisplayCategory(
                name: "Dermatology",
                icon: "hand.raised.fill",
                color: .orange.opacity(0.8),
                includedCategories: ["Dermatology"]
            ),
            DisplayCategory(
                name: "Basic Sciences",
                icon: "flask.fill",
                color: .teal,
                includedCategories: [
                    "Biochemistry", "Genetics", "Pharmacology", "Nutrition",
                    "Immunology", "Toxicology",
                    "Biochemistry / Pediatrics", "Biochemistry / Genetics",
                    "Genetics / Cardiology", "Genetics / Biochemistry", "Genetics / Urology",
                    "Genetics / Pulmonology", "Genetics / Psychiatry", "Genetics / Oncology",
                    "Genetics / OBGYN", "Genetics / Dermatology", "Genetics / Connective Tissue",
                    "Immunology / Genetics"
                ]
            ),
            DisplayCategory(
                name: "Surgical Specialties",
                icon: "cross.case.fill",
                color: .brown,
                includedCategories: [
                    "Orthopedics", "Vascular", "ENT", "Ophthalmology", "Urology",
                    "Critical Care", "Orthopedics / Oncology"
                ]
            ),
            DisplayCategory(
                name: "OB/GYN",
                icon: "figure.stand.dress",
                color: .pink.opacity(0.8),
                includedCategories: ["Obstetrics", "Gynecology", "Obstetrics & Gynecology"]
            )
        ]
    }

    /// Get the display category for a given original category
    static func displayCategory(for originalCategory: String, in displayCategories: [DisplayCategory]) -> DisplayCategory? {
        // First, try exact match
        if let match = displayCategories.first(where: { $0.includedCategories.contains(originalCategory) }) {
            return match
        }

        // For combo categories not explicitly mapped, use the PRIMARY (first) category
        if originalCategory.contains(" / ") {
            let primary = originalCategory.components(separatedBy: " / ").first ?? originalCategory
            // Find which display category contains this primary
            return displayCategories.first { displayCat in
                displayCat.includedCategories.contains { $0.lowercased() == primary.lowercased() }
            }
        }

        return nil
    }
}

// MARK: - Main View

struct CaseBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var caseHistory: [CaseHistoryEntry]
    @State private var searchText = ""
    @State private var selectedDisplayCategory: DisplayCategory?
    @State private var selectedCase: MedicalCase?
    @State private var showingGame = false
    @State private var showingPaywall = false
    @State private var showingConfetti = false
    @State private var showingCompletedAlert = false
    @State private var showingAllCases = false

    // Cached categories to avoid recomputation on every render
    @State private var cachedCategories: [DisplayCategory] = []

    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    private let allCases: [MedicalCase] = CaseLibrary.getSampleCases()

    // MARK: - Computed Properties

    private var completedCaseIDs: Set<UUID> {
        Set(caseHistory.map { $0.caseID })
    }

    private var completedDiagnoses: Set<String> {
        Set(caseHistory.map { $0.diagnosis.lowercased() })
    }

    private func isCaseCompleted(_ medicalCase: MedicalCase) -> Bool {
        if completedCaseIDs.contains(medicalCase.id) {
            return true
        }
        return completedDiagnoses.contains(medicalCase.diagnosis.lowercased())
    }

    private func historyEntry(for medicalCase: MedicalCase) -> CaseHistoryEntry? {
        if let entry = caseHistory.first(where: { $0.caseID == medicalCase.id }) {
            return entry
        }
        return caseHistory.first { $0.diagnosis.lowercased() == medicalCase.diagnosis.lowercased() }
    }

    /// Compute categories with case counts - called once on appear
    private func computeCategories() -> [DisplayCategory] {
        var categories = CategoryMapper.getDisplayCategories()
        let completedIDs = completedCaseIDs
        let completedDiags = completedDiagnoses

        for i in categories.indices {
            let casesInCategory = allCases.filter { medicalCase in
                categories[i].includedCategories.contains(medicalCase.category) ||
                CategoryMapper.displayCategory(for: medicalCase.category, in: categories)?.name == categories[i].name
            }
            categories[i].caseCount = casesInCategory.count
            categories[i].completedCount = casesInCategory.filter { mc in
                completedIDs.contains(mc.id) || completedDiags.contains(mc.diagnosis.lowercased())
            }.count
        }

        return categories
            .filter { $0.caseCount > 0 }
            .sorted { $0.caseCount > $1.caseCount }
    }

    /// Cases filtered by search
    private var searchFilteredCases: [MedicalCase] {
        guard !searchText.isEmpty else { return [] }
        return allCases.filter { medicalCase in
            medicalCase.category.localizedCaseInsensitiveContains(searchText) ||
            medicalCase.hints.first?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    /// Cases for selected category - uses the category's includedCategories directly
    private func cases(for displayCategory: DisplayCategory) -> [MedicalCase] {
        let baseCategories = CategoryMapper.getDisplayCategories()
        return allCases.filter { medicalCase in
            displayCategory.includedCategories.contains(medicalCase.category) ||
            CategoryMapper.displayCategory(for: medicalCase.category, in: baseCategories)?.name == displayCategory.name
        }.sorted { $0.category < $1.category }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search results (when searching)
                    if !searchText.isEmpty {
                        searchResultsSection
                    } else {
                        // Category grid
                        categoryGridSection

                        // All Cases option
                        allCasesButton
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Browse Cases")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search cases...")
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
            .navigationDestination(item: $selectedDisplayCategory) { category in
                CategoryCasesView(
                    displayCategory: category,
                    cases: cases(for: category),
                    isCaseCompleted: isCaseCompleted,
                    historyEntry: historyEntry,
                    onCaseSelected: { medicalCase in
                        handleCaseSelection(medicalCase)
                    }
                )
            }
            .navigationDestination(isPresented: $showingAllCases) {
                AllCasesView(
                    cases: allCases,
                    isCaseCompleted: isCaseCompleted,
                    historyEntry: historyEntry,
                    onCaseSelected: { medicalCase in
                        handleCaseSelection(medicalCase)
                    }
                )
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
                        if subscriptionManager.isProUser {
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
                    Text("You've already completed this case.")
                }
            }
            .onAppear {
                // Compute categories once on appear
                if cachedCategories.isEmpty {
                    cachedCategories = computeCategories()
                }
            }
            .onChange(of: caseHistory.count) { _, _ in
                // Recompute when history changes
                cachedCategories = computeCategories()
            }
        }
    }

    // MARK: - Category Grid

    private var categoryGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(cachedCategories) { category in
                    CategoryCard(category: category) {
                        selectedDisplayCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - All Cases Button

    private var allCasesButton: some View {
        Button {
            showingAllCases = true
        } label: {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("All Cases")
                        .font(.headline)
                    Text("\(allCases.count) cases total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if searchFilteredCases.isEmpty {
                emptySearchView
            } else {
                Text("\(searchFilteredCases.count) results")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)

                LazyVStack(spacing: 8) {
                    // Use offset as ID to avoid duplicates
                    ForEach(Array(searchFilteredCases.enumerated()), id: \.offset) { index, medicalCase in
                        let isCompleted = isCaseCompleted(medicalCase)
                        let historyItem = historyEntry(for: medicalCase)

                        Button {
                            handleCaseSelection(medicalCase)
                        } label: {
                            CompactCaseRow(
                                medicalCase: medicalCase,
                                caseNumber: index + 1,
                                isLocked: !subscriptionManager.isProSubscriber,
                                isCompleted: isCompleted,
                                wasCorrect: historyItem?.wasCorrect
                            )
                        }
                        .disabled(isCompleted)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var emptySearchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("No cases found")
                .font(.headline)

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Helpers

    private func handleCaseSelection(_ medicalCase: MedicalCase) {
        if isCaseCompleted(medicalCase) {
            selectedCase = medicalCase
            showingCompletedAlert = true
        } else if subscriptionManager.isProUser {
            selectedCase = medicalCase
            showingGame = true
        } else {
            showingPaywall = true
        }
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: DisplayCategory
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon and count
                HStack {
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: category.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(category.color)
                    }

                    Spacer()

                    Text("\(category.caseCount)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                // Name
                Text(category.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.systemGray5))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(category.color)
                                .frame(width: geometry.size.width * category.progress, height: 4)
                        }
                    }
                    .frame(height: 4)

                    Text("\(category.completedCount)/\(category.caseCount) completed")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: category.color.opacity(0.1), radius: 8, y: 2)
        }
        .buttonStyle(CategoryCardButtonStyle(color: category.color))
    }
}

// Custom button style that doesn't interfere with scrolling
struct CategoryCardButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Category Cases View (Drill-down)

struct CategoryCasesView: View {
    let displayCategory: DisplayCategory
    let cases: [MedicalCase]
    let isCaseCompleted: (MedicalCase) -> Bool
    let historyEntry: (MedicalCase) -> CaseHistoryEntry?
    let onCaseSelected: (MedicalCase) -> Void

    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }

    /// Group cases by their original subcategory
    private var groupedCases: [(subcategory: String, cases: [MedicalCase])] {
        let grouped = Dictionary(grouping: cases) { $0.category }
        return grouped.map { (subcategory: $0.key, cases: $0.value) }
            .sorted { $0.cases.count > $1.cases.count }
    }

    var body: some View {
        List {
            ForEach(groupedCases, id: \.subcategory) { group in
                Section {
                    // Use index as part of ID to avoid duplicates
                    ForEach(Array(group.cases.enumerated()), id: \.offset) { index, medicalCase in
                        let isCompleted = isCaseCompleted(medicalCase)
                        let historyItem = historyEntry(medicalCase)

                        Button {
                            onCaseSelected(medicalCase)
                        } label: {
                            CompactCaseRow(
                                medicalCase: medicalCase,
                                caseNumber: index + 1,
                                isLocked: !subscriptionManager.isProSubscriber,
                                isCompleted: isCompleted,
                                wasCorrect: historyItem?.wasCorrect
                            )
                        }
                        .disabled(isCompleted)
                    }
                } header: {
                    if groupedCases.count > 1 {
                        HStack {
                            Text(group.subcategory)
                            Spacer()
                            Text("\(group.cases.count) cases")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(displayCategory.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - All Cases View

struct AllCasesView: View {
    let cases: [MedicalCase]
    let isCaseCompleted: (MedicalCase) -> Bool
    let historyEntry: (MedicalCase) -> CaseHistoryEntry?
    let onCaseSelected: (MedicalCase) -> Void

    @State private var searchText = ""
    @State private var sortOption: SortOption = .category

    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }

    enum SortOption: String, CaseIterable {
        case category = "Category"
        case difficulty = "Difficulty"
        case status = "Status"
    }

    private var filteredAndSortedCases: [MedicalCase] {
        var result = cases

        // Filter by search
        if !searchText.isEmpty {
            result = result.filter {
                $0.category.localizedCaseInsensitiveContains(searchText) ||
                $0.hints.first?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Sort
        switch sortOption {
        case .category:
            result.sort { $0.category < $1.category }
        case .difficulty:
            result.sort { $0.difficulty > $1.difficulty }
        case .status:
            result.sort { !isCaseCompleted($0) && isCaseCompleted($1) }
        }

        return result
    }

    var body: some View {
        List {
            // Use offset as ID to avoid duplicates from CaseLibrary
            ForEach(Array(filteredAndSortedCases.enumerated()), id: \.offset) { index, medicalCase in
                let isCompleted = isCaseCompleted(medicalCase)
                let historyItem = historyEntry(medicalCase)

                Button {
                    onCaseSelected(medicalCase)
                } label: {
                    CompactCaseRow(
                        medicalCase: medicalCase,
                        caseNumber: index + 1,
                        isLocked: !subscriptionManager.isProSubscriber,
                        isCompleted: isCompleted,
                        wasCorrect: historyItem?.wasCorrect
                    )
                }
                .disabled(isCompleted)
            }
        }
        .listStyle(.plain)
        .navigationTitle("All Cases")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search cases...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort by", selection: $sortOption) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
    }
}

// MARK: - Compact Case Row

struct CompactCaseRow: View {
    let medicalCase: MedicalCase
    let caseNumber: Int
    var isLocked: Bool = false
    var isCompleted: Bool = false
    var wasCorrect: Bool? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: statusIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(statusColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Case \(caseNumber)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isCompleted ? .secondary : .primary)

                    if isCompleted {
                        Text(medicalCase.diagnosis)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 6) {
                    Text(medicalCase.category)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(getCategoryColor(medicalCase.category).opacity(0.15))
                        .foregroundStyle(getCategoryColor(medicalCase.category))
                        .cornerRadius(4)

                    if !isCompleted && !isLocked {
                        // Difficulty dots
                        HStack(spacing: 2) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(index < min(medicalCase.difficulty, 3) ? Color.orange : Color(.systemGray4))
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                }
            }

            Spacer()

            // Right indicator
            if isLocked && !isCompleted {
                ProBadge(size: .small)
            } else if isCompleted {
                Text("Done")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .opacity(isCompleted ? 0.7 : 1)
    }

    private var statusIcon: String {
        if isCompleted {
            return wasCorrect == true ? "checkmark" : "xmark"
        } else if isLocked {
            return "lock.fill"
        } else {
            return "stethoscope"
        }
    }

    private var statusColor: Color {
        if isCompleted {
            return wasCorrect == true ? .green : .red
        } else if isLocked {
            return .orange
        } else {
            return .blue
        }
    }

    private func getCategoryColor(_ category: String) -> Color {
        // Extract primary category for combos
        let primary = category.components(separatedBy: " / ").first ?? category

        switch primary {
        case "Cardiology": return .red
        case "Neurology": return .purple
        case "Pulmonology": return .blue
        case "Gastroenterology", "Hepatology": return .orange
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
        case "Obstetrics", "Gynecology", "Obstetrics & Gynecology": return .pink
        case "Oncology": return .purple.opacity(0.7)
        case "Dermatology": return .orange.opacity(0.8)
        case "Ophthalmology": return .blue.opacity(0.7)
        case "Pediatrics": return Color(red: 0.4, green: 0.8, blue: 0.9)
        case "Urology": return .cyan.opacity(0.8)
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    CaseBrowserView()
        .modelContainer(for: [CaseHistoryEntry.self], inMemory: true)
}
