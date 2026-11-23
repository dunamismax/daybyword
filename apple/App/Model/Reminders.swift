import Foundation
import Observation
import ReadingEngine
import UserNotifications

/// The reader's reminder settings on this device (docs/engine.md,
/// "Reminders"; E44): whether a reminder names the reading, quiet hours, the
/// most a day, and snoozes. Each plan's reminder time is in the journal.
enum ReminderPreferences {
    /// Whether a reminder names the reading or only the plan; on by default.
    static let showReadingKey = "reminderShowsReading"
    static let quietHoursKey = "quietHours"
    /// Quiet hours' ends, as minutes after midnight.
    static let quietFromKey = "quietFrom"
    static let quietUntilKey = "quietUntil"
    /// The most reminders on one date; 0 for no limit.
    static let mostADayKey = "remindersADay"
    static let snoozesKey = "snoozes"
    /// How long Snooze waits.
    static let snooze: TimeInterval = 3600

    static let defaultQuietFrom = 22 * 60
    static let defaultQuietUntil = 7 * 60

    /// A snooze as it is kept in user defaults.
    struct StoredSnooze: Codable, Equatable {
        var enrollment: String
        var date: String
        var time: String
    }

    static func settings(_ defaults: UserDefaults = .standard) -> ReminderSettings {
        var settings = ReminderSettings()
        if defaults.bool(forKey: quietHoursKey) {
            let from = minutes(defaults, quietFromKey, defaultQuietFrom)
            let until = minutes(defaults, quietUntilKey, defaultQuietUntil)
            if let from = WallTime(hour: from / 60, minute: from % 60),
                let until = WallTime(hour: until / 60, minute: until % 60)
            {
                settings.quietHours = .init(from: from, until: until)
            }
        }
        let most = defaults.integer(forKey: mostADayKey)
        settings.mostADay = most > 0 ? most : nil
        settings.snoozes = storedSnoozes(defaults).compactMap { stored in
            guard let enrollment = EventID(stored.enrollment), let date = try? CivilDate(stored.date),
                let time = WallTime(stored.time)
            else { return nil }
            return .init(enrollment: enrollment, at: LocalDateTime(date: date, time: time))
        }
        return settings
    }

    static func showsReading(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: showReadingKey) as? Bool ?? true
    }

    static func storedSnoozes(_ defaults: UserDefaults = .standard) -> [StoredSnooze] {
        guard let data = defaults.data(forKey: snoozesKey) else { return [] }
        return (try? JSONDecoder().decode([StoredSnooze].self, from: data)) ?? []
    }

    static func store(_ snoozes: [StoredSnooze], _ defaults: UserDefaults = .standard) {
        defaults.set(try? JSONEncoder().encode(snoozes), forKey: snoozesKey)
    }

    private static func minutes(_ defaults: UserDefaults, _ key: String, _ fallback: Int) -> Int {
        let value = defaults.object(forKey: key) as? Int ?? fallback
        return (0..<(24 * 60)).contains(value) ? value : fallback
    }
}

/// What a reminder is about, carried in its notification so its actions can
/// find the reading again.
struct ReminderPayload: Sendable, Equatable {
    let enrollment: String
    let assignment: Int
    let appointed: String?

    init(enrollment: String, assignment: Int, appointed: String?) {
        self.enrollment = enrollment
        self.assignment = assignment
        self.appointed = appointed
    }

    init?(_ userInfo: [AnyHashable: Any]) {
        guard let enrollment = userInfo["enrollment"] as? String, let assignment = userInfo["assignment"] as? Int
        else { return nil }
        self.init(enrollment: enrollment, assignment: assignment, appointed: userInfo["appointed"] as? String)
    }

    var userInfo: [String: Any] {
        var info: [String: Any] = ["enrollment": enrollment, "assignment": assignment]
        if let appointed { info["appointed"] = appointed }
        return info
    }
}

/// Keeps the device's pending reminders the ones the engine gives (BUILD.md
/// P8.8, docs/product.md "Reminders and notifications"): asked again after
/// every change to the journal, every change to a setting, whenever the app
/// becomes active, and when the time zone or the clock changes. iOS keeps at
/// most 64 pending requests, so the engine is asked for 60, and they are
/// refilled each time.
@MainActor
@Observable
final class ReminderScheduler {
    static let categoryIdentifier = "reading"
    static let prefix = "reminder."

    enum Action {
        static let markRead = "markRead"
        static let snooze = "snooze"
        static let open = "open"
    }

