/// What one enrollment asks of the reader on one date (docs/engine.md,
/// "Today" and the three behaviors). A pure answer from the folded journal
/// and the date the client resolved at the edge (E7).
public struct Today: Hashable, Sendable {
    public enum Status: String, Hashable, Sendable, CaseIterable {
        /// Before the start date.
        case upcoming
        /// There is a reading for today, not yet done.
        case reading
        /// Today's reading is read or partly read.
        case done
        /// A reading day with nothing left for today.
        case open
        case rest
        case paused
        /// A sequence with no unread reading.
        case finished
        /// The reader stopped.
        case ended
    }

    /// Where a pace enrollment is heading. Projected, never promised.
    public struct Projection: Hashable, Sendable {
        /// At one reading each reading day from the first open day.
        public let plan: CivilDate?
        /// At the pace of the 28 days before today, when there is enough to
        /// go on.
        public let recent: CivilDate?
        /// Had one reading been read every reading day since the start.
        public let unbroken: CivilDate?
    }

    /// A finish-date enrollment's schedule: its basis and where the reader
    /// stands against it.
    public struct Schedule: Hashable, Sendable {
        /// The basis: its first day, its finish date, and the readings
        /// unread when it was set.
        public let first: CivilDate
        public let finish: CivilDate
        public let remaining: Int
        /// The reading days from the first day to the finish.
        public let scheduledDays: Int
        /// The fewest and the most readings the basis puts on one day.
        public let least: Int
        public let most: Int
        /// The words of the heaviest day still ahead; nil when a reading has
        /// no word count, or none is unread.
        public let heaviestWords: Int?
        /// The readings due before today and not yet settled.
        public let outstanding: Int
        /// The readings the basis gives today.
        public let share: Int
        /// The most readings on one reading day the reader accepts.
        public let limit: Int?
        /// The earliest finish that fits the limit, when `most` is beyond it.
        public let finishWithinLimit: CivilDate?
    }

    /// A calendar enrollment's day.
    public struct Calendar: Hashable, Sendable {
        /// Today's appointment, whatever the status.
        public let appointment: Slot
        public let state: SlotState
        /// On the last day of a short month, the readings it does not appoint.
        public let notAppointed: [Int]
        /// The unread slots from the start to yesterday, paused days excluded.
        public let missed: Int
    }

    public let status: Status
    /// Whether today is one of the reader's reading days.
    public let isReadingDay: Bool
    /// The readings to read today, in reading order.
    public let readings: [Slot]
    /// The slots read or partly read with today's date, in reading order.
    public let readToday: [Slot]
    /// The next unread reading of a sequence.
    public let next: Slot?
    public let projection: Projection?
    public let schedule: Schedule?
    public let calendar: Calendar?
}

extension Enrollment {
    /// Whether a date is a reading day (docs/engine.md, "Reading days and
    /// rest days"): on or after the start, a weekday arranged for that date,
    /// not paused, and not after the enrollment ended.
    public func isReadingDay(_ date: CivilDate) -> Bool {
        guard date >= start, !isPaused(date) else { return false }
        if let ended, date > ended { return false }
        return arrangement(on: date).readingDays.contains(date.weekday)
    }

    /// The `count`-th reading day counting from `date`, which counts when it
    /// is one; nil when it never comes (the enrollment ended, a pause with
    /// no end, or past the last date).
    public func readingDay(_ count: Int, from date: CivilDate) -> CivilDate? {
        guard count >= 1 else { return nil }
        var day = max(date, start)
        var left = count
        while true {
            if let ended, day > ended { return nil }
            if let pause = pauses.first(where: { $0.contains(day) }) {
                guard let until = pause.until else { return nil }
                day = until
                continue
            }
            if arrangement(on: day).readingDays.contains(day.weekday) {
                left -= 1
                if left == 0 { return day }
            }
            guard let next = try? day.adding(days: 1) else { return nil }
            day = next
        }
    }

