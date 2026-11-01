/// The pages the server renders. These are placeholders until the design is
/// chosen (BUILD.md P2.3) and the web shell is built (P2.8).
enum Pages {
    /// The whole document around a page's content.
    static func layout(title: String, content: HTML) -> HTML {
        """
        <!doctype html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="color-scheme" content="light dark">
        <meta name="robots" content="noindex">
        <title>\(title)</title>
        <link rel="stylesheet" href="/assets/tokens.css">
        <link rel="stylesheet" href="/assets/site.css">
        <script type="module" src="/assets/copy.js"></script>
        </head>
        <body>
        <main class="page">
        \(content)
        </main>
        <footer class="page">
        <p>Day by Word is independent and not affiliated with any church or denomination.</p>
        </footer>
        </body>
        </html>

        """
    }

    static func home() -> HTML {
        layout(
            title: "Day by Word",
            content: """
                <h1>Day by Word</h1>
                <p class="tagline">Your Bible reading companion.</p>
                <p>Find your plan. Read your Bible. Keep your place.</p>
                <p class="notice">Day by Word is in development.</p>
                """
        )
    }

    /// Every shared component with sample content, for checking them in a
    /// browser. Served only in development (/dev/components); the content is
    /// invented for layout.
    static func componentGallery() -> HTML {
        let mark = Reference(display: "Mark 4:1–20", spoken: "Mark, chapter 4, verses 1 to 20")
        return layout(
            title: "Components · Day by Word",
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
