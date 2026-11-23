// The web tour (BUILD.md P2.12, PM.19, P15.6; docs/decisions.md E26, E60):
// starts the server on a spare port, drives a real browser, visits every
// section at a desktop and narrow widths in light and dark, checks each page,
// and saves a screenshot of each to screenshots/web/ (gitignored).
//
//   swift scripts/webtour.swift            the SvelteKit production server, in
//                                          Firefox through geckodriver (the default)
//   DBW_WEBDRIVER=chrome swift scripts/webtour.swift
//                                          Chrome through its DevTools protocol,
//                                          with phone widths (375 and 320 px)
//   DBW_WEBDRIVER=safari swift scripts/webtour.swift
//                                          Safari through safaridriver, once "Allow
//                                          remote automation" is on in Safari's settings
//                                          (a visible window at 1280 and 500 px; Tab is
//                                          Option-Tab, as Safari's keyboard readers press it)
//
// It also prints a week's checklist through the browser's own Print, in
// ordinary and large print, and checks the paper with PDFKit (BUILD.md
// P13.5; not in Safari, whose driver cannot print); presses keys for Share, Today and History (P15.4); and runs every
// web flow at the desktop and the narrowest width (P15.6).
//
// The checks are semantic (headings, the nav's current link, the footer, the
// first focusable element), not tied to the markup's classes. The server must
// be built first (make tour-web does it). The clients are this file's own:
// a few W3C WebDriver commands over URLSession, and a few DevTools commands
// over a WebSocket.
import Foundation
import PDFKit

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let screenshots = root.appendingPathComponent("screenshots/web")
/// Where the browser saves the files the tour asks for (a calendar, the
/// export), in the gitignored build folder, never the owner's Downloads.
let downloads = root.appendingPathComponent("build/webtour-downloads")
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

// MARK: - The browsers

/// A key the tour presses.
enum Key { case tab, enter }

/// What the tour asks of a browser. Firefox and Safari answer W3C WebDriver
/// (geckodriver, safaridriver); Chrome answers its own DevTools protocol,
/// which needs nothing but Chrome itself (Homebrew no longer installs
/// chromedriver, which fails Gatekeeper; P15.6).
@MainActor
protocol TourBrowser {
    func go(_ path: String) async
    /// Runs a script as a function's body and returns what it returns.
    @discardableResult func run(_ script: String) async -> Any?
    /// The viewport in CSS pixels. Chrome emulates a phone below 600 px.
    func resize(width: Int, height: Int) async
    /// Clicks the first element the selector finds, as a mouse would.
    func click(_ selector: String) async
    /// Presses a key on whatever has focus, as a reader at a keyboard would.
    func press(_ key: Key) async
    func screenshot(to file: URL) async
    /// The page as the browser prints it, on paper of the size given in
    /// centimetres, with 1 cm margins and without background colours, as a
    /// reader's printer would.
    func printed(width: Double, height: Double) async -> PDFDocument
    func end() async
    /// The page as assistive technology receives it: the browser's own
    /// accessibility tree, where the browser can give it (Chrome).
    func accessibilityTree() async -> [[String: Any]]?
    /// Asks for more contrast and reduced motion, as a reader's settings do;
    /// false where the browser cannot be asked (only Chrome can).
    func emulateMoreContrast(_ on: Bool) async -> Bool
    /// Forced colors (Windows contrast themes); false where the browser
    /// cannot be asked (only Chrome can).
    func emulateForcedColors(_ on: Bool) async -> Bool
}

extension WebDriver {
    func accessibilityTree() async -> [[String: Any]]? { nil }
    func emulateMoreContrast(_ on: Bool) async -> Bool { false }
    func emulateForcedColors(_ on: Bool) async -> Bool { false }
}

extension TourBrowser {
    /// Waits up to ten seconds for a script to return true.
    func waitUntil(_ script: String, _ what: String) async {
        for _ in 0..<100 {
            if await run(script) as? Bool == true { return }
            try? await Task.sleep(for: .milliseconds(100))
        }
        fail("waited for \(what)")
    }
}

/// A JavaScript string literal.
func literal(_ text: String) -> String {
    String(decoding: try! JSONSerialization.data(withJSONObject: text, options: .fragmentsAllowed), as: UTF8.self)
}

