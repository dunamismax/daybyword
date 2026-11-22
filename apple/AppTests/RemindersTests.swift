import Foundation
import ReadingData
import ReadingEngine
import Testing
import UserNotifications

@testable import DayByWord

/// A library on the bundled catalog with an empty journal in memory, its
/// clock at `hour`:`minute` in the device's zone on `today`.
@MainActor
private func library(today: String = "2027-03-01", hour: Int = 6, minute: Int = 0) throws -> Library {
    let url = try #require(Bundle.main.url(forResource: "Catalog", withExtension: "sqlite"))
    let date = try CivilDate(today)
    return Library(
        catalog: try Catalog(path: url.path), store: try JournalStore.inMemory(),
        clock: { date.start(in: .current).addingTimeInterval(TimeInterval(hour * 3600 + minute * 60)) })
}

/// Settings of its own for each test, so none reads another's.
private func defaults() -> UserDefaults {
    let name = "reminders-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

/// Gospels at your pace from Monday 1 March 2027, Monday to Friday, with a
/// reminder at 07:00.
@MainActor
@discardableResult
private func startGospels(_ library: Library) throws -> EventID {
    try library.start(
        .init(
            plan: PlanID("gospels-at-your-pace")!, version: 1, behavior: .pace, start: library.today,
            readingDays: [1, 2, 3, 4, 5], reminder: .at(WallTime(hour: 7, minute: 0)!)))
}

@MainActor
@Test func remindersNameThePlanAndTheNextReadingAtTheirWallClockTime() throws {
    let library = try library()
    let id = try startGospels(library)
    let requests = ReminderScheduler(library: library, defaults: defaults()).requests(now: library.localNow)

    // Sixty: the window, and Gospels at your pace has sixty readings.
    #expect(requests.count == 60)
    let first = try #require(requests.first)
    #expect(first.identifier == "reminder.\(id).2027-03-01T07:00")
    #expect(first.content.body == "Gospels at your pace: Matthew 1–3.")
    #expect(first.content.threadIdentifier == id.description)
    #expect(first.content.categoryIdentifier == ReminderScheduler.categoryIdentifier)
    #expect(
        ReminderPayload(first.content.userInfo)
            == ReminderPayload(enrollment: id.description, assignment: 1, appointed: nil))
    let trigger = try #require(first.trigger as? UNCalendarNotificationTrigger)
    #expect(trigger.dateComponents == DateComponents(year: 2027, month: 3, day: 1, hour: 7, minute: 0))
    #expect(!trigger.repeats)
    // Reading days only: Saturday and Sunday have none.
    #expect(requests[5].identifier == "reminder.\(id).2027-03-08T07:00")
    // Every one names the next reading as things stand, not a later one.
    #expect(requests.allSatisfy { $0.content.body == "Gospels at your pace: Matthew 1–3." })
}

@MainActor
@Test func aReaderCanKeepPassagesOffTheLockScreen() throws {
    let library = try library()
    try startGospels(library)
    let settings = defaults()
    settings.set(false, forKey: ReminderPreferences.showReadingKey)
    let first = try #require(
        ReminderScheduler(library: library, defaults: settings).requests(now: library.localNow).first)
    #expect(first.content.body == "Gospels at your pace.")
}

@MainActor
@Test func quietHoursAndTheMostADayComeFromTheDevicesSettings() throws {
    let library = try library()
    try startGospels(library)
    let settings = defaults()
    settings.set(true, forKey: ReminderPreferences.quietHoursKey)
    settings.set(22 * 60, forKey: ReminderPreferences.quietFromKey)
    settings.set(8 * 60, forKey: ReminderPreferences.quietUntilKey)
    let first = try #require(
        ReminderScheduler(library: library, defaults: settings).requests(now: library.localNow).first)
    let trigger = try #require(first.trigger as? UNCalendarNotificationTrigger)
    #expect(trigger.dateComponents.hour == 8)
    #expect(trigger.dateComponents.minute == 0)
}

@MainActor
@Test func markReadFromAReminderMarksItsReadingOnceAndNoReminderNamesItAgain() throws {
    let library = try library()
    let id = try startGospels(library)
    let scheduler = ReminderScheduler(library: library, defaults: defaults())
    let payload = ReminderPayload(enrollment: id.description, assignment: 1, appointed: nil)
    #expect(scheduler.isStillToRead(payload))
    #expect(scheduler.markRead(payload))
    #expect(library.activeEnrollments[0].state(of: Slot(assignment: 1)) == .read)
    #expect(!scheduler.isStillToRead(payload))
    // A second tap, or a stale reminder, records nothing.
    #expect(!scheduler.markRead(payload))
    #expect(library.journal?.events.count == 2)
    // Today's reading is done, so today's reminder is gone; the rest name the next one.
    let requests = scheduler.requests(now: library.localNow)
    #expect(requests.first?.identifier == "reminder.\(id).2027-03-02T07:00")
    #expect(requests.first?.content.body == "Gospels at your pace: Matthew 4–5.")
    // An unknown enrollment is no reading at all.
    #expect(!scheduler.markRead(ReminderPayload(enrollment: "nonsense", assignment: 1, appointed: nil)))
}

@MainActor
@Test func snoozeBringsTheReminderBackInAnHour() throws {
    let library = try library(hour: 7, minute: 30)
    let id = try startGospels(library)
    let settings = defaults()
    let scheduler = ReminderScheduler(library: library, defaults: settings)
    // At 07:30 today's 07:00 reminder has passed: the first is tomorrow's.
    #expect(scheduler.requests(now: library.localNow).first?.identifier == "reminder.\(id).2027-03-02T07:00")
    scheduler.snooze(ReminderPayload(enrollment: id.description, assignment: 1, appointed: nil))
    let first = try #require(scheduler.requests(now: library.localNow).first)
    #expect(first.identifier == "reminder.\(id).2027-03-01T08:30.snooze")
    #expect(first.content.body == "Gospels at your pace: Matthew 1–3.")
    #expect(ReminderPreferences.storedSnoozes(settings).count == 1)
}
