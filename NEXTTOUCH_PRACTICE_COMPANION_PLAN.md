# NextTouch Practice Companion — Execution Plan

Status: implementation handoff  
Updated: 2026-08-01  
Product promise: **Plan on the phone. Coach from the watch.**

## 1. Outcome

Build a native iPhone and Apple Watch companion for preparing a practice on the phone, downloading an immutable practice snapshot to the watch, and running the practice from the watch without a phone or internet connection.

The V1 experience is successful when a coach can:

1. Create or edit an ordered practice on iPhone.
2. See the total planned duration at all times.
3. Reliably download the practice to Apple Watch.
4. Start it from the watch and operate the timer with one-tap controls.
5. Receive a light 1:00 warning and a strong 0:00 completion signal.
6. Stay at 0:00 until manually advancing.
7. Finish offline and later sync the run result back to the phone.

## 2. Product decisions

These decisions remove ambiguity for the implementation agent:

- Build with **SwiftUI**, using one iOS app target, one watchOS app target, and a shared Swift package/framework for models, payloads, timer rules, and test fixtures.
- V1 has **no account, login, or onboarding gate**. A coach can create the first practice immediately after the notification-permission explanation.
- The iPhone is the authoring source of truth. The watch receives versioned, read-only snapshots; it never edits the underlying practice.
- The watch owns active-run state and timing. The iPhone is not consulted during a practice.
- Store all V1 product data locally with SwiftData. The app has no runtime dependency on Supabase, CloudKit, an Apple ID, or internet access.
- Keep repository protocols, stable UUIDs, UTC timestamps, and versioned Codable DTOs so a future Supabase adapter can be added without changing view or timer code.
- Use timestamp-derived time rather than decrementing an integer every second. This makes the timer recover correctly after wrist-down, suspension, UI refresh delays, or app relaunch.
- Do not auto-advance at 0:00. The current activity enters an `expired` state and remains selected.
- No separate dashboard or analytics area in V1. Practice Library is the iPhone root.
- Do not add team management, attendance, evaluations, time adjustment, drill editing, diagrams, voice notes, live cross-device control, or practice analytics.

### Required product clarification

“Sync notes after practice” is not paired with any V1 note-capture interaction. The default implementation should sync a `PracticeRunSummary` (run ID, practice revision, start/end timestamps, activity advancement timestamps, and completion state) and keep a forward-compatible `textNotes` array in the payload, but **do not build a watch note-entry UI**. If product intends typed or dictated post-practice notes, scope and approve that as a separate increment before implementation.

## 3. Visual direction

### Reference synthesis

