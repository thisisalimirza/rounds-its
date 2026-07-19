//
//  IllnessScriptsView.swift
//  Rounds
//
//  The Illness Scripts library — a growing, organized reference of structured
//  scripts (Demographics / Diagnostics / Pathophysiology / Treatment) per
//  condition, browsable by specialty like the Case Browser. Scripts are cached
//  globally server-side and locally on device, so opening one is instant.
//
//  Access: your OWN missed conditions are free; the full library is Pro.
//

import SwiftUI
import SwiftData

// MARK: - Navigation routes

enum IllnessRoute: Hashable {
    case specialty(String)
    case all
    case condition(String)
}

// MARK: - Specialty styling (icon + color per system)

enum IllnessSpecialty {
    static func icon(_ system: String) -> String {
        switch primary(system) {
        case "cardiology": return "heart.fill"
        case "pulmonology", "respiratory": return "lungs.fill"
        case "gastroenterology", "gi", "hepatology": return "fork.knife"
        case "nephrology", "renal": return "drop.fill"
        case "neurology": return "brain.head.profile"
        case "infectious disease", "infectious diseases", "id": return "allergens"
        case "endocrinology": return "waveform.path.ecg"
        case "hematology", "oncology", "hematology oncology": return "drop.triangle.fill"
        case "rheumatology": return "figure.walk"
        case "psychiatry": return "brain"
        case "pediatrics": return "figure.and.child.holdinghands"
        case "dermatology": return "hand.raised.fill"
        case "obstetrics", "gynecology", "obstetrics gynecology", "ob gyn", "obgyn": return "figure.stand.dress"
        case "surgery", "general surgery", "orthopedics", "urology", "vascular", "ent", "ophthalmology": return "cross.case.fill"
        case "emergency medicine", "critical care": return "cross.circle.fill"
        default: return "cross.case.fill"
        }
    }
    static func color(_ system: String) -> Color {
        switch primary(system) {
        case "cardiology": return .red
        case "pulmonology", "respiratory": return .blue
        case "gastroenterology", "gi", "hepatology": return .orange
        case "nephrology", "renal": return .cyan
        case "neurology": return .purple
        case "infectious disease", "infectious diseases", "id": return .yellow
        case "endocrinology": return .green
        case "hematology", "oncology", "hematology oncology": return .pink
        case "rheumatology": return .indigo
        case "psychiatry": return .mint
        case "pediatrics": return Color(red: 0.4, green: 0.8, blue: 0.9)
        case "dermatology": return .orange.opacity(0.8)
        case "obstetrics", "gynecology", "obstetrics gynecology", "ob gyn", "obgyn": return .pink.opacity(0.8)
        case "emergency medicine", "critical care": return .red.opacity(0.8)
        default: return .gray
        }
    }
    private static func primary(_ s: String) -> String {
        s.lowercased().replacingOccurrences(of: "/", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ").joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    /// Display-only fallback: guess a specialty from the condition name when the
    /// stored `system` is missing (e.g. older scripts), so the grid buckets them
    /// sensibly until they're re-opened and re-categorized server-side.
    static func guess(_ condition: String) -> String {
        let c = condition.lowercased()
        func has(_ ws: [String]) -> Bool { ws.contains { c.contains($0) } }
        if has(["ovarian","preeclampsia","eclampsia","placenta","cervic","endometri","pregnan","gestational","ectopic","obstetric","vaginal","uterine","fibroid","menstru","ovary","hellp","postpartum","fetal","amenorrhea","pcos","adnex","vulv","cervix","chorio"]) { return "Obstetrics & Gynecology" }
        if has(["myocardial","angina","heart failure","atrial","ventricular","aortic","pericard","endocard","cardiomyopathy","arrhythm","valv","coronary","tamponade"]) { return "Cardiology" }
        if has(["pneumon","asthma","copd","pulmonary","pleura","bronch","tuberculosis","ards","pneumothorax","embolism"]) { return "Pulmonology" }
        if has(["stroke","seizure","migraine","meningitis","parkinson","multiple sclerosis","neuropath","epilep","encephal","myasthenia","guillain","spinal epidural","cauda equina"]) { return "Neurology" }
        if has(["pancreatit","hepatit","cirrhosis","cholecyst","cholangit","appendicit","colitis","crohn","peptic","gastr","bowel","biliary","diverticul","esophag","ulcerative"]) { return "Gastroenterology" }
        if has(["renal","nephritic","nephrotic","kidney","glomerul","pyelonephrit","urinary","cystitis"]) { return "Nephrology" }
        if has(["diabet","thyroid","adrenal","cushing","addison","pituitary","parathyroid","hypoglycemia","ketoacidosis"]) { return "Endocrinology" }
        if has(["leukemia","lymphoma","anemia","thrombocytopenia","sickle","myeloma","coagulopath"," dic","neutropen"]) { return "Hematology & Oncology" }
        if has(["lupus","arthritis","vasculitis","gout","scleroderma","sjogren","spondyl","polymyalgia","giant cell"]) { return "Rheumatology" }
        if has(["depress","schizophren","bipolar","anxiety","psychosis","mania","serotonin"]) { return "Psychiatry" }
        if has(["sepsis","abscess","cellulitis","osteomyelit","hiv","malaria","infect","fasciit"]) { return "Infectious Disease" }
        return "Other"
    }
}

// MARK: - Library

struct IllnessScriptsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MissedItem.timestamp, order: .reverse) private var misses: [MissedItem]

