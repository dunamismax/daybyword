import Foundation
import ReadingEngine
import Testing

@testable import CatalogCompiler

/// An invented plan (never a real plan's schedule, AGENTS.md §6), with any
/// front matter value replaced, removed (nil), or the schedule changed.
func planText(_ changes: [String: String?] = [:], schedule: String = "1\tMRK 1\n2\tLUK 15:1-10; JHN 3:16") -> String {
    let values: [(String, String)] = [
        ("id", "test-plan"), ("title", "A test plan"), ("version", "1"), ("creator", "Day by Word"),
        ("summary", "Readings for the tests."), ("suits", "The tests."), ("schedule", "sequence"),
        ("behaviors", "pace, finish-date"), ("reading-days", "5"), ("coverage", "selection"),
        ("canon", "protestant"), ("books", "MRK, LUK, JHN"), ("limitations", "None worth saying."),
        ("instructions", "Read one a day."), ("source", "Invented for the tests."),
        ("rights", "daybyword-original"), ("review", "checked"),
    ]
    let lines = values.compactMap { key, value -> String? in
        let changed = changes[key] ?? value
        return changed.map { "\(key): \($0)" }
    }
    return lines.joined(separator: "\n") + "\n---\n" + schedule + "\n"
}

func readPlan(_ text: String, name: String = "test-plan") throws(PlanFileError) -> Plan {
    let registry = try! CatalogBuild.readRegistry(from: catalogSource)
    let english = try! CatalogBuild.readVersifications(from: catalogSource, registry: registry)[.english]!
    return try PlanFile.read(text, name: name, registry: registry, versification: english)
}

@Test func readsAPlanFile() throws {
    let plan = try readPlan(
        "# A comment\n" + planText(["summary": "Readings for\n  the tests,\n  in two lines."]))
    #expect(plan.id == PlanID("test-plan"))
    #expect(plan.version == 1)
    #expect(plan.summary == "Readings for the tests, in two lines.")
    #expect(plan.schedule == .sequence)
    #expect(plan.behaviors == [.pace, .finishDate])
    #expect(plan.readingDays == 5)
    #expect(plan.books.map(\.rawValue) == ["MRK", "LUK", "JHN"])
    #expect(plan.review == .checked)
    #expect(plan.assignments.map(\.id) == [1, 2])
    #expect(plan.assignments[1].reading.passages.count == 2)
}

/// Each book of the canon whole, one assignment a book.
func wholeBibleSchedule() throws -> String {
    let registry = try CatalogBuild.readRegistry(from: catalogSource)
    let english = try #require(try CatalogBuild.readVersifications(from: catalogSource, registry: registry)[.english])
    let books = try #require(registry.canon("protestant")).books
    return try books.enumerated().map { index, book in
        let chapters = try #require(english.chapters(of: book))
        let range = chapters.count == 1 ? "\(chapters.lowerBound)" : "\(chapters.lowerBound)-\(chapters.upperBound)"
        return "\(index + 1)\t\(book) \(range)"
    }.joined(separator: "\n")
}

@Test func aWholeBiblePlanListsAllOfItsCanon() throws {
    let plan = try readPlan(planText(["coverage": "whole-bible", "books": "all"], schedule: wholeBibleSchedule()))
    #expect(plan.books.count == 66)
    #expect(plan.assignments.count == 66)
}

@Test func aDayOfMonthPlanHasEveryDay() throws {
    let days = (1...31).map { "\($0)\tPRO \(min($0, 31))" }.joined(separator: "\n")
    let plan = try readPlan(
        planText(["schedule": "day-of-month", "behaviors": "calendar", "books": "PRO"], schedule: days))
    #expect(plan.assignments.count == 31)
}