- [Interval Timer — iOS Workout App](https://dribbble.com/shots/20797583-Interval-Timer-iOS-Workout-App): use the full green live state, oversized timer, minimal chrome, and bottom-anchored transport controls for watch Practice Mode.
- [Workout Tracker Mobile iOS App](https://dribbble.com/shots/21178118-Workout-Tracker-Mobile-IOS-App): use compact information blocks, strong type hierarchy, disciplined spacing, and low visual clutter as the overall iPhone language.
- [Bouldering Route Marker Mobile iOS App](https://dribbble.com/shots/25863601-Bouldering-Route-Marker-Mobile-iOS-App): use its timeline/list treatment to convey dense progress information without turning the screen into a dashboard. Keep its green influence scoped to live Practice Mode rather than replacing the established NextTouch brand palette.

These are inspiration sources, not assets to copy. Rebuild the information hierarchy with native components and original NextTouch styling.

### Design principles

1. **One dominant fact per screen.** Library: next practice. Editor: practice structure and total time. Watch: remaining time.
2. **Information density through hierarchy, not decoration.** Prefer typography, spacing, dividers, and alignment over nested cards.
3. **Live mode is visually unmistakable.** Practice Mode uses a full green background; setup and library screens use neutral surfaces.
4. **Glance first, detail second.** The current activity, time, and next action must be readable in under one second.
5. **Color is never the only signal.** Every state also has a label, symbol, shape, or haptic.
6. **Native behavior wins.** Navigation, swipe actions, context menus, sheets, alerts, Digital Crown scrolling, and accessibility follow Apple conventions.

### Proposed tokens

Finalize exact values during visual QA, but begin with:

| Token | Starting value | Usage |
|---|---:|---|
| `ink` | `#111827` | Primary text, dark controls |
| `paper` | `#FAFAFA` | iPhone canvas |
| `surface` | `#FFFFFF` | iPhone grouped content |
| `brand` | `#6F1D2A` | Established NextTouch iPhone accent |
| `brandLight` | `#F6ECEF` | Selected/subtle branded surfaces |
| `liveGreen` | `#12C94B` | Full-background active watch state |
| `warning` | `#F1C84B` | One-minute warning accent |
| `danger` | system red | Destructive actions only |
| `muted` | system secondary | Supporting metadata |

Requirements:

- Use SF Pro via system text styles; use monospaced digits for timers and duration totals.
- Use SF Symbols, not custom-drawn interface icons.
- Minimum iPhone control target: 44×44 pt. Make primary watch controls as large as the layout permits.
- Validate text/background contrast in active, paused, expired, and Always On/dimmed states.
- Reduce motion to simple opacity/scale changes; never make animation necessary to understand state.

## 4. Information architecture and screens

### iPhone navigation

Use a single `NavigationStack`. Do not add a tab bar for one primary destination.

#### A. Practice Library

Content order:

1. Large title: “Practices.”
2. “Up next” hero row/card when a scheduled practice exists.
3. Upcoming practices, sorted ascending by scheduled date.
4. Saved practices/templates, sorted by most recently updated.
5. Floating or toolbar create action.

Each row shows title, date or “Saved practice,” total duration, activity count, and watch status (`Not on Watch`, `Sending`, `On Watch`, `Update Available`, `Failed`). Keep status compact.

Interactions:

- Tap: open Practice Detail/Editor.
- Swipe trailing: Delete with confirmation.
- Context menu or swipe leading: Duplicate.
- Pull to refresh is unnecessary in local-only V1. If retained as a familiar gesture, it may only reconcile pending WatchConnectivity status and must not imply a cloud fetch.
- Empty state: one sentence plus “Create Practice.”

#### B. Practice Detail / Editor

Use one editor rather than separate view and edit screens.

Header:

- Editable title.
- Optional scheduled date/time.
- Sticky or always-visible total duration summary: `8 activities · 1h 20m`.
- Watch sync status and “Download to Watch”/“Update on Watch” action.

Timeline:

- One vertically ordered row per activity, connected by a subtle timeline rail.
- Row contains activity-type symbol, title, type label, duration, and up to two note lines.
- Reordering uses native edit-mode drag handles. Preserve activity IDs while moving.
- Tap row to edit activity details.
- Add Activity opens a bottom sheet with: Drill, Coach Talk, Water Break, Scrimmage, Custom.

Activity editor sheet:

- Activity type (fixed after creation unless explicitly changed from a menu).
- Title.
- Duration picker with minute presets and direct minutes/seconds entry.
- Coaching notes as 0–3 short bullet fields.
- Delete activity as a destructive footer action.

Drill picker:

- Open from the `Drill` add choice.
- Show the bundled starter catalog with one search field and an optional category filter.
- Each compact row shows drill name, category, and planned minutes.
- Tap once to select; `Add to practice` copies the selected drill into the practice timeline.
- Do not add favorites, drill editing, resource previews, recommendations, or a separate drill-management workflow in V1.

Behavior:

- Recalculate total duration immediately after add, delete, duration edit, or reorder.
- Save locally on each committed edit.
- Mark any previously downloaded watch snapshot as `Update Available` after a content revision.
- Download sends an immutable revision. Editing afterward must not mutate an active watch run.

#### C. Post-practice run summary

Show only after a run syncs back:

- Practice title and completion date.
- Planned duration.
- Started/finished times.
- Completion status (`Completed` or `Ended Early`).
- A compact activity timeline based on manual advancement timestamps.
- No performance analytics in V1.

### Apple Watch navigation

#### A. Downloaded Practices

- Title: “Practices.”
- Rows show title, scheduled date if present, total duration, activity count, and a small stale/update badge if relevant.
- Empty state explains that practices are downloaded from iPhone.
- Sort scheduled practices first, then most recently downloaded.

#### B. Practice preflight

- Practice title.
- Planned start/date if present.
- Total time and activity count.
- Last synced time.
- Prominent “Start Practice.”
- If notification permission is unavailable, show a concise warning that wrist-down timer alerts may not occur; allow starting.

#### C. Practice Mode

The entire screen uses `liveGreen`; do not put the timer inside a card.

Vertical composition:

1. Compact top line: activity title and `3 of 8`.
2. Timer as the visual focal point using monospaced digits.
3. Scrollable activity timeline directly below the timer:
   - Previous activity: dimmed with completed/visited symbol.
   - Current activity: high contrast; show 1–3 coaching-note bullets nested beneath it.
   - Next activity: visible with title and duration.
   - Additional activities are reachable with the Digital Crown.
4. Bottom controls: Previous, Pause/Resume, Next. Use symbols plus accessibility labels. Make Next the most prominent target.
5. Finish lives in an overflow/secondary action and requires confirmation to prevent accidental ending.

State styling:

| State | Visual behavior | Controls |
|---|---|---|
| Running | Full green, timer dominant | Previous, Pause, Next |
| Paused | Green darkens; “Paused” label; timer frozen | Previous, Resume, Next |
| 1:00 warning | Brief warning halo/label; no persistent takeover | Unchanged |
| Expired | Timer stays `0:00`; “Ready for next” label | Previous, Next prominent, Finish |
| Sync pending | Never interrupts the run | Small status only after Finish |

Avoid horizontal swipes for Previous/Next in V1; accidental gestures are too costly during live coaching.

#### D. Finish confirmation and result

- Confirmation: “Finish practice?” with `Keep Coaching` and destructive `Finish`.
- Result: completed or ended-early label, elapsed wall-clock time, and `Sync pending`/`Sent to iPhone` state.
- Saving and queueing the result must happen before showing success.

## 5. Domain model

Use stable UUIDs and explicit schema versions.

```swift
struct Practice: Identifiable, Codable {
    let id: UUID                 // maps to practice_plans.id later
    var eventID: UUID?           // maps to events.id later
    var teamID: UUID?            // nil for standalone local records
    var title: String
    var scheduledAt: Date?
    var endsAt: Date?
    var location: String?
    var concept: String?
    var objectives: String?
    var equipment: String?
    var planCoachingPoints: String?
    var activities: [PracticeActivity]
    var revision: Int
    var createdAt: Date
    var updatedAt: Date
}

struct PracticeActivity: Identifiable, Codable {
    let id: UUID
    var order: Int                // zero-based locally
    var itemType: PracticeItemType
    var category: DrillCategory?
    var name: String
    var durationSeconds: Int
    var description: String?
    var setup: String?
    var coachingPointBullets: [String]
    var equipment: String?
    var drillID: UUID?
}

enum PracticeItemType: String, Codable {
    case libraryDrill = "library_drill"
    case customDrill = "custom_drill"
    case waterBreak = "water_break"
    case coachDiscussion = "coach_discussion"
    case other
}

enum DrillCategory: String, Codable {
    case warmUp = "warm_up"
    case technical, tactical, possession
    case smallSidedGames = "small_sided_games"
    case finishing, defending, passing, receiving, rondos
}

struct WatchPracticeSnapshot: Identifiable, Codable {
    let schemaVersion: Int
    let id: UUID              // practice ID
    let revision: Int
    let downloadedAt: Date
    let title: String
    let scheduledAt: Date?
    let activities: [PracticeActivity]
}

struct PracticeRunSummary: Identifiable, Codable {
    let schemaVersion: Int
    let id: UUID              // run ID; idempotency key
    let practiceID: UUID
    let practiceRevision: Int
    let startedAt: Date
    let finishedAt: Date
    let completion: RunCompletion
    let events: [RunEvent]
    let textNotes: [String]    // reserved; no V1 watch capture UI
    var syncRevision: Int
}

struct RunEvent: Identifiable, Codable {
    let id: UUID
    let activityID: UUID
    let type: RunEventType
    let occurredAt: Date
    let remainingSeconds: Int?
}
```

Validation rules:

- Title: trimmed, 2–140 characters, matching `events.title`.
- Practice requires at least one activity before download/start.
- Duration: 1–180 whole minutes in the editor, stored locally as seconds. `durationSeconds` must be divisible by 60 so it maps losslessly to `planned_duration_minutes`.
- Coaching points: store up to 2,000 characters total. Practice Mode displays at most the first 3 trimmed, nonempty lines as bullets.
- `order` is normalized to contiguous zero-based integers at every save boundary.
- `revision` increments only when watch-relevant content changes.
- `libraryDrill` requires a non-nil `drillID`; every other item type requires `drillID == nil`.
- `waterBreak`, `coachDiscussion`, and `other` require a nil category, matching the existing database guards.

UI creation choices map to the aligned domain types as follows:

| UI choice | Domain representation |
|---|---|
| Library drill | `libraryDrill` + `drillID` + copied drill snapshot fields |
| New drill | `customDrill` |
| Coach talk | `coachDiscussion` |
| Water break | `waterBreak` |
| Scrimmage | `customDrill` + `small_sided_games` category |
| Custom activity | `other` |

## 6. Local persistence and future backend boundary

Use **SwiftData** as the V1 on-device database. Apple describes SwiftData as a native persistence framework with declarative models, SwiftUI integration, efficient fetching, and schema migration support. It requires no third-party dependency, app account, network connection, or hosted database.

Set the initial deployment targets to iOS 17+ and watchOS 10+ so both targets can use SwiftData. If the parent product requires older OS support, replace this decision with Core Data during Phase 0; do not maintain two persistence stacks.

This companion workspace currently contains no application code. The separate NextTouch web schema has been inspected for alignment, but begin behind repository protocols rather than coupling views directly to SwiftData or to that backend shape.

```swift
protocol PracticeRepository {
    func practices() async throws -> [Practice]
    func save(_ practice: Practice) async throws
    func delete(id: UUID) async throws
    func duplicate(id: UUID) async throws -> Practice
}

protocol RunRepository {
    func save(_ run: PracticeRunSummary) async throws
    func pendingWatchTransfers() async throws -> [PracticeRunSummary]
}
```

Recommended storage:

- iPhone: SwiftData is the authoritative V1 store for practices and received run summaries.
- Watch: independent SwiftData store for snapshots, active-run checkpoints, and outbound run summaries.
- Treat deletions as tombstones until device sync acknowledgement is received.
- Autosave routine edits, and explicitly save before starting a watch transfer, beginning a practice, or leaving an editor after a destructive change.
- Keep SwiftData `@Model` classes internal to the persistence adapter. Views and WatchConnectivity use domain structs/DTOs so persistence identifiers never become API identifiers.
- Use stable app-generated UUIDs as future cloud primary keys; never derive identity from SwiftData `PersistentIdentifier` values.
- Persist dates as `Date` in the app and map to UTC `timestamptz` if a backend is added. Persist durations as integer seconds and ordered positions as integers.
- Add a `schemaVersion`, `revision`, `createdAt`, `updatedAt`, and optional `deletedAt`/tombstone field to backend-portable records.
- Do not add CloudKit to V1. It avoids an in-app login, but introduces iCloud availability, entitlement, conflict, and migration behavior that the MVP does not need.

### SwiftData records versus portable domain models

Use a two-layer model:

```text
SwiftData @Model records
        ⇅ LocalPracticeMapper
Pure Swift domain structs
        ⇅ Codable DTO mapper
WatchConnectivity now / Supabase later
```

This is intentional duplication, not accidental ceremony. It keeps SwiftData relationship/lifecycle concerns out of the timer engine and preserves a clean future migration path.

Suggested local records:

- `LocalPracticeRecord`
- `LocalActivityRecord`
- `LocalDrillRecord`
- `LocalPracticeRunRecord`
- `LocalRunEventRecord`
- `ProcessedSyncMessageRecord`
- `OutboundSyncMessageRecord`
- `SeedMetadataRecord`

Use cascade deletion from a practice to its activities only after any required watch tombstone has been persisted. Never cascade-delete historical run summaries when a practice is deleted; retain the copied title/revision metadata needed to display history.

### Bundled starter drill catalog

The current NextTouch repository does not contain a Markdown drill catalog. The authoritative source is:

```text
/Users/dericcain/Documents/Next Touch/supabase/migrations/
20260713124500_replace_starter_drill_library.sql
```

That migration contains 100 starter drills with stable UUIDs, categories, planned minutes, descriptions, setup, coaching points, equipment, and related resource links.

Keep the companion implementation intentionally small:

1. During development, convert the 100 drill rows once into a checked-in `starter_drills_v1.json` app resource. Do not parse SQL at runtime.
2. Include only fields needed by the MVP: ID, canonical name, category, planned minutes, description, setup, coaching points, and equipment. Exclude external resource links from the V1 bundle/UI.
3. On first launch, upsert the JSON records into SwiftData by their canonical UUIDs and store seed version `1` in `SeedMetadataRecord`.
4. Re-running the seed is idempotent. It updates only built-in catalog records and never duplicates them.
5. Mark seeded drills `isBuiltIn = true` and keep them read-only in V1.
6. When a coach adds a drill to a practice, copy its current fields into a new `PracticeActivity` with `itemType = .libraryDrill` and `drillID` pointing to the canonical drill UUID.
7. Saved practices are snapshots: a later catalog seed update must not silently rewrite an existing practice activity.
8. Preserve the canonical stored drill name for future schema alignment. If the leading numeric prefix is visually noisy, strip it only in the display formatter and keep a deterministic seed order separately.

Do not build a general import pipeline, admin screen, catalog updater, or network refresh for V1.

### No-login MVP trade-off

Local-only V1 is simpler and more private, but the product must accept:

- No automatic restoration after deleting the app or losing the phone.
- No multi-iPhone access.
- No web-to-phone practice synchronization.
- The Apple Watch is a companion copy, not a backup authority.

Do not hide these constraints. Add data export/import or account-based sync only when the product is ready to solve recovery and multi-device ownership deliberately.

### Future NextTouch/Supabase alignment

The local models have been checked against the NextTouch migrations dated through 2026-07-21 and the current `PracticePlanDetails` query contract. Use this mapping if a backend adapter is added:

| Local field | Existing NextTouch field | Mapping rule |
|---|---|---|
| `Practice.id` | `practice_plans.id` | Same UUID |
| `Practice.eventID` | `events.id` / `practice_plans.event_id` | Required only after cloud migration |
| `Practice.teamID` | `events.team_id` | Required only after cloud migration |
| `title` | `events.title` | 2–140 trimmed characters |
| `scheduledAt` | `events.starts_at` | UTC `timestamptz` |
| `endsAt` | `events.ends_at` | Nullable UTC `timestamptz` |
| `location` | `events.location` | Nullable text |
| plan metadata | `practice_plans.concept/objectives/equipment/coaching_points` | Direct nullable text mapping |
| `PracticeActivity.id` | `practice_items.id` | Same UUID |
| practice relationship | `practice_items.practice_plan_id` | `Practice.id` |
| `drillID` | `practice_items.drill_id` | Required only for `library_drill` |
| `itemType.rawValue` | `practice_items.item_type` | Exact existing enum raw value |
| `category.rawValue` | `practice_items.category` | Exact existing drill-category raw value |
| `order` | `practice_items.sort_order` | Local zero-based value + 1 |
| `name` | `practice_items.name` | 2–140 trimmed characters |
| `durationSeconds` | `practice_items.planned_duration_minutes` | Divide by 60; reject non-whole minutes |
| descriptive fields | `description/setup/equipment` | Direct nullable text mapping |
| `coachingPointBullets` | `practice_items.coaching_points` | Join with newlines; split nonempty lines when reading |

Important gaps in the current web schema:

- There is no practice-run/history table. `practice_items.completed_at` is a single mutable completion marker and must not be used as a substitute for immutable run history.
- There is no practice `revision` column or device-sync ledger. A future sync migration needs explicit revision/idempotency fields or tables.
- Scrimmage is not a `practice_item_type`; the existing compatible representation is `custom_drill` with category `small_sided_games`.
- Relational notes already support links to events and drills through `note_events` and `note_drills`, but the product still lacks a defined V1 watch note-capture interaction.
- The web product is team-scoped and invitation-only. Existing RLS expects an authenticated active team member, so the no-login companion must not connect directly to these tables in V1.

Do not make the local schema mirror Supabase mechanically. Keep the domain model stable and put snake_case rows, nullable legacy fields, and enum conversions inside a future `SupabasePracticeRepository` mapper.

If Supabase is later introduced without a visible sign-in, choose an identity strategy explicitly. Anonymous Supabase authentication still creates an authenticated anonymous user and requires account-linking/recovery rules; embedding a shared anonymous database key without per-user authorization is not an acceptable ownership model.

## 7. WatchConnectivity protocol

Apple’s framework supports background delivery between a companion iPhone and watch even without internet. Use reliable background transfers for product state; reserve immediate messaging for UI acceleration only. See [Apple’s WatchConnectivity transfer guidance](https://developer.apple.com/documentation/watchconnectivity/transferring-data-with-watch-connectivity).

### Envelopes

```swift
struct SyncEnvelope<Payload: Codable>: Codable {
    let protocolVersion: Int
    let messageID: UUID
    let sentAt: Date
    let kind: SyncKind
    let payload: Payload
}
```

Message kinds:

- `installPracticeSnapshot`
- `deletePracticeSnapshot`
- `practiceInstalledAck`
- `practiceRunSummary`
- `practiceRunReceivedAck`

### Transport rules

- Use `transferUserInfo(_:)` with encoded `Data` for snapshots, tombstones, acknowledgements, and run summaries. It queues ordered delivery and continues after suspension. Do not rely on `isReachable`.
- Optionally mirror the same envelope through `sendMessage` when reachable to make the visible sync state update quickly. The background transfer remains authoritative.
- Do not use `updateApplicationContext` for the practice library because it overwrites pending context and cannot represent multiple independent practice installs safely.
- Receiver processing is idempotent by `messageID`, entity ID, and revision.
- Ignore an older practice revision when a newer revision is already installed.
- Never replace or delete the snapshot referenced by an active run; defer the change until the run ends.
- Persist inbound payloads before acknowledging them.
- Persist outbound payloads before starting transfer; remove them only after acknowledgement.
- Activate `WCSession` at app launch on both devices and log state transitions with privacy-safe structured logging.
- Complete every watch connectivity background task promptly. Apple warns that failing to complete those tasks can exhaust the watch app’s background budget.
- Test `transferUserInfo` on a paired physical iPhone and Apple Watch; Apple’s documentation notes that Simulator does not support this path reliably.

## 8. Timer engine

Implement the timer as a pure state machine with an injected clock and notification scheduler.

### States

```text
ready → running ↔ paused
            ↓
          expired ──manual next/previous──> running
            ↓
         finished
```

Persistent active-run state:

- Run ID and immutable practice snapshot revision.
- Current activity index.
- State (`ready`, `running`, `paused`, `expired`).
- `deadline` while running.
- `pausedRemainingSeconds` while paused.
- IDs of activities whose warning and completion signals have fired.
- Chronological run events.

### Transition rules

- Start activity: `deadline = clock.now + duration`.
- Render: `remaining = max(0, ceil(deadline - clock.now))`.
- Pause: store remaining, clear deadline, cancel that activity’s pending alerts.
- Resume: create a new deadline from paused remaining and reschedule alerts.
- Previous/Next: record an advancement event, switch index, reset to the target activity’s full planned duration, and start it immediately. If product wants a ready-before-start state, change this before implementation; V1 defaults to immediate start.
- At 1:00: fire once only when the activity’s planned/remaining duration crossed from above 60 seconds. Activities of 60 seconds or less do not emit a warning at start.
- At 0:00: fire once, transition to `expired`, cancel the deadline, and remain at `0:00` until a manual action.
- Relaunch/resume: restore persisted state first, recompute from the deadline, and reconcile whether warning/completion events should already have occurred.
- Finish: cancel all pending timer alerts, persist summary, queue phone transfer, then clear active-run state.

### Wrist-down and suspension strategy

An ordinary watch app may become suspended after it stops being frontmost, and the user—not the app—controls Return to Clock duration. Apple documents a default two-minute frontmost period and a user-configurable maximum of one hour. See [frontmost app behavior](https://developer.apple.com/documentation/watchkit/taking-advantage-of-frontmost-app-state) and [Always On behavior](https://developer.apple.com/documentation/watchos-apps/designing-your-app-for-the-always-on-state).

Therefore:

- Schedule two local watch notifications whenever an activity begins/resumes: warning and completion.
- Cancel/reschedule them on pause, Previous, Next, or Finish.
- Use the watch notification delegate to update active UI and play the in-app haptic when frontmost.
- When suspended, let the system deliver the local alert. Notification authorization is required; present the value clearly during onboarding/preflight.
- Treat the visual countdown as a projection of persisted timestamps, not as the time source.
- Do not use `HKWorkoutSession` merely to keep this coaching app alive; that would misrepresent the coach as performing a tracked workout.
- Do not select an extended-runtime category until App Review suitability is confirmed. Apple limits available categories and runtimes; they do not cleanly cover a general 60–90 minute coaching timer. See [extended runtime sessions](https://developer.apple.com/documentation/watchkit/using-extended-runtime-sessions).

### Haptics and sound

- 1:00: light haptic plus short sound.
- 0:00: distinctly stronger haptic plus completion sound.
- Provide an app-active `WKInterfaceDevice` haptic and a local-notification fallback.
- Include two short bundled audio assets only after checking license and watchOS playback behavior.
- Do not claim exact delivery guarantees: Apple states local notification delivery is attempted but not guaranteed. See [local notification scheduling](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app).

The first engineering phase must include a physical-device proof for active, wrist-down, Always On, Return to Clock, notification-denied, silent-mode, and Focus-mode behavior. Product acceptance should be based on observed device behavior.

## 9. Accessibility and resilience

- VoiceOver announces activity title, remaining time at useful intervals, state, and button purpose; do not announce every second.
- Timer uses monospaced digits and scales without truncating on supported watch sizes.
- Support Dynamic Type on iPhone; use capped scaling only where a fixed timer layout requires it.
- Provide Reduce Motion behavior.
- Use labels/symbols in addition to green/yellow/red.
- Keep controls operable with wet hands or while moving: no tiny icon-only tap targets and no required long press.
- Confirm destructive actions and prevent double taps from causing duplicate transitions.
- All sync operations are retryable and idempotent.
- A phone/watch connection loss never changes active timer behavior.
- A watch reboot or app purge restores the latest persisted active-run state and derives the correct timer state on relaunch.

## 10. Execution phases

### Phase 0 — Project and platform proof

Deliverables:

- Create Xcode project with iOS, watchOS, shared model, unit-test, and UI-test targets.
- Set bundle IDs, companion identifiers, signing, capabilities, App Group if needed, and notification descriptions.
- Build a minimal paired-device WatchConnectivity round trip.
- Build a 90-second timestamp timer that schedules the 1:00 and 0:00 local alerts.
- Record observed behavior across wrist-down, background, Return to Clock, Always On, silent mode, Focus, and notification denial.
- Decide supported OS versions and watch sizes after reviewing the parent NextTouch constraints.
- Prove the same SwiftData schema can be created, saved, migrated, and restored independently on iPhone and watchOS.

Exit gate: reliable device evidence exists for the proposed timer/alert path. If it fails, revisit product expectations before building the UI.

### Phase 1 — Shared domain and local persistence

Deliverables:

- Models, validation, schema versioning, repository protocols.
- SwiftData stores on phone and watch.
- Checked-in `starter_drills_v1.json` generated from the canonical 100-drill migration.
- Idempotent, versioned first-launch drill seeding and a read-only drill repository.
- Seed fixtures covering all activity types.
- Pure timer state machine with fake clock.
- Sync envelope encoding/decoding and idempotency ledger.

Exit gate: model and timer unit tests pass with no UI.

### Phase 2 — iPhone Practice Library and Editor

Deliverables:

- Library sections, empty/loading/offline/error states.
- Create, edit, duplicate, delete.
- Add all five activity types.
- Duration and coaching-note editing.
- Reordering and live total-duration calculation.
- Visual implementation aligned to the selected references.

Exit gate: a complete practice can be authored and restored after app relaunch while offline.

### Phase 3 — Download and watch library

Deliverables:

- Reliable install/update/delete snapshot transfers.
- Acknowledgement-driven sync states on iPhone.
- Watch library and practice preflight.
- Revision conflict and active-run protection.

Exit gate: airplane-mode-after-download test passes on a paired physical device.

### Phase 4 — Watch Practice Mode

Deliverables:

- Full-green practice UI and compact drill timeline.
- Start, Pause/Resume, Previous, Next, Finish.
- Manual 0:00 hold.
- Haptic/sound scheduler and notification fallback.
- Active-run persistence and relaunch restoration.
- Always On/dimmed rendering.

Exit gate: every timer transition and the complete multi-activity flow pass on device without iPhone availability.

### Phase 5 — Return sync and local run history

Deliverables:

- Run-summary outbox on watch.
- Idempotent receipt/acknowledgement on iPhone.
- Post-practice summary screen.
- Local run-history persistence and deletion behavior.
- WatchConnectivity retry queue and user-visible failure recovery.
- Keep the documented NextTouch mapping table current if the parent schema changes; do not implement the backend adapter in V1.

Exit gate: finishing offline, reconnecting later, and receiving exactly one run record passes repeatedly.

### Phase 6 — Polish, accessibility, and release hardening

Deliverables:

- VoiceOver, Dynamic Type, Reduce Motion, contrast, and watch-size audit.
- Destructive-action and accidental-input review.
- Sync diagnostics screen or exportable privacy-safe logs for beta support.
- TestFlight build with paired-device test script.
- App privacy, notifications rationale, and App Review notes explaining offline timer behavior.

Exit gate: all acceptance criteria below pass on the oldest supported phone/watch pair and one current pair.

## 11. Test plan

### Unit tests

- Total duration after add/edit/delete/reorder.
- Starter catalog decodes all 100 unique UUIDs and valid enum/category values.
- First seed inserts 100 drills; repeated seed inserts zero duplicates.
- Catalog reseeding does not mutate drill snapshots already added to practices.
- Model validation and note limits.
- Revision changes only for watch-relevant edits.
- Timer start, pause, resume, previous, next, expire, finish.
- No auto-advance at 0:00.
- Warning and completion fire exactly once.
- Durations ≤60 seconds do not warn at start.
- Relaunch before warning, between warning and completion, and after completion.
- Clock jumps forward/backward and delayed UI ticks.
- Payload round trips, unknown schema versions, stale revisions, duplicate message IDs.

### Integration tests

- Phone snapshot → watch persistence → acknowledgement.
- Multiple queued practice downloads.
- Update arrives while another practice is active.
- Delete tombstone while disconnected.
- Watch run summary → phone persistence → acknowledgement → outbox cleanup.
- Local persistence across termination/relaunch and SwiftData schema migration.

### Physical-device scenarios

- Phone powered off for the entire practice.
- Both devices in airplane mode after download.
- Wrist lowered through both alert thresholds.
- User returns to watch face and later reopens the app.
- App is suspended or terminated and relaunched.
- Notifications allowed/denied; silent mode and Focus enabled.
- Pause immediately before 1:00 and 0:00, then resume.
- Rapid double tap on Next/Pause.
- 40 mm and largest supported watch layout.
- 8-, 20-, and 40-activity practices.
- 30-, 60-, and 90-minute practices using an injectable accelerated clock where appropriate.

## 12. V1 acceptance criteria

- A coach can create and modify a practice containing every supported activity type.
- A fresh install immediately offers the 100 bundled NextTouch drills without login or internet access.
- A coach can find a starter drill by name/category and add it to a practice without entering its details manually.
- Reordering is persistent and total duration is always correct.
- Duplicate produces new practice/activity IDs.
- Delete requires confirmation and syncs a tombstone when relevant.
- A downloaded practice can start with no phone and no internet.
- Watch shows current activity, remaining time, 1–3 notes, next activity, and progress.
- Pause freezes time; Resume continues from the frozen value.
- Previous/Next switch activities predictably and reset to planned duration.
- 1:00 and 0:00 signals occur once under documented supported device conditions.
- 0:00 remains until the coach advances or finishes.
- Finishing saves locally before any sync attempt.
- Reconnection eventually creates exactly one phone run summary.
- The active watch flow remains usable with VoiceOver and on all supported watch sizes.

## 13. Explicitly deferred

- Time add/subtract and adjustable warnings.
- Custom haptic patterns.
- Siri/App Intents and shortcuts.
- Live Activities and complications.
- Voice or dictated practice notes.
- Attendance, evaluations, roster, and team management.
- Live phone/watch mirroring during practice.
- Planned-vs-actual analytics.
- Drill diagrams and watch media.
- Multiple template systems beyond duplicate-and-edit.

## 14. Handoff instructions for the implementation agent

1. Read this plan plus the parent NextTouch README and current migrations before creating files; re-check for schema changes newer than 2026-07-21.
2. Do Phase 0 first. Do not build the full UI until the physical watch timer/alert spike passes.
3. Keep views dependent on repository/timer protocols so preview fixtures and tests do not require SwiftData, Supabase, or a watch.
4. Commit phase-by-phase with tests and screenshots/device notes attached to each handoff.
5. Do not silently expand scope. Record any requested deviation in this document before implementing it.
6. Treat the Dribbble references as hierarchy/style direction, not licensed source assets.
7. Report the unresolved post-practice notes meaning before Phase 5; default to run-summary sync without watch note capture.
