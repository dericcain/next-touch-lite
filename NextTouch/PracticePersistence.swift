import Foundation
import SwiftData

@Model final class PracticeRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var scheduledLabel: String
    var activityData: Data
    var revision: Int
    var updatedAt: Date
    var onWatch: Bool

    init(practice: Practice) {
        id = practice.id; title = practice.title; scheduledLabel = practice.date; activityData = (try? JSONEncoder().encode(practice.activities)) ?? Data(); revision = practice.revision; updatedAt = practice.updatedAt; onWatch = practice.onWatch
    }

    func update(from practice: Practice) { title = practice.title; scheduledLabel = practice.date; activityData = (try? JSONEncoder().encode(practice.activities)) ?? Data(); revision = practice.revision; updatedAt = practice.updatedAt; onWatch = practice.onWatch }
    func value() -> Practice? { guard let activities = try? JSONDecoder().decode([PracticeActivity].self, from: activityData) else { return nil }; return Practice(id: id, title: title, date: scheduledLabel, activities: activities, onWatch: onWatch, revision: revision, updatedAt: updatedAt) }
}

@MainActor final class PracticeRepository {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }
    func all() throws -> [Practice] { try context.fetch(FetchDescriptor<PracticeRecord>(sortBy: [SortDescriptor(\PracticeRecord.updatedAt, order: .reverse)])).compactMap { $0.value() } }
    func save(_ practice: Practice) throws { if let record = try context.fetch(FetchDescriptor<PracticeRecord>(predicate: #Predicate { $0.id == practice.id })).first { record.update(from: practice) } else { context.insert(PracticeRecord(practice: practice)) }; try context.save() }
    func delete(_ practice: Practice) throws { if let record = try context.fetch(FetchDescriptor<PracticeRecord>(predicate: #Predicate { $0.id == practice.id })).first { context.delete(record); try context.save() } }
}
