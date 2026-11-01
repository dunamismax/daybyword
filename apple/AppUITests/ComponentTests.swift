import XCTest

/// The shared components in the debug gallery, as VoiceOver meets them.
final class ComponentTests: XCTestCase {
    @MainActor
    func testReferencesAndStatusesReadNaturally() {
        let app = XCUIApplication()
        app.launchArguments = ["-componentGallery"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Components"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Mark, chapter 4, verses 1 to 20"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["Reading 30, Mark, chapter 3, verses 20 to 35, Read"].exists)
        XCTAssertTrue(app.buttons["Copy reference"].exists)
    }
}
