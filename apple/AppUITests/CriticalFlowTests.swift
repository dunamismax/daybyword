import XCTest

/// The app's critical flows that other UI tests do not already walk
/// (BUILD.md P17.10): choosing a plan from the questions, starting toward a
/// finish date, Today's other ways to mark, the welcome back after a gap,
/// deleting everything, and sharing a week as a PDF. LaunchTests covers
/// launching, the sections, links, export, the streak and History.
final class CriticalFlowTests: XCTestCase {
    @MainActor
    private func launch(today: String, fresh: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-today", today] + (fresh ? ["-freshJournal", "YES"] : [])
        app.launch()
        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))
        return app
    }

    /// Scrolls until the element can be tapped (a Form or list builds rows as
    /// they come into view).
    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, up: Bool = true) {
        var swipes = 0
        while !(element.exists && element.isHittable), swipes < 10 {
            if up { app.swipeUp() } else { app.swipeDown() }
            swipes += 1
        }
    }

    /// Starts Gospels at your pace from its page, as a reader does.
    @MainActor
    private func startGospels(_ app: XCUIApplication) throws {
        app.open(try XCTUnwrap(URL(string: "daybyword://plans/gospels-at-your-pace")))
        let start = app.buttons["Start this plan"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        let confirm = app.buttons["Start"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 10))
        confirm.tap()
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.buttons["Mark read"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testChoosingAPlanFromTheQuestions() throws {
        let app = launch(today: "2027-03-01")
        app.tabBars.buttons["Plans"].tap()
        XCTAssertTrue(app.navigationBars["Plans"].waitForExistence(timeout: 10))
        let question = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "What do you hope to read?"))
            .firstMatch
        reveal(question, in: app)
        question.tap()
        let gospels = app.buttons["The Gospels"]
        XCTAssertTrue(gospels.waitForExistence(timeout: 5))
        gospels.tap()

        // A few plans, each with its reason, and the first opens its page.
        let suggestion = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Gospels at your pace"))
            .firstMatch
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5), app.debugDescription)
        reveal(suggestion, in: app)
        suggestion.tap()
        XCTAssertTrue(app.buttons["Start this plan"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testStartingTowardAFinishDate() throws {
        let app = launch(today: "2027-03-01")
        app.open(try XCTUnwrap(URL(string: "daybyword://plans/gospels-at-your-pace")))
        let start = app.buttons["Start this plan"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        let finishDate = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Work toward a finish date"))
            .firstMatch
        reveal(finishDate, in: app)
        finishDate.tap()
        // The finish date and its load are shown before anything starts.
        let finishBy = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Finish by"))
            .firstMatch
        reveal(finishBy, in: app)
        XCTAssertTrue(finishBy.exists, app.debugDescription)
        app.buttons["Start"].tap()
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.buttons["Mark read"].waitForExistence(timeout: 10))
        XCTAssertTrue(
            app.staticTexts["Matthew, chapters 1 to 3"].exists || app.otherElements["Matthew, chapters 1 to 3"].exists)
    }

    @MainActor
    func testTodaysOtherWaysToMark() throws {
        let app = launch(today: "2027-03-01")
        try startGospels(app)

        // Part read, then taken back.
        app.buttons["More"].tap()
        app.buttons["Mark part read"].tap()
        let undo = app.buttons["Undo"].firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 10))
        undo.tap()
        XCTAssertTrue(app.buttons["Mark read"].waitForExistence(timeout: 10))

        // Skip, confirmed: the next reading becomes today's, not marked read.
        app.buttons["More"].tap()
        app.buttons["Skip this reading…"].tap()
        let skip = app.buttons["Skip this reading"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        skip.tap()
        let next = app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@", "Matthew, chapters 4 to 5")
        ).firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 10), app.debugDescription)

        // Log an earlier day: kept on the day it was read.
        app.buttons["More"].tap()
        app.buttons["Log an earlier day…"].tap()
        let log = app.buttons["Log"]
        XCTAssertTrue(log.waitForExistence(timeout: 5))
        log.tap()
        XCTAssertTrue(app.buttons["Undo"].firstMatch.waitForExistence(timeout: 10), app.debugDescription)
    }

    @MainActor
    func testWelcomeBackAfterAGap() throws {
        var app = launch(today: "2027-03-01")
        try startGospels(app)
        app.buttons["Mark read"].tap()
        XCTAssertTrue(app.buttons["Undo"].firstMatch.waitForExistence(timeout: 10))
        app.terminate()

        // Ten days later: welcomed back, offered choices, each previewed.
        app = launch(today: "2027-03-11", fresh: false)
        XCTAssertTrue(app.staticTexts["Welcome back. Here's where you left off."].waitForExistence(timeout: 10))
        let carryOn = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Continue from where I left off"))
            .firstMatch
        XCTAssertTrue(carryOn.exists, app.debugDescription)
        carryOn.tap()
        let confirm = app.buttons["Confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 10))
        confirm.tap()
        // History is not rewritten: the next unread reading is today's.
        XCTAssertTrue(app.buttons["Mark read"].waitForExistence(timeout: 10))
        let next = app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@", "Matthew, chapters 4 to 5")
        ).firstMatch
        XCTAssertTrue(next.exists, app.debugDescription)
    }

    @MainActor
    func testDeletingEverything() throws {
        let app = launch(today: "2027-03-01")
        try startGospels(app)
        app.navigationBars["Today"].buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        let delete = app.buttons["Delete everything on this device"]
        reveal(delete, in: app)
        delete.tap()
        let confirm = app.buttons["Delete everything"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        app.navigationBars["Settings"].buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Your next reading will appear here."].waitForExistence(timeout: 10))
    }

    @MainActor
    func testAWeekSharesAsAPDF() throws {
        let app = launch(today: "2027-03-01")
        app.open(try XCTUnwrap(URL(string: "daybyword://plans/gospels-at-your-pace/week")))
        XCTAssertTrue(app.navigationBars["Week"].waitForExistence(timeout: 10))
        app.navigationBars["Week"].buttons["Share as PDF"].tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 10), app.debugDescription)
    }
}
