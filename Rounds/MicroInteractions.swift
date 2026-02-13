//
//  MicroInteractions.swift
//  Rounds
//
//  Subtle animations and micro interactions to make the app feel alive
//

import SwiftUI
import UIKit

// MARK: - Shimmer Effect Modifier

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    let delay: Double

    init(duration: Double = 2.5, delay: Double = 0) {
        self.duration = duration
        self.delay = delay
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: -geometry.size.width * 0.5 + (geometry.size.width * 1.5 * phase))
                    .blendMode(.overlay)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer(duration: Double = 2.5, delay: Double = 0) -> some View {
        modifier(ShimmerEffect(duration: duration, delay: delay))
    }
}

// MARK: - Breathing/Pulse Animation

struct BreathingAnimation: ViewModifier {
    @State private var isBreathing = false
    let intensity: CGFloat
    let duration: Double

    init(intensity: CGFloat = 0.05, duration: Double = 2.0) {
        self.intensity = intensity
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBreathing ? 1 + intensity : 1)
            .animation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true),
                value: isBreathing
            )
            .onAppear {
                isBreathing = true
            }
    }
}

extension View {
    func breathing(intensity: CGFloat = 0.05, duration: Double = 2.0) -> some View {
        modifier(BreathingAnimation(intensity: intensity, duration: duration))
    }
}

// MARK: - Glow Animation

struct GlowAnimation: ViewModifier {
    @State private var isGlowing = false
    let color: Color
    let intensity: CGFloat
    let duration: Double

    init(color: Color = .orange, intensity: CGFloat = 0.6, duration: Double = 1.5) {
        self.color = color
        self.intensity = intensity
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isGlowing ? intensity : intensity * 0.3),
                radius: isGlowing ? 12 : 4,
                x: 0,
                y: 0
            )
            .animation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true),
                value: isGlowing
            )
            .onAppear {
                isGlowing = true
            }
    }
}

extension View {
    func glowing(color: Color = .orange, intensity: CGFloat = 0.6, duration: Double = 1.5) -> some View {
        modifier(GlowAnimation(color: color, intensity: intensity, duration: duration))
    }
}

// MARK: - Press Effect (Scale + Haptic)

struct PressEffect: ViewModifier {
    @State private var isPressed = false
    let scale: CGFloat
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle?

    init(scale: CGFloat = 0.95, haptic: UIImpactFeedbackGenerator.FeedbackStyle? = .light) {
        self.scale = scale
        self.hapticStyle = haptic
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            if let style = hapticStyle {
                                UIImpactFeedbackGenerator(style: style).impactOccurred()
                            }
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

extension View {
    func pressEffect(scale: CGFloat = 0.95, haptic: UIImpactFeedbackGenerator.FeedbackStyle? = .light) -> some View {
        modifier(PressEffect(scale: scale, haptic: haptic))
    }
}

// MARK: - Bounce Animation

struct BounceAnimation: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(trigger ? 1.0 : 0.9)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: trigger)
    }
}

extension View {
    func bounce(trigger: Bool) -> some View {
        modifier(BounceAnimation(trigger: trigger))
    }
}

// MARK: - Floating Animation (Subtle up/down movement)

struct FloatingAnimation: ViewModifier {
    @State private var isFloating = false
    let distance: CGFloat
    let duration: Double

    init(distance: CGFloat = 3, duration: Double = 2.0) {
        self.distance = distance
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -distance : distance)
            .animation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

extension View {
    func floating(distance: CGFloat = 3, duration: Double = 2.0) -> some View {
        modifier(FloatingAnimation(distance: distance, duration: duration))
    }
}

// MARK: - Sparkle Effect

struct SparkleView: View {
    let count: Int
    let color: Color

    @State private var sparkles: [SparkleData] = []

    init(count: Int = 5, color: Color = .yellow) {
        self.count = count
        self.color = color
    }