    /// The reading days from one date to another, both included.
    func readingDays(from first: CivilDate, through last: CivilDate) -> Int {
        var count = 0
        var day = max(first, start)
        while day <= last {
            if let ended, day > ended { break }
            if let pause = pauses.first(where: { $0.contains(day) }) {
                guard let until = pause.until else { break }
                day = until
                continue
            }
            if arrangement(on: day).readingDays.contains(day.weekday) { count += 1 }
            guard let next = try? day.adding(days: 1) else { break }
            day = next
        }
        return count
    }

    /// A finish-date schedule's basis: its first day, finish, and the
    /// readings unread when it was set. The last active event that sets one
    /// is the basis; nil when none has.
    var basis: (first: CivilDate, finish: CivilDate, remaining: Int)? {
        var basis = enrolled.finish.map { (first: start, finish: $0, remaining: plan.assignments.count) }
        for event in arranging {
            switch event.body {
            case .changed(let changed):
                if let set = changed.basis { basis = (changed.from, set.finish, set.remaining) }
            case .resumed(let from, let set):
                if let set { basis = (from, set.finish, set.remaining) }
            case .returned(let date, _, let set):
                if let set { basis = (date, set.finish, set.remaining) }
            case .paused, .ended:
                continue
            }
        }
        return basis.map { ($0.first, $0.finish, min($0.remaining, plan.assignments.count)) }
    }

    /// What this enrollment asks of the reader on `date`.
    public func today(_ date: CivilDate) -> Today {
        let isReadingDay = self.isReadingDay(date)
        let readToday = settled.filter { ($0.state == .read || $0.state == .partlyRead) && $0.date == date }
            .map(\.slot)
        let behavior = arrangement(on: date).behavior
        if plan.schedule == .dayOfMonth {
            return calendarDay(date, isReadingDay: isReadingDay, readToday: readToday)
        }

        let unread = plan.assignments.map { Slot(assignment: $0.id) }.filter { state(of: $0) == .unread }
        let schedule = behavior == .finishDate ? self.schedule(on: date, unread: unread) : nil
        // How many readings are today's, when today is a reading day.
        var count = unread.isEmpty ? 0 : 1
        if let schedule {
            let settledCount = plan.assignments.count - unread.count
            let needed = max(0, target(after: date) - settledCount)
            let quota = schedule.share > 0 ? schedule.share : (schedule.outstanding > 0 ? 1 : 0)
            count = min(needed, max(0, quota - readToday.count), unread.count)
        } else if !readToday.isEmpty {
            count = 0
        }

        let status: Today.Status
        if ended != nil {
            status = .ended
        } else if unread.isEmpty {
            status = .finished
        } else if date < start {
            status = .upcoming
        } else if isPaused(date) {
            status = .paused
        } else if !isReadingDay {
            status = .rest
        } else if count > 0 {
            status = .reading
        } else {
            status = readToday.isEmpty ? .open : .done
        }

        let isOver = status == .ended || status == .finished
        var projection: Today.Projection?
        if schedule == nil, !isOver, status != .paused {
            projection = paceProjection(on: date, unread: unread.count, fromToday: status == .reading)
        }
        return Today(
            status: status, isReadingDay: isReadingDay, readings: status == .reading ? Array(unread.prefix(count)) : [],
            readToday: readToday, next: isOver || status == .upcoming ? nil : unread.first, projection: projection,
            schedule: isOver ? nil : schedule, calendar: nil)
    }

    // MARK: Continue at my pace

    private func paceProjection(on date: CivilDate, unread: Int, fromToday: Bool) -> Today.Projection {
        let tomorrow = try? date.adding(days: 1)
        let firstOpen = fromToday ? date : tomorrow
        var recent: CivilDate?
        // The 28 days before today, and not before the start.
        if let yesterday = try? date.adding(days: -1), let firstOpen {
            let window = max(start, (try? date.adding(days: -28)) ?? start)
            if window <= yesterday {
                let read = settled.count {
                    ($0.state == .read || $0.state == .partlyRead) && window <= $0.date && $0.date <= yesterday
                }
                let days = readingDays(from: window, through: yesterday)
                if days >= 5, read >= 1 {
                    recent = readingDay((unread * days + read - 1) / read, from: firstOpen)
                }
            }
        }
        return Today.Projection(
            plan: firstOpen.flatMap { readingDay(unread, from: $0) }, recent: recent,
            unbroken: readingDay(plan.assignments.count, from: start))
    }

