import ReadingData
import ReadingEngine
import SwiftUI

/// Progress (BUILD.md P8.12, P11.1): recent reading days as a plain week
/// strip, the books explored in any plan, and for each plan the readings by
/// state and the next reading. It describes activity and nothing more: no score, no streak
/// unless the reader asks for one (P11.3), and no comparison. (SwiftUI
/// already has a `ProgressView`.)
struct ProgressSectionView: View {
    @Environment(Library.self) private var library

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                if let journal = library.journal, !journal.enrollments.isEmpty, let formatter = library.formatter {
                    weekStrip(journal)
                    if let catalog = library.catalog {
                        booksExplored(journal, catalog: catalog)
                    }
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

    /// The books read in, in any plan, in the Bible's order (P11.1), kept
    /// apart from each plan's record: reading in a book is not finishing a
    /// plan, and finishing a plan is not reading these books whole.
    @ViewBuilder
    private func booksExplored(_ journal: Journal, catalog: Catalog) -> some View {
        let books = journal.coverage(in: catalog.versification).books.compactMap {
            catalog.registry.book($0)?.name(in: library.convention).name
        }
        if !books.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Books explored")
                    .typeStyle(TypeScale.referenceList)
                    .foregroundStyle(Palette.text)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: books.formatted(.list(type: .and)))
                    .typeStyle(TypeScale.body)
                    .foregroundStyle(Palette.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("The books you've marked a reading in, in any plan. Reading in a book is not reading all of it.")
                    .typeStyle(TypeScale.caption)
                    .foregroundStyle(Palette.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(padding: Spacing.m)
        }
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
