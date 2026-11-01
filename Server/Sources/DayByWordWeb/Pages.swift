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
}
