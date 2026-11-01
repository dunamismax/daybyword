/// One version of a reading plan: what its page says about it and its
/// schedule of assignments (docs/catalog-format.md). A plan version never
/// changes once published; a correction is a new version (E2, P4.6).
public struct Plan: Hashable, Sendable {
    public enum Schedule: String, Hashable, Sendable, CaseIterable {
        /// Numbered readings, read in order.
        case sequence
        /// A reading for each day of the month, 1 to 31.
        case dayOfMonth = "day-of-month"

        /// The behaviors a reader may choose for a plan on this schedule.
        public var permittedBehaviors: Set<Behavior> {
            switch self {
            case .sequence: [.pace, .finishDate]
            case .dayOfMonth: [.calendar]
            }
        }
    }

    /// The three schedule behaviors (BUILD.md, "The three schedule
    /// behaviors").
    public enum Behavior: String, Hashable, Sendable, CaseIterable {
        case pace
        case finishDate = "finish-date"
        case calendar
    }

    /// What a plan claims to cover, which the compiler checks (P4.4).
    public enum Coverage: String, Hashable, Sendable, CaseIterable {
        /// Every verse of the plan's canon.
        case wholeBible = "whole-bible"
        /// Every verse of each listed book.
        case books
        /// Passages from the listed books, with no claim to cover them.
        case selection
    }

    /// How far a plan has been reviewed (docs/editorial.md), lowest first.
    public enum Review: String, Hashable, Sendable, CaseIterable, Comparable {
        case checked
        case reviewed
        case expert

        public static func < (lhs: Self, rhs: Self) -> Bool {
            allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
        }
    }

    /// One reading in the schedule. Its id is how the journal records it, and
    /// it never changes or is reused (docs/catalog-format.md).
    public struct Assignment: Hashable, Sendable {
        public let id: Int
        public let reading: Reading

        public init(id: Int, reading: Reading) {
            self.id = id
            self.reading = reading
        }
    }

    public let id: PlanID
    public let version: Int
    public let title: String
    public let creator: String
    public let summary: String
    public let suits: String
    public let schedule: Schedule
    public let behaviors: [Behavior]
    /// The reading days a week the plan is paced for, 1 to 7.
    public let readingDays: Int
    public let coverage: Coverage
    /// The canon the plan assumes, by its id in the book registry.
    public let canon: String
    /// The books it reads from, in the canon's order.
    public let books: [BookID]
    public let limitations: String
    public let instructions: String
    public let source: String
    /// Its entry in `catalog/SOURCES.md`.
    public let rights: String
    public let review: Review
    /// In the order they are read.
    public let assignments: [Assignment]

    public init(
        id: PlanID, version: Int, title: String, creator: String, summary: String, suits: String,
        schedule: Schedule, behaviors: [Behavior], readingDays: Int, coverage: Coverage, canon: String,
        books: [BookID], limitations: String, instructions: String, source: String, rights: String,
        review: Review, assignments: [Assignment]
    ) {
        self.id = id
        self.version = version
        self.title = title
        self.creator = creator
        self.summary = summary
        self.suits = suits
        self.schedule = schedule
        self.behaviors = behaviors
        self.readingDays = readingDays
        self.coverage = coverage
        self.canon = canon
        self.books = books
        self.limitations = limitations
        self.instructions = instructions
        self.source = source
        self.rights = rights
        self.review = review
        self.assignments = assignments
    }
}