/// A few W3C WebDriver commands over URLSession (E26).
struct WebDriver: TourBrowser {
    let endpoint: String
    var session = ""
    /// Safari's Tab reaches only form controls unless the reader turns on
    /// "Press Tab to highlight each item"; Option-Tab reaches links and every
    /// control, as Safari's keyboard readers use it, without changing a setting.
    var tabWithOption = false
    /// The tour's window, which Safari keys again before each Tab: a Safari
    /// window that is not the key window moves focus on Tab but fires no
    /// focus events and shows no focus ring (`document.hasFocus()` is false).
    var window = ""

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
        // A confirm() the page asks (Skip, Delete everything) is accepted, as
        // a reader would.
        let capabilities: [String: Any] =
            browser == "safari"
            ? ["browserName": "safari", "unhandledPromptBehavior": "accept"]
            : [
                "browserName": "firefox", "unhandledPromptBehavior": "accept",
                "moz:firefoxOptions": [
                    "args": ["-headless"],
                    "prefs": [
                        // Tab reaches links and every control, as a keyboard
                        // reader's settings make it (macOS's default skips links).
                        "accessibility.tabfocus": 7,
                        "browser.download.folderList": 2, "browser.download.dir": downloads.path,
                        "browser.download.useDownloadDir": true,
                        "browser.download.always_ask_before_handling_new_types": false,
                    ],
                ],
            ]
        let value = await send("POST", "/session", ["capabilities": ["alwaysMatch": capabilities]])
        guard let id = (value as? [String: Any])?["sessionId"] as? String else { fail("no session") }
        session = id
        window = await send("GET", "/session/\(session)/window") as? String ?? ""
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
        // Safari's driver can answer before a click's navigation begins (a
        // form posted while the service worker controls the page), and then
        // reads the old page for a while: let it begin.
        if tabWithOption { try? await Task.sleep(for: .milliseconds(800)) }
    }

    func press(_ key: Key) async {
        let code = key == .tab ? "\u{E004}" : "\u{E007}"
        var keys: [[String: Any]] = [["type": "keyDown", "value": code], ["type": "keyUp", "value": code]]
        if key == .tab && tabWithOption {
            await send("POST", "/session/\(session)/window", ["handle": window])
            let option = "\u{E00A}"
            keys = [["type": "keyDown", "value": option]] + keys + [["type": "keyUp", "value": option]]
        }
        await send(
            "POST", "/session/\(session)/actions",
            ["actions": [["type": "key", "id": "keyboard", "actions": keys]]])
    }

    func screenshot(to file: URL) async {
        guard let base64 = await send("GET", "/session/\(session)/screenshot") as? String,
            let data = Data(base64Encoded: base64)
        else { fail("no screenshot") }
        try? data.write(to: file)
    }

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

/// Chrome through its DevTools protocol, over the page's WebSocket.
@MainActor
final class DevTools: TourBrowser {
    private let socket: URLSessionWebSocketTask
    private var lastID = 0
    /// The events Chrome sent while the tour waited for answers.
    private var events: [String] = []

    init(page: URL) {
        socket = URLSession.shared.webSocketTask(with: page)
        socket.maximumMessageSize = 64 << 20  // screenshots and printed pages
        socket.resume()
    }

    private func post(_ method: String, _ params: [String: Any]) async -> Int {
        lastID += 1
        let message = try! JSONSerialization.data(withJSONObject: ["id": lastID, "method": method, "params": params])
        do { try await socket.send(.string(String(decoding: message, as: UTF8.self))) } catch {
            fail("Chrome closed the connection: \(error)")
        }
        return lastID
    }

