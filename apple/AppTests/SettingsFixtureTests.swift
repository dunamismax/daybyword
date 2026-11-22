import Foundation
import ReadingEngine
import Testing

@testable import DayByWord

/// The settings the app keeps in UserDefaults match the shared fixture in
/// tests/fixtures/settings.json, which the web checks too (BUILD.md PM.12).
@MainActor
@Test func settingsMatchTheSharedFixture() throws {
    struct Fixture: Decodable {
        struct Setting: Decodable {
            struct App: Decodable {
                var storageKey: String
            }

            var name: String
            var values: [String]
            var defaultValue: String
            var app: App
        }

        var settings: [Setting]
    }

    let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().appending(path: "tests/fixtures/settings.json")
    let settings = try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url)).settings
    let appearance = try #require(settings.first { $0.name == "appearance" })
    #expect(appearance.app.storageKey == Appearance.storageKey)
    #expect(appearance.values == Appearance.allCases.map(\.rawValue))
    #expect(appearance.defaultValue == Appearance.automatic.rawValue)
    let size = try #require(settings.first { $0.name == "reference-size" })
    #expect(size.app.storageKey == ReferenceSize.storageKey)
    #expect(size.values == ReferenceSize.allCases.map(\.rawValue))
    #expect(size.defaultValue == ReferenceSize.standard.rawValue)
    let way = try #require(settings.first { $0.name == "way-to-read" })
    #expect(way.app.storageKey == WayToRead.storageKey)
    #expect(way.values == WayToRead.allCases.map(\.rawValue))
    #expect(way.defaultValue == WayToRead.physicalBible.rawValue)
    // The Bible.com number, 0 until the reader chooses (docs/destinations.md).
    let translation = try #require(settings.first { $0.name == "translation" })
    #expect(translation.app.storageKey == WayToRead.translationKey)
    #expect(translation.values == ["0"] + BibleTranslation.all.map { String($0.id) })
    #expect(translation.defaultValue == "0")
    let names = try #require(settings.first { $0.name == "book-names" })
    #expect(names.app.storageKey == Library.conventionKey)
    #expect(names.values == NamingConvention.allCases.map(\.rawValue))
    #expect(names.defaultValue == NamingConvention.common.rawValue)
    #expect(settings.count == 5)
}
