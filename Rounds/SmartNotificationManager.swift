//
//  SmartNotificationManager.swift
//  Rounds
//
//  Intelligent notification system with personalization, variety, and context-awareness
//

import Foundation
import UserNotifications
import SwiftData

// MARK: - Notification Intensity Level

enum NotificationIntensity: String, CaseIterable, Codable {
    case chill = "chill"
    case normal = "normal"
    case intense = "intense"

    var displayName: String {
        switch self {
        case .chill: return "Chill"
        case .normal: return "Normal"
        case .intense: return "Intense"
        }
    }

    var description: String {
        switch self {
        case .chill: return "Gentle, occasional reminders"
        case .normal: return "Daily reminders to stay on track"
        case .intense: return "Aggressive motivation for serious streakers"
        }
    }

    var icon: String {
        switch self {
        case .chill: return "leaf.fill"
        case .normal: return "bell.fill"
        case .intense: return "flame.fill"
        }
    }
}

// MARK: - Notification Context

struct NotificationContext {
    let currentStreak: Int
    let maxStreak: Int
    let gamesPlayed: Int
    let gamesWon: Int
    let daysSinceLastPlay: Int
    let hasPlayedToday: Bool
    let unlockedAchievements: Int
    let totalAchievements: Int

    var streakTier: StreakTier {
        switch currentStreak {
        case 0: return .none
        case 1...3: return .beginner
        case 4...7: return .building
        case 8...14: return .committed
        case 15...30: return .dedicated
        case 31...60: return .expert
        default: return .legend
        }
    }

    var winRate: Int {
        guard gamesPlayed > 0 else { return 0 }
        return Int((Double(gamesWon) / Double(gamesPlayed)) * 100)
    }

    enum StreakTier {
        case none, beginner, building, committed, dedicated, expert, legend
    }
}

// MARK: - Smart Notification Manager

class SmartNotificationManager {
    static let shared = SmartNotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let dailyIdentifier = "rounds.daily.smart"

    // UserDefaults keys
    private let intensityKey = "notification_intensity"
    private let lastMessageIndexKey = "notification_lastMessageIndex"

    private init() {}

    // MARK: - Public Interface

