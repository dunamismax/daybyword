import Foundation
import ReadingData
import ReadingEngine
import Testing

@testable import DayByWord

/// The app links the shared packages and can reach them.
@Test func linksTheSharedPackages() {
    #expect(ReadingEngine.specificationVersion == 0)
    #expect(Database.libraryVersion.hasPrefix("3."))
}

/// make catalog copies the compiled catalog into the app bundle.
@Test func bundlesTheCatalog() throws {
    let url = try #require(Bundle.main.url(forResource: "Catalog", withExtension: "sqlite"))
    let metadata = try CatalogMetadata.read(path: url.path)
    #expect(metadata.schemaVersion == 0)
}
