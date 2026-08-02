import XCTest
@testable import NextTouch

final class PracticeTimerEngineTests: XCTestCase {
    private let epoch = Date(timeIntervalSince1970: 1_700_000_000)

    private func activities(_ minutes: Int = 2, count: Int = 2) -> [PracticeActivity] {
        (0..<count).map { index in
            PracticeActivity(
                title: "Activity \(index + 1)",
                type: .custom,
                minutes: minutes,
                notes: []
            )
        }
    }

    func testStartUsesProvidedTimestampAndEntersRunningState() {
        var engine = PracticeTimerEngine()
        let items = activities()

        engine.start(at: epoch)

        XCTAssertEqual(engine.state, .running)
        XCTAssertEqual(engine.startedAt, epoch)
        XCTAssertNil(engine.pausedAt)
        XCTAssertEqual(engine.refresh(activities: items, at: epoch), 120, accuracy: 0.001)
    }

    func testPauseAndResumeExcludePausedTimeFromRemainingDuration() {
        var engine = PracticeTimerEngine()
        let items = activities()
        engine.start(at: epoch)

        engine.pause(at: epoch.addingTimeInterval(30))
        XCTAssertEqual(engine.state, .paused)
        XCTAssertEqual(engine.refresh(activities: items, at: epoch.addingTimeInterval(90)), 90, accuracy: 0.001)

        engine.resume(at: epoch.addingTimeInterval(90))
        XCTAssertEqual(engine.state, .running)
        XCTAssertNil(engine.pausedAt)
        XCTAssertEqual(engine.refresh(activities: items, at: epoch.addingTimeInterval(150)), 30, accuracy: 0.001)
    }

    func testTimestampDerivedExpirationTransitionsAtActivityDeadline() {
        var engine = PracticeTimerEngine()
        let items = activities(1, count: 1)
        engine.start(at: epoch)

        XCTAssertEqual(engine.refresh(activities: items, at: epoch.addingTimeInterval(59)), 1, accuracy: 0.001)
        XCTAssertEqual(engine.state, .running)
        XCTAssertEqual(engine.refresh(activities: items, at: epoch.addingTimeInterval(60)), 0, accuracy: 0.001)
        XCTAssertEqual(engine.state, .expired)
    }

    func testManualAdvanceRecordsTimestampAndClampsActivityIndex() {
        var engine = PracticeTimerEngine()
        let items = activities(count: 3)
        engine.start(at: epoch)
        let advancedAt = epoch.addingTimeInterval(15)

        engine.advance(to: 2, activities: items, at: advancedAt)

        XCTAssertEqual(engine.activityIndex, 2)
        XCTAssertEqual(engine.state, .running)
        XCTAssertEqual(engine.advancementTimestamps[items[2].id], advancedAt)

        engine.advance(to: 99, activities: items, at: advancedAt.addingTimeInterval(1))
        XCTAssertEqual(engine.activityIndex, 2)
    }

    func testFinishTransitionsToFinishedState() {
        var engine = PracticeTimerEngine()
        engine.start(at: epoch)

        engine.finish()

        XCTAssertEqual(engine.state, .finished)
    }
}
