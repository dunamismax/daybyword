import Foundation
import ReadingEngine

/// The goals the plan list is grouped by (`catalog/goals.json`,
/// docs/catalog-format.md "Goals"; BUILD.md P9.3), read and checked against
/// the plans: every goal is one the engine knows, in its order; every plan
/// listed is a plan in `plans/`; every plan is in at least one goal; and
/// each goal's claim is true of its plans. `begin` is an editorial choice
/// with no claim to check.
public enum GoalsFile {
    /// One goal and its plans, in the order the list shows them.
    public struct Group: Hashable, Sendable {
        public let goal: Goal
        public let plans: [PlanID]

        public init(goal: Goal, plans: [PlanID]) {
            self.goal = goal
            self.plans = plans
        }
    }

    /// The file's format, raised when its meaning changes.
    public static let format = 1

    private struct File: Decodable {
        struct Entry: Decodable {
            let id: String
            let plans: [String]
        }
        let about: String?
        let format: Int
        let goals: [Entry]
    }

    static let gospels: Set<String> = ["MAT", "MRK", "LUK", "JHN"]
    static let psalmsProverbs: Set<String> = ["PSA", "PRO"]

    /// Reads the goals in `data` for `plans`.
    public static func read(_ data: Data, plans: [Plan], registry: BookRegistry) throws(GoalsError) -> [Group] {
        let file: File
        do {
            file = try JSONDecoder().decode(File.self, from: data)
        } catch {
            throw GoalsError("is not a goals file: \"format\" and \"goals\", each with \"id\" and \"plans\"")
        }
        guard file.format == format else { throw GoalsError("is format \(file.format); this build reads \(format)") }
        let byID = Dictionary(uniqueKeysWithValues: plans.map { ($0.id, $0) })
        var groups: [Group] = []
        for entry in file.goals {
            guard let goal = Goal(rawValue: entry.id) else {
                throw GoalsError("\"\(entry.id)\" is not a goal; the goals are \(names)")
            }
            if let last = groups.last?.goal {
                let (at, previous) = (Goal.allCases.firstIndex(of: goal)!, Goal.allCases.firstIndex(of: last)!)
                guard at != previous else { throw GoalsError("\(goal.rawValue) is given twice") }
                guard at > previous else {
                    throw GoalsError("\(goal.rawValue) comes out of order; the goals come in the order \(names)")
                }
            }
            guard !entry.plans.isEmpty else { throw GoalsError("\(goal.rawValue) has no plans") }
            var listed: [PlanID] = []
            for text in entry.plans {
                guard let id = PlanID(text), let plan = byID[id] else {
                    throw GoalsError("\(goal.rawValue): \"\(text)\" is not a plan in plans/")
                }
                guard !listed.contains(id) else { throw GoalsError("\(goal.rawValue): \(id) is listed twice") }
                if let problem = claim(goal, plan, registry: registry) {
                    throw GoalsError("\(goal.rawValue): \(id) \(problem)")
                }
                listed.append(id)
            }
            groups.append(Group(goal: goal, plans: listed))
        }
        let grouped = Set(groups.flatMap(\.plans))
        if let alone = plans.map(\.id).first(where: { !grouped.contains($0) }) {
            throw GoalsError("\(alone) is in no goal; every plan needs at least one")
        }
        return groups
    }

    /// What is wrong with listing `plan` under `goal`, or nil.
    static func claim(_ goal: Goal, _ plan: Plan, registry: BookRegistry) -> String? {
        let books = plan.books.map(\.rawValue)
        switch goal {
        case .begin:
            return nil
        case .wholeBible:
            return plan.coverage == .wholeBible ? nil : "does not cover the whole Bible"
        case .newTestament:
            let outside = plan.books.first { registry.book($0)?.testament != .new }
            return outside.map { "reads \($0), which is not in the New Testament" }
        case .gospels:
            return books.first { !gospels.contains($0) }.map { "reads \($0), which is not a Gospel" }
        case .psalmsProverbs:
            return books.first { !psalmsProverbs.contains($0) }.map { "reads \($0), which is not Psalms or Proverbs" }
        }
    }

    private static var names: String { Goal.allCases.map(\.rawValue).joined(separator: ", ") }
}

/// A problem in the goals file.
public struct GoalsError: Error, CustomStringConvertible, Equatable {
    public let problem: String

    public init(_ problem: String) { self.problem = problem }

    public var description: String { problem }
}
