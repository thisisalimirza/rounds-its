//
//  RoadmapSignupView.swift
//  Rounds
//
//  Email capture for roadmap updates and early access
//

import SwiftUI

// MARK: - Roadmap Feature Model

struct RoadmapFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let timeline: String
    let color: Color
}

// MARK: - Main Signup View

struct RoadmapSignupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isValidEmail = false
    @State private var isSubmitting = false
    @State private var hasSubmitted = false
    @State private var showError = false
    @State private var animateFeatures = false

    @FocusState private var emailFieldFocused: Bool

    private let roadmapFeatures: [RoadmapFeature] = [
        RoadmapFeature(
            icon: "2.circle.fill",
            title: "Step 2 Cases",
            subtitle: "Clinical knowledge & diagnosis",
            timeline: "Coming Soon",
            color: .blue
        ),
        RoadmapFeature(
            icon: "3.circle.fill",
            title: "Step 3 Cases",
            subtitle: "Patient management scenarios",
            timeline: "In Development",
            color: .purple
        ),
        RoadmapFeature(
            icon: "globe",
            title: "Web App",
            subtitle: "Study anywhere, any device",
            timeline: "2025",
            color: .green
        ),
        RoadmapFeature(
            icon: "person.2.fill",
            title: "Study Groups",
            subtitle: "Compete with your study partners",
            timeline: "Planned",
            color: .orange
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Hero Section
                    heroSection

                    // MARK: - Roadmap Features
                    VStack(spacing: 12) {
                        ForEach(Array(roadmapFeatures.enumerated()), id: \.element.id) { index, feature in
                            RoadmapFeatureRow(feature: feature)
                                .opacity(animateFeatures ? 1 : 0)
                                .offset(y: animateFeatures ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.1),
                                    value: animateFeatures
                                )
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Email Signup Section
                    if !hasSubmitted {
                        emailSignupSection
                    } else {
                        successSection
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 20)
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                withAnimation {
                    animateFeatures = true
                }
                AnalyticsManager.shared.track("roadmap_viewed")
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "map.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Rounds is Growing")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Get early access to new features")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Email Signup Section

    private var emailSignupSection: some View {
        VStack(spacing: 16) {
            // Value proposition
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text("Early access subscribers get features first")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(Color.yellow.opacity(0.1))
            )

            // Email input
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    TextField("your@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($emailFieldFocused)
                        .onChange(of: email) { _, newValue in
                            isValidEmail = isValidEmailFormat(newValue)
                        }

                    if !email.isEmpty {
                        Image(systemName: isValidEmail ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(isValidEmail ? .green : .red.opacity(0.5))
                            .animation(.spring(response: 0.3), value: isValidEmail)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                )

                // Submit button
                Button {
                    submitEmail()
                } label: {
                    HStack(spacing: 8) {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Get Early Access")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: isValidEmail ? [.blue, .purple] : [.gray.opacity(0.3), .gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(14)
                }
                .disabled(!isValidEmail || isSubmitting)
                .animation(.spring(response: 0.3), value: isValidEmail)

                // Privacy note
                Text("We'll only email you about major updates. No spam, ever.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Success Section

    private var successSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 4) {
                Text("You're on the list!")
                    .font(.headline)

                Text("We'll notify you when new features drop.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 20)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Helpers

    private func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    private func submitEmail() {
        guard isValidEmail else { return }

        isSubmitting = true
        emailFieldFocused = false

        // Track the signup
        AnalyticsManager.shared.track("roadmap_email_submitted", properties: [
            "email_domain": email.components(separatedBy: "@").last ?? "unknown"
        ])

        // Submit to Formspree
        RoadmapEmailManager.shared.saveEmail(email) { success in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isSubmitting = false
                hasSubmitted = true
            }

            // Track success/failure
            if success {
                AnalyticsManager.shared.track("roadmap_email_success")
            } else {
                AnalyticsManager.shared.track("roadmap_email_failed_but_stored")
            }
        }
    }
}

// MARK: - Roadmap Feature Row

struct RoadmapFeatureRow: View {
    let feature: RoadmapFeature

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: feature.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(feature.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.system(size: 16, weight: .semibold))

                Text(feature.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Timeline badge
            Text(feature.timeline)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(feature.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(feature.color.opacity(0.1))
                )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: feature.color.opacity(0.08), radius: 8, y: 2)
        )
    }
}

// MARK: - Roadmap Card (For More Tab)

struct RoadmapCard: View {
    let action: () -> Void
    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Animated gradient icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.15), .purple.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .scaleEffect(isPulsing ? 1.05 : 1.0)

                    Image(systemName: "map.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("What's Coming")
                            .font(.system(size: 16, weight: .semibold))

                        // "New" badge
                        Text("NEW")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(4)
                    }

                    Text("Step 2, Step 3, Web App & more")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: .purple.opacity(0.1), radius: 6, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Email Manager

class RoadmapEmailManager {
    static let shared = RoadmapEmailManager()

    private let formspreeEndpoint = "https://formspree.io/f/mdaleljq"
    private let hasSignedUpKey = "has_signed_up_for_roadmap"
    private let signedUpEmailKey = "roadmap_signed_up_email"

    private init() {}

    var hasSignedUp: Bool {
        UserDefaults.standard.bool(forKey: hasSignedUpKey)
    }

    var signedUpEmail: String? {
        UserDefaults.standard.string(forKey: signedUpEmailKey)
    }

    /// Submit email to Formspree and store locally
    func saveEmail(_ email: String, completion: ((Bool) -> Void)? = nil) {
        // Submit to Formspree
        submitToFormspree(email: email) { success in
            if success {
                // Store locally on success
                UserDefaults.standard.set(true, forKey: self.hasSignedUpKey)
                UserDefaults.standard.set(email.lowercased(), forKey: self.signedUpEmailKey)

                #if DEBUG
                print("📧 Email submitted to Formspree: \(email)")
                #endif
            } else {
                #if DEBUG
                print("📧 Formspree submission failed, storing locally anyway")
                #endif
                // Still mark as signed up locally even if network fails
                // (better UX than showing error for email collection)
                UserDefaults.standard.set(true, forKey: self.hasSignedUpKey)
                UserDefaults.standard.set(email.lowercased(), forKey: self.signedUpEmailKey)
            }
            completion?(success)
        }
    }

    private func submitToFormspree(email: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: formspreeEndpoint) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "email": email,
            "_subject": "New Rounds Early Access Signup",
            "source": "ios_app_roadmap"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            #if DEBUG
            print("📧 Failed to encode request body: \(error)")
            #endif
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    #if DEBUG
                    print("📧 Formspree error: \(error.localizedDescription)")
                    #endif
                    completion(false)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    let success = (200...299).contains(httpResponse.statusCode)
                    #if DEBUG
                    print("📧 Formspree response: \(httpResponse.statusCode)")
                    #endif
                    completion(success)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
}

// MARK: - Preview

#Preview {
    RoadmapSignupView()
}

#Preview("Roadmap Card") {
    RoadmapCard {
        print("Tapped")
    }
    .padding()
}
