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
    // A five-day plan's sample week rests at the weekend.
    let week = page.sampleWeek
    #expect(week.map(\.label) == ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])
    #expect(week[0].reference == ReferenceText(display: "Matthew 1–3", spoken: "Matthew, chapters 1 to 3"))
    #expect(week[5].reference == nil && week[6].reference == nil)

    let proverbs = PlanPresentation(
        catalog: catalog, plan: try #require(catalog.plan(PlanID("proverbs-through-the-month")!)))
    #expect(proverbs.sampleWeek.map(\.label) == (1...7).map { "Day \($0)" })
    #expect(proverbs.sampleWeek[6].reference?.display == "Proverbs 7")
    #expect(
        catalog.listed.map(\.id.rawValue) == ["proverbs-through-the-month", "gospels-at-your-pace", "bible-in-a-year"])
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
