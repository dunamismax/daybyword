import Foundation
import ReadingData

/// Writes a compiled catalog database.
///
/// For now this writes only the catalog's metadata, so that the app and the
/// server can be wired to a real `Catalog.sqlite` from the start. Plans,
/// validation, and calendars arrive with BUILD.md Phase 4 (P4.3).
public enum CatalogBuild {
    /// How strictly the catalog is built. Release builds refuse uncleared
    /// sources (BUILD.md P4.3); development builds may include them.
    public enum Mode: String, Sendable {
        case development
        case release
    }

    /// The version of the catalog's database schema.
    public static let schemaVersion = 0

    /// Builds the catalog and writes it to `output`, replacing any file there
    /// only once the new one is complete.
    public static func write(to output: URL, mode: Mode) throws {
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

    /// The metadata written into every catalog, in a fixed order so that two
    /// builds of the same sources write the same rows.
    static func metadata(mode: Mode) -> [(String, String)] {
        [
            ("schema_version", String(schemaVersion)),
            ("build_mode", mode.rawValue),
        ]
    }
}
