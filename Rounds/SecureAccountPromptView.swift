//
//  SecureAccountPromptView.swift
//  Rounds
//
//  A gentle, one-time nudge shown after a meaningful moment (e.g. a streak
//  milestone) inviting an anonymous user to secure their account so Pro and
//  progress sync across devices. Reuses the same linking controls as the
//  Account hub. Fully dismissible — never nags twice.
//

import SwiftUI

struct SecureAccountPromptView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 76, height: 76)
                            Image(systemName: "icloud.and.arrow.up.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(LinearGradient(colors: [.blue, .purple],
                                                                startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                        Text("Save your progress")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .multilineTextAlignment(.center)
                        Text("You're on a roll! Sign in so your streak, progress, and Pro access are backed up and follow you to any device.")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                Section {
                    AccountLinkingControls()
                } footer: {
                    Text("Takes a few seconds. Your data stays exactly where it is.")
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Maybe later") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SecureAccountPromptView()
}
