import SwiftUI

struct WatchPracticeView: View {
    let practice: Practice
    @Environment(\.dismiss) private var dismiss
    @State private var engine = PracticeTimerEngine()
    @State private var now = Date()
    @State private var showFinishConfirmation = false
    @State private var showSummary = false
    @State private var startedAt = Date()
    @StateObject private var syncStore = PracticeSyncStore()
    @StateObject private var connectivity = WatchConnectivityBridge()

    private var current: PracticeActivity { practice.activities[min(engine.activityIndex, max(0, practice.activities.count - 1))] }
    private var remaining: TimeInterval {
        var copy = engine
        return copy.refresh(activities: practice.activities, at: now)
    }
    private var timerText: String { let seconds = max(0, Int(remaining.rounded(.up))); return "\(seconds / 60):\(String(format: "%02d", seconds % 60))" }

    var body: some View {
        ZStack { (engine.state == .expired ? Color.yellow : engine.state == .running || engine.state == .paused ? Color.green : Color.black).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack { Button { dismiss() } label: { Image(systemName: "chevron.left") }; Spacer(); Text("WATCH COMPANION").font(.caption2.weight(.semibold)); Spacer(); Image(systemName: "ellipsis") }.foregroundStyle(engine.state == .idle ? .white : .black)
                if engine.state == .idle { preflight } else { liveMode }
            }.padding(24)
        }.onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now = $0 }
        .task { _ = await PracticeNotificationService.shared.requestAuthorization(); connectivity.activate() }
        .confirmationDialog("Finish practice?", isPresented: $showFinishConfirmation) { Button("Keep Coaching", role: .cancel) {}; Button("Finish", role: .destructive) { finishRun() } } message: { Text("Your run will be saved before returning to the phone.") }
        .sheet(isPresented: $showSummary) { NavigationStack { PracticeRunSummaryView(practice: practice, completed: engine.activityIndex == practice.activities.count - 1 && engine.state == .finished, startedAt: startedAt, endedAt: now) } }
    }

    private var preflight: some View { VStack(spacing: 14) { Spacer(); Text("READY TO COACH").font(.caption2.weight(.bold)); Text(practice.title).font(.system(size: 40, weight: .bold, design: .rounded)).multilineTextAlignment(.center); Label("\(practice.totalText) total", systemImage: "clock").padding(.top, 18); Spacer(); Button { startedAt = now; engine.start(at: now); scheduleAlerts() } label: { Label("Start Practice", systemImage: "play.fill").padding(.horizontal, 24).padding(.vertical, 14) }.buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: NextTouchTheme.controlCornerRadius)).tint(.nextTouch); Text("Downloaded · ready offline").font(.caption).foregroundStyle(.secondary) } }

    private func scheduleAlerts() { var cursor = now; for activity in practice.activities { let end = cursor.addingTimeInterval(TimeInterval(activity.minutes * 60)); PracticeNotificationService.shared.scheduleCompletion(practice: practice, activity: activity, fireDate: end); if activity.minutes > 1 { PracticeNotificationService.shared.scheduleWarning(practice: practice, activity: activity, fireDate: end.addingTimeInterval(-60)) }; cursor = end } }
    private func finishRun() { engine.finish(); let summary = PracticeRunSummary(id: UUID(), practiceID: practice.id, practiceRevision: practice.revision, startedAt: startedAt, endedAt: now, completed: engine.activityIndex == practice.activities.count - 1, advancementTimestamps: engine.advancementTimestamps); syncStore.queue(summary); connectivity.send(summary: summary); showSummary = true }

    private var liveMode: some View { VStack(spacing: 18) { HStack { Text("\(practice.totalText) total"); Spacer(); Text("\(engine.activityIndex + 1) of \(practice.activities.count)") }.font(.caption); HStack { Image(systemName: current.symbol); Text(engine.state == .expired ? "Ready for next" : current.title).font(.headline); Spacer(); Text("Notes").font(.caption) }; Text(timerText).font(.system(size: 78, weight: .regular, design: .monospaced)); Divider(); if !current.notes.isEmpty { VStack(alignment: .leading, spacing: 4) { ForEach(current.notes, id: \.self) { Text("• \($0)").font(.caption) } }.frame(maxWidth: .infinity, alignment: .leading) }; HStack { VStack(alignment: .leading) { Text("NEXT UP").font(.caption2); Text(engine.activityIndex + 1 < practice.activities.count ? practice.activities[engine.activityIndex + 1].title : "Practice complete").font(.headline) }; Spacer(); if engine.activityIndex + 1 < practice.activities.count { Text("\(practice.activities[engine.activityIndex + 1].minutes)m").monospacedDigit() } }; Spacer(); HStack { Button { engine.advance(to: max(0, engine.activityIndex - 1), activities: practice.activities, at: now) } label: { Image(systemName: "backward.end.fill") }.accessibilityLabel("Previous activity"); Button { if engine.state == .paused { engine.resume(at: now) } else { engine.pause(at: now) } } label: { Image(systemName: engine.state == .paused ? "play.fill" : "pause.fill") }.accessibilityLabel(engine.state == .paused ? "Resume practice" : "Pause practice"); Button { if engine.activityIndex < practice.activities.count - 1 { engine.advance(to: engine.activityIndex + 1, activities: practice.activities, at: now) } else { _ = engine.refresh(activities: practice.activities, at: now) } } label: { Image(systemName: "forward.end.fill") }.accessibilityLabel("Next activity") }.buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: NextTouchTheme.controlCornerRadius)).tint(.black); Button("Finish practice") { showFinishConfirmation = true }.font(.caption) }.padding(.top, 36) }
}
