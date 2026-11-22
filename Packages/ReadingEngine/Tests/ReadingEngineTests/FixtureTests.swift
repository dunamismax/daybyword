import Foundation
import ReadingEngine
import Testing

// The shared fixtures in the repository's tests/fixtures/ (its README): inputs,
// and the outputs this Swift code gives for them, which the TypeScript web
// module must give too (docs/decisions.md E33). Set DBW_RECORD_FIXTURES=1 to
// rewrite the outputs from the code, then review the diff before committing.

/// The repository's `tests/fixtures/`.
let fixturesURL = registryURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appending(path: "tests/fixtures", directoryHint: .isDirectory)

/// An invented plan version in a scheduling fixture's `plans`: enough to
/// enroll in and mark, with readings in the plan-file format.
struct FixturePlan: Codable, Sendable {
    struct Assignment: Codable, Sendable {
        var id: Int
        var reading: String
    }

    var id: String
    var version: Int
    var schedule: String
    var behaviors: [String]
    var readingDays: Int
    var assignments: [Assignment]

    /// The plan as the engine takes it, with each reading's words from the
    /// counts given.
    func planVersion(in versification: Versification, counts: WordCounts? = nil) throws -> PlanVersion {
        let assignments = try assignments.map {
            Plan.Assignment(id: $0.id, reading: try ReferenceFormat.reading($0.reading, in: versification))
        }
        var words: [Int: Int] = [:]
        for assignment in assignments { words[assignment.id] = counts?.words(in: assignment.reading) }
        return PlanVersion(
            id: try #require(PlanID(id)), version: version, schedule: try #require(Plan.Schedule(rawValue: schedule)),
            behaviors: try behaviors.map { try #require(Plan.Behavior(rawValue: $0)) }, readingDays: readingDays,
            assignments: assignments, words: words)
    }
}

struct FixtureFile<Input: Codable & Sendable, Output: Codable & Equatable & Sendable>: Codable, Sendable {
    struct Case: Codable, Sendable {
        /// What the case shows, in the scheduling fixtures.
        var name: String?
        var input: Input
        var output: Output?
    }

    var fixture: String
    var version: Int
    var about: String
    /// The invented plans a scheduling fixture's cases enroll in.
    var plans: [FixturePlan]?
    var cases: [Case]
}

/// Checks each case of `tests/fixtures/<name>.json` against `compute`, or
/// records `compute`'s outputs into the file.
func checkFixture<Input: Codable & Sendable, Output: Codable & Equatable & Sendable>(
    _ name: String, sourceLocation: SourceLocation = #_sourceLocation, _ compute: (Input) throws -> Output
) throws {
    try checkFixture(name, sourceLocation: sourceLocation) { input, _ in try compute(input) }
}

/// The same, for a scheduling fixture: `compute` is also given the file's
/// invented plans.
func checkFixture<Input: Codable & Sendable, Output: Codable & Equatable & Sendable>(
    _ name: String, sourceLocation: SourceLocation = #_sourceLocation,
    _ compute: (Input, [PlanVersion]) throws -> Output
) throws {
    let url = fixturesURL.appending(path: "\(name).json")
    var file = try JSONDecoder().decode(FixtureFile<Input, Output>.self, from: Data(contentsOf: url))
    #expect(file.fixture == name, sourceLocation: sourceLocation)
    let (english, counts) = (try loadEnglish(), try loadWordCounts())
    let plans = try (file.plans ?? []).map { try $0.planVersion(in: english, counts: counts) }
    if ProcessInfo.processInfo.environment["DBW_RECORD_FIXTURES"] != nil {
        for index in file.cases.indices { file.cases[index].output = try compute(file.cases[index].input, plans) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try (encoder.encode(file) + Data("\n".utf8)).write(to: url, options: .atomic)
        return
    }
    #expect(!file.cases.isEmpty, sourceLocation: sourceLocation)
    for (index, testCase) in file.cases.enumerated() {
        let output = try compute(testCase.input, plans)
        #expect(
            testCase.output == output, "\(name) case \(index) \(testCase.name ?? ""): \(testCase.input)",
            sourceLocation: sourceLocation)
    }
}

// MARK: References

struct ReferenceOutput: Codable, Equatable, Sendable {
    struct Range: Codable, Equatable, Sendable {
        var book: String
        var start: String
        var end: String
    }

    struct Display: Codable, Equatable, Sendable {
        var full: String
        var abbreviated: String
    }

