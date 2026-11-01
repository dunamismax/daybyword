import ReadingEngine

/// Reads a plan file (docs/catalog-format.md) and checks everything that can
/// be checked from the file alone: its front matter, its schedule, and every
/// reference against the versification. Whether its rights entry exists, and
/// whether its coverage claim holds, are checked by `CatalogBuild`.
public enum PlanFile {
    /// The front matter's keys, in the order they must appear.
    public static let keys = [
        "id", "title", "version", "creator", "summary", "suits", "schedule", "behaviors", "reading-days",
        "coverage", "canon", "books", "limitations", "instructions", "source", "rights", "review",
    ]

    /// Reads the plan in `text`, from a file named `<name>.plan`.
    public static func read(
        _ text: String, name: String, registry: BookRegistry, versification: Versification
    ) throws(PlanFileError) -> Plan {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let divider = lines.firstIndex(of: "---") else {
            throw PlanFileError(line: nil, problem: "has no \"---\" line between its front matter and its schedule")
        }
        let fields = try frontMatter(lines[..<divider])
        func value(_ key: String) -> (line: Int, text: String) { fields[key]! }
        func fail(_ key: String, _ problem: String) -> PlanFileError {
            PlanFileError(line: value(key).line, problem: "\(key): \(problem)")
        }

        guard let id = PlanID(value("id").text) else { throw fail("id", "\"\(value("id").text)\" is not a plan id") }
        guard id.rawValue == name else { throw fail("id", "\"\(id)\" does not match the file name \"\(name).plan\"") }
        guard let version = Int(value("version").text), version >= 1, String(version) == value("version").text else {
            throw fail("version", "must be a whole number from 1")
        }
        guard let schedule = Plan.Schedule(rawValue: value("schedule").text) else {
            throw fail("schedule", "must be one of \(names(Plan.Schedule.allCases))")
        }
        let behaviorNames = value("behaviors").text.split(separator: ", ", omittingEmptySubsequences: false)
        let behaviors = behaviorNames.compactMap { Plan.Behavior(rawValue: String($0)) }
        guard behaviors.count == behaviorNames.count else {
            throw fail("behaviors", "must be joined by \", \" from \(names(Plan.Behavior.allCases))")
        }
        guard Set(behaviors).count == behaviors.count else { throw fail("behaviors", "lists a behavior twice") }
        if let wrong = behaviors.first(where: { !schedule.permittedBehaviors.contains($0) }) {
            throw fail("behaviors", "\(wrong.rawValue) does not suit a \(schedule.rawValue) plan")
        }
        guard let readingDays = Int(value("reading-days").text), (1...7).contains(readingDays),
            String(readingDays) == value("reading-days").text
        else { throw fail("reading-days", "must be a whole number from 1 to 7") }
        guard let coverage = Plan.Coverage(rawValue: value("coverage").text) else {
            throw fail("coverage", "must be one of \(names(Plan.Coverage.allCases))")
        }
        guard let canon = registry.canon(value("canon").text) else {
            throw fail("canon", "\"\(value("canon").text)\" is not a canon in books.json")
        }
        let books = try listedBooks(value("books").text, coverage: coverage, canon: canon) { fail("books", $0) }
        guard let review = Plan.Review(rawValue: value("review").text) else {
            throw fail("review", "must be one of \(names(Plan.Review.allCases))")
        }
        guard SourcesRegistry.isID(value("rights").text) else {
            throw fail("rights", "\"\(value("rights").text)\" is not a SOURCES.md id")
        }

        let scheduled = try assignments(
            lines[(divider + 1)...], firstLine: divider + 2, kind: schedule, versification: versification)
        for (line, assignment) in scheduled {
            if let book = assignment.reading.passages.map(\.book).first(where: { !books.contains($0) }) {
                throw PlanFileError(line: line, problem: "reads \(book), which the books line does not list")
            }
        }
        let assignments = scheduled.map(\.assignment)
        let read = Set(assignments.flatMap { $0.reading.passages.map(\.book) })
        if let book = books.first(where: { !read.contains($0) }) {
            throw fail("books", "lists \(book), which no reading reads")
        }

        return Plan(
            id: id, version: version, title: value("title").text, creator: value("creator").text,
            summary: value("summary").text, suits: value("suits").text, schedule: schedule, behaviors: behaviors,
            readingDays: readingDays, coverage: coverage, canon: canon.id, books: books,
            limitations: value("limitations").text, instructions: value("instructions").text,
            source: value("source").text, rights: value("rights").text, review: review, assignments: assignments)
    }

