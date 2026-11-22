import XCTest

/// The app launches to Today, and the shell reaches every section.
final class LaunchTests: XCTestCase {
    @MainActor
    func testLaunchesToToday() {
        let app = XCUIApplication()
        app.launchArguments = ["-freshJournal", "YES"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Your next reading will appear here."].exists)
    }

    @MainActor
    func testVisitsEverySectionAndSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["-freshJournal", "YES"]
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
        // The list builds rows as they scroll into view.
        var swipes = 0
        while !app.staticTexts["Version"].exists, swipes < 8 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(app.staticTexts["Version"].exists)
        app.navigationBars["Settings"].buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Progress"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testOpensDayByWordLinks() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-freshJournal", "YES"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))

        app.open(try XCTUnwrap(URL(string: "daybyword://plans/psalm-a-day")))
        XCTAssertTrue(app.navigationBars["Plan"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Plan"].buttons["Plans"].exists)

        app.open(try XCTUnwrap(URL(string: "daybyword://settings")))
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
    }

    /// Export opens the share sheet with the reading record (P8.13).
    @MainActor
    func testExportOpensTheShareSheet() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-freshJournal", "YES"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))

        app.open(try XCTUnwrap(URL(string: "daybyword://settings")))
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        let export = app.buttons["Export my reading record"]
        var swipes = 0
        while !export.isHittable, swipes < 8 {
            app.swipeUp()
            swipes += 1
        }
        export.tap()

        // The system's share sheet over Settings, named for the file it
        // shares. (SwiftUI's ShareLink closed Settings instead; ShareSheet.)
        let sheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 10), app.debugDescription)
        let named = app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@", "Day by Word reading record"))
        XCTAssertTrue(named.firstMatch.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }

    /// The reading days in a row (D17, P11.3): off until the reader turns it
    /// on in Settings, then small on Progress.
    @MainActor
    func testTheStreakShowsOnlyWhenTurnedOn() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-freshJournal", "YES", "-today", "2027-03-01"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))

        app.open(try XCTUnwrap(URL(string: "daybyword://plans/gospels-at-your-pace")))
        let start = app.buttons["Start this plan"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        let confirm = app.buttons["Start"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 10))
        confirm.tap()
        app.tabBars.buttons["Today"].tap()
        let markRead = app.buttons["Mark read"]
        XCTAssertTrue(markRead.waitForExistence(timeout: 10))
        markRead.tap()

        let inARow = app.staticTexts["1 reading day in a row"]
        app.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(app.staticTexts["Recent days"].waitForExistence(timeout: 10))
        XCTAssertFalse(inARow.exists)

        // From the toolbar: opening daybyword://settings would launch the
        // app again with its fresh journal.
        func flipTheSetting() throws {
            app.navigationBars["Progress"].buttons["Settings"].tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
            let toggle = app.switches["Show reading days in a row on Progress"]
            var swipes = 0
            while !toggle.isHittable, swipes < 8 {
                app.swipeUp()
                swipes += 1
            }
            toggle.switches.firstMatch.tap()
            app.navigationBars["Settings"].buttons["Done"].tap()
        }

        try flipTheSetting()
        app.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(inARow.waitForExistence(timeout: 10), app.debugDescription)
        // Leave it as the next test expects: off.
        try flipTheSetting()
        XCTAssertFalse(inARow.waitForExistence(timeout: 2))
    }
}