    var text: String?
    var passages: [Range]?
    var verses: Int?
    /// Absent when a book has no word counts.
    var words: Int?
    var minutes: [Int]?
    var display: [String: Display]?
    var error: String?
    var message: String?
}

func errorKind(_ error: ReferenceFormatError) -> String {
    switch error {
    case .empty: "empty"
    case .malformed: "malformed"
    case .notABook: "notABook"
    case .redundant: "redundant"
    case .passage(let error):
        switch error {
        case .unknownBook: "unknownBook"
        case .noSuchChapter: "noSuchChapter"
        case .noSuchVerse: "noSuchVerse"
        case .endsBeforeItStarts: "endsBeforeItStarts"
        case .emptyReading: "emptyReading"
        case .mixedSchemes: "mixedSchemes"
        }
    }
}

@Test func referencesMatchTheirFixture() throws {
    let (registry, english, counts) = (try loadRegistry(), try loadEnglish(), try loadWordCounts())
    try checkFixture("references") { (text: String) -> ReferenceOutput in
        let reading: Reading
        do throws(ReferenceFormatError) {
            reading = try ReferenceFormat.reading(text, in: english)
        } catch {
            return ReferenceOutput(error: errorKind(error), message: error.description)
        }
        let words = counts.words(in: reading)
        var display: [String: ReferenceOutput.Display] = [:]
        for convention in NamingConvention.allCases {
            let formatter = ReferenceFormatter(registry: registry, versification: english, convention: convention)
            display[convention.rawValue] = .init(
                full: formatter.string(for: reading), abbreviated: formatter.string(for: reading, style: .abbreviated))
        }
        return ReferenceOutput(
            text: ReferenceFormat.text(of: reading, in: english),
            passages: reading.passages.map { .init(book: $0.book.rawValue, start: "\($0.start)", end: "\($0.end)") },
            verses: reading.verseCount(in: english), words: words,
            minutes: words.map { Workload(words: $0).minutes }.map { [$0.lowerBound, $0.upperBound] },
            display: display)
    }
}

@Test func planIDsMatchTheirFixture() throws {
    try checkFixture("plan-ids") { (text: String) -> Bool in PlanID(text) != nil }
}

// MARK: Coverage

struct CoverageOutput: Codable, Equatable, Sendable {
    var verses: Int
    var uniqueVerses: Int
    var repeats: [String]
    var wholeChapters: Int
    var partialChapters: Int
    /// Unique verses by book.
    var books: [String: Int]
}

@Test func coverageMatchesItsFixture() throws {
    let english = try loadEnglish()
    try checkFixture("coverage") { (texts: [String]) -> CoverageOutput in
        let readings = try texts.map { try ReferenceFormat.reading($0, in: english) }
        let passages = readings.flatMap(\.passages)
        let covered = VerseSet(passages, in: english)
        let chapters = covered.chapters(in: english)
        return CoverageOutput(
            verses: readings.reduce(0) { $0 + $1.verseCount(in: english) }, uniqueVerses: covered.count,
            repeats: VerseSet.repeats(in: passages, in: english).passages(in: english).map {
                ReferenceFormat.text(of: $0, in: english)
            },
            wholeChapters: chapters.count(where: \.isWhole), partialChapters: chapters.count(where: { !$0.isWhole }),
            books: Dictionary(uniqueKeysWithValues: covered.books.map { ($0.rawValue, covered.count(in: $0)) }))
    }
}

// MARK: Workload

struct WorkloadOutput: Codable, Equatable, Sendable {
    var silentMinutes: Double
    var aloudMinutes: Double
    var minutes: [Int]
}

@Test func workloadsMatchTheirFixture() throws {
    try checkFixture("workload") { (words: Int) -> WorkloadOutput in
        let workload = Workload(words: words)
        return WorkloadOutput(
            silentMinutes: workload.silentMinutes, aloudMinutes: workload.aloudMinutes,
            minutes: [workload.minutes.lowerBound, workload.minutes.upperBound])
    }
}

struct PlanWorkloadOutput: Codable, Equatable, Sendable {
    /// Words of the lightest, middle, and heaviest readings; absent for a plan
    /// with no readings.
    var minimum: Int?
    var median: Int?
    var maximum: Int?
}

@Test func planWorkloadsMatchTheirFixture() throws {
    try checkFixture("plan-workload") { (words: [Int]) -> PlanWorkloadOutput in
        guard let workload = PlanWorkload(words: words) else { return PlanWorkloadOutput() }
        return PlanWorkloadOutput(
            minimum: workload.minimum.words, median: workload.median.words, maximum: workload.maximum.words)
    }
}

// MARK: Scripture

struct ScriptureOutput: Codable, Equatable, Sendable {
    struct Book: Codable, Equatable, Sendable {
        var id: String
        var testament: String
        /// The first and last chapter the scheme numbers; absent for a book
        /// it does not number.
        var chapters: [Int]?
        var verses: Int?
        var words: Int?
        var names: [String: BookRegistry.BookName]
    }

    struct Canon: Codable, Equatable, Sendable {
        var id: String
        var books: [String]
        var orders: [String: Int]
        var chapters: Int
        var verses: Int
        /// Absent unless every book of the canon is counted.
        var words: Int?
    }

