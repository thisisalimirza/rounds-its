//
//  SyncAndGateTests.swift
//  RoundsTests
//
//  Merge rules, streak freezes, and the account-gate decision. These types
//  don't touch SwiftData or the network.
//

import Foundation
import Testing
@testable import Rounds

struct SyncAndGateTests {

    private func pacific() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }

    private func day(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test func laterPlayDayKeepsItsStreakEvenWhenSmaller() {
        let calendar = pacific()
        let older = day(2026, 3, 10, calendar: calendar)
        let newer = day(2026, 3, 12, calendar: calendar)
        let streak = ProgressMerge.currentStreak(
            localDay: older, localStreak: 40,
            remoteDay: newer, remoteStreak: 3,
            calendar: calendar
        )
        #expect(streak == 3)

        let reverse = ProgressMerge.currentStreak(
            localDay: newer, localStreak: 3,
            remoteDay: older, remoteStreak: 40,
            calendar: calendar
        )
        #expect(reverse == 3)
    }

    @Test func sameDayKeepsTheHigherStreak() {
        let calendar = pacific()
        let today = day(2026, 3, 12, calendar: calendar)
        let streak = ProgressMerge.currentStreak(
            localDay: today, localStreak: 4,
            remoteDay: today, remoteStreak: 9,
            calendar: calendar
        )
        #expect(streak == 9)
    }

    @Test func missingDayLosesToAPresentDay() {
        let calendar = pacific()
        let played = day(2026, 3, 12, calendar: calendar)
        #expect(ProgressMerge.currentStreak(
            localDay: nil, localStreak: 8,
            remoteDay: played, remoteStreak: 2,
            calendar: calendar
        ) == 2)
        #expect(ProgressMerge.currentStreak(
            localDay: nil, localStreak: 8,
            remoteDay: nil, remoteStreak: 2,
            calendar: calendar
        ) == 8)
    }

    @Test func dayStringUsesTheDeviceCalendarNotUTC() {
        let calendar = pacific()
        // 02:00 UTC on the 15th is still the 14th in Los Angeles.
        let instant = Date(timeIntervalSince1970: 1_773_540_000)
        #expect(ProgressMerge.dayString(from: instant, calendar: calendar) == "2026-03-14")
        let parsed = ProgressMerge.date(fromDayString: "2026-03-14T00:00:00Z", calendar: calendar)
        #expect(parsed == day(2026, 3, 14, calendar: calendar))
    }

    @Test func laterDayStringAndReviewedFlag() {
        #expect(ProgressMerge.laterDayString("2026-03-01", "2026-03-02") == "2026-03-02")
        #expect(ProgressMerge.laterDayString(nil, "2026-03-02") == "2026-03-02")
        #expect(ProgressMerge.reviewed(false, true))
        #expect(ProgressMerge.reviewed(true, false))
        #expect(!ProgressMerge.reviewed(false, false))
    }

    @Test func freezeCoversExactlyOneMissedDay() {
        let calendar = pacific()
        let today = day(2026, 3, 12, calendar: calendar)
        let yesterday = day(2026, 3, 11, calendar: calendar)
        let twoAgo = day(2026, 3, 10, calendar: calendar)
        let threeAgo = day(2026, 3, 9, calendar: calendar)

        #expect(StreakFreezeRules.canSpend(
            isPro: true, currentStreak: 5, freezesAvailable: 1, usedToday: false,
            lastPlayed: twoAgo, now: today, calendar: calendar
        ))
        #expect(!StreakFreezeRules.canSpend(
            isPro: true, currentStreak: 5, freezesAvailable: 1, usedToday: false,
            lastPlayed: yesterday, now: today, calendar: calendar
        ))
        #expect(!StreakFreezeRules.canSpend(
            isPro: true, currentStreak: 5, freezesAvailable: 1, usedToday: false,
            lastPlayed: threeAgo, now: today, calendar: calendar
        ))
        #expect(!StreakFreezeRules.canSpend(
            isPro: false, currentStreak: 5, freezesAvailable: 1, usedToday: false,
            lastPlayed: twoAgo, now: today, calendar: calendar
        ))
        #expect(!StreakFreezeRules.canSpend(
            isPro: true, currentStreak: 5, freezesAvailable: 1, usedToday: true,
            lastPlayed: twoAgo, now: today, calendar: calendar
        ))
        #expect(!StreakFreezeRules.canSpend(
            isPro: true, currentStreak: 0, freezesAvailable: 1, usedToday: false,
            lastPlayed: twoAgo, now: today, calendar: calendar
        ))
    }

    private func gate(
        anonymous: Bool = true,
        online: Bool = true,
        session: Bool = true,
        confirmed: Bool = true,
        cohort: AccountCohort = .trial,
        cases: Int = 0,
        enabled: Bool = true,
        grandfathered: Bool = true,
        freeCases: Int = 3,
        playing: Bool = false,
        nudged: Bool = false
    ) -> AccountGateKind {
        AccountGatePolicy.decision(AccountGateContext(
            isAnonymous: anonymous,
            isOnline: online,
            hasSession: session,
            backfillConfirmed: confirmed,
            cohort: cohort,
            casesCompleted: cases,
            gateEnabled: enabled,
            grandfatheredEnabled: grandfathered,
            freeCases: freeCases,
            playingCase: playing,
            nudgeAlreadyShown: nudged
        ))
    }

    @Test func grandfatheredGateWaitsForAConfirmedOnlineBackup() {
        #expect(gate(cohort: .grandfathered, cases: 40, confirmed: false) == .none)
        #expect(gate(cohort: .grandfathered, cases: 40, online: false) == .none)
        #expect(gate(cohort: .grandfathered, cases: 40, playing: true) == .none)
        #expect(gate(cohort: .grandfathered, cases: 40) == .grandfathered)
    }

    @Test func turningOffGrandfatheredDoesNotDumpThemIntoTheTrial() {
        #expect(gate(cohort: .grandfathered, cases: 40, grandfathered: false) == .none)
    }

    @Test func trialGateAfterTheFreeCasesAndNotMidCaseOrOffline() {
        #expect(gate(cases: 2) == .nudge)
        #expect(gate(cases: 2, nudged: true) == .none)
        #expect(gate(cases: 3) == .trialLimit)
        #expect(gate(cases: 3, online: false) == .none)
        #expect(gate(cases: 3, playing: true) == .none)
        #expect(gate(cases: 3, session: false) == .none)
        #expect(gate(cases: 3, anonymous: false) == .none)
        #expect(gate(cases: 3, enabled: false) == .none)
    }

    @Test func emailHintsAcceptAnyAddressAndNameSchoolAndTypos() {
        #expect(EmailAddressHints.isValid("a@b.c"))
        #expect(!EmailAddressHints.isValid("not-an-email"))
        #expect(EmailAddressHints.tone(of: "student@med.nyu.edu") == .school)
        #expect(EmailAddressHints.tone(of: "me@ox.ac.uk") == .school)
        #expect(EmailAddressHints.tone(of: "me@gmail.com") == .personal)
        #expect(EmailAddressHints.tone(of: "me@hospital.org") == .other)
        #expect(EmailAddressHints.suggestion(for: "Me@Gmial.com") == "me@gmail.com")
    }

    @Test func aCleanWinIsNotAWeakSpot() {
        #expect(!WeakSpotRule.shouldLog(won: true, hintsUsed: 1, guesses: 1))
        #expect(!WeakSpotRule.neededHelp(hintsUsed: 1, guesses: 1))
    }

    @Test func aWinNeedsHelpAfterAnExtraHintOrASecondGuess() {
        #expect(WeakSpotRule.extraHints == 1)
        #expect(WeakSpotRule.guesses == 2)
        #expect(WeakSpotRule.shouldLog(won: true, hintsUsed: 2, guesses: 1))
        #expect(WeakSpotRule.shouldLog(won: true, hintsUsed: 1, guesses: 2))
        #expect(WeakSpotRule.shouldLog(won: false, hintsUsed: 1, guesses: 1))
    }

    @Test func browsePlaysAreBrowseAndOldHistoryStaysRandom() {
        #expect(PlayOrigin.missSourceRaw(stored: "browse", wasDailyCase: false) == "browseCase")
        #expect(PlayOrigin.missSourceRaw(stored: "daily", wasDailyCase: true) == "dailyCase")
        #expect(PlayOrigin.missSourceRaw(stored: "random", wasDailyCase: false) == "randomCase")
        #expect(PlayOrigin.missSourceRaw(stored: "", wasDailyCase: false) == "randomCase")
        #expect(PlayOrigin.missSourceRaw(stored: "", wasDailyCase: true) == "dailyCase")
    }
}
