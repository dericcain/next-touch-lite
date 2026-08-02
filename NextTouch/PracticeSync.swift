import Foundation

/// Versioned payloads keep the watch snapshot immutable while the iPhone remains the authoring source of truth.
struct PracticeSnapshot: Codable, Identifiable {
    let schemaVersion: Int
    let id: UUID
    let practiceID: UUID
    let revision: Int
    let createdAt: Date
    let practice: Practice
    init(id: UUID, practiceID: UUID, revision: Int, createdAt: Date, practice: Practice, schemaVersion: Int = PracticeSchema.version) { self.id = id; self.practiceID = practiceID; self.revision = revision; self.createdAt = createdAt; self.practice = practice; self.schemaVersion = schemaVersion }
}

struct PracticeRunSummary: Codable, Identifiable {
    let schemaVersion: Int
    let id: UUID
    let practiceID: UUID
    let practiceRevision: Int
    let startedAt: Date
    let endedAt: Date
    let completed: Bool
    let advancementTimestamps: [UUID: Date]
    var textNotes: [String] = []
    init(id: UUID, practiceID: UUID, practiceRevision: Int, startedAt: Date, endedAt: Date, completed: Bool, advancementTimestamps: [UUID: Date], textNotes: [String] = [], schemaVersion: Int = PracticeSchema.version) { self.id = id; self.practiceID = practiceID; self.practiceRevision = practiceRevision; self.startedAt = startedAt; self.endedAt = endedAt; self.completed = completed; self.advancementTimestamps = advancementTimestamps; self.textNotes = textNotes; self.schemaVersion = schemaVersion }
}

@MainActor final class PracticeSyncStore: ObservableObject {
    @Published private(set) var snapshots: [UUID: PracticeSnapshot] = [:]
    @Published private(set) var pendingRuns: [PracticeRunSummary] = []
    @Published private(set) var receivedRuns: [PracticeRunSummary] = []
    private let snapshotKey = "nexttouch.watch.snapshots"
    private let runKey = "nexttouch.watch.pendingRuns"
    private let receivedRunKey = "nexttouch.phone.receivedRuns"

    init() {
        if let data = UserDefaults.standard.data(forKey: snapshotKey), let saved = try? JSONDecoder().decode([PracticeSnapshot].self, from: data) { snapshots = Dictionary(uniqueKeysWithValues: saved.map { ($0.practiceID, $0) }) }
        if let data = UserDefaults.standard.data(forKey: runKey), let saved = try? JSONDecoder().decode([PracticeRunSummary].self, from: data) { pendingRuns = saved }
        if let data = UserDefaults.standard.data(forKey: receivedRunKey), let saved = try? JSONDecoder().decode([PracticeRunSummary].self, from: data) { receivedRuns = saved }
    }

    func download(_ practice: Practice) {
        if let existing = snapshots[practice.id], existing.revision > practice.revision { return }
        snapshots[practice.id] = PracticeSnapshot(id: UUID(), practiceID: practice.id, revision: practice.revision, createdAt: Date(), practice: practice)
        persist()
    }

    func install(_ snapshot: PracticeSnapshot) {
        if let existing = snapshots[snapshot.practiceID], existing.revision >= snapshot.revision { return }
        snapshots[snapshot.practiceID] = snapshot
        persist()
    }

    func queue(_ summary: PracticeRunSummary) { guard !pendingRuns.contains(where: { $0.id == summary.id }) else { return }; pendingRuns.append(summary); persist() }
    func recordReceived(_ summary: PracticeRunSummary) { guard !receivedRuns.contains(where: { $0.id == summary.id }) else { return }; receivedRuns.append(summary); persist() }
    func acknowledge(runID: UUID) { pendingRuns.removeAll { $0.id == runID }; persist() }
    private func persist() { if let snapshotsData = try? JSONEncoder().encode(Array(snapshots.values)) { UserDefaults.standard.set(snapshotsData, forKey: snapshotKey) }; if let runsData = try? JSONEncoder().encode(pendingRuns) { UserDefaults.standard.set(runsData, forKey: runKey) }; if let receivedData = try? JSONEncoder().encode(receivedRuns) { UserDefaults.standard.set(receivedData, forKey: receivedRunKey) } }
}
