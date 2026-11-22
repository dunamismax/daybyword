import ReadingData
import ReadingEngine
import SwiftUI

/// One plan's history (BUILD.md P11.5; docs/product.md, Progress): every
/// reading of the record with its state, a reading marked read on a chosen
/// date (late logging) or its last mark taken back, every change newest
/// first, and the plan itself paused, resumed, stopped or followed again.
/// Every answer is the engine's; each action is one journal event, and
/// nothing is ever deleted.
struct PlanHistoryView: View {
    @Environment(Library.self) private var library
    let enrollmentID: EventID
    /// The day a reading marked read here is kept on.
    @State private var readOn = Date.now
    @State private var confirmingEnd = false
    /// The reminder time to offer for the calendar file, while asking.
    @State private var calendarTime: WallTime?
    @State private var failure: String?

    var body: some View {
        Group {
            if let journal = library.journal,
                let enrollment = journal.enrollments.first(where: { $0.id == enrollmentID }),
                let plan = library.plan(of: enrollment), let formatter = library.formatter
            {
                history(journal: journal, enrollment: enrollment, plan: plan, formatter: formatter)
            } else {
                StateMessage(kind: .empty(title: String(localized: "This plan isn't in your record."), message: ""))
            }
        }
        .readableRows()
        .background(Palette.background)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func history(journal: Journal, enrollment: Enrollment, plan: Plan, formatter: ReferenceFormatter)
        -> some View
    {
        let today = library.today
        let isCalendar = plan.schedule == .dayOfMonth
        return Form {
            Section {
                Text(verbatim: plan.title)
                    .typeStyle(TypeStyle(size: 17, weight: .bold, relativeTo: .headline))
                    .foregroundStyle(Palette.text)
                    .accessibilityAddTraits(.isHeader)
                if enrollment.ended == nil {
                    DatePicker(
                        "Read on", selection: $readOn,
                        in: enrollment.start.start(in: .current)...today.start(in: .current),
                        displayedComponents: .date)
                }
            } footer: {
                Group {
                    if enrollment.ended == nil {
                        Text("Mark read keeps the reading on this date.")
                    }
                }
                .sectionNote()
            }
            .listRowBackground(Palette.surface)

            Section {
                ForEach(enrollment.recordSlots(on: today), id: \.self) { slot in
                    let mark = enrollment.settled.first { $0.slot == slot }
                    reading(
                        slot, mark: mark, enrollment: enrollment, plan: plan, formatter: formatter,
                        markable: mark?.state != .read && (isCalendar || mark != nil))
                }
            } header: {
                Text("Readings").sectionNote()
            }
            .listRowBackground(Palette.surface)

            Section {
                ForEach(changes(journal, enrollment: enrollment, plan: plan, formatter: formatter), id: \.self) {
                    Text(verbatim: $0).fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text("Changes").sectionNote()
            }
            .listRowBackground(Palette.surface)

            Section {
                actions(journal: journal, enrollment: enrollment)
                if let failure {
                    Text(verbatim: failure).foregroundStyle(Palette.danger)
                }
            } header: {
                Text("This plan").sectionNote()
            } footer: {
                Group {
                    if enrollment.ended == nil, !enrollment.isPaused(today), !enrollment.isFinished {
                        Text("Pausing stops its reminders and keeps your place; nothing is moved or marked.")
                    }
                }
                .sectionNote()
            }
            .listRowBackground(Palette.surface)
        }
        .scrollContentBackground(.hidden)
        .typeStyle(TypeScale.body)
        // Today as the app resolved it (E7), not the clock's instant.
        .onAppear { readOn = today.start(in: .current) }
        .confirmationDialog(
            "Add the next four weeks to a calendar", isPresented: calendarAsking, titleVisibility: .visible,
            presenting: calendarTime
        ) { time in
            Button("At my reminder time, \(RemindersSection.timeText(time))") { shareCalendar(enrollment, time: time) }
            Button("All day") { shareCalendar(enrollment, time: nil) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("The calendar keeps these dates. If your plan moves, add the weeks again.")
        }
        .confirmationDialog(
            "Stop following this plan?", isPresented: $confirmingEnd, titleVisibility: .visible
        ) {
            Button("Stop following this plan", role: .destructive) { record(.ended(date: today)) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Its record is kept, and you can follow it again from Progress.")
        }
    }

    /// One reading: its label, its reference and its state in words, with
    /// Mark read where it can be marked here and Undo where it is settled.
    private func reading(
        _ slot: Slot, mark: SlotMark?, enrollment: Enrollment, plan: Plan, formatter: ReferenceFormatter,
        markable: Bool
    ) -> some View {
        let reference = plan.assignments.first { $0.id == slot.assignment }.map { formatter.string(for: $0.reading) }
        let label =
            slot.appointed.map { PlanPresentation.dayText($0) }
            ?? String(localized: "Reading \(enrollment.plan.positions[slot.assignment] ?? slot.assignment)")
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: label).typeStyle(TypeScale.label).foregroundStyle(Palette.textMuted)
                Text(verbatim: reference ?? "").fontWeight(.semibold).foregroundStyle(Palette.text)
                Text(verbatim: Self.state(mark)).foregroundStyle(Palette.textMuted)
            }
            .accessibilityElement(children: .combine)
            if enrollment.ended == nil, markable || mark != nil {
                HStack(spacing: Spacing.m) {
                    if markable {
                        Button("Mark read") {
                            record(
                                .marked(
                                    .init(
                                        .completed, assignment: slot.assignment, date: readOnDay(enrollment),
                                        appointed: slot.appointed)))
                        }
                        .accessibilityHint(Text("Marks \(reference ?? "") read on the date above."))
                    }
                    if let mark {
                        Button("Undo") { record(.undone(target: mark.event)) }
                            .accessibilityHint(Text("Takes back: \(Self.state(mark))"))
                    }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Palette.accent)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }

    /// "Read on Monday 1 March", "Part read on …", "Skipped on …", or "Not
    /// yet read".
    static func state(_ mark: SlotMark?) -> String {
        guard let mark else { return String(localized: "Not yet read") }
        let day = PlanPresentation.dayText(mark.date)
        return switch mark.state {
        case .read: String(localized: "Read on \(day)")
        case .partlyRead: String(localized: "Part read on \(day)")
        case .skipped: String(localized: "Skipped on \(day)")
        case .unread: String(localized: "Not yet read")
        }
    }

    /// The plan's events that mean something, newest first, in words.
    private func changes(_ journal: Journal, enrollment: Enrollment, plan: Plan, formatter: ReferenceFormatter)
        -> [String]
    {
        let inert = Set(journal.inert.map(\.event))
        let events = journal.events.filter { $0.enrollment == enrollment.id && !inert.contains($0.id) }
        func reference(_ assignment: Int) -> String {
            plan.assignments.first { $0.id == assignment }.map { formatter.string(for: $0.reading) }
                ?? String(assignment)
        }
        func describe(_ event: JournalEvent) -> String? {
            switch event.body {
            case .enrolled(let enrolled):
                return String(localized: "Started the plan from \(PlanPresentation.dayText(enrolled.start)).")
            case .marked(let marked):
                let (ref, day) = (reference(marked.assignment), PlanPresentation.dayText(marked.date))
                return switch marked.mark {
                case .completed: String(localized: "Marked \(ref) read on \(day).")
                case .partlyCompleted: String(localized: "Marked \(ref) part read on \(day).")
                case .skipped: String(localized: "Skipped \(ref) on \(day).")
                }
            case .undone(let target):
                guard let undone = journal.events.first(where: { $0.id == target }), let change = describe(undone)
                else { return nil }
                return String(localized: "Took back: \(change)")
            case .changed(let changed):
                let what = [
                    changed.readingDays != nil ? String(localized: "the reading days") : nil,
                    changed.behavior != nil ? String(localized: "the schedule") : nil,
                    changed.basis != nil ? String(localized: "the finish date") : nil,
                    changed.limit != nil ? String(localized: "the most readings a day") : nil,
                    changed.reminder != nil ? String(localized: "the reminder") : nil,
                    changed.start != nil ? String(localized: "the start date") : nil,
                ].compactMap { $0 }.formatted(.list(type: .and))
                return String(localized: "Changed \(what) from \(PlanPresentation.dayText(changed.from)).")
            case .paused(let from):
                return String(localized: "Paused from \(PlanPresentation.dayText(from)).")
            case .resumed(let from, _):
                return String(localized: "Resumed on \(PlanPresentation.dayText(from)).")
            case .returned(let date, let choice, _):
                let title =
                    switch choice {
                    case .continue: String(localized: "Continue from where I left off")
                    case .spread: String(localized: "Spread the readings over the days ahead")
                    case .moveFinish: String(localized: "Move my finish date")
                    case .rejoin: String(localized: "Rejoin today's readings")
                    }
                return String(localized: "Answered the welcome back on \(PlanPresentation.dayText(date)): \(title).")
            case .ended(let date):
                return String(localized: "Stopped following the plan on \(PlanPresentation.dayText(date)).")
            }
        }
        return events.reversed().compactMap(describe)
    }

    /// Pause, resume, stop following or follow again, as the plan stands today.
    @ViewBuilder
    private func actions(journal: Journal, enrollment: Enrollment) -> some View {
        let today = library.today
        if enrollment.ended != nil {
            if let ended = journal.events.last(where: {
                guard $0.enrollment == enrollment.id, case .ended = $0.body else { return false }
                return journal.isActive($0.id)
            }) {
                Button("Follow this plan again") { record(.undone(target: ended.id)) }
            }
        } else {
            if enrollment.isPaused(today) {
                Button("Resume this plan") { record(.resumed(from: today, basis: nil)) }
            } else if !enrollment.isFinished {
                Button("Pause this plan") { record(.paused(from: today)) }
                Button("Add the next four weeks to a calendar…") {
                    // At the reminder time, or all day, when the plan has one.
                    if let time = enrollment.arrangement(on: today).reminder {
                        calendarTime = time
                    } else {
                        shareCalendar(enrollment, time: nil)
                    }
                }
                .accessibilityHint(Text("Shares a calendar file of this plan's readings for the next four weeks."))
            }
            Button("Stop following this plan", role: .destructive) { confirmingEnd = true }
        }
    }

    /// A calendar file of the plan's readings ahead, through the share sheet
    /// (P13.4): a snapshot, so it says how far it reaches.
    private func shareCalendar(_ enrollment: Enrollment, time: WallTime?) {
        guard let plan = library.plan(of: enrollment), let formatter = library.formatter else { return }
        do {
            let events = CalendarFile.events(enrollment, plan: plan, from: library.today, formatter: formatter)
            ShareSheet.present(try CalendarFile.file(events, plan: plan.title, time: time, now: library.now))
            failure = nil
        } catch {
            failure = String(localized: "That wasn't saved: \(String(describing: error))")
        }
    }

    private var calendarAsking: Binding<Bool> {
        Binding(get: { calendarTime != nil }, set: { if !$0 { calendarTime = nil } })
    }

    /// The date chosen above, kept between the plan's start and today.
    private func readOnDay(_ enrollment: Enrollment) -> CivilDate {
        let chosen = (try? CivilDate(readOn, in: .current)) ?? library.today
        return min(max(chosen, enrollment.start), library.today)
    }

    private func record(_ body: JournalEvent.Body) {
        do {
            try library.record(body, enrollment: enrollmentID)
            failure = nil
        } catch {
            failure = String(localized: "That wasn't saved: \(String(describing: error))")
        }
    }
}
