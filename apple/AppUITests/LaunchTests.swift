import XCTest

/// The app launches to Today.
final class LaunchTests: XCTestCase {
    @MainActor
    func testLaunchesToToday() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Your next reading will appear here."].exists)
    }
}
