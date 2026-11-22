import Foundation
import ReadingData
import ReadingEngine
import Testing

@testable import DayByWord

/// What Siri and Shortcuts say and record (BUILD.md P12.4): the library's
/// answers behind the intents, since `perform()` itself needs the system.
@MainActor
private func library(today: String = "2027-03-01") throws -> Library {
    let url = try #require(Bundle.main.url(forResource: "Catalog", withExtension: "sqlite"))
    let date = try CivilDate(today)
    return Library(
        catalog: try Catalog(path: url.path), store: try JournalStore.inMemory(),
        clock: { date.start(in: TimeZone(identifier: "UTC")!).addingTimeInterval(7 * 3600) })
}

private let gospels = PlanID("gospels-at-your-pace")!
private let proverbs = PlanID("proverbs-through-the-month")!

@MainActor
@Test func withNoPlanSiriSuggestsChoosingOne() throws {
    let library = try library()
    #expect(library.todaysAnswer().display == "You're not following a plan yet. Choose one in Day by Word.")
    #expect(library.followedPlans().isEmpty)
    #expect(library.todaysReadings().isEmpty)
}

@MainActor
@Test func todaysAnswerNamesEachPlansReadingAndSaysItInWords() throws {
    let library = try library()
    let first = try library.start(
        .init(plan: gospels, version: 1, behavior: .pace, start: library.today, readingDays: [1, 2, 3, 4, 5]))
    let second = try library.start(
        .init(
            plan: proverbs, version: 1, behavior: .calendar, start: library.today, readingDays: [1, 2, 3, 4, 5, 6, 7]))
    // Both start on the same fixed clock, so their order is the ids' random
    // part (AGENTS.md §11): find each by its id.
    #expect(Set(library.followedPlans().map(\.id)) == [first.description, second.description])

    let readings = library.todaysReadings()
    let gospel = try #require(readings.first { $0.enrollment == first })
    let proverb = try #require(readings.first { $0.enrollment == second })
    #expect(readings.count == 2)
    #expect(gospel.label == "Reading 1")
    #expect(proverb.label == "Day 1")
    // 1 March is day 1 of the month: Proverbs 1.
    #expect(proverb.reference == "Proverbs 1")
    #expect(proverb.spoken == "Proverbs, chapter 1")

    let answer = library.todaysAnswer()
    let lines = answer.display.components(separatedBy: "\n")
    #expect(lines.count == 2)
    #expect(lines.contains("Gospels at your pace, Reading 1: \(gospel.reference)."))
    #expect(lines.contains("Proverbs through the month, Day 1: Proverbs 1."))
    #expect(answer.spoken.contains("Proverbs through the month, Day 1: Proverbs, chapter 1."))
}

@MainActor
@Test func markingFromSiriRecordsTheReadingOnceAndTodaySaysSo() throws {
    let library = try library()
    let id = try library.start(
        .init(plan: gospels, version: 1, behavior: .pace, start: library.today, readingDays: [1, 2, 3, 4, 5]))
    let reading = try #require(library.todaysReadings().first)
    #expect(try library.markRead(reading))
    #expect(library.activeEnrollments[0].state(of: reading.slot) == .read)
    // Nothing is recorded twice.
    #expect(try library.markRead(reading) == false)
    #expect(library.journal?.events.count == 2)
    #expect(library.todaysReadings().isEmpty)
    #expect(library.todaysAnswer().display == "Gospels at your pace: That's today's reading.")
    #expect(library.status(of: id.description) == "Gospels at your pace: That's today's reading.")
}

@MainActor
@Test func aPausedPlanIsNamedButNotOfferedToMark() throws {
    let library = try library()
    let id = try library.start(
        .init(plan: gospels, version: 1, behavior: .pace, start: library.today, readingDays: [1, 2, 3, 4, 5]))
    try library.record(.paused(from: library.today), enrollment: id)
    #expect(library.todaysReadings().isEmpty)
    #expect(library.todaysAnswer().display == "Gospels at your pace: This plan is paused.")
    #expect(library.status(of: "not-a-plan") == "That plan isn't one you're following now.")
}
