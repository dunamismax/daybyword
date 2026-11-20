import XCTest

/// The app tour (BUILD.md P2.12, PM.19): every section and Settings, in light
/// and dark, and in light at the largest accessibility text size (AX5). Each screen is attached to the test result, and when the test runner
/// is given DBW_SCREENSHOTS (make tour-app passes TEST_RUNNER_DBW_SCREENSHOTS),
/// it is also saved there as a PNG; screenshots/ is gitignored.
final class TourTests: XCTestCase {
    @MainActor
    func testTourInLightAndDark() throws {
        for (appearance, textSize) in [("light", ""), ("dark", ""), ("light", "ax5")] {
            let app = XCUIApplication()
            // The reader's own appearance choice (Settings) sets the theme.
            app.launchArguments = ["-appearance", appearance]
            if textSize == "ax5" {
                app.launchArguments += [
                    "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
                ]
            }
            let appearance = textSize.isEmpty ? appearance : "\(appearance)-\(textSize)"
            app.launch()

            XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))
            save(app, "\(appearance)-today")

            for section in ["Plans", "Progress"] {
                app.tabBars.buttons[section].tap()
                XCTAssertTrue(app.navigationBars[section].waitForExistence(timeout: 5))
                save(app, "\(appearance)-\(section.lowercased())")
            }

            app.open(try XCTUnwrap(URL(string: "daybyword://plans/psalm-a-day")))
            XCTAssertTrue(app.navigationBars["Plan"].waitForExistence(timeout: 10))
            save(app, "\(appearance)-plan")

            app.open(try XCTUnwrap(URL(string: "daybyword://plans/psalm-a-day/week")))
            XCTAssertTrue(app.navigationBars["Week"].waitForExistence(timeout: 10))
            save(app, "\(appearance)-week")

            app.open(try XCTUnwrap(URL(string: "daybyword://settings")))
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
            save(app, "\(appearance)-settings")
            app.navigationBars["Settings"].buttons["Done"].tap()

            app.terminate()
        }
    }

    @MainActor
    private func save(_ app: XCUIApplication, _ name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        guard let folder = ProcessInfo.processInfo.environment["DBW_SCREENSHOTS"], !folder.isEmpty else { return }
        let directory = URL(fileURLWithPath: folder)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? screenshot.pngRepresentation.write(to: directory.appendingPathComponent("\(name).png"))
    }
}