@Test(
    arguments: [
        // A change to the plan file, and the problem reported.
        (["id": "Test-Plan"], "line 1: id: \"Test-Plan\" is not a plan id"),
        (["id": "other-plan"], "line 1: id: \"other-plan\" does not match the file name \"test-plan.plan\""),
        (["version": "0"], "line 3: version: must be a whole number from 1"),
        (["version": "01"], "line 3: version: must be a whole number from 1"),
        (["schedule": "weekly"], "line 7: schedule: must be one of sequence, day-of-month"),
        (
            ["behaviors": "pace,finish-date"],
            "line 8: behaviors: must be joined by \", \" from pace, finish-date, calendar"
        ),
        (["behaviors": "pace, pace"], "line 8: behaviors: lists a behavior twice"),
        (["behaviors": "calendar"], "line 8: behaviors: calendar does not suit a sequence plan"),
        (["reading-days": "8"], "line 9: reading-days: must be a whole number from 1 to 7"),
        (["coverage": "most"], "line 10: coverage: must be one of whole-bible, books, selection"),
        (["canon": "orthodox"], "line 11: canon: \"orthodox\" is not a canon in books.json"),
        (["books": "MRK,LUK, JHN"], "line 12: books: must be USFM ids joined by \", \""),
        (["books": "MRK, LUK, JHN, TOB"], "line 12: books: TOB is not a book of the protestant canon"),
        (["books": "LUK, MRK, JHN"], "line 12: books: must list each book once, in the protestant canon's order"),
        (["books": "MRK, LUK, JHN, ACT"], "line 12: books: lists ACT, which no reading reads"),
        (["books": "MRK, LUK"], "line 20: reads JHN, which the books line does not list"),
        (["books": "all"], "line 12: books: must be USFM ids joined by \", \""),
        (["coverage": "whole-bible"], "line 12: books: a whole-bible plan lists \"all\", the canon's books"),
        (["rights": "Day by Word"], "line 16: rights: \"Day by Word\" is not a SOURCES.md id"),
        (["review": "approved"], "line 17: review: must be one of checked, reviewed, expert"),
        (["review": nil], "is missing review"),
        (["suits": nil], "line 6: schedule comes out of order; suits comes next"),
        (["title": " A test plan"], "line 2: title needs a value, without extra spaces"),
        (["title": ""], "line 2: title needs a value, without extra spaces"),
        (["title": nil, "id": "test-plan\ntitle"], "line 2: is not a \"key: value\" line"),
    ] as [([String: String?], String)])
func refusesAPlanFileThatBreaksTheFormat(changes: [String: String?], problem: String) {
    do {
        _ = try readPlan(planText(changes))
        Issue.record("read a broken plan file")
    } catch {
        #expect(error.description == problem)
    }
}

@Test(
    arguments: [
        // A plan file's text, and the problem reported.
        (
            planText().replacingOccurrences(of: "---\n", with: ""),
            "has no \"---\" line between its front matter and its schedule"
        ),
        (planText().replacingOccurrences(of: "title:", with: "subtitle:"), "line 2: \"subtitle\" is not a plan key"),
        (
            planText().replacingOccurrences(of: "version: 1", with: "version: 1\ntitle: Again"),
            "line 4: title is given twice"
        ),
        ("  stray\n" + planText(), "line 1: is indented but continues no value"),
        (planText(schedule: ""), "has no assignments"),
        (planText(schedule: "1\tMRK 1\n1\tMRK 2"), "line 20: repeats id 1"),
        (planText(schedule: "0\tMRK 1"), "line 19: is not an assignment id, a tab, and a reading"),
        (planText(schedule: "1 MRK 1"), "line 19: is not an assignment id, a tab, and a reading"),
        (planText(schedule: "1\tMRK 17"), "line 19: MRK has no chapter 17"),
        (planText(schedule: "1\tMark 1"), "line 19: \"Mark\" is not a USFM book id"),
        (planText(schedule: "1\tMRK 2-2"), "line 19: \"MRK 2-2\" should be written \"MRK 2\""),
        (
            planText(["schedule": "day-of-month", "behaviors": "calendar", "books": "MRK"], schedule: "1\tMRK 1"),
            "a day-of-month plan has one line for each day from 1 to 31, in order"
        ),
    ])
func refusesAPlanFileWithABrokenLine(text: String, problem: String) {
    do {
        _ = try readPlan(text)
        Issue.record("read a broken plan file")
    } catch {
        #expect(error.description == problem)
    }
}

@Test(
    arguments: [
        // FIPS 180-4's examples.
        ("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"),
        ("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"),
        (
            "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
            "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"
        ),
    ])
func sha256MatchesTheStandard(message: String, digest: String) {
    #expect(SHA256.hex(Array(message.utf8)) == digest)
}

@Test func sha256HandlesEveryPaddingLength() {
    // A million "a"s, the standard's long example.
    #expect(
        SHA256.hex([UInt8](repeating: UInt8(ascii: "a"), count: 1_000_000))
            == "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
    // Messages either side of a block's padding boundary all differ.
    #expect(Set((50...70).map { SHA256.hex([UInt8](repeating: 0, count: $0)) }).count == 21)
}