    /// The reminders' category: Mark read, Snooze, and Open, and the words
    /// shown when the device hides notification previews.
    static var category: UNNotificationCategory {
        UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [
                UNNotificationAction(identifier: Action.markRead, title: String(localized: "Mark read")),
                UNNotificationAction(identifier: Action.snooze, title: String(localized: "Snooze for an hour")),
                UNNotificationAction(identifier: Action.open, title: String(localized: "Open"), options: .foreground),
            ],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: String(localized: "A reading in your plan"))
    }

    /// Whether notifications are allowed for Day by Word, as last asked.
    private(set) var authorization: UNAuthorizationStatus = .notDetermined

    private let library: Library
    private let defaults: UserDefaults
    private var running: Task<Void, Never>?
    private var again = false

    init(library: Library, defaults: UserDefaults = .standard) {
        self.library = library
        self.defaults = defaults
    }

    // MARK: Scheduling

    /// The notification requests for the reminders the engine gives now.
    func requests(now: LocalDateTime) -> [UNNotificationRequest] {
        guard let journal = library.journal else { return [] }
        let settings = ReminderPreferences.settings(defaults)
        let showsReading = ReminderPreferences.showsReading(defaults)
        return journal.reminders(now: now, settings: settings).compactMap { reminder in
            guard let enrollment = journal.enrollments.first(where: { $0.id == reminder.enrollment }),
                let plan = library.plan(of: enrollment)
            else { return nil }
            let content = UNMutableNotificationContent()
            content.body = text(plan: plan, slot: reminder.slot, showsReading: showsReading)
            content.threadIdentifier = enrollment.id.description
            content.categoryIdentifier = Self.categoryIdentifier
            content.sound = .default
            if let slot = reminder.slot {
                content.userInfo =
                    ReminderPayload(
                        enrollment: enrollment.id.description, assignment: slot.assignment,
                        appointed: slot.appointed?.description
                    ).userInfo
            }
            let identifier =
                "\(Self.prefix)\(enrollment.id).\(reminder.at.date)T\(reminder.at.time)"
                + (reminder.isSnooze ? ".snooze" : "")
            return UNNotificationRequest(
                identifier: identifier, content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: reminder.at.components, repeats: false))
        }
    }

    /// "Gospels at your pace: Mark 4:1–20.", or "Gospels at your pace." when
    /// the reader keeps passages off the Lock Screen. Never a missed day, a
    /// count, or the streak (docs/engine.md, "Reminders", rule 7).
    func text(plan: Plan, slot: Slot?, showsReading: Bool) -> String {
        guard showsReading, let slot, let formatter = library.formatter,
            let reading = plan.assignments.first(where: { $0.id == slot.assignment })?.reading
        else { return String(localized: "\(plan.title).") }
        return String(localized: "\(plan.title): \(formatter.string(for: reading)).")
    }

    /// Asks for the reminders again, once any run already going has finished.
    func setNeedsReschedule() {
        if running != nil {
            again = true
            return
        }
        running = Task {
            repeat {
                again = false
                await reschedule()
            } while again
            running = nil
        }
    }

    /// Replaces the pending reminders with the engine's, and takes away
    /// delivered ones whose reading is no longer to read.
    func reschedule() async {
        let center = UNUserNotificationCenter.current()
        authorization = await center.notificationSettings().authorizationStatus
        pruneSnoozes()
        let wanted = requests(now: library.localNow)
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter {
            $0.hasPrefix(Self.prefix)
        }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        if authorization == .authorized || authorization == .provisional || authorization == .ephemeral {
            for request in wanted { try? await center.add(request) }
        }
        let delivered = await center.deliveredNotifications()
        let stale = delivered.filter { notification in
            guard let payload = ReminderPayload(notification.request.content.userInfo) else { return false }
            return !isStillToRead(payload)
        }
        center.removeDeliveredNotifications(withIdentifiers: stale.map(\.request.identifier))
    }

    /// Asks the reader to allow notifications, when they have just chosen a
    /// reminder; never at launch (docs/product.md).
    func askForPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        authorization = await center.notificationSettings().authorizationStatus
        setNeedsReschedule()
        return granted
    }

    /// Snoozes that have passed are forgotten.
    private func pruneSnoozes() {
        let now = library.localNow
        let kept = ReminderPreferences.storedSnoozes(defaults).filter { stored in
            guard let date = try? CivilDate(stored.date), let time = WallTime(stored.time) else { return false }
            return LocalDateTime(date: date, time: time) > now
        }
        ReminderPreferences.store(kept, defaults)
    }

    // MARK: Actions

    /// Whether the reading a reminder named is still unread in an enrollment
    /// that has not ended.
    func isStillToRead(_ payload: ReminderPayload) -> Bool {
        guard let (enrollment, slot) = find(payload) else { return false }
        return enrollment.state(of: slot) == .unread
    }

    /// Mark read, from a reminder: the reading it named, read today, if it is
    /// still unread. Returns whether anything was recorded.
    @discardableResult
    func markRead(_ payload: ReminderPayload) -> Bool {
        guard let (enrollment, slot) = find(payload), enrollment.state(of: slot) == .unread else { return false }
        let mark = JournalEvent.Marked(
            .completed, assignment: slot.assignment, date: library.today, appointed: slot.appointed)
        return (try? library.record(.marked(mark), enrollment: enrollment.id)) != nil
    }

    /// Snooze: the reminder again in an hour, while its reading is still to
    /// read today.
    func snooze(_ payload: ReminderPayload) {
        guard let (enrollment, _) = find(payload),
            let at = try? LocalDateTime(
                library.now.addingTimeInterval(ReminderPreferences.snooze), in: library.timeZone)
        else { return }
        var stored = ReminderPreferences.storedSnoozes(defaults)
        stored.append(
            .init(enrollment: enrollment.id.description, date: at.date.description, time: at.time.description))
        ReminderPreferences.store(stored, defaults)
        setNeedsReschedule()
    }

    private func find(_ payload: ReminderPayload) -> (Enrollment, Slot)? {
        guard let id = EventID(payload.enrollment),
            let enrollment = library.journal?.enrollments.first(where: { $0.id == id }), enrollment.ended == nil
        else { return nil }
        var appointed: CivilDate?
        if let text = payload.appointed {
            guard let date = try? CivilDate(text) else { return nil }
            appointed = date
        }
        return (enrollment, Slot(assignment: payload.assignment, appointed: appointed))
    }
}
