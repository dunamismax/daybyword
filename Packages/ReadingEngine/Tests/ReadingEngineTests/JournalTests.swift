import Foundation
import ReadingEngine
import Testing

// The journal beyond its shared cases (tests/fixtures/journal.json): the
// properties the cases cannot state one input at a time.

/// A small generator with a fixed seed, so a shuffle is the same every run.
private struct Shuffler: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}

private struct JournalCases: Decodable {
    struct Case: Decodable {
        struct Input: Decodable {
            var events: [JSONValue]
        }

        var name: String
        var input: Input
    }

    var plans: [FixturePlan]
    var cases: [Case]
}

private func loadJournalCases() throws -> (plans: [PlanVersion], cases: [JournalCases.Case]) {
    let file = try JSONDecoder().decode(
        JournalCases.self, from: Data(contentsOf: fixturesURL.appending(path: "journal.json")))
    let english = try loadEnglish()
    return (try file.plans.map { try $0.planVersion(in: english) }, file.cases)
}

/// What a fold comes to, for comparing two folds.
private struct Summary: Equatable {
    var events: [JournalEvent]
    var inert: [Journal.Inert]
    var active: [Bool]
    var settled: [[SlotMark]]
    var pauses: [[Pause]]
    var starts: [CivilDate]
    var ended: [CivilDate?]

    init(_ journal: Journal) {
        events = journal.events
        inert = journal.inert
        active = journal.events.map { journal.isActive($0.id) }
        settled = journal.enrollments.map(\.settled)
        pauses = journal.enrollments.map(\.pauses)
        starts = journal.enrollments.map(\.start)
        ended = journal.enrollments.map(\.ended)
    }
}

@Test func theFoldIsTheSameInAnyArrivalOrder() throws {
    let (plans, cases) = try loadJournalCases()
    var shuffler = Shuffler(state: 2027)
    var folded = 0
    for testCase in cases {
        guard let events = try? JournalEvent.events(wire: testCase.input.events),
            let journal = try? Journal(events: events, plans: plans)
        else { continue }
        folded += 1
        let expected = Summary(journal)
        #expect(Summary(try Journal(events: events.reversed(), plans: plans)) == expected, "\(testCase.name)")
        for _ in 0..<5 {
            let shuffled = events.shuffled(using: &shuffler)
            #expect(Summary(try Journal(events: shuffled, plans: plans)) == expected, "\(testCase.name)")
        }
        // Every event sent twice is the same journal.
        #expect(Summary(try Journal(events: events + events, plans: plans)) == expected, "\(testCase.name)")
    }
    #expect(folded >= 30)
}

@Test func anEventReadsBackFromItsWireForm() throws {
    let (_, cases) = try loadJournalCases()
    var kinds: Set<String> = []
    for testCase in cases {
        guard let events = try? JournalEvent.events(wire: testCase.input.events) else { continue }
        for event in events {
            kinds.insert(event.kind)
            #expect(try JournalEvent(wire: event.wire) == event)
            // Through JSON text and back, as a client stores it.
            let data = try JSONEncoder().encode([event.wire])
            #expect(try JournalEvent.events(wire: data) == [event])
        }
    }
    #expect(kinds.count == 10)
}

@Test func aJournalThatIsNotAListOfEventsIsMalformed() {
    #expect(throws: JournalError.malformedEvent("the journal is not a JSON list of events")) {
        try JournalEvent.events(wire: Data(#"{"events": []}"#.utf8))
    }
    #expect(throws: JournalError.self) { try JournalEvent.events(wire: Data("not JSON".utf8)) }
}

@Test func jsonValuesKeepTrueApartFromOne() throws {
    let values = try JSONDecoder().decode(
        [JSONValue].self, from: Data(#"[true, 1, "1", null, 1.5, [1], {"a": 1}]"#.utf8))
    #expect(
        values == [
            .bool(true), .number(1), .string("1"), .null, .number(1.5), .array([.number(1)]),
            .object(["a": .number(1)]),
        ])
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let text = String(decoding: try encoder.encode(values), as: UTF8.self)
    #expect(text == #"[true,1,"1",null,1.5,[1],{"a":1}]"#)
}

@Test func eventIDsSortByTheTimeTheyWereMade() throws {
    let random = [UInt8](repeating: 0xFF, count: 10)
    let earlier = try #require(EventID(milliseconds: 1_803_898_923_456, random: random))
    let later = try #require(EventID(milliseconds: 1_803_898_923_457, random: [UInt8](repeating: 0, count: 10)))
    #expect(earlier < later)
    #expect(earlier.rawValue < later.rawValue)
    #expect(earlier.milliseconds == 1_803_898_923_456)
    #expect(EventID(earlier.rawValue) == earlier)
    #expect(EventID(milliseconds: 1 << 48, random: random) == nil)
    #expect(EventID(milliseconds: 0, random: []) == nil)
}

@Test func wallTimesAreWrittenAndReadBack() {
    #expect(WallTime("07:05")?.description == "07:05")
    #expect(WallTime("00:00").map { [$0.hour, $0.minute] } == [0, 0])
    #expect(WallTime("23:59").map { [$0.hour, $0.minute] } == [23, 59])
    for text in ["24:00", "07:60", "7:05", "07:5", "0705", "07:05:00", " 07:05", "０７:05", ""] {
        #expect(WallTime(text) == nil, "\(text)")
    }
    #expect(WallTime(hour: 24, minute: 0) == nil)
    #expect(WallTime("06:59")! < WallTime("07:00")!)
}

@Test func aPlanVersionGivesEachAssignmentItsPlace() throws {
    let (plans, _) = try loadJournalCases()
    let second = try #require(plans.first { $0.version == 2 })
    #expect(second.positions[11] == 4)
    #expect(second.positions[4] == 5)
    #expect(second.positions[12] == nil)
}