    /// Sends a command and returns its result, or nil when Chrome refuses
    /// it, as it does while a page is being replaced.
    @discardableResult
    func send(_ method: String, _ params: [String: Any] = [:]) async -> [String: Any]? {
        let id = await post(method, params)
        let watchdog = Task {
            try await Task.sleep(for: .seconds(90))
            fail("Chrome did not answer \(method)")
        }
        defer { watchdog.cancel() }
        while true {
            guard let message = try? await socket.receive() else { fail("no answer from Chrome for \(method)") }
            let text: String
            switch message {
            case .string(let string): text = string
            case .data(let data): text = String(decoding: data, as: UTF8.self)
            @unknown default: continue
            }
            guard let json = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any] else { continue }
            if let event = json["method"] as? String {
                events.append(event)
                // A confirm() the page asks (Skip, Delete everything) is
                // accepted, as a reader would.
                if event == "Page.javascriptDialogOpening" {
                    _ = await post("Page.handleJavaScriptDialog", ["accept": true])
                }
                continue
            }
            guard json["id"] as? Int == id else { continue }
            if json["error"] != nil { return nil }
            return json["result"] as? [String: Any] ?? [:]
        }
    }

    func go(_ path: String) async {
        events.removeAll()
        await send("Page.navigate", ["url": base + path])
        for _ in 0..<300 {
            if events.contains("Page.loadEventFired") { return }
            try? await Task.sleep(for: .milliseconds(50))
            await send("Runtime.evaluate", ["expression": "0"])  // gathers the events sent meanwhile
        }
        fail("\(path) did not load in Chrome")
    }

    @discardableResult
    func run(_ script: String) async -> Any? {
        guard
            let result = await send(
                "Runtime.evaluate",
                ["expression": "(function () {\n\(script)\n})()", "returnByValue": true, "awaitPromise": true])
        else { return nil }
        if let exception = result["exceptionDetails"] as? [String: Any] {
            let thrown = (exception["exception"] as? [String: Any])?["description"] ?? exception["text"] ?? ""
            fail("a script failed in Chrome: \(thrown)\n\(script)")
        }
        return (result["result"] as? [String: Any])?["value"]
    }

    func resize(width: Int, height: Int) async {
        let phone = width < 600
        await send(
            "Emulation.setDeviceMetricsOverride",
            ["width": width, "height": height, "deviceScaleFactor": phone ? 2 : 1, "mobile": phone])
    }

    func click(_ selector: String) async {
        guard
            let point = await run(
                """
                const element = document.querySelector(\(literal(selector)));
                if (!element) return null;
                element.scrollIntoView({ block: 'center' });
                const box = element.getBoundingClientRect();
                return [box.left + box.width / 2, box.top + box.height / 2];
                """) as? [Double], point.count == 2
        else { fail("no element \(selector)") }
        for type in ["mousePressed", "mouseReleased"] {
            await send(
                "Input.dispatchMouseEvent",
                ["type": type, "x": point[0], "y": point[1], "button": "left", "clickCount": 1])
        }
    }

    func press(_ key: Key) async {
        let (name, code) = key == .tab ? ("Tab", 9) : ("Enter", 13)
        var down: [String: Any] = ["type": "keyDown", "key": name, "code": name, "windowsVirtualKeyCode": code]
        if key == .enter { down["text"] = "\r" }
        await send("Input.dispatchKeyEvent", down)
        await send("Input.dispatchKeyEvent", ["type": "keyUp", "key": name, "code": name, "windowsVirtualKeyCode": code])
    }

    func screenshot(to file: URL) async {
        guard let base64 = await send("Page.captureScreenshot", ["format": "png"])?["data"] as? String,
            let data = Data(base64Encoded: base64)
        else { fail("no screenshot") }
        try? data.write(to: file)
    }

    func printed(width: Double, height: Double) async -> PDFDocument {
        let inch = 2.54
        guard
            let base64 = await send(
                "Page.printToPDF",
                [
                    "paperWidth": width / inch, "paperHeight": height / inch, "printBackground": false,
                    "marginTop": 1 / inch, "marginBottom": 1 / inch, "marginLeft": 1 / inch, "marginRight": 1 / inch,
                ])?["data"] as? String,
            let data = Data(base64Encoded: base64), let document = PDFDocument(data: data)
        else { fail("no printed page") }
        return document
    }

    func end() async { socket.cancel(with: .goingAway, reason: nil) }

    func emulateMoreContrast(_ on: Bool) async -> Bool {
        let features: [[String: String]] =
            on
            ? [["name": "prefers-contrast", "value": "more"], ["name": "prefers-reduced-motion", "value": "reduce"]]
            : []
        await send("Emulation.setEmulatedMedia", ["features": features])
        return true
    }

    func emulateForcedColors(_ on: Bool) async -> Bool {
        let features: [[String: String]] = on ? [["name": "forced-colors", "value": "active"]] : []
        await send("Emulation.setEmulatedMedia", ["features": features])
        return true
    }

    func accessibilityTree() async -> [[String: Any]]? {
        await send("Accessibility.enable")
        return await send("Accessibility.getFullAXTree")?["nodes"] as? [[String: Any]]
    }
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
    ("support", "/support", "Support", nil),
    ("sources", "/sources", "Sources and permissions", nil),
    ("criteria", "/criteria", "How Day by Word chooses its plans", nil),
    ("accessibility", "/accessibility", "Accessibility", nil),
    ("privacy", "/privacy", "Privacy policy", nil),
    ("terms", "/terms", "Terms of use", nil),
    ("not-found", "/no-such-page", "Page not found", nil),
]

let browser = ProcessInfo.processInfo.environment["DBW_WEBDRIVER"] ?? "firefox"

/// Chrome emulates a phone at 375 and 320 px. Firefox will not make a window
/// narrower than 500 px, so its narrow pass is 500 px wide.
let widths: [(name: String, width: Int, height: Int)] =
    browser == "chrome"
    ? [("desktop", 1280, 900), ("phone", 375, 812), ("small", 320, 640)]
    : [("desktop", 1280, 900), ("narrow", 500, 812)]

var checked = 0
func expect(_ condition: Bool, _ message: @autoclosure () -> String) {
    checked += 1
    if !condition { fail(message()) }
}

