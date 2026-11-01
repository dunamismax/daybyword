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

/// Every reading status has its own word and symbol, so color never carries the
/// meaning alone.
@Test func readingStatusesHaveDistinctWordsAndSymbols() {
    let labels = ReadingStatus.allCases.map { String(localized: $0.label) }
    let symbols = ReadingStatus.allCases.map(\.symbol)
    #expect(Set(labels).count == ReadingStatus.allCases.count)
    #expect(Set(symbols).count == ReadingStatus.allCases.count)
    #expect(labels.allSatisfy { !$0.isEmpty })
}

/// Time estimates always say they are estimates.
@Test func workloadSaysEstimatesVary() {
    #expect(String(localized: WorkloadLine.text(minutes: 1)) == "About 1 minute. Estimates vary.")
    #expect(String(localized: WorkloadLine.text(minutes: 12)) == "About 12 minutes. Estimates vary.")
}
