import Foundation

/// One event in the journal (docs/engine.md, "The journal"; E3): something
/// the reader did, kept for good. An event is never edited; taking one back
/// is another event.
public struct JournalEvent: Hashable, Sendable {
    /// What a marking event says about a reading.
    public enum Mark: String, Hashable, Sendable, CaseIterable {
        case completed
        case partlyCompleted
        /// A scheduling decision, not a reading.
        case skipped
    }

    /// The reader's answer to the welcome after a gap ("Returning after a
    /// break").
    public enum Choice: String, Hashable, Sendable, CaseIterable {
        case `continue`
        case spread
        case moveFinish
        case rejoin
    }

    public enum Reminder: Hashable, Sendable {
        case off
        case at(WallTime)
    }

    /// A finish date and the readings unread when it was set, which together
    /// set a schedule's basis ("Work toward a finish date").
    public struct Basis: Hashable, Sendable {
        public let finish: CivilDate
        public let remaining: Int

        public init(finish: CivilDate, remaining: Int) {
            self.finish = finish
            self.remaining = remaining
        }
    }

    public struct Enrolled: Hashable, Sendable {
        public let plan: PlanID
        public let version: Int
        public let behavior: Plan.Behavior
        public let start: CivilDate
        /// Weekday numbers, 1 Monday to 7 Sunday, ascending.
        public let readingDays: [Int]
        public let finish: CivilDate?
        public let limit: Int?
        public let reminder: Reminder?

        public init(
            plan: PlanID, version: Int, behavior: Plan.Behavior, start: CivilDate, readingDays: [Int],
            finish: CivilDate? = nil, limit: Int? = nil, reminder: Reminder? = nil
        ) {
            self.plan = plan
            self.version = version
            self.behavior = behavior
            self.start = start
            self.readingDays = readingDays
            self.finish = finish
            self.limit = limit
            self.reminder = reminder
        }
    }

    public struct Marked: Hashable, Sendable {
        public let mark: Mark
        public let assignment: Int
        /// The day the reading happened.
        public let date: CivilDate
        /// The calendar slot's date, on a calendar plan.
        public let appointed: CivilDate?
        /// Which part was read, on `partlyCompleted`, as the text it was given.
        public let verses: String?

        public init(
            _ mark: Mark, assignment: Int, date: CivilDate, appointed: CivilDate? = nil, verses: String? = nil
        ) {
            self.mark = mark
            self.assignment = assignment
            self.date = date
            self.appointed = appointed
            self.verses = verses
        }
    }

    public struct Changed: Hashable, Sendable {
        public let from: CivilDate
        public let start: CivilDate?
        public let readingDays: [Int]?
        public let behavior: Plan.Behavior?
        public let basis: Basis?
        public let limit: Int?
        public let reminder: Reminder?

        public init(
            from: CivilDate, start: CivilDate? = nil, readingDays: [Int]? = nil, behavior: Plan.Behavior? = nil,
            basis: Basis? = nil, limit: Int? = nil, reminder: Reminder? = nil
        ) {
            self.from = from
            self.start = start
            self.readingDays = readingDays
            self.behavior = behavior
            self.basis = basis
            self.limit = limit
            self.reminder = reminder
        }

        /// Whether it changes nothing.
        var isEmpty: Bool {
            start == nil && readingDays == nil && behavior == nil && basis == nil && limit == nil && reminder == nil
        }
    }

    public enum Body: Hashable, Sendable {
        case enrolled(Enrolled)
        case marked(Marked)
        case undone(target: EventID)
        case changed(Changed)
        case paused(from: CivilDate)
        case resumed(from: CivilDate, basis: Basis?)
        case returned(date: CivilDate, choice: Choice, basis: Basis?)
        case ended(date: CivilDate)
    }

    public let id: EventID
    public let enrollment: EventID
    /// The instant it was made, `YYYY-MM-DDTHH:MM:SSZ`. A record; the engine
    /// never reads it.
    public let at: String
    public let zone: String
    public let device: String
    public let body: Body

    public init(id: EventID, enrollment: EventID, at: String, zone: String, device: String, body: Body) {
        self.id = id
        self.enrollment = enrollment
        self.at = at
        self.zone = zone
        self.device = device
        self.body = body
    }

