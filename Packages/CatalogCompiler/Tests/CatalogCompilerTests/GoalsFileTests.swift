import CatalogCompiler
import Foundation
import ReadingEngine
import Testing

// The goals the plan list is grouped by (docs/catalog-format.md, "Goals";
// BUILD.md P9.3), checked against the plans.

/// The repository's own plans, read as the compiler reads them.
private func repositoryPlans() throws -> (plans: [Plan], registry: BookRegistry) {
    let registry = try CatalogBuild.readRegistry(from: catalogSource)
    let english = try CatalogBuild.readVersifications(from: catalogSource, registry: registry)[.english]!
    return (
        try CatalogBuild.readPlans(from: catalogSource, registry: registry, versification: english).map(\.plan),
        registry
    )
}

private func goals(_ entries: String) -> Data {
    Data("{\"format\": 1, \"goals\": [\(entries)]}".utf8)
}

@Test func readsTheRepositorysGoals() throws {
    let (plans, registry) = try repositoryPlans()
    let groups = try CatalogBuild.readGoals(from: catalogSource, plans: plans, registry: registry)
    #expect(groups.map(\.goal) == Goal.allCases)
    #expect(groups.first?.plans == [PlanID("gospels-at-your-pace")!])
    // Every plan is somewhere.
    #expect(Set(groups.flatMap(\.plans)) == Set(plans.map(\.id)))
}

@Test(
    arguments: [
        ("{\"goals\": []}", "is not a goals file: \"format\" and \"goals\", each with \"id\" and \"plans\""),
        ("{\"format\": 2, \"goals\": []}", "is format 2; this build reads 1"),
    ])
func refusesAGoalsFileOfAnotherShape(json: String, problem: String) throws {
    let (plans, registry) = try repositoryPlans()
    #expect(throws: GoalsError(problem)) { try GoalsFile.read(Data(json.utf8), plans: plans, registry: registry) }
}

@Test(
    arguments: [
        (
            "{\"id\": \"church-year\", \"plans\": [\"psalm-a-day\"]}",
            "\"church-year\" is not a goal; the goals are begin, whole-bible, new-testament, gospels, psalms-proverbs"
        ),
        (
            "{\"id\": \"gospels\", \"plans\": [\"gospels-at-your-pace\"]}, {\"id\": \"begin\", \"plans\": [\"psalm-a-day\"]}",
            "begin comes out of order; the goals come in the order begin, whole-bible, new-testament, gospels, psalms-proverbs"
        ),
        (
            "{\"id\": \"begin\", \"plans\": [\"psalm-a-day\"]}, {\"id\": \"begin\", \"plans\": [\"pauls-letters\"]}",
            "begin is given twice"
        ),
        ("{\"id\": \"begin\", \"plans\": []}", "begin has no plans"),
        ("{\"id\": \"begin\", \"plans\": [\"no-such-plan\"]}", "begin: \"no-such-plan\" is not a plan in plans/"),
        ("{\"id\": \"begin\", \"plans\": [\"psalm-a-day\", \"psalm-a-day\"]}", "begin: psalm-a-day is listed twice"),
        (
            "{\"id\": \"whole-bible\", \"plans\": [\"new-testament-in-a-year-five-days\"]}",
            "whole-bible: new-testament-in-a-year-five-days does not cover the whole Bible"
        ),
        (
            "{\"id\": \"new-testament\", \"plans\": [\"bible-in-a-year\"]}",
            "new-testament: bible-in-a-year reads GEN, which is not in the New Testament"
        ),
        (
            "{\"id\": \"gospels\", \"plans\": [\"pauls-letters\"]}",
            "gospels: pauls-letters reads ROM, which is not a Gospel"
        ),
        (
            "{\"id\": \"psalms-proverbs\", \"plans\": [\"gospels-at-your-pace\"]}",
            "psalms-proverbs: gospels-at-your-pace reads MAT, which is not Psalms or Proverbs"
        ),
    ])
func refusesAGoalThatDoesNotHold(entries: String, problem: String) throws {
    let (plans, registry) = try repositoryPlans()
    #expect(throws: GoalsError(problem)) { try GoalsFile.read(goals(entries), plans: plans, registry: registry) }
}

@Test func everyPlanNeedsAGoal() throws {
    let (plans, registry) = try repositoryPlans()
    let missing = plans.map(\.id.rawValue).filter { $0 != "psalm-a-day" }.map { "\"\($0)\"" }
    let entries = "{\"id\": \"begin\", \"plans\": [\(missing.joined(separator: ", "))]}"
    #expect(throws: GoalsError("psalm-a-day is in no goal; every plan needs at least one")) {
        try GoalsFile.read(goals(entries), plans: plans, registry: registry)
    }
}

@Test func aReleaseLeavesOutTheGoalsOfPlansItLeavesOut() throws {
    let reviewed = planText(["id": "ready-plan", "review": "reviewed"])
    let unreviewed = planText(["id": "draft-plan", "review": "checked"])
    let (root, source) = try fixtureCatalog(
        plans: ["ready-plan.plan": reviewed, "draft-plan.plan": unreviewed],
        goals: """
            {"format": 1, "goals": [{"id": "begin", "plans": ["ready-plan"]}, {"id": "gospels", "plans": ["draft-plan"]}]}
            """)
    defer { try? FileManager.default.removeItem(at: root) }
    let catalog = root.appending(path: "Catalog.sqlite")
    try CatalogBuild.write(from: source, to: catalog, mode: .release)
    let export = try CatalogExport(catalog: catalog, sources: try CatalogBuild.readSources(from: source))
    #expect(export.goals.map(\.id) == ["begin"])
    #expect(export.goals.first?.plans == ["ready-plan"])
}
