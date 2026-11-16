//
//  ProgressMerge.swift
//  Rounds
//
//  Pure merge rules shared by the client and mirrored in
//  supabase/schema_sync_v2.sql. Kept free of SwiftData and Supabase so the
//  unit tests can pin the rules down without a device.
//
//  The streak follows the later calendar day of play, the same way
//  last_daily_case_played already does. A phone that merely synced more
//  recently must not overwrite a streak earned on a later day.
//

import Foundation

nonisolated enum ProgressMerge {

    /// Streak that belongs to the later day of play.
    ///
    /// A missing date loses to a present one. The same calendar day keeps the
    /// higher streak, because two devices that both played today are describing
    /// the same day and the smaller number is a partial upload.
    static func currentStreak(
        localDay: Date?,
        localStreak: Int,
        remoteDay: Date?,
        remoteStreak: Int,
        calendar: Calendar = .current
    ) -> Int {
        switch (localDay, remoteDay) {
        case (nil, nil):
            return max(0, max(localStreak, remoteStreak))
        case (nil, _?):
            return max(0, remoteStreak)
        case (_?, nil):
            return max(0, localStreak)
        case let (local?, remote?):
            let localStart = calendar.startOfDay(for: local)
            let remoteStart = calendar.startOfDay(for: remote)
            if localStart > remoteStart { return max(0, localStreak) }
            if remoteStart > localStart { return max(0, remoteStreak) }
            return max(0, max(localStreak, remoteStreak))
        }
    }

    /// Later `yyyy-MM-dd` string. Lexical order matches calendar order for this format.
    static func laterDayString(_ lhs: String?, _ rhs: String?) -> String? {
        switch (lhs, rhs) {
        case (nil, nil): return nil
        case (nil, let rhs?): return rhs
        case (let lhs?, nil): return lhs
        case let (lhs?, rhs?): return lhs >= rhs ? lhs : rhs
        }
    }

    /// Device-calendar day, never UTC. Streaks and the daily case roll over at local midnight.
    static func dayString(from date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Parses a `yyyy-MM-dd` (or a timestamp prefixed with one) in the device calendar.
    static func date(fromDayString raw: String, calendar: Calendar = .current) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 else { return nil }
        let day = String(trimmed.prefix(10))
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: day)
    }

    /// Once a miss is reviewed on any device, it stays reviewed.
    static func reviewed(_ local: Bool, _ remote: Bool) -> Bool {
        local || remote
    }
}

/// One definition of "this freeze can be spent", used by both the manual
/// save and the automatic bridge. A freeze covers exactly one missed day
/// (last play was the day before yesterday) and only one freeze exists per week.
nonisolated enum StreakFreezeRules {
    static func canSpend(
        isPro: Bool,
        currentStreak: Int,
        freezesAvailable: Int,
        usedToday: Bool,
        lastPlayed: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard isPro, currentStreak > 0, freezesAvailable > 0, !usedToday, let lastPlayed else {
            return false
        }
        let today = calendar.startOfDay(for: now)
        let last = calendar.startOfDay(for: lastPlayed)
        let gap = calendar.dateComponents([.day], from: last, to: today).day ?? 0
        return gap == 2
    }
}

/// Set when a freeze was spent on this phone before the server confirmed it.
/// The next sync asks the server to spend once; the server refuses a second spend.
nonisolated enum StreakFreezeSync {
    static let pendingKey = "streakFreeze.pendingSpend.v1"

    static var isPending: Bool {
        UserDefaults.standard.bool(forKey: pendingKey)
    }

    static func markPending() {
        UserDefaults.standard.set(true, forKey: pendingKey)
    }

    static func clearPending() {
        UserDefaults.standard.set(false, forKey: pendingKey)
    }
}
