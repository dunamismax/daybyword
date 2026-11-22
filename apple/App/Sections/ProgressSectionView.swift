import ReadingData
import ReadingEngine
import SwiftUI

/// Progress (BUILD.md P8.12, P11.1): recent reading days as a plain week
/// strip, the books explored in any plan, and for each plan the readings by
/// state and the next reading. It describes activity and nothing more: no score, no streak
/// unless the reader turns it on in Settings (D17, P11.3), and no comparison. (SwiftUI
/// already has a `ProgressView`.)
struct ProgressSectionView: View {
    @Environment(Library.self) private var library
    @AppStorage(StreakDisplay.storageKey) private var streak = StreakDisplay.off

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                if let journal = library.journal, !journal.enrollments.isEmpty, let formatter = library.formatter {
                    weekStrip(journal)
                    if let catalog = library.catalog {
                        booksExplored(journal, catalog: catalog)
                    }
                    // The archive (P11.5): plans being read first, then
                    // paused, finished and stopped ones, each under its heading.
                    ForEach(PlanGroup.allCases, id: \.self) { group in
                        let members = journal.enrollments.filter { PlanGroup($0, on: library.today) == group }
                        if !members.isEmpty {
                            Text(group.title)
                                .typeStyle(TypeScale.referenceList)
                                .foregroundStyle(Palette.text)
                                .accessibilityAddTraits(.isHeader)
                                .padding(.top, Spacing.s)
                            ForEach(members, id: \.id) { enrollment in
                                if let plan = library.plan(of: enrollment) {
                                    PlanProgress(
                                        enrollment: enrollment, plan: plan, today: library.today,
                                        formatter: formatter)
                                }
                            }
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
            .frame(maxWidth: ReadableWidth.column, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(Spacing.m)
        }
        .background(Palette.background)
        .navigationTitle("Progress")
    }

    /// The books read in, in any plan, in the Bible's order (P11.1), each
    /// with its verses read, each once, and its chapters read in full and in
    /// part (P11.4). Kept apart from each plan's record: reading in a book is
    /// not finishing a plan, and finishing a plan is not reading these books
    /// whole.
    @ViewBuilder
    private func booksExplored(_ journal: Journal, catalog: Catalog) -> some View {
        let books = journal.coverage(in: catalog.versification).byBook(in: catalog.versification)
        if !books.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Books explored")
                    .typeStyle(TypeScale.referenceList)
                    .foregroundStyle(Palette.text)
                    .accessibilityAddTraits(.isHeader)
                ForEach(books, id: \.book) { book in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(
                            verbatim: catalog.registry.book(book.book)?.name(in: library.convention).name
                                ?? book.book.rawValue
                        )
                        .typeStyle(TypeStyle(size: 17, weight: .semibold, relativeTo: .body))
                        .foregroundStyle(Palette.text)
                        Text(verbatim: Self.explored(book))
                            .typeStyle(TypeScale.body)
                            .foregroundStyle(Palette.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
                Text(
                    "The books you've marked a reading in, in any plan. Each verse counts once, and a chapter read in part is not counted as read."
                )
                .typeStyle(TypeScale.caption)
                .foregroundStyle(Palette.textMuted)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(padding: Spacing.m)
        }
    }

    /// What of a book was read, in words: "98 of 1,533 verses · 3 chapters
    /// read in full · 1 chapter in part", or "All 85 verses".
    static func explored(_ book: BookCoverage) -> String {
        if book.isWhole { return String(localized: "All \(book.of) verses") }
        var parts = [String(localized: "\(book.verses) of \(book.of) verses")]
        if book.wholeChapters == 1 {
            parts.append(String(localized: "1 chapter read in full"))
        } else if book.wholeChapters > 1 {
            parts.append(String(localized: "\(book.wholeChapters) chapters read in full"))
        }
        if book.partialChapters == 1 {
            parts.append(String(localized: "1 chapter in part"))
        } else if book.partialChapters > 1 {
            parts.append(String(localized: "\(book.partialChapters) chapters in part"))
        }
        return parts.joined(separator: " · ")
    }

    /// The seven days ending today: each says in words and a symbol whether
    /// the reader read, and rest days are named as rest days.
    private func weekStrip(_ journal: Journal) -> some View {
        let days = journal.recentDays(ending: library.today)
        // The streak, only when the reader turned it on (D17).
        let inARow = streak == .on ? journal.streak(on: library.today) : 0
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
            // Small, in words, and said only while there is one: never a zero,
            // never as something lost.
            if inARow > 0 {
                Text(
                    inARow == 1
                        ? String(localized: "1 reading day in a row")
                        : String(localized: "\(inARow) reading days in a row")
                )
                .typeStyle(TypeScale.caption)
                .foregroundStyle(Palette.text)
                .padding(.top, Spacing.xxs)
            }
        }
        .card(padding: Spacing.m)
    }
}

/// Where a plan stands, for the archive on Progress (P11.5).
enum PlanGroup: CaseIterable {
    case reading
    case paused
    case finished
    case stopped

    init(_ enrollment: Enrollment, on date: CivilDate) {
        if enrollment.ended != nil {
            self = .stopped
        } else if enrollment.isFinished {
            self = .finished
        } else if enrollment.isPaused(date) {
            self = .paused
        } else {
            self = .reading
        }
    }

    var title: String {
        switch self {
        case .reading: String(localized: "Reading now")
        case .paused: String(localized: "Paused")
        case .finished: String(localized: "Finished")
        case .stopped: String(localized: "Stopped")
        }
    }
}

/// One plan's record: readings by state, and the next reading.
private struct PlanProgress: View {
    let enrollment: Enrollment
    let plan: Plan
    let today: CivilDate
    let formatter: ReferenceFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            record
            // Every reading's state and every change (P11.5).
            NavigationLink(value: Destination.history(enrollment.id)) {
                Text("History")
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.accent)
                    .frame(minHeight: 44)
            }
            .accessibilityHint(Text("Every reading of \(plan.title), and every change."))
        }
        .typeStyle(TypeScale.body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: Spacing.m)
    }

    private var record: some View {
        let counts = enrollment.counts(on: today)
        let day = enrollment.today(today)
        return VStack(alignment: .leading, spacing: Spacing.xs) {
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
        .accessibilityElement(children: .combine)
    }
}
