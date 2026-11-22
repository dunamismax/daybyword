import XCTest

/// The App Store's screenshots (BUILD.md P16.7): Today, Plans, a plan's page,
/// Progress and a week, in light and dark, on whichever simulator runs it
/// (make app-store-screenshots runs the 6.9-inch iPhone and the 13-inch iPad).
/// The record behind them is real: two plans started and four days read
/// through the app's own buttons, so no screen shows an empty state.
///
/// It runs only when the test runner is given DBW_APP_STORE_SCREENSHOTS (a
/// folder), and saves each screen there as a PNG; screenshots/ is gitignored.
final class AppStoreScreenshots: XCTestCase {
    /// Monday 1 March 2027 to Thursday 4 March: the days read.
    private let readDays = ["2027-03-01", "2027-03-02", "2027-03-03", "2027-03-04"]
    /// Friday 5 March, the day the screenshots show.
    private let shownDay = "2027-03-05"

    @MainActor
    func testAppStoreScreenshots() throws {
        guard let folder = ProcessInfo.processInfo.environment["DBW_APP_STORE_SCREENSHOTS"], !folder.isEmpty else {
            throw XCTSkip("Set DBW_APP_STORE_SCREENSHOTS to a folder (make app-store-screenshots).")
        }
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"

        // Two plans, each started in its own launch: opening a daybyword://
        // link launches the app again with its arguments, so -freshJournal
        // is given only to the first.
        for (index, plan) in ["gospels-at-your-pace", "proverbs-through-the-month"].enumerated() {
            let app = launch(on: readDays[0], appearance: "light", fresh: index == 0)
            app.open(try XCTUnwrap(URL(string: "daybyword://plans/\(plan)")))
            let start = app.buttons["Start this plan"]
            XCTAssertTrue(start.waitForExistence(timeout: 10), plan)
            start.tap()
            let confirm = app.buttons["Start"]
            XCTAssertTrue(confirm.waitForExistence(timeout: 10), plan)
            confirm.tap()
            XCTAssertTrue(start.waitForNonExistence(timeout: 10), plan)
            app.terminate()
        }

        // Four days read, each day's readings marked on Today.
        for day in readDays {
            let app = launch(on: day, appearance: "light", fresh: false)
            XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))
            var marked = 0
            let markRead = app.buttons["Mark read"].firstMatch
            while markRead.waitForExistence(timeout: 3), marked < 4 {
                var swipes = 0
                while !markRead.isHittable, swipes < 4 {
                    app.swipeUp()
                    swipes += 1
                }
                markRead.tap()
                marked += 1
            }
            XCTAssertEqual(marked, 2, "\(day): both plans' readings marked")
            app.terminate()
        }

        // The screens, on the fifth day, with its readings still to read.
        let directory = URL(fileURLWithPath: folder).appendingPathComponent(device)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for appearance in ["light", "dark"] {
            let app = launch(on: shownDay, appearance: appearance, fresh: false)
            XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))
            XCTAssertTrue(app.buttons["Mark read"].firstMatch.waitForExistence(timeout: 10), "Today shows readings")
            save(app, "\(appearance)-1-today", in: directory)

            for (number, route, title) in [
                (2, "plans/gospels-at-your-pace", "Plan"),
                (3, "progress", "Progress"),
                (4, "plans", "Plans"),
                (5, "plans/gospels-at-your-pace/week", "Week"),
            ] {
                app.open(try XCTUnwrap(URL(string: "daybyword://\(route)")))
                XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10), route)
                save(app, "\(appearance)-\(number)-\(route.split(separator: "/").last ?? "")", in: directory)
            }
            app.terminate()
        }
    }

    @MainActor
    private func launch(on day: String, appearance: String, fresh: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-today", day, "-appearance", appearance] + (fresh ? ["-freshJournal", "YES"] : [])
        app.launch()
        return app
    }

    @MainActor
    private func save(_ app: XCUIApplication, _ name: String, in directory: URL) {
        // Let a pushed screen finish arriving.
        _ = app.wait(for: .runningForeground, timeout: 2)
        Thread.sleep(forTimeInterval: 1)
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        try? screenshot.pngRepresentation.write(to: directory.appendingPathComponent("\(name).png"))
    }
}
