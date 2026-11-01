import CatalogCompiler
import Foundation
import ReadingData
import Testing

/// The repository's `catalog/` directory.
let catalogSource = URL(filePath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
    .appending(path: "catalog", directoryHint: .isDirectory)

func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("catalog-\(UUID().uuidString)")
}

@Test func writesTheCatalogMetadata() throws {
    let directory = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let output = directory.appendingPathComponent("Catalog.sqlite")

    try CatalogBuild.write(from: catalogSource, to: output, mode: .release)
    try CatalogBuild.write(from: catalogSource, to: output, mode: .development)

    let catalog = try Database(path: output.path, access: .readOnly)
    let rows = try catalog.query("SELECT key, value FROM catalog_meta ORDER BY key")
    #expect(rows.map { $0["key"] } == [.text("build_mode"), .text("schema_version")])
    #expect(rows.map { $0["value"] } == [.text("development"), .text(String(CatalogBuild.schemaVersion))])
    #expect(!FileManager.default.fileExists(atPath: output.path + ".partial"))
    #expect(
        try CatalogMetadata.read(path: output.path)
            == CatalogMetadata(schemaVersion: CatalogBuild.schemaVersion, buildMode: "development")
    )
}

@Test func readsTheRepositorysBookRegistry() throws {
    let registry = try CatalogBuild.readRegistry(from: catalogSource)
    #expect(registry.canons.map(\.id) == ["protestant", "catholic"])
}

@Test func aBrokenRegistryWritesNothing() throws {
    let directory = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let source = directory.appending(path: "catalog")
    let registry = source.appending(path: "scripture/books.json")
    try FileManager.default.createDirectory(
        at: registry.deletingLastPathComponent(), withIntermediateDirectories: true)
    let output = directory.appendingPathComponent("Catalog.sqlite")

    #expect(throws: CatalogError.self) { try CatalogBuild.write(from: source, to: output, mode: .development) }

    try Data(#"{ "format": 2, "conventions": [], "books": [], "canons": [], "sources": [] }"#.utf8).write(to: registry)
    let error = #expect(throws: CatalogError.self) {
        try CatalogBuild.write(from: source, to: output, mode: .development)
    }
    #expect(error?.problem == "format 2 is not format 1")
    #expect(!FileManager.default.fileExists(atPath: output.path))
}