    @State private var store = IllnessLibraryStore.shared
    @State private var searchText = ""
    @State private var showingPaywall = false

    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    private var isPro: Bool { subscriptionManager.isProUser }

    /// Conditions the user has gotten wrong (their personal set — free).
    private var myConditions: [String] {
        var seen = Set<String>(); var out: [String] = []
        for m in misses where (m.sourceKind?.isWrongAnswer ?? true) {
            let name = m.item.trimmingCharacters(in: .whitespacesAndNewlines)
            let k = name.lowercased()
            if !name.isEmpty && !seen.contains(k) { seen.insert(k); out.append(name) }
        }
        return out
    }

    private func specialtyName(_ s: IllnessScriptSummary) -> String {
        let sys = (s.system ?? "").trimmingCharacters(in: .whitespaces)
        return sys.isEmpty ? IllnessSpecialty.guess(s.condition) : sys
    }

    /// Catalog grouped by specialty, largest first.
    private var specialties: [(name: String, items: [IllnessScriptSummary])] {
        Dictionary(grouping: store.catalog) { specialtyName($0) }
            .map { (name: $0.key, items: $0.value) }
            .sorted { $0.items.count > $1.items.count }
    }

    private var searchResults: [IllnessScriptSummary] {
        guard !searchText.isEmpty else { return [] }
        return store.catalog.filter { $0.condition.localizedCaseInsensitiveContains(searchText) }
    }
    private var myMatches: [String] {
        searchText.isEmpty ? [] : myConditions.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if searchText.isEmpty {
                    browseContent
                } else {
                    searchContent
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Illness Scripts")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search any condition")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
            .navigationDestination(for: IllnessRoute.self) { route in
                switch route {
                case .condition(let c): IllnessScriptDetailView(condition: c)
                case .specialty(let s): IllnessSpecialtyListView(specialty: s, items: specialties.first { $0.name == s }?.items ?? [])
                case .all: IllnessAllListView(items: store.catalog)
                }
            }
            .sheet(isPresented: $showingPaywall) { RoundsPaywallView() }
            .task {
                await store.refreshCatalog()
                await store.syncFullLibrary(isPro: isPro)
            }
        }
    }

    // MARK: Browse

    private var browseContent: some View {
        VStack(spacing: 20) {
            hero

            if !myConditions.isEmpty {
                section(title: "Conditions you've missed", systemImage: "target",
                        footer: "Illnesses you got wrong or needed help recognizing in cases and challenges — free to review.") {
                    VStack(spacing: 8) {
                        ForEach(myConditions.prefix(12), id: \.self) { c in
                            NavigationLink(value: IllnessRoute.condition(c)) {
                                IllnessScriptRow(condition: c, subtitle: "You missed this")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if isPro {
                specialtyGridSection
                allButton
            } else {
                lockedLibraryCard
            }
        }
        .padding(.vertical, 16)
    }

    private var hero: some View {
        VStack(spacing: 6) {
            Text("\(max(store.count, 0))")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom))
                .contentTransition(.numericText())
            Text(store.count == 1 ? "illness script" : "illness scripts")
                .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            Text("A growing reference library — search any condition to add one.")
                .font(.caption).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var specialtyGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by specialty").font(.headline).foregroundStyle(.secondary).padding(.horizontal, 20)
            if specialties.isEmpty {
                Text("The library fills in as conditions get added. Search any condition to start.")
                    .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 20)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(specialties, id: \.name) { group in
                        NavigationLink(value: IllnessRoute.specialty(group.name)) {
                            IllnessSpecialtyCard(name: group.name, count: group.items.count)
                        }
                        .buttonStyle(CategoryCardButtonStyle(color: IllnessSpecialty.color(group.name)))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var allButton: some View {
        NavigationLink(value: IllnessRoute.all) {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill").font(.title3).foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("All scripts").font(.headline).foregroundStyle(.primary)
                    Text("\(store.count) total").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private var lockedLibraryCard: some View {
        Button { showingPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill").font(.title3).foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Browse the full library").font(.headline).foregroundStyle(.primary)
                    Text("Every condition, organized by specialty — with Rounds Pro").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("PRO").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)))
            }
            .padding(16)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: Search

    private var searchContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

            // Offer to add an exact-typed condition not already in the library.
            if !q.isEmpty && !store.catalog.contains(where: { $0.condition.localizedCaseInsensitiveCompare(q) == .orderedSame }) {
                NavigationLink(value: IllnessRoute.condition(q)) {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.badge.plus").font(.title3).foregroundStyle(.indigo)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open “\(q)”").font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                            Text(isPro ? "Add it to the library" : "Free if it's one of your missed conditions").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
            }

            if !myMatches.isEmpty {
                resultList("From your conditions", myMatches.map { IllnessScriptSummary(condition: $0, conditionKey: $0.lowercased(), system: nil, oneLiner: nil, missCount: 0) })
            }
            if isPro && !searchResults.isEmpty {
                resultList("Library", searchResults)
            }
        }
        .padding(.vertical, 16)
    }

    private func resultList(_ title: String, _ items: [IllnessScriptSummary]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary).padding(.horizontal, 20)
            VStack(spacing: 8) {
                ForEach(items) { item in
                    NavigationLink(value: IllnessRoute.condition(item.condition)) {
                        IllnessScriptRow(condition: item.condition, subtitle: item.oneLiner, missCount: item.missCount)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: Section helper

    private func section<Content: View>(title: String, systemImage: String, footer: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage).font(.headline).foregroundStyle(.secondary).padding(.horizontal, 20)
            content().padding(.horizontal, 16)
            if let footer {
                Text(footer).font(.caption).foregroundStyle(.tertiary).padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Specialty card (Case-Browser style)

struct IllnessSpecialtyCard: View {
    let name: String
    let count: Int

    var body: some View {
        let color = IllnessSpecialty.color(name)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: IllnessSpecialty.icon(name)).font(.system(size: 20)).foregroundStyle(color)
                }
                Spacer()
                Text("\(count)").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(.primary)
            }
            Text(name).font(.system(size: 14, weight: .semibold)).foregroundStyle(.primary).lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: color.opacity(0.1), radius: 8, y: 2)
    }
}

// MARK: - Compact script row

struct IllnessScriptRow: View {
    let condition: String
    var subtitle: String?
    var missCount: Int = 0

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.blue.opacity(0.12)).frame(width: 34, height: 34)
                Image(systemName: "book.closed.fill").font(.system(size: 13, weight: .semibold)).foregroundStyle(.blue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(condition).font(.subheadline.weight(.semibold)).foregroundStyle(.primary).lineLimit(1)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            if missCount > 1 {
                Text("\(missCount)").font(.caption2.weight(.bold)).foregroundStyle(.orange)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.12)))
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Drill-down lists

struct IllnessSpecialtyListView: View {
    let specialty: String
    let items: [IllnessScriptSummary]

    var body: some View {
        List {
            ForEach(items) { item in
                NavigationLink(value: IllnessRoute.condition(item.condition)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.condition).font(.subheadline.weight(.semibold))
                        if let ol = item.oneLiner, !ol.isEmpty {
                            Text(ol).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(specialty)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct IllnessAllListView: View {
    let items: [IllnessScriptSummary]
    @State private var searchText = ""

    private var filtered: [IllnessScriptSummary] {
        searchText.isEmpty ? items : items.filter { $0.condition.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            ForEach(filtered) { item in
                NavigationLink(value: IllnessRoute.condition(item.condition)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.condition).font(.subheadline.weight(.semibold))
                        if let ol = item.oneLiner, !ol.isEmpty {
                            Text(ol).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("All Scripts")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search conditions")
    }
}

// MARK: - Detail

struct IllnessScriptDetailView: View {
    let condition: String
    var reason: String = "review"

    private enum Phase: Equatable {
        case loading, ready(IllnessScript), failed(String)
        static func == (l: Phase, r: Phase) -> Bool {
            switch (l, r) {
            case (.loading, .loading): return true
            case let (.failed(a), .failed(b)): return a == b
            case (.ready, .ready): return true
            default: return false
            }
        }
    }

    @State private var phase: Phase = .loading

    var body: some View {
        Group {
            switch phase {
            case .loading: loadingView
            case .ready(let s): scriptView(s)
            case .failed(let m): errorView(m)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private var displayTitle: String {
        if case .ready(let s) = phase { return s.condition }
        return condition
    }

    private func load() async {
        // Instant if already cached locally.
        if let cached = IllnessLibraryStore.shared.cachedScript(for: condition) {
            phase = .ready(cached); return
        }
        do {
            let s = try await IllnessLibraryStore.shared.script(for: condition, reason: reason)
            await MainActor.run { withAnimation { phase = .ready(s) } }
        } catch {
            await MainActor.run { withAnimation { phase = .failed(error.localizedDescription) } }
        }
    }

    private func scriptView(_ s: IllnessScript) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if !s.system.isEmpty {
                    Label(s.system, systemImage: IllnessSpecialty.icon(s.system))
                        .font(.caption.weight(.semibold)).foregroundStyle(IllnessSpecialty.color(s.system))
                }

                // Snapshot — labeled like every other section.
                if !s.definition.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Snapshot", systemImage: "text.alignleft").font(.subheadline.weight(.bold)).foregroundStyle(.indigo)
                        Text(s.definition).font(.system(.subheadline, design: .rounded))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                }

                section("Predisposing Factors", icon: "person.2.fill", tint: .blue, items: s.predisposing)
                section("Pathophysiology", icon: "waveform.path.ecg", tint: .purple, items: s.pathophysiology)
                section("Clinical Presentation", icon: "stethoscope", tint: .teal, items: s.presentation)
                section("Diagnostics", icon: "magnifyingglass", tint: .orange, items: s.diagnostics)
                section("Management", icon: "pills.fill", tint: .green, items: s.management)
                pivotsSection(s.pivots)

                Text("Educational reference — cross-check with your curriculum and clinical judgment.")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center).padding(.top, 4)
            }
            .padding().padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func pivotsSection(_ pivots: [IllnessPivot]) -> some View {
        if !pivots.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label("Differential Pivot Points", systemImage: "arrow.triangle.branch")
                    .font(.subheadline.weight(.bold)).foregroundStyle(.pink)
                Text("How to tell it apart from its closest lookalikes:")
                    .font(.caption2).foregroundStyle(.secondary)
                ForEach(pivots) { p in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("vs. \(p.condition)").font(.caption.weight(.bold)).foregroundStyle(.pink)
                        Text(p.distinguisher).font(.caption).foregroundStyle(.primary.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.pink.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private func section(_ title: String, icon: String, tint: Color, items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon).font(.subheadline.weight(.bold)).foregroundStyle(tint)
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill").font(.system(size: 4)).foregroundStyle(tint).padding(.top, 6)
                        Text(item).font(.subheadline).foregroundStyle(.primary.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.3)
            Text("Loading illness script…")
                .font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle").font(.system(size: 40)).foregroundStyle(.orange)
            Text("Couldn't load this script").font(.system(.headline, design: .rounded))
            Text(message).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
            Button("Try again") { phase = .loading; Task { await load() } }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 24).padding(.vertical, 10)
                .background(Capsule().fill(Color(.secondarySystemBackground)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding()
    }
}

/// Sheet wrapper for presenting a single script from contextual entry points
/// (Weak Spots items, Study Plan can't-miss diagnoses).
struct IllnessScriptSheet: View {
    let condition: String
    var reason: String = "review"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            IllnessScriptDetailView(condition: condition, reason: reason)
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

#Preview {
    IllnessScriptsView()
}
