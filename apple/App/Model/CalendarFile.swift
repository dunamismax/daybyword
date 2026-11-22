import Foundation
import ReadingData
import ReadingEngine

/// A calendar file of the readings ahead (BUILD.md P13.4, docs/decisions.md
/// E59): iCalendar (RFC 5545) text the reader imports into their own
/// calendar. A snapshot, not a subscription. The web writes the same bytes
/// (web/src/lib/calendar.ts); both are held to tests/fixtures/calendar.json.
enum CalendarFile {
    /// One day's readings in one plan.
    struct Event: Hashable, Sendable {
        /// The enrollment's id, which with the date makes the event's UID.
        let enrollment: String
        /// A civil date, YYYY-MM-DD.
        let date: String
        let plan: String
        /// "Reading 12", or "Day 21" by the date.
        let label: String
        /// The day's references as shown ("Matthew 1–3").
        let references: [String]
    }

    /// How far ahead the file reaches: four weeks, since a plan at the
    /// reader's pace moves when a day is missed and the file does not.
    static let days = 28

    /// The days ahead in one plan with readings on them, as events: the
    /// engine's own days ahead (docs/engine.md, "The days ahead").
    static func events(
        _ enrollment: Enrollment, plan: Plan, from date: CivilDate, formatter: ReferenceFormatter
    ) -> [Event] {
        let readings = Dictionary(plan.assignments.map { ($0.id, $0.reading) }, uniquingKeysWith: { first, _ in first })
        return enrollment.comingDays(from: date, count: days).compactMap { day -> Event? in
            guard let first = day.readings.first else { return nil }
            let references = day.readings.compactMap { slot in
                readings[slot.assignment].map { formatter.string(for: $0) }
            }
            return Event(
                enrollment: enrollment.id.description, date: day.date.description, plan: plan.title,
                label: TodaysReading.label(first, in: enrollment), references: references)
        }
    }

    /// The file for one plan, written to the temporary folder to share.
    static func file(_ events: [Event], plan: String, time: WallTime?, now: Date) throws -> URL {
        let text = text(
            events, stamp: now.formatted(.iso8601), time: time?.description, description: description)
        let url = FileManager.default.temporaryDirectory.appending(path: "\(plan).ics")
        try Data(text.utf8).write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    /// The description for each event, with `{label}` in it.
    static var description: String {
        String(localized: "{label}. Read it in your own Bible, then mark it read in Day by Word.")
    }

    /// The file for `events`, lines joined by CRLF. `stamp` is the moment
    /// it is made, an ISO 8601 instant in UTC; `time` a wall-clock time
    /// HH:MM for every event, or nil for all-day events.
    static func text(_ events: [Event], stamp: String, time: String?, description: String) -> String {
        let stamp = stamp.replacing(/[-:]/, with: "").replacing(/\.\d+/, with: "")
        var lines = [
            "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Day by Word//Calendar export 1//EN", "CALSCALE:GREGORIAN",
        ]
        for event in events {
            let day = event.date.replacing("-", with: "")
            lines += ["BEGIN:VEVENT", "UID:\(event.enrollment)-\(day)@daybyword.com", "DTSTAMP:\(stamp)"]
            if let time {
                // Floating time: the wall-clock time wherever the reader is,
                // as the reminders are (docs/engine.md, "Reminders").
                lines += ["DTSTART:\(day)T\(time.replacing(":", with: ""))00", "DURATION:PT15M"]
            } else {
                lines += ["DTSTART;VALUE=DATE:\(day)", "DTEND;VALUE=DATE:\(nextDay(event.date))"]
            }
            lines += [
                "SUMMARY:\(escape("\(event.plan): \(event.references.joined(separator: "; "))"))",
                "DESCRIPTION:\(escape(description.replacing("{label}", with: event.label)))",
                "TRANSP:TRANSPARENT",
                "END:VEVENT",
            ]
        }
        lines.append("END:VCALENDAR")
        return lines.map(fold).joined(separator: "\r\n") + "\r\n"
    }

    /// The day after a civil date, YYYYMMDD.
    private static func nextDay(_ date: String) -> String {
        let parts = date.split(separator: "-").compactMap { Int($0) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        guard parts.count == 3,
            let day = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])),
            let next = calendar.date(byAdding: .day, value: 1, to: day)
        else { return date.replacing("-", with: "") }
        let components = calendar.dateComponents([.year, .month, .day], from: next)
        return String(format: "%04d%02d%02d", components.year!, components.month!, components.day!)
    }

    /// RFC 5545 TEXT: backslash, semicolon, comma and newline escaped.
    private static func escape(_ text: String) -> String {
        text.replacing("\\", with: "\\\\").replacing(";", with: "\\;").replacing(",", with: "\\,")
            .replacing("\n", with: "\\n")
    }

    /// A line of at most 75 octets, continued on lines that begin with a
    /// space, never splitting a character.
    private static func fold(_ line: String) -> String {
        var parts: [String] = []
        var current = ""
        var octets = 0
        for character in line.unicodeScalars {
            let size = String(character).utf8.count
            if octets + size > (parts.isEmpty ? 75 : 74) {
                parts.append(current)
                current = ""
                octets = 0
            }
            current.unicodeScalars.append(character)
            octets += size
        }
        parts.append(current)
        return parts.joined(separator: "\r\n ")
    }
}
