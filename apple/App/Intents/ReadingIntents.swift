import AppIntents
import Foundation
import ReadingEngine

// Siri, Shortcuts, Spotlight and the Action button (BUILD.md P12.4): three
// actions on the reader's own record, each a thin wrapper over the library
// the app already runs on. Nothing here restates a reading rule; the answers
// are the engine's, put into words by `TodaysReading`.

/// A plan the reader follows, as Siri and Shortcuts name it.
struct FollowedPlan: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Plan")
    static let defaultQuery = FollowedPlanQuery()

    /// The enrollment's id: the same plan started again is another one.
    let id: String
    let title: String

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(title)") }
}

/// The plans the reader follows and has not ended, in the order started.
struct FollowedPlanQuery: EntityQuery {
    @Dependency private var library: Library

    @MainActor
    func entities(for identifiers: [String]) async throws -> [FollowedPlan] {
        library.followedPlans().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [FollowedPlan] {
        library.followedPlans()
    }
}

/// "What's my reading today?": today's reading in each plan, said aloud and
/// shown, and returned as text for a shortcut to use.
struct TodaysReadingIntent: AppIntent {
    static let title: LocalizedStringResource = "Today's Reading"
    static let description = IntentDescription("Tells you today's reading in each plan you follow.")

    @Dependency private var library: Library

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        library.reloadJournal()
        library.refreshToday()
        let answer = library.todaysAnswer()
        return .result(
            value: answer.display, dialog: IntentDialog(full: "\(answer.spoken)", supporting: "\(answer.display)"))
    }
}

/// "Mark today's reading read": names the reading and asks before marking
/// it, because a voice or a button press that shows nothing is not yet the
/// reader confirming what they read (AGENTS.md §3). Undo is on Today.
struct MarkTodaysReadingIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Today's Reading Read"
    static let description = IntentDescription(
        "Marks today's reading in one of your plans as read, after saying which reading it is.")

    @Parameter(title: "Plan") var plan: FollowedPlan?
    @Dependency private var library: Library

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        library.reloadJournal()
        library.refreshToday()
        var readings = library.todaysReadings()
        if let plan {
            readings = readings.filter { $0.enrollment.description == plan.id }
            if readings.isEmpty { return .result(dialog: "\(library.status(of: plan.id))") }
        }
        let reading: TodaysReading
        switch readings.count {
        case 0:
            let words = library.todaysAnswer()
            return .result(dialog: IntentDialog(full: "\(words.spoken)", supporting: "\(words.display)"))
        case 1:
            reading = readings[0]
        default:
            let choices = readings.map { FollowedPlan(id: $0.enrollment.description, title: $0.plan) }
            let chosen = try await $plan.requestDisambiguation(
                among: choices, dialog: "Which plan's reading did you read?")
            guard let found = readings.first(where: { $0.enrollment.description == chosen.id }) else {
                return .result(dialog: "\(library.status(of: chosen.id))")
            }
            reading = found
        }
        try await requestConfirmation(
            actionName: .custom(
                acceptLabel: "Mark read", acceptAlternatives: ["Yes"], denyLabel: "Not now", denyAlternatives: ["No"]),
            dialog: IntentDialog(
                full: "Mark \(reading.spoken) read, in \(reading.plan)?",
                supporting: "Mark \(reading.reference) read, in \(reading.plan)?"))
        guard try library.markRead(reading) else {
            return .result(dialog: "\(library.status(of: reading.enrollment.description))")
        }
        return .result(
            dialog: IntentDialog(
                full: "Marked \(reading.spoken) read. You can undo it on Today.",
                supporting: "Marked \(reading.reference) read. You can undo it on Today."))
    }
}

