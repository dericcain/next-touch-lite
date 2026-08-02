import Foundation

enum PracticeSchema { static let version = 1 }
enum PlannedItemType: String, Codable, CaseIterable { case libraryDrill = "library_drill", customDrill = "custom_drill", waterBreak = "water_break", coachDiscussion = "coach_discussion", scrimmage, other }
enum DrillCategory: String, Codable, CaseIterable { case warmUp = "warm_up", passing, possession, transition, finishing, defending, scrimmage, recovery, other }
struct PracticeRunEvent: Codable, Identifiable { let id: UUID; let activityID: UUID; let occurredAt: Date; let kind: Kind; enum Kind: String, Codable { case advanced, paused, resumed, expired } }
struct SnapshotEnvelope: Codable { let schemaVersion: Int; let kind: Kind; let payload: Data; enum Kind: String, Codable { case practiceSnapshot, practiceRunSummary } }
