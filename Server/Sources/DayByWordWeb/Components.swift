/// The site's shared components (BUILD.md P2.6), in the Morning design
/// (docs/design.md), styled by components in site.css. The app has the same set
/// (apple/App/Components/Components.swift).

/// A reference as it is shown ("Mark 4:1–20") and as a screen reader reads it
/// ("Mark, chapter 4, verses 1 to 20"). ReadingEngine's formatter produces both
/// (BUILD.md P3.4); pages only display them.
struct Reference: Sendable, Hashable {
    let display: String
    let spoken: String

    /// The display text with its chapter and verses kept on one line, so
    /// "4:1–20" never breaks at the dash; copied text stays plain.
    var unbroken: HTML {
        guard let space = display.lastIndex(of: " ") else { return "\(display)" }
        let book = String(display[...space])
        let place = String(display[display.index(after: space)...])
        return "\(book)<span class=\"nobreak\">\(place)</span>"
    }
}

/// How a reading stands, always in words and a symbol as well as color.
enum ReadingStatus: CaseIterable, Sendable {
    case read
    case partlyRead
    case skipped
    case unread

    var label: String {
        switch self {
        case .read: "Read"
        case .partlyRead: "Part read"
        case .skipped: "Skipped"
        case .unread: "Not yet read"
        }
    }

    var symbol: String {
        switch self {
        case .read: "✓"
        case .partlyRead: "◐"
        case .skipped: "↷"
        case .unread: "○"
        }
    }

    var className: String {
        switch self {
        case .read: "status-read"
        case .partlyRead: "status-part"
        case .skipped: "status-skipped"
        case .unread: "status-unread"
        }
    }
}

/// One line of a preview: what changes, from what, to what.
struct PreviewedChange: Sendable {
    let what: String
    let before: String
    let after: String
}

enum Components {
    /// A reference set large enough to read from across a desk. The visible text
    /// is hidden from screen readers, which read the spoken form instead.
    static func referenceBlock(_ reference: Reference, heading: Int = 2) -> HTML {
        let tag = heading == 1 ? "h1" : "h2"
        return """
            <\(HTML(stringLiteral: tag)) class="reference"><span aria-hidden="true">\(reference.unbroken)</span>\
            <span class="visually-hidden">\(reference.spoken)</span></\(HTML(stringLiteral: tag))>
            """
    }

    /// Copies the reference with the project's own script (copy.js); without
    /// JavaScript the reference itself stays selectable.
    static func copyButton(_ reference: Reference) -> HTML {
        """
        <button type="button" class="button secondary" data-copy="\(reference.display)" \
        data-copied="Copied" data-failed="Selected; copy it with your keyboard">Copy reference</button>
        """
    }

    static func primaryButton(_ label: String) -> HTML {
        "<button type=\"submit\" class=\"button primary\">\(label)</button>"
    }

    /// "About 12 minutes. Estimates vary." Estimates always say they are estimates.
    static func workload(minutes: Int) -> HTML {
        minutes == 1
            ? "<p class=\"workload\">About 1 minute. Estimates vary.</p>"
            : "<p class=\"workload\">About \(minutes) minutes. Estimates vary.</p>"
    }

    /// One reading in a list: its label, its reference, and its status in words
    /// and a symbol.
    static func assignmentRow(label: String, reference: Reference, status: ReadingStatus) -> HTML {
        """
        <li class="assignment \(status.className)">\
        <span class="assignment-label">\(label)</span>\
        <span class="assignment-reference"><span aria-hidden="true">\(reference.unbroken)</span>\
        <span class="visually-hidden">\(reference.spoken)</span></span>\
        <span class="assignment-status"><span aria-hidden="true">\(status.symbol)</span> \(status.label)</span>\
        </li>
        """
    }

    /// A plan in a list: what it is, what it covers, and its workload.
    static func planCard(title: String, kind: String, summary: String, minutes: Int, schedule: String, href: String)
        -> HTML
    {
        """
        <article class="card plan-card">
        <p class="label">\(kind)</p>
        <h3><a href="\(href)">\(title)</a></h3>
        <p>\(summary)</p>
        <p class="workload">\(minutes == 1 ? "About 1 minute" : "About \(minutes) minutes"). Estimates vary. · \(schedule)</p>
        </article>
        """
    }

    /// Where a plan comes from, in a sentence or two.
    static func sourceNote(_ text: String) -> HTML {
        "<p class=\"source-note\"><strong>Source.</strong> \(text)</p>"
    }

    /// A plan's sample week: the first few readings and their references.
    static func sampleWeek(_ readings: [(label: String, reference: Reference)]) -> HTML {
        let rows = HTML(
            readings.map { reading in
                """
                <li><span class="sample-label">\(reading.label)</span>\
                <span class="sample-reference"><span aria-hidden="true">\(reading.reference.unbroken)</span>\
                <span class="visually-hidden">\(reading.reference.spoken)</span></span></li>
                """
            })
        return """
            <section class="card sample-week" aria-labelledby="sample-week">
            <h3 id="sample-week">A sample week</h3>
            <ol>\(rows)</ol>
            </section>
            """
    }

    /// Shows exactly what a change will do before anything changes. The form
    /// does nothing until the reader confirms.
    static func changePreview(title: String, explanation: String, changes: [PreviewedChange], confirm: String) -> HTML {
        let rows = HTML(
            changes.map { change in
                """
                <div><dt>\(change.what)</dt>\
                <dd><span class="visually-hidden">from </span>\(change.before) \
                <span aria-hidden="true">→</span><span class="visually-hidden"> to</span> \(change.after)</dd></div>
                """
            })
        return """
            <section class="card change-preview" aria-labelledby="change-preview-title">
            <h2 id="change-preview-title">\(title)</h2>
            <p>\(explanation)</p>
            <dl>\(rows)</dl>
            <form method="post" class="actions">\(primaryButton(confirm))\
            <a class="button secondary" href="./">Cancel</a></form>
            </section>
            """
    }

    /// A quiet confirmation with Undo, announced politely to screen readers.
    static func undoBanner(_ message: String) -> HTML {
        """
        <div class="undo-banner" role="status"><span>\(message)</span>\
        <form method="post"><button type="submit" class="link-button">Undo</button></form></div>
        """
    }

    enum State {
        case empty(title: String, message: String)
        case loading
        case offline
        case error(message: String)
    }

    /// What a page shows when it has nothing yet, is waiting, is offline, or met
    /// an error.
    static func state(_ state: State) -> HTML {
        switch state {
        case .empty(let title, let message):
            return "<div class=\"state\"><p class=\"state-title\">\(title)</p><p>\(message)</p></div>"
        case .loading:
            return "<div class=\"state\" role=\"status\"><p>Loading…</p></div>"
        case .offline:
            return """
                <div class="state" role="status"><p class="state-title">You're offline</p>\
                <p>Marks you make here are kept and sent when you're back online.</p></div>
                """
        case .error(let message):
            return """
                <div class="state" role="alert"><p class="state-title">Something went wrong</p>\
                <p class="error">\(message)</p><a class="button secondary" href="">Try again</a></div>
                """
        }
    }
}
