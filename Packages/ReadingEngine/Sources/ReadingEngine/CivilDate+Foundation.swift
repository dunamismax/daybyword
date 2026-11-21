import Foundation

// The edge between instants and civil dates (docs/engine.md, "Civil dates";
// docs/decisions.md E7). A client resolves "today" here once, in the
// reader's time zone, and gives the engine the civil date; the engine's rules
// never see a `Date`.
extension CivilDate {
    /// The civil date it is at `instant` in `zone`.
    public init(_ instant: Date, in zone: TimeZone) throws(CivilDateError) {
        let parts = Self.calendar(in: zone).dateComponents([.era, .year, .month, .day], from: instant)
        // Era 0 is before year 1, which the engine does not handle.
        guard parts.era == 1, let year = parts.year, let month = parts.month, let day = parts.day else {
            throw .outOfRange
        }
        try self.init(year: year, month: month, day: day)
    }

    /// The first instant of this date in `zone`: midnight, or the first time
    /// after it where a daylight saving change skips midnight.
    public func start(in zone: TimeZone) -> Date {
        let calendar = Self.calendar(in: zone)
        let parts = DateComponents(year: year, month: month, day: day, hour: 12)
        // Noon exists on every date in every zone, and the start of its day is
        // the day's first instant.
        let noon = calendar.date(from: parts)!
        return calendar.startOfDay(for: noon)
    }

    fileprivate static func calendar(in zone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar
    }
}

// The same edge for reminders (docs/engine.md, "Reminders"): the device
// tells the engine the local date and wall-clock time now, and schedules
// what the engine returns by wall-clock time in its present zone.
extension LocalDateTime {
    /// The local date and wall-clock time it is at `instant` in `zone`.
    public init(_ instant: Date, in zone: TimeZone) throws(CivilDateError) {
        let parts = CivilDate.calendar(in: zone).dateComponents([.hour, .minute], from: instant)
        guard let hour = parts.hour, let minute = parts.minute, let time = WallTime(hour: hour, minute: minute)
        else { throw .outOfRange }
        self.init(date: try CivilDate(instant, in: zone), time: time)
    }

    /// The date and time as calendar components with no zone, which a
    /// calendar notification trigger fires at by the wall clock: at the
    /// next minute that exists when a daylight saving change skips this
    /// one, and once when it happens twice.
    public var components: DateComponents {
        DateComponents(year: date.year, month: date.month, day: date.day, hour: time.hour, minute: time.minute)
    }
}
