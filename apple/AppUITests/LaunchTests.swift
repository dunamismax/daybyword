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

    /// A plan's history (P11.5): a reading's state, Undo, and the plan
    /// paused, resumed, stopped and followed again, each moving it between
    /// Progress's groups.
    @MainActor
    func testHistoryUndoesAndPausesAndStops() throws {
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

        app.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(app.staticTexts["Reading now"].waitForExistence(timeout: 10))
        func openHistory() {
            let history = app.buttons["History"]
            var swipes = 0
            while !history.isHittable, swipes < 6 {
                app.swipeUp()
                swipes += 1
            }
            history.tap()
            XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 10))
        }
        func tapInHistory(_ label: String) {
            let button = app.buttons[label].firstMatch
            var swipes = 0
            while !button.isHittable, swipes < 10 {
                app.swipeUp()
                swipes += 1
            }
            button.tap()
        }

        // History's rows are made as they scroll into view.
        func reveal(_ element: XCUIElement) -> Bool {
            var swipes = 0
            while !(element.exists && element.isHittable), swipes < 10 {
                app.swipeUp()
                swipes += 1
            }
            return element.exists
        }
        func backToTop() {
            let first = app.staticTexts["Reading 1"]
            var swipes = 0
            while !(first.exists && first.isHittable), swipes < 15 {
                app.swipeDown()
                swipes += 1
            }
        }

        openHistory()
        let reading = app.staticTexts["Read on Monday, March 1"]
        XCTAssertTrue(reading.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(reveal(app.staticTexts["Marked Matthew 1–3 read on Monday, March 1."]))
        backToTop()
        app.buttons["Undo"].firstMatch.tap()
        XCTAssertTrue(reveal(app.staticTexts["Took back: Marked Matthew 1–3 read on Monday, March 1."]))
        XCTAssertFalse(reading.exists)
        backToTop()

        tapInHistory("Pause this plan")
        XCTAssertTrue(app.buttons["Resume this plan"].waitForExistence(timeout: 10))
        app.navigationBars["History"].buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Paused"].waitForExistence(timeout: 10))

        openHistory()
        tapInHistory("Resume this plan")
        tapInHistory("Stop following this plan")
        // The confirmation's own button: the list's is covered by it.
        let stops = app.buttons.matching(NSPredicate(format: "label == %@", "Stop following this plan"))
        let asked = expectation(for: NSPredicate(format: "count >= 2"), evaluatedWith: stops)
        wait(for: [asked], timeout: 10)
        let confirmStop = (0..<stops.count).map { stops.element(boundBy: $0) }.first { $0.isHittable }
        try XCTUnwrap(confirmStop).tap()
        XCTAssertTrue(reveal(app.buttons["Follow this plan again"]))
        app.navigationBars["History"].buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Stopped"].waitForExistence(timeout: 10))

        openHistory()
        tapInHistory("Follow this plan again")
        app.navigationBars["History"].buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Reading now"].waitForExistence(timeout: 10))
    }
}
