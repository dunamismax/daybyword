import ReadingEngine

/// What a plan's schedule actually covers, computed by the compiler and never
/// taken from the plan file (AGENTS.md §6): its unique coverage, its
/// repeats, what it leaves out of the books it lists, and its workload. The
/// plan page shows these (BUILD.md P9.4), and the compiler refuses a coverage
/// claim they do not support (P4.4).
public struct PlanFacts: Hashable, Sendable {
    /// Verses given, counting a repeated verse each time.
    public let verses: Int
    /// Verses given, each once.
    public let uniqueVerses: Int
    /// The verses given more than once, as the fewest passages.
    public let repeats: [Passage]
    /// The verses of the listed books that no reading gives.
    public let omitted: [Passage]
    /// Chapters every verse of which is read, and chapters only partly read.
    public let wholeChapters: Int
    public let partialChapters: Int
    /// Each assignment's words, in reading order.
    public let words: [Int]
    public let workload: PlanWorkload

    public init(_ plan: Plan, versification: Versification, counts: WordCounts) throws(PlanFactsError) {
        let passages = plan.assignments.flatMap(\.reading.passages)
        let covered = VerseSet(passages, in: versification)
        let listed = VerseSet(
            plan.books.map { try! Passage($0, chapters: versification.chapters(of: $0)!, in: versification) },
            in: versification)
        var words: [Int] = []
        for assignment in plan.assignments {
            guard let count = counts.words(in: assignment.reading) else {
                let book = assignment.reading.passages.first { counts.words(of: $0.book) == nil }!.book
                throw .uncounted(book)
            }
            words.append(count)
        }
        let chapters = covered.chapters(in: versification)
        self.verses = plan.assignments.reduce(0) { $0 + $1.reading.verseCount(in: versification) }
        self.uniqueVerses = covered.count
        self.repeats = VerseSet.repeats(in: passages, in: versification).passages(in: versification)
        self.omitted = listed.subtracting(covered).passages(in: versification)
        self.wholeChapters = chapters.count(where: \.isWhole)
        self.partialChapters = chapters.count - wholeChapters
        self.words = words
        self.workload = PlanWorkload(words: words)!
    }

    /// Throws unless the schedule supports the plan's coverage claim: a
    /// whole-Bible plan and a plan of whole books must read every verse of
    /// what they list. A selection claims nothing to check.
    public func check(_ plan: Plan, versification: Versification) throws(PlanFactsError) {
        switch plan.coverage {
        case .wholeBible, .books:
            guard omitted.isEmpty else {
                throw .claimNotMet(
                    plan.coverage,
                    omitted: omitted.prefix(3).map { ReferenceFormat.text(of: $0, in: versification) },
                    more: max(0, omitted.count - 3))
            }
        case .selection: return
        }
    }
}

public enum PlanFactsError: Error, Equatable, CustomStringConvertible {
    case uncounted(BookID)
    case claimNotMet(Plan.Coverage, omitted: [String], more: Int)

    public var description: String {
        switch self {
        case .uncounted(let book): "\(book) has no word counts, so its workload cannot be estimated"
        case .claimNotMet(let coverage, let omitted, let more):
            "coverage: claims \(coverage.rawValue), but no reading gives \(omitted.joined(separator: "; "))"
                + (more > 0 ? " and \(more) more passage\(more == 1 ? "" : "s")" : "")
        }
    }
}