    var currentIntensity: NotificationIntensity {
        get {
            guard let raw = UserDefaults.standard.string(forKey: intensityKey),
                  let intensity = NotificationIntensity(rawValue: raw) else {
                return .normal
            }
            return intensity
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: intensityKey)
        }
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// Schedule smart daily notification with context-aware messaging
    func scheduleSmartReminder(
        hour: Int = 19,
        minute: Int = 0,
        context: NotificationContext? = nil
    ) {
        // Remove existing
        center.removePendingNotificationRequests(withIdentifiers: [dailyIdentifier])

        let content = UNMutableNotificationContent()
        let message = generateMessage(context: context, intensity: currentIntensity)

        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.badge = 1

        // Add category for potential future actions
        content.categoryIdentifier = "DAILY_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: dailyIdentifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("SmartNotificationManager: Failed to schedule - \(error)")
            } else {
                print("SmartNotificationManager: Scheduled smart reminder for \(hour):\(String(format: "%02d", minute))")
            }
        }
    }

    /// Schedule a one-time notification (for streak warnings, achievements, etc.)
    func scheduleOneTimeNotification(
        identifier: String,
        title: String,
        body: String,
        delay: TimeInterval
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    /// Schedule streak warning notification for evening before streak expires
    func scheduleStreakWarning(currentStreak: Int, hour: Int = 21) {
        guard currentStreak > 0 else { return }

        let identifier = "rounds.streak.warning"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "⚠️ Streak Alert!"
        content.body = "Your \(currentStreak)-day streak expires at midnight! Play now to keep it alive."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    // MARK: - Message Generation

    private func generateMessage(context: NotificationContext?, intensity: NotificationIntensity) -> (title: String, body: String) {
        // If no context, use generic messages
        guard let ctx = context else {
            return getGenericMessage(intensity: intensity)
        }

        // Choose message based on context
        if ctx.daysSinceLastPlay >= 3 {
            return getWinBackMessage(context: ctx, intensity: intensity)
        } else if ctx.hasPlayedToday {
            return getAlreadyPlayedMessage(context: ctx)
        } else if ctx.currentStreak > 0 {
            return getStreakMessage(context: ctx, intensity: intensity)
        } else {
            return getStartStreakMessage(intensity: intensity)
        }
    }

    // MARK: - Message Templates

    private func getStreakMessage(context: NotificationContext, intensity: NotificationIntensity) -> (title: String, body: String) {
        let streak = context.currentStreak

        // Milestone celebrations
        if [7, 14, 21, 30, 50, 100].contains(streak) {
            return getMilestoneMessage(streak: streak)
        }

        // Tier-based messages
        switch context.streakTier {
        case .beginner:
            return getBeginnerStreakMessages(streak: streak, intensity: intensity).randomElement()!
        case .building:
            return getBuildingStreakMessages(streak: streak, intensity: intensity).randomElement()!
        case .committed:
            return getCommittedStreakMessages(streak: streak, intensity: intensity).randomElement()!
        case .dedicated:
            return getDedicatedStreakMessages(streak: streak, intensity: intensity).randomElement()!
        case .expert, .legend:
            return getLegendStreakMessages(streak: streak, intensity: intensity).randomElement()!
        case .none:
            return getStartStreakMessage(intensity: intensity)
        }
    }

    private func getMilestoneMessage(streak: Int) -> (title: String, body: String) {
        switch streak {
        case 7:
            return ("🎉 One Week Streak!", "7 days strong! You're building a real habit.")
        case 14:
            return ("🏆 Two Week Champion!", "14 days! Your diagnostic skills are sharpening.")
        case 21:
            return ("⭐️ 21 Days - Habit Formed!", "They say it takes 21 days to form a habit. You did it!")
        case 30:
            return ("🔥 ONE MONTH STREAK!", "30 days of medical mastery. You're unstoppable!")
        case 50:
            return ("👑 50 Day Legend!", "Half a century of streaks. Absolutely incredible!")
        case 100:
            return ("💯 100 DAYS!", "Triple digits! You're in the medical elite now.")
        default:
            return ("🔥 Keep Going!", "Your \(streak)-day streak is impressive!")
        }
    }

    private func getBeginnerStreakMessages(streak: Int, intensity: NotificationIntensity) -> [(title: String, body: String)] {
        switch intensity {
        case .chill:
            return [
                ("Day \(streak) 🌱", "Small steps lead to big results. Play when you're ready."),
                ("Streak: \(streak)", "You're doing great. Keep it going at your own pace."),
                ("🩺 Quick Case?", "A few minutes of practice goes a long way.")
            ]
        case .normal:
            return [
                ("🔥 Day \(streak)!", "Keep the momentum going with today's case."),
                ("Streak Alert: \(streak) days", "Don't break the chain! Play today's case."),
                ("📈 Building Momentum", "Day \(streak) of your streak. Let's make it \(streak + 1)!")
            ]
        case .intense:
            return [
                ("⚡️ DAY \(streak) - NO EXCUSES!", "Champions don't skip days. Get in there!"),
                ("🔥 STREAK MODE: \(streak)", "You started this. Now FINISH today's case!"),
                ("💪 \(streak) AND COUNTING!", "Every day counts. Don't let yesterday's work go to waste!")
            ]
        }
    }

    private func getBuildingStreakMessages(streak: Int, intensity: NotificationIntensity) -> [(title: String, body: String)] {
        switch intensity {
        case .chill:
            return [
                ("\(streak) Days Strong 💪", "You're building something great. Keep it up!"),
                ("Week \(streak / 7)+ Streak", "Consistency is key. You've got this."),
                ("🎯 Almost a Week!", "Just a bit more to hit that weekly milestone.")
            ]
        case .normal:
            return [
                ("🔥 \(streak)-Day Streak!", "You're getting serious! Don't stop now."),
                ("Building Habits 📚", "\(streak) days in. This is becoming routine!"),
                ("Momentum Building!", "Day \(streak). Your future self will thank you.")
            ]
        case .intense:
            return [
                ("⚡️ \(streak) DAYS STRONG!", "You're in the zone! Keep that energy!"),
                ("NO BREAKS! 🔥", "\(streak) days of grinding. Today is no different!"),
                ("UNSTOPPABLE! 💥", "Day \(streak). Nothing can stop you now!")
            ]
        }
    }

    private func getCommittedStreakMessages(streak: Int, intensity: NotificationIntensity) -> [(title: String, body: String)] {
        switch intensity {
        case .chill:
            return [
                ("\(streak) Days 🌟", "You're officially committed. Impressive!"),
                ("Two Weeks+!", "This streak is becoming part of your routine."),
                ("Consistent! 📈", "\(streak) days of growth. Well done!")
            ]
        case .normal:
            return [
                ("🏆 \(streak)-Day Warrior!", "Over a week strong. You're in the elite now!"),
                ("Serious Streak! 🔥", "\(streak) days! Most people quit by now."),
                ("Dedication Pays Off", "Day \(streak). Your consistency is inspiring!")
            ]
        case .intense:
            return [
                ("💪 \(streak) DAYS - ELITE STATUS!", "You're outworking 90% of players!"),
                ("WARRIOR MODE! ⚔️", "\(streak) days! This is what champions do!"),
                ("RELENTLESS! 🔥🔥", "Day \(streak). You don't know the word 'quit'!")
            ]
        }
    }

    private func getDedicatedStreakMessages(streak: Int, intensity: NotificationIntensity) -> [(title: String, body: String)] {
        switch intensity {
        case .chill:
            return [
                ("\(streak) Days! 👏", "A month+ of dedication. You should be proud."),
                ("Legendary Progress", "Your commitment is remarkable. Keep going!"),
                ("Master in Training 🎓", "\(streak) days of honing your skills.")
            ]
        case .normal:
            return [
                ("🔥 \(streak)-Day Legend!", "A month of daily practice. You're exceptional!"),
                ("Elite Dedication! ⭐️", "\(streak) days! You're in rare company."),
                ("Medical Master 🏅", "Day \(streak). Your skills are getting sharp!")
            ]
        case .intense:
            return [
                ("👑 \(streak) DAYS - ROYALTY!", "You're medical ROYALTY at this point!"),
                ("LEGENDARY! 🔥🔥🔥", "\(streak) days of PURE DEDICATION!"),
                ("UNSTOPPABLE FORCE! ⚡️", "Day \(streak). You're built different!")
            ]
        }
    }

    private func getLegendStreakMessages(streak: Int, intensity: NotificationIntensity) -> [(title: String, body: String)] {
        switch intensity {
        case .chill:
            return [
                ("\(streak) Days - Legend 👑", "You've achieved what few ever will."),
                ("Incredible Journey", "\(streak) days. You're an inspiration."),
                ("Master Status 🏆", "Your dedication is truly remarkable.")
            ]
        case .normal:
            return [
                ("🏆 \(streak)-DAY LEGEND!", "You're in the top 1% of all players!"),
                ("GOAT Status! 🐐", "\(streak) days! You're a medical trivia GOAT!"),
                ("Hall of Fame! ⭐️", "Day \(streak). You belong in the hall of fame!")
            ]
        case .intense:
            return [
                ("👑👑👑 \(streak) DAYS!", "BOW DOWN TO THE STREAK MONARCH!"),
                ("ABSOLUTE LEGEND! 🔥", "\(streak) DAYS OF PURE DOMINATION!"),
                ("IMMORTAL STATUS! ⚡️", "Day \(streak). You've transcended mortal limits!")
            ]
        }
    }

    private func getStartStreakMessage(intensity: NotificationIntensity) -> (title: String, body: String) {
        switch intensity {
        case .chill:
            return [
                ("Start Fresh 🌱", "Every streak starts with day one. No pressure!"),
                ("New Beginning", "Today's a great day to start a new streak."),
                ("🩺 Quick Case?", "A few minutes of practice when you have time.")
            ].randomElement()!
        case .normal:
            return [
                ("Start Your Streak! 🔥", "Day 1 awaits. Let's build something great!"),
                ("Fresh Start! 💪", "New streak opportunity. Make today count!"),
                ("Begin Again! 📈", "Every champion started at zero. Your turn!")
            ].randomElement()!
        case .intense:
            return [
                ("NO MORE EXCUSES! ⚡️", "Start your streak TODAY. No more waiting!"),
                ("DAY 1 STARTS NOW! 🔥", "Stop putting it off. GET IN THERE!"),
                ("TIME TO DOMINATE! 💪", "Zero to hero starts with ONE case!")
            ].randomElement()!
        }
    }

    private func getWinBackMessage(context: NotificationContext, intensity: NotificationIntensity) -> (title: String, body: String) {
        let days = context.daysSinceLastPlay

        switch intensity {
        case .chill:
            return [
                ("We Miss You! 🩺", "It's been \(days) days. Play when you're ready!"),
                ("Welcome Back?", "Your medical knowledge misses you. No rush though!"),
                ("Been a While! 👋", "Drop by when you have a moment.")
            ].randomElement()!
        case .normal:
            return [
                ("Come Back! 🔥", "It's been \(days) days. Your skills are getting rusty!"),
                ("We Miss You! 😢", "The cases miss you! Time to diagnose again?"),
                ("Rusty Skills Alert! ⚠️", "\(days) days away. Time to sharpen up!")
            ].randomElement()!
        case .intense:
            return [
                ("WHERE ARE YOU?! 😤", "\(days) DAYS?! Your competition isn't taking breaks!"),
                ("SKILLS DECLINING! ⚠️", "Every day away makes you weaker. GET BACK!"),
                ("DON'T QUIT! 🔥", "\(days) days is too long. Champions don't disappear!")
            ].randomElement()!
        }
    }

    private func getAlreadyPlayedMessage(context: NotificationContext) -> (title: String, body: String) {
        return [
            ("Great Job Today! ✅", "You already played! See you tomorrow."),
            ("Streak Secured! 🔥", "Today's done. Rest up for tomorrow's case!"),
            ("Champion! 🏆", "You showed up today. That's what matters!")
        ].randomElement()!
    }

    private func getGenericMessage(intensity: NotificationIntensity) -> (title: String, body: String) {
        switch intensity {
        case .chill:
            return [
                ("Daily Case Ready 🩺", "A new medical mystery awaits when you're ready."),
                ("Practice Time?", "Sharpen your diagnostic skills at your own pace."),
                ("New Case Available", "Today's case is waiting. No rush!")
            ].randomElement()!
        case .normal:
            return [
                ("🔥 Daily Case Time!", "Test your diagnostic skills with today's case."),
                ("New Challenge! 🧠", "A fresh case awaits. Can you solve it?"),
                ("Keep Learning! 📚", "Today's case is ready. Make it count!")
            ].randomElement()!
        case .intense:
            return [
                ("CASE TIME! ⚡️", "No excuses! Get in and diagnose!"),
                ("LET'S GO! 🔥", "Today's case won't solve itself!"),
                ("GRIND TIME! 💪", "Every case makes you sharper. DO IT!")
            ].randomElement()!
        }
    }
}

// MARK: - Helper to build context from PlayerStats

extension SmartNotificationManager {
    /// Build notification context from PlayerStats
    static func buildContext(from stats: PlayerStats, achievements: AchievementProgress?) -> NotificationContext {
        let daysSinceLastPlay: Int
        if let lastPlayed = stats.lastPlayedDate {
            daysSinceLastPlay = Calendar.current.dateComponents([.day], from: lastPlayed, to: Date()).day ?? 0
        } else {
            daysSinceLastPlay = 999 // Never played
        }

        return NotificationContext(
            currentStreak: stats.currentStreak,
            maxStreak: stats.maxStreak,
            gamesPlayed: stats.gamesPlayed,
            gamesWon: stats.gamesWon,
            daysSinceLastPlay: daysSinceLastPlay,
            hasPlayedToday: stats.hasPlayedDailyCaseToday(),
            unlockedAchievements: achievements?.unlockedAchievements.count ?? 0,
            totalAchievements: Achievement.allCases.count
        )
    }
}
