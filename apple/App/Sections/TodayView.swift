import ReadingData
import ReadingEngine
import SwiftUI
import UIKit

/// Today answers one question: what do I read now? One card for each plan
/// the reader follows, with its label, the references set large, and the
/// controls to copy and mark them (docs/product.md, Today; BUILD.md P8.3,
/// P8.4). Every answer is the engine's `today`; marking records journal
/// events, and each can be undone from the banner.
struct TodayView: View {
    @Environment(Library.self) private var library
    @Environment(AppNavigation.self) private var navigation
    @AppStorage(WayToRead.storageKey) private var wayToRead = WayToRead.physicalBible
    @AppStorage(WayToRead.keepAwakeKey) private var keepAwake = false
    /// The last thing the reader did, for the Undo (or Redo) banner.
    @State private var lastAction: LastAction?
    @State private var failure: String?
    @Environment(\.scenePhase) private var scenePhase

    struct LastAction: Equatable {
        let message: String
        let event: JournalEvent
        /// Whether the action was itself an undo, so the banner offers Redo.
        let isUndo: Bool
        /// What the reader did first, said again when they redo it.
        let original: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                let enrollments = library.activeEnrollments
                if library.catalog == nil || library.journal == nil {
                    StateMessage(
                        kind: .empty(
                            title: String(localized: "Your reading record can't be opened."),
                            message: library.problem ?? ""))
                } else if enrollments.isEmpty {
                    welcome
                } else {
                    let noticed = celebrations
                    ForEach(enrollments, id: \.id) { enrollment in
                        if let plan = library.plan(of: enrollment), let formatter = library.formatter {
                            // After a gap, the welcome comes first (P8.7).
                            if let welcome = enrollment.welcome(on: library.today), let journal = library.journal {
                                WelcomeBack(
                                    welcome: welcome, enrollment: enrollment, journal: journal, plan: plan,
                                    today: library.today, formatter: formatter, act: act)
                            }
                            TodayCard(
                                enrollment: enrollment, plan: plan, today: library.today, formatter: formatter,
                                act: act, todaysMark: todaysMark(enrollment), undoMark: undoMark,
                                celebrations: noticed.compactMap { words($0, in: enrollment, plan: plan) })
                        }
                    }
                    if noticed.contains(.keptRhythm) {
                        Celebrations(words: [String(localized: "You've read on each of your reading days this week.")])
                    }
                }
                if let failure {
                    Text(verbatim: failure).typeStyle(TypeScale.body).foregroundStyle(Palette.danger)
                }
            }
            .frame(maxWidth: ReadableWidth.column, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(Spacing.m)
            .padding(.bottom, lastAction == nil ? 0 : 72)
        }
        .background(Palette.background)
        .navigationTitle("Today")
        .overlay(alignment: .bottom) {
            if let lastAction {
                banner(lastAction)
                    .padding(Spacing.m)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: lastAction)
        // Physical Bible mode may keep the screen awake while Today is open.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = wayToRead == .physicalBible && keepAwake }
        .onChange(of: keepAwake) { UIApplication.shared.isIdleTimerDisabled = wayToRead == .physicalBible && keepAwake }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        // The banner is for what was just done here; once the reader leaves,
        // the widget or a reminder may change the record, and each card
        // offers Undo for today's mark instead.
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { lastAction = nil }
        }
    }

    /// What today quietly notices (P11.2), from the engine.
    private var celebrations: [Celebration] {
        guard let journal = library.journal, let catalog = library.catalog else { return [] }
        return journal.celebrations(on: library.today, in: catalog.versification)
    }

    /// A celebration about this enrollment, in words.
    private func words(_ celebration: Celebration, in enrollment: Enrollment, plan: Plan) -> String? {
        guard celebration.enrollment == enrollment.id else { return nil }
        switch celebration {
        case .returned: return String(localized: "You've picked up where you left off.")
        case .finishedBook(let book, _):
            let name = library.catalog?.registry.book(book)?.name(in: library.convention).name ?? book.rawValue
            return String(localized: "You've read all of \(name).")
        case .finishedPlan: return String(localized: "You've finished \(plan.title).")
        case .keptRhythm: return nil
        }
    }

    /// No plan yet: a short welcome and the way into choosing one.
    private var welcome: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Your next reading will appear here.")
                .typeStyle(TypeScale.referenceList)
                .foregroundStyle(Palette.text)
            Text("Find your plan. Read your Bible. Keep your place.")
                .typeStyle(TypeScale.body)
                .foregroundStyle(Palette.textMuted)
            Button("Choose a plan") { navigation.open(.plans) }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, Spacing.s)
        }
    }

    @ViewBuilder
    private func banner(_ action: LastAction) -> some View {
        if action.isUndo {
            HStack(spacing: Spacing.s) {
                Text(verbatim: action.message).typeStyle(TypeScale.body).foregroundStyle(Palette.text)
                Spacer(minLength: Spacing.xs)
                Button("Redo") { undo(action) }
                    .typeStyle(TypeStyle(size: 17, weight: .semibold, relativeTo: .body))
                    .foregroundStyle(Palette.accent)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.xxs)
            .background(Palette.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.line))
            .accessibilityElement(children: .contain)
        } else {
            UndoBanner(message: action.message) { undo(action) }
        }
    }

    /// Records an event for an enrollment and offers to take it back.
    private func act(_ body: JournalEvent.Body, enrollment: EventID, message: String) {
        do {
            let event = try library.record(body, enrollment: enrollment)
            failure = nil
            lastAction = LastAction(message: message, event: event, isUndo: false, original: message)
        } catch {
            failure = String(localized: "That wasn't saved: \(String(describing: error))")
        }
    }

    /// The last mark made today in an enrollment and still standing, when
    /// the banner is not already offering to undo it: a mark from the widget
    /// or a reminder, or from earlier today (P8.9).
    private func todaysMark(_ enrollment: Enrollment) -> JournalEvent? {
        guard let journal = library.journal else { return nil }
        let mark = journal.events.last { event in
            guard event.enrollment == enrollment.id, case .marked(let marked) = event.body else { return false }
            return marked.date == library.today && journal.isActive(event.id)
        }
        guard let mark, mark.id != lastAction?.event.id else { return nil }
        return mark
    }

    /// Undo for a mark Today did not make in this visit.
    private func undoMark(_ event: JournalEvent, message: String) {
        undo(LastAction(message: message, event: event, isUndo: false, original: message))
    }

    /// Takes back the last action: an undo of a mark, or of an undo (redo).
    private func undo(_ action: LastAction) {
        do {
            let event = try library.record(.undone(target: action.event.id), enrollment: action.event.enrollment)
            failure = nil
            lastAction = LastAction(
                message: action.isUndo ? action.original : String(localized: "Undone."), event: event,
                isUndo: !action.isUndo, original: action.original)
        } catch {
            failure = String(localized: "That wasn't saved: \(String(describing: error))")
        }
    }
}