    /// The kind as the wire writes it.
    public var kind: String {
        switch body {
        case .enrolled: "enrolled"
        case .marked(let marked): marked.mark.rawValue
        case .undone: "undone"
        case .changed: "changed"
        case .paused: "paused"
        case .resumed: "resumed"
        case .returned: "returned"
        case .ended: "ended"
        }
    }
}

/// Why a journal is refused whole (docs/engine.md). Everything else that is
/// wrong with an event makes it inert (`Journal.InertReason`). The kind is
/// the contract; the message is for logs.
public enum JournalError: Error, Hashable, Sendable, CustomStringConvertible {
    /// Not an object, a field missing or of the wrong type, or not a date, id
    /// or kind this version knows.
    case malformedEvent(String)
    /// Two different events under one id.
    case conflictingEvent(EventID)

    public var kind: String {
        switch self {
        case .malformedEvent: "malformedEvent"
        case .conflictingEvent: "conflictingEvent"
        }
    }

    public var description: String {
        switch self {
        case .malformedEvent(let message): message
        case .conflictingEvent(let id): "two different events have the id \(id)"
        }
    }
}

// MARK: The wire

/// What a field should have been, for a malformed event's message.
private enum Expected: String {
    case id = "a UUIDv7 id"
    case kind = "a kind this version knows"
    case instant = "an instant written YYYY-MM-DDTHH:MM:SSZ"
    case zone = "a zone name"
    case device = "a name of 1 to 64 characters"
    case plan = "a plan id"
    case positive = "a whole number from 1"
    case behavior = "a behavior"
    case date = "a date"
    case readingDays = "a list of weekdays, ascending"
    case reminder = "a time written HH:MM, or off"
    case verses = "text"
    case choice = "a return choice"
}

/// One event's fields, read in the specification's order; the first fault is
/// the error.
private struct Fields {
    let fields: [String: JSONValue]
    let number: Int

    init(_ value: JSONValue, number: Int) throws(JournalError) {
        guard case .object(let fields) = value else { throw .malformedEvent("event \(number) is not an object") }
        self.fields = fields
        self.number = number
    }

    func has(_ name: String) -> Bool { fields[name] != nil }

    func required<T>(_ name: String, _ expected: Expected, _ read: (JSONValue) -> T?) throws(JournalError) -> T {
        guard let field = fields[name] else { throw .malformedEvent("event \(number) has no \"\(name)\"") }
        guard let value = read(field) else {
            throw .malformedEvent("event \(number)'s \"\(name)\" is not \(expected.rawValue)")
        }
        return value
    }

    func optional<T>(_ name: String, _ expected: Expected, _ read: (JSONValue) -> T?) throws(JournalError) -> T? {
        has(name) ? try required(name, expected, read) : nil
    }

    /// Required when `needed`, and read when present either way.
    func when<T>(
        _ needed: Bool, _ name: String, _ expected: Expected, _ read: (JSONValue) -> T?
    ) throws(JournalError) -> T? {
        needed ? try required(name, expected, read) : try optional(name, expected, read)
    }
}

private func readID(_ value: JSONValue) -> EventID? { value.text.flatMap(EventID.init) }

private func readDate(_ value: JSONValue) -> CivilDate? { value.text.flatMap { try? CivilDate($0) } }

private func readPositive(_ value: JSONValue) -> Int? { value.whole.flatMap { $0 >= 1 ? $0 : nil } }

private func readInstant(_ value: JSONValue) -> String? {
    guard let text = value.text else { return nil }
    let bytes = Array(text.utf8)
    guard bytes.count == 20, bytes[10] == UInt8(ascii: "T"), bytes[13] == UInt8(ascii: ":"),
        bytes[16] == UInt8(ascii: ":"), bytes[19] == UInt8(ascii: "Z"),
        (try? CivilDate(String(decoding: bytes[0..<10], as: UTF8.self))) != nil
    else { return nil }
    for (range, most) in [(11..<13, 23), (14..<16, 59), (17..<19, 59)] {
        var number = 0
        for byte in bytes[range] {
            guard (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte) else { return nil }
            number = number * 10 + Int(byte - UInt8(ascii: "0"))
        }
        guard number <= most else { return nil }
    }
    return text
}

private let zoneBytes = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_+-/".utf8)

private func readZone(_ value: JSONValue) -> String? {
    guard let text = value.text, (1...64).contains(text.utf8.count), text.utf8.allSatisfy(zoneBytes.contains) else {
        return nil
    }
    return text
}

