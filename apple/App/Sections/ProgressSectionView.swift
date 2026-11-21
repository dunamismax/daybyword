import ReadingData
import ReadingEngine
import SwiftUI

/// Progress, first version (BUILD.md P8.12): recent reading days as a plain
/// week strip, and for each plan the readings by state and the next
/// reading. It describes activity and nothing more: no score, no streak
/// unless the reader asks for one (P11.3), and no comparison. (SwiftUI
/// already has a `ProgressView`.)
struct ProgressSectionView: View {
    @Environment(Library.self) private var library

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                if let journal = library.journal, !journal.enrollments.isEmpty, let formatter = library.formatter {
                    weekStrip(journal)
                    ForEach(journal.enrollments, id: \.id) { enrollment in
                        if let plan = library.plan(of: enrollment) {
                            PlanProgress(
                                enrollment: enrollment, plan: plan, today: library.today, formatter: formatter)
                        }
                    }
                    Text("This describes what you've marked, and nothing more.")
                        .typeStyle(TypeScale.caption)
                        .foregroundStyle(Palette.textMuted)
                } else {
                    StateMessage(
                        kind: .empty(
                            title: String(localized: "Your reading record will appear here."),
                            message: String(localized: "It describes what you've read, and nothing more.")))
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(Spacing.m)
        }
        .background(Palette.background)
        .navigationTitle("Progress")
    }

    /// The seven days ending today: each says in words and a symbol whether
    /// the reader read, and rest days are named as rest days.
    private func weekStrip(_ journal: Journal) -> some View {
        let days = journal.recentDays(ending: library.today)
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Recent days")
                .typeStyle(TypeStyle(size: 17, weight: .bold, relativeTo: .headline))
                .foregroundStyle(Palette.text)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: Spacing.xxs) {
                ForEach(days, id: \.date) { day in
                    let name = PlanPresentation.weekdayName(day.date)
                    VStack(spacing: Spacing.xxs) {
                        Text(verbatim: String(name.prefix(1)))
                            .typeStyle(TypeScale.caption)
                            .foregroundStyle(Palette.textMuted)
                        Text(verbatim: day.isRead ? "✓" : (day.isReadingDay ? "○" : "–"))
                            .typeStyle(TypeScale.label)
                            .foregroundStyle(day.isRead ? Palette.accent : Palette.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        Text(
                            day.isRead
                                ? "\(PlanPresentation.dayText(day.date)), read"
                                : day.isReadingDay
                                    ? "\(PlanPresentation.dayText(day.date)), not read"
                                    : "\(PlanPresentation.dayText(day.date)), rest day"))
                }
            }
            Text("✓ read · ○ a reading day · – a rest day")
                .typeStyle(TypeScale.caption)
                .foregroundStyle(Palette.textMuted)
        }
        .card(padding: Spacing.m)
    }
}

/// One plan's record: readings by state, and the next reading.
private struct PlanProgress: View {
    let enrollment: Enrollment
    let plan: Plan
    let today: CivilDate
    let formatter: ReferenceFormatter

    var body: some View {
        let counts = enrollment.counts(on: today)
        let day = enrollment.today(today)
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(verbatim: plan.title)
                .typeStyle(TypeStyle(size: 17, weight: .bold, relativeTo: .headline))
                .foregroundStyle(Palette.text)
                .accessibilityAddTraits(.isHeader)
            if enrollment.ended != nil {
                Text("You stopped following this plan.").foregroundStyle(Palette.textMuted)
            }
            Text(
                counts.total == 1
                    ? "\(counts.read) of 1 reading read"
                    : "\(counts.read) of \(counts.total) readings read"
            )
            .foregroundStyle(Palette.text)
            let others = [
                counts.partlyRead > 0 ? String(localized: "\(counts.partlyRead) part read") : nil,
                counts.skipped > 0 ? String(localized: "\(counts.skipped) skipped") : nil,
            ].compactMap { $0 }
            if !others.isEmpty {
                Text(verbatim: others.joined(separator: " · ")).foregroundStyle(Palette.textMuted)
            }
            if enrollment.isFinished {
                Text("You've reached the end of this plan.").foregroundStyle(Palette.textMuted)
            } else if let next = (day.readings.first ?? day.next), enrollment.ended == nil,
                let reading = plan.assignments.first(where: { $0.id == next.assignment })?.reading
            {
                Text("Next: \(formatter.string(for: reading))").foregroundStyle(Palette.text)
            }
            if let finish = day.projection?.plan, enrollment.ended == nil {
                Text("At one reading each reading day, you'd finish on \(PlanPresentation.dayText(finish)).")
                    .foregroundStyle(Palette.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let schedule = day.schedule, enrollment.ended == nil {
                Text("Your finish date is \(PlanPresentation.dayText(schedule.finish)).")
                    .foregroundStyle(Palette.textMuted)
            }
        }
        .typeStyle(TypeScale.body)
        .card(padding: Spacing.m)
        .accessibilityElement(children: .combine)
    }
}
