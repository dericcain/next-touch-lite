import SwiftUI
import WatchConnectivity
import UserNotifications

@main
struct WatchNextTouchApp: App {
    var body: some Scene { WindowGroup { WatchPracticeList() } }
}

struct WatchActivity: Identifiable, Codable {
    let id: UUID
    let title: String
    let category: String
    let minutes: Int
    let notes: [String]
    init(id: UUID = UUID(), title: String, category: String = "", minutes: Int, notes: [String]) { self.id = id; self.title = title; self.category = category; self.minutes = minutes; self.notes = notes }
    private enum CodingKeys: String, CodingKey { case id, title, category, minutes, notes }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        minutes = try container.decode(Int.self, forKey: .minutes)
        notes = try container.decode([String].self, forKey: .notes)
    }
}

struct WatchPractice: Identifiable, Codable {
    let id: UUID
    let title: String
    let activities: [WatchActivity]
    var totalMinutes: Int { activities.reduce(0) { $0 + $1.minutes } }
    init(id: UUID = UUID(), title: String, activities: [WatchActivity]) { self.id = id; self.title = title; self.activities = activities }
}

private let samplePractice = WatchPractice(title: "Wednesday Training", activities: [
    .init(title: "Warm-Up", category: "Warm-up", minutes: 10, notes: ["Movement prep"]),
    .init(title: "Rondo 4v2", category: "Passing", minutes: 12, notes: ["Two-touch maximum"]),
    .init(title: "Positional Play", category: "Game", minutes: 20, notes: ["Find the free player"])
])

@MainActor final class WatchSnapshotStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var practices: [WatchPractice] = []
    private let key = "nexttouch.watch.importedPractices"

    override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: key), let saved = try? JSONDecoder().decode([WatchPractice].self, from: data) { practices = saved }
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard userInfo["kind"] as? String == "practice_snapshot", let data = userInfo["payload"] as? Data else { return }
        Task { @MainActor in self.install(data) }
    }
    private func install(_ data: Data) {
        guard let snapshot = try? JSONDecoder().decode(WatchSnapshot.self, from: data) else { return }
        let practice = snapshot.practice.asWatchPractice
        practices.removeAll { $0.id == practice.id }
        practices.append(practice)
        if let encoded = try? JSONEncoder().encode(practices) { UserDefaults.standard.set(encoded, forKey: key) }
    }
}

private struct WatchSnapshot: Codable { let practice: WatchPayloadPractice }
private struct WatchPayloadPractice: Codable {
    let id: UUID; let title: String; let activities: [WatchPayloadActivity]
    var asWatchPractice: WatchPractice { WatchPractice(id: id, title: title, activities: activities.map { $0.asWatchActivity }) }
}
private struct WatchPayloadActivity: Codable {
    let id: UUID; let title: String; let type: String; let minutes: Int; let notes: [String]
    var asWatchActivity: WatchActivity { WatchActivity(id: id, title: title, category: type, minutes: minutes, notes: notes) }
}

