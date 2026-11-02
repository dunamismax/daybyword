import Foundation
import Testing

@testable import DayByWord

/// The settings the app keeps in UserDefaults match the shared fixture in
/// tests/fixtures/settings.json, which the web checks too (BUILD.md PM.12).
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
    #expect(settings.count == 2)
}
