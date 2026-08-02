import Foundation

enum PracticeRunState: String, Codable { case idle, running, paused, expired, finished }

struct PracticeTimerEngine: Codable {
    private(set) var state: PracticeRunState = .idle
    private(set) var activityIndex = 0
    private(set) var startedAt: Date?
    private(set) var pausedAt: Date?
    private(set) var accumulatedPause: TimeInterval = 0
    private(set) var advancementTimestamps: [UUID: Date] = [:]

    mutating func start(at date: Date = .now) { guard state == .idle else { return }; startedAt = date; state = .running }
    mutating func pause(at date: Date = .now) { guard state == .running else { return }; pausedAt = date; state = .paused }
    mutating func resume(at date: Date = .now) { guard state == .paused, let pausedAt else { return }; accumulatedPause += date.timeIntervalSince(pausedAt); self.pausedAt = nil; state = .running }
    mutating func advance(to index: Int, activities: [PracticeActivity], at date: Date = .now) { guard !activities.isEmpty else { return }; activityIndex = min(max(index, 0), activities.count - 1); advancementTimestamps[activities[activityIndex].id] = date; state = .running }
    mutating func finish() { state = .finished }
    mutating func refresh(activities: [PracticeActivity], at date: Date = .now) -> TimeInterval { guard let startedAt, activityIndex < activities.count else { return 0 }; let anchor = pausedAt ?? date; let elapsed = max(0, anchor.timeIntervalSince(startedAt) - accumulatedPause); let duration = TimeInterval(activities[activityIndex].minutes * 60); if state == .running && elapsed >= duration { state = .expired; return 0 }; return max(0, duration - elapsed) }
}