    // MARK: Work toward a finish date

    /// The settled readings due once `date` is over.
    func target(after date: CivilDate) -> Int {
        let total = plan.assignments.count
        guard let basis else { return total }
        guard date >= basis.first else { return total - basis.remaining }
        let scheduled = readingDays(from: basis.first, through: basis.finish)
        guard scheduled > 0, date <= basis.finish else { return total }
        return total - basis.remaining + readingDays(from: basis.first, through: date) * basis.remaining / scheduled
    }

    private func schedule(on date: CivilDate, unread: [Slot]) -> Today.Schedule? {
        guard let basis else { return nil }
        let scheduled = readingDays(from: basis.first, through: basis.finish)
        let settledCount = plan.assignments.count - unread.count
        let before = (try? date.adding(days: -1)).map { target(after: $0) } ?? plan.assignments.count - basis.remaining
        let isScheduled = isReadingDay(date) && basis.first <= date && date <= basis.finish
        let (least, most) =
            scheduled > 0
            ? (basis.remaining / scheduled, (basis.remaining + scheduled - 1) / scheduled)
            : (basis.remaining, basis.remaining)

        // Each unread reading's scheduled day: the k-th of the basis's
        // readings is expected on scheduled day ⌈k × N ÷ R⌉.
        var heaviest: Int?
        if scheduled > 0, !unread.isEmpty {
            var words: [Int: Int] = [:]
            var counted = true
            for (index, slot) in unread.enumerated() {
                guard let count = plan.words[slot.assignment] else {
                    counted = false
                    break
                }
                let place = min(max(basis.remaining - unread.count + index + 1, 1), basis.remaining)
                words[(place * scheduled + basis.remaining - 1) / basis.remaining, default: 0] += count
            }
            heaviest = counted ? words.values.max() : nil
        }

        let limit = arrangement(on: date).limit
        var finishWithinLimit: CivilDate?
        if let limit, most > limit {
            finishWithinLimit = readingDay((basis.remaining + limit - 1) / limit, from: basis.first)
        }
        return Today.Schedule(
            first: basis.first, finish: basis.finish, remaining: basis.remaining, scheduledDays: scheduled,
            least: least, most: most, heaviestWords: heaviest, outstanding: max(0, before - settledCount),
            share: isScheduled ? target(after: date) - before : 0, limit: limit, finishWithinLimit: finishWithinLimit)
    }

    // MARK: Follow the calendar

    private func calendarDay(_ date: CivilDate, isReadingDay: Bool, readToday: [Slot]) -> Today {
        let slot = Slot(assignment: date.day, appointed: date)
        let state = self.state(of: slot)
        let isAppointed = date >= start && plan.positions[date.day] != nil
        let status: Today.Status
        if ended != nil {
            status = .ended
        } else if date < start {
            status = .upcoming
        } else if isPaused(date) {
            status = .paused
        } else if !isReadingDay {
            status = .rest
        } else if !isAppointed || state == .skipped {
            status = .open
        } else {
            status = state == .unread ? .reading : .done
        }

        var calendar: Today.Calendar?
        if isAppointed, status != .ended {
            // The days from the start to yesterday, less the paused ones and
            // the slots settled on the others.
            var missed = start.days(to: date)
            for pause in pauses {
                let from = max(pause.from, start)
                let until = min(pause.until ?? date, date)
                if from < until { missed -= from.days(to: until) }
            }
            missed -= settled.count {
                guard let appointed = $0.slot.appointed else { return false }
                return start <= appointed && appointed < date && !isPaused(appointed)
            }
            let last = date.daysInMonth
            calendar = Today.Calendar(
                appointment: slot, state: state,
                notAppointed: date.day == last && last < 31
                    ? ((last + 1)...31).filter { plan.positions[$0] != nil } : [],
                missed: missed)
        }
        return Today(
            status: status, isReadingDay: isReadingDay, readings: status == .reading ? [slot] : [],
            readToday: readToday, next: nil, projection: nil, schedule: nil, calendar: calendar)
    }
}
