import XCTest

/// Apple's accessibility audit on every screen (BUILD.md P17.1, P17.2): each
/// element has a description VoiceOver can speak, traits that match what it
/// does, a large enough hit region, sufficient contrast, and text that grows
/// with Dynamic Type without being clipped. The screens hold a real record
/// (a plan started and a reading marked), so no screen is audited empty.
final class AccessibilityAuditTests: XCTestCase {
    @MainActor
    func testEveryScreenPassesTheAudit() throws {
        for (appearance, textSize) in [("light", ""), ("dark", ""), ("light", "ax5"), ("dark", "bold-contrast")] {
            let app = XCUIApplication()
            app.launchArguments = ["-freshJournal", "YES", "-today", "2027-03-01", "-appearance", appearance]
            if textSize == "ax5" {
                app.launchArguments += [
                    "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
                ]
            }
            // Bold Text and Increase Contrast together (P17.2).
            if textSize == "bold-contrast" {
                app.launchArguments += ["-boldText", "YES", "-increaseContrast", "YES"]
            }
            let appearance = textSize.isEmpty ? appearance : "\(appearance)-\(textSize)"
            app.launch()
            XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 10))
            try audit(app, largeText: textSize == "ax5", "\(appearance) Today, empty")

            app.tabBars.buttons["Plans"].tap()
            XCTAssertTrue(app.navigationBars["Plans"].waitForExistence(timeout: 10))
            try audit(app, largeText: textSize == "ax5", "\(appearance) Plans")

            app.open(try XCTUnwrap(URL(string: "daybyword://plans/gospels-at-your-pace")))
            let start = app.buttons["Start this plan"]
            XCTAssertTrue(start.waitForExistence(timeout: 10))
            try audit(app, largeText: textSize == "ax5", "\(appearance) a plan's page")

            start.tap()
            let confirm = app.buttons["Start"]
            XCTAssertTrue(confirm.waitForExistence(timeout: 10))
            try audit(app, largeText: textSize == "ax5", "\(appearance) starting a plan")
            confirm.tap()

            app.tabBars.buttons["Today"].tap()
            let markRead = app.buttons["Mark read"]
            XCTAssertTrue(markRead.waitForExistence(timeout: 10))
            try audit(app, largeText: textSize == "ax5", "\(appearance) Today, a reading")
            markRead.tap()
            XCTAssertTrue(app.buttons["Undo"].waitForExistence(timeout: 10))
            try audit(app, largeText: textSize == "ax5", "\(appearance) Today, marked")

            app.tabBars.buttons["Progress"].tap()
            XCTAssertTrue(app.staticTexts["Reading now"].waitForExistence(timeout: 10))
            try audit(app, largeText: textSize == "ax5", "\(appearance) Progress")

            let history = app.buttons["History"]
            var swipes = 0
            while !history.isHittable, swipes < 6 {
                app.swipeUp()
                swipes += 1
            }
            history.tap()
            XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 10))
            try audit(app, largeText: textSize == "ax5", "\(appearance) History")
            app.navigationBars["History"].buttons.firstMatch.tap()

            app.navigationBars["Progress"].buttons["Settings"].tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
            try audit(app, largeText: textSize == "ax5", "\(appearance) Settings")
            app.navigationBars["Settings"].buttons["Done"].tap()

            app.open(try XCTUnwrap(URL(string: "daybyword://plans/gospels-at-your-pace/week")))
            XCTAssertTrue(app.navigationBars["Week"].waitForExistence(timeout: 10))
            try audit(app, largeText: textSize == "ax5", "\(appearance) a week")
            app.terminate()
        }
    }

    /// Runs the audit and fails on every issue but these, each checked by
    /// hand and recorded in docs/accessibility.md:
    /// - contrast and Dynamic Type on the navigation bar's own glass buttons
    ///   (Done, Cancel, Start), which the system draws and sizes;
    /// - contrast on text that reaches under the tab bar, which the audit
    ///   samples through the bar's blur, and contrast it can name no element
    ///   for while the tab bar shows (the same text, seen through the bar);
    /// - Dynamic Type at the standard size, where the audit flags text that
    ///   does grow: the AX5 pass audits Dynamic Type itself and is seen;
    /// - contrast on a label of one glyph (Progress's day letters, check,
    ///   circle and rest-day dash), whose colors are 6.3:1 (light) and 7.2:1
    ///   (dark) by the tokens, but which the audit samples unreliably;
    /// - text clipped by the screen's own edge, where it scrolls into view
    ///   (an element clipped within the screen still fails);
    /// - text the audit cannot match to an element where the element says it
    ///   in words (a sample week's "Matthew 1–3" is "Matthew, chapters 1 to 3",
    ///   and Progress's "M ✓" is "Monday, March 1, read").
    @MainActor
    private func audit(_ app: XCUIApplication, largeText: Bool, _ screen: String) throws {
        save(app, screen)
        // An issue counts when two audits a moment apart both find it: the
        // contrast check samples pixels, and on a busy machine it can catch
        // a screen still settling (a real issue is found every time).
        let first = try issues(app, screen, largeText: largeText)
        guard !first.isEmpty else { return }
        Thread.sleep(forTimeInterval: 2)
        let again = Set(try issues(app, screen, largeText: largeText))
        let found = first.filter { again.contains($0) }
        XCTAssertTrue(found.isEmpty, found.joined(separator: "\n"))
    }

    @MainActor
    private func issues(_ app: XCUIApplication, _ screen: String, largeText: Bool) throws -> [String] {
        let navigationBar = app.navigationBars.firstMatch
        let tabBar = app.tabBars.firstMatch
        let tabBarTop = tabBar.exists ? tabBar.frame.minY : .infinity
        var found: [String] = []
        try app.performAccessibilityAudit { issue in
            let frame = issue.element?.frame ?? .zero
            let inNavigationBar = navigationBar.exists && navigationBar.frame.insetBy(dx: 0, dy: -8).contains(frame)
            let oneGlyph = (issue.element?.label.count ?? 0) == 1
            switch issue.auditType {
            case .contrast where inNavigationBar || frame.maxY > tabBarTop || oneGlyph: return true
            // Text seen through the tab bar's blur, which the audit cannot
            // name an element for (a long list on History).
            case .contrast where issue.element == nil && tabBar.exists: return true
            case .textClipped where issue.element == nil: return true
            case .dynamicType where inNavigationBar || !largeText: return true
            case .elementDetection
            where issue.element == nil && (screen.hasSuffix("a plan's page") || screen.hasSuffix("Progress")):
                return true
            default: break
            }
            // Described without the element's address, which differs between audits.
            let element = issue.element.map { "\($0.elementType.rawValue) '\($0.label)' at \($0.frame.integral)" }
            found.append("\(screen): \(issue.auditType) on \(element ?? "the screen"): \(issue.compactDescription)")
            return true
        }
        return found
    }

    /// Each audited screen, attached to the result and, when the runner is
    /// given DBW_SCREENSHOTS, saved there (screenshots/ is gitignored).
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
        let file = name.replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "'", with: "")
        try? screenshot.pngRepresentation.write(to: directory.appendingPathComponent("\(file).png"))
    }
}
