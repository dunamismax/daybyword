import Foundation
import ReadingData
import Testing

@Test func linksSQLite3() {
    #expect(Database.libraryVersion.hasPrefix("3."))
}

@Test func roundTripsEveryKindOfValue() throws {
    let database = try Database.inMemory()
    try database.execute("CREATE TABLE item (n INTEGER, r REAL, t TEXT, b BLOB, z)")
    try database.run(
        "INSERT INTO item VALUES (?, ?, ?, ?, ?)",
        [.integer(-42), .real(2.5), .text("Psalm 119 · ünïcode"), .blob([0, 1, 255]), .null]
    )
    let rows = try database.query("SELECT n, r, t, b, z FROM item")
    #expect(rows.count == 1)
    #expect(rows[0].columns == ["n", "r", "t", "b", "z"])
    #expect(rows[0]["n"] == .integer(-42))
    #expect(rows[0]["r"] == .real(2.5))
    #expect(rows[0]["t"] == .text("Psalm 119 · ünïcode"))
    #expect(rows[0]["b"] == .blob([0, 1, 255]))
    #expect(rows[0]["z"] == .null)
    #expect(rows[0]["missing"] == nil)
}

@Test func rollsBackAFailedTransaction() throws {
    let database = try Database.inMemory()
    try database.execute("CREATE TABLE item (n INTEGER NOT NULL)")
    #expect(throws: SQLiteError.self) {
        try database.transaction {
            try database.run("INSERT INTO item VALUES (1)")
            try database.run("INSERT INTO item VALUES (NULL)")
        }
    }
    #expect(try database.query("SELECT count(*) AS c FROM item")[0]["c"] == .integer(0))
}

@Test func reportsBadSQL() throws {
    let database = try Database.inMemory()
    #expect(throws: SQLiteError.self) { try database.query("SELECT FROM nowhere") }
}

@Test func readOnlyRefusesWrites() throws {
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("readingdata-\(UUID().uuidString).sqlite").path
    defer { try? FileManager.default.removeItem(atPath: path) }
    try Database(path: path, access: .create).execute("CREATE TABLE item (n INTEGER)")

    let readOnly = try Database(path: path, access: .readOnly)
    #expect(throws: SQLiteError.self) { try readOnly.run("INSERT INTO item VALUES (1)") }
    #expect(throws: SQLiteError.self) { try Database(path: path + ".missing", access: .readOnly) }
}

@Test func aMissingCatalogSaysWhatToDo() {
    let path = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString).sqlite").path
    #expect(throws: CatalogReadError(path: path, problem: "does not exist; run `make catalog`")) {
        try Catalog(path: path)
    }
}

@Test func aCatalogOfAnotherSchemaIsRefused() throws {
    let path = FileManager.default.temporaryDirectory.appendingPathComponent("old-\(UUID().uuidString).sqlite").path
    defer { try? FileManager.default.removeItem(atPath: path) }
    let database = try Database(path: path, access: .create)
    try database.execute(
        """
        CREATE TABLE catalog_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL) STRICT;
        INSERT INTO catalog_meta VALUES ('schema_version', '0'), ('build_mode', 'development');
        """)
    let problem =
        "has schema 0, but this build reads schema \(CatalogMetadata.currentSchemaVersion); run `make catalog`"
    #expect(throws: CatalogReadError(path: path, problem: problem)) { try Catalog(path: path) }
}