/// "Open my plan": opens Day by Word on Today, where each plan's reading
/// is, or on a plan's own page when one is named.
struct OpenPlanIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Plan"
    static let description = IntentDescription("Opens Day by Word on Today, or on one of your plans.")
    static let supportedModes: IntentModes = .foreground(.immediate)

    @Parameter(title: "Plan") var plan: FollowedPlan?
    @Dependency private var library: Library
    @Dependency private var routes: PendingRoute

    @MainActor
    func perform() async throws -> some IntentResult {
        let id = plan.flatMap { EventID($0.id) }
        if let enrollment = library.activeEnrollments.first(where: { $0.id == id }) {
            routes.route = .plan(enrollment.plan.id)
        } else {
            routes.route = .today
        }
        return .result()
    }
}

/// The phrases Siri and Spotlight offer without any setup.
struct DayByWordShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TodaysReadingIntent(),
            phrases: [
                "What's my reading today in \(.applicationName)?",
                "What's today's reading in \(.applicationName)?",
                "\(.applicationName) today",
            ],
            shortTitle: "Today's Reading", systemImageName: "book")
        AppShortcut(
            intent: MarkTodaysReadingIntent(),
            phrases: [
                "Mark today's reading read in \(.applicationName)",
                "Mark my \(.applicationName) reading read",
            ],
            shortTitle: "Mark Read", systemImageName: "checkmark.circle")
        AppShortcut(
            intent: OpenPlanIntent(),
            phrases: [
                "Open my plan in \(.applicationName)",
                "Open \(\.$plan) in \(.applicationName)",
            ],
            shortTitle: "Open Plan", systemImageName: "books.vertical")
    }
}

// MARK: - The library's answers

extension Library {
    /// The plans the reader follows, as entities.
    func followedPlans() -> [FollowedPlan] {
        activeEnrollments.compactMap { enrollment in
            plan(of: enrollment).map { FollowedPlan(id: enrollment.id.description, title: $0.title) }
        }
    }

    /// Today's first reading in each active plan.
    func todaysReadings() -> [TodaysReading] {
        guard let catalog, let formatter else { return [] }
        return TodaysReading.all(in: activeEnrollments, catalog: catalog, today: today, formatter: formatter)
    }

    /// Today in words, to show and to say: each plan's reading, or each
    /// plan's day where it has none to read now.
    func todaysAnswer() -> (display: String, spoken: String) {
        guard catalog != nil, journal != nil else {
            let words = String(localized: "Open Day by Word to see your next reading.")
            return (words, words)
        }
        let enrollments = activeEnrollments
        guard !enrollments.isEmpty else {
            let words = String(localized: "You're not following a plan yet. Choose one in Day by Word.")
            return (words, words)
        }
        let readings = todaysReadings()
        var display: [String] = []
        var spoken: [String] = []
        for enrollment in enrollments {
            guard let plan = plan(of: enrollment) else { continue }
            if let reading = readings.first(where: { $0.enrollment == enrollment.id }) {
                display.append(String(localized: "\(plan.title), \(reading.label): \(reading.reference)."))
                spoken.append(String(localized: "\(plan.title), \(reading.label): \(reading.spoken)."))
            } else {
                let words = String(localized: "\(plan.title): \(TodaysReading.statusText(enrollment.today(today)))")
                display.append(words)
                spoken.append(words)
            }
        }
        return (display.joined(separator: "\n"), spoken.joined(separator: " "))
    }

    /// One plan's day in words, when it has no reading to mark.
    func status(of enrollment: String) -> String {
        guard let found = activeEnrollments.first(where: { $0.id.description == enrollment }),
            let plan = plan(of: found)
        else { return String(localized: "That plan isn't one you're following now.") }
        return String(localized: "\(plan.title): \(TodaysReading.statusText(found.today(today)))")
    }

    /// Marks a reading read today if it is still unread; nothing is
    /// recorded twice. Returns whether it was marked.
    func markRead(_ reading: TodaysReading) throws -> Bool {
        guard let enrollment = activeEnrollments.first(where: { $0.id == reading.enrollment }),
            enrollment.state(of: reading.slot) == .unread
        else { return false }
        let mark = JournalEvent.Marked(
            .completed, assignment: reading.slot.assignment, date: today, appointed: reading.slot.appointed)
        try record(.marked(mark), enrollment: enrollment.id)
        return true
    }
}
