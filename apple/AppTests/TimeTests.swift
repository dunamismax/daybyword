import Foundation
import ReadingData
import ReadingEngine
import Testing
import UserNotifications

@testable import DayByWord

/// Time, end to end (BUILD.md P17.4): Today and the reminders as the day
/// turns at midnight, as the reader crosses the date line, as the clocks
/// change, on a leap day, and when the device's clock was set wrong and is
/// put right. The engine's own rules for each are in docs/engine.md and
/// tests/fixtures/; these drive the app's library and scheduler through them.

/// A clock a test can move, and the zone the reader is in.
@MainActor
private final class Device {
    var now: Date
    var zone: TimeZone

    init(_ date: String, hour: Int, minute: Int = 0, in zone: String) throws {
        let zone = try #require(TimeZone(identifier: zone))
        self.zone = zone
        now = try CivilDate(date).start(in: zone).addingTimeInterval(TimeInterval(hour * 3600 + minute * 60))
    }

    func library() throws -> Library {
        let url = try #require(Bundle.main.url(forResource: "Catalog", withExtension: "sqlite"))
        return Library(
            catalog: try Catalog(path: url.path), store: try JournalStore.inMemory(), clock: { [unowned self] in now },
            zone: { [unowned self] in zone })
    }
}

private let gospels = PlanID("gospels-at-your-pace")!
private let proverbs = PlanID("proverbs-through-the-month")!

