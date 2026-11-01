import XCTest

/// The app launches to Today, and the shell reaches every section.
final class LaunchTests: XCTestCase {
    @MainActor
    func testLaunchesToToday() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Your next reading will appear here."].exists)
    }

    @MainActor
    func testVisitsEverySectionAndSettings() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))

        app.tabBars.buttons["Plans"].tap()
        XCTAssertTrue(app.navigationBars["Plans"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(app.navigationBars["Progress"].waitForExistence(timeout: 5))

        app.navigationBars["Progress"].buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Appearance"].exists || app.staticTexts["Appearance"].exists)
        XCTAssertTrue(app.buttons["Reference text size"].exists || app.staticTexts["Reference text size"].exists)
        XCTAssertTrue(app.staticTexts["Mark, chapter 4, verses 1 to 20"].exists)
        XCTAssertTrue(app.staticTexts["Version"].exists)
        app.navigationBars["Settings"].buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Progress"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOpensDayByWordLinks() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))

        app.open(try XCTUnwrap(URL(string: "daybyword://plans/psalm-a-day")))
        XCTAssertTrue(app.navigationBars["Plan"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Plan"].buttons["Plans"].exists)

        app.open(try XCTUnwrap(URL(string: "daybyword://settings")))
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
    }
}
