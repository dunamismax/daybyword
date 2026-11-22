/// What the reader has done (docs/engine.md, "Progress"). Records describe
/// activity: they do not measure faithfulness, maturity or understanding,
/// and nothing built on them may suggest they do.
public enum Progress {
    /// An enrollment's readings by state. "62 of 89 readings read."
    public struct Counts: Hashable, Sendable {
        public let read: Int
        public let partlyRead: Int
        public let skipped: Int
        public let unread: Int
        public let total: Int
    }

    /// One of the recent dates.
    public struct Day: Hashable, Sendable {
        public let date: CivilDate
        /// Whether the reader read on it, in any enrollment.
        public let isRead: Bool
        /// Whether it was a reading day of any enrollment.
        public let isReadingDay: Bool
    }

    /// The verses the reader has read across every enrollment, each once.
    public struct Coverage: Sendable {
        public let verses: VerseSet
        /// Every chapter read from, in the scheme's book order. A chapter of
        /// a reading marked part read with no verses stated is listed with
        /// none covered unless other readings cover some of it.
        public let chapters: [VerseSet.ChapterCoverage]
        /// The books explored, in the scheme's book order.
        public let books: [BookID]

        /// Each book explored, in the scheme's book order, with its verses
        /// read of the verses it has and its chapters read whole and in part
        /// (P11.4). Repeats add nothing: each verse counts once.
        public func byBook(in versification: Versification) -> [BookCoverage] {
            books.map { book in
                let touched = chapters.filter { $0.book == book }
                return BookCoverage(
                    book: book, verses: verses.count(in: book), of: versification.verseCount(of: book),
                    wholeChapters: touched.count(where: \.isWhole), partialChapters: touched.count { !$0.isWhole })
            }
        }
    }

}

/// A book explored: its verses read of the verses it has, and its
/// chapters read whole and in part. A partly read chapter is never
/// counted as read.
public struct BookCoverage: Hashable, Sendable {
    public let book: BookID
    /// The verses read, each once.
    public let verses: Int
    /// The verses the book has.
    public let of: Int
    public let wholeChapters: Int
    public let partialChapters: Int
    /// Whether every verse of the book is read.
    public var isWhole: Bool { verses == of }
}

extension Enrollment {
    /// Whether this is a sequence with no unread reading.
    public var isFinished: Bool {
        plan.schedule == .sequence && settled.count >= plan.positions.count
    }

    /// The readings by state on `date`. A sequence's total is its readings.
    /// A calendar enrollment's is the slots appointed from the start to that
    /// date (or to the day it ended), paused days excluded, and with them
    /// any slot the reader settled outside those days, so the states always
    /// add up to the total.
    public func counts(on date: CivilDate) -> Progress.Counts {
        var total = plan.positions.count
        if plan.schedule == .dayOfMonth {
            let last = min(date, ended ?? date)
            total = 0
            var day = start
            while day <= last {
                if !isPaused(day), plan.positions[day.day] != nil { total += 1 }
                guard let next = try? day.adding(days: 1) else { break }
                day = next
            }
            total += settled.count {
                guard let appointed = $0.slot.appointed else { return false }
                return appointed < start || appointed > last || isPaused(appointed)
            }
        }
        let read = settled.count { $0.state == .read }
        let partlyRead = settled.count { $0.state == .partlyRead }
        let skipped = settled.count { $0.state == .skipped }
        return Progress.Counts(
            read: read, partlyRead: partlyRead, skipped: skipped, unread: total - settled.count, total: total)
    }

    /// Whether `date` is a reading day on which this enrollment still had
    /// something to ask: a finished sequence asks nothing after the last day
    /// the reader marked in it, so its later days neither count as reading
    /// days among the recent ones nor weigh on the streak.
    func expectsReading(on date: CivilDate) -> Bool {
        guard isReadingDay(date) else { return false }
        guard isFinished, let last = settled.map(\.date).max() else { return true }
        return date <= last
    }
}

