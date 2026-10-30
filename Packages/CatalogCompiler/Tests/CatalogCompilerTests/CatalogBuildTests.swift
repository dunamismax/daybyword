import CatalogCompiler
import Foundation
import ReadingData
import Testing

@Test func writesTheCatalogMetadata() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("catalog-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: directory) }
    let output = directory.appendingPathComponent("Catalog.sqlite")

    try CatalogBuild.write(to: output, mode: .release)
    try CatalogBuild.write(to: output, mode: .development)

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
