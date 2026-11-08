import CatalogCompiler
import Foundation
import ReadingData
import Testing

// The export the server's PostgreSQL import reads (BUILD.md PM.14), pinned in
// tests/fixtures/catalog-export.json from an invented release catalog, so the
// TypeScript import tests read exactly what this compiler writes. Set
// DBW_RECORD_FIXTURES=1 to rewrite it, then review the diff.

/// Two invented plans, both reviewed and from a cleared source, compiled for
/// release: a sequence and a day-of-month plan.
func exportFixtureCatalog() throws -> (root: URL, catalog: URL, sources: SourcesRegistry) {
    let days = (1...31).map { "\($0)\tPRO \($0)" }.joined(separator: "\n")
    let monthly = planText(
        [
            "id": "monthly-plan", "title": "A monthly test plan", "schedule": "day-of-month",
            "behaviors": "calendar", "books": "PRO", "coverage": "books", "reading-days": "7",
            "review": "reviewed",
        ],
        schedule: days)
    let sequence = planText(["review": "reviewed"])
    let (root, source) = try fixtureCatalog(plans: ["test-plan.plan": sequence, "monthly-plan.plan": monthly])
    let catalog = root.appending(path: "Catalog.sqlite")
    try CatalogBuild.write(from: source, to: catalog, mode: .release)
    return (root, catalog, try CatalogBuild.readSources(from: source))
}

@Test func exportsTheCompiledCatalog() throws {
    let (root, catalog, sources) = try exportFixtureCatalog()
    defer { try? FileManager.default.removeItem(at: root) }
    let export = try CatalogExport(catalog: catalog, sources: sources)
    let checksum = try Database(path: catalog.path, access: .readOnly)
        .query("SELECT value FROM catalog_meta WHERE key = 'content_sha256'").first?["value"]

    #expect(export.format == "daybyword-catalog-export")
    #expect(export.schemaVersion == CatalogBuild.schemaVersion)
    #expect(export.buildMode == "release")
    #expect(checksum == .text(export.contentSha256))
    #expect(export.plans.map(\.id) == ["monthly-plan", "test-plan"])
    #expect(export.plans.allSatisfy { $0.rightsStatus == "cleared" })
    #expect(export.plans[0].assignments.count == 31)
    #expect(export.plans[1].assignments.map(\.reading) == ["MRK 1", "LUK 15:1-10; JHN 3:16"])
    #expect(export.scripture.map(\.name) == ["books.json", "versification/english.tsv"])
}

@Test func theSameCatalogExportsTheSameBytes() throws {
    let (root, catalog, sources) = try exportFixtureCatalog()
    defer { try? FileManager.default.removeItem(at: root) }
    let first = root.appending(path: "a.json")
    let second = root.appending(path: "b.json")
    try CatalogExport.write(catalog: catalog, sources: sources, to: first)
    try CatalogExport.write(catalog: catalog, sources: sources, to: second)
    #expect(try Data(contentsOf: first) == (try Data(contentsOf: second)))
}

@Test func theExportMatchesItsFixture() throws {
    let (root, catalog, sources) = try exportFixtureCatalog()
    defer { try? FileManager.default.removeItem(at: root) }
    let data = try CatalogExport(catalog: catalog, sources: sources).json()
    let url = catalogSource.deletingLastPathComponent().appending(path: "tests/fixtures/catalog-export.json")
    if ProcessInfo.processInfo.environment["DBW_RECORD_FIXTURES"] == "1" {
        try data.write(to: url, options: .atomic)
    }
    #expect(try Data(contentsOf: url) == data, "tests/fixtures/catalog-export.json is out of date")
}

@Test func refusesACatalogOfAnotherSchema() throws {
    let (root, catalog, sources) = try exportFixtureCatalog()
    defer { try? FileManager.default.removeItem(at: root) }
    let database = try Database(path: catalog.path, access: .readWrite)
    try database.run("UPDATE catalog_meta SET value = '2' WHERE key = 'schema_version'")
    #expect(throws: CatalogError.self) { try CatalogExport(catalog: catalog, sources: sources) }
}
