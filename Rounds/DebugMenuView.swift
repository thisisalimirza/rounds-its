//
//  DebugMenuView.swift
//  Rounds
//
//  DEBUG-only developer menu. Compiled out of App Store builds entirely.
//  Access: triple-tap the "Rounds" title on the home screen.
//

#if DEBUG
import SwiftUI

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaywallPreview = false
    @State private var showingRetentionPreview = false

    var body: some View {
        NavigationStack {
            List {

                // MARK: - Subscription simulation
                Section {
                    Toggle(isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "debug_simulate_free_user") },
                        set: { UserDefaults.standard.set($0, forKey: "debug_simulate_free_user") }
                    )) {
                        Label("Simulate Free User", systemImage: "person.slash")
                    }
                    .tint(.orange)
                } header: {
                    Text("Subscription")
                } footer: {
                    Text("Forces free tier so you can test paywalls and locked UI. Stripped from App Store builds.")
                }

                // MARK: - Paywall previews
                Section {
                    Button {
                        showingPaywallPreview = true
                    } label: {
                        Label("Preview 3-Tier Paywall", systemImage: "camera")
                    }

                    Button {
                        // Reset the seen flag so retention offer can show again
                        UserDefaults.standard.removeObject(forKey: "hasSeenRetentionOffer")
                    } label: {
                        Label("Reset Retention Offer (show again)", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Paywalls")
                } footer: {
                    Text("Use '3-Tier Paywall' to take App Store screenshots. Reset retention to re-trigger the one-time offer.")
                }

                // MARK: - RevenueCat status
                Section {
                    let sm = SubscriptionManager.shared
                    DebugRow(label: "Pro Access", value: sm.isProUser ? "✅ Yes" : "❌ No")
                    DebugRow(label: "Pro Subscriber", value: sm.isProSubscriber ? "✅ Yes" : "❌ No")
                    DebugRow(label: "Status", value: sm.subscriptionStatus.displayName)
                    DebugRow(label: "Free Simulation", value: UserDefaults.standard.bool(forKey: "debug_simulate_free_user") ? "ON" : "off")
                    DebugRow(label: "Seen Retention", value: UserDefaults.standard.bool(forKey: "hasSeenRetentionOffer") ? "Yes" : "No")
                } header: {
                    Text("Current State")
                }
            }
            .navigationTitle("🛠 Debug Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPaywallPreview) {
                DebugPaywallPreview()
            }
        }
    }
}

private struct DebugRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(.caption, design: .monospaced))
        }
    }
}

#Preview {
    DebugMenuView()
}
#endif
