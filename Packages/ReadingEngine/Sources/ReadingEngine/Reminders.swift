/// A local date and wall-clock time, with no zone (docs/engine.md,
/// "Reminders"): what a clock on the reader's wall shows. The engine works
/// in these and never in instants, so a 07:00 reminder stays at 07:00 when
/// the clocks change or the reader travels.
public struct LocalDateTime: Hashable, Comparable, Sendable {
    public let date: CivilDate
    public let time: WallTime

    public init(date: CivilDate, time: WallTime) {
        self.date = date
        self.time = time
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { (lhs.date, lhs.time) < (rhs.date, rhs.time) }
}

/// A reminder the device should schedule, at a wall-clock time in whatever
/// zone it is then in.
public struct ScheduledReminder: Hashable, Sendable {
    public let enrollment: EventID
    public let at: LocalDateTime
    /// The reading it is about, for its text ("Gospels at your pace: Mark
    /// 4:1–20."): a calendar day's appointment, or a sequence's next
    /// reading as things stand now.
    public let slot: Slot?
    /// Whether it is a reminder the reader snoozed.
    public let isSnooze: Bool
}

/// The reader's settings for reminders, which belong to the device and not
/// to any one enrollment.
public struct ReminderSettings: Hashable, Sendable {
    /// From one wall-clock time up to another; they may cross midnight.
    public struct QuietHours: Hashable, Sendable {
        public let from: WallTime
        public let until: WallTime

        public init(from: WallTime, until: WallTime) {
            self.from = from
            self.until = until
        }
    }

    /// A reminder the reader asked to see again, at a later time.
    public struct Snooze: Hashable, Sendable {
        public let enrollment: EventID
        public let at: LocalDateTime

        public init(enrollment: EventID, at: LocalDateTime) {
            self.enrollment = enrollment
            self.at = at
        }
    }

    public var quietHours: QuietHours?
    /// The most reminders on one date; nil for no limit.
    public var mostADay: Int?
    /// How many reminders to give. iOS keeps at most 64 pending requests
    /// (Research finding 9), so the app asks for 60 and refills.
    public var window: Int
    public var snoozes: [Snooze]

    public init(quietHours: QuietHours? = nil, mostADay: Int? = nil, window: Int = 60, snoozes: [Snooze] = []) {
        self.quietHours = quietHours
        self.mostADay = mostADay
        self.window = window
        self.snoozes = snoozes
    }

    /// A time as quiet hours leave it: inside them it moves to their end
    /// when that is later the same day, and is dropped (nil) otherwise, so a
    /// reminder never arrives the next morning about the day before.
    public func afterQuietHours(_ time: WallTime) -> WallTime? {
        guard let quietHours, quietHours.from != quietHours.until else { return time }
        if quietHours.from < quietHours.until {
            return quietHours.from <= time && time < quietHours.until ? quietHours.until : time
        }
        if time < quietHours.until { return quietHours.until }
        return time >= quietHours.from ? nil : time
    }
}

extension Journal {
    /// How far ahead reminders are looked for: today and the 365 days after.
    public static let reminderHorizon = 366

    /// The reminders to schedule from `now` (docs/engine.md, "Reminders"),
    /// earliest first. The device schedules them by wall-clock time and asks
    /// again whenever a reading is marked, a setting changes, or the time
    /// zone changes.
    public func reminders(now: LocalDateTime, settings: ReminderSettings) -> [ScheduledReminder] {
        struct Candidate {
            let order: Int
            let reminder: ScheduledReminder
        }
        guard settings.window > 0 else { return [] }
        var candidates: [Candidate] = []

        for (order, enrollment) in enrollments.enumerated() {
            let today = enrollment.today(now.date)
            guard today.status != .ended, today.status != .finished else { continue }
            let isSequence = enrollment.plan.schedule == .sequence
            let unread =
                isSequence
                ? enrollment.plan.assignments.map { Slot(assignment: $0.id) }.filter {
                    enrollment.state(of: $0) == .unread
                } : []
            // A sequence gets no more reminders than it has unread readings.
            var left = isSequence ? min(unread.count, settings.window) : settings.window
            var day = now.date
            for offset in 0..<Self.reminderHorizon where left > 0 {
                if offset > 0 {
                    guard let next = try? day.adding(days: 1) else { break }
                    day = next
                }
                guard enrollment.isReadingDay(day), let arranged = enrollment.arrangement(on: day).reminder else {
                    continue
                }
                if offset == 0, today.status != .reading { continue }
                guard let time = settings.afterQuietHours(arranged) else { continue }
                if offset == 0, time <= now.time { continue }
                let slot: Slot?
                if isSequence {
                    // The next reading as things stand: if the reader reads
                    // nothing it is still next, and a mark asks again.
                    slot = unread.first
                } else {
                    let appointment = Slot(assignment: day.day, appointed: day)
                    guard enrollment.plan.positions[day.day] != nil, enrollment.state(of: appointment) == .unread
                    else { continue }
                    slot = appointment
                }
                candidates.append(
                    Candidate(
                        order: order,
                        reminder: ScheduledReminder(
                            enrollment: enrollment.id, at: LocalDateTime(date: day, time: time), slot: slot,
                            isSnooze: false)))
                left -= 1
            }
        }

        // A snooze: one more, if it is still to come and the reading it was
        // about is still to read.
        for snooze in settings.snoozes {
            guard let order = enrollments.firstIndex(where: { $0.id == snooze.enrollment }) else { continue }
            let today = enrollments[order].today(now.date)
            guard today.status == .reading, let time = settings.afterQuietHours(snooze.at.time) else { continue }
            let at = LocalDateTime(date: snooze.at.date, time: time)
            guard at > now else { continue }
            candidates.append(
                Candidate(
                    order: order,
                    reminder: ScheduledReminder(
                        enrollment: snooze.enrollment, at: at, slot: today.readings.first, isSnooze: true)))
        }

        candidates.sort {
            if $0.reminder.at != $1.reminder.at { return $0.reminder.at < $1.reminder.at }
            if $0.order != $1.order { return $0.order < $1.order }
            return !$0.reminder.isSnooze && $1.reminder.isSnooze
        }
        var kept: [ScheduledReminder] = []
        var onDate = 0
        for candidate in candidates {
            let reminder = candidate.reminder
            // One reminder for an enrollment at one time.
            if kept.contains(where: { $0.enrollment == reminder.enrollment && $0.at == reminder.at }) { continue }
            if kept.last?.at.date != reminder.at.date { onDate = 0 }
            if let most = settings.mostADay, onDate >= most { continue }
            kept.append(reminder)
            onDate += 1
            if kept.count == settings.window { break }
        }
        return kept
    }
}
