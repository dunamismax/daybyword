/// What a reader may hope to read, by which the catalog groups its plans
/// (`catalog/goals.json`), in the order the plan list shows them
/// (docs/engine.md, "Choosing a plan"; BUILD.md P9.3).
public enum Goal: String, Hashable, Sendable, CaseIterable, Codable {
    /// A place to begin: plans for starting, or returning to, a reading habit.
    case begin
    case wholeBible = "whole-bible"
    case newTestament = "new-testament"
    case gospels
    case psalmsProverbs = "psalms-proverbs"
}

/// Recommending plans from a reader's answers, by fixed and documented rules
/// (docs/engine.md, "Choosing a plan"; BUILD.md P9.2): never popularity,
/// never anything the reader did not say, and never AI (D12, D23).
public enum Choosing {
    /// How long a reading may take, as the reader answers.
    public enum Time: String, Hashable, Sendable, CaseIterable, Codable {
        /// About 5 minutes.
        case short
        /// About 10 minutes.
        case medium
        /// 15 minutes or more.
        case long

        /// The most minutes a typical reading may take to fit; nil for any.
        var limit: Int? {
            switch self {
            case .short: 5
            case .medium: 10
            case .long: nil
            }
        }

        /// The minutes the answer stands for, which nearer plans come closer to.
        var target: Int {
            switch self {
            case .short: 5
            case .medium: 10
            case .long: 15
            }
        }
    }

    /// The reader's answers; nil is "not sure".
    public struct Answers: Hashable, Sendable {
        public var hope: Goal?
        public var time: Time?
        /// The days a week the reader expects to read, 1 to 7.
        public var days: Int?

        public init(hope: Goal? = nil, time: Time? = nil, days: Int? = nil) {
            precondition(days.map { (1...7).contains($0) } ?? true, "a week has 1 to 7 reading days")
            self.hope = hope
            self.time = time
            self.days = days
        }
    }

    /// A plan as the catalog gives it.
    public struct Candidate: Hashable, Sendable {
        public let plan: PlanID
        public let goals: Set<Goal>
        public let schedule: Plan.Schedule
        /// The reading days a week the plan is paced for.
        public let readingDays: Int
        public let readings: Int
        /// The words of its typical (middle) reading.
        public let typicalWords: Int

        public init(
            plan: PlanID, goals: Set<Goal>, schedule: Plan.Schedule, readingDays: Int, readings: Int,
            typicalWords: Int
        ) {
            self.plan = plan
            self.goals = goals
            self.schedule = schedule
            self.readingDays = readingDays
            self.readings = readings
            self.typicalWords = typicalWords
        }
    }

    /// One recommended plan with the facts the reader sees as its reasons.
    public struct Recommendation: Hashable, Sendable {
        public let plan: PlanID
        /// The reader's goal, or `begin` when they gave none and the plan is in it.
        public let goal: Goal?
        /// The typical reading's minutes, from silent to aloud.
        public let minutes: ClosedRange<Int>
        /// Nil when the reader did not say how long.
        public let fitsTime: Bool?
        /// The days the reader expects to read; nil when not sure.
        public let readerDays: Int?
        /// Nil when the reader did not say how many days.
        public let fitsDays: Bool?
        /// A sequence's readings a week: the fewer of the reader's days and
        /// the plan's (the plan's when the reader is not sure); nil for a
        /// day-of-month plan.
        public let perWeek: Int?
        /// The weeks a sequence takes at `perWeek`; nil for a day-of-month plan.
        public let weeks: Int?
    }

    /// The plans to recommend for `answers`, from `candidates` in the
    /// catalog's order: at most three, best first.
    public static func recommend(_ candidates: [Candidate], for answers: Answers) -> [Recommendation] {
        struct Ranked {
            let order: Int
            let candidate: Candidate
            let minutes: ClosedRange<Int>
            let fitsTime: Bool?
            let fitsDays: Bool?
        }
        let ranked = candidates.enumerated()
            .filter { answers.hope.map($0.element.goals.contains) ?? true }
            .map { order, candidate -> Ranked in
                let minutes = Workload(words: candidate.typicalWords).minutes
                return Ranked(
                    order: order, candidate: candidate, minutes: minutes,
                    fitsTime: answers.time.map { time in time.limit.map { minutes.lowerBound <= $0 } ?? true },
                    fitsDays: answers.days.map { candidate.readingDays <= $0 })
            }
        func key(_ plan: Ranked) -> [Int] {
            let misses = (plan.fitsTime == false ? 1 : 0) + (plan.fitsDays == false ? 1 : 0)
            let notBegin = answers.hope == nil && !plan.candidate.goals.contains(.begin) ? 1 : 0
            let pace = answers.days.map { abs(plan.candidate.readingDays - $0) } ?? 0
            let time = answers.time.map { abs(plan.minutes.lowerBound - $0.target) } ?? 0
            return [misses, notBegin, pace, time, plan.order]
        }
        return ranked.sorted { key($0).lexicographicallyPrecedes(key($1)) }.prefix(3).map { plan in
            let candidate = plan.candidate
            let perWeek = min(answers.days ?? candidate.readingDays, candidate.readingDays)
            let sequence = candidate.schedule == .sequence
            return Recommendation(
                plan: candidate.plan,
                goal: answers.hope ?? (candidate.goals.contains(.begin) ? .begin : nil),
                minutes: plan.minutes, fitsTime: plan.fitsTime, readerDays: answers.days,
                fitsDays: plan.fitsDays, perWeek: sequence ? perWeek : nil,
                weeks: sequence ? (candidate.readings + perWeek - 1) / perWeek : nil)
        }
    }
}
