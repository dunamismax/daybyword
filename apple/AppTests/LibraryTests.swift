import Foundation
import ReadingData
import ReadingEngine
import Testing

@testable import DayByWord

/// The bundled catalog, opened as the app opens it.
@MainActor
private func bundledCatalog() throws -> Catalog {
    let url = try #require(Bundle.main.url(forResource: "Catalog", withExtension: "sqlite"))
    return try Catalog(path: url.path)
}

/// A library on the bundled catalog with an empty journal in memory, its
/// clock at 07:00 UTC on `today`.
@MainActor
private func library(today: String = "2027-03-01") throws -> Library {
    let date = try CivilDate(today)
    return Library(
        catalog: try bundledCatalog(), store: try JournalStore.inMemory(),
        clock: { date.start(in: TimeZone(identifier: "UTC")!).addingTimeInterval(7 * 3600) })
}

private let gospels = PlanID("gospels-at-your-pace")!

@MainActor
@Test func startsAPlanWithOneEnrolledEvent() throws {
    let library = try library()
    #expect(library.activeEnrollments.isEmpty)
    let enrolled = JournalEvent.Enrolled(
        plan: gospels, version: 1, behavior: .pace, start: library.today, readingDays: [1, 2, 3, 4, 5])
    let id = try library.start(enrolled)
    let enrollment = try #require(library.activeEnrollments.first)
    #expect(enrollment.id == id)
    #expect(enrollment.enrolled == enrolled)
    #expect(library.journal?.events.count == 1)
    #expect(library.journal?.inert.isEmpty == true)
    // Monday 1 March 2027: the first reading is today's.
    #expect(enrollment.today(library.today).status == .reading)
    #expect(enrollment.today(library.today).readings == [Slot(assignment: 1)])
}

@MainActor
@Test func marksUndoesAndRedoesThroughTheJournal() throws {
    let library = try library()
    let id = try library.start(
        .init(plan: gospels, version: 1, behavior: .pace, start: library.today, readingDays: [1, 2, 3, 4, 5]))
    let read = try library.record(.marked(.init(.completed, assignment: 1, date: library.today)), enrollment: id)
    #expect(library.activeEnrollments[0].today(library.today).status == .done)

    let undo = try library.record(.undone(target: read.id), enrollment: id)
    #expect(library.activeEnrollments[0].state(of: Slot(assignment: 1)) == .unread)
    #expect(library.activeEnrollments[0].today(library.today).status == .reading)

    try library.record(.undone(target: undo.id), enrollment: id)
    #expect(library.activeEnrollments[0].state(of: Slot(assignment: 1)) == .read)
    // Nothing is removed: the history keeps all four events, none of them inert.
    #expect(library.journal?.events.count == 4)
    #expect(library.journal?.inert.isEmpty == true)
}

@MainActor
@Test func eachEventFollowsTheOnesBeforeItInItsEnrollment() throws {
    let library = try library()
    let id = try library.start(
        .init(plan: gospels, version: 1, behavior: .pace, start: library.today, readingDays: [1, 2, 3, 4, 5]))
    // The clock stands still, so each id must still be later than the last.
    var ids = [id]
    for assignment in 1...3 {
        ids.append(
            try library.record(.marked(.init(.completed, assignment: assignment, date: library.today)), enrollment: id)
                .id)
    }
    #expect(ids == ids.sorted())
    #expect(Set(ids.map(\.milliseconds)).count == ids.count)
}

@MainActor
@Test func aSkipMovesTheNextReadingUpWithoutCountingAsRead() throws {
    let library = try library()
    let id = try library.start(
        .init(plan: gospels, version: 1, behavior: .pace, start: library.today, readingDays: [1, 2, 3, 4, 5]))
    try library.record(.marked(.init(.skipped, assignment: 1, date: library.today)), enrollment: id)
    let today = library.activeEnrollments[0].today(library.today)
    #expect(today.status == .reading)
    #expect(today.readings == [Slot(assignment: 2)])
    #expect(library.activeEnrollments[0].state(of: Slot(assignment: 1)) == .skipped)
}

@MainActor
@Test func thePlanPageMatchesTheWebs() throws {
    let catalog = try bundledCatalog()
    let plan = try #require(catalog.plan(gospels))
    let page = PlanPresentation(catalog: catalog, plan: plan)
    #expect(page.readings == "60 readings")
    #expect(page.kind == "Read in order")
    #expect(page.typicalWorkload == "About 6–8 minutes. Estimates vary.")
    #expect(page.workloads.map(\.text) == ["About 6–8 minutes", "About 3–4 minutes", "About 8–10 minutes"])
    #expect(page.covers.first == "Every verse of Matthew, Mark, Luke, and John: 3,779 verses.")
    #expect(page.length == "60 readings: about 12 weeks at 5 readings a week.")
    #expect(
        page.permissions
            == "Day by Word's own plan: free to follow, to print for your own use, and to share by its link.")
    // A five-day plan's sample week rests at the weekend.
    let week = page.sampleWeek
    #expect(week.map(\.label) == ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])
    #expect(week[0].reference == ReferenceText(display: "Matthew 1–3", spoken: "Matthew, chapters 1 to 3"))
    #expect(week[5].reference == nil && week[6].reference == nil)

    let proverbs = PlanPresentation(
        catalog: catalog, plan: try #require(catalog.plan(PlanID("proverbs-through-the-month")!)))
    #expect(proverbs.sampleWeek.map(\.label) == (1...7).map { "Day \($0)" })
    #expect(proverbs.sampleWeek[6].reference?.display == "Proverbs 7")
    #expect(proverbs.length == "A reading for each day of the month, begun again each month.")
    #expect(
        catalog.listed.map(\.id.rawValue) == [
            "proverbs-through-the-month", "story-of-scripture", "gospels-at-your-pace", "pauls-letters",
            "psalm-a-day",
            "bible-in-a-year-five-days", "new-testament-in-a-year-five-days", "bible-in-a-year",
        ])
}

