import Foundation
import Hummingbird
import HummingbirdTesting
import Testing

@testable import DayByWordWeb

// The web's shared fixtures in tests/fixtures/ (its README): what each address
// answers, the interface text, and the settings kept in the browser, which
// the Astro site must match before this server retires (BUILD.md PM.16,
// PM.20). Set DBW_RECORD_FIXTURES=1 to rewrite the outputs from this server,
// then review the diff before committing.

private let repository = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

private let recording = ProcessInfo.processInfo.environment["DBW_RECORD_FIXTURES"] != nil

private func fixtureURL(_ name: String) -> URL { repository.appending(path: "tests/fixtures/\(name).json") }

private func record(_ value: some Encodable, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try (encoder.encode(value) + Data("\n".utf8)).write(to: url, options: .atomic)
}

private struct RouteFixture: Codable {
    struct Input: Codable {
        var path: String
        /// `development` when absent.
        var environment: String?
    }

    struct Output: Codable, Equatable, Sendable {
        var status: Int
        var contentType: String?
        var cacheControl: String?
        /// For pages: the title, the first heading, and the section marked
        /// current in the navigation.
        var title: String?
        var heading: String?
        var current: String?
    }

    struct Case: Codable {
        var input: Input
        var output: Output?
    }

    var fixture: String
    var version: Int
    var about: String
    /// The headers every response carries, errors included.
    var headers: [String: String]
    var cases: [Case]
}

/// The text between the first `start` and the next `end`, if any.
private func first(_ start: String, _ end: String, in body: String) -> String? {
    guard let open = body.range(of: start), let close = body[open.upperBound...].range(of: end) else { return nil }
    return String(body[open.upperBound..<close.lowerBound])
}

@Test func routesMatchTheirFixture() async throws {
    let url = fixtureURL("routes")
    var file = try JSONDecoder().decode(RouteFixture.self, from: Data(contentsOf: url))
    #expect(file.fixture == "routes")
    #expect(!file.cases.isEmpty)
    var headers: [String: String] = [:]
    for (index, testCase) in file.cases.enumerated() {
        var configuration = ServerConfiguration()
        configuration.publicDirectory = repository.appending(path: "Server/Public").path
        configuration.logLevel = .warning
        configuration.environment = try #require(.init(rawValue: testCase.input.environment ?? "development"))
        let (output, sent) = try await buildApplication(configuration).test(.router) { client in
            try await client.execute(uri: testCase.input.path, method: .get) { response in
                let body = String(buffer: response.body)
                let html = response.headers[.contentType]?.hasPrefix("text/html") == true
                let output = RouteFixture.Output(
                    status: Int(response.status.code), contentType: response.headers[.contentType],
                    cacheControl: response.headers[.cacheControl],
                    title: html ? first("<title>", "</title>", in: body) : nil,
                    heading: html ? first("<h1>", "</h1>", in: body) : nil,
                    current: html ? first(#"aria-current="page">"#, "</a>", in: body) : nil)
                var sent: [String: String] = [:]
                for field in SecurityHeadersMiddleware<BasicRequestContext>.headers {
                    sent[field.name.canonicalName] = response.headers[field.name]
                }
                return (output, sent)
            }
        }
        headers = sent
        if recording {
            file.cases[index].output = output
        } else {
            #expect(testCase.output == output, "routes case \(index): \(testCase.input.path)")
            #expect(sent == file.headers, "routes case \(index): \(testCase.input.path)")
        }
    }
    if recording {
        file.headers = headers
        try record(file, to: url)
    }
}

private struct StringsFixture: Codable {
    struct Case: Codable {
        var input: String
        var output: [String: String]?
    }

    var fixture: String
    var version: Int
    var about: String
    var cases: [Case]
}

@Test func stringsMatchTheirFixture() throws {
    let url = fixtureURL("strings")
    var file = try JSONDecoder().decode(StringsFixture.self, from: Data(contentsOf: url))
    #expect(file.cases.map(\.input) == ["en"])
    let english = Dictionary(uniqueKeysWithValues: Strings.english.table.map { ($0.key.rawValue, $0.value) })
    if recording {
        file.cases[0].output = english
        try record(file, to: url)
    } else {
        #expect(file.cases.first?.output == english)
    }
}

/// tests/fixtures/settings.json, written by hand: the settings each client
/// keeps on the reader's device.
struct SettingsFixture: Codable {
    struct Setting: Codable {
        struct Web: Codable {
            var field: String
            var storageKey: String
        }

        struct App: Codable {
            var storageKey: String
        }

        var name: String
        var values: [String]
        var defaultValue: String
        var web: Web
        var app: App
    }

    var fixture: String
    var version: Int
    var about: String
    var settings: [Setting]
}

@Test func theSettingsPageOffersTheFixturesSettings() async throws {
    let file = try JSONDecoder().decode(SettingsFixture.self, from: Data(contentsOf: fixtureURL("settings")))
    #expect(file.fixture == "settings")
    let scripts = try ["settings.js", "theme.js"].map {
        try String(contentsOf: repository.appending(path: "Server/Public/assets/\($0)"), encoding: .utf8)
    }
    try await buildApplication(ServerConfiguration()).test(.router) { client in
        try await client.execute(uri: "/settings", method: .get) { response in
            let body = String(buffer: response.body)
            for setting in file.settings {
                for value in setting.values {
                    let checked = value == setting.defaultValue ? " checked" : ""
                    #expect(body.contains(#"name="\#(setting.web.field)" value="\#(value)"\#(checked)>"#))
                }
                for script in scripts { #expect(script.contains("'\(setting.web.storageKey)'")) }
            }
        }
    }
}
