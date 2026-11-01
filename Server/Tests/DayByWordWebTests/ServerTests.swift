import Foundation
import Hummingbird
import HummingbirdTesting
import ReadingData
import Testing

@testable import DayByWordWeb

/// The repository's `Server/Public`, so tests serve the real assets.
private let publicDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("Public").path

private func testApplication() throws -> some ApplicationProtocol {
    var configuration = ServerConfiguration()
    configuration.publicDirectory = publicDirectory
    configuration.logLevel = .warning
    return try buildApplication(configuration)
}

@Test func homePageIsHTMLWithTheIndependenceStatement() async throws {
    try await testApplication().test(.router) { client in
        try await client.execute(uri: "/", method: .get) { response in
            #expect(response.status == .ok)
            #expect(response.headers[.contentType] == "text/html; charset=utf-8")
            let body = String(buffer: response.body)
            #expect(body.hasPrefix("<!doctype html>"))
            #expect(body.contains("<h1>Day by Word</h1>"))
            #expect(body.contains("not affiliated with any church or denomination"))
            #expect(body.contains(#"<meta name="robots" content="noindex">"#))
        }
    }
}

@Test func upAnswersOK() async throws {
    try await testApplication().test(.router) { client in
        try await client.execute(uri: "/up", method: .get) { response in
            #expect(response.status == .ok)
            #expect(String(buffer: response.body) == "OK\n")
            #expect(response.headers[.cacheControl] == "no-store")
        }
    }
}

@Test func servesStaticAssets() async throws {
    try await testApplication().test(.router) { client in
        try await client.execute(uri: "/assets/site.css", method: .get) { response in
            #expect(response.status == .ok)
            #expect(response.headers[.contentType]?.hasPrefix("text/css") == true)
        }
    }
}

@Test(arguments: ["/", "/up", "/assets/site.css", "/no-such-page"])
func everyResponseCarriesTheSecurityHeaders(path: String) async throws {
    try await testApplication().test(.router) { client in
        try await client.execute(uri: path, method: .get) { response in
            let policy = try #require(response.headers[.contentSecurityPolicy])
            #expect(policy.contains("default-src 'none'"))
            #expect(!policy.contains("unsafe"))
            #expect(!policy.contains("http"))
            for field in SecurityHeadersMiddleware<BasicRequestContext>.headers {
                #expect(response.headers[field.name] == field.value)
            }
        }
    }
}

@Test func unknownPathsAreNotFound() async throws {
    try await testApplication().test(.router) { client in
        try await client.execute(uri: "/no-such-page", method: .get) { response in
            #expect(response.status == .notFound)
        }
    }
}

@Test func aMissingCatalogStopsStartUp() throws {
    var configuration = ServerConfiguration()
    configuration.catalogPath = "/nonexistent/Catalog.sqlite"
    configuration.logLevel = .warning
    #expect(
        throws: CatalogReadError(path: "/nonexistent/Catalog.sqlite", problem: "does not exist; run `make catalog`")
    ) { try buildApplication(configuration) }
}

@Test(arguments: [("/today", "Today"), ("/plans", "Plans"), ("/progress", "Progress"), ("/settings", "Settings")])
func sectionPagesMarkTheCurrentSection(path: String, title: String) async throws {
    try await testApplication().test(.router) { client in
        try await client.execute(uri: path, method: .get) { response in
            #expect(response.status == .ok)
            let body = String(buffer: response.body)
            #expect(body.contains("<title>\(title) · Day by Word</title>"))
            #expect(body.contains("<h1>\(title)</h1>"))
            #expect(body.contains(#"<a href="\#(path)" aria-current="page">\#(title)</a>"#))
            #expect(body.components(separatedBy: "aria-current").count == 2)
            #expect(body.contains(#"<nav aria-label="Sections">"#))
            #expect(body.contains("not affiliated with any church or denomination"))
        }
    }
}

@Test(arguments: ["/", "/today", "/no-such-page"])
func pagesLoadOnlyTheirOwnScriptsAndStyles(path: String) async throws {
    try await testApplication().test(.router) { client in
        try await client.execute(uri: path, method: .get) { response in
            let body = String(buffer: response.body)
            // Every script and stylesheet is an external file from this site, so
            // the CSP never needs 'unsafe-inline' (docs/web.md).
            #expect(!body.contains("<script>"))
            #expect(!body.contains("style="))
            #expect(!body.contains("http://"))
            #expect(!body.contains("https://"))
            #expect(body.contains(#"<script type="module" src="/assets/support.js"></script>"#))
            #expect(body.contains(#"<script nomodule defer src="/assets/unsupported.js"></script>"#))
            #expect(body.contains(#"id="browser-notice" role="note" hidden"#))
            #expect(body.contains("<noscript>"))
            #expect(body.contains(##"<a class="skip-link" href="#content">"##))
        }
    }
}

