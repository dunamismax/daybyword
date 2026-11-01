import ReadingEngine

/// The site's sections, the same three as the app's tabs, plus Settings
/// (docs/product.md, Navigation).
enum Section: CaseIterable, Sendable {
    case today
    case plans
    case progress
    case settings

    var path: String {
        switch self {
        case .today: "/today"
        case .plans: "/plans"
        case .progress: "/progress"
        case .settings: "/settings"
        }
    }

    var title: String {
        switch self {
        case .today: "Today"
        case .plans: "Plans"
        case .progress: "Progress"
        case .settings: "Settings"
        }
    }
}

/// The pages the server renders, inside one layout: a header with the
/// wordmark and the section switcher, the page's content, and a footer with
/// the independence statement (BUILD.md P2.8).
enum Pages {
    /// The whole document around a page's content. `section` marks the
    /// current section in the header.
    static func layout(title: String, section: Section? = nil, content: HTML) -> HTML {
        let fullTitle = title == "Day by Word" ? title : "\(title) · Day by Word"
        return """
            <!doctype html>
            <html lang="en">
            <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <meta name="color-scheme" content="light dark">
            <meta name="robots" content="noindex">
            <title>\(fullTitle)</title>
            <link rel="icon" href="/assets/images/favicon-32.png" sizes="32x32" type="image/png">
            <link rel="apple-touch-icon" href="/assets/images/apple-touch-icon.png">
            <link rel="stylesheet" href="/assets/tokens.css">
            <link rel="stylesheet" href="/assets/site.css">
            <script type="module" src="/assets/support.js"></script>
            <script nomodule defer src="/assets/unsupported.js"></script>
            <script type="module" src="/assets/copy.js"></script>
            </head>
            <body>
            <a class="skip-link" href="#content">Skip to content</a>
            \(header(current: section))
            \(browserNotice)
            <main id="content" class="page" tabindex="-1">
            \(content)
            </main>
            <footer class="site-footer">
            <div class="page">
            <p>Day by Word is independent and not affiliated with any church or denomination.</p>
            <p class="notice">Day by Word is in development.</p>
            </div>
            </footer>
            </body>
            </html>

            """
    }

    /// The wordmark and the section switcher. The current section carries
    /// `aria-current="page"`, so it is announced, not only colored.
    static func header(current: Section?) -> HTML {
        let links = HTML(
            Section.allCases.map { section in
                section == current
                    ? "<li><a href=\"\(section.path)\" aria-current=\"page\">\(section.title)</a></li>"
                    : "<li><a href=\"\(section.path)\">\(section.title)</a></li>"
            })
        return """
            <header class="site-header">
            <div class="page">
            <a class="wordmark" href="/">\(mark)<span>Day by Word</span></a>
            <nav aria-label="Sections"><ul class="sections">\(links)</ul></nav>
            </div>
            </header>
            """
    }

    /// The owner's mark (design/images/mark.svg), inline so it follows the
    /// text color in light and dark. It is decorative: the name beside it is
    /// the link's text.
    static let mark: HTML = """
        <svg class="mark" aria-hidden="true" focusable="false" viewBox="0 0 1024 1024">\
        <g transform="translate(0,1024) scale(0.1,-0.1)" fill="currentColor">\
        <path d="M4855 6935 c-370 -48 -732 -197 -1040 -428 -117 -88 -349 -325 -437 -447 -199 -276 -332 -580 -397 -907 -30 -150 -51 -323 -51 -420 l0 -53 118 0 c225 0 554 -38 782 -91 227 -52 491 -153 675 -256 205 -116 314 -198 493 -375 l123 -122 117 115 c173 170 255 236 427 342 409 250 898 385 1430 393 l210 3 -2 111 c-5 207 -65 500 -148 716 -115 298 -267 539 -480 761 -198 207 -374 335 -638 464 -212 103 -451 172 -689 198 -127 14 -367 12 -493 -4z"/>\
        <path d="M2900 4434 c-319 -39 -439 -61 -643 -120 -240 -69 -572 -210 -782 -331 -116 -68 -327 -211 -425 -290 -109 -87 -240 -214 -240 -232 0 -32 240 2 805 114 499 99 739 134 1085 155 618 40 1323 -78 1825 -303 173 -78 419 -226 540 -326 27 -22 52 -41 56 -41 3 0 34 23 69 51 95 76 250 175 385 245 355 185 729 296 1215 361 212 28 781 25 1025 -5 294 -37 474 -69 865 -156 281 -61 464 -94 597 -105 119 -10 153 -7 153 14 0 43 -392 356 -605 483 -102 61 -396 207 -485 242 -456 177 -900 262 -1285 247 -553 -22 -1068 -202 -1490 -520 -104 -79 -304 -280 -380 -384 -33 -45 -62 -82 -65 -82 -3 0 -18 18 -35 42 -55 79 -162 202 -242 278 -371 354 -849 573 -1407 645 -117 15 -465 27 -536 18z"/>\
        </g></svg>
        """

