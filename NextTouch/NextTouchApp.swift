import SwiftUI

@main
struct NextTouchApp: App {
    var body: some Scene {
        WindowGroup { PracticeLibraryView() }
    }
}

enum PracticeItemType: String, Codable, CaseIterable { case warmUp = "Warm-up", passing = "Passing", game = "Game", transition = "Transition", finishing = "Finishing", setPiece = "Set piece", recovery = "Recovery", custom = "Custom" }

struct PracticeActivity: Identifiable, Codable, Equatable, Hashable {
    var id = UUID(); var title: String; var type: PracticeItemType; var minutes: Int; var notes: [String]
    var symbol: String { switch type { case .warmUp: return "flame"; case .passing: return "arrow.triangle.2.circlepath"; case .game: return "sparkles"; case .transition: return "arrow.right"; case .finishing: return "target"; case .setPiece: return "flag"; case .recovery: return "wind"; case .custom: return "square.grid.2x2" } }
}

struct Practice: Identifiable, Codable, Hashable { var id = UUID(); var title: String; var date: String; var activities: [PracticeActivity]; var onWatch = true; var revision: Int = 1; var updatedAt = Date()
    var totalMinutes: Int { activities.reduce(0) { $0 + $1.minutes } }
    var totalText: String { "\(totalMinutes / 60)h \(String(format: "%02d", totalMinutes % 60))m" }
}

@MainActor final class PracticeStore: ObservableObject {
    @Published var practices: [Practice] = []
    @Published var selectedPractice: Practice?
    private let key = "nexttouch.practices"
    init() { if let data = UserDefaults.standard.data(forKey: key), let saved = try? JSONDecoder().decode([Practice].self, from: data) { practices = saved } else { practices = [.sample] } }
    func save(_ practice: Practice) {
        var updated = practice
        if let index = practices.firstIndex(where: { $0.id == practice.id }) {
            let existing = practices[index]
            let changed = existing.title != practice.title || existing.date != practice.date || existing.activities != practice.activities || existing.onWatch != practice.onWatch
            updated.revision = changed ? existing.revision + 1 : existing.revision
            updated.updatedAt = changed ? .now : existing.updatedAt
            practices[index] = updated
        } else {
            updated.revision = max(1, practice.revision)
            updated.updatedAt = .now
            practices.insert(updated, at: 0)
        }
        if let data = try? JSONEncoder().encode(practices) { UserDefaults.standard.set(data, forKey: key) }
        selectedPractice = nil
    }
    func duplicate(_ practice: Practice) { var copy = practice; copy.id = UUID(); copy.title += " Copy"; copy.activities = copy.activities.map { var activity = $0; activity.id = UUID(); return activity }; copy.revision = 1; practices.insert(copy, at: 0); persist() }
    func delete(_ practice: Practice) { practices.removeAll { $0.id == practice.id }; persist() }
    private func persist() { if let data = try? JSONEncoder().encode(practices) { UserDefaults.standard.set(data, forKey: key) } }
}

extension Practice { static let sample = Practice(title: "Wednesday Training", date: "Today · 6:00 PM", activities: [
    .init(title: "Warm-Up", type: .warmUp, minutes: 10, notes: ["Movement prep", "Ball mastery"]), .init(title: "Rondo 4v2", type: .passing, minutes: 12, notes: ["Two-touch maximum", "Win it, switch"]), .init(title: "Passing Pattern", type: .passing, minutes: 15, notes: ["Open body", "Play with tempo"]), .init(title: "Positional Play", type: .game, minutes: 20, notes: ["Find the free player"]), .init(title: "Transition Game", type: .transition, minutes: 15, notes: ["React on loss"]), .init(title: "Finishing", type: .finishing, minutes: 15, notes: ["Quality over speed"]), .init(title: "Set Pieces", type: .setPiece, minutes: 8, notes: []), .init(title: "Cool Down", type: .recovery, minutes: 5, notes: ["Bring the group in"])
]) }
