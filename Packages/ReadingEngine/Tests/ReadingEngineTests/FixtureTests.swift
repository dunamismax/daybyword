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

struct FixtureFile<Input: Codable & Sendable, Output: Codable & Equatable & Sendable>: Codable, Sendable {
    struct Case: Codable, Sendable {
        var input: Input
        var output: Output?
    }

    var fixture: String
    var version: Int
    var about: String
    var cases: [Case]
}

/// Checks each case of `tests/fixtures/<name>.json` against `compute`, or
/// records `compute`'s outputs into the file.
func checkFixture<Input: Codable & Sendable, Output: Codable & Equatable & Sendable>(
    _ name: String, sourceLocation: SourceLocation = #_sourceLocation, _ compute: (Input) throws -> Output
) throws {
    let url = fixturesURL.appending(path: "\(name).json")
    var file = try JSONDecoder().decode(FixtureFile<Input, Output>.self, from: Data(contentsOf: url))
    #expect(file.fixture == name, sourceLocation: sourceLocation)
    if ProcessInfo.processInfo.environment["DBW_RECORD_FIXTURES"] != nil {
        for index in file.cases.indices { file.cases[index].output = try compute(file.cases[index].input) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try (encoder.encode(file) + Data("\n".utf8)).write(to: url, options: .atomic)
        return
    }
    #expect(!file.cases.isEmpty, sourceLocation: sourceLocation)
    for (index, testCase) in file.cases.enumerated() {
        let output = try compute(testCase.input)
        #expect(testCase.output == output, "\(name) case \(index): \(testCase.input)", sourceLocation: sourceLocation)
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
