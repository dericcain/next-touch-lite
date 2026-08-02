import Foundation
import UserNotifications

final class PracticeNotificationService {
    static let shared = PracticeNotificationService()
    func requestAuthorization() async -> Bool { (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false }
    func scheduleWarning(practice: Practice, activity: PracticeActivity, fireDate: Date) {
        let content = UNMutableNotificationContent(); content.title = practice.title; content.body = "1:00 left · \(activity.title)"; content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, fireDate.timeIntervalSinceNow), repeats: false); let request = UNNotificationRequest(identifier: "\(practice.id).\(activity.id).warning", content: content, trigger: trigger); UNUserNotificationCenter.current().add(request)
    }
    func scheduleCompletion(practice: Practice, activity: PracticeActivity, fireDate: Date) {
        let content = UNMutableNotificationContent(); content.title = "Activity complete"; content.body = "Ready for next · \(activity.title)"; content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, fireDate.timeIntervalSinceNow), repeats: false); let request = UNNotificationRequest(identifier: "\(practice.id).\(activity.id).completion", content: content, trigger: trigger); UNUserNotificationCenter.current().add(request)
    }
}