private func readDevice(_ value: JSONValue) -> String? {
    // Counted in Unicode scalar values, as the TypeScript runtime counts them.
    guard let text = value.text, (1...64).contains(text.unicodeScalars.count) else { return nil }
    return text
}

private func readPlanID(_ value: JSONValue) -> PlanID? { value.text.flatMap(PlanID.init) }

private func readBehavior(_ value: JSONValue) -> Plan.Behavior? { value.text.flatMap(Plan.Behavior.init) }

private func readReadingDays(_ value: JSONValue) -> [Int]? {
    guard case .array(let values) = value, !values.isEmpty else { return nil }
    var days: [Int] = []
    for value in values {
        guard let day = value.whole, day > days.last ?? 0, day <= 7 else { return nil }
        days.append(day)
    }
    return days
}

private func readReminder(_ value: JSONValue) -> JournalEvent.Reminder? {
    guard let text = value.text else { return nil }
    return text == "off" ? .off : WallTime(text).map { .at($0) }
}

private func readVerses(_ value: JSONValue) -> String? { value.text.flatMap { $0.isEmpty ? nil : $0 } }

private func readChoice(_ value: JSONValue) -> JournalEvent.Choice? { value.text.flatMap(JournalEvent.Choice.init) }

private let kinds: Set<String> = [
    "enrolled", "completed", "partlyCompleted", "skipped", "undone", "changed", "paused", "resumed", "returned",
    "ended",
]

extension JournalEvent {
    /// An event from its wire form. `number` is its place among the events as
    /// they were given, from 1, for the error's message.
    public init(wire value: JSONValue, number: Int = 1) throws(JournalError) {
        let fields = try Fields(value, number: number)
        id = try fields.required("id", .id, readID)
        let kind = try fields.required("kind", .kind) { $0.text.flatMap { kinds.contains($0) ? $0 : nil } }
        enrollment = try fields.required("enrollment", .id, readID)
        at = try fields.required("at", .instant, readInstant)
        zone = try fields.required("zone", .zone, readZone)
        device = try fields.required("device", .device, readDevice)
        func basis(needed: Bool) throws(JournalError) -> Basis? {
            let finish = try fields.when(needed || fields.has("remaining"), "finish", .date, readDate)
            let remaining = try fields.when(needed || fields.has("finish"), "remaining", .positive, readPositive)
            guard let finish, let remaining else { return nil }
            return Basis(finish: finish, remaining: remaining)
        }
        switch kind {
        case "enrolled":
            let plan = try fields.required("plan", .plan, readPlanID)
            let version = try fields.required("version", .positive, readPositive)
            let behavior = try fields.required("behavior", .behavior, readBehavior)
            let start = try fields.required("start", .date, readDate)
            let readingDays = try fields.required("readingDays", .readingDays, readReadingDays)
            let scheduled = behavior == .finishDate
            body = .enrolled(
                Enrolled(
                    plan: plan, version: version, behavior: behavior, start: start, readingDays: readingDays,
                    finish: try fields.when(scheduled, "finish", .date, readDate),
                    limit: try fields.when(scheduled, "limit", .positive, readPositive),
                    reminder: try fields.optional("reminder", .reminder, readReminder)))
        case "undone":
            body = .undone(target: try fields.required("target", .id, readID))
        case "changed":
            let from = try fields.required("from", .date, readDate)
            let start = try fields.optional("start", .date, readDate)
            let readingDays = try fields.optional("readingDays", .readingDays, readReadingDays)
            let behavior = try fields.optional("behavior", .behavior, readBehavior)
            let scheduled = behavior == .finishDate
            // In the order the fields are listed: finish, limit, remaining.
            let finish = try fields.when(scheduled || fields.has("remaining"), "finish", .date, readDate)
            let limit = try fields.when(scheduled, "limit", .positive, readPositive)
            let remaining = try fields.when(scheduled || fields.has("finish"), "remaining", .positive, readPositive)
            var basis: Basis?
            if let finish, let remaining { basis = Basis(finish: finish, remaining: remaining) }
            body = .changed(
                Changed(
                    from: from, start: start, readingDays: readingDays, behavior: behavior, basis: basis,
                    limit: limit, reminder: try fields.optional("reminder", .reminder, readReminder)))
        case "paused":
            body = .paused(from: try fields.required("from", .date, readDate))
        case "resumed":
            body = .resumed(from: try fields.required("from", .date, readDate), basis: try basis(needed: false))
        case "returned":
            let date = try fields.required("date", .date, readDate)
            let choice = try fields.required("choice", .choice, readChoice)
            let rescheduling = choice == .spread || choice == .moveFinish
            body = .returned(date: date, choice: choice, basis: rescheduling ? try basis(needed: true) : nil)
        case "ended":
            body = .ended(date: try fields.required("date", .date, readDate))
        default:
            // The kinds left are the three marks.
            let mark = Mark(rawValue: kind)!
            body = .marked(
                Marked(
                    mark, assignment: try fields.required("assignment", .positive, readPositive),
                    date: try fields.required("date", .date, readDate),
                    appointed: try fields.optional("appointed", .date, readDate),
                    verses: mark == .partlyCompleted ? try fields.optional("verses", .verses, readVerses) : nil))
        }
    }

