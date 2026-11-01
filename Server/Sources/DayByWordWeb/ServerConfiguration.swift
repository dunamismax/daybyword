import Logging

/// The server's settings, read from the environment at start-up.
///
/// | Variable | Meaning | Default |
/// |---|---|---|
/// | `DBW_ENV` | `development` or `production` | `development` |
/// | `DBW_HOST` | the address to listen on | `127.0.0.1` |
/// | `DBW_PORT` | the port to listen on | `8080` |
/// | `DBW_PUBLIC_DIR` | the folder of static assets | `Public` |
/// | `DBW_CATALOG` | the compiled `Catalog.sqlite`, opened read-only | none; required in production |
/// | `DBW_COMMIT` | the deployed commit, shown in Settings | none: "Development build" |
/// | `LOG_LEVEL` | `trace` … `critical` | `info` |
public struct ServerConfiguration: Sendable, Equatable {
    public enum Environment: String, Sendable {
        case development
        case production
    }

    public var environment: Environment = .development
    public var host = "127.0.0.1"
    public var port = 8080
    public var publicDirectory = "Public"
    public var catalogPath: String?
    public var commit: String?
    public var logLevel = Logger.Level.info

    public init() {}

    /// Reads the settings from environment variables, rejecting values it does
    /// not understand rather than guessing.
    public init(environment variables: [String: String]) throws(ConfigurationError) {
        if let value = variables["DBW_ENV"] {
            guard let environment = Environment(rawValue: value) else {
                throw ConfigurationError("DBW_ENV must be development or production, not \(value)")
            }
            self.environment = environment
        }
        if let value = variables["DBW_HOST"] {
            guard !value.isEmpty else { throw ConfigurationError("DBW_HOST is empty") }
            host = value
        }
        if let value = variables["DBW_PORT"] {
            guard let port = Int(value), (1...65535).contains(port) else {
                throw ConfigurationError("DBW_PORT must be a port number, not \(value)")
            }
            self.port = port
        }
        if let value = variables["DBW_PUBLIC_DIR"], !value.isEmpty {
            publicDirectory = value
        }
        if let value = variables["DBW_CATALOG"], !value.isEmpty {
            catalogPath = value
        }
        if let value = variables["DBW_COMMIT"], !value.isEmpty {
            guard value.count <= 40, value.allSatisfy(\.isHexDigit) else {
                throw ConfigurationError("DBW_COMMIT must be a commit hash, not \(value)")
            }
            commit = value.lowercased()
        }
        if let value = variables["LOG_LEVEL"] {
            guard let level = Logger.Level(rawValue: value) else {
                throw ConfigurationError("LOG_LEVEL must be trace, debug, info, notice, warning, error, or critical")
            }
            logLevel = level
        }
        if self.environment == .production, catalogPath == nil {
            throw ConfigurationError("DBW_CATALOG is required in production")
        }
    }
}

/// A setting the server cannot start with.
public struct ConfigurationError: Error, Sendable, Equatable, CustomStringConvertible {
    public let description: String

    init(_ description: String) {
        self.description = description
    }
}