@Test func unknownPagesGetTheSitesNotFoundPage() async throws {
    try await testApplication().test(.router) { client in
        try await client.execute(uri: "/no-such-page", method: .get) { response in
            #expect(response.status == .notFound)
            #expect(response.headers[.contentType] == "text/html; charset=utf-8")
            let body = String(buffer: response.body)
            #expect(body.contains("<h1>Page not found</h1>"))
            #expect(!body.contains("aria-current"))
        }
        try await client.execute(uri: "/assets/no-such-file.css", method: .get) { response in
            #expect(response.status == .notFound)
        }
    }
}

@Test(arguments: [
    "/assets/support.js", "/assets/unsupported.js", "/assets/theme.js", "/assets/settings.js",
    "/assets/images/favicon-32.png",
])
func servesTheShellsAssets(path: String) async throws {
    try await testApplication().test(.router) { client in
        try await client.execute(uri: path, method: .get) { response in
            #expect(response.status == .ok)
        }
    }
}

/// Every address in docs/urls.md's table answers.
@Test(arguments: [
    "/", "/today", "/plans", "/plans/psalm-a-day", "/plans/psalm-a-day/week",
    "/plans/psalm-a-day/week?start=2027-01-04", "/plans/psalm-a-day/week?start=next-week", "/progress",
    "/settings",
])
func everyDocumentedAddressAnswers(path: String) async throws {
    try await testApplication().test(.router) { client in
        try await client.execute(uri: path, method: .get) { response in
            #expect(response.status == .ok)
        }
    }
}

/// Plan addresses with anything but a plan id are not found.
@Test(arguments: [
    "/plans/Psalm-a-day", "/plans/-psalm", "/plans/psalm--a-day", "/plans/psalm_a_day", "/plans/psalm%20a%20day",
    "/plans/Psalm/week", "/plans/psalm-a-day/month",
])
func otherPlanAddressesAreNotFound(path: String) async throws {
    try await testApplication().test(.router) { client in
        try await client.execute(uri: path, method: .get) { response in
            #expect(response.status == .notFound)
        }
    }
}

@Test func plansPagesSitInThePlansSection() async throws {
    try await testApplication().test(.router) { client in
        try await client.execute(uri: "/plans/psalm-a-day/week", method: .get) { response in
            let body = String(buffer: response.body)
            #expect(body.contains(#"<a href="/plans" aria-current="page">Plans</a>"#))
            #expect(body.contains(#"<a href="/plans/psalm-a-day">Plan</a>"#))
        }
    }
}

@Test func weekStartsAreKeptOnlyWhenTheyLookLikeDates() {
    #expect(Pages.startDate("2027-01-04") == "2027-01-04")
    #expect(Pages.startDate(nil) == nil)
    #expect(Pages.startDate("next-week") == nil)
    #expect(Pages.startDate("2027-1-4") == nil)
    #expect(Pages.startDate("2027/01/04") == nil)
    #expect(Pages.startDate("２０２７-01-04") == nil)
}

@Test func settingsOffersAppearanceReferenceSizeAndTheVersion() async throws {
    try await testApplication().test(.router) { client in
        try await client.execute(uri: "/settings", method: .get) { response in
            let body = String(buffer: response.body)
            for value in ["automatic", "light", "dark"] {
                #expect(body.contains(#"name="appearance" value="\#(value)""#))
            }
            for value in ["standard", "larger", "largest"] {
                #expect(body.contains(#"name="reference-size" value="\#(value)""#))
            }
            #expect(body.components(separatedBy: " checked>").count == 3)
            #expect(body.contains("<legend>Appearance</legend>"))
            #expect(body.contains("Development build"))
            #expect(body.contains("never sent to daybyword.com"))
            #expect(body.contains("not affiliated with any church or denomination"))
        }
    }
}

@Test func settingsShowsTheDeployedCommit() async throws {
    var configuration = ServerConfiguration()
    configuration.commit = "a333b3f0123456789abcdef"
    configuration.logLevel = .warning
    try await buildApplication(configuration).test(.router) { client in
        try await client.execute(uri: "/settings", method: .get) { response in
            #expect(String(buffer: response.body).contains("Version a333b3f01234"))
        }
    }
}
