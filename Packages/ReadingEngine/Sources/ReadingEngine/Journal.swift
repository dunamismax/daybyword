/// The journal, folded (docs/engine.md, "The fold"; E3, E40): its events in
/// journal order, each once; the inert ones and why; which are active; and
/// each enrollment's state. The same events give the same state in whatever
/// order they arrived. Nothing here reads a clock, a zone database, or
/// storage.
public struct Journal: Sendable {
    /// Why an event can mean nothing. It is kept, and only does nothing.
    public enum InertReason: String, Hashable, Sendable, CaseIterable {
        case noEnrollment
        case unknownPlan
        case unknownAssignment
        case wrongSlot
        case notPermitted
        case noTarget
        case ended
        case noEffect
    }

    public struct Inert: Hashable, Sendable {
        public let event: EventID
        public let reason: InertReason
    }

    /// In journal order, each id once.
    public let events: [JournalEvent]
    /// The events that can mean nothing, in journal order.
    public let inert: [Inert]
    /// In the order of their `enrolled` events.
    public let enrollments: [Enrollment]
    private let activeIDs: Set<EventID>

    /// Whether an event is active: in the journal, not inert, and not undone.
    public func isActive(_ id: EventID) -> Bool { activeIDs.contains(id) }

    /// Reads events from a JSON array of their wire forms and folds them.
    /// Every event is checked before any is folded, so a malformed event
    /// refuses the journal whatever else is wrong with it.
    public init(wire values: [JSONValue], plans: [PlanVersion]) throws(JournalError) {
        try self.init(events: try JournalEvent.events(wire: values), plans: plans)
    }

    /// Folds events against the plan versions given. Throws for two different
    /// events under one id.
    public init(events given: [JournalEvent], plans: [PlanVersion]) throws(JournalError) {
        var events: [JournalEvent] = []
        for event in given.sorted(by: { $0.id < $1.id }) {
            guard let last = events.last, last.id == event.id else {
                events.append(event)
                continue
            }
            guard last == event else { throw .conflictingEvent(event.id) }
        }

        var fold = Fold(events: events, plans: plans)
        for index in events.indices { fold.take(index) }

        self.events = events
        inert = fold.inert
        activeIDs = Set(events.indices.filter { fold.active[$0] }.map { events[$0].id })
        enrollments = fold.order.map { id in
            let working = fold.working[id]!
            return Enrollment(
                id: id, plan: working.plan, enrolled: working.enrolled,
                marks: working.marks.filter { fold.active[$0] }.map { fold.marked(at: $0) },
                arranging: fold.activeArranging(working))
        }
    }
}

/// One event of an enrollment that is neither its `enrolled` event, a mark,
/// nor an undo, with the id it came under.
public struct ArrangingEvent: Hashable, Sendable {
    public enum Body: Hashable, Sendable {
        case changed(JournalEvent.Changed)
        case paused(from: CivilDate)
        case resumed(from: CivilDate, basis: JournalEvent.Basis?)
        case returned(date: CivilDate, choice: JournalEvent.Choice, basis: JournalEvent.Basis?)
        case ended(date: CivilDate)
    }

    public let id: EventID
    public let body: Body
}

/// A marking event, with the id it came under.
public struct MarkingEvent: Hashable, Sendable {
    public let id: EventID
    public let marked: JournalEvent.Marked
}

/// The behavior arranged for a date, from the active events given.
private func arrangedBehavior(
    on date: CivilDate, enrolled: JournalEvent.Enrolled, arranging: [ArrangingEvent]
) -> Plan.Behavior {
    var behavior = enrolled.behavior
    for event in arranging {
        if case .changed(let changed) = event.body, let changedBehavior = changed.behavior, changed.from <= date {
            behavior = changedBehavior
        }
    }
    return behavior
}

/// The start date, from the active events given.
private func arrangedStart(enrolled: JournalEvent.Enrolled, arranging: [ArrangingEvent]) -> CivilDate {
    var start = enrolled.start
    for event in arranging {
        if case .changed(let changed) = event.body, let changedStart = changed.start { start = changedStart }
    }
    return start
}

