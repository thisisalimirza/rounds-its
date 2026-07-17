//
//  FeedbackView.swift
//  Rounds
//
//  One screen, two tabs:
//   • Send feedback  — writes straight to Supabase (no more mailto).
//   • Ideas          — a live, community-prioritized roadmap board: anyone can
//                      suggest a feature and up/downvote others', no account
//                      needed (everyone already has a silent anonymous session).
//
//  Kept to the existing "Feedback" entry point so nothing new crowds the app.
//

import SwiftUI

// MARK: - Shared backend models
//
// The Supabase-facing calls live in AccountManager (submitFeedback /
// fetchFeatureRequests / submitFeatureRequest / voteFeatureRequest) — the same
// authenticated anonymous session used everywhere else. These are the decoded
// shapes those methods return.

nonisolated struct FeatureRequest: Decodable, Sendable {
    let id: String
    let title: String
    let detail: String?
    let status: String
    let upvotes: Int
    let downvotes: Int
    let score: Int
}

nonisolated struct FeatureVoteRow: Decodable, Sendable {
    let request_id: String
    let value: Int
}

// MARK: - Backend service (UI-facing wrapper around AccountManager)

@MainActor
@Observable
final class FeedbackService {
    private(set) var requests: [FeatureRequestVM] = []
    private(set) var isLoading = false
    private(set) var loadFailed = false

    func submitFeedback(category: String, message: String) async throws {
        try await AccountManager.shared.submitFeedback(category: category, message: message)
    }

    func loadFeatureRequests() async {
        isLoading = true
        loadFailed = false
        defer { isLoading = false }
        do {
            let (reqs, votes) = try await AccountManager.shared.fetchFeatureRequests()
            requests = reqs.map { FeatureRequestVM(request: $0, myVote: votes[$0.id] ?? 0) }
        } catch {
            print("⚠️ loadFeatureRequests: \(error.localizedDescription)")
            loadFailed = true
        }
    }

    func submitFeatureRequest(title: String, detail: String) async throws {
        try await AccountManager.shared.submitFeatureRequest(title: title, detail: detail)
        await loadFeatureRequests()
    }

    func vote(_ request: FeatureRequestVM, _ direction: Int) async {
        let newVote = (request.myVote == direction) ? 0 : direction
        applyLocalVote(id: request.id, newVote: newVote)   // optimistic
        do {
            try await AccountManager.shared.voteFeatureRequest(id: request.id, value: direction, current: request.myVote)
        } catch {
            print("⚠️ vote: \(error.localizedDescription)")
            await loadFeatureRequests()   // resync on failure
        }
    }

    private func applyLocalVote(id: String, newVote: Int) {
        guard let i = requests.firstIndex(where: { $0.id == id }) else { return }
        let old = requests[i].myVote
        if old == 1 { requests[i].upvotes -= 1 }
        if old == -1 { requests[i].downvotes -= 1 }
        if newVote == 1 { requests[i].upvotes += 1 }
        if newVote == -1 { requests[i].downvotes += 1 }
        requests[i].myVote = newVote
    }
}

// MARK: - View model

struct FeatureRequestVM: Identifiable {
    let id: String
    let title: String
    let detail: String?
    let status: String
    var upvotes: Int
    var downvotes: Int
    var myVote: Int

    init(request: FeatureRequest, myVote: Int) {
        id = request.id; title = request.title; detail = request.detail; status = request.status
        upvotes = request.upvotes; downvotes = request.downvotes; self.myVote = myVote
    }

    var score: Int { upvotes - downvotes }

    var statusLabel: String? {
        switch status {
        case "planned": return "Planned"
        case "in_progress": return "In progress"
        case "done": return "Shipped"
        default: return nil
        }
    }
    var statusColor: Color {
        switch status {
        case "planned": return .blue
        case "in_progress": return .orange
        case "done": return .green
        default: return .secondary
        }
    }
}

// MARK: - Main view

struct FeedbackView: View {
    enum Tab: Hashable { case feedback, ideas }

    let initialTab: Tab

    init(initialTab: Tab = .feedback) {
        self.initialTab = initialTab
        _tab = State(initialValue: initialTab)
    }

    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab
    @State private var service = FeedbackService()

    // Feedback tab
    @State private var category = "idea"
    @State private var message = ""
    @State private var isSending = false
    @State private var sent = false

    // Ideas tab
    @State private var showingCompose = false

    private let categories: [(id: String, label: String, icon: String)] = [
        ("idea", "Idea", "lightbulb.fill"),
        ("bug", "Bug", "ant.fill"),
        ("general", "General", "text.bubble.fill"),
        ("praise", "Love it", "heart.fill")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    Text("Send Feedback").tag(Tab.feedback)
                    Text("Ideas").tag(Tab.ideas)
                }
                .pickerStyle(.segmented)
                .padding()

