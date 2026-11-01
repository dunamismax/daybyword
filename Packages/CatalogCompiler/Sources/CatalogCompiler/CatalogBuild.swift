import Foundation
import ReadingData
import ReadingEngine

/// Writes a compiled catalog database.
///
/// For now this checks the book registry (`scripture/books.json`), the
/// versification schemes (`scripture/versification/`), and the word counts
/// (`scripture/words/`) and writes
/// only the catalog's metadata, so that the app and the server can be wired
/// to a real `Catalog.sqlite` from the start. Plans, the rest of validation,
/// and calendars arrive with BUILD.md Phase 4 (P4.3).
public enum CatalogBuild {
    /// How strictly the catalog is built. Release builds refuse uncleared
    /// sources (BUILD.md P4.3); development builds may include them.
    public enum Mode: String, Sendable {
        case development
        case release
    }

    /// The version of the catalog's database schema.
    public static let schemaVersion = 0

    /// Builds the catalog from the `catalog/` directory at `source` and writes
    /// it to `output`, replacing any file there only once the new one is
    /// complete. A source that fails its checks writes nothing.
    public static func write(from source: URL, to output: URL, mode: Mode) throws {
        let registry = try readRegistry(from: source)
        let schemes = try readVersifications(from: source, registry: registry)
        _ = try readWordCounts(from: source, versification: schemes[.english]!)
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: output.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let partial = output.appendingPathExtension("partial")
        try? fileManager.removeItem(at: partial)

        do {
            let database = try Database(path: partial.path, access: .create)
            try database.execute(
                """
                PRAGMA journal_mode = DELETE;
                CREATE TABLE catalog_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL) STRICT;
                """
            )
            try database.transaction {
                for (key, value) in metadata(mode: mode) {
                    try database.run("INSERT INTO catalog_meta (key, value) VALUES (?, ?)", [.text(key), .text(value)])
                }
            }
        } catch {
            try? fileManager.removeItem(at: partial)
            throw error
        }

        if fileManager.fileExists(atPath: output.path) {
            _ = try fileManager.replaceItemAt(output, withItemAt: partial)
        } else {
            try fileManager.moveItem(at: partial, to: output)
        }
    }

    /// Reads and checks the book registry under `source`.
    public static func readRegistry(from source: URL) throws -> BookRegistry {
        let url = source.appending(path: "scripture/books.json")
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw CatalogError(file: url, problem: "cannot be read (\(error.localizedDescription))")
        }
        do {
            return try BookRegistry(json: data)
        } catch let error as BookRegistryError {
            throw CatalogError(file: url, problem: error.description)
        }
    }

    /// Reads every versification scheme under `source` and checks each against
    /// the registry.
    public static func readVersifications(
        from source: URL, registry: BookRegistry
    ) throws -> [Versification.Scheme: Versification] {
        var schemes: [Versification.Scheme: Versification] = [:]
        for scheme in Versification.Scheme.allCases {
            let url = source.appending(path: "scripture/versification/\(scheme.rawValue).tsv")
            let text: String
            do {
                text = try String(contentsOf: url, encoding: .utf8)
            } catch {
                throw CatalogError(file: url, problem: "cannot be read (\(error.localizedDescription))")
            }
            do {
                let versification = try Versification(scheme: scheme, tsv: text)
                try versification.check(against: registry)
                schemes[scheme] = versification
            } catch let error as VersificationError {
                throw CatalogError(file: url, problem: error.description)
            }
        }
        return schemes
    }

    /// Reads the word counts under `source` and checks them against the
    /// scheme they are numbered by.
    public static func readWordCounts(from source: URL, versification: Versification) throws -> WordCounts {
        let url = source.appending(path: "scripture/words/web.tsv")
        let text: String
        do {
            text = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw CatalogError(file: url, problem: "cannot be read (\(error.localizedDescription))")
        }
        do {
            return try WordCounts(tsv: text, versification: versification)
        } catch {
            throw CatalogError(file: url, problem: error.description)
        }
    }

    /// The metadata written into every catalog, in a fixed order so that two
    /// builds of the same sources write the same rows.
    static func metadata(mode: Mode) -> [(String, String)] {
        [
            ("schema_version", String(schemaVersion)),
            ("build_mode", mode.rawValue),
        ]
    }
}

/// A problem in the catalog's sources, naming the file it is in.
public struct CatalogError: Error, CustomStringConvertible, Equatable {
    public let file: URL
    public let problem: String

    public var description: String { "\(file.path): \(problem)" }
}
