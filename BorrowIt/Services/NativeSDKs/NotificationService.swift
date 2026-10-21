import Foundation
import UserNotifications

// MARK: - UserNotifications Manager
public class NotificationService: NSObject, NotificationServiceProtocol, UNUserNotificationCenterDelegate {
    public static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    public override init() {
        super.init()
        center.delegate = self
    }
    
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification permission error: \(error.localizedDescription)")
            return false
        }
    }
    
    public func scheduleLocalAlert(title: String, body: String, timeInterval: TimeInterval = 1.0) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(0.5, timeInterval), repeats: false)
        let request = UNNotificationRequest(
            identifier: "borrowit_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Domain-Specific Rich Notifications
    public func notifyBorrowRequested(itemTitle: String, lenderName: String) {
        scheduleLocalAlert(
            title: "Request Sent to \(lenderName)",
            body: "Your borrow request for '\(itemTitle)' has been sent. We'll alert you once approved."
        )
    }
    
    public func notifyLenderApproved(itemTitle: String, lenderName: String) {
        scheduleLocalAlert(
            title: "\(lenderName) approved your request!",
            body: "Your request for '\(itemTitle)' is approved. Pickup address unlocked."
        )
    }
    
    public func notifyGeofenceEntered(itemTitle: String, lenderName: String) {
        scheduleLocalAlert(
            title: "Within 50m of \(lenderName)'s Handoff Spot!",
            body: "You've entered the pickup zone for '\(itemTitle)'. Tap to present your QR pass."
        )
    }
    
    public func notifyDueReminder(itemTitle: String, hoursRemaining: Int) {
        scheduleLocalAlert(
            title: "Item Due Soon",
            body: "Reminder: '\(itemTitle)' is due back in \(hoursRemaining) hours."
        )
    }
    
    // Present notification banner while app is in foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
