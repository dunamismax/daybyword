import ReadingData
import ReadingEngine
import SwiftUI
import UserNotifications

/// How the reader reads: the preference that decides whether Today offers
/// a link (P8.5) or the desk-glance layout for paper (P8.6). Kept in user
/// defaults, a preference rather than reading data.
enum WayToRead: String, CaseIterable, Identifiable, Sendable {
    case physicalBible
    case youVersion
    case otherApp

    static let storageKey = "wayToRead"

    var id: Self { self }

    var label: LocalizedStringResource {
        switch self {
        case .physicalBible: "A physical Bible"
        case .youVersion: "YouVersion or Bible.com"
        case .otherApp: "Another app, with Copy reference"
        }
    }
}

/// Starting a plan (docs/product.md, "Starting a plan"): the start date, or
/// today's readings for a calendar plan; the behavior, explained; reading
/// days; how the reader reads; and an offer of a reminder. Notification
/// permission is asked for only when the reader turns a reminder on.
/// Starting records one `enrolled` event; nothing else changes.
struct StartPlanView: View {
    let presentation: PlanPresentation
    let onStarted: () -> Void

    @Environment(Library.self) private var library
    @Environment(\.dismiss) private var dismiss
    @AppStorage(WayToRead.storageKey) private var wayToRead = WayToRead.physicalBible

    @State private var start = Date.now
    @State private var behavior: Plan.Behavior
    @State private var readingDays: Set<Int>
    @State private var finish = Date.now
    @State private var limit = 2
    @State private var reminderOn = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? .now
    @State private var notificationsRefused = false
    @State private var failure: String?
    @State private var prepared = false

    init(presentation: PlanPresentation, onStarted: @escaping () -> Void) {
        self.presentation = presentation
        self.onStarted = onStarted
        _behavior = State(initialValue: presentation.plan.behaviors[0])
        _readingDays = State(initialValue: Set(1...presentation.plan.readingDays))
    }

    private var plan: Plan { presentation.plan }
    private var isCalendar: Bool { plan.schedule == .dayOfMonth }

    private var startDate: CivilDate {
        isCalendar ? library.today : ((try? CivilDate(start, in: .current)) ?? library.today)
    }

    private var finishDate: CivilDate { (try? CivilDate(finish, in: .current)) ?? startDate }

    /// The `enrolled` event the reader's choices make.
    private var enrolled: JournalEvent.Enrolled {
        let reminder: JournalEvent.Reminder? =
            reminderOn
            ? WallTime(
                hour: Calendar.current.component(.hour, from: reminderTime),
                minute: Calendar.current.component(.minute, from: reminderTime)
            ).map { .at($0) } : nil
        return JournalEvent.Enrolled(
            plan: plan.id, version: plan.version, behavior: behavior, start: startDate,
            readingDays: readingDays.sorted(), finish: behavior == .finishDate ? finishDate : nil,
            limit: behavior == .finishDate ? limit : nil, reminder: reminder)
    }

    /// What the finish date asks, from the engine: the most readings on a
    /// day, the heaviest day, and the earliest finish within the limit.
    private var schedule: Today.Schedule? {
        guard behavior == .finishDate else { return nil }
        return PlanPresentation.candidate(enrolled, plan: library.catalog!.version(of: plan))?
            .today(startDate).schedule
    }

    /// The finish at one reading each chosen reading day, the default.
    private var paceFinish: CivilDate? {
        var pace = enrolled
        pace = JournalEvent.Enrolled(
            plan: pace.plan, version: pace.version, behavior: .pace, start: pace.start, readingDays: pace.readingDays)
        return PlanPresentation.candidate(pace, plan: library.catalog!.version(of: plan))?
            .readingDay(plan.assignments.count, from: startDate)
    }

