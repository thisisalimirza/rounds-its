//
//  PlayerStatsRepair.swift
//  Rounds
//
//  Rebuilds PlayerStats from the case history it summarises.
//
//  PlayerStats is a running total, kept up to date by incrementing it after
//  each game. That makes it the only part of a player's record with no way to
//  recover from being wrong — and it goes wrong routinely:
//
//    * Reinstalling creates a fresh zeroed PlayerStats (seedDataIfNeeded runs
//      before CloudKit has delivered anything). CloudKit then restores the
//      CaseHistoryEntry rows. If it doesn't also restore the old aggregate, or
//      restores it alongside the new one, the totals are lost or split in two.
//    * With two PlayerStats rows in the store, `fetch(...).first` returns an
//      arbitrary one, so the app and the sync can disagree with each other.
//
//  That is not hypothetical: it produced a live account reporting "1 game
//  played, 400 points" on top of 206 games and 45,750 points of real history —
//  wrong on the phone's own Stats tab, and faithfully uploaded to the server.
//
//  CaseHistoryEntry is the durable record: one row per completed game, written
//  on completion and restored by CloudKit. Everything PlayerStats claims about
//  games, wins and score can be recounted from it, so it is recounted here.
//
//  Repair only ever moves a number up. History cannot see games played before
//  CaseHistoryEntry existed, and cannot know about streak freezes, so a stored
//  value that is larger is treated as real.
//

import Foundation
import SwiftData

enum PlayerStatsRepair {

    /// Collapses duplicate stats rows, recounts the totals from history, and
    /// returns the single surviving PlayerStats.
    ///
    /// Cheap enough to call on every sync: it recounts in memory and only
    /// writes when something actually changed.
    @discardableResult
    static func repair(context: ModelContext) -> PlayerStats? {
        guard let all = try? context.fetch(FetchDescriptor<PlayerStats>()),
              let stats = all.first else { return nil }

        var changed = collapseDuplicates(all, into: stats, context: context)

        let history = (try? context.fetch(FetchDescriptor<CaseHistoryEntry>())) ?? []
        if !history.isEmpty {
            changed = recount(history, into: stats) || changed
        }

        if changed { try? context.save() }
        return stats
    }

    // MARK: - Duplicates

    /// Folds any extra PlayerStats rows into the survivor and deletes them.
    private static func collapseDuplicates(
        _ all: [PlayerStats],
        into stats: PlayerStats,
        context: ModelContext
    ) -> Bool {
        guard all.count > 1 else { return false }

        for other in all.dropFirst() {
            stats.gamesPlayed   = max(stats.gamesPlayed,   other.gamesPlayed)
            stats.gamesWon      = max(stats.gamesWon,      other.gamesWon)
            stats.totalScore    = max(stats.totalScore,    other.totalScore)
            stats.currentStreak = max(stats.currentStreak, other.currentStreak)
            stats.maxStreak     = max(stats.maxStreak,     other.maxStreak)

            if stats.guessDistribution.count == other.guessDistribution.count {
                stats.guessDistribution = zip(stats.guessDistribution, other.guessDistribution).map(max)
            }

            if let otherPlayed = other.lastPlayedDate {
                stats.lastPlayedDate = max(stats.lastPlayedDate ?? .distantPast, otherPlayed)
            }
            // Sortable as text because the format is yyyy-MM-dd.
            if let otherDaily = other.lastDailyCasePlayed {
                stats.lastDailyCasePlayed = max(stats.lastDailyCasePlayed ?? "", otherDaily)
            }
            stats.favoriteCaseIDs = Array(Set(stats.favoriteCaseIDs).union(other.favoriteCaseIDs))

            // Freezes take the *minimum*, unlike everything else here. They are
            // spendable rather than earned, and a fresh duplicate starts with
            // one — taking the max would hand back a freeze already used.
            stats.streakFreezesAvailable = min(stats.streakFreezesAvailable, other.streakFreezesAvailable)
            stats.streakFreezeUsedToday = stats.streakFreezeUsedToday || other.streakFreezeUsedToday
            if let otherReset = other.lastStreakFreezeReset {
                stats.lastStreakFreezeReset = max(stats.lastStreakFreezeReset ?? .distantPast, otherReset)
            }

            context.delete(other)
        }

        print("ℹ️ PlayerStatsRepair: collapsed \(all.count) stats rows into one")
        return true
    }

    // MARK: - Recount

    private static func recount(_ history: [CaseHistoryEntry], into stats: PlayerStats) -> Bool {
        var changed = false

        let played = history.count
        let won = history.reduce(0) { $0 + ($1.wasCorrect ? 1 : 0) }
        let score = history.reduce(0) { $0 + $1.score }

        if played > stats.gamesPlayed { stats.gamesPlayed = played; changed = true }
        if won    > stats.gamesWon    { stats.gamesWon    = won;    changed = true }
        if score  > stats.totalScore  { stats.totalScore  = score;  changed = true }

        // Only wins occupy a guess bucket, so the distribution is replaced
        // wholesale when history accounts for more wins than it currently does.
        var buckets = [0, 0, 0, 0, 0]
        for entry in history where entry.wasCorrect {
            let index = min(max(entry.guessCount - 1, 0), buckets.count - 1)
            buckets[index] += 1
        }
        if buckets.reduce(0, +) > stats.guessDistribution.reduce(0, +) {
            stats.guessDistribution = buckets
            changed = true
        }

        if let latest = history.map(\.playedAt).max(),
           latest > (stats.lastPlayedDate ?? .distantPast) {
            stats.lastPlayedDate = latest
            changed = true
        }

        let days = playedDays(history)
        let longest = longestRun(days)
        if longest > stats.maxStreak { stats.maxStreak = longest; changed = true }

        let current = currentRun(days)
        if current > stats.currentStreak { stats.currentStreak = current; changed = true }

        return changed
    }

    // MARK: - Streaks

    /// Distinct calendar days with at least one completed game, ascending.
    private static func playedDays(_ history: [CaseHistoryEntry]) -> [Date] {
        let calendar = Calendar.current
        return Array(Set(history.map { calendar.startOfDay(for: $0.playedAt) })).sorted()
    }

    private static func longestRun(_ days: [Date]) -> Int {
        guard days.count > 1 else { return days.count }
        let calendar = Calendar.current
        var best = 1
        var run = 1
        for i in 1 ..< days.count {
            let gap = calendar.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 0
            if gap == 1 {
                run += 1
                best = max(best, run)
            } else if gap > 1 {
                run = 1
            }
        }
        return best
    }

    /// The run ending on the most recent play day, but only if that day is
    /// today or yesterday — otherwise the streak is already broken and
    /// reporting the old run would revive a streak the player actually lost.
    private static func currentRun(_ days: [Date]) -> Int {
        guard let last = days.last else { return 0 }
        let calendar = Calendar.current
        let sinceLast = calendar.dateComponents([.day], from: last, to: calendar.startOfDay(for: Date())).day ?? 0
        guard sinceLast <= 1 else { return 0 }

        var run = 1
        var index = days.count - 1
        while index > 0 {
            let gap = calendar.dateComponents([.day], from: days[index - 1], to: days[index]).day ?? 0
            if gap == 1 { run += 1; index -= 1 } else { break }
        }
        return run
    }
}
