import Foundation
import UserNotifications

struct NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    /// Requests notification authorization if needed.
    func requestAuthorizationIfNeeded() {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    Logger.info("NotificationService: Permission granted.")
                } else if let error = error {
                    Logger.error("NotificationService: Error requesting permission: \(error.localizedDescription)")
                    UserDefaults.standard.set(false, forKey: Constants.enableNotificationsKey)
                } else {
                    Logger.warning("NotificationService: Permission denied.")
                    // Reset the toggle if permission is explicitly denied
                    UserDefaults.standard.set(false, forKey: Constants.enableNotificationsKey)
                }
            }
        }
    }

    /// Schedules a notification for a launching app
    func scheduleLaunchNotification(for app: ManagedApp) {
        let content = UNMutableNotificationContent()
        content.title = "Staged App Launched"
        content.body = "\(app.name) is launched after its delay."

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request) { error in
            if let error = error {
                Logger.error("NotificationService: Error scheduling notification for \(app.name): \(error.localizedDescription)")
            }
        }
    }
}
