import Foundation
import ReadingData
import ReadingEngine

/// Choosing a plan, as the Plans list shows it (BUILD.md P9.1–P9.3): the
/// goals' names, and each recommendation's facts as reasons in words. The
/// engine's `Choosing` makes the recommendations; nothing here restates a
/// rule. The web's counterpart is `planSuggestions` in
/// web/src/lib/server/catalog/present.ts, with the same words.
extension Goal {
    var label: String {
        switch self {
        case .begin: String(localized: "A place to begin")
        case .wholeBible: String(localized: "The whole Bible")
        case .newTestament: String(localized: "The New Testament")
        case .gospels: String(localized: "The Gospels")
        case .psalmsProverbs: String(localized: "The Psalms and Proverbs")
        }
    }

    /// Why a plan answers this goal.
    var reason: String {
        switch self {
        case .begin: String(localized: "A plan for beginning, or returning to, a reading habit.")
        case .wholeBible: String(localized: "A plan for reading the whole Bible.")
        case .newTestament: String(localized: "A plan for reading in the New Testament.")
        case .gospels: String(localized: "A plan for reading the Gospels.")
        case .psalmsProverbs: String(localized: "A plan for reading the Psalms or Proverbs.")
        }
    }
}

extension Choosing.Time {
    /// The choice in the picker.
    var label: String {
        switch self {
        case .short: String(localized: "About 5 minutes")
        case .medium: String(localized: "About 10 minutes")
        case .long: String(localized: "15 minutes or more")
        }
    }

    /// The answer as a reason repeats it.
    var said: String {
        switch self {
        case .short: String(localized: "about 5 minutes")
        case .medium: String(localized: "about 10 minutes")
        case .long: String(localized: "15 minutes or more")
        }
    }
}

/// A recommended plan and its reasons.
struct PlanSuggestion: Identifiable {
    let plan: Plan
    let reasons: [String]
    var id: PlanID { plan.id }
}

extension Catalog {
    /// The days a week the picker offers, with its words for each.
    static let dayChoices: [(days: Int, label: String)] = [
        (7, String(localized: "Every day")),
        (5, String(localized: "Five days a week")),
        (3, String(localized: "A few days a week")),
    ]

    /// The plans to consider for the reader's answers, by the engine's rules
    /// (docs/engine.md, "Choosing a plan").
    func suggestions(for answers: Choosing.Answers) -> [PlanSuggestion] {
        let candidates = listed.compactMap { plan -> Choosing.Candidate? in
            guard let facts = facts[plan.id] else { return nil }
            return Choosing.Candidate(
                plan: plan.id, goals: goals(of: plan.id), schedule: plan.schedule, readingDays: plan.readingDays,
                readings: plan.assignments.count, typicalWords: facts.workload.median.words)
        }
        return Choosing.recommend(candidates, for: answers).compactMap { found in
            self.plan(found.plan).map {
                PlanSuggestion(plan: $0, reasons: Self.reasons(found, answers: answers, planDays: $0.readingDays))
            }
        }
    }

    /// The engine's facts about one recommendation, as the reader reads them.
    static func reasons(_ found: Choosing.Recommendation, answers: Choosing.Answers, planDays: Int) -> [String] {
        var lines: [String] = []
        if let goal = found.goal { lines.append(goal.reason) }
        let minutes = minutesPhrase(found.minutes)
        switch (found.fitsTime, answers.time) {
        case (true?, let time?):
            lines.append(String(localized: "You said \(time.said). A typical reading takes \(minutes)."))
        case (false?, _):
            lines.append(String(localized: "A typical reading takes \(minutes), longer than you said."))
        default:
            lines.append(String(localized: "A typical reading takes \(minutes)."))
        }
        if let readerDays = found.readerDays {
            let days = pacedPhrase(planDays)
            if found.fitsDays == false {
                lines.append(String(localized: "It's paced for \(days), more than you said."))
            } else if planDays == readerDays {
                lines.append(String(localized: "It's paced for \(days), as you said."))
            } else {
                lines.append(
                    String(localized: "It's paced for \(days), fewer than you said; the others are rest days."))
            }
        }
        if let weeks = found.weeks, let perWeek = found.perWeek {
            let per = perWeek == 1 ? String(localized: "1 reading") : String(localized: "\(perWeek) readings")
            lines.append(
                weeks == 1
                    ? String(localized: "At \(per) a week it takes 1 week.")
                    : String(localized: "At \(per) a week it takes about \(weeks) weeks."))
        } else {
            lines.append(String(localized: "It has a reading for each date of the month."))
        }
        return lines
    }

    private static func minutesPhrase(_ minutes: ClosedRange<Int>) -> String {
        let (low, high) = (minutes.lowerBound, minutes.upperBound)
        if low != high { return String(localized: "about \(low) to \(high) minutes") }
        return low == 1 ? String(localized: "about 1 minute") : String(localized: "about \(low) minutes")
    }

    private static func pacedPhrase(_ days: Int) -> String {
        switch days {
        case 7: String(localized: "every day")
        case 1: String(localized: "1 reading day a week")
        default: String(localized: "\(days) reading days a week")
        }
    }
}
