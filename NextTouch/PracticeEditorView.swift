import SwiftUI

struct PracticeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var practice: Practice
    let onSave: (Practice) -> Void
    @State private var editingIndex: Int?
    @State private var showAddChoices = false
    @State private var showDrillPicker = false
    @State private var showDatePicker = false
    @State private var scheduledDate = Date()
    @State private var validationMessage: String?
    @StateObject private var bridge = WatchConnectivityBridge()

    var body: some View {
        VStack(spacing: 0) {
                Form {
                    Section {
                        TextField("Practice title", text: $practice.title)
                        Button {
                            showDatePicker = true
                        } label: {
                            Label(practice.date, systemImage: "calendar")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .foregroundStyle(.primary)
                    }
                    .listRowBackground(NextTouchTheme.cardBackground)
                    Section("ACTIVITIES") {
                        ForEach(practice.activities.indices, id: \.self) { index in
                            ActivityRow(activity: practice.activities[index])
                                .contentShape(Rectangle())
                                .onTapGesture { editingIndex = index }
                                .swipeActions { Button(role: .destructive) { practice.activities.remove(at: index) } label: { Label("Delete", systemImage: "trash") } }
                        }
                        .onMove { practice.activities.move(fromOffsets: $0, toOffset: $1) }
                        Button { showAddChoices = true } label: { Label("Add Activity", systemImage: "plus") }.foregroundStyle(Color.nextTouch)
                    }
                    .listRowBackground(NextTouchTheme.cardBackground)
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.active))
                VStack(spacing: 10) {
                    Label(bridge.isReachable ? "Watch connected" : "Watch sync queued offline", systemImage: bridge.isReachable ? "applewatch.radiowaves.left.and.right" : "icloud.slash").font(.caption2).foregroundStyle(.secondary)
                    Text("\(practice.activities.count) activities  ·  \(practice.totalText)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                    Button { commitSave(sync: true) } label: { Label("Save & sync to Watch", systemImage: "applewatch") .frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: 4)).tint(.nextTouch)
                }.padding()
            }
            .navigationTitle("Practice Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { commitSave(sync: false) }.fontWeight(.semibold) } }
            .sheet(isPresented: Binding(get: { editingIndex != nil }, set: { if !$0 { editingIndex = nil } })) { if let index = editingIndex { ActivityEditor(activity: $practice.activities[index]) } }
            .sheet(isPresented: $showDrillPicker) { DrillPickerView { activity in practice.activities.append(activity); editingIndex = practice.activities.count - 1 } }
            .sheet(isPresented: $showDatePicker) {
                NavigationStack {
                    Form {
                        Section("Schedule") {
                            DatePicker("Date and time", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                        }
                        Section {
                            Button("Remove schedule", role: .destructive) {
                                practice.date = "Not scheduled"
                                showDatePicker = false
                            }
                        }
                    }
                    .listStyle(.plain)
                    .navigationTitle("Practice date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                practice.date = formattedDate(scheduledDate)
                                showDatePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .confirmationDialog("Add activity", isPresented: $showAddChoices) { Button("Drill") { showDrillPicker = true }; Button("Coach Talk") { addActivity(title: "Coach Talk", type: .custom) }; Button("Water Break") { addActivity(title: "Water Break", type: .recovery) }; Button("Scrimmage") { addActivity(title: "Scrimmage", type: .game) }; Button("Custom") { addActivity(title: "New Activity", type: .custom) } }
            .task { bridge.activate() }
            .alert("Practice needs attention", isPresented: Binding(get: { validationMessage != nil }, set: { if !$0 { validationMessage = nil } })) { Button("OK", role: .cancel) {} } message: { Text(validationMessage ?? "") }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(NextTouchTheme.pageBackground.ignoresSafeArea())
    }

    private func addActivity(title: String, type: PracticeItemType) { practice.activities.append(.init(title: title, type: type, minutes: 10, notes: [])); editingIndex = practice.activities.count - 1 }
    private func commitSave(sync: Bool) { let candidate = PracticeValidator.normalized(practice); do { try PracticeValidator.validate(candidate); if sync { let snapshot = PracticeSnapshot(id: UUID(), practiceID: candidate.id, revision: candidate.revision, createdAt: .now, practice: candidate); bridge.send(snapshot: snapshot) }; onSave(candidate); dismiss() } catch { validationMessage = error.localizedDescription } }
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct ActivityEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var activity: PracticeActivity
    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    TextField("Title", text: $activity.title)
                    Picker("Type", selection: $activity.type) { ForEach(PracticeItemType.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                    Stepper("Duration · \(activity.minutes) min", value: $activity.minutes, in: 1...180)
                }
                if let drill = starterDrills.first(where: { $0.name == activity.title }) {
                    Section("Drill details") {
                        DrillDetailsDisclosure(drill: drill)
                    }
                }
                Section("Coaching notes") {
                    TextEditor(text: Binding(
                        get: { activity.notes.joined(separator: "\n") },
                        set: { activity.notes = $0.components(separatedBy: "\n") }
                    ))
                    .frame(minHeight: 140)
                    .overlay(alignment: .topLeading) {
                        if activity.notes.joined().isEmpty {
                            Text("Add coaching points, setup, and instructions…")
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { activity.notes = activity.notes.filter { !$0.isEmpty }; dismiss() } } }
        }
    }
}

private struct DrillDetailsDisclosure: View {
    let drill: DrillCatalogItem
    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                detail("What to do", drill.description)
                detail("Setup", drill.setup)
                detail("Coaching points", drill.coachingPoints)
                detail("Equipment", drill.equipment)
                if let url = drill.resourceURL {
                    Link(destination: url) {
                        Label("Open drill resource", systemImage: "arrow.up.right.square")
                    }
                }
            }
            .padding(.vertical, 4)
        } label: {
            HStack {
                Text("How to run this drill")
                Spacer()
                Text("Est. \(drill.minutes)m")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func detail(_ title: String, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value.replacingOccurrences(of: "- ", with: "• "))
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ActivityRow: View {
    let activity: PracticeActivity
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.symbol).foregroundStyle(NextTouchTheme.accent).frame(width: 34, height: 34).background(NextTouchTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: NextTouchTheme.cornerRadius))
            VStack(alignment: .leading, spacing: 3) {
                Text(activity.title).font(.subheadline.weight(.semibold))
                Text(activity.type.rawValue).font(.caption).foregroundStyle(.secondary)
                if !activity.notes.isEmpty {
                    Text(activity.notes.joined(separator: " • "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            Spacer(); Text("\(activity.minutes)m").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
        }
    }
}
