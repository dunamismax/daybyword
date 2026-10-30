import ReadingData
import ReadingEngine
import Testing

@testable import DayByWord

/// The app links the shared packages and can reach them.
@Test func linksTheSharedPackages() {
    #expect(ReadingEngine.specificationVersion == 0)
    #expect(Database.libraryVersion.hasPrefix("3."))
}
