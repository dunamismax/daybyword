import Testing

@testable import DayByWordWeb

@Test func defaultsServeLocallyInDevelopment() throws {
    let configuration = try ServerConfiguration(environment: [:])
    #expect(configuration == ServerConfiguration())
    #expect(configuration.environment == .development)
    #expect(configuration.host == "127.0.0.1")
    #expect(configuration.port == 8080)
    #expect(configuration.catalogPath == nil)
}

@Test func readsEveryVariable() throws {
    let configuration = try ServerConfiguration(environment: [
        "DBW_ENV": "production",
        "DBW_HOST": "0.0.0.0",
        "DBW_PORT": "4316",
        "DBW_PUBLIC_DIR": "/srv/www/daybyword.com/current/Public",
        "DBW_CATALOG": "/srv/www/daybyword.com/current/Catalog.sqlite",
        "LOG_LEVEL": "notice",
    ])
    #expect(configuration.environment == .production)
    #expect(configuration.host == "0.0.0.0")
    #expect(configuration.port == 4316)
    #expect(configuration.publicDirectory == "/srv/www/daybyword.com/current/Public")
    #expect(configuration.catalogPath == "/srv/www/daybyword.com/current/Catalog.sqlite")
    #expect(configuration.logLevel == .notice)
}

@Test(arguments: [
    ["DBW_ENV": "staging"],
    ["DBW_PORT": "eighty"],
    ["DBW_PORT": "70000"],
    ["DBW_HOST": ""],
    ["LOG_LEVEL": "loud"],
    ["DBW_ENV": "production"],
])
func rejectsSettingsItCannotUse(variables: [String: String]) {
    #expect(throws: ConfigurationError.self) { try ServerConfiguration(environment: variables) }
}
