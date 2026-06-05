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
    @State private var showingRetentionOffer = false
    @State private var showingMainPaywall = false

    // Refreshable state readout
    @State private var refreshToggle = false

    var body: some View {
        NavigationStack {
            List {

                // MARK: - Subscription simulation
                Section {
                    Toggle(isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "debug_simulate_free_user") },
                        set: {
                            UserDefaults.standard.set($0, forKey: "debug_simulate_free_user")
                            refreshToggle.toggle()
                        }
                    )) {
                        Label("Simulate Free User", systemImage: "person.slash")
                    }
                    .tint(.orange)
                } header: {
                    Text("Subscription")
                } footer: {
                    Text("Forces free tier so you can test paywalls and locked UI. Toggle flips instantly — no restart needed.")
                }

                // MARK: - Paywall testing
                Section {
                    // Static screenshot preview
                    Button {
                        showingPaywallPreview = true
                    } label: {
                        Label("3-Tier Paywall (screenshot mock)", systemImage: "camera")
                    }

                    // Real interactive main paywall
                    Button {
                        showingMainPaywall = true
                    } label: {
                        Label("Main Paywall (live RevenueCat)", systemImage: "creditcard")
                    }

                    // Retention offer — direct launch
                    Button {
                        // Reset flag first so it can be shown, then present directly
                        UserDefaults.standard.removeObject(forKey: "hasSeenRetentionOffer")
                        refreshToggle.toggle()
                        showingRetentionOffer = true
                    } label: {
                        Label("Retention Offer (live RevenueCat)", systemImage: "gift")
                    }

                    // Reset flag only, without showing
                    Button(role: .destructive) {
                        UserDefaults.standard.removeObject(forKey: "hasSeenRetentionOffer")
                        refreshToggle.toggle()
                    } label: {
                        Label("Reset 'Seen Retention' flag only", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Paywalls")
                } footer: {
                    Text("'Screenshot mock' is static — for App Store submission only. 'Live RevenueCat' versions hit real offerings and are fully interactive.")
                }

                // MARK: - Live state readout
                Section {
                    let sm = SubscriptionManager.shared
                    let _ = refreshToggle // force re-read on toggle
                    DebugRow(
                        label: "Pro Access",
                        value: sm.isProUser ? "✅ Yes" : "❌ No",
                        valueColor: sm.isProUser ? .green : .red
                    )
                    DebugRow(
                        label: "RC Subscriber",
                        value: sm.isProSubscriber ? "✅ Yes" : "❌ No",
                        valueColor: sm.isProSubscriber ? .green : .red
                    )
                    DebugRow(label: "Plan", value: sm.subscriptionStatus.displayName)
                    DebugRow(
                        label: "Free Simulation",
                        value: UserDefaults.standard.bool(forKey: "debug_simulate_free_user") ? "🟠 ON" : "off"
                    )
                    DebugRow(
                        label: "Seen Retention",
                        value: UserDefaults.standard.bool(forKey: "hasSeenRetentionOffer") ? "Yes" : "No"
                    )
                } header: {
                    Text("Live State")
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
            .sheet(isPresented: $showingMainPaywall) {
                RoundsPaywallView()
            }
            .sheet(isPresented: $showingRetentionOffer) {
                RetentionOfferView()
            }
        }
    }
}

private struct DebugRow: View {
    let label: String
    let value: String
    var valueColor: Color = .secondary

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(valueColor)
        }
    }
}

#Preview {
    DebugMenuView()
}
#endif