    var books: [Book]
    var canons: [Canon]
}

@Test func scriptureMatchesItsFixture() throws {
    let (registry, english, counts) = (try loadRegistry(), try loadEnglish(), try loadWordCounts())
    try checkFixture("scripture") { (scheme: String) -> ScriptureOutput in
        try #require(scheme == english.scheme.rawValue)
        let books = registry.books.map { book in
            ScriptureOutput.Book(
                id: book.id.rawValue, testament: book.testament.rawValue,
                chapters: english.chapters(of: book.id).map { [$0.lowerBound, $0.upperBound] },
                verses: english.chapters(of: book.id) == nil ? nil : english.verseCount(of: book.id),
                words: counts.words(of: book.id),
                names: Dictionary(
                    uniqueKeysWithValues: NamingConvention.allCases.map { ($0.rawValue, book.name(in: $0)) }))
        }
        let canons = registry.canons.map { canon in
            let numbered = canon.books.filter { english.chapters(of: $0) != nil }
            let words = canon.books.map { counts.words(of: $0) }
            return ScriptureOutput.Canon(
                id: canon.id, books: canon.books.map(\.rawValue),
                orders: Dictionary(uniqueKeysWithValues: canon.orders.map { ($0.id, $0.books.count) }),
                chapters: numbered.reduce(0) { $0 + english.chapters(of: $1)!.count },
                verses: numbered.reduce(0) { $0 + english.verseCount(of: $1) },
                words: words.contains(nil) ? nil : words.reduce(0) { $0 + $1! })
        }
        return ScriptureOutput(books: books, canons: canons)
    }
}

// MARK: Scripture files

struct ScriptureFileInput: Codable, Sendable {
    /// `registry`, `versification` (English), or `word-counts` (read against
    /// the repository's English scheme).
    var file: String
    var text: String
}

struct ScriptureFileOutput: Codable, Equatable, Sendable {
    /// The books the file registers, numbers, or counts, in its order.
    var books: [String]?
    var canons: [String]?
    var verses: Int?
    var words: Int?
    var error: String?
    /// Absent for an unreadable registry, whose detail is each runtime's own.
    var message: String?
}

func errorKind(_ error: BookRegistryError) -> String {
    switch error {
    case .unreadable: "unreadable"
    case .unsupportedFormat: "unsupportedFormat"
    case .duplicateConvention: "duplicateConvention"
    case .missingConvention: "missingConvention"
    case .duplicateBook: "duplicateBook"
    case .emptyName: "emptyName"
    case .redundantName: "redundantName"
    case .duplicateName: "duplicateName"
    case .duplicateAbbreviation: "duplicateAbbreviation"
    case .duplicateCanon: "duplicateCanon"
    case .duplicateOrder: "duplicateOrder"
    case .canonWithoutOrder: "canonWithoutOrder"
    case .unknownBook: "unknownBook"
    case .repeatedBook: "repeatedBook"
    case .ordersDisagree: "ordersDisagree"
    case .testamentsMixed: "testamentsMixed"
    case .includedTwice: "includedTwice"
    case .unsourcedIncludes: "unsourcedIncludes"
    case .bookInNoCanon: "bookInNoCanon"
    case .duplicateSource: "duplicateSource"
    case .unknownSource: "unknownSource"
    case .unusedSource: "unusedSource"
    }
}

func errorKind(_ error: VersificationError) -> String {
    switch error {
    case .malformedLine: "malformedLine"
    case .duplicateBook: "duplicateBook"
    case .unregisteredBook: "unregisteredBook"
    case .missingBook: "missingBook"
    }
}

func errorKind(_ error: WordCountsError) -> String {
    switch error {
    case .malformedLine: "malformedLine"
    case .noSuchChapter: "noSuchChapter"
    case .wrongVerseCount: "wrongVerseCount"
    case .duplicateChapter: "duplicateChapter"
    case .missingChapter: "missingChapter"
    }
}

@Test func scriptureFilesMatchTheirFixture() throws {
    let english = try loadEnglish()
    try checkFixture("scripture-files") { (input: ScriptureFileInput) -> ScriptureFileOutput in
        switch input.file {
        case "registry":
            do {
                let registry = try BookRegistry(json: Data(input.text.utf8))
                return ScriptureFileOutput(
                    books: registry.books.map(\.id.rawValue), canons: registry.canons.map(\.id))
            } catch let error as BookRegistryError {
                if case .unreadable = error { return ScriptureFileOutput(error: errorKind(error)) }
                return ScriptureFileOutput(error: errorKind(error), message: error.description)
            }
        case "versification":
            do {
                let scheme = try Versification(scheme: .english, tsv: input.text)
                let verses = scheme.books.reduce(0) { $0 + scheme.verseCount(of: $1) }
                return ScriptureFileOutput(books: scheme.books.map(\.rawValue), verses: verses)
            } catch let error as VersificationError {
                return ScriptureFileOutput(error: errorKind(error), message: error.description)
            }
        default:
            try #require(input.file == "word-counts")
            do throws(WordCountsError) {
                let counts = try WordCounts(tsv: input.text, versification: english)
                let words = counts.books.reduce(0) { $0 + counts.words(of: $1)! }
                return ScriptureFileOutput(books: counts.books.map(\.rawValue), words: words)
            } catch {
                return ScriptureFileOutput(error: errorKind(error), message: error.description)
            }
        }
    }
}

// MARK: Civil dates

struct CivilDateInput: Codable, Sendable {
    var text: String
    /// Days to add, when the case asks for a sum.
    var add: Int?
    /// Another date to count the days to.
    var to: String?
}

struct CivilDateOutput: Codable, Equatable, Sendable {
    var date: String?
    var weekday: Int?
    var daysInMonth: Int?
    var dayOfYear: Int?
    var leapYear: Bool?
    var ordinal: Int?
    /// The date `add` days later, or why there is none.
    var sum: String?
    var sumError: String?
    /// The whole days to `to`, or why it is not a date.
    var daysTo: Int?
    var toError: String?
    var error: String?
    var message: String?
}

@Test func civilDatesMatchTheirFixture() throws {
    try checkFixture("civil-dates") { (input: CivilDateInput) -> CivilDateOutput in
        let date: CivilDate
        do throws(CivilDateError) {
            date = try CivilDate(input.text)
        } catch {
            return CivilDateOutput(error: error.kind, message: error.description)
        }
        var output = CivilDateOutput(
            date: date.description, weekday: date.weekday, daysInMonth: date.daysInMonth, dayOfYear: date.dayOfYear,
            leapYear: CivilDate.isLeapYear(date.year), ordinal: date.ordinal)
        if let days = input.add {
            do throws(CivilDateError) {
                output.sum = try date.adding(days: days).description
            } catch {
                output.sumError = error.kind
            }
        }
        if let other = input.to {
            do throws(CivilDateError) {
                output.daysTo = date.days(to: try CivilDate(other))
            } catch {
                output.toError = error.kind
            }
        }
        return output
    }
}

// MARK: Event ids

struct EventIDInput: Codable, Sendable {
    /// Text that may be an id.
    var text: String?
    /// Or the millisecond count and random bytes to make one from.
    var milliseconds: Double?
    var random: [Int]?
}

struct EventIDOutput: Codable, Equatable, Sendable {
    /// Whether the text is an id.
    var valid: Bool?
    /// The id made, or the milliseconds the id was made at.
    var id: String?
    var milliseconds: Int?
}

@Test func eventIDsMatchTheirFixture() throws {
    try checkFixture("event-ids") { (input: EventIDInput) -> EventIDOutput in
        if let text = input.text {
            let id = EventID(text)
            return EventIDOutput(valid: id != nil, milliseconds: id?.milliseconds)
        }
        // A count or byte that is not a whole number in range makes no id.
        guard let milliseconds = Int(exactly: try #require(input.milliseconds)),
            let random = try #require(input.random).reduce(
                into: [UInt8]?([]),
                { bytes, byte in
                    if let value = UInt8(exactly: byte) { bytes?.append(value) } else { bytes = nil }
                }), let id = EventID(milliseconds: milliseconds, random: random)
        else { return EventIDOutput() }
        return EventIDOutput(id: id.rawValue, milliseconds: id.milliseconds)
    }
}

// MARK: The journal

struct JournalInput: Codable, Sendable {
    /// Events in their wire form, in the order they arrived.
    var events: [JSONValue]
    /// Dates to give the arrangement on.
    var on: [String]?
}

struct JournalOutput: Codable, Equatable, Sendable {
    struct Inert: Codable, Equatable, Sendable {
        var event: String
        var reason: String
    }

