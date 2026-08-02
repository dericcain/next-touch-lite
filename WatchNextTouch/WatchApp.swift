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
    let minutes: Int
    let notes: [String]
    init(id: UUID = UUID(), title: String, minutes: Int, notes: [String]) { self.id = id; self.title = title; self.minutes = minutes; self.notes = notes }
}

struct WatchPractice: Identifiable, Codable {
    let id: UUID
    let title: String
    let activities: [WatchActivity]
    var totalMinutes: Int { activities.reduce(0) { $0 + $1.minutes } }
    init(id: UUID = UUID(), title: String, activities: [WatchActivity]) { self.id = id; self.title = title; self.activities = activities }
}

private let samplePractice = WatchPractice(title: "Wednesday Training", activities: [
    .init(title: "Warm-Up", minutes: 10, notes: ["Movement prep"]),
    .init(title: "Rondo 4v2", minutes: 12, notes: ["Two-touch maximum"]),
    .init(title: "Positional Play", minutes: 20, notes: ["Find the free player"])
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
    var asWatchActivity: WatchActivity { WatchActivity(id: id, title: title, minutes: minutes, notes: notes) }
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
        VStack(spacing: 12) {
            Spacer()
            Text("READY TO COACH").font(.caption2)
            Text(practice.title).font(.title2.bold()).multilineTextAlignment(.center)
            Text("\(practice.totalMinutes)m total · \(practice.activities.count) activities")
            Spacer()
            NavigationLink { WatchLive(practice: practice) } label: {
                Label("Start Practice", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: NextTouchTheme.controlCornerRadius)).tint(.green)
            Text("Downloaded · ready offline").font(.caption2).foregroundStyle(.secondary)
        }
        .padding().navigationTitle("Preflight")
    }
}

struct WatchLive: View {
    let practice: WatchPractice
    @State private var index = 0
    @State private var state: LiveState = .running
    @State private var startedAt = Date()
    @State private var pausedAt: Date?
    @State private var pausedElapsed: TimeInterval = 0
    @State private var now = Date()
    @State private var showingFinish = false

    fileprivate enum LiveState: String, Codable { case running, paused, expired }
    private var activity: WatchActivity { practice.activities[index] }
    private var remaining: Int {
        guard state != .expired else { return 0 }
        let anchor = pausedAt ?? now
        let elapsed = max(0, anchor.timeIntervalSince(startedAt) - pausedElapsed)
        return max(0, Int(ceil(Double(activity.minutes * 60) - elapsed)))
    }

    var body: some View {
        ZStack {
            (state == .expired ? Color.yellow : Color.green).ignoresSafeArea()
            VStack(spacing: 10) {
                HStack { Text(activity.title); Spacer(); Text("\(index + 1) of \(practice.activities.count)") }.font(.caption)
                Text("\(remaining / 60):\(String(format: "%02d", remaining % 60))")
                    .font(.system(size: 54, design: .monospaced))
                Text(state == .paused ? "Paused" : state == .expired ? "Ready for next" : "Running").font(.caption.bold())
                if !activity.notes.isEmpty {
                    VStack(alignment: .leading) { ForEach(activity.notes, id: \.self) { Text("• \($0)").font(.caption) } }
                }
                Spacer()
                HStack {
                    Button { move(to: max(0, index - 1)) } label: { Image(systemName: "backward.end.fill") }.accessibilityLabel("Previous activity")
                    Button { togglePause() } label: { Image(systemName: state == .paused ? "play.fill" : "pause.fill") }.accessibilityLabel(state == .paused ? "Resume practice" : "Pause practice")
                    Button {
                        if index < practice.activities.count - 1 { move(to: index + 1) }
                    } label: { Image(systemName: "forward.end.fill") }.accessibilityLabel("Next activity")
                }.buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: NextTouchTheme.controlCornerRadius)).tint(.black)
                Button("Finish practice") { showingFinish = true }.font(.caption)
            }.padding()
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
        guard WCSession.isSupported(), let data = try? JSONEncoder().encode(summary) else { return }
        WCSession.default.transferUserInfo(["kind": "practice_run_summary", "schema": 1, "payload": data])
        UserDefaults.standard.removeObject(forKey: checkpointKey)
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
