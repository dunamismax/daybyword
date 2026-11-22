import ReadingEngine
import SwiftUI
import UserNotifications
import WidgetKit

/// Reminders in Settings (BUILD.md P8.8, docs/product.md "Reminders and
/// notifications"): each plan's reminder, which is in the journal, and this
/// device's settings for how reminders may interrupt. Turning reminders off
/// never limits the app.
struct RemindersSection: View {
    @Environment(Library.self) private var library
    @Environment(ReminderScheduler.self) private var reminders
    @AppStorage(ReminderPreferences.showReadingKey) private var showsReading = true
    @AppStorage(ReminderPreferences.quietHoursKey) private var quietHours = false
    @AppStorage(ReminderPreferences.quietFromKey) private var quietFrom = ReminderPreferences.defaultQuietFrom
    @AppStorage(ReminderPreferences.quietUntilKey) private var quietUntil = ReminderPreferences.defaultQuietUntil
    @AppStorage(ReminderPreferences.mostADayKey) private var mostADay = 0

    var body: some View {
        Section {
            ForEach(library.activeEnrollments, id: \.id) { enrollment in
                if let plan = library.plan(of: enrollment) {
                    NavigationLink {
                        ReminderEditor(enrollment: enrollment, plan: plan)
                    } label: {
                        LabeledContent {
                            Text(verbatim: Self.timeText(enrollment.arrangement(on: library.today).reminder))
                        } label: {
                            Text(verbatim: plan.title)
                        }
                    }
                }
            }
            Toggle("Name the reading in reminders and on the Lock Screen", isOn: $showsReading)
            Toggle("Quiet hours", isOn: $quietHours)
            if quietHours {
                DatePicker("From", selection: time($quietFrom), displayedComponents: .hourAndMinute)
                DatePicker("Until", selection: time($quietUntil), displayedComponents: .hourAndMinute)
            }
            Picker("Reminders a day", selection: $mostADay) {
                Text("No limit").tag(0)
                ForEach(1...3, id: \.self) { count in
                    Text(count == 1 ? "At most 1" : "At most \(count)").tag(count)
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            footer
        }
        .listRowBackground(Palette.surface)
        .onChange(of: showsReading) {
            reminders.setNeedsReschedule()
            // The Lock Screen widgets follow it too (P12.2).
            SharedJournal.defaults.set(showsReading, forKey: ReminderPreferences.showReadingKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: quietHours) { reminders.setNeedsReschedule() }
        .onChange(of: quietFrom) { reminders.setNeedsReschedule() }
        .onChange(of: quietUntil) { reminders.setNeedsReschedule() }
        .onChange(of: mostADay) { reminders.setNeedsReschedule() }
    }

    @ViewBuilder
    private var footer: some View {
        if reminders.authorization == .denied {
            Text(
                "Notifications are turned off for Day by Word in the Settings app, so no reminders arrive. Everything else works without them."
            )
        } else if showsReading {
            Text(
                "A reminder says the plan and its reading, and nothing more. Inside quiet hours it waits until they end, or is left out if they last past midnight."
            )
        } else {
            Text("A reminder says only the plan's name, so no passage shows on the Lock Screen.")
        }
    }

    /// A time kept as minutes after midnight, for a time picker.
    private func time(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding {
            Calendar.current.date(
                bySettingHour: minutes.wrappedValue / 60, minute: minutes.wrappedValue % 60, second: 0, of: .now)
                ?? .now
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            minutes.wrappedValue = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        }
    }

    /// "7:00 AM", or "Off".
    static func timeText(_ time: WallTime?) -> String {
        guard let time,
            let date = Calendar.current.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: .now)
        else { return String(localized: "Off") }
        return date.formatted(date: .omitted, time: .shortened)
    }
}

/// One plan's reminder: on or off, and its time. Saving records a `changed`
/// event from today; earlier days keep the reminder they had.
struct ReminderEditor: View {
    let enrollment: Enrollment
    let plan: Plan

    @Environment(Library.self) private var library
    @Environment(ReminderScheduler.self) private var reminders
    @Environment(\.dismiss) private var dismiss
    @State private var isOn = false
    @State private var time = Date.now
    @State private var prepared = false
    @State private var failure: String?

    private var chosen: JournalEvent.Reminder {
        guard isOn else { return .off }
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        return WallTime(hour: parts.hour ?? 7, minute: parts.minute ?? 0).map { .at($0) } ?? .off
    }

    private var current: JournalEvent.Reminder {
        enrollment.arrangement(on: library.today).reminder.map { .at($0) } ?? .off
    }

    var body: some View {
        Form {
            Section {
                Toggle("Remind me on reading days", isOn: $isOn)
                    .onChange(of: isOn) { _, on in
                        if on, reminders.authorization == .notDetermined {
                            Task { _ = await reminders.askForPermission() }
                        }
                    }
                if isOn {
                    DatePicker("At", selection: $time, displayedComponents: .hourAndMinute)
                }
            } footer: {
                if let failure {
                    Text(verbatim: failure).foregroundStyle(Palette.danger)
                } else {
                    Text("From today on. A reminder says what's next and nothing more.")
                }
            }
            .listRowBackground(Palette.surface)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .navigationTitle(Text(verbatim: plan.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.disabled(chosen == current)
            }
        }
        .onAppear {
            guard !prepared else { return }
            prepared = true
            let reminder = enrollment.arrangement(on: library.today).reminder
            isOn = reminder != nil
            let wall = reminder ?? WallTime(hour: 7, minute: 0)!
            time = Calendar.current.date(bySettingHour: wall.hour, minute: wall.minute, second: 0, of: .now) ?? .now
        }
    }

    private func save() {
        do {
            try library.record(
                .changed(enrollment.change(from: library.today, reminder: chosen)), enrollment: enrollment.id)
            dismiss()
        } catch {
            failure = String(localized: "That wasn't saved: \(String(describing: error))")
        }
    }
}
