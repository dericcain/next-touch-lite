import SwiftUI

struct PracticeLibraryView: View {
    @StateObject private var store = PracticeStore()
    @StateObject private var bridge = WatchConnectivityBridge()
    @StateObject private var syncStore = PracticeSyncStore()
    @State private var showingWatch = false
    @State private var showingInbox = false
    @State private var deleteCandidate: Practice?
    var body: some View {
        NavigationStack {
            List {
                Section { if let next = store.practices.first { Button { store.selectedPractice = next } label: { UpNextRow(practice: next) }.buttonStyle(.plain) } } header: { Text("UP NEXT") }
                Section("All practices") { ForEach(store.practices) { practice in Button { store.selectedPractice = practice } label: { PracticeRow(practice: practice) }.buttonStyle(.plain).contextMenu { Button { store.duplicate(practice) } label: { Label("Duplicate", systemImage: "plus.square.on.square") } }.swipeActions { Button(role: .destructive) { deleteCandidate = practice } label: { Label("Delete", systemImage: "trash") } } } }
                Section { Button { showingWatch = true } label: { Label("Open watch companion", systemImage: "applewatch") } }
            }
            .listStyle(.insetGrouped).navigationTitle("Practices").toolbar { ToolbarItemGroup(placement: .topBarTrailing) { Button { showingInbox = true } label: { Image(systemName: "arrow.triangle.2.circlepath") }; Button { store.selectedPractice = Practice(title: "New Practice", date: "Not scheduled", activities: []) } label: { Image(systemName: "plus") } } }
            .navigationDestination(item: $store.selectedPractice) { practice in
                PracticeEditorView(practice: practice) { saved in
                    store.save(saved)
                    syncStore.download(saved)
                    if let snapshot = syncStore.snapshots[saved.id] { bridge.send(snapshot: snapshot) }
                }
            }
            .navigationDestination(isPresented: $showingWatch) {
                if let practice = store.practices.first { WatchPracticeView(practice: practice) }
                else { ContentUnavailableView("No practice available", systemImage: "applewatch", description: Text("Create a practice before opening the watch companion.")) }
            }
            .navigationDestination(isPresented: $showingInbox) { SyncInboxView(bridge: bridge, syncStore: syncStore) }
            .task { bridge.activate() }
            .alert("Delete practice?", isPresented: Binding(get: { deleteCandidate != nil }, set: { if !$0 { deleteCandidate = nil } })) { Button("Cancel", role: .cancel) {}; Button("Delete", role: .destructive) { if let deleteCandidate { store.delete(deleteCandidate) }; deleteCandidate = nil } } message: { Text("This removes the local plan. Any downloaded watch snapshot remains unchanged until the next sync.") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
    }
}

private struct UpNextRow: View { let practice: Practice; var body: some View { HStack(spacing: 14) { Image(systemName: "calendar").font(.title3).foregroundStyle(.white).frame(width: 44, height: 44).background(Color.nextTouch, in: RoundedRectangle(cornerRadius: 4)); VStack(alignment: .leading, spacing: 5) { Text(practice.title).font(.headline); Label("\(practice.date)  ·  \(practice.activities.count) activities  ·  \(practice.totalText)", systemImage: "calendar").font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) }.padding(.vertical, 5) } }
private struct PracticeRow: View { let practice: Practice; var body: some View { HStack { Image(systemName: "calendar").foregroundStyle(Color.nextTouch); VStack(alignment: .leading, spacing: 4) { Text(practice.title).font(.subheadline.weight(.semibold)); Text("\(practice.date)  ·  \(practice.activities.count) activities  ·  \(practice.totalText)").font(.caption).foregroundStyle(.secondary) }; Spacer(); Text(practice.onWatch ? "On Watch" : "Not on Watch").font(.caption2.weight(.semibold)).foregroundStyle(practice.onWatch ? Color.nextTouch : .secondary); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary) } } }
extension Color { static let nextTouch = Color(red: 0.62, green: 0.07, blue: 0.15) }
