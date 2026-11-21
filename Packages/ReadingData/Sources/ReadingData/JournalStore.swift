import Foundation
import ReadingEngine

/// The reader's journal on the device: every event they made, in its wire
/// form, in one SQLite file (docs/engine.md, "The journal"; E3, E8). It
/// only ever adds events. Writing an event a second time, as a retry does,
/// changes nothing, because an event is its id. The one removal is the
/// reader's own request to delete their data (`deleteEverything`).
///
/// A store is one connection, so it is not `Sendable`: the app keeps it on
/// the main actor.
public final class JournalStore {
    private let database: Database

    /// The schema this build writes, in `PRAGMA user_version`.
    public static let schemaVersion = 1

    /// Opens the journal at `path`, creating it when it does not exist.
    public init(path: String) throws {
        database = try Database(path: path, access: .create)
        try migrate()
    }

    /// A journal that lives only in memory, for tests and previews.
    public static func inMemory() throws -> JournalStore {
        try JournalStore(path: ":memory:")
    }

    private func migrate() throws {
        let version = try database.query("PRAGMA user_version").first?["user_version"]
        guard case .integer(let found) = version else {
            throw SQLiteError(code: 0, message: "the journal has no user_version")
        }
        switch found {
        case 0:
            try database.execute(
                """
                CREATE TABLE events (id TEXT PRIMARY KEY, wire TEXT NOT NULL) STRICT;
                PRAGMA user_version = \(Self.schemaVersion);
                """)
        case Int64(Self.schemaVersion):
            break
        default:
            throw SQLiteError(
                code: 0,
                message: "the journal has schema \(found), but this build reads schema \(Self.schemaVersion)")
        }
    }

    /// Every event, in journal order (by id).
    public func events() throws -> [JournalEvent] {
        let values = try database.query("SELECT wire FROM events ORDER BY id").map { row -> JSONValue in
            guard case .text(let wire) = row["wire"] else {
                throw SQLiteError(code: 0, message: "an event in the journal has no wire form")
            }
            return try JSONDecoder().decode(JSONValue.self, from: Data(wire.utf8))
        }
        return try JournalEvent.events(wire: values)
    }

    /// Adds events, all or none. An event already in the journal, by id, is
    /// left as it is.
    public func append(_ events: [JournalEvent]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        try database.transaction {
            for event in events {
                let wire = String(decoding: try encoder.encode(event.wire), as: UTF8.self)
                try database.run(
                    "INSERT INTO events (id, wire) VALUES (?, ?) ON CONFLICT (id) DO NOTHING",
                    [.text(event.id.rawValue), .text(wire)])
            }
        }
    }

    /// Removes every event, at the reader's request (docs/product.md,
    /// Settings: "delete all data").
    public func deleteEverything() throws {
        try database.run("DELETE FROM events")
        try database.execute("VACUUM")
    }
}
