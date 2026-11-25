//
//  ProDiagnosticsView.swift
//  Rounds
//
//  Hidden support screen. Five taps on the version in Settings opens it.
//  The Pro grant here is opt-in and off by default. TestFlight does not
//  grant Pro on its own.
//

import RevenueCat
import SwiftUI

struct ProDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    private var subscription: SubscriptionManager { SubscriptionManager.shared }
    private var account: AccountManager { AccountManager.shared }

    @State private var copied = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("Account ID") {
                        Text(truncated(account.userID))
                            .font(.caption.monospaced())
                    }
                    LabeledContent("RevenueCat user") {
                        Text(truncated(subscription.customerInfo?.originalAppUserId))
                            .font(.caption.monospaced())
                    }
                }
                Section("Rounds Pro") {
                    LabeledContent("Entitlement") {
                        Text(entitlement?.isActive == true ? "Active" : "Not active")
                    }
                    LabeledContent("Expires") {
                        Text(expiryText)
                    }
                    LabeledContent("Store") {
                        Text(storeName)
                    }
                    LabeledContent("Product") {
                        Text(entitlement?.productIdentifier ?? "—")
                            .font(.caption.monospaced())
                    }
                    Button(copied ? "Copied" : "Copy support info") {
                        UIPasteboard.general.string = supportInfo
                        copied = true
                    }
                }
                Section {
                    Toggle("Grant Pro on this device", isOn: Binding(
                        get: { subscription.diagnosticsProGrant },
                        set: { subscription.diagnosticsProGrant = $0 }
                    ))
                    Toggle("Simulate free user", isOn: Binding(
                        get: { subscription.isSimulatingFreeUser },
                        set: { subscription.isSimulatingFreeUser = $0 }
                    ))
                    .disabled(!subscription.isBetaBuild)
                } footer: {
                    Text("Grant Pro is off unless you turn it on. A TestFlight install is not Pro by itself. Simulate free is available on debug and TestFlight builds.")
                }
            }
            .navigationTitle("Pro status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var entitlement: EntitlementInfo? {
        subscription.customerInfo?.entitlements[SubscriptionManager.proEntitlementID]
    }

    private var storeName: String {
        guard let store = entitlement?.store else { return "—" }
        return String(describing: store)
    }

    private var expiryText: String {
        guard let date = entitlement?.expirationDate else {
            return entitlement?.isActive == true ? "Does not expire" : "—"
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private var supportInfo: String {
        """
        Account ID: \(account.userID ?? "none")
        RevenueCat: \(subscription.customerInfo?.originalAppUserId ?? "none")
        Entitlement: \(entitlement?.isActive == true ? "active" : "inactive")
        Expires: \(expiryText)
        Store: \(storeName)
        Product: \(entitlement?.productIdentifier ?? "none")
        """
    }

    private func truncated(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "—" }
        if value.count <= 14 { return value }
        return "\(value.prefix(8))…\(value.suffix(4))"
    }
}