/// One plan's day: its status in words, and on a day with a reading, the
/// reading with Copy reference, Mark read, and the other ways to mark it.
struct TodayCard: View {
    let enrollment: Enrollment
    let plan: Plan
    let today: CivilDate
    let formatter: ReferenceFormatter
    let act: (JournalEvent.Body, EventID, String) -> Void
    /// The last mark made today, to offer Undo for (P8.9).
    var todaysMark: JournalEvent?
    var undoMark: (JournalEvent, String) -> Void = { _, _ in }
    /// What this plan's day quietly notices, in words (P11.2).
    var celebrations: [String] = []

    @AppStorage(WayToRead.storageKey) private var wayToRead = WayToRead.physicalBible
    @State private var confirmingSkip: Slot?
    @State private var loggingEarlier: EarlierDay?

    private var day: Today { enrollment.today(today) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            switch day.status {
            case .reading:
                ForEach(day.readings, id: \.self) { slot in reading(slot) }
            default:
                Text(verbatim: plan.title)
                    .typeStyle(TypeScale.label)
                    .foregroundStyle(Palette.textMuted)
                Text(verbatim: statusText)
                    .typeStyle(TypeScale.referenceList)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !celebrations.isEmpty { Celebrations(words: celebrations) }
            if let todaysMark, case .marked(let marked) = todaysMark.body {
                let message = markMessage(
                    marked.mark,
                    display: reference(Slot(assignment: marked.assignment, appointed: marked.appointed)).display,
                    on: marked.date)
                HStack(spacing: Spacing.s) {
                    Text(verbatim: message)
                        .typeStyle(TypeScale.body)
                        .foregroundStyle(Palette.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: Spacing.xs)
                    Button("Undo") { undoMark(todaysMark, message) }
                        .typeStyle(TypeStyle(size: 17, weight: .semibold, relativeTo: .body))
                        .foregroundStyle(Palette.accent)
                        .frame(minHeight: 44)
                        .accessibilityHint(Text("Takes back: \(message)"))
                }
            }
            if let note = shortMonthNote {
                Text(verbatim: note)
                    .typeStyle(TypeScale.caption)
                    .foregroundStyle(Palette.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .card()
        .confirmationDialog(
            "Skip this reading?",
            isPresented: Binding(get: { confirmingSkip != nil }, set: { if !$0 { confirmingSkip = nil } }),
            titleVisibility: .visible,
            presenting: confirmingSkip
        ) { slot in
            Button("Skip this reading") {
                confirmingSkip = nil
                mark(.skipped, slot, on: today)
            }
            Button("Cancel", role: .cancel) { confirmingSkip = nil }
        } message: { _ in
            Text("Skip this reading. It won't count as read.")
        }
        .sheet(item: $loggingEarlier) { earlier in
            let slot = earlier.slot
            LogEarlierDaySheet(
                reference: reference(slot), earliest: enrollment.start, latest: today
            ) { date in
                loggingEarlier = nil
                // A calendar plan's earlier day is that date's own reading.
                if plan.schedule == .dayOfMonth {
                    mark(.completed, Slot(assignment: date.day, appointed: date), on: date)
                } else {
                    mark(.completed, slot, on: date)
                }
            } onCancel: {
                loggingEarlier = nil
            }
        }
    }

    /// The words for a day with no reading to show.
    private var statusText: String {
        switch day.status {
        case .upcoming:
            String(localized: "This plan starts on \(PlanPresentation.dayText(enrollment.start)).")
        case .done: String(localized: "That's today's reading.")
        case .open: String(localized: "Nothing more is scheduled today.")
        case .rest: String(localized: "Today is a rest day in this plan.")
        case .paused: String(localized: "This plan is paused.")
        case .finished: String(localized: "You've reached the end of this plan.")
        case .ended, .reading: ""
        }
    }

    /// On a short month's last day, the readings it does not appoint
    /// (docs/engine.md, "Follow the calendar").
    private var shortMonthNote: String? {
        guard let calendar = day.calendar, !calendar.notAppointed.isEmpty else { return nil }
        let month = today.start(in: .current).formatted(.dateTime.month(.wide))
        let days = calendar.notAppointed.map { "\($0)" }.formatted(.list(type: .and))
        return String(
            localized: "\(month) has \(today.daysInMonth) days, so this plan has no reading for day \(days) this month."
        )
    }

    /// "Gospels at your pace — Reading 12", or "— Day 21" by the date.
    private func label(_ slot: Slot) -> String {
        if let appointed = slot.appointed {
            return String(localized: "\(plan.title) — Day \(appointed.day)")
        }
        let position = enrollment.plan.positions[slot.assignment] ?? slot.assignment
        return String(localized: "\(plan.title) — Reading \(position)")
    }

    private func reading(of slot: Slot) -> Reading? {
        plan.assignments.first { $0.id == slot.assignment }?.reading
    }

    private func reference(_ slot: Slot) -> ReferenceText {
        guard let reading = plan.assignments.first(where: { $0.id == slot.assignment })?.reading else {
            return ReferenceText(display: "", spoken: "")
        }
        return ReferenceText(reading, formatter: formatter)
    }

    private func reading(_ slot: Slot) -> some View {
        let reference = reference(slot)
        return VStack(alignment: .leading, spacing: Spacing.s) {
            Text(verbatim: label(slot))
                .typeStyle(TypeScale.label)
                .foregroundStyle(Palette.textMuted)
            ReferenceBlock(reference: reference)
            if wayToRead == .physicalBible, let reading = reading(of: slot) {
                // Physical Bible mode: where to find it in print (P8.6).
                ForEach(PlaceInPrint.lines(reading, formatter: formatter), id: \.self) { line in
                    Text(verbatim: line)
                        .typeStyle(TypeScale.body)
                        .foregroundStyle(Palette.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityHidden(true)
            }
            ActionRow {
                if wayToRead == .youVersion, let reading = reading(of: slot) {
                    OpenInYouVersion(reading: reading, formatter: formatter, spoken: reference.spoken)
                }
                CopyReferenceButton(reference: reference)
                Menu {
                    Button("Mark part read") { mark(.partlyCompleted, slot, on: today) }
                    Button("Skip this reading…") { confirmingSkip = slot }
                    Button("Log an earlier day…") { loggingEarlier = EarlierDay(slot: slot) }
                } label: {
                    Text("More")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint(Text("Mark part read, skip, or log an earlier day."))
            }
            if wayToRead == .youVersion, let reading = reading(of: slot) {
                OpenInYouVersionNote(reading: reading, formatter: formatter)
            }
            Button("Mark read") { mark(.completed, slot, on: today) }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityHint(Text("Marks \(reference.spoken) read today."))
        }
    }

    private func markMessage(_ mark: JournalEvent.Mark, display: String, on date: CivilDate) -> String {
        switch mark {
        case .completed:
            date == today
                ? String(localized: "Marked \(display) read.")
                : String(localized: "Marked \(display) read on \(PlanPresentation.dayText(date)).")
        case .partlyCompleted: String(localized: "Marked \(display) part read.")
        case .skipped: String(localized: "Skipped \(display). It won't count as read.")
        }
    }

    private func mark(_ mark: JournalEvent.Mark, _ slot: Slot, on date: CivilDate) {
        let message = markMessage(mark, display: reference(slot).display, on: date)
        act(
            .marked(.init(mark, assignment: slot.assignment, date: date, appointed: slot.appointed)), enrollment.id,
            message)
    }
}

/// Quiet celebrations (docs/product.md, Progress; BUILD.md P11.2): a few
/// words on the accent tint, never confetti, a badge or a count of days.
struct Celebrations: View {
    let words: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            ForEach(words, id: \.self) { line in
                Text(verbatim: line)
                    .typeStyle(TypeScale.body)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// A slot to log on an earlier day, for the sheet that asks which day.
struct EarlierDay: Identifiable {
    let slot: Slot
    var id: Slot { slot }
}

/// "Log an earlier day": records a reading on the date it happened, never
/// as today's (docs/product.md, "Marking honestly").
struct LogEarlierDaySheet: View {
    let reference: ReferenceText
    let earliest: CivilDate
    let latest: CivilDate
    let onLog: (CivilDate) -> Void
    let onCancel: () -> Void
    @State private var date = Date.now

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Read on", selection: $date,
                        in: earliest.start(in: .current)...latest.start(in: .current),
                        displayedComponents: .date)
                } footer: {
                    Text("The reading is kept on the day you read it, not today.")
                }
                .listRowBackground(Palette.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle(Text(verbatim: reference.display))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        onLog((try? CivilDate(date, in: .current)) ?? latest)
                    }
                }
            }
            .onAppear {
                let yesterday = (try? latest.adding(days: -1)) ?? latest
                date = max(earliest, yesterday).start(in: .current)
            }
        }
        .presentationDetents([.medium])
    }
}
