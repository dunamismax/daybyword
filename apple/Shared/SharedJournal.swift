import Foundation
import ReadingEngine
import UIKit

/// The reader's journal where the app and its widget both reach it: the
/// App Group container (E47, BUILD.md P8.9). Each new event is made here, so
/// an event the widget records follows the same rules as one the app does.
enum SharedJournal {
    static let appGroup = "group.com.daybyword.app"

    /// Settings the widget also reads, such as the reader's book names.
    static var defaults: UserDefaults { UserDefaults(suiteName: appGroup) ?? .standard }

    /// The journal file in the shared container.
    static func url() throws -> URL {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            throw SharedJournalError.noContainer
        }
        return container.appending(path: "Journal.sqlite")
    }

    /// Moves a journal kept in the app's own Application Support folder, as
    /// builds before P8.9 did, into the shared container, once. Nothing is
    /// moved over a journal already there.
    static func moveEarlierJournal(to url: URL) throws {
        let fileManager = FileManager.default
        let support = try fileManager.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let earlier = support.appending(path: "Journal.sqlite")
        guard fileManager.fileExists(atPath: earlier.path), !fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.moveItem(at: earlier, to: url)
    }

    /// A new event for an enrollment, its id a UUIDv7 later than `latest`, so
    /// a slow clock never puts an event before the one it answers
    /// (docs/engine.md, "The journal").
    @MainActor static func event(_ body: JournalEvent.Body, enrollment: EventID, after latest: EventID?, now: Date)
        -> JournalEvent
    {
        JournalEvent(
            id: newID(after: latest, now: now), enrollment: enrollment, at: now.formatted(.iso8601), zone: zone,
            device: device, body: body)
    }

    /// A new UUIDv7 id, later than `earlier`.
    static func newID(after earlier: EventID?, now: Date) -> EventID {
        var milliseconds = Int(now.timeIntervalSince1970 * 1000)
        if let earlier { milliseconds = max(milliseconds, earlier.milliseconds + 1) }
        var generator = SystemRandomNumberGenerator()
        let random = (0..<10).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        return EventID(milliseconds: milliseconds, random: random)!
    }

    /// The latest event of an enrollment, or the enrollment's own id.
    static func latest(in journal: Journal?, enrollment: EventID) -> EventID {
        journal?.events.filter { $0.enrollment == enrollment }.map(\.id).max() ?? enrollment
    }

    /// The device's IANA zone, as the journal records it.
    static var zone: String {
        let identifier = TimeZone.current.identifier
        return identifier.wholeMatch(of: /[A-Za-z0-9\/_+\-]{1,64}/) != nil ? identifier : "UTC"
    }

    /// An opaque name for the device in the journal: its kind, never its
    /// owner's name.
    @MainActor static var device: String { UIDevice.current.model }
}

enum SharedJournalError: Error, CustomStringConvertible {
    case noContainer

    var description: String { "The shared folder for the reading record cannot be found." }
}
