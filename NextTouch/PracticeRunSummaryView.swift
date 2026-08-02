import SwiftUI

struct PracticeRunSummaryView: View {
    let practice: Practice
    let completed: Bool
    let startedAt: Date
    let endedAt: Date
    var body: some View {
        List {
            Section { Label(completed ? "Completed" : "Ended Early", systemImage: completed ? "checkmark.circle.fill" : "exclamationmark.circle.fill").foregroundStyle(completed ? .green : .orange); Text(practice.title).font(.title3.bold()); Text("Planned \(practice.totalText) · \(endedAt.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary) }
            Section("Activity timeline") { ForEach(practice.activities) { activity in HStack { Image(systemName: activity.symbol).foregroundStyle(Color.nextTouch); Text(activity.title); Spacer(); Text("\(activity.minutes)m").monospacedDigit().foregroundStyle(.secondary) } } }
            Section { Label("Sync pending", systemImage: "arrow.triangle.2.circlepath").font(.caption).foregroundStyle(.secondary) }
        }.listStyle(.plain).navigationTitle("Practice Result")
    }
}