let web = root.appendingPathComponent("web")
guard FileManager.default.fileExists(atPath: web.appendingPathComponent("build/handler.js").path) else {
    fail("build the web app first (make build-web)")
}
// The pinned Node from the PATH, as make uses it (scripts/check-toolchain.sh).
FileManager.default.changeCurrentDirectoryPath(web.path)
/// The site's server; the offline pass stops it and starts it again (P17.5).
func startServer() -> Process {
    start("/usr/bin/env", ["node", "server.ts"], environment: ["HOST": "127.0.0.1", "PORT": String(serverPort)])
}
var server = startServer()
let driver: any TourBrowser
/// Chrome's browser-wide connection, kept open for its download setting.
var chromeBrowser: DevTools?
switch browser {
case "firefox", "safari":
    if browser == "firefox" {
        guard let gecko = ["/opt/homebrew/bin/geckodriver", "/usr/local/bin/geckodriver"].first(where: {
            FileManager.default.isExecutableFile(atPath: $0)
        }) else { fail("geckodriver is not installed (brew install geckodriver)") }
        _ = start(gecko, ["--port", String(driverPort)])
    } else {
        _ = start("/usr/bin/safaridriver", ["--port", String(driverPort)])
    }
    await waitUntilAnswering("\(base)/up", what: "the server")
    await waitUntilAnswering("http://127.0.0.1:\(driverPort)/status", what: "the browser driver")
    var webDriver = WebDriver(endpoint: "http://127.0.0.1:\(driverPort)", tabWithOption: browser == "safari")
    await webDriver.startSession(browser: browser)
    driver = webDriver
case "chrome":
    let chrome = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    guard FileManager.default.isExecutableFile(atPath: chrome) else { fail("Google Chrome is not installed") }
    // A fresh profile each time, in the gitignored build folder, with
    // Chrome's own background traffic (updates, sync, metrics) turned off.
    let profile = root.appendingPathComponent("build/webtour-chrome")
    try? FileManager.default.removeItem(at: profile)
    _ = start(
        chrome,
        [
            "--headless", "--remote-debugging-port=\(driverPort)", "--user-data-dir=\(profile.path)",
            "--no-first-run", "--no-default-browser-check", "--disable-background-networking",
            "--disable-component-update", "--disable-default-apps", "--disable-sync", "--metrics-recording-only",
            "--no-pings", "about:blank",
        ])
    await waitUntilAnswering("\(base)/up", what: "the server")
    await waitUntilAnswering("http://127.0.0.1:\(driverPort)/json/version", what: "Chrome")
    guard let (list, _) = try? await URLSession.shared.data(from: URL(string: "http://127.0.0.1:\(driverPort)/json/list")!),
        let targets = try? JSONSerialization.jsonObject(with: list) as? [[String: Any]],
        let address = targets.first(where: { $0["type"] as? String == "page" })?["webSocketDebuggerUrl"] as? String,
        let page = URL(string: address)
    else { fail("Chrome has no page to drive") }
    let devTools = DevTools(page: page)
    await devTools.send("Page.enable")
    driver = devTools
    // Downloads go to the build folder; the setting lasts while this
    // connection to the browser stays open.
    if let (version, _) = try? await URLSession.shared.data(
        from: URL(string: "http://127.0.0.1:\(driverPort)/json/version")!),
        let address = (try? JSONSerialization.jsonObject(with: version) as? [String: Any])?["webSocketDebuggerUrl"]
            as? String, let url = URL(string: address)
    {
        chromeBrowser = DevTools(page: url)
        await chromeBrowser?.send("Browser.setDownloadBehavior", ["behavior": "allow", "downloadPath": downloads.path])
    }
default:
    fail("DBW_WEBDRIVER must be firefox, chrome or safari, not \(browser)")
}
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
            let label = "\(browser) \(size.name) \(theme) \(page.path)"
            expect(facts["heading"] as? String == page.heading, "\(label): heading is \(facts["heading"] ?? "none")")
            expect(facts["current"] as? String == page.section, "\(label): current section is \(facts["current"] ?? "none")")
            expect((facts["currentCount"] as? Int ?? 0) == (page.section == nil ? 0 : 1), "\(label): current markers")
            expect(facts["theme"] as? String == theme, "\(label): theme is \(facts["theme"] ?? "automatic")")
            expect((facts["overflow"] as? Int ?? 1) <= 0, "\(label): scrolls sideways by \(facts["overflow"] ?? "?") px")
            expect(facts["noticeHidden"] as? Bool == true, "\(label): the unsupported-browser notice is showing")
            expect((facts["footer"] as? String ?? "").contains("not affiliated with any church"), "\(label): footer")
            expect(facts["firstFocusable"] as? String == "Skip to content", "\(label): the skip link is not first")
            if size.name != "desktop" {
                expect(
                    (facts["width"] as? Int ?? 9999) <= size.width,
                    "\(label): the window is \(facts["width"] ?? "?") px wide")
            }
            await driver.screenshot(
                to: screenshots.appendingPathComponent("\(browser)-\(size.name)-\(theme)-\(page.name).png"))
        }
    }
}

