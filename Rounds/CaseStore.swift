//
//  CaseStore.swift
//  Rounds
//
//  The case library, no longer welded into the binary.
//
//  Cases and diagnoses lived in CaseLibrary.swift and DiagnosisRegistry.swift
//  as hand-written Swift literals, which meant a typo in a hint, or a case
//  that only accepts one exact spelling of its answer, needed an App Store
//  release to fix. They now come from Supabase.
//
//  Offline is not negotiable here. This is studied on hospital wifi, on the
//  ward, in basements — so nothing about playing is allowed to depend on the
//  network:
//
//    * The current library ships *inside* the app as JSON, so a fresh install
//      is completely playable before it has ever reached the internet.
//    * What the server sends is written to disk and read from there at launch.
//    * Refresh happens in the background, off the critical path. A failed
//      refresh leaves the last good library in place and is never surfaced.
//
//  The load order is deliberately three-deep — disk, then bundle, then the
//  hard-coded Swift arrays. That last fallback is redundant by design: it is
//  the same content the JSON was exported from, kept for one release so that
//  a bug in this file cannot leave the app with no cases at all.
//

import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class CaseStore {
    static let shared = CaseStore()

    /// The playable library. Rebuilt whenever records change.
    private(set) var cases: [MedicalCase] = []

    /// The answer-matching vocabulary behind DiagnosisRegistry.
    private(set) var diagnoses: [DiagnosisDefinition] = []

    private(set) var lastRefreshedAt: Date?
    private(set) var source: Source = .bundled

    enum Source: String {
        case disk       // synced from the server at some point
        case bundled    // shipped with this build
        case legacy     // the hard-coded Swift arrays
    }

    // MARK: - Storage

    private var caseRecords: [CaseRecord] = []
    private var diagnosisRecords: [DiagnosisRecord] = []
    private var schedule: [String: String] = [:]   // yyyy-MM-dd -> case id

    private let dir: URL
    private var casesURL: URL { dir.appendingPathComponent("cases.json") }
    private var diagnosesURL: URL { dir.appendingPathComponent("diagnoses.json") }
    private var scheduleURL: URL { dir.appendingPathComponent("daily_schedule.json") }

    private static let cursorKey = "caseStore.updatedAtCursor"
    private static let diagnosisCursorKey = "caseStore.diagnosisCursor"
    private static let lastRefreshKey = "caseStore.lastRefreshAt"

    /// Minimum gap between content refreshes.
    ///
    /// Cases change when someone edits them, which is rare and never urgent —
    /// a fix landing within six hours is fine. Refreshing on every launch
    /// instead multiplies a fixed cost by however many times a day a student
    /// opens the app, which is the wrong thing to scale with the user base.
    private static let refreshInterval: TimeInterval = 6 * 60 * 60

    private init() {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: nil, create: true))
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        dir = base.appendingPathComponent("Content", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        load()
    }

    // MARK: - Load

    /// Synchronous on purpose. `CaseLibrary.getSampleCases()` is called from
    /// view initialisers and has always returned immediately; making the
    /// library async would ripple through every screen for no benefit, since
    /// the data is a local file either way.
    private func load() {
        if let cached = decode([CaseRecord].self, at: casesURL), !cached.isEmpty {
            caseRecords = cached
            diagnosisRecords = decode([DiagnosisRecord].self, at: diagnosesURL) ?? bundledDiagnoses()
            schedule = decode([String: String].self, at: scheduleURL) ?? bundledSchedule()
            source = .disk
        } else if let seed = bundledCases(), !seed.isEmpty {
            caseRecords = seed
            diagnosisRecords = bundledDiagnoses()
            schedule = bundledSchedule()
            source = .bundled
        } else {
            // Should be unreachable. Kept so that a missing or malformed
            // bundled resource degrades to the previous behaviour instead of
            // an app with an empty library.
            caseRecords = CaseLibrary.legacyCases().map { CaseRecord($0) }
            diagnosisRecords = DiagnosisRegistry.legacyAll.map { DiagnosisRecord($0) }
            schedule = [:]
            source = .legacy
            print("⚠️ CaseStore: falling back to hard-coded content")
        }
        rebuild()
    }

    private func rebuild() {
        cases = caseRecords.map { $0.makeCase() }
        diagnoses = diagnosisRecords.map { $0.makeDefinition() }
    }

    private func decode<T: Decodable>(_ type: T.Type, at url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func bundledCases() -> [CaseRecord]? {
        guard let url = Bundle.main.url(forResource: "cases", withExtension: "json") else { return nil }
        return decode([CaseRecord].self, at: url)
    }

    private func bundledDiagnoses() -> [DiagnosisRecord] {
        guard let url = Bundle.main.url(forResource: "diagnoses", withExtension: "json"),
              let records = decode([DiagnosisRecord].self, at: url) else {
            return DiagnosisRegistry.legacyAll.map { DiagnosisRecord($0) }
        }
        return records
    }

    private func bundledSchedule() -> [String: String] {
        guard let url = Bundle.main.url(forResource: "daily_schedule", withExtension: "json"),
              let rows = decode([ScheduleRow].self, at: url) else { return [:] }
        return Dictionary(rows.map { ($0.day, $0.case_id) }, uniquingKeysWith: { a, _ in a })
    }

    // MARK: - Daily case

    /// The scheduled case for a given day, or nil when that day isn't
    /// scheduled and the caller should fall back to the legacy seeded pick.
    ///
    /// Keyed on the *device's* calendar day, never the server's. Postgres
    /// `current_date` is UTC, so at 8pm in New York the server has already
    /// moved to tomorrow — looking the schedule up server-side would hand
    /// American users the next day's case every evening.
    func scheduledCase(for date: Date = Date()) -> MedicalCase? {
        guard let id = schedule[Self.dayKey(date)] else { return nil }
        return cases.first { $0.id.uuidString.lowercased() == id.lowercased() }
    }

    static func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    // MARK: - Refresh

    private var refreshTask: Task<Void, Never>?

    /// Pulls content changes. Safe to call at every launch; usually costs one
    /// small request that returns nothing.
    func refresh(force: Bool = false) {
        guard refreshTask == nil else { return }
        if !force, let last = UserDefaults.standard.object(forKey: Self.lastRefreshKey) as? Date,
           Date().timeIntervalSince(last) < Self.refreshInterval {
            return
        }
        refreshTask = Task { [weak self] in
            await self?.performRefresh()
            self?.refreshTask = nil
        }
    }

    private func performRefresh() async {
        let client = AccountManager.shared.supabase

        do {
            // A delta alone can't see removals: an unpublished case simply
            // stops appearing, which is indistinguishable from "unchanged".
            // Comparing counts first catches that, and costs one HEAD request.
            let counted: PostgrestResponse<Void> = try await client
                .from("cases")
                .select("id", head: true, count: .exact)
                .execute()
            let serverCount = counted.count ?? caseRecords.count

            let cursor = UserDefaults.standard.string(forKey: Self.cursorKey)
            let full = serverCount != caseRecords.count || cursor == nil

            var query = client
                .from("cases")
                .select("id, diagnosis, diagnosis_slug, alternative_names, hints, category, difficulty, updated_at")
            if !full, let cursor {
                query = query.gt("updated_at", value: cursor)
            }
            let incoming: [CaseRecord] = try await query.execute().value

            if full {
                caseRecords = incoming
            } else if !incoming.isEmpty {
                var byID = Dictionary(caseRecords.map { ($0.id.lowercased(), $0) },
                                      uniquingKeysWith: { a, _ in a })
                for record in incoming { byID[record.id.lowercased()] = record }
                caseRecords = Array(byID.values)
            }

            // Order is content too — Browse Cases lists in library order.
            caseRecords.sort { ($0.sort_order ?? .max, $0.diagnosis) < ($1.sort_order ?? .max, $1.diagnosis) }

            // Same treatment as cases: count first to catch removals, then
            // pull only what changed. Fetching all 366 rows on every refresh
            // was ~65KB per user per launch for data that changes monthly.
            let dxCounted: PostgrestResponse<Void> = try await client
                .from("diagnoses")
                .select("slug", head: true, count: .exact)
                .execute()
            let dxCursor = UserDefaults.standard.string(forKey: Self.diagnosisCursorKey)
            let dxFull = (dxCounted.count ?? diagnosisRecords.count) != diagnosisRecords.count || dxCursor == nil

            var dxQuery = client
                .from("diagnoses")
                .select("slug, canonical_name, alternative_names, category, updated_at")
            if !dxFull, let dxCursor {
                dxQuery = dxQuery.gt("updated_at", value: dxCursor)
            }
            let dx: [DiagnosisRecord] = try await dxQuery.execute().value

            if dxFull, !dx.isEmpty {
                diagnosisRecords = dx
            } else if !dx.isEmpty {
                var bySlug = Dictionary(diagnosisRecords.map { ($0.slug, $0) },
                                        uniquingKeysWith: { a, _ in a })
                for record in dx { bySlug[record.slug] = record }
                diagnosisRecords = Array(bySlug.values).sorted { $0.canonical_name < $1.canonical_name }
            }
            if let newestDx = dx.compactMap(\.updated_at).max() {
                UserDefaults.standard.set(newestDx, forKey: Self.diagnosisCursorKey)
            } else if dxCursor == nil {
                UserDefaults.standard.set(SyncTime.string(from: Date()), forKey: Self.diagnosisCursorKey)
            }

            // Only when the local copy is running out. The schedule is
            // months of tiny rows; re-pulling it because a refresh happened
            // is pure waste.
            let horizon = Self.dayKey(Date().addingTimeInterval(86_400 * 14))
            if schedule[Self.dayKey(Date())] == nil || schedule[horizon] == nil {
                let upcoming: [ScheduleRow] = try await client
                    .from("daily_cases")
                    .select("day, case_id")
                    .gte("day", value: Self.dayKey(Date().addingTimeInterval(-86_400 * 2)))
                    .execute().value
                for row in upcoming { schedule[row.day] = row.case_id }
            }

            if let newest = incoming.compactMap(\.updated_at).max() {
                UserDefaults.standard.set(newest, forKey: Self.cursorKey)
            } else if cursor == nil {
                UserDefaults.standard.set(SyncTime.string(from: Date()), forKey: Self.cursorKey)
            }

            persist()
            rebuild()
            source = .disk
            lastRefreshedAt = Date()
            UserDefaults.standard.set(lastRefreshedAt, forKey: Self.lastRefreshKey)
        } catch {
            // Deliberately silent. The library on disk is still good, and a
            // student on ward wifi should never see a sync error over a game.
            print("⚠️ CaseStore refresh failed: \(error.localizedDescription)")
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        try? encoder.encode(caseRecords).write(to: casesURL, options: .atomic)
        try? encoder.encode(diagnosisRecords).write(to: diagnosesURL, options: .atomic)
        try? encoder.encode(schedule).write(to: scheduleURL, options: .atomic)
    }
}

// MARK: - Wire records

nonisolated struct CaseRecord: Codable, Sendable {
    let id: String
    let diagnosis: String
    let diagnosis_slug: String?
    let alternative_names: [String]
    let hints: [String]
    let category: String
    let difficulty: Int
    var sort_order: Int?
    var updated_at: String?

    @MainActor init(_ medicalCase: MedicalCase) {
        id = medicalCase.id.uuidString
        diagnosis = medicalCase.diagnosis
        diagnosis_slug = medicalCase.diagnosisSlug
        alternative_names = medicalCase.alternativeNames
        hints = medicalCase.hints
        category = medicalCase.category
        difficulty = medicalCase.difficulty
        sort_order = nil
        updated_at = nil
    }

    /// The id is assigned from the record rather than left to the initializer.
    ///
    /// Both derive it the same way — sha256 of the diagnosis name — so they
    /// agree today. Taking the server's value means they still agree if that
    /// derivation ever has to change, and every CaseHistoryEntry keeps pointing
    /// at a case that exists.
    @MainActor func makeCase() -> MedicalCase {
        let built = MedicalCase(
            diagnosis: diagnosis,
            diagnosisSlug: diagnosis_slug,
            alternativeNames: alternative_names,
            hints: hints,
            category: category,
            difficulty: difficulty
        )
        if let uuid = UUID(uuidString: id) { built.id = uuid }
        return built
    }
}

nonisolated struct DiagnosisRecord: Codable, Sendable {
    let slug: String
    let canonical_name: String
    let alternative_names: [String]
    let category: String
    var updated_at: String?

    init(_ definition: DiagnosisDefinition) {
        slug = definition.id
        canonical_name = definition.canonicalName
        alternative_names = definition.alternativeNames
        category = definition.category
        updated_at = nil
    }

    func makeDefinition() -> DiagnosisDefinition {
        DiagnosisDefinition(
            id: slug,
            canonicalName: canonical_name,
            alternativeNames: alternative_names,
            category: category
        )
    }
}

nonisolated struct ScheduleRow: Codable, Sendable {
    let day: String
    let case_id: String
}
