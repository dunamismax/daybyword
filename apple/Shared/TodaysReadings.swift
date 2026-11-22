import Foundation
import ReadingData
import ReadingEngine

/// Today's reading in each plan the reader follows, as the widgets and Siri
/// name it (BUILD.md P12.2, P12.4): the first reading each plan has to read
/// now, in the order the plans were started. Every answer is the engine's
/// `today` (docs/engine.md, "Today"); this only puts it into words.
struct TodaysReading: Hashable {
    let enrollment: EventID
    let slot: Slot
    let plan: String
    /// "Reading 12", or "Day 21" by the date.
    let label: String
    /// "Mark 4:1–20", under the reader's book names.
    let reference: String
    /// "Mark, chapter 4, verses 1 to 20", for VoiceOver and Siri.
    let spoken: String

    /// The first reading to read now in each active plan.
    static func all(
        in enrollments: [Enrollment], catalog: Catalog, today: CivilDate, formatter: ReferenceFormatter
    ) -> [TodaysReading] {
        enrollments.filter { $0.ended == nil }.compactMap { enrollment in
            let day = enrollment.today(today)
            guard day.status == .reading, let slot = day.readings.first, let plan = catalog.plan(enrollment.plan.id),
                let reading = plan.assignments.first(where: { $0.id == slot.assignment })?.reading
            else { return nil }
            let label = label(slot, in: enrollment)
            return TodaysReading(
                enrollment: enrollment.id, slot: slot, plan: plan.title, label: label,
                reference: formatter.string(for: reading), spoken: SpokenReference.text(reading, formatter: formatter))
        }
    }

    /// "Reading 12" by its place in the plan, or "Day 21" by the date.
    static func label(_ slot: Slot, in enrollment: Enrollment) -> String {
        slot.appointed.map { String(localized: "Day \($0.day)") }
            ?? String(localized: "Reading \(enrollment.plan.positions[slot.assignment] ?? slot.assignment)")
    }

    /// Today's words for a day whose reading is read.
    static var doneText: String { String(localized: "That's today's reading.") }

    /// The words Today uses for a day with nothing to read now.
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
