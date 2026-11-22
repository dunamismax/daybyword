import ReadingEngine
import SwiftUI
import UIKit
import UserNotifications
import WidgetKit

/// The app's model and its answers to the system: the library, the
/// reminders, and what a reminder's actions do (BUILD.md P8.8). One library
/// serves the interface and the notification actions, which can run while
/// the app is in the background.
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {
    let library = Library.live()
    private(set) lazy var reminders = ReminderScheduler(library: library)
    /// A place a reminder asked the interface to open.
    let routes = PendingRoute()

    func application(
        _ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories([ReminderScheduler.category])
        library.onChange = { [weak self] in
            self?.reminders.setNeedsReschedule()
            // The widget shows the same next reading (P8.9).
            WidgetCenter.shared.reloadAllTimelines()
        }
        // Reminders are wall-clock times: after travel or a clock change,
        // today and the reminders are worked out again (E40, E44).
        for name in [Notification.Name.NSSystemTimeZoneDidChange, UIApplication.significantTimeChangeNotification] {
            NotificationCenter.default.addObserver(
                self, selector: #selector(clockChanged), name: name, object: nil)
        }
        reminders.setNeedsReschedule()
        return true
    }

    @objc private func clockChanged() {
        library.refreshToday()
        reminders.setNeedsReschedule()
    }

    /// A reminder that arrives while Day by Word is open still shows.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    /// Mark read, Snooze, and Open. Tapping the reminder itself opens Today.
    /// Nothing is marked read because a reminder was tapped (docs/product.md,
    /// "Marking honestly").
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let payload = ReminderPayload(response.notification.request.content.userInfo)
        switch response.actionIdentifier {
        case ReminderScheduler.Action.markRead:
            if let payload { reminders.markRead(payload) }
        case ReminderScheduler.Action.snooze:
            if let payload { reminders.snooze(payload) }
        case UNNotificationDismissActionIdentifier:
            break
        default:
            library.refreshToday()
            routes.route = .today
        }
        await reminders.reschedule()
    }
}

/// A route the interface should open, set from outside the views.
@MainActor
@Observable
final class PendingRoute {
    var route: AppRoute?
}