// Screen readers (P17.1): on every page, in every browser, the landmarks a
// screen reader jumps between (banner, navigation, main, contentinfo), one
// first-level heading and no skipped heading levels; and in Chrome, from the
// browser's own accessibility tree, a name for every link, button and field,
// and every image either named or hidden.
await driver.resize(width: 1280, height: 900)
for page in pages {
    await driver.go(page.path)
    let structure =
        await driver.run(
            """
            const levels = [...document.querySelectorAll('h1, h2, h3, h4, h5, h6')]
              .filter((h) => h.getClientRects().length > 0)
              .map((h) => Number(h.tagName[1]));
            const skipped = levels.filter((level, i) => i > 0 && level > levels[i - 1] + 1);
            return {
              landmarks: [
                // A header or footer outside sectioning content is the
                // banner or contentinfo landmark (HTML-AAM).
                [...document.querySelectorAll('header')].some((e) => !e.closest('main, article, aside, nav, section')),
                document.querySelector('nav') !== null,
                document.querySelectorAll('main').length === 1,
                [...document.querySelectorAll('footer')].some((e) => !e.closest('main, article, aside, nav, section')),
              ],
              ones: levels.filter((level) => level === 1).length,
              skipped: skipped.length,
              lang: document.documentElement.lang,
            };
            """) as? [String: Any] ?? [:]
    let label = "\(browser) \(page.path)"
    expect((structure["landmarks"] as? [Bool] ?? []) == [true, true, true, true], "\(label): landmarks \(structure["landmarks"] ?? "?")")
    expect(structure["ones"] as? Int == 1, "\(label): \(structure["ones"] ?? "?") first-level headings")
    expect(structure["skipped"] as? Int == 0, "\(label): a heading level is skipped")
    expect(structure["lang"] as? String == "en", "\(label): the page's language is \(structure["lang"] ?? "unset")")
    if let nodes = await driver.accessibilityTree() {
        let named: Set = ["link", "button", "textbox", "checkbox", "radio", "combobox", "spinbutton", "searchbox", "image", "img"]
        var unnamed: [String] = []
        for node in nodes where node["ignored"] as? Bool != true {
            let role = (node["role"] as? [String: Any])?["value"] as? String ?? ""
            let name = ((node["name"] as? [String: Any])?["value"] as? String ?? "").trimmingCharacters(in: .whitespaces)
            if named.contains(role) && name.isEmpty { unnamed.append(role) }
        }
        expect(nodes.count > 10, "\(label): Chrome gave no accessibility tree")
        expect(unnamed.isEmpty, "\(label): unnamed in the accessibility tree: \(unnamed)")
    }
}

// More contrast (P17.2), where the browser can be asked: the tokens'
// high-contrast colors replace the standard ones in light and dark. (Nothing
// on the site moves; app.css stops any transition under reduced motion.)
if await driver.emulateMoreContrast(true) {
    for (theme, muted, line) in [("light", "rgb(67, 73, 87)", "rgb(138, 144, 156)"), ("dark", "rgb(195, 201, 211)", "rgb(104, 114, 130)")] {
        await driver.go("/plans")
        await driver.run("document.documentElement.dataset.theme = '\(theme)'")
        let seen =
            await driver.run(
                """
                const muted = document.querySelector('.text-text-muted');
                const card = document.querySelector('.card');
                return [muted ? getComputedStyle(muted).color : '', card ? getComputedStyle(card).borderTopColor : ''];
                """) as? [String] ?? []
        expect(seen.count == 2 && seen[0] == muted, "\(browser) more contrast, \(theme): muted text is \(seen.first ?? "?")")
        expect(seen.count == 2 && seen[1] == line, "\(browser) more contrast, \(theme): a card's line is \(seen.dropFirst().first ?? "?")")
    }
    _ = await driver.emulateMoreContrast(false)
}

// Text at 200% (P17.3, WCAG 1.4.4): with the root font size doubled, as a
// reader's text-only zoom does, every page still fits the desktop and the
// narrow width without scrolling sideways, and no element hides text it
// cannot fit. (400% zoom is the 320 px width above, in Chrome.)
for (width, height) in [(1280, 900), (widths[widths.count - 1].width, widths[widths.count - 1].height)] {
    await driver.resize(width: width, height: height)
    for page in pages {
        await driver.go(page.path)
        let fit =
            await driver.run(
                """
                document.documentElement.style.fontSize = '200%';
                const clipped = [...document.querySelectorAll('body *')].filter((e) => {
                  const style = getComputedStyle(e);
                  // Text kept for screen readers only is clipped on purpose.
                  return e.getClientRects().length > 0 && e.clientWidth > 0 && !e.classList.contains('sr-only')
                    && ['hidden', 'clip'].includes(style.overflowX) && e.scrollWidth > e.clientWidth + 1;
                }).map((e) => e.outerHTML.slice(0, 80));
                return { overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth, clipped };
                """) as? [String: Any] ?? [:]
        let label = "\(browser) 200% text at \(width) px \(page.path)"
        expect((fit["overflow"] as? Int ?? 1) <= 0, "\(label): scrolls sideways by \(fit["overflow"] ?? "?") px")
        expect((fit["clipped"] as? [String] ?? ["?"]).isEmpty, "\(label): clips \(fit["clipped"] ?? "?")")
    }
}

// Forced colors (P17.3), where the browser can be asked: every button keeps
// an edge, the current section is underlined, and the skip link still
// comes first.
await driver.resize(width: 1280, height: 900)
if await driver.emulateForcedColors(true) {
    for page in pages {
        await driver.go(page.path)
        let forced =
            await driver.run(
                """
                const edgeless = [...document.querySelectorAll('.button')]
                  .filter((e) => e.getClientRects().length > 0 && getComputedStyle(e).borderTopStyle === 'none')
                  .map((e) => e.outerHTML.slice(0, 80));
                const current = document.querySelector('header nav [aria-current="page"]');
                return {
                  active: matchMedia('(forced-colors: active)').matches,
                  edgeless,
                  underlined: current ? getComputedStyle(current).textDecorationLine.includes('underline') : null,
                };
                """) as? [String: Any] ?? [:]
        let label = "\(browser) forced colors \(page.path)"
        expect(forced["active"] as? Bool == true, "\(label): not in forced colors")
        expect((forced["edgeless"] as? [String] ?? ["?"]).isEmpty, "\(label): buttons without an edge: \(forced["edgeless"] ?? "?")")
        if page.section != nil {
            expect(forced["underlined"] as? Bool == true, "\(label): the current section is not underlined")
        }
    }
    _ = await driver.emulateForcedColors(false)
}