    /// The wire form: what a client stores and sends, and what `init(wire:)`
    /// reads back.
    public var wire: JSONValue {
        var fields: [String: JSONValue] = [
            "id": .string(id.rawValue), "kind": .string(kind), "enrollment": .string(enrollment.rawValue),
            "at": .string(at), "zone": .string(zone), "device": .string(device),
        ]
        func date(_ value: CivilDate?) -> JSONValue? { value.map { .string($0.description) } }
        func number(_ value: Int?) -> JSONValue? { value.map { .number(Double($0)) } }
        func days(_ value: [Int]?) -> JSONValue? { value.map { .array($0.map { .number(Double($0)) }) } }
        func reminder(_ value: Reminder?) -> JSONValue? {
            switch value {
            case .off: .string("off")
            case .at(let time): .string(time.description)
            case nil: nil
            }
        }
        switch body {
        case .enrolled(let enrolled):
            fields["plan"] = .string(enrolled.plan.rawValue)
            fields["version"] = number(enrolled.version)
            fields["behavior"] = .string(enrolled.behavior.rawValue)
            fields["start"] = date(enrolled.start)
            fields["readingDays"] = days(enrolled.readingDays)
            fields["finish"] = date(enrolled.finish)
            fields["limit"] = number(enrolled.limit)
            fields["reminder"] = reminder(enrolled.reminder)
        case .marked(let marked):
            fields["assignment"] = number(marked.assignment)
            fields["date"] = date(marked.date)
            fields["appointed"] = date(marked.appointed)
            fields["verses"] = marked.verses.map { .string($0) }
        case .undone(let target):
            fields["target"] = .string(target.rawValue)
        case .changed(let changed):
            fields["from"] = date(changed.from)
            fields["start"] = date(changed.start)
            fields["readingDays"] = days(changed.readingDays)
            fields["behavior"] = changed.behavior.map { .string($0.rawValue) }
            fields["finish"] = date(changed.basis?.finish)
            fields["limit"] = number(changed.limit)
            fields["remaining"] = number(changed.basis?.remaining)
            fields["reminder"] = reminder(changed.reminder)
        case .paused(let from):
            fields["from"] = date(from)
        case .resumed(let from, let basis):
            fields["from"] = date(from)
            fields["finish"] = date(basis?.finish)
            fields["remaining"] = number(basis?.remaining)
        case .returned(let day, let choice, let basis):
            fields["date"] = date(day)
            fields["choice"] = .string(choice.rawValue)
            fields["finish"] = date(basis?.finish)
            fields["remaining"] = number(basis?.remaining)
        case .ended(let day):
            fields["date"] = date(day)
        }
        return .object(fields)
    }

    /// Events from a JSON array of their wire forms. Every event is checked,
    /// in the order given, before any is folded.
    public static func events(wire data: Data) throws(JournalError) -> [JournalEvent] {
        guard let values = try? JSONDecoder().decode([JSONValue].self, from: data) else {
            throw .malformedEvent("the journal is not a JSON list of events")
        }
        return try events(wire: values)
    }

    public static func events(wire values: [JSONValue]) throws(JournalError) -> [JournalEvent] {
        var events: [JournalEvent] = []
        for (index, value) in values.enumerated() { events.append(try JournalEvent(wire: value, number: index + 1)) }
        return events
    }
}