@MainActor
@Test func plansAreGroupedAndSuggestedAsOnTheWeb() throws {
    let catalog = try bundledCatalog()
    #expect(catalog.goals.map(\.goal) == Goal.allCases)
    #expect(catalog.goals.first?.plans == [gospels, PlanID("story-of-scripture")!])
    // docs/engine.md's example, in words, as web/test/db/read.test.ts has them.
    let suggested = catalog.suggestions(for: Choosing.Answers(hope: .wholeBible, time: .medium, days: 5))
    #expect(suggested.map(\.plan.id.rawValue) == ["bible-in-a-year-five-days", "bible-in-a-year"])
    #expect(
        suggested.first?.reasons == [
            "A plan for reading the whole Bible.",
            "A typical reading takes about 12 to 16 minutes, longer than you said.",
            "It's paced for 5 reading days a week, as you said.",
            "At 5 readings a week it takes about 52 weeks.",
        ])
    #expect(
        suggested.last?.reasons == [
            "A plan for reading the whole Bible.",
            "You said about 10 minutes. A typical reading takes about 9 to 11 minutes.",
            "It's paced for every day, more than you said.",
            "At 5 readings a week it takes about 73 weeks.",
        ])
    let calendar = catalog.suggestions(for: Choosing.Answers(hope: .psalmsProverbs, time: .short, days: 7))
    #expect(calendar.first?.plan.id.rawValue == "proverbs-through-the-month")
    #expect(calendar.first?.reasons.last == "It has a reading for each date of the month.")
}

@MainActor
@Test func referencesAreSpokenAsTheWebSpeaksThem() throws {
    let catalog = try bundledCatalog()
    let formatter = ReferenceFormatter(registry: catalog.registry, versification: catalog.versification)
    func spoken(_ text: String) throws -> String {
        ReferenceText(try ReferenceFormat.reading(text, in: catalog.versification), formatter: formatter).spoken
    }
    #expect(try spoken("MRK 4:1-20") == "Mark, chapter 4, verses 1 to 20")
    #expect(try spoken("MAT 1-3") == "Matthew, chapters 1 to 3")
    #expect(try spoken("PSA 23") == "Psalm 23")
    #expect(try spoken("JUD 1") == "Jude")
    #expect(try spoken("JUD 1:3-5") == "Jude, verses 3 to 5")
    #expect(try spoken("MAT 3:1-4:11") == "Matthew, chapter 3, verse 1, to chapter 4, verse 11")
    #expect(try spoken("PSA 119:1-24; PSA 120") == "Psalms, chapter 119, verses 1 to 24; then Psalm 120")
}

@MainActor
@Test func physicalBibleModeSaysWhereToFindAReadingInPrint() throws {
    let catalog = try bundledCatalog()
    let formatter = ReferenceFormatter(registry: catalog.registry, versification: catalog.versification)
    func place(_ text: String) throws -> [String] {
        PlaceInPrint.lines(try ReferenceFormat.reading(text, in: catalog.versification), formatter: formatter)
    }
    #expect(try place("MRK 4:1-20") == ["Mark · chapter 4 · verses 1–20"])
    #expect(try place("MAT 1-3") == ["Matthew · chapters 1–3"])
    #expect(try place("PRO 7") == ["Proverbs · chapter 7"])
    #expect(try place("JUD 1:3-5") == ["Jude · verses 3–5"])
}

@MainActor
@Test func aReturnAfterAGapIsWelcomedAndAnsweredWithoutRewritingHistory() throws {
    let library = try library(today: "2027-03-01")
    let id = try library.start(
        .init(plan: gospels, version: 1, behavior: .pace, start: library.today, readingDays: [1, 2, 3, 4, 5]))
    try library.record(.marked(.init(.completed, assignment: 1, date: library.today)), enrollment: id)
    // A week later: a gap of reading days, so the welcome is offered.
    let later = try CivilDate("2027-03-09")
    let enrollment = try #require(library.activeEnrollments.first)
    let welcome = try #require(enrollment.welcome(on: later))
    #expect(welcome.offers.map(\.choice) == [.continue])
    try library.record(welcome.answer(welcome.offers[0], on: later), enrollment: id)
    #expect(library.activeEnrollments[0].welcome(on: later) == nil)
    #expect(library.activeEnrollments[0].state(of: Slot(assignment: 1)) == .read)
    #expect(library.activeEnrollments[0].today(later).readings == [Slot(assignment: 2)])
}

@MainActor
@Test func theExportIsTheJournalItselfAndDeletingRemovesIt() throws {
    let library = try library()
    let id = try library.start(
        .init(plan: gospels, version: 1, behavior: .pace, start: library.today, readingDays: [1, 2, 3, 4, 5]))
    try library.record(.marked(.init(.completed, assignment: 1, date: library.today)), enrollment: id)
    let file = try JSONDecoder().decode(JSONValue.self, from: try library.export().data)
    guard case .object(let fields) = file, case .array(let events) = fields["events"] else {
        Issue.record("the export is not an object with events")
        return
    }
    #expect(fields["format"] == .string("day-by-word-journal"))
    #expect(try JournalEvent.events(wire: events) == library.journal?.events)

    try library.deleteEverything()
    #expect(library.journal?.events.isEmpty == true)
    #expect(library.activeEnrollments.isEmpty)
}