    /// The plain notice for browsers the web app does not support (D30). It
    /// starts hidden; `support.js` shows it when a modern feature is missing,
    /// `unsupported.js` when the browser cannot run modules at all, and the
    /// `noscript` copy covers JavaScript turned off. Public pages still read
    /// without JavaScript.
    static let browserNotice: HTML = """
        <div class="browser-notice" id="browser-notice" role="note" hidden>
        <p class="page">This browser is too old for Day by Word's web app. \
        Pages still work for reading, but marking readings needs a recent version of \
        Safari, Chrome, Firefox, or Edge.</p>
        </div>
        <noscript><div class="browser-notice"><p class="page">Day by Word's web app needs JavaScript. \
        Pages still work for reading without it.</p></div></noscript>
        """

    static func home() -> HTML {
        layout(
            title: "Day by Word",
            content: """
                <h1>Day by Word</h1>
                <p class="tagline">Your Bible reading companion.</p>
                <p>Find your plan. Read your Bible. Keep your place.</p>
                <p><a class="button primary" href="/today">Go to Today</a></p>
                """
        )
    }

    static func today() -> HTML {
        section(
            .today,
            Components.state(
                .empty(
                    title: "Your next reading will appear here.",
                    message: "Find your plan. Read your Bible. Keep your place.")))
    }

    static func plans() -> HTML {
        section(
            .plans,
            Components.state(
                .empty(title: "Plans will appear here.", message: "You'll be able to choose a reading plan here.")))
    }

    /// A plan's page, a placeholder until plan pages are built (P9.4).
    static func plan(_ id: PlanID) -> HTML {
        layout(
            title: "Plan",
            section: .plans,
            content: """
                <p><a href="/plans">Plans</a></p>
                <h1>Plan</h1>
                <div class="card">\(Components.state(.empty(title: "This plan's page will appear here.", message: "Plan pages arrive with the catalog.")))</div>
                """
        )
    }

    /// A plan's week from a start date, a placeholder until printable weeks
    /// are built (Phase 13).
    static func planWeek(_ id: PlanID, start: String?) -> HTML {
        layout(
            title: "Week",
            section: .plans,
            content: """
                <p><a href="/plans/\(id.rawValue)">Plan</a></p>
                <h1>Week</h1>
                <div class="card">\(Components.state(.empty(title: "This plan's week will appear here.", message: "Weeks arrive with the catalog.")))</div>
                """
        )
    }

    /// A week's start as the address gives it, kept only when it looks like
    /// `YYYY-MM-DD`; anything else is ignored and the default week shows
    /// (docs/urls.md). `CivilDate` (P5.3) will check that the date exists.
    static func startDate(_ text: Substring?) -> String? {
        guard let text, text.utf8.count == 10 else { return nil }
        let shape = text.utf8.enumerated().allSatisfy { index, byte in
            index == 4 || index == 7
                ? byte == UInt8(ascii: "-") : (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte)
        }
        return shape ? String(text) : nil
    }

