import AppIntents
import Foundation
import ReadingData
import ReadingEngine
import WidgetKit

/// Mark read, from the widget (BUILD.md P8.9): records the reading the
/// widget showed as read today, in the journal the app shares, if it is
/// still unread. The app offers Undo for it on Today.
struct MarkReadIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark read"
    static let description = IntentDescription("Marks the reading the widget shows as read today.")
    /// Only the widget's button runs it for now; Shortcuts come with P12.4.
    static let isDiscoverable = false

    @Parameter(title: "Plan") var enrollment: String
    @Parameter(title: "Reading") var assignment: Int
    @Parameter(title: "Date") var appointed: String?

    init() {}

    init(enrollment: String, assignment: Int, appointed: String?) {
        self.enrollment = enrollment
        self.assignment = assignment
        self.appointed = appointed
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = EventID(enrollment) else { return .result() }
        guard let catalogURL = Bundle.main.url(forResource: "Catalog", withExtension: "sqlite") else {
            return .result()
        }
        let catalog = try Catalog(path: catalogURL.path)
        let store = try JournalStore(path: try SharedJournal.url().path)
        let journal = try Journal(events: try store.events(), plans: catalog.versions)
        guard let found = journal.enrollments.first(where: { $0.id == id }), found.ended == nil else {
            return .result()
        }
        let date = appointed.flatMap { try? CivilDate($0) }
        let slot = Slot(assignment: assignment, appointed: date)
        // Nothing is recorded twice: a reading already settled stays as it is.
        guard found.state(of: slot) == .unread else { return .result() }
        let now = Date.now
        let mark = JournalEvent.Marked(
            .completed, assignment: assignment, date: try CivilDate(now, in: .current), appointed: date)
        try store.append([
            SharedJournal.event(
                .marked(mark), enrollment: id, after: SharedJournal.latest(in: journal, enrollment: id), now: now)
        ])
        // The system reloads the widget after an intent, but not always
        // after the write is visible; ask once more.
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
