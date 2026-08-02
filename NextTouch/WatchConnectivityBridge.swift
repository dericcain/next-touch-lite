import Foundation
import WatchConnectivity

@MainActor final class WatchConnectivityBridge: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var isReachable = false
    @Published private(set) var lastError: String?
    @Published private(set) var receivedRuns: [PracticeRunSummary] = []
    @Published private(set) var receivedSnapshots: [PracticeSnapshot] = []
    private let syncStore = PracticeSyncStore()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func activate() { guard WCSession.isSupported() else { return }; WCSession.default.delegate = self; WCSession.default.activate() }
    func send(snapshot: PracticeSnapshot) {
        guard WCSession.isSupported() else { return }
        do { let data = try encoder.encode(snapshot); WCSession.default.transferUserInfo(["kind": "practice_snapshot", "schema": 1, "payload": data]) } catch { lastError = error.localizedDescription }
    }
    func send(summary: PracticeRunSummary) {
        guard WCSession.isSupported() else { return }
        do { let data = try encoder.encode(summary); WCSession.default.transferUserInfo(["kind": "practice_run_summary", "schema": 1, "payload": data]) } catch { lastError = error.localizedDescription }
    }
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { Task { @MainActor in isReachable = session.isReachable; lastError = error?.localizedDescription } }
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) { Task { @MainActor in isReachable = session.isReachable } }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) { }
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        guard let kind = userInfo["kind"] as? String, let data = userInfo["payload"] as? Data else { return }
        Task { @MainActor in
            do {
                if kind == "practice_run_summary" {
                    let run = try decoder.decode(PracticeRunSummary.self, from: data)
                    if !receivedRuns.contains(where: { $0.id == run.id }) { receivedRuns.append(run) }
                    syncStore.recordReceived(run)
                    sendRunAcknowledgement(runID: run.id)
                }
                if kind == "practice_snapshot" {
                    let snapshot = try decoder.decode(PracticeSnapshot.self, from: data)
                    if !receivedSnapshots.contains(where: { $0.practiceID == snapshot.practiceID && $0.revision >= snapshot.revision }) { receivedSnapshots.append(snapshot) }
                    syncStore.install(snapshot)
                }
            } catch { lastError = error.localizedDescription }
        }
    }

    func retry(_ summaries: [PracticeRunSummary]) { summaries.forEach(send(summary:)) }

    private func sendRunAcknowledgement(runID: UUID) {
        guard WCSession.isSupported(), let data = try? JSONEncoder().encode(runID) else { return }
        WCSession.default.transferUserInfo(["kind": "practice_run_received_ack", "schema": PracticeSchema.version, "payload": data])
    }
}