    struct Slot: Codable, Equatable, Sendable {
        var assignment: Int
        var appointed: String?
        var state: String
        var date: String
        var event: String
        var verses: String?
    }

    struct Pause: Codable, Equatable, Sendable {
        var from: String
        var until: String?
    }

    struct Arrangement: Codable, Equatable, Sendable {
        var date: String
        var behavior: String
        var readingDays: [Int]
        var limit: Int?
        var reminder: String?
        var paused: Bool
    }

    struct Enrollment: Codable, Equatable, Sendable {
        var id: String
        var plan: String
        var version: Int
        var start: String
        var ended: String?
        var slots: [Slot]
        var paused: [Pause]
        var on: [Arrangement]?
    }

    /// The distinct events.
    var events: Int?
    var inert: [Inert]?
    /// The events an active undo has taken back, in journal order.
    var undone: [String]?
    var enrollments: [Enrollment]?
    var error: String?
    var message: String?
}

@Test func theJournalMatchesItsFixture() throws {
    try checkFixture("journal") { (input: JournalInput, plans: [PlanVersion]) -> JournalOutput in
        let journal: Journal
        do throws(JournalError) {
            journal = try Journal(wire: input.events, plans: plans)
        } catch {
            return JournalOutput(error: error.kind, message: error.description)
        }
        let dates = try (input.on ?? []).map { try CivilDate($0) }
        let inert = Set(journal.inert.map(\.event))
        return JournalOutput(
            events: journal.events.count,
            inert: journal.inert.map { .init(event: $0.event.rawValue, reason: $0.reason.rawValue) },
            undone: journal.events.map(\.id).filter { !inert.contains($0) && !journal.isActive($0) }.map(\.rawValue),
            enrollments: journal.enrollments.map { enrollment in
                JournalOutput.Enrollment(
                    id: enrollment.id.rawValue, plan: enrollment.plan.id.rawValue, version: enrollment.plan.version,
                    start: enrollment.start.description, ended: enrollment.ended?.description,
                    slots: enrollment.settled.map {
                        .init(
                            assignment: $0.slot.assignment, appointed: $0.slot.appointed?.description,
                            state: $0.state.rawValue, date: $0.date.description, event: $0.event.rawValue,
                            verses: $0.verses)
                    },
                    paused: enrollment.pauses.map { .init(from: $0.from.description, until: $0.until?.description) },
                    on: dates.isEmpty
                        ? nil
                        : dates.map { date in
                            let arrangement = enrollment.arrangement(on: date)
                            return .init(
                                date: date.description, behavior: arrangement.behavior.rawValue,
                                readingDays: arrangement.readingDays, limit: arrangement.limit,
                                reminder: arrangement.reminder?.description, paused: enrollment.isPaused(date))
                        })
            })
    }
}

// MARK: Today

struct TodayInput: Codable, Sendable {
    var events: [JSONValue]
    var today: String
}

struct TodayOutput: Codable, Equatable, Sendable {
    struct Place: Codable, Equatable, Sendable {
        var assignment: Int
        /// Its place in reading order, which the reader sees.
        var position: Int
        var appointed: String?

