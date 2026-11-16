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
    case dailyCase, randomCase, browseCase, connections, ddxChallenge, ddxBuilder

    var displayName: String {
        switch self {
        case .dailyCase: return "Daily Case"
        case .randomCase: return "Random Case"
        case .browseCase: return "Browse Cases"
        case .connections: return "Case Connections"
        case .ddxChallenge: return "Differential Challenge"
        case .ddxBuilder: return "Differential Builder"
        }
    }

    var icon: String {
        switch self {
        case .dailyCase, .randomCase, .browseCase: return "cross.case.fill"
        case .connections: return "square.grid.2x2.fill"
        case .ddxChallenge: return "list.bullet.rectangle.portrait.fill"
        case .ddxBuilder: return "stethoscope"
        }
    }

    /// Whether a miss from this source is a genuine wrong answer (vs. a
    /// self-flagged uncertainty signal like using the Differential Builder).
    var isWrongAnswer: Bool { self != .ddxBuilder }
}

/// How a case play was started. Stored on `CaseHistoryEntry.playSource`.
///
/// `CaseContext.random` is also used for a Browse search with no category, so
/// context alone cannot tell a Random Case play from a Browse play.
nonisolated enum PlayOrigin: String, Sendable {
    case daily
    case random
    case browse

    var modeName: String { rawValue }

    /// `MissSource` raw value for a stored origin.
    ///
    /// Daily stays daily. An explicit random stays random. Anything else that
    /// is not daily — browse, archive, an empty stored source — is browse.
    /// Existing server rows are not rewritten.
    static func missSourceRaw(stored: String, wasDailyCase: Bool) -> String {
        switch stored {
        case PlayOrigin.daily.rawValue, "dailyCase":
            return "dailyCase"
        case PlayOrigin.browse.rawValue, "browseCase":
            return "browseCase"
        case PlayOrigin.random.rawValue, "randomCase":
            return "randomCase"
        case "connections", "ddxChallenge", "ddxBuilder":
            return stored
        default:
            return wasDailyCase ? "dailyCase" : "browseCase"
        }
    }
}

/// When a finished case belongs in Weak Spots.
///
/// Same numbers as `roundsapp-landing` `lib/game/weak-spot.ts`: a loss always
/// counts, and a win counts when a second clue was opened (`hintsUsed` >= 2,
/// which includes the free first clue), four clues were opened, four guesses
/// were used (the correct guess counts), or all five clues were opened.
/// `hintsUsed` of 4 and 5 sit inside `>= 2`. They stay so this matches the web
/// expression exactly.
nonisolated enum WeakSpotRule {
    /// A second clue. `hintsUsed` includes the free first clue.
    static let hintsUsed = 2
    /// Four clues. Subsumed by `hintsUsed`, kept to match the web rule.
    static let manyClues = 4
    /// Guesses used, including the correct one.
    static let guesses = 4
    /// All five clues open.
    static let allClues = 5

    static func neededHelp(hintsUsed: Int, guesses: Int) -> Bool {
        let openedAnother = hintsUsed >= Self.hintsUsed
        let many = hintsUsed >= manyClues
        let close = guesses >= Self.guesses || hintsUsed >= allClues
        return openedAnother || many || close
    }

    static func shouldLog(diagnosis: String, won: Bool, hintsUsed: Int, guesses: Int) -> Bool {
        guard !diagnosis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if !won { return true }
        return neededHelp(hintsUsed: hintsUsed, guesses: guesses)
    }

    /// Qualifying wins store `needed_help`. Losses store an empty detail.
    static func detail(won: Bool, hintsUsed: Int, guesses: Int) -> String {
        won && neededHelp(hintsUsed: hintsUsed, guesses: guesses) ? "needed_help" : ""
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
    ///
    /// One row per diagnosis, compared as lower(trim(item)), per local calendar
    /// day. A row that is already there is left alone: reviewed stays reviewed,
    /// and detail is not rewritten. Case plays store dailyCase, randomCase, or
    /// browseCase, and the caller passes detail (`needed_help` or empty).
    @discardableResult
    static func record(
        _ context: ModelContext,
        source: MissSource,
        topic: String,
        item: String,
        detail: String = "",
        at date: Date = Date()
    ) -> Bool {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedItem = item.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedItem.isEmpty else { return false }
        let needle = trimmedItem.lowercased()
        let calendar = Calendar.current
        let existing = (try? context.fetch(FetchDescriptor<MissedItem>())) ?? []
        if existing.contains(where: {
            $0.item.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == needle
                && calendar.isDate($0.timestamp, inSameDayAs: date)
        }) {
            return false
        }
        let row = MissedItem(
            source: source,
            topic: trimmedTopic.isEmpty ? "General" : trimmedTopic,
            item: trimmedItem,
            detail: detail
        )
        row.timestamp = date
        context.insert(row)
        try? context.save()
        return true
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
