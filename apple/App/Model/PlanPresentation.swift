import Foundation
import ReadingData
import ReadingEngine

/// What a plan's page and its card in the list show, worked out from the
/// bundled catalog: the facts are the compiler's, the workload and the
/// sample week the engine's, and the words the String Catalog's. A plan's
/// own words (title, summary, limitations and the rest) are shown as the
/// catalog has them. The web's counterpart is
/// web/src/lib/server/catalog/present.ts.
struct PlanPresentation {
    let catalog: Catalog
    let plan: Plan

    var formatter: ReferenceFormatter {
        ReferenceFormatter(registry: catalog.registry, versification: catalog.versification)
    }

    var facts: Catalog.Facts? { catalog.facts[plan.id] }

    /// "By Day by Word".
    var byline: String { String(localized: "By \(plan.creator)") }

    /// "Read in order" or "By the date".
    var kind: String {
        plan.schedule == .sequence ? String(localized: "Read in order") : String(localized: "By the date")
    }

    /// "60 readings".
    var readings: String { Self.readings(plan.assignments.count) }

    static func readings(_ count: Int) -> String {
        count == 1 ? String(localized: "1 reading") : String(localized: "\(count) readings")
    }

    /// A typical reading's workload: "About 6–8 minutes. Estimates vary."
    var typicalWorkload: String {
        guard let facts else { return "" }
        return Self.workload(facts.workload.median.minutes, saying: true)
    }

    /// "About 9–11 minutes", with ". Estimates vary." when `saying`.
    static func workload(_ minutes: ClosedRange<Int>, saying vary: Bool = false) -> String {
        let (low, high) = (minutes.lowerBound, minutes.upperBound)
        if vary {
            if low != high { return String(localized: "About \(low)–\(high) minutes. Estimates vary.") }
            return low == 1
                ? String(localized: "About 1 minute. Estimates vary.")
                : String(localized: "About \(low) minutes. Estimates vary.")
        }
        if low != high { return String(localized: "About \(low)–\(high) minutes") }
        return low == 1 ? String(localized: "About 1 minute") : String(localized: "About \(low) minutes")
    }

    /// The lightest, the typical and the heaviest reading.
    var workloads: [(label: String, text: String)] {
        guard let facts else { return [] }
        return [
            (String(localized: "A typical reading"), Self.workload(facts.workload.median.minutes)),
            (String(localized: "The lightest reading"), Self.workload(facts.workload.minimum.minutes)),
            (String(localized: "The heaviest reading"), Self.workload(facts.workload.maximum.minutes)),
        ]
    }

    var paced: String {
        switch plan.readingDays {
        case 7: String(localized: "It is paced for every day of the week. You choose your own days.")
        case 1: String(localized: "It is paced for 1 reading day a week. You choose your own days.")
        default:
            String(localized: "It is paced for \(plan.readingDays) reading days a week. You choose your own days.")
        }
    }

    /// How long it takes at its own pace, or its cycle (BUILD.md P9.4):
    /// "60 readings: about 12 weeks at 5 readings a week."
    var length: String {
        guard plan.schedule == .sequence else {
            return String(localized: "A reading for each day of the month, begun again each month.")
        }
        let per =
            plan.readingDays == 1
            ? String(localized: "1 reading") : String(localized: "\(plan.readingDays) readings")
        let weeks = Choosing.weeks(readings: plan.assignments.count, perWeek: plan.readingDays)
        return weeks == 1
            ? String(localized: "\(readings): 1 week at \(per) a week.")
            : String(localized: "\(readings): about \(weeks) weeks at \(per) a week.")
    }

    /// Its permissions in plain words, by its rights entry.
    var permissions: String {
        switch plan.rights {
        case "daybyword-original":
            String(
                localized:
                    "Day by Word's own plan: free to follow, to print for your own use, and to share by its link.")
        default: String(localized: "Its permissions are recorded with its source.")
        }
    }

    // A Monday that is also the first of a month, so one start serves both
    // kinds of sample: a week from a Monday, and a month's first seven days.
    static let sampleStart = try! CivilDate("2001-01-01")

    /// The plan's sample week: the engine's days ahead for a reader who
    /// starts on `sampleStart` at the plan's own pace (docs/decisions.md E45).
    var sampleWeek: [(label: String, reference: ReferenceText?)] {
        week(from: Self.sampleStart).map { day in
            let label =
                plan.schedule == .sequence
                ? Self.weekdayName(day.date) : String(localized: "Day \(day.date.day)")
            return (label, day.references.first)
        }
    }

    var sampleNote: String {
        plan.schedule == .sequence
            ? String(
                localized:
                    "Its first week, begun on a Monday. Your own week depends on the day you start and the days you choose."
            )
            : String(localized: "The first seven days of a month. Each date has its own reading.")
    }