/// The fold under way: what the events before the one being taken add up to.
private struct Fold {
    struct Working {
        let plan: PlanVersion
        let enrolled: JournalEvent.Enrolled
        /// Indices, in journal order, of its marking events that are not inert.
        var marks: [Int] = []
        /// Indices of its other events that are not inert, undos apart.
        var arranging: [Int] = []
    }

    let events: [JournalEvent]
    let plans: [String: PlanVersion]
    var indexOf: [EventID: Int] = [:]
    var effective: [Bool]
    var active: [Bool]
    var undoers: [Int: [Int]] = [:]
    var working: [EventID: Working] = [:]
    var order: [EventID] = []
    var inert: [Journal.Inert] = []

    init(events: [JournalEvent], plans: [PlanVersion]) {
        self.events = events
        self.plans = Dictionary(
            plans.map { (Self.key($0.id, $0.version), $0) }, uniquingKeysWith: { first, _ in first })
        effective = Array(repeating: false, count: events.count)
        active = Array(repeating: false, count: events.count)
    }

    static func key(_ plan: PlanID, _ version: Int) -> String { "\(plan.rawValue)@\(version)" }

    func arranging(at index: Int) -> ArrangingEvent? {
        let event = events[index]
        let body: ArrangingEvent.Body
        switch event.body {
        case .changed(let changed): body = .changed(changed)
        case .paused(let from): body = .paused(from: from)
        case .resumed(let from, let basis): body = .resumed(from: from, basis: basis)
        case .returned(let date, let choice, let basis): body = .returned(date: date, choice: choice, basis: basis)
        case .ended(let date): body = .ended(date: date)
        case .enrolled, .marked, .undone: return nil
        }
        return ArrangingEvent(id: event.id, body: body)
    }

    func marked(at index: Int) -> MarkingEvent {
        guard case .marked(let marked) = events[index].body else { preconditionFailure("not a marking event") }
        return MarkingEvent(id: events[index].id, marked: marked)
    }

    func activeArranging(_ working: Working) -> [ArrangingEvent] {
        working.arranging.filter { active[$0] }.compactMap { arranging(at: $0) }
    }

    /// The id of the enrollment's active `ended` event, if it has one.
    func stopped(_ working: Working) -> EventID? {
        activeArranging(working).last {
            if case .ended = $0.body { true } else { false }
        }?.id
    }

    /// Whether the last active `paused` or `resumed` event is a `paused` one.
    func isPaused(_ working: Working) -> Bool {
        for event in activeArranging(working).reversed() {
            switch event.body {
            case .paused: return true
            case .resumed: return false
            case .changed, .returned, .ended: continue
            }
        }
        return false
    }

    func isScheduled(_ working: Working, on date: CivilDate, own: Plan.Behavior? = nil) -> Bool {
        (own ?? arrangedBehavior(on: date, enrolled: working.enrolled, arranging: activeArranging(working)))
            == .finishDate
    }

    /// Why an event can mean nothing, from the events before it alone.
    func reason(for event: JournalEvent) -> Journal.InertReason? {
        let enrollment = working[event.enrollment]
        if case .enrolled(let enrolled) = event.body {
            guard enrollment == nil else { return .noEffect }
            guard let plan = plans[Self.key(enrolled.plan, enrolled.version)] else { return .unknownPlan }
            guard plan.behaviors.contains(enrolled.behavior) else { return .notPermitted }
            if enrolled.behavior != .finishDate, enrolled.finish != nil || enrolled.limit != nil {
                return .notPermitted
            }
            return nil
        }
        guard let enrollment else { return .noEnrollment }
        if let stopped = stopped(enrollment) {
            guard case .undone(let target) = event.body, target == stopped else { return .ended }
        }
        switch event.body {
        case .enrolled, .ended:
            return nil
        case .marked(let marked):
            guard enrollment.plan.positions[marked.assignment] != nil else { return .unknownAssignment }
            guard enrollment.plan.schedule == .dayOfMonth else { return marked.appointed == nil ? nil : .wrongSlot }
            let start = arrangedStart(enrolled: enrollment.enrolled, arranging: activeArranging(enrollment))
            guard let appointed = marked.appointed, appointed.day == marked.assignment, start <= appointed else {
                return .wrongSlot
            }
            return nil
        case .undone(let target):
            guard let index = indexOf[target], effective[index], events[index].enrollment == event.enrollment else {
                return .noTarget
            }
            if case .enrolled = events[index].body { return .noTarget }
            return nil
        case .changed(let changed):
            guard !changed.isEmpty else { return .noEffect }
            if let behavior = changed.behavior, !enrollment.plan.behaviors.contains(behavior) {
                return .notPermitted
            }
            if changed.basis != nil || changed.limit != nil,
                !isScheduled(enrollment, on: changed.from, own: changed.behavior)
            {
                return .notPermitted
            }
            return nil
        case .paused:
            return isPaused(enrollment) ? .noEffect : nil
        case .resumed(let from, let basis):
            guard isPaused(enrollment) else { return .noEffect }
            return basis != nil && !isScheduled(enrollment, on: from) ? .notPermitted : nil
        case .returned(let date, let choice, _):
            let behavior = arrangedBehavior(
                on: date, enrolled: enrollment.enrolled, arranging: activeArranging(enrollment))
            let fits =
                switch choice {
                case .rejoin: behavior == .calendar
                case .continue: behavior != .calendar
                case .spread, .moveFinish: behavior == .finishDate
                }
            return fits ? nil : .notPermitted
        }
    }

