//
//  ClinicalCalculatorsView.swift
//  Rounds
//
//  Searchable browser of clinical calculators + the calculator screen.
//

import SwiftUI

struct ClinicalCalculatorsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var groups: [(category: CalcCategory, items: [ClinicalCalculator])] {
        CalculatorLibrary.grouped(matching: query)
    }

    var body: some View {
        NavigationStack {
            List {
                if groups.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
                ForEach(groups, id: \.category) { group in
                    Section {
                        ForEach(group.items) { calc in
                            NavigationLink {
                                CalculatorDetailView(calculator: calc)
                            } label: {
                                calcRow(calc)
                            }
                        }
                    } header: {
                        Label(group.category.rawValue, systemImage: group.category.icon)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Clinical Calculators")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, prompt: "Search calculators, e.g. AFib, liver, PHQ")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func calcRow(_ calc: ClinicalCalculator) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Text(calc.name)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                if calc.comingSoon {
                    Text("SOON")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                }
            }
            Text(calc.tagline)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Calculator Detail

struct CalculatorDetailView: View {
    let calculator: ClinicalCalculator

    @State private var values: [String: Double]
    @State private var numberText: [String: String]
    @State private var showTeaching: Bool

    init(calculator: ClinicalCalculator) {
        self.calculator = calculator
        var initial: [String: Double] = [:]
        for field in calculator.fields {
            switch field.kind {
            case .toggle: initial[field.id] = 0
            case .options(let opts): initial[field.id] = opts.first?.value ?? 0
            case .number: break
            }
        }
        _values = State(initialValue: initial)
        _numberText = State(initialValue: [:])
        // Coming-soon calcs are all teaching, so expand; functional calcs start collapsed
        // to keep the screen focused on the calculator.
        _showTeaching = State(initialValue: calculator.comingSoon)
    }

    private var result: CalcResult? {
        guard let compute = calculator.compute else { return nil }
        var merged = values
        for field in calculator.fields where field.isNumber {
            guard let text = numberText[field.id], let d = Double(text) else { return nil }
            merged[field.id] = d
        }
        return compute(merged)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                teachingCard

                if calculator.comingSoon {
                    comingSoonCard
                } else {
                    inputsCard
                    resultCard
                }

                Text(CalculatorLibrary.disclaimer)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding()
        }
        .background(
            LinearGradient(colors: [Color.blue.opacity(0.06), Color.purple.opacity(0.06)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
        .navigationTitle(calculator.abbreviation)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: When to use (progressive disclosure — tagline always, depth on tap)

    private var teachingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showTeaching.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(calculator.tagline)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(showTeaching ? "Hide details" : "Why & when to use it")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showTeaching ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showTeaching {
                VStack(alignment: .leading, spacing: 10) {
                    Text(calculator.whenToUse)
                        .font(.callout)
                        .foregroundStyle(.primary)
                    if let pearl = calculator.pearl {
                        Label {
                            Text(pearl).font(.footnote).foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "star.fill").font(.footnote).foregroundStyle(.yellow)
                        }
                    }
                }
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var comingSoonCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "hourglass")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Interactive calculator coming soon")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
            Text("The 'when to use' guidance above is ready now — the calculator is being validated.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Inputs

    private var inputsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(calculator.fields.enumerated()), id: \.element.id) { index, field in
                fieldRow(field)
                if index < calculator.fields.count - 1 {
                    Divider().padding(.leading)
                }
            }
        }
        .padding(.vertical, 4)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func fieldRow(_ field: CalcField) -> some View {
        switch field.kind {
        case .toggle(let points):
            Toggle(isOn: Binding(
                get: { (values[field.id] ?? 0) != 0 },
                set: { values[field.id] = $0 ? points : 0 }
            )) {
                Text(field.label).font(.subheadline)
            }
            .padding(.horizontal).padding(.vertical, 10)

        case .options(let opts):
            HStack {
                Text(field.label).font(.subheadline)
                Spacer()
                Picker(field.label, selection: Binding(
                    get: { values[field.id] ?? opts.first?.value ?? 0 },
                    set: { values[field.id] = $0 }
                )) {
                    ForEach(opts) { opt in Text(opt.label).tag(opt.value) }
                }
                .pickerStyle(.menu)
                .tint(.blue)
            }
            .padding(.horizontal).padding(.vertical, 6)

        case .number(let unit):
            HStack {
                Text(field.label).font(.subheadline)
                Spacer()
                TextField("0", text: Binding(
                    get: { numberText[field.id] ?? "" },
                    set: { numberText[field.id] = $0 }
                ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                Text(unit).font(.caption).foregroundStyle(.secondary).frame(width: 64, alignment: .leading)
            }
            .padding(.horizontal).padding(.vertical, 10)
        }
    }

    // MARK: Result

    @ViewBuilder
    private var resultCard: some View {
        if let result {
            VStack(spacing: 6) {
                Text(result.value)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(result.severity.color)
                Text(result.interpretation)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(result.severity.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(result.severity.color.opacity(0.4), lineWidth: 1)
            )
        } else {
            Text("Fill in all fields to see the result")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding()
        }
    }
}

#Preview {
    ClinicalCalculatorsView()
}
