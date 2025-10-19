import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            if !granted {
                print("Notification permission not granted")
            }
        } catch {
            print("Notification authorization error: \(error)")
        }
    }

    func scheduleNotification(at date: Date, phase: TimerPhase) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Session Complete", comment: "Notification title")
        content.body = String(format: NSLocalizedString("%@ finished.", comment: "Notification body"), phase.title)
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
        let request = UNNotificationRequest(identifier: "tomato.timer.\(UUID().uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func clearNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
}