        init(_ slot: Slot, in plan: PlanVersion) {
            assignment = slot.assignment
            position = plan.positions[slot.assignment] ?? 0
            appointed = slot.appointed?.description
        }
    }

    struct Projection: Codable, Equatable, Sendable {
        var plan: String?
        var recent: String?
        var unbroken: String?
    }

    struct Schedule: Codable, Equatable, Sendable {
        var first: String
        var finish: String
        var remaining: Int
        var scheduledDays: Int
        var least: Int
        var most: Int
        var heaviestWords: Int?
        var outstanding: Int
        var share: Int
        var limit: Int?
        var finishWithinLimit: String?
    }

    struct Calendar: Codable, Equatable, Sendable {
        var appointment: Place
        var state: String
        var notAppointed: [Int]
        var missed: Int
    }

    struct Enrollment: Codable, Equatable, Sendable {
        var id: String
        var status: String
        var readingDay: Bool
        var readings: [Place]
        var readToday: [Place]
        var next: Place?
        var projection: Projection?
        var schedule: Schedule?
        var calendar: Calendar?
    }

    var enrollments: [Enrollment]
}

@Test func todayMatchesItsFixture() throws {
    try checkFixture("today") { (input: TodayInput, plans: [PlanVersion]) -> TodayOutput in
        let journal = try Journal(wire: input.events, plans: plans)
        let date = try CivilDate(input.today)
        return TodayOutput(
            enrollments: journal.enrollments.map { enrollment in
                let today = enrollment.today(date)
                let plan = enrollment.plan
                return TodayOutput.Enrollment(
                    id: enrollment.id.rawValue, status: today.status.rawValue, readingDay: today.isReadingDay,
                    readings: today.readings.map { .init($0, in: plan) },
                    readToday: today.readToday.map { .init($0, in: plan) },
                    next: today.next.map { .init($0, in: plan) },
                    projection: today.projection.map {
                        .init(
                            plan: $0.plan?.description, recent: $0.recent?.description,
                            unbroken: $0.unbroken?.description)
                    },
                    schedule: today.schedule.map {
                        .init(
                            first: $0.first.description, finish: $0.finish.description, remaining: $0.remaining,
                            scheduledDays: $0.scheduledDays, least: $0.least, most: $0.most,
                            heaviestWords: $0.heaviestWords, outstanding: $0.outstanding, share: $0.share,
                            limit: $0.limit, finishWithinLimit: $0.finishWithinLimit?.description)
                    },
                    calendar: today.calendar.map {
                        .init(
                            appointment: .init($0.appointment, in: plan), state: $0.state.rawValue,
                            notAppointed: $0.notAppointed, missed: $0.missed)
                    })
            })
    }
}

// MARK: Returning

struct ReturningOutput: Codable, Equatable, Sendable {
    /// Today's answer were a choice recorded.
    struct Preview: Codable, Equatable, Sendable {
        var status: String
        /// The readings to read, by their place in reading order.
        var readings: [Int]
        /// The projected finish at the plan's pace, or the scheduled finish.
        var finish: String?
        /// The most readings on a day under the schedule.
        var most: Int?
        /// Whether the welcome would still be offered.
        var welcome: Bool
    }

    struct Choice: Codable, Equatable, Sendable {
        var choice: String
        var finish: String?
        var remaining: Int?
        var most: Int?
        var preview: Preview
    }

    struct Enrollment: Codable, Equatable, Sendable {
        var id: String
        var welcome: Bool
        var choices: [Choice]?
        var spreadNeeds: Int?
    }

    var enrollments: [Enrollment]
}

@Test func returningMatchesItsFixture() throws {
    try checkFixture("returning") { (input: TodayInput, plans: [PlanVersion]) -> ReturningOutput in
        let journal = try Journal(wire: input.events, plans: plans)
        let date = try CivilDate(input.today)
        return ReturningOutput(
            enrollments: try journal.enrollments.map { enrollment in
                guard let welcome = enrollment.welcome(on: date) else {
                    return ReturningOutput.Enrollment(id: enrollment.id.rawValue, welcome: false)
                }
                let choices = try welcome.offers.map { offer in
                    let previewed = try #require(journal.previewing(welcome.answer(offer, on: date), in: enrollment.id))
                    #expect(previewed.inert == journal.inert)
                    let after = try #require(previewed.enrollments.first { $0.id == enrollment.id })
                    let today = after.today(date)
                    return ReturningOutput.Choice(
                        choice: offer.choice.rawValue, finish: offer.basis?.finish.description,
                        remaining: offer.basis?.remaining, most: offer.most,
                        preview: .init(
                            status: today.status.rawValue,
                            readings: today.readings.map { after.plan.positions[$0.assignment] ?? 0 },
                            finish: (today.schedule?.finish ?? today.projection?.plan)?.description,
                            most: today.schedule?.most, welcome: after.welcome(on: date) != nil))
                }
                return ReturningOutput.Enrollment(
                    id: enrollment.id.rawValue, welcome: true, choices: choices, spreadNeeds: welcome.spreadNeeds)
            })
    }
}

// MARK: Changing

struct ChangingInput: Codable, Sendable {
    struct Change: Codable, Sendable {
        var from: String
        var start: String?
        var readingDays: [Int]?
        var behavior: String?
        var finish: String?
        var limit: Int?
        var reminder: String?
    }