    /// The days ahead from `start` for a reader who begins that day with the
    /// plan's first behavior, on its own pace's first reading days.
    func week(from start: CivilDate) -> [(date: CivilDate, references: [ReferenceText])] {
        let enrolled = JournalEvent.Enrolled(
            plan: plan.id, version: plan.version, behavior: plan.behaviors[0], start: start,
            readingDays: Array(1...plan.readingDays))
        guard let enrollment = Self.candidate(enrolled, plan: catalog.version(of: plan)) else { return [] }
        let readings = Dictionary(plan.assignments.map { ($0.id, $0.reading) }, uniquingKeysWith: { first, _ in first })
        let formatter = formatter
        return enrollment.comingDays(from: start, count: 7).map { day in
            (
                day.date,
                day.readings.compactMap { readings[$0.assignment].map { ReferenceText($0, formatter: formatter) } }
            )
        }
    }

    /// The enrollment a candidate `enrolled` event would make, for a preview.
    static func candidate(_ enrolled: JournalEvent.Enrolled, plan: PlanVersion) -> Enrollment? {
        let zeros = [UInt8](repeating: 0, count: 10)
        let event = JournalEvent(
            id: EventID(milliseconds: 1, random: zeros)!, enrollment: EventID(milliseconds: 0, random: zeros)!,
            at: "2001-01-01T00:00:00Z", zone: "UTC", device: "preview", body: .enrolled(enrolled))
        return (try? Journal(events: [event], plans: [plan]))?.enrollments.first
    }

    /// What the plan covers, as the compiler computed it.
    var covers: [String] {
        guard let facts else { return [] }
        let verses = facts.uniqueVerses.formatted()
        var lines: [String] = []
        switch plan.coverage {
        case .wholeBible:
            let label = catalog.registry.canon(plan.canon)?.label ?? ""
            let canon = Self.canonName(plan.canon)
            lines.append(String(localized: "Every verse of the \(label) of the \(canon) canon: \(verses) verses."))
        case .books:
            lines.append(String(localized: "Every verse of \(bookList): \(verses) verses."))
        case .selection:
            lines.append(
                String(localized: "Passages from \(bookList): \(verses) verses. It does not read these books whole."))
        }
        if facts.repeats.isEmpty {
            lines.append(String(localized: "No verse is read twice."))
        } else {
            let passages = facts.repeats.map { formatter.string(for: $0) }.formatted(.list(type: .and))
            lines.append(String(localized: "It reads these verses more than once: \(passages)."))
        }
        if plan.coverage != .wholeBible {
            lines.append(
                String(
                    localized:
                        "Finishing a plan is not the same as reading the whole Bible, unless its readings cover it."))
        }
        return lines
    }

    private var bookList: String {
        plan.books.map { catalog.registry.book($0)?.commonName.name ?? $0.rawValue }.formatted(.list(type: .and))
    }

    static func canonName(_ id: String) -> String {
        switch id {
        case "protestant": String(localized: "Protestant")
        case "catholic": String(localized: "Catholic")
        default: id
        }
    }

    var how: String {
        plan.schedule == .sequence
            ? String(localized: "Its readings are numbered and read in order.")
            : String(localized: "Each day of the month has its own reading.")
    }

    var review: String {
        switch plan.review {
        case .checked: String(localized: "Checked automatically: every reference and claim.")
        case .reviewed:
            String(localized: "Reviewed: checked against its own rules and Day by Word's criteria for plans.")
        case .expert: String(localized: "Reviewed by a reader who uses its source.")
        }
    }

    // MARK: - Words shared by several screens

    static func weekdayName(_ date: CivilDate) -> String {
        weekdayName(date.weekday)
    }

    /// The weekday's name, from ISO 8601's number (1 is Monday).
    static func weekdayName(_ number: Int) -> String {
        switch number {
        case 1: String(localized: "Monday")
        case 2: String(localized: "Tuesday")
        case 3: String(localized: "Wednesday")
        case 4: String(localized: "Thursday")
        case 5: String(localized: "Friday")
        case 6: String(localized: "Saturday")
        default: String(localized: "Sunday")
        }
    }

    /// "Wednesday 6 January", in the reader's own calendar format.
    static func dayText(_ date: CivilDate) -> String {
        date.start(in: .current).formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}

extension Plan.Behavior {
    var name: String {
        switch self {
        case .pace: String(localized: "Continue at my pace")
        case .finishDate: String(localized: "Work toward a finish date")
        case .calendar: String(localized: "Follow the calendar")
        }
    }

    var about: String {
        switch self {
        case .pace:
            String(
                localized:
                    "Read the next reading whenever you read. If you miss a day, nothing is lost: your next reading waits for you, and your finish date moves."
            )
        case .finishDate:
            String(
                localized:
                    "Choose when you'd like to finish. If you miss days, Day by Word can spread the unread readings over the days ahead, up to a limit you set, or move your finish date. You'll see the change before it happens."
            )
        case .calendar:
            String(
                localized:
                    "Read the readings appointed for each date. Today's readings stay on today, as the calendar sets them. Readings from earlier dates stay in your history, and you can read them whenever you like."
            )
        }
    }
}

extension Catalog {
    /// The plans as the list shows them: the shortest first, then by title,
    /// until P9.3 groups them by goal (docs/decisions.md E45).
    var listed: [Plan] {
        plans.sorted {
            ($0.assignments.count, $0.title) < ($1.assignments.count, $1.title)
        }
    }
}
