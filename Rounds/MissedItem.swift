//
//  MissedItem.swift
//  Rounds
//
//  A universal log of everything the user gets wrong across every mode.
//  This is the canonical "knowledge gap" stream — later consumed to build
//  tailored study plans (LLM or rules-based) and surfaced in Weak Spots.
//

import Foundation
import SwiftData

/// Where a miss happened.
enum MissSource: String, CaseIterable, Codable {
    case dailyCase, randomCase, browseCase, connections, ddxChallenge

    var displayName: String {
        switch self {
        case .dailyCase: return "Daily Case"
        case .randomCase: return "Random Case"
        case .browseCase: return "Browse Cases"
        case .connections: return "Case Connections"
        case .ddxChallenge: return "Differential Challenge"
        }
    }

    var icon: String {
        switch self {
        case .dailyCase, .randomCase, .browseCase: return "cross.case.fill"
        case .connections: return "square.grid.2x2.fill"
        case .ddxChallenge: return "list.bullet.rectangle.portrait.fill"
        }
    }
}

@Model
final class MissedItem {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    /// Raw value of `MissSource`.
    var source: String = ""
    /// Grouping key — specialty / category / chief complaint.
    var topic: String = ""
    /// The specific missed thing — diagnosis, concept, etc.
    var item: String = ""
    /// Optional extra context (e.g. "missed can't-miss").
    var detail: String = ""
    var reviewed: Bool = false

    init(source: MissSource, topic: String, item: String, detail: String = "") {
        self.id = UUID()
        self.timestamp = Date()
        self.source = source.rawValue
        self.topic = topic
        self.item = item
        self.detail = detail
        self.reviewed = false
    }

    var sourceKind: MissSource? { MissSource(rawValue: source) }
}

// MARK: - Logging

enum MistakeLog {
    /// Record a single miss. Safe to call from any view that has a ModelContext.
    static func record(_ context: ModelContext, source: MissSource, topic: String, item: String, detail: String = "") {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedItem = item.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedItem.isEmpty else { return }
        context.insert(MissedItem(source: source, topic: trimmedTopic.isEmpty ? "General" : trimmedTopic, item: trimmedItem, detail: detail))
        try? context.save()
    }
}

// MARK: - Aggregation (pure helpers for display / future study plans)

enum MissAggregate {
    struct Bucket: Identifiable {
        let id = UUID()
        let key: String
        let count: Int
        var subtitle: String? = nil
        var lastSeen: Date? = nil
    }

    static func byTopic(_ items: [MissedItem]) -> [Bucket] {
        Dictionary(grouping: items, by: { $0.topic })
            .map { Bucket(key: $0.key, count: $0.value.count, lastSeen: $0.value.map(\.timestamp).max()) }
            .sorted { $0.count > $1.count }
    }

    static func byItem(_ items: [MissedItem]) -> [Bucket] {
        Dictionary(grouping: items, by: { $0.item })
            .map { group in
                Bucket(key: group.key, count: group.value.count,
                       subtitle: group.value.first?.topic,
                       lastSeen: group.value.map(\.timestamp).max())
            }
            .sorted { $0.count > $1.count }
    }

    static func bySource(_ items: [MissedItem]) -> [Bucket] {
        Dictionary(grouping: items, by: { $0.sourceKind?.displayName ?? "Other" })
            .map { Bucket(key: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
}
