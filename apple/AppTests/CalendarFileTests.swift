import Foundation
import Testing

@testable import DayByWord

/// The app's calendar file against tests/fixtures/calendar.json (BUILD.md
/// P13.4, docs/decisions.md E59), the cases the web's writer passes too.
private struct Fixture: Decodable {
    struct Case: Decodable {
        let name: String
        let stamp: String
        let time: String?
        let events: [Event]
        let lines: [String]
    }

    struct Event: Decodable {
        let enrollment: String
        let date: String
        let plan: String
        let label: String
        let references: [String]
    }

    let description: String
    let cases: [Case]
}

private func fixture() throws -> Fixture {
    let repository = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent()
    let data = try Data(contentsOf: repository.appending(path: "tests/fixtures/calendar.json"))
    return try JSONDecoder().decode(Fixture.self, from: data)
}

@Test func theDescriptionIsTheStringTables() throws {
    #expect(CalendarFile.description == (try fixture()).description)
}

@Test func writesEachFixtureCaseExactly() throws {
    let fixture = try fixture()
    #expect(fixture.cases.count >= 5)
    for item in fixture.cases {
        let events = item.events.map {
            CalendarFile.Event(
                enrollment: $0.enrollment, date: $0.date, plan: $0.plan, label: $0.label, references: $0.references)
        }
        let text = CalendarFile.text(events, stamp: item.stamp, time: item.time, description: fixture.description)
        #expect(text == item.lines.joined(separator: "\r\n") + "\r\n", "\(item.name)")
    }
}