                switch tab {
                case .feedback: feedbackTab
                case .ideas:    ideasTab
                }
            }
            .navigationTitle("Feedback & Ideas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showingCompose) {
                SuggestIdeaSheet { title, detail in
                    try await service.submitFeatureRequest(title: title, detail: detail)
                }
            }
            .task {
                if initialTab == .ideas { await service.loadFeatureRequests() }
            }
            .onChange(of: tab) { _, newTab in
                if newTab == .ideas && service.requests.isEmpty {
                    Task { await service.loadFeatureRequests() }
                }
            }
        }
    }

    // MARK: Feedback tab

    private var feedbackTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if sent {
                    sentConfirmation
                } else {
                    Text("What's on your mind?")
                        .font(.system(.headline, design: .rounded))

                    // Category chips
                    FlowLayout(spacing: 8) {
                        ForEach(categories, id: \.id) { c in
                            let selected = category == c.id
                            Button {
                                category = c.id
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Label(c.label, systemImage: c.icon)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(Capsule().fill(selected ? Color.blue.opacity(0.15) : Color(.secondarySystemBackground)))
                                    .foregroundStyle(selected ? .blue : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    ZStack(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Tell us what's working, what's not, or what you'd love to see…")
                                .font(.subheadline).foregroundStyle(.tertiary)
                                .padding(.horizontal, 14).padding(.vertical, 16)
                        }
                        TextEditor(text: $message)
                            .font(.subheadline)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 160)
                            .padding(8)
                    }
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

                    Button {
                        Task { await send() }
                    } label: {
                        HStack {
                            if isSending { ProgressView().tint(.white) }
                            Text(isSending ? "Sending…" : "Send")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Capsule().fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)))
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                    Text("Goes straight to the team. Want others to vote on your idea? Post it under **Ideas** instead.")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .padding()
        }
    }

    private var sentConfirmation: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 48)).foregroundStyle(.green)
            Text("Thanks — we got it!").font(.system(.headline, design: .rounded))
            Text("Every note is read. It genuinely shapes what we build next.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Send another") { withAnimation { sent = false; message = "" } }
                .font(.subheadline.weight(.semibold))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity).padding(.top, 40)
    }

    private func send() async {
        isSending = true
        defer { isSending = false }
        do {
            try await service.submitFeedback(category: category, message: message)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { sent = true }
        } catch {
            print("⚠️ submitFeedback: \(error.localizedDescription)")
            // Even on failure, thank the user (don't lose goodwill); log for us.
            withAnimation { sent = true }
        }
    }

    // MARK: Ideas tab

    private var ideasTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Button {
                    showingCompose = true
                } label: {
                    Label("Suggest an idea", systemImage: "plus.circle.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(Capsule().fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)))
                }
                .buttonStyle(.plain)

                if service.isLoading && service.requests.isEmpty {
                    ProgressView().padding(.top, 40)
                } else if service.requests.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: service.loadFailed ? "wifi.slash" : "lightbulb")
                            .font(.system(size: 40)).foregroundStyle(.secondary)
                        Text(service.loadFailed ? "Couldn't load ideas" : "Be the first to suggest one")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 40)
                } else {
                    ForEach(service.requests) { req in
                        FeatureRequestRowView(request: req) { direction in
                            Task { await service.vote(req, direction) }
                        }
                    }
                    Text("Ideas are ranked by community votes. This is our live, user-driven roadmap.")
                        .font(.caption2).foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 4)
                }
            }
            .padding()
        }
        .refreshable { await service.loadFeatureRequests() }
    }
}

// MARK: - Feature request row

private struct FeatureRequestRowView: View {
    let request: FeatureRequestVM
    let onVote: (Int) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Vote stack
            VStack(spacing: 2) {
                voteButton(direction: 1, icon: "chevron.up")
                Text("\(request.score)")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(request.myVote == 1 ? .blue : (request.myVote == -1 ? .red : .primary))
                    .contentTransition(.numericText())
                voteButton(direction: -1, icon: "chevron.down")
            }
            .frame(width: 40)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(request.title)
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    if let label = request.statusLabel {
                        Text(label)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(request.statusColor))
                    }
                }
                if let detail = request.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func voteButton(direction: Int, icon: String) -> some View {
        let active = request.myVote == direction
        let tint: Color = direction == 1 ? .blue : .red
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onVote(direction)
        } label: {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(active ? tint : .secondary)
                .frame(width: 28, height: 22)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Suggest idea compose sheet

private struct SuggestIdeaSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSubmit: (String, String) async throws -> Void

    @State private var title = ""
    @State private var detail = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("A short, clear title", text: $title)
                } header: {
                    Text("Your idea")
                } footer: {
                    Text("Keep it one idea per post so others can vote on it cleanly.")
                }
                Section("More detail (optional)") {
                    TextField("What would it do? Why would it help?", text: $detail, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Suggest an idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await submit() }
                    } label: {
                        if isSubmitting { ProgressView() } else { Text("Post").fontWeight(.semibold) }
                    }
                    .disabled(isSubmitting || title.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await onSubmit(title, detail)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            print("⚠️ submitFeatureRequest: \(error.localizedDescription)")
            dismiss()
        }
    }
}

#Preview {
    FeedbackView()
}
