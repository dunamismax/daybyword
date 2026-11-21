import Foundation
import Observation
import ReadingData
import ReadingEngine
import UIKit

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

    private let store: JournalStore?
    private let clock: () -> Date

    init(catalog: Catalog?, store: JournalStore?, problem: String? = nil, clock: @escaping () -> Date = Date.init) {
        self.catalog = catalog
        self.store = store
        self.problem = problem
        self.clock = clock
        today = Self.civilDate(clock())
        reload()
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

    private static func journalURL() throws -> URL {
        let folder = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let url = folder.appending(path: "Journal.sqlite")
        #if DEBUG
            if UserDefaults.standard.bool(forKey: "freshJournal") {
                try? FileManager.default.removeItem(at: url)
            }
        #endif
        return url
    }

    private static func civilDate(_ instant: Date) -> CivilDate {
        (try? CivilDate(instant, in: .current)) ?? .earliest
    }

    /// Resolves today again, as when the app returns to the foreground.
    func refreshToday() {
        let now = Self.civilDate(clock())
        if now != today { today = now }
    }

    /// Reads the journal again and folds it.
    private func reload() {
        guard let catalog, let store else { return }
        do {
            journal = try Journal(events: try store.events(), plans: catalog.versions)
        } catch {
            problem = String(describing: error)
        }
    }

    /// The reference formatter for the catalog, under the common names.
    var formatter: ReferenceFormatter? {
        catalog.map { ReferenceFormatter(registry: $0.registry, versification: $0.versification) }
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
        let enrollment = newID(after: nil)
        try record(.enrolled(enrolled), enrollment: enrollment)
        return enrollment
    }

    /// Records one event for an enrollment, and folds the journal again.
    @discardableResult
    func record(_ body: JournalEvent.Body, enrollment: EventID) throws -> JournalEvent {
        guard let store else { throw LibraryError.unavailable }
        let latest = journal?.events.filter { $0.enrollment == enrollment }.map(\.id).max()
        let event = JournalEvent(
            id: newID(after: latest ?? enrollment), enrollment: enrollment,
            at: clock().formatted(.iso8601), zone: Self.zone, device: Self.device, body: body)
        try store.append([event])
        reload()
        return event
    }

    /// A new UUIDv7 id, later than `earlier` so a slow clock never puts an
    /// event before the one it answers (docs/engine.md, "The journal").
    private func newID(after earlier: EventID?) -> EventID {
        var milliseconds = Int(clock().timeIntervalSince1970 * 1000)
        if let earlier { milliseconds = max(milliseconds, earlier.milliseconds + 1) }
        var generator = SystemRandomNumberGenerator()
        let random = (0..<10).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        return EventID(milliseconds: milliseconds, random: random)!
    }

    /// The device's IANA zone, as the journal records it.
    private static var zone: String {
        let identifier = TimeZone.current.identifier
        return identifier.wholeMatch(of: /[A-Za-z0-9\/_+\-]{1,64}/) != nil ? identifier : "UTC"
    }

    /// An opaque name for the device in the journal: its kind, never its
    /// owner's name.
    private static var device: String { UIDevice.current.model }
}

enum LibraryError: Error, CustomStringConvertible {
    case unavailable

    var description: String { "The reading record on this device cannot be opened." }
}