    var events: [JSONValue]
    var today: String
    var change: Change
}

struct ChangingOutput: Codable, Equatable, Sendable {
    /// What an enrollment's day comes to, for comparing before and after.
    struct Day: Codable, Equatable, Sendable {
        var status: String
        var readings: [Int]
        var finish: String?
        var most: Int?
        var finishWithinLimit: String?
        var start: String
        var readingDay: Bool
        var settled: Int

        init(_ enrollment: Enrollment, on date: CivilDate) {
            let today = enrollment.today(date)
            status = today.status.rawValue
            readings = today.readings.map { enrollment.plan.positions[$0.assignment] ?? 0 }
            finish = (today.schedule?.finish ?? today.projection?.plan)?.description
            most = today.schedule?.most
            finishWithinLimit = today.schedule?.finishWithinLimit?.description
            start = enrollment.start.description
            readingDay = today.isReadingDay
            settled = enrollment.settled.count
        }
    }

    /// The candidate event's own fields.
    var event: [String: JSONValue]
    var inert: String?
    var before: Day
    var after: Day
}

@Test func changingMatchesItsFixture() throws {
    try checkFixture("changing") { (input: ChangingInput, plans: [PlanVersion]) -> ChangingOutput in
        let journal = try Journal(wire: input.events, plans: plans)
        let date = try CivilDate(input.today)
        let enrollment = try #require(journal.enrollments.first)
        let change = input.change
        var reminder: JournalEvent.Reminder?
        if let text = change.reminder { reminder = text == "off" ? .off : .at(try #require(WallTime(text))) }
        let changed = enrollment.change(
            from: try CivilDate(change.from), start: try change.start.map { try CivilDate($0) },
            readingDays: change.readingDays,
            behavior: try change.behavior.map { try #require(Plan.Behavior(rawValue: $0)) },
            finish: try change.finish.map { try CivilDate($0) }, limit: change.limit, reminder: reminder)
        let previewed = try #require(journal.previewing(.changed(changed), in: enrollment.id))
        let candidate = try #require(previewed.events.last)
        guard case .object(var fields) = candidate.wire else { throw JournalError.malformedEvent("not an object") }
        for name in ["id", "enrollment", "at", "zone", "device"] { fields[name] = nil }
        // The candidate reads back from its wire form as the event it is.
        #expect(try JournalEvent(wire: candidate.wire) == candidate)
        return ChangingOutput(
            event: fields, inert: previewed.inert.first { $0.event == candidate.id }?.reason.rawValue,
            before: .init(enrollment, on: date),
            after: .init(try #require(previewed.enrollments.first), on: date))
    }
}

// MARK: Progress

struct ProgressOutput: Codable, Equatable, Sendable {
    struct Enrollment: Codable, Equatable, Sendable {
        var id: String
        var read: Int
        var partlyRead: Int
        var skipped: Int
        var unread: Int
        var total: Int
    }

    struct Day: Codable, Equatable, Sendable {
        var date: String
        var read: Bool
        var readingDay: Bool
    }

    struct Book: Codable, Equatable, Sendable {
        var book: String
        /// The verses read, of the verses the book has.
        var verses: Int
        var of: Int
        var wholeChapters: Int
        var partialChapters: Int
    }

    struct Coverage: Codable, Equatable, Sendable {
        var verses: Int
        /// The verses read as the fewest passages, in the plan-file format.
        var passages: [String]
        var wholeChapters: Int
        var partialChapters: Int
        /// The books explored, in the scheme's order.
        var books: [Book]
    }

    var enrollments: [Enrollment]
    /// The seven dates ending today.
    var recent: [Day]
    var coverage: Coverage
    var streak: Int
}

@Test func progressMatchesItsFixture() throws {
    let english = try loadEnglish()
    try checkFixture("progress") { (input: TodayInput, plans: [PlanVersion]) -> ProgressOutput in
        let journal = try Journal(wire: input.events, plans: plans)
        let date = try CivilDate(input.today)
        let coverage = journal.coverage(in: english)
        return ProgressOutput(
            enrollments: journal.enrollments.map {
                let counts = $0.counts(on: date)
                #expect(counts.read + counts.partlyRead + counts.skipped + counts.unread == counts.total)
                return .init(
                    id: $0.id.rawValue, read: counts.read, partlyRead: counts.partlyRead, skipped: counts.skipped,
                    unread: counts.unread, total: counts.total)
            },
            recent: journal.recentDays(ending: date).map {
                .init(date: $0.date.description, read: $0.isRead, readingDay: $0.isReadingDay)
            },
            coverage: .init(
                verses: coverage.verses.count,
                passages: coverage.verses.passages(in: english).map { ReferenceFormat.text(of: $0, in: english) },
                wholeChapters: coverage.chapters.count(where: \.isWhole),
                partialChapters: coverage.chapters.count(where: { !$0.isWhole }),
                books: coverage.books.map { book in
                    let chapters = coverage.chapters.filter { $0.book == book }
                    return .init(
                        book: book.rawValue, verses: coverage.verses.count(in: book), of: english.verseCount(of: book),
                        wholeChapters: chapters.count(where: \.isWhole),
                        partialChapters: chapters.count(where: { !$0.isWhole }))
                }),
            streak: journal.streak(on: date))
    }
}

// MARK: Celebrations

struct CelebrationsOutput: Codable, Equatable, Sendable {
    struct Celebration: Codable, Equatable, Sendable {
        var kind: String
        /// Absent for the week's rhythm.
        var enrollment: String?
        /// The book finished, for `finishedBook`.
        var book: String?
    }

    var celebrations: [Celebration]
}

@Test func celebrationsMatchTheirFixture() throws {
    let english = try loadEnglish()
    try checkFixture("celebrations") { (input: TodayInput, plans: [PlanVersion]) -> CelebrationsOutput in
        let journal = try Journal(wire: input.events, plans: plans)
        let date = try CivilDate(input.today)
        return CelebrationsOutput(
            celebrations: journal.celebrations(on: date, in: english).map {
                switch $0 {
                case .returned(let enrollment): .init(kind: "returned", enrollment: enrollment.rawValue)
                case .finishedBook(let book, let enrollment):
                    .init(kind: "finishedBook", enrollment: enrollment.rawValue, book: book.rawValue)
                case .finishedPlan(let enrollment): .init(kind: "finishedPlan", enrollment: enrollment.rawValue)
                case .keptRhythm: .init(kind: "keptRhythm")
                }
            })
    }
}

// MARK: Reminders

struct RemindersInput: Codable, Sendable {
    struct Quiet: Codable, Sendable {
        var from: String
        var until: String
    }

    struct Snooze: Codable, Sendable {
        var enrollment: String
        var date: String
        var time: String
    }

    var events: [JSONValue]
    /// The local date and wall-clock time now.
    var today: String
    var time: String
    var quiet: Quiet?
    var most: Int?
    var window: Int?
    var snoozes: [Snooze]?
}

struct RemindersOutput: Codable, Equatable, Sendable {
    struct Reminder: Codable, Equatable, Sendable {
        var enrollment: String
        var date: String
        var time: String
        /// The reading it is about.
        var assignment: Int?
        var position: Int?
        var appointed: String?
        /// Present, and true, for a reminder the reader snoozed.
        var snooze: Bool?
    }

    var reminders: [Reminder]
}

@Test func remindersMatchTheirFixture() throws {
    try checkFixture("reminders") { (input: RemindersInput, plans: [PlanVersion]) -> RemindersOutput in
        let journal = try Journal(wire: input.events, plans: plans)
        let now = LocalDateTime(date: try CivilDate(input.today), time: try #require(WallTime(input.time)))
        var settings = ReminderSettings()
        if let quiet = input.quiet {
            settings.quietHours = .init(
                from: try #require(WallTime(quiet.from)), until: try #require(WallTime(quiet.until)))
        }
        settings.mostADay = input.most
        settings.window = input.window ?? settings.window
        settings.snoozes = try (input.snoozes ?? []).map {
            .init(
                enrollment: try #require(EventID($0.enrollment)),
                at: LocalDateTime(date: try CivilDate($0.date), time: try #require(WallTime($0.time))))
        }
        return RemindersOutput(
            reminders: journal.reminders(now: now, settings: settings).map { reminder in
                let plan = journal.enrollments.first { $0.id == reminder.enrollment }?.plan
                return .init(
                    enrollment: reminder.enrollment.rawValue, date: reminder.at.date.description,
                    time: reminder.at.time.description, assignment: reminder.slot?.assignment,
                    position: reminder.slot.flatMap { plan?.positions[$0.assignment] },
                    appointed: reminder.slot?.appointed?.description, snooze: reminder.isSnooze ? true : nil)
            })
    }
}

// MARK: The days ahead

struct AheadInput: Codable, Sendable {
    var events: [JSONValue]
    var today: String
    var days: Int
}

struct AheadOutput: Codable, Equatable, Sendable {
    struct Day: Codable, Equatable, Sendable {
        var date: String
        var readingDay: Bool
        var readings: [TodayOutput.Place]
    }

    struct Enrollment: Codable, Equatable, Sendable {
        var id: String
        var days: [Day]
    }

    var enrollments: [Enrollment]
}

@Test func theDaysAheadMatchTheirFixture() throws {
    try checkFixture("ahead") { (input: AheadInput, plans: [PlanVersion]) -> AheadOutput in
        let journal = try Journal(wire: input.events, plans: plans)
        let date = try CivilDate(input.today)
        return AheadOutput(
            enrollments: journal.enrollments.map { enrollment in
                .init(
                    id: enrollment.id.rawValue,
                    days: enrollment.comingDays(from: date, count: input.days).map { day in
                        .init(
                            date: day.date.description, readingDay: day.isReadingDay,
                            readings: day.readings.map { .init($0, in: enrollment.plan) })
                    })
            })
    }
}

/// The days ahead are Today's answer for each date in turn, supposing the
/// reader reads what each day shows: so marking each day's readings read,
/// one day after another, must find Today showing what was listed.
@Test func theDaysAheadAreWhatTodayWillShow() throws {
    let url = fixturesURL.appending(path: "ahead.json")
    let file = try JSONDecoder().decode(FixtureFile<AheadInput, AheadOutput>.self, from: Data(contentsOf: url))
    let (english, counts) = (try loadEnglish(), try loadWordCounts())
    let plans = try (file.plans ?? []).map { try $0.planVersion(in: english, counts: counts) }
    for testCase in file.cases {
        var journal = try Journal(wire: testCase.input.events, plans: plans)
        let first = try CivilDate(testCase.input.today)
        let listed = journal.enrollments.map { $0.comingDays(from: first, count: testCase.input.days) }
        for offset in 0..<testCase.input.days {
            let date = try first.adding(days: offset)
            for (index, enrollment) in journal.enrollments.enumerated() {
                let day = listed[index][offset]
                #expect(day.date == date)
                let today = enrollment.today(date)
                #expect(day.isReadingDay == today.isReadingDay, "\(testCase.name ?? "") on \(date)")
                if enrollment.plan.schedule == .sequence {
                    #expect(day.readings == today.readings, "\(testCase.name ?? "") on \(date)")
                } else {
                    // The appointment is the day's, on rest and paused days too.
                    let appointed = today.calendar.map { $0.state == .unread ? [$0.appointment] : [] } ?? []
                    #expect(day.readings == appointed, "\(testCase.name ?? "") on \(date)")
                }
            }
            // Read everything the day listed, in every enrollment.
            for (index, enrollment) in journal.enrollments.enumerated() {
                for slot in listed[index][offset].readings {
                    let mark = JournalEvent.Marked(
                        .completed, assignment: slot.assignment, date: date, appointed: slot.appointed)
                    journal = try #require(journal.previewing(.marked(mark), in: enrollment.id))
                }
            }
        }
    }
}

// MARK: Bible links

struct BibleLinkInput: Codable, Sendable {
    var reading: String
    var translation: Int
}

struct BibleLinkOutput: Codable, Equatable, Sendable {
    var url: String?
    var whole: Bool?
    /// Where an address that does not hold the whole reading opens.
    var opensAt: String?
    var abbreviation: String?
    var name: String?
    var error: String?
}

@Test func bibleLinksMatchTheirFixture() throws {
    let english = try loadEnglish()
    try checkFixture("bible-links") { (input: BibleLinkInput) -> BibleLinkOutput in
        guard let translation = BibleTranslation.withID(input.translation) else {
            return BibleLinkOutput(error: "unknownTranslation")
        }
        let link = BibleLink(
            try ReferenceFormat.reading(input.reading, in: english), translation: translation, in: english)
        return BibleLinkOutput(
            url: link.address, whole: link.isWholeReading,
            opensAt: link.isWholeReading ? nil : "\(link.book) \(link.chapter)",
            abbreviation: translation.abbreviation, name: translation.name)
    }
}

/// Every translation Day by Word links to is pinned by a case, so the web's
/// list cannot leave one out or name one differently.
@Test func everyTranslationIsInTheBibleLinksFixture() throws {
    let file = try JSONDecoder().decode(
        FixtureFile<BibleLinkInput, BibleLinkOutput>.self,
        from: Data(contentsOf: fixturesURL.appending(path: "bible-links.json")))
    let pinned = Set(file.cases.map(\.input.translation))
    #expect(Set(BibleTranslation.all.map(\.id)).isSubset(of: pinned))
    #expect(Set(BibleTranslation.all.map(\.id)).count == BibleTranslation.all.count)
    // Alphabetical by name: no translation is put first.
    #expect(BibleTranslation.all.map(\.name) == BibleTranslation.all.map(\.name).sorted())
}

// MARK: Choosing a plan

struct ChoosingInput: Codable, Sendable {
    struct Answers: Codable, Sendable {
        var hope: Goal?
        var time: Choosing.Time?
        var days: Int?
    }
    struct Candidate: Codable, Sendable {
        var plan: String
        var goals: [Goal]
        var schedule: String
        var readingDays: Int
        var readings: Int
        var typicalWords: Int
    }
    var answers: Answers
    var candidates: [Candidate]
}

struct ChoosingOutput: Codable, Equatable, Sendable {
    struct Recommendation: Codable, Equatable, Sendable {
        var plan: String
        var goal: Goal?
        var minutes: [Int]
        var fitsTime: Bool?
        var readerDays: Int?
        var fitsDays: Bool?
        var perWeek: Int?
        var weeks: Int?
    }
    var recommendations: [Recommendation]
}

@Test func recommendationsMatchTheirFixture() throws {
    try checkFixture("recommendations") { (input: ChoosingInput) -> ChoosingOutput in
        let candidates = try input.candidates.map { candidate in
            Choosing.Candidate(
                plan: try #require(PlanID(candidate.plan)), goals: Set(candidate.goals),
                schedule: try #require(Plan.Schedule(rawValue: candidate.schedule)),
                readingDays: candidate.readingDays, readings: candidate.readings,
                typicalWords: candidate.typicalWords)
        }
        let answers = Choosing.Answers(hope: input.answers.hope, time: input.answers.time, days: input.answers.days)
        return ChoosingOutput(
            recommendations: Choosing.recommend(candidates, for: answers).map {
                .init(
                    plan: $0.plan.rawValue, goal: $0.goal, minutes: [$0.minutes.lowerBound, $0.minutes.upperBound],
                    fitsTime: $0.fitsTime, readerDays: $0.readerDays, fitsDays: $0.fitsDays, perWeek: $0.perWeek,
                    weeks: $0.weeks)
            })
    }
}
