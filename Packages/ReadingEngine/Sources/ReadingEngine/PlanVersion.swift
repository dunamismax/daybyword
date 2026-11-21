/// A plan version as the scheduling rules see it (docs/engine.md, "Plans and
/// assignments"): what a reader can enroll in and mark, without the plan
/// page's prose. The app builds one from the bundled catalog, and the
/// compiler from a `Plan`.
public struct PlanVersion: Hashable, Sendable {
    public let id: PlanID
    public let version: Int
    public let schedule: Plan.Schedule
    /// The behaviors this plan permits.
    public let behaviors: [Plan.Behavior]
    /// The reading days a week the plan is paced for, 1 to 7.
    public let readingDays: Int
    /// In the order they are read.
    public let assignments: [Plan.Assignment]
    /// Each assignment's position in reading order, from 1, by its id.
    public let positions: [Int: Int]

    public init(
        id: PlanID, version: Int, schedule: Plan.Schedule, behaviors: [Plan.Behavior], readingDays: Int,
        assignments: [Plan.Assignment]
    ) {
        self.id = id
        self.version = version
        self.schedule = schedule
        self.behaviors = behaviors
        self.readingDays = readingDays
        self.assignments = assignments
        var positions: [Int: Int] = [:]
        for (index, assignment) in assignments.enumerated() where positions[assignment.id] == nil {
            positions[assignment.id] = index + 1
        }
        self.positions = positions
    }

    public init(_ plan: Plan) {
        self.init(
            id: plan.id, version: plan.version, schedule: plan.schedule, behaviors: plan.behaviors,
            readingDays: plan.readingDays, assignments: plan.assignments)
    }
}
