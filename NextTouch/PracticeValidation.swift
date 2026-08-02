import Foundation

enum PracticeValidationError: LocalizedError { case titleLength, noActivities, invalidDuration, notesTooLong, invalidOrder; var errorDescription: String? { switch self { case .titleLength: return "Title must be 2–140 characters."; case .noActivities: return "Add at least one activity."; case .invalidDuration: return "Activity durations must be whole minutes from 1–180."; case .notesTooLong: return "Coaching notes exceed 2,000 characters."; case .invalidOrder: return "Activity order is invalid." } } }

struct PracticeValidator {
    static func validate(_ practice: Practice) throws {
        let title = practice.title.trimmingCharacters(in: .whitespacesAndNewlines); guard (2...140).contains(title.count) else { throw PracticeValidationError.titleLength }
        guard !practice.activities.isEmpty else { throw PracticeValidationError.noActivities }
        guard practice.activities.allSatisfy({ (1...180).contains($0.minutes) }) else { throw PracticeValidationError.invalidDuration }
        guard practice.activities.allSatisfy({ $0.notes.count <= 3 && $0.notes.joined(separator: "\n").count <= 2_000 }) else { throw PracticeValidationError.notesTooLong }
        guard practice.activities.indices.allSatisfy({ $0 < practice.activities.count }) else { throw PracticeValidationError.invalidOrder }
    }
    static func normalized(_ practice: Practice) -> Practice { var copy = practice; copy.title = copy.title.trimmingCharacters(in: .whitespacesAndNewlines); copy.activities = copy.activities.map { var activity = $0; activity.title = activity.title.trimmingCharacters(in: .whitespacesAndNewlines); activity.notes = activity.notes.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }; return activity }; return copy }
}
