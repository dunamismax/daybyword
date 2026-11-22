// The web tour (BUILD.md P2.12, PM.19, docs/decisions.md E26): starts the
// server on a spare port, drives a real browser through WebDriver, visits every
// section at a desktop and a narrow width in light and dark, checks each page,
// and saves a screenshot of each to screenshots/web/ (gitignored).
//
//   swift scripts/webtour.swift            the SvelteKit production server, in
//                                          Firefox through geckodriver (the default)
//   DBW_WEBDRIVER=safari swift scripts/webtour.swift
//                                          Safari through safaridriver, once "Allow
//                                          remote automation" is on in Safari's settings
//
// It also prints a week's checklist through the browser's own Print
// (WebDriver's Print Page), in ordinary and large print, and checks the
// paper with PDFKit (BUILD.md P13.5).
//
// The checks are semantic (headings, the nav's current link, the footer, the
// first focusable element), not tied to the markup's classes. The server must
// be built first (make tour-web does it). The WebDriver
// client is this file's own: a few W3C WebDriver commands over URLSession.
import Foundation
import PDFKit

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let screenshots = root.appendingPathComponent("screenshots/web")
let serverPort = 8197
let driverPort = 4497
let base = "http://127.0.0.1:\(serverPort)"

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("tour-web: \(message)\n".utf8))
    stopAll()
    exit(1)
}

// MARK: - Processes

var processes: [Process] = []

func start(_ executable: String, _ arguments: [String], environment: [String: String] = [:]) -> Process {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.environment = ProcessInfo.processInfo.environment.merging(environment) { $1 }
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do { try process.run() } catch { fail("could not start \(executable): \(error)") }
    processes.append(process)
    return process
}

func stopAll() {
    for process in processes where process.isRunning { process.terminate() }
}

func waitUntilAnswering(_ url: String, what: String) async {
    for _ in 0..<100 {
        if let (_, response) = try? await URLSession.shared.data(from: URL(string: url)!),
            (response as? HTTPURLResponse)?.statusCode == 200
        {
            return
        }
        try? await Task.sleep(for: .milliseconds(200))
    }
    fail("\(what) did not answer at \(url)")
}

// MARK: - A small WebDriver client

struct WebDriver {
    let endpoint: String
    var session = ""

