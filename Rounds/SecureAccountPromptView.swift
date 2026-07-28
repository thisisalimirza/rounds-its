//
//  SecureAccountPromptView.swift
//  Rounds
//
//  Shown after a meaningful moment (finishing a case) to invite an anonymous
//  user to secure their account so Pro and progress survive a reinstall or a
//  new phone.
//
//  Presented full height rather than as a half sheet. As a medium detent it
//  opened with "Maybe later" as the most prominent control and the actual
//  sign-in options cut off below the fold, which made dismissing the obvious
//  move. Now the stakes come first, the options are fully visible, and the
//  dismiss is deliberately quiet — though always available, since this must
//  never feel like a trap.
//

import SwiftUI

struct SecureAccountPromptView: View {
    @Environment(\.dismiss) private var dismiss

    /// Why we are asking. Chooses the headline, so the sheet opens by naming
    /// the thing that just happened rather than opening with a policy.
    var reason: AccountManager.SecurePromptReason = .generic
    var currentStreak: Int = 0
    var casesPlayed: Int = 0
    var hasPro: Bool = false
    var schoolName: String? = nil

    private var headline: String {
        switch reason {
        case .bestStreak:  return "Your best streak yet"
        case .milestone:   return "\(casesPlayed) cases in"
        case .leaderboard: return "You're on the board"
        case .proUnlocked: return "Make Pro follow you"
        case .generic:     return "Save your progress"
        }
    }

    private var subhead: String? {
        switch reason {
        case .bestStreak:
            return "\(currentStreak) days. It exists in one place."
        case .milestone:
            return "That's a lot of work to leave on one device."
        case .leaderboard:
            return "Ranks belong to accounts. Right now yours belongs to a phone."
        case .proUnlocked:
            return "You paid for it — let's make sure you keep it."
        case .generic:
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    stakes
                    AccountLinkingControls()
                    reassurance
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Not now") { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 84, height: 84)
                Image(systemName: "icloud.and.arrow.up.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple],
                                                    startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            Text(headline)
                .font(.system(.title, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)

            if let subhead = subhead {
                Text(subhead)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 8)
    }

    private var stakes: some View {
        AccountSyncStakes(
            currentStreak: currentStreak,
            casesPlayed: casesPlayed,
            hasPro: hasPro,
            schoolName: schoolName
        )
    }

    private var reassurance: some View {
        VStack(spacing: 6) {
            Label("Takes about ten seconds", systemImage: "clock")
            Text("We only use this to restore your account. No spam, no password to remember, and your data stays exactly where it is.")
                .multilineTextAlignment(.center)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }
}

#Preview {
    SecureAccountPromptView()
}

/// What this particular person stands to lose, in their own numbers.
///
/// The previous version said "your streak and stats live only on this phone"
/// to everybody — the same three abstractions on the home banner, in this
/// sheet, and in Settings. Three surfaces making one argument, and the
/// argument was insurance against something that has not happened yet. A third
/// of accounts saw the banner on every launch for months and never acted on
/// it, which is about as clear a verdict as a product gets.
///
/// So: read the real figures and say them. "Your 12-day streak" is a thing
/// someone owns. "Your streak" is a category. The difference is the whole
/// point of this view.
///
/// Falls back to the generic lines when there is genuinely nothing to name —
/// a brand-new account has no stakes, and inventing some would be a lie the
/// user can check.
struct AccountSyncStakes: View {
    /// Passed in rather than fetched, because this view is presented from a
    /// sheet where a fresh SwiftData query would have to be plumbed anyway, and
    /// because the caller already holds the stats it used to decide to ask.
    var currentStreak: Int = 0
    var casesPlayed: Int = 0
    var hasPro: Bool = false
    var schoolName: String? = nil

    private var hasSomethingToLose: Bool { casesPlayed > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if hasSomethingToLose {
                if currentStreak >= 2 {
                    row(icon: "flame.fill", tint: .orange,
                        title: "Your \(currentStreak)-day streak is on this phone only",
                        detail: "Nowhere else. Not in iCloud in a way you can get back on a new phone.")
                }

                row(icon: "checklist", tint: .blue,
                    title: "\(casesPlayed) case\(casesPlayed == 1 ? "" : "s") — and everything they taught us about you",
                    detail: "Your weak spots and study plan are built from these. Start over and they start over.")

                if let school = schoolName, !school.isEmpty {
                    row(icon: "trophy.fill", tint: .purple,
                        title: "Your place at \(school)",
                        detail: "A new phone is a new player. You would be rebuilding from zero.")
                }

                if hasPro {
                    row(icon: "crown.fill", tint: .yellow,
                        title: "Pro is tied to this install",
                        detail: "You paid for it. An email is what makes it follow you.")
                }
            } else {
                row(icon: "iphone.and.arrow.forward", tint: .blue,
                    title: "Right now this is a local-only app",
                    detail: "Delete it, switch phones, or lose this one, and there is nothing to come back to.")
            }

            // The one line here that is not about loss. Everything above is a
            // reason not to lose something; this is a reason to want something,
            // and it is the only part of the offer that pays off today rather
            // than on some future bad day.
            row(icon: "chart.line.uptrend.xyaxis", tint: .green,
                title: "Opens your dashboard on the web",
                detail: "Every case you've played, what you keep missing, and why — on a real screen.")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func row(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}
