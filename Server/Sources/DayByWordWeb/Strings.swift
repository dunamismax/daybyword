/// The web's interface text, by key (docs/decisions.md E15, E25). Pages and
/// components never write interface words themselves; they ask for a key,
/// so adding a language means adding a table, not touching every page.
/// English is the only table for now.
enum StringKey: String, CaseIterable, Sendable {
    case siteName = "site.name"
    case siteTagline = "site.tagline"
    case siteLine = "site.line"
    case siteIndependence = "site.independence"
    case siteInDevelopment = "site.in-development"
    case pageTitle = "site.page-title"
    case skipToContent = "site.skip-to-content"
    case sectionsLabel = "site.sections-label"
    case browserTooOld = "site.browser-too-old"
    case browserNeedsJavaScript = "site.browser-needs-javascript"
    case goToToday = "site.go-to-today"

    case today = "section.today"
    case plans = "section.plans"
    case progress = "section.progress"
    case settings = "section.settings"

    case todayEmptyTitle = "today.empty-title"
    case plansEmptyTitle = "plans.empty-title"
    case plansEmptyMessage = "plans.empty-message"
    case planTitle = "plan.title"
    case planEmptyTitle = "plan.empty-title"
    case planEmptyMessage = "plan.empty-message"
    case weekTitle = "week.title"
    case weekEmptyTitle = "week.empty-title"
    case weekEmptyMessage = "week.empty-message"
    case progressEmptyTitle = "progress.empty-title"
    case progressEmptyMessage = "progress.empty-message"
    case settingsEmptyTitle = "settings.empty-title"
    case notFoundTitle = "not-found.title"
    case notFoundMessage = "not-found.message"

    case copyReference = "component.copy-reference"
    case copied = "component.copied"
    case copyFailed = "component.copy-failed"
    case workloadOne = "component.workload-one"
    case workloadOther = "component.workload-other"
    case statusRead = "component.status-read"
    case statusPartlyRead = "component.status-partly-read"
    case statusSkipped = "component.status-skipped"
    case statusUnread = "component.status-unread"
    case sourceLabel = "component.source-label"
    case sampleWeek = "component.sample-week"
    case changeFrom = "component.change-from"
    case changeTo = "component.change-to"
    case cancel = "component.cancel"
    case undo = "component.undo"
    case loading = "component.loading"
    case offlineTitle = "component.offline-title"
    case offlineMessage = "component.offline-message"
    case errorTitle = "component.error-title"
    case tryAgain = "component.try-again"
}

/// One language's table. Values may hold `{name}` placeholders, filled by
/// `subscript(_:_:)`.
struct Strings: Sendable {
    let table: [StringKey: String]

    /// The text for a key, with its placeholders filled. A key missing from a
    /// table shows the key itself, which the string tests catch long before a
    /// reader could.
    subscript(_ key: StringKey, _ values: [String: String] = [:]) -> String {
        var text = table[key] ?? key.rawValue
        for (name, value) in values {
            text = text.replacingOccurrences(of: "{\(name)}", with: value)
        }
        return text
    }

    static let english = Strings(table: [
        .siteName: "Day by Word",
        .siteTagline: "Your Bible reading companion.",
        .siteLine: "Find your plan. Read your Bible. Keep your place.",
        .siteIndependence: "Day by Word is independent and not affiliated with any church or denomination.",
        .siteInDevelopment: "Day by Word is in development.",
        .pageTitle: "{page} · Day by Word",
        .skipToContent: "Skip to content",
        .sectionsLabel: "Sections",
        .browserTooOld:
            "This browser is too old for Day by Word's web app. Pages still work for reading, but marking readings needs a recent version of Safari, Chrome, Firefox, or Edge.",
        .browserNeedsJavaScript: "Day by Word's web app needs JavaScript. Pages still work for reading without it.",
        .goToToday: "Go to Today",

        .today: "Today",
        .plans: "Plans",
        .progress: "Progress",
        .settings: "Settings",

        .todayEmptyTitle: "Your next reading will appear here.",
        .plansEmptyTitle: "Plans will appear here.",
        .plansEmptyMessage: "You'll be able to choose a reading plan here.",
        .planTitle: "Plan",
        .planEmptyTitle: "This plan's page will appear here.",
        .planEmptyMessage: "Plan pages arrive with the catalog.",
        .weekTitle: "Week",
        .weekEmptyTitle: "This plan's week will appear here.",
        .weekEmptyMessage: "Weeks arrive with the catalog.",
        .progressEmptyTitle: "Your reading record will appear here.",
        .progressEmptyMessage: "It describes what you've read, and nothing more.",
        .settingsEmptyTitle: "Settings will appear here.",
        .notFoundTitle: "Page not found",
        .notFoundMessage: "There's no page at this address. It may have moved, or the link may be mistyped.",

        .copyReference: "Copy reference",
        .copied: "Copied",
        .copyFailed: "Selected; copy it with your keyboard",
        .workloadOne: "About 1 minute. Estimates vary.",
        .workloadOther: "About {minutes} minutes. Estimates vary.",
        .statusRead: "Read",
        .statusPartlyRead: "Part read",
        .statusSkipped: "Skipped",
        .statusUnread: "Not yet read",
        .sourceLabel: "Source.",
        .sampleWeek: "A sample week",
        .changeFrom: "from",
        .changeTo: "to",
        .cancel: "Cancel",
        .undo: "Undo",
        .loading: "Loading…",
        .offlineTitle: "You're offline",
        .offlineMessage: "Marks you make here are kept and sent when you're back online.",
        .errorTitle: "Something went wrong",
        .tryAgain: "Try again",
    ])
}

/// The current language's text for a key. Every page is English until a
/// second table arrives; then the language comes from the request.
func text(_ key: StringKey, _ values: [String: String] = [:]) -> String {
    Strings.english[key, values]
}