    @discardableResult
    func send(_ method: String, _ path: String, _ body: [String: Any]? = nil) async -> Any? {
        var request = URLRequest(url: URL(string: endpoint + path)!)
        request.httpMethod = method
        request.timeoutInterval = 60
        if let body {
            request.httpBody = try! JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        guard let (data, _) = try? await URLSession.shared.data(for: request),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { fail("no answer from the browser driver for \(method) \(path)") }
        let value = json["value"]
        if let error = value as? [String: Any], let kind = error["error"] as? String {
            fail("\(method) \(path): \(kind): \(error["message"] ?? "")")
        }
        return value
    }

    mutating func startSession(browser: String) async {
        let capabilities: [String: Any] =
            browser == "safari"
            ? ["browserName": "safari"]
            : ["browserName": "firefox", "moz:firefoxOptions": ["args": ["-headless"]]]
        let value = await send("POST", "/session", ["capabilities": ["alwaysMatch": capabilities]])
        guard let id = (value as? [String: Any])?["sessionId"] as? String else { fail("no session") }
        session = id
    }

    func go(_ path: String) async { await send("POST", "/session/\(session)/url", ["url": base + path]) }

    @discardableResult
    func run(_ script: String) async -> Any? {
        await send("POST", "/session/\(session)/execute/sync", ["script": script, "args": []])
    }

    func resize(width: Int, height: Int) async {
        await send("POST", "/session/\(session)/window/rect", ["width": width, "height": height])
    }

    func click(_ selector: String) async {
        let element = await send(
            "POST", "/session/\(session)/element", ["using": "css selector", "value": selector])
        guard let id = (element as? [String: Any])?.values.first as? String else { fail("no element \(selector)") }
        await send("POST", "/session/\(session)/element/\(id)/click", [:])
    }

    /// The WebDriver codes for the keys the tour presses.
    static let tab = "\u{E004}", enter = "\u{E007}"

    /// Presses a key on whatever has focus, as a reader at a keyboard would.
    func press(_ key: String) async {
        let keys: [[String: Any]] = [["type": "keyDown", "value": key], ["type": "keyUp", "value": key]]
        await send(
            "POST", "/session/\(session)/actions",
            ["actions": [["type": "key", "id": "keyboard", "actions": keys]]])
    }

    /// Waits up to ten seconds for a script to return true.
    func waitUntil(_ script: String, _ what: String) async {
        for _ in 0..<100 {
            if await run(script) as? Bool == true { return }
            try? await Task.sleep(for: .milliseconds(100))
        }
        fail("waited for \(what)")
    }

    func screenshot(to file: URL) async {
        guard let base64 = await send("GET", "/session/\(session)/screenshot") as? String,
            let data = Data(base64Encoded: base64)
        else { fail("no screenshot") }
        try? data.write(to: file)
    }

    /// The page as the browser prints it, on paper of the size given in
    /// centimetres, without background colours, as a reader's printer would.
    func printed(width: Double, height: Double) async -> PDFDocument {
        guard
            let base64 = await send(
                "POST", "/session/\(session)/print",
                ["page": ["width": width, "height": height], "background": false, "shrinkToFit": false]) as? String,
            let data = Data(base64Encoded: base64), let document = PDFDocument(data: data)
        else { fail("no printed page") }
        return document
    }

    func end() async { await send("DELETE", "/session/\(session)") }
}

// MARK: - The tour

/// Every address in docs/urls.md, with the heading it shows and the section
/// the header marks as current.
let pages: [(name: String, path: String, heading: String, section: String?)] = [
    ("home", "/", "Day by Word", nil),
    ("today", "/today", "Today", "Today"),
    ("plans", "/plans", "Plans", "Plans"),
    ("plan", "/plans/gospels-at-your-pace", "Gospels at your pace", "Plans"),
    ("plan-calendar", "/plans/proverbs-through-the-month", "Proverbs through the month", "Plans"),
    ("week", "/plans/gospels-at-your-pace/week?start=2027-01-04", "Week", "Plans"),
    ("progress", "/progress", "Progress", "Progress"),
    ("settings", "/settings", "Settings", "Settings"),
    ("not-found", "/no-such-page", "Page not found", nil),
]

/// Firefox will not make a window narrower than 500 px, so the narrow pass
/// is 500 px wide; phone widths (375 and 320 px) are checked by hand in a
/// browser's device emulation (AGENTS.md §7).
let widths: [(name: String, width: Int, height: Int)] = [("desktop", 1280, 900), ("narrow", 500, 812)]

var checked = 0
func expect(_ condition: Bool, _ message: @autoclosure () -> String) {
    checked += 1
    if !condition { fail(message()) }
}

let browser = ProcessInfo.processInfo.environment["DBW_WEBDRIVER"] ?? "firefox"
let web = root.appendingPathComponent("web")
guard FileManager.default.fileExists(atPath: web.appendingPathComponent("build/handler.js").path) else {
    fail("build the web app first (make build-web)")
}
// The pinned Node from the PATH, as make uses it (scripts/check-toolchain.sh).
FileManager.default.changeCurrentDirectoryPath(web.path)
_ = start("/usr/bin/env", ["node", "server.ts"], environment: ["HOST": "127.0.0.1", "PORT": String(serverPort)])
switch browser {
case "firefox":
    guard let gecko = ["/opt/homebrew/bin/geckodriver", "/usr/local/bin/geckodriver"].first(where: {
        FileManager.default.isExecutableFile(atPath: $0)
    }) else { fail("geckodriver is not installed (brew install geckodriver)") }
    _ = start(gecko, ["--port", String(driverPort)])
case "safari":
    _ = start("/usr/bin/safaridriver", ["--port", String(driverPort)])
default:
    fail("DBW_WEBDRIVER must be firefox or safari, not \(browser)")
}
await waitUntilAnswering("\(base)/up", what: "the server")
await waitUntilAnswering("http://127.0.0.1:\(driverPort)/status", what: "the browser driver")

var driver = WebDriver(endpoint: "http://127.0.0.1:\(driverPort)")
await driver.startSession(browser: browser)
try? FileManager.default.createDirectory(at: screenshots, withIntermediateDirectories: true)

for size in widths {
    await driver.resize(width: size.width, height: size.height)
    for theme in ["light", "dark"] {
        // The reader's own appearance choice (Settings) sets the theme, as it would for a reader.
        await driver.go("/")
        await driver.run("localStorage.setItem('dbw.appearance', '\(theme)')")
        for page in pages {
            await driver.go(page.path)
            let facts =
                await driver.run(
                    """
                    const current = document.querySelector('header nav [aria-current="page"]');
                    return {
                      heading: document.querySelector('h1')?.textContent ?? '',
                      current: current ? current.textContent : null,
                      currentCount: document.querySelectorAll('[aria-current="page"]').length,
                      theme: document.documentElement.dataset.theme ?? null,
                      overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
                      noticeHidden: document.getElementById('browser-notice').hidden,
                      footer: document.querySelector('body footer')?.textContent ?? '',
                      firstFocusable: document.querySelector('a, button, input')?.textContent ?? '',
                      width: window.innerWidth,
                    };
                    """) as? [String: Any] ?? [:]
            let label = "\(size.name) \(theme) \(page.path)"
            expect(facts["heading"] as? String == page.heading, "\(label): heading is \(facts["heading"] ?? "none")")
            expect(facts["current"] as? String == page.section, "\(label): current section is \(facts["current"] ?? "none")")
            expect((facts["currentCount"] as? Int ?? 0) == (page.section == nil ? 0 : 1), "\(label): current markers")
            expect(facts["theme"] as? String == theme, "\(label): theme is \(facts["theme"] ?? "automatic")")
            expect((facts["overflow"] as? Int ?? 1) <= 0, "\(label): scrolls sideways by \(facts["overflow"] ?? "?") px")
            expect(facts["noticeHidden"] as? Bool == true, "\(label): the unsupported-browser notice is showing")
            expect((facts["footer"] as? String ?? "").contains("not affiliated with any church"), "\(label): footer")
            expect(facts["firstFocusable"] as? String == "Skip to content", "\(label): the skip link is not first")
            if size.name == "narrow" {
                expect((facts["width"] as? Int ?? 9999) <= 500, "\(label): the window is \(facts["width"] ?? "?") px wide")
            }
            await driver.screenshot(to: screenshots.appendingPathComponent("\(size.name)-\(theme)-\(page.name).png"))
        }
    }
}

// Settings: a choice applies at once and is kept across a reload.
await driver.resize(width: 1280, height: 900)
await driver.go("/")
await driver.run("localStorage.clear()")
await driver.go("/settings")
await driver.click("#appearance-dark")
await driver.click("#reference-size-largest")
expect(await driver.run("return document.documentElement.dataset.theme") as? String == "dark", "Dark did not apply")
await driver.go("/today")
let kept = await driver.run(
    "return [document.documentElement.dataset.theme, document.documentElement.dataset.referenceSize]") as? [String]
expect(kept == ["dark", "largest"], "Settings were not kept: \(kept ?? [])")
await driver.go("/settings")
expect(await driver.run("return document.getElementById('appearance-dark').checked") as? Bool == true, "Dark not restored")
await driver.run("localStorage.clear()")

// Paper (P13.1, P13.5): the week's checklist printed on Letter, in ordinary
// and large print, and on a short page that forces breaks. The page alone is
// printed, every reading is on it, and no day is split across pages.
let week = "/plans/gospels-at-your-pace/week?start=2027-01-04"
let days = [
    ("Monday 4 January", "Matthew 1–3"), ("Tuesday 5 January", "Matthew 4–5"),
    ("Wednesday 6 January", "Matthew 6–7"), ("Thursday 7 January", "Matthew 8–9"),
    ("Friday 8 January", "Matthew 10–11"),
]
var pageCounts: [String: Int] = [:]
for (name, query, height) in [("ordinary", "", 27.94), ("large", "&size=large", 27.94), ("short", "&size=large", 9.0)] {
    await driver.go(week + query)
    let document = await driver.printed(width: 21.59, height: height)
    // A large label can wrap ("Monday 4 / January"): compare words, not lines.
    let texts = (0..<document.pageCount).map {
        (document.page(at: $0)?.string ?? "").split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
    let all = texts.joined(separator: "\n")
    pageCounts[name] = document.pageCount
    expect(!all.contains("Skip to content") && !all.contains("Show this week"), "print \(name): the site's own parts are on paper")
    expect(all.contains("Tick each reading as you read it.") && all.contains("Source."), "print \(name): the note or source is missing")
    // Each day's row, its date and then its reading, whole on one page. A
    // PDF's text runs the two together, so spaces are left out.
    let compact = texts.map { $0.filter { !$0.isWhitespace } }
    for (day, reference) in days {
        let row = (day + reference).filter { !$0.isWhitespace }
        let holding = compact.filter { $0.contains(row) }
        expect(holding.count == 1, "print \(name): \(day) and \(reference) are together on \(holding.count) pages")
    }
}
expect((pageCounts["large"] ?? 0) >= (pageCounts["ordinary"] ?? 0), "print: large print has fewer pages")
expect((pageCounts["short"] ?? 0) > 1, "print: a short page did not break")

// Keyboard (P15.4). A plan's Share button is the next stop after Start, and
// Enter copies the link, or shows it selected if the clipboard is refused.
// The share sheet itself (the Web Share API) is the system's, seen on a
// phone, so it is taken away here to test the fallback.
await driver.go("/plans/gospels-at-your-pace")
await driver.run(
    "delete Navigator.prototype.share; delete Navigator.prototype.canShare; document.querySelector('a[href$=\"/start\"]').focus()")
await driver.press(WebDriver.tab)
expect(
    await driver.run("return document.activeElement.dataset.share ?? ''") as? String == "/plans/gospels-at-your-pace",
    "keyboard: Tab from Start does not reach Share")
await driver.press(WebDriver.enter)
await driver.waitUntil(
    "return document.querySelector('button[data-share]').textContent.trim() !== 'Share this plan'", "Share")
let shared = await driver.run(
    "return [document.querySelector('button[data-share]').textContent.trim(), document.activeElement.value ?? '']")
    as? [String] ?? []
expect(
    shared.first == "Link copied"
        || (shared.first == "Selected; copy it with your keyboard"
            && shared.last == "\(base)/plans/gospels-at-your-pace"),
    "keyboard: Share gave \(shared)")

// Today and History: after Mark read from the keyboard, focus is on its
// Undo, and after Undo on Mark read again, in the same plan, rather than
// back at the top of the page with the buttons it pressed gone.
let monday = "today=2027-01-04"
await driver.run("localStorage.clear(); indexedDB.deleteDatabase('day-by-word')")
await driver.go("/plans/gospels-at-your-pace/start?\(monday)")
await driver.click("#start-plan button[type=submit]")
await driver.waitUntil("return location.pathname === '/today'", "the plan to start")
await driver.go("/today?\(monday)")
let markRead = "#today button[data-mark=completed]:not([data-earlier-for])"
await driver.waitUntil("return document.querySelector('\(markRead)') !== null", "Today's card")
await driver.run("document.querySelector('\(markRead)').focus()")
await driver.press(WebDriver.enter)
await driver.waitUntil("return document.activeElement.matches('#today button[data-undo]')", "focus on Undo after Mark read")
expect(
    await driver.run(
        "return document.getElementById(document.activeElement.getAttribute('aria-describedby'))?.textContent ?? ''")
        as? String == "Marked Matthew 1–3 read.",
    "keyboard: Undo does not name the reading it takes back")
await driver.press(WebDriver.enter)
await driver.waitUntil("return document.activeElement.matches('\(markRead)')", "focus on Mark read after Undo")
// History marks a calendar plan's days (a sequence plan's next reading is
// marked on Today), so this part follows Proverbs through the month.
await driver.go("/plans/proverbs-through-the-month/start?\(monday)")
await driver.click("#start-plan button[type=submit]")
await driver.waitUntil("return location.pathname === '/today'", "the second plan to start")
await driver.go("/progress?\(monday)")
let rowMark = "#progress details[data-history] button[data-mark][data-appointed='2027-01-04']"
await driver.waitUntil("return document.querySelector(\"\(rowMark)\") !== null", "History's rows")
await driver.run("const m = document.querySelector(\"\(rowMark)\"); m.closest('details').open = true; m.focus()")
await driver.press(WebDriver.enter)
await driver.waitUntil(
    "return document.activeElement.matches(\"#progress button[data-undo][data-appointed='2027-01-04']\")",
    "focus on the row's Undo in History")
await driver.press(WebDriver.enter)
await driver.waitUntil("return document.activeElement.matches(\"\(rowMark)\")", "focus on the row's Mark read after Undo")
await driver.run("localStorage.clear(); indexedDB.deleteDatabase('day-by-word')")

await driver.end()
stopAll()
print("tour-web: \(checked) checks passed in \(browser); screenshots in screenshots/web/")
