// The web tour (BUILD.md P2.12, docs/decisions.md E26): starts the server on a
// spare port, drives a real browser through WebDriver, visits every section at
// a desktop and a narrow width in light and dark, checks each page, and saves a
// screenshot of each to screenshots/web/ (gitignored).
//
//   swift scripts/webtour.swift            Firefox through geckodriver (the default)
//   DBW_WEBDRIVER=safari swift scripts/webtour.swift
//                                          Safari through safaridriver, once "Allow
//                                          remote automation" is on in Safari's settings
//
// The server must be built first (make tour-web does both). The WebDriver
// client is this file's own: a few W3C WebDriver commands over URLSession.
import Foundation

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

    func screenshot(to file: URL) async {
        guard let base64 = await send("GET", "/session/\(session)/screenshot") as? String,
            let data = Data(base64Encoded: base64)
        else { fail("no screenshot") }
        try? data.write(to: file)
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
    ("plan", "/plans/psalm-a-day", "Plan", "Plans"),
    ("week", "/plans/psalm-a-day/week?start=2027-01-04", "Week", "Plans"),
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
let serverBinary = root.appendingPathComponent("Server/.build/debug/DayByWordServer").path
guard FileManager.default.isExecutableFile(atPath: serverBinary) else { fail("build the server first (make tour-web)") }

_ = start(
    serverBinary, [],
    environment: [
        "DBW_PORT": String(serverPort), "DBW_PUBLIC_DIR": root.appendingPathComponent("Server/Public").path,
        "DBW_CATALOG": root.appendingPathComponent("build/catalog/Catalog.sqlite").path, "LOG_LEVEL": "warning",
    ])
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
                    const current = document.querySelector('.sections [aria-current="page"]');
                    return {
                      heading: document.querySelector('h1')?.textContent ?? '',
                      current: current ? current.textContent : null,
                      currentCount: document.querySelectorAll('[aria-current="page"]').length,
                      theme: document.documentElement.dataset.theme ?? null,
                      overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
                      noticeHidden: document.getElementById('browser-notice').hidden,
                      footer: document.querySelector('.site-footer')?.textContent ?? '',
                      firstFocusable: document.querySelector('a, button, input')?.className ?? '',
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
            expect(facts["firstFocusable"] as? String == "skip-link", "\(label): the skip link is not first")
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

await driver.end()
stopAll()
print("tour-web: \(checked) checks passed in \(browser); screenshots in screenshots/web/")
