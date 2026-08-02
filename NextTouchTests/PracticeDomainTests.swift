import XCTest
@testable import NextTouch

final class PracticeDomainTests: XCTestCase {
    func testStarterCatalogHasOneHundredStableUniqueIDs() {
        XCTAssertEqual(starterDrills.count, 100)
        XCTAssertEqual(Set(starterDrills.map(\.id)).count, 100)
        XCTAssertEqual(starterDrills.first?.id.uuidString, "00000000-0000-0000-0000-000000000001")
    }

    func testNormalizationTrimsPracticeAndCoachingText() {
        let activity = PracticeActivity(title: "  Rondo  ", type: .passing, minutes: 12, notes: ["  Open body ", "   "])
        let practice = Practice(title: "  Wednesday  ", date: "Today", activities: [activity])

        let normalized = PracticeValidator.normalized(practice)

        XCTAssertEqual(normalized.title, "Wednesday")
        XCTAssertEqual(normalized.activities[0].title, "Rondo")
        XCTAssertEqual(normalized.activities[0].notes, ["Open body"])
    }

    func testValidationRejectsEmptyPracticeAndInvalidDuration() {
        XCTAssertThrowsError(try PracticeValidator.validate(Practice(title: "Valid", date: "Today", activities: [])))
        let invalid = Practice(title: "Valid", date: "Today", activities: [.init(title: "Drill", type: .passing, minutes: 181, notes: [])])
        XCTAssertThrowsError(try PracticeValidator.validate(invalid))
    }

    func testDuplicateCreatesNewPracticeAndActivityIDs() async throws {
        let key = "nexttouch.repository.practices"
        UserDefaults.standard.removeObject(forKey: key)
        let repository = LocalPracticeRepository()
        let original = try await repository.practices().first!

        let copy = try await repository.duplicate(id: original.id)

        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertEqual(copy.activities.count, original.activities.count)
        XCTAssertTrue(zip(copy.activities, original.activities).allSatisfy { $0.0.id != $0.1.id })
        UserDefaults.standard.removeObject(forKey: key)
    }

    func testRunRepositoryIsIdempotentByRunID() async throws {
        let key = "nexttouch.repository.runs"
        UserDefaults.standard.removeObject(forKey: key)
        let repository = LocalPracticeRepository()
        let practice = try await repository.practices().first!
        let run = PracticeRunSummary(id: UUID(), practiceID: practice.id, practiceRevision: practice.revision, startedAt: .now, endedAt: .now, completed: false, advancementTimestamps: [:])

        try await repository.save(run)
        try await repository.save(run)

        let pending = try await repository.pendingWatchTransfers()
        XCTAssertEqual(pending.filter { $0.id == run.id }.count, 1)
        UserDefaults.standard.removeObject(forKey: key)
    }

    @MainActor
    func testSnapshotStoreRejectsOlderRevision() {
        let store = PracticeSyncStore()
        let practice = Practice(title: "Revision Test", date: "Today", activities: [.init(title: "Drill", type: .passing, minutes: 10, notes: [])], revision: 3)
        store.download(practice)
        let stalePractice = Practice(id: practice.id, title: "Stale", date: "Today", activities: practice.activities, revision: 2)
        store.install(PracticeSnapshot(id: UUID(), practiceID: practice.id, revision: 2, createdAt: .now, practice: stalePractice))
        XCTAssertEqual(store.snapshots[practice.id]?.revision, 3)
        UserDefaults.standard.removeObject(forKey: "nexttouch.watch.snapshots")
    }

    @MainActor
    func testUnchangedPracticeSaveDoesNotBumpRevision() {
        let key = "nexttouch.practices"
        UserDefaults.standard.removeObject(forKey: key)
        let store = PracticeStore()
        let practice = Practice(title: "Revision", date: "Today", activities: [.init(title: "Drill", type: .passing, minutes: 10, notes: [])])
        store.save(practice)
        let saved = store.practices[0]
        store.save(saved)
        XCTAssertEqual(store.practices[0].revision, saved.revision)
        UserDefaults.standard.removeObject(forKey: key)
    }
}