struct WatchPracticeList: View {
    @StateObject private var snapshotStore = WatchSnapshotStore()
    var body: some View {
        NavigationStack {
            List {
                ForEach(snapshotStore.practices.isEmpty ? [samplePractice] : snapshotStore.practices) { practice in
                    NavigationLink { WatchPreflight(practice: practice) } label: {
                        VStack(alignment: .leading) {
                            Text(practice.title)
                            Text("\(practice.totalMinutes)m · \(practice.activities.count) activities")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Practices")
        }
    }
}

struct WatchPreflight: View {
    let practice: WatchPractice

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 8) {
                Text(practice.title)
                    .font(.headline.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                NavigationLink { WatchLive(practice: practice) } label: {
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .frame(width: 48, height: 48)
                }
                .accessibilityLabel("Start practice")
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(.green)
                .padding(.vertical, 6)

                Text("\(practice.totalMinutes)m total · \(practice.activities.count) activities")
                    .font(.caption2)

                Divider()
                    .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(practice.activities.enumerated()), id: \.element.id) { number, activity in
                        HStack(spacing: 6) {
                            Text("\(number + 1)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: 14, alignment: .leading)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(activity.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                if !activity.category.isEmpty {
                                    Text(activity.category)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer(minLength: 4)
                            Text("\(activity.minutes)m")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, NextTouchTheme.watchContentPadding)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
    }
}

struct WatchLive: View {
    let practice: WatchPractice
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var state: LiveState = .running
    @State private var startedAt = Date()
    @State private var pausedAt: Date?
    @State private var pausedElapsed: TimeInterval = 0
    @State private var now = Date()
    @State private var showingFinish = false
    @State private var showingNotes = false

    fileprivate enum LiveState: String, Codable { case running, paused, expired }
    private var activity: WatchActivity { practice.activities[index] }
    private var nextActivity: WatchActivity? {
        let nextIndex = index + 1
        guard practice.activities.indices.contains(nextIndex) else { return nil }
        return practice.activities[nextIndex]
    }
    private var remaining: Int {
        guard state != .expired else { return 0 }
        let anchor = pausedAt ?? now
        let elapsed = max(0, anchor.timeIntervalSince(startedAt) - pausedElapsed)
        return max(0, Int(ceil(Double(activity.minutes * 60) - elapsed)))
    }

    var body: some View {
        ZStack {
            (state == .expired ? Color.yellow : Color.green)
                .opacity(state == .paused ? 0.58 : 1)
                .ignoresSafeArea()
            ScrollView(.vertical) {
                VStack(spacing: NextTouchTheme.watchVerticalSpacing) {
                    HStack {
                        Text("\(practice.totalMinutes)m total")
                        Spacer(minLength: 4)
                        Text("\(index + 1) of \(practice.activities.count)")
                    }
                    .font(.caption2)
                    .minimumScaleFactor(0.8)
                    HStack(spacing: 6) {
                        Image(systemName: activitySymbol(for: activity.category))
                            .font(.caption)
                            .frame(width: 20)
                        Text(activity.title)
                            .font(.caption)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Spacer(minLength: 2)
                        if !activity.notes.isEmpty {
                            Button { showingNotes = true } label: {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Show coach notes")
                        }
                    }
                    HStack(spacing: 4) {
                        Button { move(to: max(0, index - 1)) } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3.bold())
                                .frame(width: 30, height: 54)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Previous activity")
                        .disabled(index == 0)

                        Button { togglePause() } label: {
                            Text("\(remaining / 60):\(String(format: "%02d", remaining % 60))")
                                .font(.system(size: NextTouchTheme.watchTimerFontSize, design: .monospaced))
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(state == .paused ? "Resume timer" : "Pause timer")

                        Button {
                            if index < practice.activities.count - 1 { move(to: index + 1) }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title3.bold())
                                .frame(width: 30, height: 54)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Next activity")
                        .disabled(index >= practice.activities.count - 1)
                    }
                    Text(state == .paused ? "Paused" : state == .expired ? "Ready for next" : "Running")
                        .font(.caption2.bold())
                    if let note = activity.notes.first {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                            Text(note).lineLimit(1)
                        }
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider().overlay(Color.black.opacity(0.35))
                    if let nextActivity {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Next up").font(.caption2)
                            HStack {
                                Text(nextActivity.title).lineLimit(1).minimumScaleFactor(0.75)
                                Spacer(minLength: 4)
                                Text("\(nextActivity.minutes)m")
                            }
                            .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    // Keep this consequential action below the initial viewport.
                    Button("Finish practice") { showingFinish = true }
                        .font(.caption2)
                        .padding(.top, 10)
                }
                .padding(.horizontal, NextTouchTheme.watchContentPadding)
                .padding(.top, 2)
                .padding(.bottom, 6)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingNotes) {
            WatchNotesSheet(activity: activity)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { tick in
            now = tick
            if state == .running && remaining == 0 { state = .expired }
        }
        .onChange(of: index) { _, _ in saveCheckpoint() }
        .onChange(of: state) { _, _ in saveCheckpoint() }
        .onChange(of: pausedElapsed) { _, _ in saveCheckpoint() }
        .confirmationDialog("Finish practice?", isPresented: $showingFinish) {
            Button("Keep Coaching", role: .cancel) {}
            Button("Finish", role: .destructive) { finish() }
        } message: { Text("Your run will be saved and sent to iPhone when available.") }
        .task {
            restoreCheckpoint()
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            scheduleAlerts()
        }
    }

    private func togglePause() {
        if state == .paused {
            if let pausedAt { pausedElapsed += now.timeIntervalSince(pausedAt) }
            self.pausedAt = nil; state = .running
            scheduleAlerts()
        } else if state == .running {
            cancelAlerts()
            pausedAt = now; state = .paused
        }
    }

    private func move(to newIndex: Int) {
        guard !practice.activities.isEmpty else { return }
        cancelAlerts()
        index = newIndex
        startedAt = now; pausedAt = nil; pausedElapsed = 0; state = .running
        scheduleAlerts()
    }

    private func finish() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let summary = WatchRunSummary(id: UUID(), practiceID: practice.id, practiceRevision: 1, startedAt: startedAt, endedAt: now, completed: index == practice.activities.count - 1 && state == .expired, advancementTimestamps: [:])
        if WCSession.isSupported(), let data = try? JSONEncoder().encode(summary) {
            WCSession.default.transferUserInfo(["kind": "practice_run_summary", "schema": 1, "payload": data])
        }
        UserDefaults.standard.removeObject(forKey: checkpointKey)
        dismiss()
    }

    private func activitySymbol(for category: String) -> String {
        switch category.lowercased() {
        case "passing": return "arrow.left.arrow.right"
        case "game": return "sparkles"
        case "warm-up", "warmup": return "flame"
        default: return "circle.grid.2x2"
        }
    }

    private func scheduleAlerts() {
        var cursor = now
        for (offset, activity) in practice.activities.enumerated().dropFirst(index) {
            let duration = offset == index ? TimeInterval(max(1, remaining)) : TimeInterval(activity.minutes * 60)
            let end = cursor.addingTimeInterval(duration)
            let completion = UNMutableNotificationContent()
            completion.title = practice.title
            completion.body = "(activity.title) complete"
            completion.sound = .default
            let completionRequest = UNNotificationRequest(identifier: "nexttouch.complete.\(practice.id).\(offset)", content: completion, trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, end.timeIntervalSinceNow), repeats: false))
            UNUserNotificationCenter.current().add(completionRequest)
            if activity.minutes > 1 {
                let warning = UNMutableNotificationContent()
                warning.title = "One minute left"
                warning.body = activity.title
                warning.sound = .default
                let warningRequest = UNNotificationRequest(identifier: "nexttouch.warning.\(practice.id).\(offset)", content: warning, trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, end.addingTimeInterval(-60).timeIntervalSinceNow), repeats: false))
                UNUserNotificationCenter.current().add(warningRequest)
            }
            cursor = end
        }
    }

    private func cancelAlerts() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private var checkpointKey: String { "nexttouch.watch.activeRun.\(practice.id.uuidString)" }
    private func saveCheckpoint() {
        let checkpoint = WatchRunCheckpoint(index: index, state: state, startedAt: startedAt, pausedAt: pausedAt, pausedElapsed: pausedElapsed)
        if let data = try? JSONEncoder().encode(checkpoint) { UserDefaults.standard.set(data, forKey: checkpointKey) }
    }
    private func restoreCheckpoint() {
        guard let data = UserDefaults.standard.data(forKey: checkpointKey), let checkpoint = try? JSONDecoder().decode(WatchRunCheckpoint.self, from: data) else { return }
        index = min(max(0, checkpoint.index), max(0, practice.activities.count - 1))
        state = checkpoint.state
        startedAt = checkpoint.startedAt
        pausedAt = checkpoint.pausedAt
        pausedElapsed = checkpoint.pausedElapsed
    }
}

private struct WatchNotesSheet: View {
    let activity: WatchActivity
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Coach notes").font(.headline)
                Spacer()
                Button("Done") { dismiss() }.font(.caption)
            }
            Text(activity.title).font(.caption.bold())
            ForEach(activity.notes, id: \.self) { note in
                HStack(alignment: .top, spacing: 5) {
                    Image(systemName: "info.circle")
                    Text(note).font(.caption2)
                }
            }
        }
        .padding()
    }
}

private struct WatchRunCheckpoint: Codable {
    let index: Int
    let state: WatchLive.LiveState
    let startedAt: Date
    let pausedAt: Date?
    let pausedElapsed: TimeInterval
}

private struct WatchRunSummary: Codable {
    var schemaVersion: Int = 1
    let id: UUID
    let practiceID: UUID
    let practiceRevision: Int
    let startedAt: Date
    let endedAt: Date
    let completed: Bool
    let advancementTimestamps: [UUID: Date]
    var textNotes: [String] = []
}