extension Journal {
    /// The dates on which the reader read: the date of every active
    /// `completed` or `partlyCompleted` event, in any enrollment. A reading
    /// begun one day and finished the next is two days read, though its
    /// slot keeps only the later mark.
    var readDates: Set<CivilDate> {
        var dates: Set<CivilDate> = []
        for enrollment in enrollments {
            for mark in enrollment.marks where mark.marked.mark != .skipped { dates.insert(mark.marked.date) }
        }
        return dates
    }

    /// The `count` dates ending on `date`, earliest first, each with whether
    /// the reader read on it and whether it was a reading day of any
    /// enrollment. Dates before the calendar begins are left out.
    public func recentDays(ending date: CivilDate, count: Int = 7) -> [Progress.Day] {
        let read = readDates
        var days: [Progress.Day] = []
        for back in stride(from: count - 1, through: 0, by: -1) {
            guard let day = try? date.adding(days: -back) else { continue }
            days.append(
                Progress.Day(
                    date: day, isRead: read.contains(day),
                    isReadingDay: enrollments.contains { $0.expectsReading(on: day) }))
        }
        return days
    }

    /// The streak on `date` (D17): the consecutive reading days, of any
    /// enrollment that is not ended, on which the reader read, counting back
    /// from that date, or from the last reading day before it when it is not
    /// yet read. Rest days and paused days neither break it nor add to it.
    public func streak(on date: CivilDate) -> Int {
        let open = enrollments.filter { $0.ended == nil }
        guard let earliest = open.map(\.start).min() else { return 0 }
        let read = readDates
        var count = 0
        var day = date
        while day >= earliest {
            if open.contains(where: { $0.expectsReading(on: day) }) {
                if read.contains(day) {
                    count += 1
                } else if day != date {
                    break
                }
            }
            guard let previous = try? day.adding(days: -1) else { break }
            day = previous
        }
        return count
    }

    /// Coverage across all enrollments, each verse once: every reading
    /// marked read, and the stated verses of readings marked part read, as
    /// far as they are verses of that reading. A reading marked part read
    /// with no such verses adds none: its chapters are listed and its books
    /// count as explored.
    public func coverage(in versification: Versification) -> Progress.Coverage {
        var verses = VerseSet(scheme: versification.scheme)
        var touched = verses
        for enrollment in enrollments {
            let covered = enrollment.covered(in: versification)
            verses = verses.union(covered.verses)
            touched = touched.union(covered.touched)
        }

        let all = verses.union(touched)
        var covered: [String: Int] = [:]
        for chapter in verses.chapters(in: versification) {
            covered["\(chapter.book.rawValue) \(chapter.chapter)"] = chapter.covered
        }
        return Progress.Coverage(
            verses: verses,
            chapters: all.chapters(in: versification).map {
                VerseSet.ChapterCoverage(
                    book: $0.book, chapter: $0.chapter, covered: covered["\($0.book.rawValue) \($0.chapter)"] ?? 0,
                    verses: $0.verses)
            },
            books: versification.books.filter { all.books.contains($0) })
    }
}

extension Enrollment {
    /// This enrollment's part of coverage: the verses its readings marked
    /// read cover, with the stated verses of those marked part read, as far
    /// as they are verses of that reading; and, apart, the readings marked
    /// part read with no such verses, whose chapters are listed and whose
    /// books are explored though they add no verses.
    func covered(in versification: Versification) -> (verses: VerseSet, touched: VerseSet) {
        var verses = VerseSet(scheme: versification.scheme)
        var touched = verses
        var readings: [Int: Reading] = [:]
        for assignment in plan.assignments where readings[assignment.id] == nil {
            readings[assignment.id] = assignment.reading
        }
        for mark in settled where mark.state != .skipped {
            guard let reading = readings[mark.slot.assignment], reading.scheme == versification.scheme else {
                continue
            }
            let whole = VerseSet(reading.passages, in: versification)
            if mark.state == .read {
                verses = verses.union(whole)
                continue
            }
            var stated = VerseSet(scheme: versification.scheme)
            if let text = mark.verses, let said = try? ReferenceFormat.reading(text, in: versification) {
                stated = VerseSet(said.passages, in: versification).intersection(whole)
            }
            if stated.isEmpty { touched = touched.union(whole) } else { verses = verses.union(stated) }
        }
        return (verses, touched)
    }
}
