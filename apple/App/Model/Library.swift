import Foundation
import Observation
import ReadingData
import ReadingEngine

/// The reader's plans and record on this device: the bundled catalog, the
/// journal in its SQLite file, the journal folded by the engine, and today's
/// date, resolved once at the edge (docs/engine.md, E7, E8). Views read it
/// and ask it to record events; it never restates a reading rule.
@MainActor
@Observable
final class Library {
    /// The bundled catalog, or nil with `problem` saying why.
    let catalog: Catalog?
    /// Why the catalog or the journal cannot be read, in words.
    private(set) var problem: String?
    /// Today, in the device's time zone; `refreshToday()` keeps it current.
    private(set) var today: CivilDate
    /// The journal, folded.
    private(set) var journal: Journal?

    /// The reader's book-name convention (D29), kept in user defaults.
    var convention: NamingConvention {
        didSet {
            UserDefaults.standard.set(convention.rawValue, forKey: Self.conventionKey)
            // The widget names books the same way (P8.9).
            SharedJournal.defaults.set(convention.rawValue, forKey: Self.conventionKey)
        }
    }
    static let conventionKey = "bookNames"

    /// Called after the journal is read again, as after every write, so the
    /// reminders can follow (P8.8).
    var onChange: (@MainActor () -> Void)?

    private let store: JournalStore?
    private let clock: () -> Date
    private let zone: () -> TimeZone

    /// `clock` and `zone` are the device's own unless a test gives others
    /// (a clock past midnight, a reader who has flown, P17.4).
    init(
        catalog: Catalog?, store: JournalStore?, problem: String? = nil, clock: @escaping () -> Date = Date.init,
        zone: @escaping () -> TimeZone = { .current }
    ) {
        self.catalog = catalog
        self.store = store
        self.problem = problem
        self.clock = clock
        self.zone = zone
        convention =
            NamingConvention(rawValue: UserDefaults.standard.string(forKey: Self.conventionKey) ?? "") ?? .common
        today = Self.civilDate(clock(), in: zone())
        reload()
        // The widgets read these from the App Group (P8.9, P12.2).
        SharedJournal.defaults.set(convention.rawValue, forKey: Self.conventionKey)
        SharedJournal.defaults.set(ReminderPreferences.showsReading(), forKey: ReminderPreferences.showReadingKey)
    }

    /// The library the app runs on: the catalog in the app bundle and the
    /// journal in Application Support. Debug builds accept `-today
    /// YYYY-MM-DD` and `-freshJournal YES` for tests and screenshots (E14).
    static func live() -> Library {
        var problems: [String] = []
        var catalog: Catalog?
        if let url = Bundle.main.url(forResource: "Catalog", withExtension: "sqlite") {
            do { catalog = try Catalog(path: url.path) } catch { problems.append(String(describing: error)) }
        } else {
            problems.append("The app has no catalog.")
        }
        var store: JournalStore?
        do {
            store = try JournalStore(path: try journalURL().path)
        } catch {
            problems.append(String(describing: error))
        }
        #if DEBUG
            let defaults = UserDefaults.standard
            if let text = defaults.string(forKey: "today"), let pinned = try? CivilDate(text) {
                let library = Library(
                    catalog: catalog, store: store, problem: problems.first,
                    clock: { pinned.start(in: .current).addingTimeInterval(9 * 3600) })
                return library
            }
        #endif
        return Library(catalog: catalog, store: store, problem: problems.first)
    }

    /// The journal in the App Group container, which the widget shares
    /// (E47, P8.9); a journal from an earlier build is moved there first.
    private static func journalURL() throws -> URL {
        let url = try SharedJournal.url()
        #if DEBUG
            if UserDefaults.standard.bool(forKey: "freshJournal") {
                try? FileManager.default.removeItem(at: url)
            }
        #endif
        try SharedJournal.moveEarlierJournal(to: url)
        return url
    }

    private static func civilDate(_ instant: Date, in zone: TimeZone) -> CivilDate {
        (try? CivilDate(instant, in: zone)) ?? .earliest
    }

    /// Resolves today again, as when the app returns to the foreground, the
    /// day turns at midnight, or the reader arrives in another zone.
    func refreshToday() {
        let now = Self.civilDate(clock(), in: zone())
        if now != today { today = now }
    }

    /// The instant now, by the library's clock.
    var now: Date { clock() }

    /// The time zone the reader is in now.
    var timeZone: TimeZone { zone() }

    /// The local date and wall-clock time now, in the device's zone, which the
    /// engine's reminders work in (docs/engine.md, "Reminders").
    var localNow: LocalDateTime {
        (try? LocalDateTime(clock(), in: zone()))
            ?? LocalDateTime(date: today, time: WallTime(hour: 0, minute: 0)!)
    }

    /// Reads the journal again, as when the app comes back and the widget
    /// may have written to it.
    func reloadJournal() {
        reload()
    }

    /// Reads the journal again and folds it.
    private func reload() {
        guard let catalog, let store else { return }
        do {
            journal = try Journal(events: try store.events(), plans: catalog.versions)
        } catch {
            problem = String(describing: error)
        }
        onChange?()
    }

    /// The reference formatter for the catalog, under the reader's names.
    var formatter: ReferenceFormatter? {
        catalog.map {
            ReferenceFormatter(registry: $0.registry, versification: $0.versification, convention: convention)
        }
    }

    /// The plans the reader follows and has not ended, in the order started.
    var activeEnrollments: [Enrollment] {
        (journal?.enrollments ?? []).filter { $0.ended == nil }
    }

    /// The catalog's page for an enrollment's plan.
    func plan(of enrollment: Enrollment) -> Plan? {
        catalog?.plan(enrollment.plan.id)
    }

    // MARK: - Recording

    /// Starts a plan: a new enrollment with its `enrolled` event. Returns the
    /// enrollment's id.
    @discardableResult
    func start(_ enrolled: JournalEvent.Enrolled) throws -> EventID {
        let enrollment = SharedJournal.newID(after: nil, now: clock())
        try record(.enrolled(enrolled), enrollment: enrollment)
        return enrollment
    }

    /// Removes every plan and mark from this device, at the reader's request.
    func deleteEverything() throws {
        guard let store else { throw LibraryError.unavailable }
        try store.deleteEverything()
        reload()
    }

    /// Records one event for an enrollment, and folds the journal again.
    @discardableResult
    func record(_ body: JournalEvent.Body, enrollment: EventID) throws -> JournalEvent {
        guard let store else { throw LibraryError.unavailable }
        let event = SharedJournal.event(
            body, enrollment: enrollment, after: SharedJournal.latest(in: journal, enrollment: enrollment),
            now: clock())
        try store.append([event])
        reload()
        return event
    }
}

enum LibraryError: Error, CustomStringConvertible {
    case unavailable

    var description: String { "The reading record on this device cannot be opened." }
}
