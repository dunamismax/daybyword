import DayByWordWeb
import Foundation

// Reads the configuration from the environment, builds the application, and
// serves until SIGTERM or SIGINT, when Hummingbird shuts down gracefully.
let configuration: ServerConfiguration
do {
    configuration = try ServerConfiguration(environment: ProcessInfo.processInfo.environment)
} catch {
    FileHandle.standardError.write(Data("DayByWordServer: \(error)\n".utf8))
    exit(1)
}

let app = try buildApplication(configuration)
try await app.runService()
