import AppIntents
import ReadingData
import ReadingEngine
import SwiftUI
import WidgetKit

/// The app's widgets (BUILD.md P8.9, P12.2): the next reading (small) and
/// today's readings across plans (medium) on the Home Screen, and on the
/// Lock Screen the next reading (rectangular), a line (inline) and a symbol
/// (circular). Mark read is wherever the reading is named; Undo is on Today
/// in the app. With "Name the reading" off, the Lock Screen shows the plan
/// and "Reading 12", never the passage (P8.8).
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
        .description("Shows today's reading in your plans, with Mark read.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular,
        ])
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
        /// Today's readings, one for each plan with a reading to read now,
        /// in the order the plans were started; never empty.
        case readings([Reading])
        /// A plan with nothing to read now, and why, in Today's words.
        case status(plan: String, text: String)
        case noPlan
        case unavailable
    }

    let date: Date
    let content: Content
    /// Whether the Lock Screen may name the passage ("Name the reading in
    /// reminders and on the Lock Screen", P8.8).
    var namesReading = true
}

struct NextReadingProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextReadingEntry {
        NextReadingEntry(
            date: .now,
            content: .readings([
                .init(
                    plan: String(localized: "Gospels at your pace"), label: String(localized: "Reading 12"),
                    reference: String(localized: "Mark 4:1–20"),
                    spoken: String(localized: "Mark, chapter 4, verses 1 to 20"), enrollment: "", assignment: 0,
                    appointed: nil)
            ]))
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

    /// Today's readings, the first of each plan with one to read now, or
    /// else the first plan's day in words; every answer is the engine's
    /// (docs/engine.md, "Today").
    static func entry(at now: Date) -> NextReadingEntry {
        var entry = readings(at: now)
        // The app keeps this in the App Group for the widgets (Library).
        entry.namesReading = SharedJournal.defaults.object(forKey: "reminderShowsReading") as? Bool ?? true
        return entry
    }

    private static func readings(at now: Date) -> NextReadingEntry {
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
        var readings: [NextReadingEntry.Reading] = []
        for enrollment in active {
            let day = enrollment.today(today)
            guard day.status == .reading, let slot = day.readings.first, let plan = catalog.plan(enrollment.plan.id),
                let reading = plan.assignments.first(where: { $0.id == slot.assignment })?.reading
            else { continue }
            let label =
                slot.appointed.map { String(localized: "Day \($0.day)") }
                ?? String(localized: "Reading \(enrollment.plan.positions[slot.assignment] ?? slot.assignment)")
            readings.append(
                .init(
                    plan: plan.title, label: label, reference: formatter.string(for: reading),
                    spoken: SpokenReference.text(reading, formatter: formatter),
                    enrollment: enrollment.id.description,
                    assignment: slot.assignment, appointed: slot.appointed?.description))
        }
        if !readings.isEmpty { return NextReadingEntry(date: now, content: .readings(readings)) }
        return NextReadingEntry(
            date: now, content: .status(plan: firstPlan.title, text: statusText(first.today(today))))
    }

    /// The words Today uses for a day with nothing to read now.
    /// Today's words for a day whose reading is read.
    static var doneText: String { String(localized: "That's today's reading.") }

    static func statusText(_ day: Today) -> String {
        switch day.status {
        case .upcoming: String(localized: "This plan hasn't started yet.")
        case .done: doneText
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
        case .accessoryInline: inline
        case .accessoryCircular: circular
        case .systemMedium: medium
        default: small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch entry.content {
            case .readings(let readings):
                let reading = readings[0]
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

    /// Today's readings, up to three plans, each with Mark read; or the
    /// first plan's day in words.
    private var medium: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch entry.content {
            case .readings(let readings):
                ForEach(readings.prefix(3), id: \.self) { reading in
                    HStack(alignment: .center, spacing: 8) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(verbatim: reading.plan)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Palette.textMuted)
                                .lineLimit(1)
                            Text(verbatim: reading.reference)
                                .font(readings.count == 1 ? .title2.weight(.bold) : .headline)
                                .foregroundStyle(Palette.text)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .accessibilityLabel(Text(verbatim: reading.spoken))
                                .privacySensitive()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Button(intent: intent(reading)) {
                            Label("Mark read", systemImage: "checkmark")
                                .labelStyle(.iconOnly)
                                .font(.headline)
                                .frame(minWidth: 44, minHeight: 36)
                        }
                        .tint(Palette.accent)
                        .accessibilityLabel(Text("Mark read"))
                        .accessibilityHint(Text("Marks \(reading.spoken) read today."))
                    }
                }
                Spacer(minLength: 0)
            case .status, .noPlan, .unavailable:
                small
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// One line on the Lock Screen: the next reading, or the day in words.
    /// An inline accessory holds no button, so Mark read is elsewhere.
    private var inline: some View {
        switch entry.content {
        case .readings(let readings):
            let reading = readings[0]
            return entry.namesReading
                ? Text(verbatim: reading.reference).accessibilityLabel(Text(verbatim: reading.spoken))
                : Text(verbatim: "\(reading.plan): \(reading.label)")
        case .status(_, let text): return Text(verbatim: text)
        case .noPlan: return Text("Choose a plan in Day by Word.")
        case .unavailable: return Text("Open Day by Word.")
        }
    }

    /// A symbol on the Lock Screen: an open book while a reading waits, a
    /// check once today's is read. It names no reading, so it opens Today
    /// rather than marking one.
    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            switch entry.content {
            case .readings:
                Image(systemName: "book")
                    .font(.title3)
                    .accessibilityLabel(Text("A reading for today"))
            case .status(_, let text):
                Image(systemName: text == NextReadingProvider.doneText ? "checkmark" : "book.closed")
                    .font(.title3)
                    .accessibilityLabel(Text(verbatim: text))
            case .noPlan, .unavailable:
                Image(systemName: "book.closed")
                    .font(.title3)
                    .accessibilityLabel(Text("Day by Word"))
            }
        }
    }

    private var rectangular: some View {
        HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 0) {
                switch entry.content {
                case .readings(let readings):
                    let reading = readings[0]
                    Text(verbatim: reading.plan).font(.caption).lineLimit(1)
                    if entry.namesReading {
                        Text(verbatim: reading.reference)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .accessibilityLabel(Text(verbatim: reading.spoken))
                            .privacySensitive()
                    } else {
                        Text(verbatim: reading.label).font(.headline).lineLimit(1)
                    }
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
            if case .readings(let readings) = entry.content {
                let reading = readings[0]
                Button(intent: intent(reading)) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Mark read"))
                .accessibilityHint(
                    entry.namesReading
                        ? Text("Marks \(reading.spoken) read today.")
                        : Text("Marks \(reading.plan), \(reading.label), read today."))
            }
        }
    }

    private func intent(_ reading: NextReadingEntry.Reading) -> MarkReadIntent {
        MarkReadIntent(enrollment: reading.enrollment, assignment: reading.assignment, appointed: reading.appointed)
    }
}
