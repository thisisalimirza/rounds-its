//
//  DebugPaywallPreview.swift
//  Rounds
//
//  TEMPORARY FILE — for App Store Connect subscription screenshots only.
//  Shows a static preview of the 3-tier paywall. Delete after screenshots are taken.
//  Compiled out of App Store builds via #if DEBUG.
//

#if DEBUG
import SwiftUI

struct DebugPaywallPreview: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0A0A1A"), Color(hex: "0F0A2A")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Header
                    VStack(spacing: 12) {
                        Image(systemName: "stethoscope")
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "3B82F6"), Color(hex: "8B5CF6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 32)

                        Text("Rounds Pro")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Master every diagnosis")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }

                    // MARK: - Features
                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(icon: "infinity", text: "Unlimited daily cases")
                        FeatureRow(icon: "trophy.fill", text: "Global leaderboard by med school")
                        FeatureRow(icon: "flame.fill", text: "Streak freeze protection")
                        FeatureRow(icon: "sparkles", text: "Step 2 + Shelf Exam content — free forever")
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // MARK: - Plans
                    VStack(spacing: 12) {
                        PlanCard(
                            title: "Weekly",
                            price: "$9.99",
                            period: "per week",
                            badge: nil,
                            isSelected: false
                        )
                        PlanCard(
                            title: "Annual",
                            price: "$39.99",
                            period: "per year",
                            badge: "BEST VALUE",
                            isSelected: true
                        )
                        PlanCard(
                            title: "Lifetime",
                            price: "$99.99",
                            period: "one-time",
                            badge: "ALL FUTURE CONTENT",
                            isSelected: false
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - CTA
                    Button(action: {}) {
                        Text("Start Learning")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "3B82F6"), Color(hex: "8B5CF6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    Button("Restore Purchases") {}
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .padding(.bottom, 32)
                }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Subviews

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: "3B82F6"))
                .frame(width: 20)
            Text(text)
                .foregroundStyle(.white)
                .font(.subheadline)
            Spacer()
        }
    }
}

private struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    let badge: String?
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if let badge {
                        Text(badge)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "3B82F6"))
                            .clipShape(Capsule())
                    }
                }
                Text(period)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Text(price)
                .font(.title3.bold())
                .foregroundStyle(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color(hex: "3B82F6").opacity(0.2) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color(hex: "3B82F6") : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                )
        )
    }
}

// MARK: - Hex color helper (debug only)

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    DebugPaywallPreview()
}
#endif
