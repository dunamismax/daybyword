import AppIntents
import ReadingData
import ReadingEngine
import SwiftUI
import WidgetKit

/// The app's widgets (BUILD.md P8.9): the next reading, on the Home Screen
/// and the Lock Screen, with Mark read. Undo is on Today in the app.
@main
struct DayByWordWidgets: WidgetBundle {
    var body: some Widget {
        NextReadingWidget()
    }
}

struct NextReadingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextReading", provider: NextReadingProvider()) { entry in
            NextReadingView(entry: entry)
                .containerBackground(Palette.background, for: .widget)
                .widgetURL(URL(string: "daybyword://today"))
        }
        .configurationDisplayName("Next reading")
        .description("Shows the next reading in your plan, with Mark read.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct NextReadingEntry: TimelineEntry {
    /// A reading to read, with what Mark read needs to find it again.
    struct Reading: Hashable {
        let plan: String
        let label: String
        let reference: String
        let spoken: String
        let enrollment: String
        let assignment: Int
        let appointed: String?
    }

    enum Content: Hashable {
        case reading(Reading)
        /// A plan with nothing to read now, and why, in Today's words.
        case status(plan: String, text: String)
        case noPlan
        case unavailable
    }

    let date: Date
    let content: Content
}

struct NextReadingProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextReadingEntry {
        NextReadingEntry(
            date: .now,
            content: .reading(
                .init(
                    plan: String(localized: "Gospels at your pace"), label: String(localized: "Reading 12"),
                    reference: String(localized: "Mark 4:1–20"),
                    spoken: String(localized: "Mark, chapter 4, verses 1 to 20"), enrollment: "", assignment: 0,
                    appointed: nil)))
    }

    func getSnapshot(in context: Context, completion: @escaping (NextReadingEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : Self.entry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextReadingEntry>) -> Void) {
        let now = Date.now
        // Today changes at midnight; a mark reloads the timeline sooner.
        let midnight = Calendar.current.startOfDay(for: now.addingTimeInterval(86_400))
        completion(Timeline(entries: [Self.entry(at: now)], policy: .after(midnight)))
    }

    /// The first plan with a reading to read today, or else the first plan's
    /// day in words; every answer is the engine's (docs/engine.md, "Today").
    static func entry(at now: Date) -> NextReadingEntry {
        guard let url = Bundle.main.url(forResource: "Catalog", withExtension: "sqlite"),
            let catalog = try? Catalog(path: url.path),
            let store = try? JournalStore(path: (try? SharedJournal.url().path) ?? ""),
            let journal = try? Journal(events: try store.events(), plans: catalog.versions),
            let today = try? CivilDate(now, in: .current)
        else { return NextReadingEntry(date: now, content: .unavailable) }
        let active = journal.enrollments.filter { $0.ended == nil }
        guard let first = active.first, let firstPlan = catalog.plan(first.plan.id) else {
            return NextReadingEntry(date: now, content: .noPlan)
        }
        let convention =
            NamingConvention(rawValue: SharedJournal.defaults.string(forKey: "bookNames") ?? "") ?? .common
        let formatter = ReferenceFormatter(
            registry: catalog.registry, versification: catalog.versification, convention: convention)
        for enrollment in active {
            let day = enrollment.today(today)
            guard day.status == .reading, let slot = day.readings.first, let plan = catalog.plan(enrollment.plan.id),
                let reading = plan.assignments.first(where: { $0.id == slot.assignment })?.reading
            else { continue }
            let label =
                slot.appointed.map { String(localized: "Day \($0.day)") }
                ?? String(localized: "Reading \(enrollment.plan.positions[slot.assignment] ?? slot.assignment)")
            return NextReadingEntry(
                date: now,
                content: .reading(
                    .init(
                        plan: plan.title, label: label, reference: formatter.string(for: reading),
                        spoken: SpokenReference.text(reading, formatter: formatter),
                        enrollment: enrollment.id.description,
                        assignment: slot.assignment, appointed: slot.appointed?.description)))
        }
        return NextReadingEntry(
            date: now, content: .status(plan: firstPlan.title, text: statusText(first.today(today))))
    }

    /// The words Today uses for a day with nothing to read now.
    static func statusText(_ day: Today) -> String {
        switch day.status {
        case .upcoming: String(localized: "This plan hasn't started yet.")
        case .done: String(localized: "That's today's reading.")
        case .open: String(localized: "Nothing more is scheduled today.")
        case .rest: String(localized: "Today is a rest day in this plan.")
        case .paused: String(localized: "This plan is paused.")
        case .finished: String(localized: "You've reached the end of this plan.")
        case .ended, .reading: ""
        }
    }
}

struct NextReadingView: View {
    let entry: NextReadingEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular: rectangular
        default: small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch entry.content {
            case .reading(let reading):
                Text(verbatim: reading.plan)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.textMuted)
                    .lineLimit(2)
                Text(verbatim: reading.reference)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Palette.text)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .accessibilityLabel(Text(verbatim: reading.spoken))
                    .privacySensitive()
                Spacer(minLength: 0)
                Button(intent: intent(reading)) {
                    Label("Mark read", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .tint(Palette.accent)
                .accessibilityHint(Text("Marks \(reading.spoken) read today."))
            case .status(let plan, let text):
                Text(verbatim: plan)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.textMuted)
                    .lineLimit(2)
                Text(verbatim: text)
                    .font(.headline)
                    .foregroundStyle(Palette.text)
                Spacer(minLength: 0)
            case .noPlan:
                Text("Day by Word")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.textMuted)
                Text("Choose a plan in the app, and your next reading will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.text)
                Spacer(minLength: 0)
            case .unavailable:
                Text("Open Day by Word to see your next reading.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.text)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var rectangular: some View {
        HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
                switch entry.content {
                case .reading(let reading):
                    Text(verbatim: reading.plan).font(.caption).lineLimit(1)
                    Text(verbatim: reading.reference)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .accessibilityLabel(Text(verbatim: reading.spoken))
                        .privacySensitive()
                case .status(let plan, let text):
                    Text(verbatim: plan).font(.caption).lineLimit(1)
                    Text(verbatim: text).font(.headline).lineLimit(2)
                case .noPlan:
                    Text("Choose a plan in Day by Word.").font(.headline).lineLimit(2)
                case .unavailable:
                    Text("Open Day by Word to see your next reading.").font(.caption).lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if case .reading(let reading) = entry.content {
                Button(intent: intent(reading)) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Mark read"))
                .accessibilityHint(Text("Marks \(reading.spoken) read today."))
            }
        }
    }

    private func intent(_ reading: NextReadingEntry.Reading) -> MarkReadIntent {
        MarkReadIntent(enrollment: reading.enrollment, assignment: reading.assignment, appointed: reading.appointed)
    }
}