// Keyboard alone (P15.4, P16.6): on every page, Tab reaches every control a
// reader can see (one stop for each group of radio buttons), and each shows
// its focus outline. A date field's parts take Tabs of their own, so the
// tour presses three times as many as there are controls; focus wraps.
await driver.resize(width: 1280, height: 900)
for page in pages {
    await driver.go(page.path)
    let controls = """
        const seen = new Set();
        const controls = [...document.querySelectorAll('a[href], button, input, select, textarea, summary')]
          .filter((e) => e.getClientRects().length > 0 && !e.disabled && e.type !== 'hidden')
          .filter((e) => {
            if (e.type !== 'radio') return true;
            if (seen.has(e.name)) return false;
            seen.add(e.name);
            return true;
          });
        """
    let count =
        await driver.run(
            controls
                + """
                window.__reached = new Set();
                window.__unmarked = [];
                document.addEventListener('focusin', (event) => {
                  const target = event.target;
                  window.__reached.add(target.type === 'radio' ? 'radio:' + target.name : target);
                  if (getComputedStyle(target).outlineStyle === 'none' || !target.matches(':focus-visible')) {
                    window.__unmarked.push(target.outerHTML.slice(0, 80));
                  }
                });
                document.activeElement?.blur();
                return controls.length;
                """) as? Int ?? 0
    for _ in 0..<(count * 3 + 2) {
        await driver.press(.tab)
        // Safari fires no focusin when Tab enters a date field's parts, so
        // the tour also notes where focus is after each press.
        if browser == "safari" {
            await driver.run(
                """
                const target = document.activeElement;
                // A ring missed while the window was briefly not key is
                // forgiven once the element is seen with it.
                if (target && getComputedStyle(target).outlineStyle !== 'none') {
                  const html = target.outerHTML.slice(0, 80);
                  window.__unmarked = window.__unmarked.filter((each) => each !== html);
                }
                if (target && target !== document.body && !window.__reached.has(target)) {
                  window.__reached.add(target);
                  // Such a field is never :focus-visible there, so the outline alone counts.
                  if (getComputedStyle(target).outlineStyle === 'none') {
                    window.__unmarked.push(target.outerHTML.slice(0, 80));
                  }
                }
                """)
        }
    }
    let result =
        await driver.run(
            controls
                + """
                const missed = controls
                  .filter((e) => !window.__reached.has(e.type === 'radio' ? 'radio:' + e.name : e))
                  .map((e) => e.outerHTML.slice(0, 80));
                return { missed, unmarked: window.__unmarked };
                """) as? [String: Any] ?? [:]
    let missed = result["missed"] as? [String] ?? ["?"]
    let unmarked = result["unmarked"] as? [String] ?? ["?"]
    expect(count > 0 && missed.isEmpty, "\(browser) \(page.path): Tab never reaches \(missed)")
    expect(unmarked.isEmpty, "\(browser) \(page.path): no focus outline on \(unmarked)")
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
// safaridriver has no Print command, so Safari's printing is checked by hand
// at each release (docs/browsers.md).
let week = "/plans/gospels-at-your-pace/week?start=2027-01-04"
let days = [
    ("Monday 4 January", "Matthew 1–3"), ("Tuesday 5 January", "Matthew 4–5"),
    ("Wednesday 6 January", "Matthew 6–7"), ("Thursday 7 January", "Matthew 8–9"),
    ("Friday 8 January", "Matthew 10–11"),
]
var pageCounts: [String: Int] = [:]
let papers = browser == "safari" ? [] : [("ordinary", "", 27.94), ("large", "&size=large", 27.94), ("short", "&size=large", 9.0)]
for (name, query, height) in papers {
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
if !papers.isEmpty {
    expect((pageCounts["large"] ?? 0) >= (pageCounts["ordinary"] ?? 0), "print: large print has fewer pages")
    expect((pageCounts["short"] ?? 0) > 1, "print: a short page did not break")
}

// Keyboard (P15.4). A plan's Share button is the next stop after Start, and
// Enter copies the link, or shows it selected if the clipboard is refused.
// The share sheet itself (the Web Share API) is the system's, seen on a
// phone, so it is taken away here to test the fallback.
await driver.go("/plans/gospels-at-your-pace")
await driver.run(
    "delete Navigator.prototype.share; delete Navigator.prototype.canShare; document.querySelector('a[href$=\"/start\"]').focus()")
await driver.press(.tab)
expect(
    await driver.run("return document.activeElement.dataset.share ?? ''") as? String == "/plans/gospels-at-your-pace",
    "keyboard: Tab from Start does not reach Share")
await driver.press(.enter)
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
await driver.press(.enter)
await driver.waitUntil("return document.activeElement.matches('#today button[data-undo]')", "focus on Undo after Mark read")
expect(
    await driver.run(
        "return document.getElementById(document.activeElement.getAttribute('aria-describedby'))?.textContent ?? ''")
        as? String == "Marked Matthew 1–3 read.",
    "keyboard: Undo does not name the reading it takes back")
await driver.press(.enter)
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
await driver.press(.enter)
await driver.waitUntil(
    "return document.activeElement.matches(\"#progress button[data-undo][data-appointed='2027-01-04']\")",
    "focus on the row's Undo in History")
await driver.press(.enter)
await driver.waitUntil("return document.activeElement.matches(\"\(rowMark)\")", "focus on the row's Mark read after Undo")
await driver.run("localStorage.clear(); indexedDB.deleteDatabase('day-by-word')")

// MARK: - Every web flow (P15.6)

/// A file the browser saved into `downloads`, once it is whole.
func downloaded(_ name: String) async -> Data? {
    let file = downloads.appendingPathComponent(name)
    for _ in 0..<100 {
        if let data = try? Data(contentsOf: file), !data.isEmpty { return data }
        try? await Task.sleep(for: .milliseconds(100))
    }
    return nil
}

// Each flow a reader has on the web, at the desktop width and the narrowest
// one: choosing a plan, starting one toward a finish date, Copy, part read,
// Skip and Undo on Today, the welcome back after a gap, a plan's history
// (pause, resume, stop following, follow again), the calendar file, and
// export and deletion. Every confirm() is accepted, as a reader would.
let markRead2 = "#today button[data-mark=completed]:not([data-earlier-for])"
for size in [widths[0], widths[widths.count - 1]] {
    let at = "\(browser) \(size.name)"
    await driver.resize(width: size.width, height: size.height)
    try? FileManager.default.removeItem(at: downloads)
    try? FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
    await driver.go("/")
    await driver.run("localStorage.clear(); sessionStorage.clear(); indexedDB.deleteDatabase('day-by-word')")

    // Choosing: the questions suggest up to three plans, each with its page.
    await driver.go("/plans")
    await driver.click("form[action='#suggestions'] input[name=time]:not([value=''])")
    await driver.click("form[action='#suggestions'] button[type=submit]")
    await driver.waitUntil(
        "return document.querySelectorAll('#suggestions a[href^=\"/plans/\"]').length > 0", "\(at): suggestions")
    let suggested = await driver.run("return document.querySelectorAll('#suggestions > ul > li').length") as? Int ?? 0
    expect((1...3).contains(suggested), "\(at): \(suggested) plans suggested")

    // Starting toward a finish date: its load is previewed before starting.
    await driver.go("/plans/gospels-at-your-pace/start?\(monday)")
    await driver.click("#start-plan input[name=behavior][value=finish-date]")
    await driver.run(
        """
        const finish = document.querySelector('#start-plan input[name=finish]');
        finish.value = '2027-02-26';
        finish.dispatchEvent(new Event('change', { bubbles: true }));
        """)
    await driver.waitUntil(
        "const p = document.querySelector('[data-finish-preview]'); return !p.hidden && p.textContent.trim() !== ''",
        "\(at): the finish date's preview")
    await driver.click("#start-plan button[type=submit]")
    await driver.waitUntil("return location.pathname === '/today'", "\(at): the plan to start")

    // Today: Copy reference, then part read and Skip, each taken back.
    await driver.go("/today?\(monday)")
    await driver.waitUntil("return document.querySelector('\(markRead2)') !== null", "\(at): Today's card")
    await driver.click("#today button[data-copy]")
    await driver.waitUntil(
        "return document.querySelector('#today button[data-copy]').textContent.trim() !== 'Copy reference'",
        "\(at): Copy reference")
    for (selector, said) in [
        ("button[data-mark=partlyCompleted]", "Marked Matthew 1–3 part read."),
        ("button[data-mark=skipped]", "Skipped Matthew 1–3. It won't count as read."),
    ] {
        await driver.click("#today \(selector)")
        await driver.waitUntil(
            "return document.getElementById('today').textContent.includes(\(literal(said)))", "\(at): \(said)")
        await driver.click("#today button[data-undo]")
        await driver.waitUntil(
            "return !document.getElementById('today').textContent.includes(\(literal(said)))"
                + " && document.querySelector('\(markRead2)') !== null",
            "\(at): Undo after \(said)")
    }
    await driver.click(markRead2)
    await driver.waitUntil(
        "return document.getElementById('today').textContent.includes('Marked Matthew 1–3 read.')", "\(at): Mark read")

    // Three weeks later, the welcome back: one of its choices, confirmed.
    let later = "today=2027-01-25"
    await driver.go("/today?\(later)")
    await driver.waitUntil("return document.querySelector('#today button[data-return]') !== null", "\(at): the welcome back")
    await driver.click("#today button[data-return]")
    await driver.waitUntil(
        "return document.querySelector('#today button[data-return]') === null"
            + " && document.querySelector('\(markRead2)') !== null",
        "\(at): the welcome answered")

    // History: pause, resume, stop following (confirmed), follow again.
    await driver.go("/progress?\(later)")
    await driver.waitUntil("return document.querySelector('#progress details[data-history]') !== null", "\(at): History")
    await driver.run("document.querySelector('#progress details[data-history]').open = true")
    for (press, then) in [
        ("button[data-action=pause]", "button[data-action=resume]"),
        ("button[data-action=resume]", "button[data-action=pause]"),
        ("button[data-action=end]", "details[data-history] button[data-undo]:not([data-assignment])"),
        ("details[data-history] button[data-undo]:not([data-assignment])", "button[data-action=pause]"),
    ] {
        await driver.click("#progress \(press)")
        await driver.waitUntil("return document.querySelector('#progress \(then)') !== null", "\(at): \(press) in History")
    }

    if browser != "safari" {
        // The next four weeks as a calendar file.
        await driver.click("#progress button[data-calendar]")
        let calendar = String(decoding: await downloaded("Gospels at your pace.ics") ?? Data(), as: UTF8.self)
        expect(
            calendar.hasPrefix("BEGIN:VCALENDAR") && calendar.contains("Gospels at your pace"),
            "\(at): the calendar file is \(calendar.prefix(80))")

        // The reading record exported, as the app exports it.
        await driver.go("/settings")
        await driver.click("#your-data-section button[data-export]")
        let record =
            (try? JSONSerialization.jsonObject(with: await downloaded("Day by Word reading record.json") ?? Data()))
            as? [String: Any]
        expect(
            record?["format"] as? String == "day-by-word-journal" && ((record?["events"] as? [Any])?.count ?? 0) >= 4,
            "\(at): the exported record is \(record.map { "\($0.keys.sorted())" } ?? "missing")")
    }

    // Delete everything (confirmed): Today is empty again.
    await driver.go("/settings")
    await driver.click("#your-data-section button[data-delete-everything]")
    await driver.waitUntil("return !document.querySelector('[data-data-status]').hidden", "\(at): deletion")
    await driver.go("/today?\(later)")
    try? await Task.sleep(for: .seconds(1))
    expect(
        await driver.run("return document.querySelector('#today article') === null") as? Bool == true,
        "\(at): Today still shows a plan after Delete everything")
}

// Offline (P15.2, P17.5): with a plan started and Today opened once, the
// server stops, as when the reader loses their connection. Today opens with
// its kept card and says it is offline, Mark read is kept to send later,
// Plans opens, and a page never opened shows the offline page. With the
// server back, the kept mark is sent and Today shows it read. Not in
// Safari: under its driver, after the flows above, the worker stays
// installing and never takes the page, so Safari offline is checked by
// hand at each release (docs/browsers.md).
if browser != "safari" {
    let at = "\(browser) offline"
    await driver.resize(width: 1280, height: 900)
    await driver.go("/")
    await driver.run("localStorage.clear(); sessionStorage.clear(); indexedDB.deleteDatabase('day-by-word')")
    await driver.go("/plans/gospels-at-your-pace/start?\(monday)")
    await driver.click("#start-plan button[type=submit]")
    await driver.waitUntil("return location.pathname === '/today'", "\(at): the plan to start")
    // The worker keeps the release when it installs, and answers pages
    // from the next load on.
    var controlled = false
    for _ in 0..<40 where !controlled {
        await driver.go("/today?\(monday)")
        controlled =
            await driver.run(
                "return navigator.serviceWorker.controller !== null") as? Bool
            == true
        if !controlled { try? await Task.sleep(for: .milliseconds(250)) }
    }
    expect(controlled, "\(at): the service worker never took the page")
    await driver.waitUntil("return document.querySelector('\(markRead2)') !== null", "\(at): Today's card online")
    await driver.go("/plans")

    server.terminate()
    server.waitUntilExit()
    await driver.go("/today?\(monday)")
    await driver.waitUntil(
        "return document.querySelector('\(markRead2)') !== null && !document.querySelector('[data-today-offline]').hidden",
        "\(at): Today's kept card and the offline note")
    await driver.click(markRead2)
    // Each look starts a count of the kept marks and reads the last one's
    // answer (Safari's driver does not wait for a promise).
    await driver.waitUntil(
        """
        const seen = window.__pending;
        const open = indexedDB.open('day-by-word');
        open.onsuccess = () => {
          const count = open.result.transaction('pending').objectStore('pending').count();
          count.onsuccess = () => { window.__pending = count.result; };
        };
        return seen === 1;
        """, "\(at): the mark kept to send")
    await driver.go("/plans")
    expect(await driver.run("return document.querySelector('h1')?.textContent") as? String == "Plans", "\(at): Plans")
    await driver.go("/plans/pauls-letters/week")
    let shown = await driver.run("return document.querySelector('h1')?.textContent") as? String ?? ""
    expect(shown == "You're offline", "\(at): a page never opened shows \(shown)")

    server = startServer()
    await waitUntilAnswering("\(base)/up", what: "the server again")
    await driver.go("/today?\(monday)")
    await driver.waitUntil(
        "return document.querySelector('\(markRead2)') === null && document.querySelector('#today article') !== null",
        "\(at): the kept mark sent and shown read")
}

await driver.end()
stopAll()
print("tour-web: \(checked) checks passed in \(browser); screenshots in screenshots/web/")
