//
//  DifferentialDiagnosisView.swift
//  Rounds
//
//  Browse common chief complaints, try building your own differential, then
//  reveal an expert "can't-miss first" framework.
//

import SwiftUI

struct DifferentialDiagnosisView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                let items = DifferentialLibrary.filtered(query)
                if items.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
                Section {
                    ForEach(items) { presentation in
                        NavigationLink {
                            DifferentialDetailView(presentation: presentation)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: presentation.icon)
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(presentation.complaint)
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                    Text(presentation.system)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } footer: {
                    Text("Pick a chief complaint, jot your own differential, then reveal the framework.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Differential Builder")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, prompt: "Search a chief complaint")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Detail

struct DifferentialDetailView: View {
    let presentation: DDxPresentation

    @State private var showApproach = false
    @State private var newEntry = ""
    @State private var myList: [String] = []
    @State private var revealed = false
    @FocusState private var entryFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                approachCard
                myDifferentialCard

                if revealed {
                    expertCard
                } else {
                    Button {
                        withAnimation { revealed = true }
                        entryFocused = false
                    } label: {
                        Label("Reveal expert differential", systemImage: "sparkles")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                                        in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Text(DifferentialLibrary.disclaimer)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding()
        }
        .background(
            LinearGradient(colors: [Color.blue.opacity(0.06), Color.purple.opacity(0.06)],
                           startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
        )
        .navigationTitle(presentation.complaint)
        .navigationBarTitleDisplayMode(.inline)
    }

    // Approach (collapsible)
    private var approachCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showApproach.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill").foregroundStyle(.blue)
                    Text("How to approach it")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showApproach ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showApproach {
                Text(presentation.approach)
                    .font(.callout)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // Interactive scratchpad
    private var myDifferentialCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your differential")
                .font(.system(.subheadline, design: .rounded).weight(.bold))

            HStack {
                TextField("Add a diagnosis…", text: $newEntry)
                    .focused($entryFocused)
                    .onSubmit(addEntry)
                Button(action: addEntry) {
                    Image(systemName: "plus.circle.fill").font(.title3)
                }
                .disabled(newEntry.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if myList.isEmpty {
                Text("Jot down what you'd consider before revealing the framework.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(myList.enumerated()), id: \.offset) { index, item in
                    HStack {
                        Image(systemName: "circle.fill").font(.system(size: 5)).foregroundStyle(.blue)
                        Text(item).font(.subheadline)
                        Spacer()
                        Button {
                            myList.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func addEntry() {
        let trimmed = newEntry.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        myList.append(trimmed)
        newEntry = ""
    }

    // Expert framework
    private var expertCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            section(title: "Can't-miss (rule out first)", tint: .red, items: presentation.cantMiss)
            section(title: "Common causes", tint: .blue, items: presentation.common)

            VStack(alignment: .leading, spacing: 8) {
                Label("Key questions", systemImage: "questionmark.circle.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(.purple)
                ForEach(presentation.keyQuestions, id: \.self) { q in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary).padding(.top, 3)
                        Text(q).font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        }
        .transition(.opacity)
    }

    private func section(title: String, tint: Color, items: [DDxItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(tint)
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.subheadline.weight(.semibold))
                    Text(item.clue).font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    DifferentialDiagnosisView()
}