    var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size))
                    .foregroundStyle(color)
                    .opacity(sparkle.opacity)
                    .offset(x: sparkle.x, y: sparkle.y)
                    .scaleEffect(sparkle.scale)
            }
        }
        .onAppear {
            startSparkles()
        }
    }

    private func startSparkles() {
        sparkles = (0..<count).map { i in
            SparkleData(
                id: UUID(),
                x: CGFloat.random(in: -20...20),
                y: CGFloat.random(in: -20...20),
                size: CGFloat.random(in: 6...12),
                opacity: 0,
                scale: 0,
                delay: Double(i) * 0.3
            )
        }

        for i in sparkles.indices {
            withAnimation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
                .delay(sparkles[i].delay)
            ) {
                sparkles[i].opacity = Double.random(in: 0.5...1.0)
                sparkles[i].scale = CGFloat.random(in: 0.8...1.2)
            }
        }
    }
}

struct SparkleData: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var scale: CGFloat
    var delay: Double
}

// MARK: - Animated Logo

struct AnimatedLogo: View {
    @State private var rotation: Double = 0
    @State private var isGlowing = false

    var body: some View {
        Image(systemName: "cross.case.fill")
            .font(.system(size: 28))
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(
                color: .blue.opacity(isGlowing ? 0.5 : 0.2),
                radius: isGlowing ? 8 : 4,
                x: 0,
                y: 0
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
    }
}

// MARK: - Animated Streak Pill

struct AnimatedStreakPill: View {
    let streak: Int
    let freezes: Int
    let isPro: Bool

    @State private var fireScale: CGFloat = 1.0
    @State private var glowIntensity: CGFloat = 0.2

    var body: some View {
        HStack(spacing: 6) {
            Text("🔥")
                .font(.system(size: 16))
                .scaleEffect(fireScale)

            Text("\(streak)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.systemBackground))
                .shadow(color: streak > 0 ? .orange.opacity(glowIntensity) : .orange.opacity(0.2), radius: streak > 0 ? 8 : 4, y: 2)
        )
        .onAppear {
            if streak > 0 {
                // Fire emoji bounce
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    fireScale = 1.15
                }
                // Glow pulse
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    glowIntensity = 0.5
                }
            }
        }
    }
}

// MARK: - Enhanced Daily Case Button

struct EnhancedDailyCaseButton: View {
    let isCompleted: Bool
    let streak: Int

    @State private var shimmerPhase: CGFloat = 0
    @State private var iconScale: CGFloat = 1.0
    @State private var glowRadius: CGFloat = 12

    var body: some View {
        VStack(spacing: 12) {
            if isCompleted {
                // Completed State (unchanged but with celebration)
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.green)
                        .scaleEffect(iconScale)
                }
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        iconScale = 1.1
                    }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                        iconScale = 1.0
                    }
                }

                Text("Daily Complete!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)

                Text("Come back tomorrow")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // Play State with enhanced animations
                ZStack {
                    // Animated glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .cyan.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 92, height: 92)
                        .scaleEffect(iconScale * 1.1)
                        .opacity(0.6)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .blue.opacity(0.4), radius: glowRadius, x: 0, y: 6)
                        .scaleEffect(iconScale)

                    Image(systemName: "play.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .offset(x: 2)
                        .scaleEffect(iconScale)
                }
                .onAppear {
                    // Subtle pulse
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        iconScale = 1.05
                        glowRadius = 18
                    }
                }

                Text("Play Daily Case")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                if streak > 0 {
                    Text("Keep your \(streak)-day streak alive!")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                } else {
                    Text("Start your streak today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: isCompleted ? .green.opacity(0.15) : .blue.opacity(0.15), radius: 12, y: 4)
        )
        .overlay(
            // Shimmer overlay for play state
            Group {
                if !isCompleted {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.15),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerPhase)
                        .mask(RoundedRectangle(cornerRadius: 20))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isCompleted ? Color.green.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .onAppear {
            if !isCompleted {
                withAnimation(
                    .easeInOut(duration: 3)
                    .repeatForever(autoreverses: false)
                ) {
                    shimmerPhase = 400
                }
            }
        }
    }
}

