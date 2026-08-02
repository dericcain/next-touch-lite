import SwiftUI

struct SyncInboxView: View {
    @ObservedObject var bridge: WatchConnectivityBridge
    @ObservedObject var syncStore: PracticeSyncStore
    @State private var showingRetry = false
    var body: some View {
        List {
            Section("Received runs") {
                if syncStore.receivedRuns.isEmpty { ContentUnavailableView("No synced runs", systemImage: "arrow.triangle.2.circlepath", description: Text("Completed offline runs will appear here when the watch reconnects.")) }
                ForEach(syncStore.receivedRuns) { run in HStack { Image(systemName: run.completed ? "checkmark.circle.fill" : "exclamationmark.circle").foregroundStyle(run.completed ? .green : .orange); VStack(alignment: .leading) { Text(run.completed ? "Completed practice" : "Ended early").font(.subheadline.weight(.semibold)); Text(run.endedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary) }; Spacer(); Text("Sent").font(.caption2).foregroundStyle(.secondary) } }
            }
            Section {
                Button {
                    syncStore.pendingRuns.forEach(bridge.send(summary:))
                    showingRetry = true
                } label: { Label("Retry pending sync", systemImage: "arrow.clockwise") }
                if !syncStore.pendingRuns.isEmpty { Text("\(syncStore.pendingRuns.count) run(s) queued") }
            }
        }.navigationTitle("Sync Inbox").alert("Retry queued", isPresented: $showingRetry) { Button("OK", role: .cancel) {} } message: { Text("Pending summaries will be retried when the watch is reachable.") }
    }
}