    /// The front matter's values by key, with the line each starts on.
    private static func frontMatter(_ lines: ArraySlice<String>) throws(PlanFileError) -> [String: (
        line: Int, text: String
    )] {
        var fields: [String: (line: Int, text: String)] = [:]
        var order: [String] = []
        for (offset, line) in lines.enumerated() {
            let number = lines.startIndex + offset + 1
            if line.isEmpty || line.hasPrefix("#") { continue }
            if line.hasPrefix("  ") {
                let continuation = line.dropFirst(2)
                guard let key = order.last, !continuation.isEmpty, !continuation.hasPrefix(" ") else {
                    throw PlanFileError(line: number, problem: "is indented but continues no value")
                }
                fields[key]!.text += " " + continuation
                continue
            }
            guard let colon = line.firstIndex(of: ":"), line[line.index(after: colon)...].hasPrefix(" ") else {
                throw PlanFileError(line: number, problem: "is not a \"key: value\" line")
            }
            let key = String(line[..<colon])
            let text = String(line[line.index(colon, offsetBy: 2)...])
            guard keys.contains(key) else { throw PlanFileError(line: number, problem: "\"\(key)\" is not a plan key") }
            guard fields[key] == nil else { throw PlanFileError(line: number, problem: "\(key) is given twice") }
            guard !text.isEmpty, !text.hasPrefix(" "), !text.hasSuffix(" ") else {
                throw PlanFileError(line: number, problem: "\(key) needs a value, without extra spaces")
            }
            let expected = keys[order.count]
            guard key == expected else {
                throw PlanFileError(line: number, problem: "\(key) comes out of order; \(expected) comes next")
            }
            fields[key] = (number, text)
            order.append(key)
        }
        if order.count < keys.count {
            throw PlanFileError(line: nil, problem: "is missing \(keys[order.count])")
        }
        return fields
    }

    private static func listedBooks(
        _ text: String, coverage: Plan.Coverage, canon: BookRegistry.Canon,
        fail: (String) -> PlanFileError
    ) throws(PlanFileError) -> [BookID] {
        if coverage == .wholeBible {
            guard text == "all" else { throw fail("a whole-bible plan lists \"all\", the canon's books") }
            return canon.books
        }
        let names = text.split(separator: ", ", omittingEmptySubsequences: false)
        let books = names.compactMap { BookID(String($0)) }
        guard books.count == names.count else { throw fail("must be USFM ids joined by \", \"") }
        if let book = books.first(where: { !canon.books.contains($0) }) {
            throw fail("\(book) is not a book of the \(canon.id) canon")
        }
        guard books == canon.books.filter(books.contains), Set(books).count == books.count else {
            throw fail("must list each book once, in the \(canon.id) canon's order")
        }
        return books
    }

    private static func assignments(
        _ lines: ArraySlice<String>, firstLine: Int, kind: Plan.Schedule, versification: Versification
    ) throws(PlanFileError) -> [(line: Int, assignment: Plan.Assignment)] {
        var assignments: [(line: Int, assignment: Plan.Assignment)] = []
        var ids: Set<Int> = []
        for (offset, line) in lines.enumerated() {
            let number = firstLine + offset
            if line.isEmpty || line.hasPrefix("#") { continue }
            let cells = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard cells.count == 2, let id = Int(cells[0]), id >= 1, String(id) == cells[0] else {
                throw PlanFileError(line: number, problem: "is not an assignment id, a tab, and a reading")
            }
            guard ids.insert(id).inserted else { throw PlanFileError(line: number, problem: "repeats id \(id)") }
            do {
                let reading = try ReferenceFormat.reading(String(cells[1]), in: versification)
                assignments.append((number, Plan.Assignment(id: id, reading: reading)))
            } catch {
                throw PlanFileError(line: number, problem: error.description)
            }
        }
        guard !assignments.isEmpty else { throw PlanFileError(line: nil, problem: "has no assignments") }
        if kind == .dayOfMonth, assignments.map(\.assignment.id) != Array(1...31) {
            throw PlanFileError(
                line: nil, problem: "a day-of-month plan has one line for each day from 1 to 31, in order")
        }
        return assignments
    }

    private static func names<T: RawRepresentable<String>>(_ cases: [T]) -> String {
        cases.map(\.rawValue).joined(separator: ", ")
    }
}

/// A problem in a plan file, and the line it is on where there is one.
public struct PlanFileError: Error, Equatable, CustomStringConvertible {
    public let line: Int?
    public let problem: String

    public var description: String { line.map { "line \($0): \(problem)" } ?? problem }
}