// MARK: - Enhanced Feature Card with Press Effect

struct EnhancedFeatureCard: View {
    let icon: String
    let title: String
    var badgeText: String? = nil
    let color: Color
    var isLocked: Bool = false
    var action: (() -> Void)? = nil

    @State private var isPressed = false
    @State private var iconRotation: Double = 0

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            // Small rotation animation on tap
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                iconRotation = 15
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
                iconRotation = 0
            }
            action?()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: isLocked ? "lock.fill" : icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isLocked ? .gray : color)
                        .rotationEffect(.degrees(iconRotation))
                }

                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isLocked ? .secondary : .primary)
                        .lineLimit(1)

                    if let badge = badgeText {
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(color)
                    } else if isLocked {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.orange)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: color.opacity(isPressed ? 0.25 : 0.15), radius: isPressed ? 8 : 6, y: isPressed ? 1 : 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1)
        }
        .buttonStyle(.plain)
        .opacity(isLocked ? 0.7 : 1)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Enhanced Tab Bar with Bounce

struct EnhancedTabBar: View {
    @Binding var selectedTab: HomeTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomeTab.allCases, id: \.self) { tab in
                EnhancedTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 2)
        )
        .padding(.horizontal, 40)
    }
}

struct EnhancedTabButton: View {
    let tab: HomeTab
    let isSelected: Bool
    let action: () -> Void

    @State private var bounceScale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            // Bounce animation
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                bounceScale = 1.2
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                bounceScale = 1.0
            }
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22))
                    .symbolRenderingMode(.hierarchical)
                    .scaleEffect(bounceScale)

                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isSelected ? .blue : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Swipe Up Indicator (TikTok-style next case)

struct SwipeUpIndicator: View {
    let progress: CGFloat  // 0 to 1 based on drag progress
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 6) {
            // Animated chevrons
            VStack(spacing: 2) {
                Image(systemName: "chevron.up")
                    .font(.caption.bold())
                    .opacity(0.3 + progress * 0.7)
                Image(systemName: "chevron.up")
                    .font(.caption.bold())
                    .opacity(0.6 + progress * 0.4)
            }
            .foregroundStyle(progress > 0.7 ? .blue : .secondary)
            .offset(y: isAnimating ? -4 : 0)
            .animation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )

            Text("Swipe up for next case")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
        .opacity(Double(1.0 - progress * 0.5))  // Fade as user swipes
        .onAppear { isAnimating = true }
    }
}

// MARK: - Swipe Progress Bar

struct SwipeProgressBar: View {
    let progress: CGFloat  // 0 to 1

    var body: some View {
        GeometryReader { geometry in
            Capsule()
                .fill(Color(.systemGray5))
                .frame(height: 4)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(1, progress))
                }
        }
        .frame(height: 4)
        .padding(.horizontal, 60)
    }
}

// MARK: - Preview

#Preview("Micro Interactions") {
    VStack(spacing: 20) {
        AnimatedLogo()

        AnimatedStreakPill(streak: 7, freezes: 1, isPro: true)

        EnhancedDailyCaseButton(isCompleted: false, streak: 5)

        HStack(spacing: 12) {
            EnhancedFeatureCard(
                icon: "trophy.fill",
                title: "Leaderboard",
                color: .orange
            ) {}

            EnhancedFeatureCard(
                icon: "medal.fill",
                title: "Badges",
                badgeText: "5/10",
                color: .yellow
            ) {}
        }
        .padding(.horizontal, 20)
    }
    .padding()
    .background(Color(.systemGray6))
}

#Preview("Swipe Indicator") {
    VStack {
        Spacer()
        SwipeUpIndicator(progress: 0)
        Spacer()
        SwipeProgressBar(progress: 0.5)
            .padding()
    }
    .background(Color(.systemGray6))
}
