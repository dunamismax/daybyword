/// What the reader did that Day by Word quietly notices on the day it
/// happened (docs/engine.md, "Quiet celebrations"): words, never confetti,
/// never a comparison with anyone, and never a count of days. Like every
/// record they describe activity.
public enum Celebration: Hashable, Sendable {
    /// Reading again after a gap. "You've picked up where you left off."
    case returned(enrollment: EventID)
    /// Every verse of a book now read in this enrollment. "You've read all
    /// of Ruth."
    case finishedBook(BookID, enrollment: EventID)
    /// A sequence with no unread reading left. "You've finished Gospels at
    /// your pace."
    case finishedPlan(enrollment: EventID)
    /// Every reading day of the week read, on the last of them. "You've read
    /// on each of your reading days this week."
    case keptRhythm

    /// The enrollment it is about, or nil for the week's rhythm.
    public var enrollment: EventID? {
        switch self {
        case .returned(let enrollment), .finishedBook(_, let enrollment), .finishedPlan(let enrollment): enrollment
        case .keptRhythm: nil
        }
    }
}

extension Journal {
    /// The celebrations on `date`: for each enrollment that has not ended, in
    /// the order the reader started them, its return, the books it finished
    /// (in the scheme's order) and its finishing; then the week's rhythm.
    public func celebrations(on date: CivilDate, in versification: Versification) -> [Celebration] {
        var found: [Celebration] = []
        for enrollment in enrollments where enrollment.ended == nil {
            let before = enrollment.record { $0 < date }
            let through = enrollment.record { $0 <= date }
            if enrollment.hasReturned(on: date, before: before) { found.append(.returned(enrollment: enrollment.id)) }
            let had = before.covered(in: versification).verses
            let has = through.covered(in: versification).verses
            for book in versification.books where has.books.contains(book) {
                let verses = versification.verseCount(of: book)
                if has.count(in: book) == verses, had.count(in: book) < verses {
                    found.append(.finishedBook(book, enrollment: enrollment.id))
                }
            }
            if through.isFinished, !before.isFinished { found.append(.finishedPlan(enrollment: enrollment.id)) }
        }
        if keptRhythm(on: date) { found.append(.keptRhythm) }
        return found
    }

    /// Whether `date` is the last reading day of its week (Monday to Sunday),
    /// the week has at least two, and the reader read on every one of them up
    /// to `date`. Reading days are those of any enrollment that has not
    /// ended, as for the streak; rest days and paused days are not asked
    /// about.
    func keptRhythm(on date: CivilDate) -> Bool {
        let open = enrollments.filter { $0.ended == nil }
        let isReadingDay = { (day: CivilDate) in open.contains { $0.expectsReading(on: day) } }
        guard isReadingDay(date), let monday = try? date.adding(days: 1 - date.weekday) else { return false }
        let read = readDates
        var count = 0
        for offset in 0..<7 {
            guard let day = try? monday.adding(days: offset) else { break }
            guard isReadingDay(day) else { continue }
            guard day <= date, read.contains(day) else { return false }
            count += 1
        }
        return count >= 2
    }
}

extension Enrollment {
    /// The enrollment as its active marks dated on the days `keep` accepts
    /// would make it alone: "the record before" a date, or "through" it.
    func record(keeping keep: (CivilDate) -> Bool) -> Enrollment {
        Enrollment(
            id: id, plan: plan, enrolled: enrolled, marks: marks.filter { keep($0.marked.date) },
            arranging: arranging)
    }

    /// Whether the reader returned on `date` after a gap: they read in this
    /// enrollment on it and on an earlier date, it is on or after the start
    /// and not paused, the plan was not finished in the record before it,
    /// and two or more reading days lie strictly between the anchor and it.
    /// The anchor is the latest of the day before the start, the last
    /// earlier date read, and the day before the last resuming on or before
    /// `date`; answering the welcome is not reading, so it does not move it.
    func hasReturned(on date: CivilDate, before: Enrollment) -> Bool {
        let reading = marks.filter { $0.marked.mark != .skipped }
        guard reading.contains(where: { $0.marked.date == date }), date >= start, !isPaused(date), !before.isFinished
        else { return false }
        let earlier = reading.map(\.marked.date).filter { $0 < date }
        guard let last = earlier.max() else { return false }
        var resumed: Int?
        for event in arranging {
            if case .resumed(let from, _) = event.body, from <= date { resumed = from.ordinal - 1 }
        }
        let anchor = max(start.ordinal - 1, last.ordinal, resumed ?? last.ordinal)
        guard let first = try? CivilDate(ordinal: anchor + 1), let end = try? date.adding(days: -1) else {
            return false
        }
        return readingDays(from: first, through: end) >= 2
    }
}
