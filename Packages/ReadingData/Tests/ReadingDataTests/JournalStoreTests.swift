import Foundation
import ReadingData
import ReadingEngine
import Testing

private func event(_ milliseconds: Int, enrollment: Int = 1, _ body: JournalEvent.Body) -> JournalEvent {
    let zeros = [UInt8](repeating: 0, count: 10)
    return JournalEvent(
        id: EventID(milliseconds: milliseconds, random: zeros)!,
        enrollment: EventID(milliseconds: enrollment, random: zeros)!,
        at: "2027-03-01T07:00:00Z", zone: "Europe/London", device: "iPhone", body: body)
}

private let enrolled = event(
    2,
    .enrolled(
        .init(
            plan: PlanID("gospels-at-your-pace")!, version: 1, behavior: .pace,
            start: try! CivilDate("2027-03-01"), readingDays: [1, 2, 3, 4, 5])))
private let read = event(
    3, .marked(.init(.completed, assignment: 1, date: try! CivilDate("2027-03-01"))))

@Test func keepsEventsInJournalOrderAsTheyWereWritten() throws {
    let store = try JournalStore.inMemory()
    #expect(try store.events().isEmpty)
    try store.append([read])
    try store.append([enrolled])
    #expect(try store.events() == [enrolled, read])
}

@Test func writingAnEventTwiceKeepsOne() throws {
    let store = try JournalStore.inMemory()
    try store.append([enrolled, read])
    try store.append([read])
    #expect(try store.events() == [enrolled, read])
}

@Test func keepsTheJournalAcrossOpenings() throws {
    let path = FileManager.default.temporaryDirectory.appending(path: "journal-\(UUID()).sqlite").path
    defer { try? FileManager.default.removeItem(atPath: path) }
    try JournalStore(path: path).append([enrolled, read])
    #expect(try JournalStore(path: path).events() == [enrolled, read])
}

@Test func deletesEverythingOnlyWhenAsked() throws {
    let store = try JournalStore.inMemory()
    try store.append([enrolled, read])
    try store.deleteEverything()
    #expect(try store.events().isEmpty)
}

@Test func refusesAJournalFromALaterBuild() throws {
    let path = FileManager.default.temporaryDirectory.appending(path: "journal-\(UUID()).sqlite").path
    defer { try? FileManager.default.removeItem(atPath: path) }
    let database = try Database(path: path, access: .create)
    try database.execute("PRAGMA user_version = 99")
    #expect(throws: SQLiteError.self) { try JournalStore(path: path) }
}