    static func progress() -> HTML {
        section(
            .progress,
            Components.state(
                .empty(
                    title: "Your reading record will appear here.",
                    message: "It describes what you've read, and nothing more.")))
    }

    static func settings() -> HTML {
        section(
            .settings,
            Components.state(
                .empty(
                    title: "Settings will appear here.",
                    message: "Day by Word is independent and not affiliated with any church or denomination.")))
    }

    /// A section's page: its title and its content in a card.
    private static func section(_ section: Section, _ content: HTML) -> HTML {
        layout(
            title: section.title,
            section: section,
            content: """
                <h1>\(section.title)</h1>
                <div class="card">\(content)</div>
                """
        )
    }

    static func notFound() -> HTML {
        layout(
            title: "Page not found",
            content: """
                <h1>Page not found</h1>
                <p>There's no page at this address. It may have moved, or the link may be mistyped.</p>
                <p><a href="/today">Go to Today</a></p>
                """
        )
    }

    /// Every shared component with sample content, for checking them in a
    /// browser. Served only in development (/dev/components); the content is
    /// invented for layout.
    static func componentGallery() -> HTML {
        let mark = Reference(display: "Mark 4:1–20", spoken: "Mark, chapter 4, verses 1 to 20")
        return layout(
            title: "Components",
            content: """
                <h1>Components</h1>
                <article class="card reading">
                <p class="label accent">Gospels at your pace · Reading 31</p>
                \(Components.referenceBlock(mark))
                \(Components.workload(minutes: 6))
                <form method="post" class="actions">\(Components.primaryButton("Mark read"))\
                <a class="button secondary" href="https://www.bible.com/">Open in YouVersion</a>\
                \(Components.copyButton(mark))</form>
                </article>
                <section class="card" aria-label="Readings">
                <ul class="assignments">
                \(Components.assignmentRow(label: "Reading 31", reference: mark, status: .unread))
                \(Components.assignmentRow(label: "Reading 30", reference: Reference(display: "Mark 3:20–35", spoken: "Mark, chapter 3, verses 20 to 35"), status: .read))
                \(Components.assignmentRow(label: "Reading 29", reference: Reference(display: "Mark 3:1–19", spoken: "Mark, chapter 3, verses 1 to 19"), status: .partlyRead))
                \(Components.assignmentRow(label: "Reading 28", reference: Reference(display: "Mark 2", spoken: "Mark, chapter 2"), status: .skipped))
                </ul>
                </section>
                \(Components.planCard(title: "Gospels at your pace", kind: "A Day by Word plan", summary: "Matthew, Mark, Luke, and John in readings of about the same length.", minutes: 6, schedule: "Continue at my pace", href: "#plan"))
                \(Components.sampleWeek([
                    ("Reading 1", Reference(display: "Matthew 1", spoken: "Matthew, chapter 1")),
                    ("Reading 2", Reference(display: "Matthew 2", spoken: "Matthew, chapter 2")),
                    ("Reading 3", Reference(display: "Matthew 3:1–4:11", spoken: "Matthew, chapter 3 verse 1 to chapter 4 verse 11")),
                ]))
                \(Components.sourceNote("An original Day by Word plan, built from verse counts and estimated reading time."))
                \(Components.changePreview(title: "Welcome back", explanation: "Here is what continuing from where you left off will do. Your history stays as it is.", changes: [PreviewedChange(what: "Next reading", before: "Mark 3:20–35", after: "Mark 4:1–20"), PreviewedChange(what: "Projected finish", before: "2 March", after: "14 March")], confirm: "Continue"))
                \(Components.undoBanner("Marked Mark 4:1–20 read."))
                <div class="card">\(Components.state(.empty(title: "No plan yet", message: "Choose a plan to see your first reading here.")))</div>
                <div class="card">\(Components.state(.loading))</div>
                <div class="card">\(Components.state(.offline))</div>
                <div class="card">\(Components.state(.error(message: "The plan could not be opened.")))</div>
                """
        )
    }
}