    /// Whether an event is active: no active undo targets it. Follows the
    /// change down the chain of undos.
    mutating func refresh(_ index: Int) {
        var next: Int? = index
        while let at = next {
            let now = !(undoers[at] ?? []).contains { active[$0] }
            guard now != active[at] else { return }
            active[at] = now
            if case .undone(let target) = events[at].body { next = indexOf[target] } else { next = nil }
        }
    }

    mutating func take(_ index: Int) {
        let event = events[index]
        let reason = reason(for: event)
        indexOf[event.id] = index
        if let reason {
            inert.append(Journal.Inert(event: event.id, reason: reason))
            return
        }
        effective[index] = true
        active[index] = true
        switch event.body {
        case .enrolled(let enrolled):
            working[event.enrollment] = Working(
                plan: plans[Self.key(enrolled.plan, enrolled.version)]!, enrolled: enrolled)
            order.append(event.enrollment)
        case .undone(let target):
            let targetIndex = indexOf[target]!
            undoers[targetIndex, default: []].append(index)
            refresh(targetIndex)
        case .marked:
            working[event.enrollment]!.marks.append(index)
        case .changed, .paused, .resumed, .returned, .ended:
            working[event.enrollment]!.arranging.append(index)
        }
    }
}

/// One thing a reader can mark (docs/engine.md, "Plans and assignments"): an
/// assignment, and on a calendar plan the date it is appointed to.
public struct Slot: Hashable, Sendable {
    public let assignment: Int
    public let appointed: CivilDate?

    public init(assignment: Int, appointed: CivilDate? = nil) {
        self.assignment = assignment
        self.appointed = appointed
    }
}

/// The four states a reader sees: "Not yet read", "Read", "Part read",
/// "Skipped".
public enum SlotState: String, Hashable, Sendable, CaseIterable {
    case unread
    case read
    case partlyRead
    case skipped
}

/// What a settled slot's last active marking event says.
public struct SlotMark: Hashable, Sendable {
    public let slot: Slot
    public let state: SlotState
    /// The day the reading happened.
    public let date: CivilDate
    public let event: EventID
    public let verses: String?
}

/// The reader's arrangement for following a plan, on one date.
public struct Arrangement: Hashable, Sendable {
    public let behavior: Plan.Behavior
    public let start: CivilDate
    public let readingDays: [Int]
    public let limit: Int?
    public let reminder: WallTime?
}

/// Paused days: from `from` up to, not including, `until`; with no `until`
/// they run on.
public struct Pause: Hashable, Sendable {
    public let from: CivilDate
    public let until: CivilDate?

    public func contains(_ date: CivilDate) -> Bool {
        from <= date && until.map { date < $0 } ?? true
    }
}