/// Settings of its own for each test, so none reads another's.
private func defaults() -> UserDefaults {
    let name = "time-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

@MainActor
@Test func todayTurnsAtMidnightAndKeepsTheMarkMadeBeforeIt() throws {
    let device = try Device("2027-03-01", hour: 23, minute: 59, in: "America/New_York")
    let library = try device.library()
    let id = try library.start(
        .init(plan: gospels, version: 1, behavior: .pace, start: library.today, readingDays: [1, 2, 3, 4, 5]))
    try library.record(.marked(.init(.completed, assignment: 1, date: library.today)), enrollment: id)

    // Two minutes later it is Tuesday: the app hears of it (a significant
    // time change) and works out today again.
    device.now.addTimeInterval(120)
    library.refreshToday()
    #expect(library.today == (try CivilDate("2027-03-02")))
    let enrollment = library.activeEnrollments[0]
    #expect(enrollment.today(library.today).readings == [Slot(assignment: 2)])
    #expect(enrollment.today(library.today).status == .reading)
    #expect(enrollment.state(of: Slot(assignment: 1)) == .read)
}

@MainActor
@Test func crossingTheDateLineMovesTodayAndTheRemindersWithTheReader() throws {
    // Tuesday 2 March at 10:00 in Honolulu is Wednesday 3 March at 09:00 in
    // Auckland: the same instant, a day apart.
    let device = try Device("2027-03-02", hour: 10, in: "Pacific/Honolulu")
    let library = try device.library()
    let id = try library.start(
        .init(
            plan: gospels, version: 1, behavior: .pace, start: library.today, readingDays: [1, 2, 3, 4, 5],
            reminder: .at(WallTime(hour: 7, minute: 0)!)))
    try library.record(.marked(.init(.completed, assignment: 1, date: library.today)), enrollment: id)

    device.zone = try #require(TimeZone(identifier: "Pacific/Auckland"))
    library.refreshToday()
    #expect(library.today == (try CivilDate("2027-03-03")))
    #expect(library.localNow.time == WallTime(hour: 9, minute: 0)!)
    let enrollment = library.activeEnrollments[0]
    #expect(enrollment.today(library.today).readings == [Slot(assignment: 2)])
    #expect(enrollment.state(of: Slot(assignment: 1)) == .read)

    // The reminder keeps its 07:00 in the new zone; today's has passed there.
    let requests = ReminderScheduler(library: library, defaults: defaults()).requests(now: library.localNow)
    #expect(requests.first?.identifier == "reminder.\(id).2027-03-04T07:00")

    // Flying back, Tuesday's mark is still Tuesday's, and nothing is lost.
    device.zone = try #require(TimeZone(identifier: "Pacific/Honolulu"))
    library.refreshToday()
    #expect(library.today == (try CivilDate("2027-03-02")))
    #expect(library.activeEnrollments[0].state(of: Slot(assignment: 1)) == .read)
}

@MainActor
@Test func remindersKeepTheirWallClockTimeWhenTheClocksChange() throws {
    // New York's clocks go forward at 02:00 on Sunday 14 March 2027, so
    // 02:30 does not happen that night; they go back on Sunday 7 November,
    // when 01:30 happens twice.
    for (day, time, changeDay) in [("2027-03-13", (2, 30), "2027-03-14"), ("2027-11-06", (1, 30), "2027-11-07")] {
        let device = try Device(day, hour: 12, in: "America/New_York")
        let library = try device.library()
        let id = try library.start(
            .init(
                plan: gospels, version: 1, behavior: .pace, start: library.today, readingDays: [1, 2, 3, 4, 5, 6, 7],
                reminder: .at(WallTime(hour: time.0, minute: time.1)!)))
        let requests = ReminderScheduler(library: library, defaults: defaults()).requests(now: library.localNow)
        let wallClock = String(format: "T%02d:%02d", time.0, time.1)
        // One reminder on the night the clocks change, at its wall-clock time
        // with no zone of its own: the system delivers a skipped time at the
        // next minute that exists, and a repeated one once.
        let onTheNight = requests.filter { $0.identifier.contains(changeDay) }
        #expect(onTheNight.map(\.identifier) == ["reminder.\(id).\(changeDay)\(wallClock)"])
        for request in requests.prefix(3) {
            let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
            #expect(trigger.dateComponents.hour == time.0 && trigger.dateComponents.minute == time.1)
            #expect(trigger.dateComponents.timeZone == nil)
        }
    }
}

@MainActor
@Test func aLeapDayHasItsOwnReadingInACalendarPlan() throws {
    let device = try Device("2028-02-28", hour: 8, in: "Europe/London")
    let library = try device.library()
    try library.start(
        .init(
            plan: proverbs, version: 1, behavior: .calendar, start: library.today,
            readingDays: [1, 2, 3, 4, 5, 6, 7]))
    for (date, assignment) in [("2028-02-28", 28), ("2028-02-29", 29), ("2028-03-01", 1)] {
        device.now = try CivilDate(date).start(in: device.zone).addingTimeInterval(8 * 3600)
        library.refreshToday()
        let readings = library.activeEnrollments[0].today(library.today).readings
        #expect(readings == [Slot(assignment: assignment, appointed: try CivilDate(date))], "\(date)")
    }
}

@MainActor
@Test func aClockSetWrongAndPutRightKeepsTheRecordInOrder() throws {
    // The clock reads a year ahead when the reader starts and marks a reading.
    let device = try Device("2028-03-01", hour: 7, in: "UTC")
    let library = try device.library()
    let id = try library.start(
        .init(plan: gospels, version: 1, behavior: .pace, start: library.today, readingDays: [1, 2, 3, 4, 5]))
    let read = try library.record(.marked(.init(.completed, assignment: 1, date: library.today)), enrollment: id)

    // Put right, the clock is a year earlier than the events already made.
    device.now = try CivilDate("2027-03-01").start(in: device.zone).addingTimeInterval(7 * 3600)
    library.refreshToday()
    #expect(library.today == (try CivilDate("2027-03-01")))
    // Undo still answers the mark: its id comes after it, as the journal's
    // order needs, whatever the clock says.
    let undo = try library.record(.undone(target: read.id), enrollment: id)
    #expect(undo.id > read.id)
    #expect(library.activeEnrollments[0].state(of: Slot(assignment: 1)) == .unread)
    // The plan began on the date the reader was shown; today is before it.
    #expect(library.activeEnrollments[0].today(library.today).status == .upcoming)
}
