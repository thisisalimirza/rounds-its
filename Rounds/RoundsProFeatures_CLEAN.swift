//
//  RoundsProFeatures.swift
//  Rounds
//
//  Created by Ali Mirza on 1/11/26.
//
//  This file contains all Pro feature gating logic and UI components
//  in one place to avoid conflicts.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Simple Paywall Wrapper

/// Use this to show the RevenueCat paywall with callbacks
struct RoundsPaywall: View {
    @Environment(\.dismiss) private var dismiss
    
    var onPurchased: (() -> Void)?
    var onRestored: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            PaywallView()
                .onPurchaseCompleted { _ in
                    onPurchased?()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
                .onRestoreCompleted { _ in
                    onRestored?()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
        }
    }
}

// MARK: - Feature Gating Helpers

extension View {
    /// Show paywall if user doesn't have Pro access
    func requiresPro(action: @escaping () -> Void) -> some View {
        self.modifier(ProGateModifier(action: action))
    }
}

private struct ProGateModifier: ViewModifier {
    let action: () -> Void
    
    @State private var showPaywall = false
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                if SubscriptionManager.shared.hasProAccess() {
                    action()
                } else {
                    showPaywall = true
                }
            }
            .sheet(isPresented: $showPaywall) {
                RoundsPaywall()
            }
    }
}

// MARK: - Pro Gated Button

/// A button that automatically shows paywall for non-Pro users
struct ProButton<Label: View>: View {
    let action: () -> Void
    let label: Label
    
    @State private var showPaywall = false
    
    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }
    
    var body: some View {
        Button {
            if SubscriptionManager.shared.hasProAccess() {
                action()
            } else {
                showPaywall = true
            }
        } label: {
            HStack {
                label
                if !SubscriptionManager.shared.hasProAccess() {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            RoundsPaywall()
        }
    }
}

// MARK: - Pro Content View

/// Show different content based on Pro status
struct ProContent<Content: View, FreeTier: View>: View {
    let content: Content
    let freeTier: FreeTier
    
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder freeTier: () -> FreeTier
    ) {
        self.content = content()
        self.freeTier = freeTier()
    }
    
    var body: some View {
        if SubscriptionManager.shared.hasProAccess() {
            content
        } else {
            freeTier
        }
    }
}

// MARK: - Pro Badge (Single Definition)

/// Visual badge showing Pro status
struct RoundsProBadge: View {
    enum Size {
        case small, medium, large
        
        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }
    
    var size: Size = .medium
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
            Text("PRO")
                .fontWeight(.bold)
        }
        .font(size.font)
        .foregroundStyle(.white)
        .padding(.horizontal, size.padding * 1.5)
        .padding(.vertical, size.padding)
        .background(
            LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(size.padding)
    }
}

// MARK: - Example Usage

#Preview("Pro Button") {
    ProButton {
        print("Feature accessed!")
    } label: {
        Label("Advanced Stats", systemImage: "chart.bar")
    }
}

#Preview("Pro Badge") {
    VStack(spacing: 16) {
        RoundsProBadge(size: .small)
        RoundsProBadge(size: .medium)
        RoundsProBadge(size: .large)
    }
}

#Preview("Pro Content") {
    ProContent {
        Text("Pro Content Here!")
            .font(.title)
            .foregroundStyle(.green)
    } freeTier: {
        VStack {
            Text("Upgrade to see this")
            RoundsProBadge()
        }
    }
}