/// One reader's following of one plan version (docs/engine.md,
/// "Enrollments"), as the journal's active events add up to it. It is never
/// stored or edited: it is always folded from the journal.
public struct Enrollment: Sendable {
    public let id: EventID
    public let plan: PlanVersion
    public let enrolled: JournalEvent.Enrolled
    /// Its active marking events, in journal order.
    public let marks: [MarkingEvent]
    /// Its other active events, in journal order.
    public let arranging: [ArrangingEvent]
    public let start: CivilDate
    /// The date the reader stopped, when they have.
    public let ended: CivilDate?
    /// In order of date, with none overlapping.
    public let pauses: [Pause]
    /// Every settled slot, in reading order and then by appointed date.
    public let settled: [SlotMark]
    private let slots: [Slot: SlotMark]

    init(
        id: EventID, plan: PlanVersion, enrolled: JournalEvent.Enrolled, marks: [MarkingEvent],
        arranging: [ArrangingEvent]
    ) {
        self.id = id
        self.plan = plan
        self.enrolled = enrolled
        self.marks = marks
        self.arranging = arranging
        start = arrangedStart(enrolled: enrolled, arranging: arranging)
        var ended: CivilDate?
        for event in arranging { if case .ended(let date) = event.body { ended = date } }
        self.ended = ended

        var slots: [Slot: SlotMark] = [:]
        for mark in marks {
            let slot = Slot(assignment: mark.marked.assignment, appointed: mark.marked.appointed)
            let state: SlotState =
                switch mark.marked.mark {
                case .completed: .read
                case .partlyCompleted: .partlyRead
                case .skipped: .skipped
                }
            slots[slot] = SlotMark(
                slot: slot, state: state, date: mark.marked.date, event: mark.id, verses: mark.marked.verses)
        }
        self.slots = slots
        settled = slots.values.sorted {
            let (first, second) = (plan.positions[$0.slot.assignment] ?? 0, plan.positions[$1.slot.assignment] ?? 0)
            if first != second { return first < second }
            guard let earlier = $0.slot.appointed, let later = $1.slot.appointed else { return false }
            return earlier < later
        }
        pauses = Self.pauses(arranging)
    }

    /// A slot's state: what its last active marking event says, or unread.
    public func state(of slot: Slot) -> SlotState { slots[slot]?.state ?? .unread }

    /// The arrangement on a date.
    public func arrangement(on date: CivilDate) -> Arrangement {
        var readingDays = enrolled.readingDays
        var limit = enrolled.limit
        var reminder = enrolled.reminder
        for event in arranging {
            guard case .changed(let changed) = event.body, changed.from <= date else { continue }
            readingDays = changed.readingDays ?? readingDays
            limit = changed.limit ?? limit
            reminder = changed.reminder ?? reminder
        }
        var time: WallTime?
        if case .at(let wallTime) = reminder { time = wallTime }
        return Arrangement(
            behavior: arrangedBehavior(on: date, enrolled: enrolled, arranging: arranging), start: start,
            readingDays: readingDays, limit: limit, reminder: time)
    }

    /// Whether a date is a paused day.
    public func isPaused(_ date: CivilDate) -> Bool { pauses.contains { $0.contains(date) } }

    /// The paused days the active `paused` and `resumed` events give, merged
    /// and in order.
    private static func pauses(_ arranging: [ArrangingEvent]) -> [Pause] {
        var ranges: [Pause] = []
        for (index, event) in arranging.enumerated() {
            guard case .paused(let from) = event.body else { continue }
            var until: CivilDate?
            var isResumed = false
            for later in arranging[(index + 1)...] {
                if case .resumed(let resumed, _) = later.body {
                    until = resumed
                    isResumed = true
                    break
                }
            }
            if !isResumed {
                ranges.append(Pause(from: from, until: nil))
            } else if let until, from < until {
                ranges.append(Pause(from: from, until: until))
            }
        }
        ranges.sort { $0.from < $1.from }
        var merged: [Pause] = []
        for range in ranges {
            guard let last = merged.last else {
                merged.append(range)
                continue
            }
            guard let lastUntil = last.until else { continue }
            if range.from > lastUntil {
                merged.append(range)
            } else if let until = range.until {
                if until > lastUntil { merged[merged.count - 1] = Pause(from: last.from, until: until) }
            } else {
                merged[merged.count - 1] = Pause(from: last.from, until: nil)
            }
        }
        return merged
    }
}
