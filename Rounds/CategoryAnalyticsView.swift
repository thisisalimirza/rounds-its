//
//  CategoryAnalyticsView.swift
//  Rounds
//
//  Pro Feature: Category performance breakdown
//

import SwiftUI
import SwiftData

struct CategoryAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [AchievementProgress]
    @Query(sort: \CaseHistoryEntry.playedAt, order: .reverse) private var historyEntries: [CaseHistoryEntry]
    
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    
    private var categoryPerformance: [CategoryPerformance] {
        var stats: [String: (wins: Int, total: Int)] = [:]
        
        for entry in historyEntries {
            let category = entry.category
            var current = stats[category] ?? (wins: 0, total: 0)
            current.total += 1
            if entry.wasCorrect {
                current.wins += 1
            }
            stats[category] = current
        }
        
        return stats.map { category, data in
            CategoryPerformance(
                category: category,
                wins: data.wins,
                total: data.total
            )
        }
        .sorted { $0.total > $1.total }  // Sort by most played
    }
    
    private var overallStats: (total: Int, wins: Int, accuracy: Double) {
        let total = historyEntries.count
        let wins = historyEntries.filter { $0.wasCorrect }.count
        let accuracy = total > 0 ? Double(wins) / Double(total) * 100 : 0
        return (total, wins, accuracy)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overall Stats Header
                    overallStatsCard
                    
                    // Category Breakdown
                    if categoryPerformance.isEmpty {
                        emptyStateView
                    } else {
                        categoryBreakdown
                    }
                    
                    // Insights
                    if !categoryPerformance.isEmpty {
                        insightsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Category Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Overall Stats Card
    
    private var overallStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overall Performance")
                    .font(.headline)
                Spacer()
                ProBadge(size: .small)
            }
            
            HStack(spacing: 0) {
                StatColumn(
                    value: "\(overallStats.total)",
                    label: "Cases",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 50)
                
                StatColumn(
                    value: "\(overallStats.wins)",
                    label: "Correct",
                    color: .green
                )
                
                Divider()
                    .frame(height: 50)
                
                StatColumn(
                    value: String(format: "%.0f%%", overallStats.accuracy),
                    label: "Accuracy",
                    color: accuracyColor(overallStats.accuracy)
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Category")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(categoryPerformance) { performance in
                    CategoryPerformanceRow(performance: performance)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)
            
            // Strongest category
            if let strongest = categoryPerformance.filter({ $0.total >= 3 }).max(by: { $0.accuracy < $1.accuracy }) {
                InsightCard(
                    icon: "checkmark.seal.fill",
                    title: "Strongest Area",
                    message: "\(strongest.category) at \(String(format: "%.0f%%", strongest.accuracy)) accuracy",
                    color: .green
                )
            }
            
            // Weakest category (needs work)
            if let weakest = categoryPerformance.filter({ $0.total >= 3 && $0.accuracy < 70 }).min(by: { $0.accuracy < $1.accuracy }) {
                InsightCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Needs Practice",
                    message: "\(weakest.category) at \(String(format: "%.0f%%", weakest.accuracy)) accuracy",
                    color: .orange
                )
            }
            
            // Most practiced
            if let mostPlayed = categoryPerformance.first {
                InsightCard(
                    icon: "chart.bar.fill",
                    title: "Most Practiced",
                    message: "\(mostPlayed.category) with \(mostPlayed.total) cases",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("No Data Yet")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Play some cases to see your performance breakdown by category.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func accuracyColor(_ accuracy: Double) -> Color {
        switch accuracy {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Category Performance Model

struct CategoryPerformance: Identifiable {
    let id = UUID()
    let category: String
    let wins: Int
    let total: Int
    
    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(wins) / Double(total) * 100
    }
    
    var status: PerformanceStatus {
        if total < 3 { return .needsData }
        switch accuracy {
        case 80...100: return .strong
        case 60..<80: return .good
        case 40..<60: return .needsWork
        default: return .weak
        }
    }
}

enum PerformanceStatus {
    case strong, good, needsWork, weak, needsData
    
    var label: String {
        switch self {
        case .strong: return "Strong"
        case .good: return "Good"
        case .needsWork: return "Practice"
        case .weak: return "Review"
        case .needsData: return "Building..."
        }
    }
    
    var color: Color {
        switch self {
        case .strong: return .green
        case .good: return .blue
        case .needsWork: return .orange
        case .weak: return .red
        case .needsData: return .gray
        }
    }
}

// MARK: - Category Performance Row

struct CategoryPerformanceRow: View {
    let performance: CategoryPerformance
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Category color dot
                Circle()
                    .fill(categoryColor(for: performance.category))
                    .frame(width: 12, height: 12)
                
                Text(performance.category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Status badge
                Text(performance.status.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(performance.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(performance.status.color.opacity(0.15))
                    .cornerRadius(8)
                
                // Accuracy
                Text(String(format: "%.0f%%", performance.accuracy))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(performance.status.color)
                    .frame(width: 50, alignment: .trailing)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(performance.status.color)
                        .frame(width: geometry.size.width * CGFloat(performance.accuracy / 100), height: 8)
                }
            }
            .frame(height: 8)
            
            // Cases count
            HStack {
                Text("\(performance.wins)/\(performance.total) correct")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func categoryColor(for category: String) -> Color {
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
        case "Pharmacology": return .red.opacity(0.7)
        case "Immunology": return .blue.opacity(0.7)
        case "Genetics": return .purple.opacity(0.7)
        default: return .gray
        }
    }
}

// MARK: - Stat Column

private struct StatColumn: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Insight Card

private struct InsightCard: View {
    let icon: String
    let title: String
    let message: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    CategoryAnalyticsView()
        .modelContainer(for: [AchievementProgress.self, CaseHistoryEntry.self], inMemory: true)
}

