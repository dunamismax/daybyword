import Foundation
import Hummingbird
import HummingbirdTesting
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
    #expect(throws: (any Error).self) { try buildApplication(configuration) }
}
