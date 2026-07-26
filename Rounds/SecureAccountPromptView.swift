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
            Text("Save your progress")
                .font(.system(.title, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var stakes: some View { AccountSyncStakes() }

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

/// The three concrete consequences of staying anonymous.
///
/// Shared by the post-game nudge and Settings → Account so the two cannot
/// drift. Naming what is actually lost — this phone only, delete and it's
/// gone, Pro won't follow you — lands where "sync across devices" does not.
struct AccountSyncStakes: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            row(icon: "flame.fill", tint: .orange,
                title: "Right now, nothing is backed up",
                detail: "Your streak and stats live only on this phone.")
            row(icon: "iphone.and.arrow.forward", tint: .blue,
                title: "Delete the app and it's gone",
                detail: "Same if you switch phones or lose this one.")
            row(icon: "crown.fill", tint: .yellow,
                title: "Pro won't follow you",
                detail: "Sign in and it works on every device, plus the web.")
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
