//
//  ProFeatureGate.swift
//  Rounds
//
//  Created by Ali Mirza on 1/11/26.
//

import SwiftUI

/// A view modifier that gates content behind Pro subscription
struct ProFeatureGate: ViewModifier {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                if subscriptionManager.hasProAccess() {
                    action()
                } else {
                    showingPaywall = true
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
    }
}

extension View {
    /// Gate a feature behind Pro subscription
    func requiresProSubscription(action: @escaping () -> Void) -> some View {
        modifier(ProFeatureGate(action: action))
    }
}

/// A button that shows paywall if user doesn't have Pro
struct ProGatedButton<Label: View>: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    
    let action: () -> Void
    let label: Label
    
    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }
    
    var body: some View {
        Button {
            if subscriptionManager.hasProAccess() {
                action()
            } else {
                showingPaywall = true
            }
        } label: {
            HStack {
                label
                
                if !subscriptionManager.hasProAccess() {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
}

/// A view that shows different content based on subscription status
struct ProContentView<Content: View, Placeholder: View>: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    let content: Content
    let placeholder: Placeholder
    
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.content = content()
        self.placeholder = placeholder()
    }
    
    var body: some View {
        if subscriptionManager.hasProAccess() {
            content
        } else {
            placeholder
        }
    }
}

/// A badge to show Pro features
struct ProBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
            Text("PRO")
        }
        .font(.caption2)
        .bold()
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: [.yellow, .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .foregroundStyle(.white)
        .cornerRadius(4)
    }
}

#Preview {
    VStack(spacing: 20) {
        ProGatedButton {
            print("Pro feature accessed")
        } label: {
            Label("Pro Feature", systemImage: "star.fill")
        }
        
        ProBadge()
    }
}