    private var canStart: Bool {
        guard !readingDays.isEmpty else { return false }
        if behavior == .finishDate {
            guard finishDate >= startDate, let schedule else { return false }
            return schedule.most <= limit
        }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                whenSection
                if plan.behaviors.count > 1 { behaviorSection }
                if behavior == .finishDate { finishSection }
                daysSection
                Section {
                    Picker("How you read", selection: $wayToRead) {
                        ForEach(WayToRead.allCases) { Text($0.label).tag($0) }
                    }
                } footer: {
                    Text("Day by Word never shows Bible text. Read in your own Bible, and mark what you read here.")
                }
                .listRowBackground(Palette.surface)
                reminderSection
                if let failure {
                    Section { Text(verbatim: failure).foregroundStyle(Palette.danger) }
                        .listRowBackground(Palette.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle(Text(verbatim: plan.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { startPlan() }.disabled(!canStart)
                }
            }
            .onAppear(perform: prepare)
        }
    }

    private var whenSection: some View {
        Section {
            if isCalendar {
                Text("You'll join today's readings, \(PlanPresentation.dayText(library.today)).")
            } else {
                DatePicker(
                    "Start on", selection: $start, in: Date.distantPast...Date.distantFuture,
                    displayedComponents: .date)
            }
        } header: {
            Text("When")
        } footer: {
            if isCalendar {
                Text("Each date has its own reading. Earlier dates' readings are not added to today.")
            }
        }
        .listRowBackground(Palette.surface)
    }

    private var behaviorSection: some View {
        Section {
            Picker("Schedule", selection: $behavior) {
                ForEach(plan.behaviors, id: \.self) { Text(verbatim: $0.name).tag($0) }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } header: {
            Text("Schedule")
        } footer: {
            Text(verbatim: behavior.about)
        }
        .listRowBackground(Palette.surface)
    }

    private var finishSection: some View {
        Section {
            DatePicker("Finish by", selection: $finish, in: start..., displayedComponents: .date)
            Stepper(value: $limit, in: 1...10) {
                Text(limit == 1 ? "At most 1 reading a day" : "At most \(limit) readings a day")
            }
            if let schedule {
                if let later = schedule.finishWithinLimit, schedule.most > limit {
                    Text(
                        "To finish by \(PlanPresentation.dayText(finishDate)) you'd read up to \(schedule.most) readings a day. At \(limit) a day you'd finish on \(PlanPresentation.dayText(later))."
                    )
                    Button("Finish on \(PlanPresentation.dayText(later)) instead") {
                        finish = later.start(in: .current)
                    }
                } else {
                    Text(
                        schedule.least != schedule.most
                            ? "\(schedule.least) to \(schedule.most) readings a day, on \(schedule.scheduledDays) reading days."
                            : schedule.most == 1
                                ? "1 reading a day, on \(schedule.scheduledDays) reading days."
                                : "\(schedule.most) readings a day, on \(schedule.scheduledDays) reading days."
                    )
                    if let words = schedule.heaviestWords {
                        Text(
                            verbatim: String(
                                localized:
                                    "\(PlanPresentation.workload(Workload(words: words).minutes)) on the heaviest day. Estimates vary."
                            ))
                    }
                }
            }
        } header: {
            Text("Finish date")
        } footer: {
            Text("If you miss days, you'll be offered a choice, and you'll see it before anything changes.")
        }
        .listRowBackground(Palette.surface)
    }

    private var daysSection: some View {
        Section {
            ForEach(1...7, id: \.self) { day in
                Toggle(
                    PlanPresentation.weekdayName(day),
                    isOn: Binding(
                        get: { readingDays.contains(day) },
                        set: { on in if on { readingDays.insert(day) } else { readingDays.remove(day) } }))
            }
        } header: {
            Text("Reading days")
        } footer: {
            if readingDays.isEmpty {
                Text("Choose at least one day.").foregroundStyle(Palette.danger)
            } else if isCalendar {
                Text("Each date still has its reading. Your reading days decide reminders and nothing else.")
            } else {
                Text(verbatim: presentation.paced + " " + String(localized: "Other days are rest days."))
            }
        }
        .listRowBackground(Palette.surface)
    }

    private var reminderSection: some View {
        Section {
            Toggle("Remind me on reading days", isOn: $reminderOn)
                .onChange(of: reminderOn) { _, on in
                    if on { askForNotifications() }
                }
            if reminderOn {
                DatePicker("At", selection: $reminderTime, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Reminder")
        } footer: {
            if notificationsRefused {
                Text("Notifications are turned off for Day by Word in the Settings app. The plan works without them.")
            } else {
                Text("Optional. A reminder says what's next and nothing more.")
            }
        }
        .listRowBackground(Palette.surface)
    }

    /// Sets the default finish once: the date the plan ends at one reading
    /// each reading day.
    private func prepare() {
        guard !prepared else { return }
        prepared = true
        start = library.today.start(in: .current)
        finish = (paceFinish ?? library.today).start(in: .current)
    }

    private func askForNotifications() {
        Task {
            let granted =
                (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
            notificationsRefused = !granted
        }
    }

    private func startPlan() {
        do {
            try library.start(enrolled)
            onStarted()
        } catch {
            failure = String(localized: "The plan could not be started: \(String(describing: error))")
        }
    }
}
