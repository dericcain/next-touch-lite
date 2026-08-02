import Foundation

protocol PracticeRepository { func practices() async throws -> [Practice]; func save(_ practice: Practice) async throws; func delete(id: UUID) async throws; func duplicate(id: UUID) async throws -> Practice }
protocol RunRepository { func save(_ run: PracticeRunSummary) async throws; func pendingWatchTransfers() async throws -> [PracticeRunSummary] }

actor LocalPracticeRepository: PracticeRepository, RunRepository {
    private let practicesKey = "nexttouch.repository.practices"
    private let runsKey = "nexttouch.repository.runs"
    private var practiceCache: [Practice]
    private var runCache: [PracticeRunSummary]
    init() { practiceCache = (try? JSONDecoder().decode([Practice].self, from: UserDefaults.standard.data(forKey: practicesKey) ?? Data())) ?? [.sample]; runCache = (try? JSONDecoder().decode([PracticeRunSummary].self, from: UserDefaults.standard.data(forKey: runsKey) ?? Data())) ?? [] }
    func practices() async throws -> [Practice] { practiceCache }
    func save(_ practice: Practice) async throws { if let index = practiceCache.firstIndex(where: { $0.id == practice.id }) { practiceCache[index] = practice } else { practiceCache.insert(practice, at: 0) }; persist() }
    func delete(id: UUID) async throws { practiceCache.removeAll { $0.id == id }; persist() }
    func duplicate(id: UUID) async throws -> Practice { guard var copy = practiceCache.first(where: { $0.id == id }) else { throw RepositoryError.notFound }; copy.id = UUID(); copy.title += " Copy"; copy.activities = copy.activities.map { var item = $0; item.id = UUID(); return item }; practiceCache.insert(copy, at: 0); persist(); return copy }
    func save(_ run: PracticeRunSummary) async throws { if !runCache.contains(where: { $0.id == run.id }) { runCache.append(run); persist() } }
    func pendingWatchTransfers() async throws -> [PracticeRunSummary] { runCache }
    private func persist() { if let data = try? JSONEncoder().encode(practiceCache) { UserDefaults.standard.set(data, forKey: practicesKey) }; if let data = try? JSONEncoder().encode(runCache) { UserDefaults.standard.set(data, forKey: runsKey) } }
}
enum RepositoryError: Error { case notFound }
