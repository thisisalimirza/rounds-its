//
//  RetentionOfferView.swift
//  Rounds
//
//  One-time retention paywall — shown only after a user dismisses the main
//  paywall without purchasing. Uses the "retention" offering in RevenueCat
//  which carries a promotional annual price. Once shown it is never shown again.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct RetentionOfferView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenRetentionOffer") private var hasSeenRetentionOffer: Bool = false

    @State private var retentionOffering: Offering?
    @State private var isLoading = true
    @State private var purchaseCompleted = false

    var body: some View {
        ZStack(alignment: .top) {
            if isLoading {
                loadingView
            } else if let offering = retentionOffering {
                paywallContent(offering: offering)
            } else {
                unavailableView
            }
        }
        .task {
            await loadRetentionOffering()
        }
    }

    // MARK: - Paywall content

    private func paywallContent(offering: Offering) -> some View {
        ZStack(alignment: .topLeading) {
            RevenueCatUI.PaywallView(offering: offering)
                .onPurchaseCompleted { _ in
                    purchaseCompleted = true
                    dismiss()
                }
                .onRestoreCompleted { _ in
                    if SubscriptionManager.shared.hasProAccess() {
                        purchaseCompleted = true
                        dismiss()
                    }
                }
                .onPurchaseFailure { error in
                    print("❌ Retention purchase failed: \(error.localizedDescription)")
                }

            // ONE-TIME OFFER badge — overlaid top-left
            oneTimeOfferBadge
        }
    }

    // MARK: - One-time offer badge

    private var oneTimeOfferBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.caption2)
            Text("ONE-TIME OFFER")
                .font(.caption2.bold())
                .tracking(0.5)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.red)
        .clipShape(Capsule())
        .shadow(color: .red.opacity(0.4), radius: 8, x: 0, y: 4)
        .padding(.top, 56) // Clear the notch/dynamic island
        .padding(.leading, 16)
    }

    // MARK: - Loading / unavailable states

    private var loadingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.3)
                Text("Loading your offer…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var unavailableView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Offer unavailable")
                    .font(.headline)
                    .foregroundStyle(.white)
                Button("Close") { dismiss() }
                    .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Load offering

    private func loadRetentionOffering() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            retentionOffering = offerings.offering(identifier: "retention")
        } catch {
            print("❌ Failed to load retention offering: \(error.localizedDescription)")
        }
        isLoading = false
    }
}

#Preview {
    RetentionOfferView()
}
