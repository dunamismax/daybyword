import CatalogCompiler
import Foundation
import ReadingData
import ReadingEngine
import Testing

func facts(_ plan: Plan) throws -> PlanFacts {
    let registry = try CatalogBuild.readRegistry(from: catalogSource)
    let english = try #require(try CatalogBuild.readVersifications(from: catalogSource, registry: registry)[.english])
    let counts = try CatalogBuild.readWordCounts(from: catalogSource, versification: english)
    return try PlanFacts(plan, versification: english, counts: counts)
}

func written(_ passages: [Passage]) throws -> [String] {
    let registry = try CatalogBuild.readRegistry(from: catalogSource)
    let english = try #require(try CatalogBuild.readVersifications(from: catalogSource, registry: registry)[.english])
    return passages.map { ReferenceFormat.text(of: $0, in: english) }
}

func claimProblem(_ plan: Plan) throws -> String? {
    let registry = try CatalogBuild.readRegistry(from: catalogSource)
    let english = try #require(try CatalogBuild.readVersifications(from: catalogSource, registry: registry)[.english])
    do {
        try facts(plan).check(plan, versification: english)
        return nil
    } catch let error as PlanFactsError {
        return error.description
    }
}

/// The test plan reads Mark 1 (45 verses, 879 words), Luke 15:1-10 (212
/// words), and John 3:16 (25 words), counted from web.tsv.
@Test func computesWhatASelectionCovers() throws {
    let computed = try facts(readPlan(planText()))
    #expect(computed.verses == 56)
    #expect(computed.uniqueVerses == 56)
    #expect(computed.repeats.isEmpty)
    #expect(computed.wholeChapters == 1)
    #expect(computed.partialChapters == 2)
    #expect(computed.words == [879, 212 + 25])
    #expect(computed.workload.minimum.words == 237)
    #expect(computed.workload.maximum.words == 879)
    #expect(
        try written(computed.omitted) == [
            "MRK 2-16", "LUK 1-14", "LUK 15:11-24:53", "JHN 1:1-3:15", "JHN 3:17-21:25",
        ])
    #expect(try claimProblem(readPlan(planText())) == nil)
}

@Test func countsRepeatsOnceInCoverage() throws {
    let plan = try readPlan(
        planText(["coverage": "books", "books": "JUD"], schedule: "1\tJUD 1:1-15\n2\tJUD 1:10-25"))
    let computed = try facts(plan)
    #expect(computed.verses == 31)
    #expect(computed.uniqueVerses == 25)
    #expect(try written(computed.repeats) == ["JUD 1:10-15"])
    #expect(computed.omitted.isEmpty)
    #expect(try claimProblem(plan) == nil)
}

@Test(
    arguments: [
        // Coverage and books, a schedule, and the problem.
        ("books", "JUD", "1\tJUD 1:1-20", "coverage: claims books, but no reading gives JUD 1:21-25"),
        (
            "books", "RUT", "1\tRUT 1:1-5\n2\tRUT 2:1-5\n3\tRUT 3:1-5\n4\tRUT 4:1-5",
            "coverage: claims books, but no reading gives RUT 1:6-22; RUT 2:6-23; RUT 3:6-18 and 1 more passage"
        ),
    ])
func refusesAClaimTheScheduleDoesNotMeet(coverage: String, books: String, schedule: String, problem: String) throws {
    #expect(
        try claimProblem(readPlan(planText(["coverage": coverage, "books": books], schedule: schedule))) == problem)
}

@Test func aWholeBiblePlanMustReadEveryVerse() throws {
    let whole = try wholeBibleSchedule()
    let plan = try readPlan(planText(["coverage": "whole-bible", "books": "all"], schedule: whole))
    #expect(try claimProblem(plan) == nil)
    #expect(try facts(plan).uniqueVerses == 31_102)

    let short = whole.replacingOccurrences(of: "GEN 1-50", with: "GEN 1-49; GEN 50:1-25")
    let shortPlan = try readPlan(planText(["coverage": "whole-bible", "books": "all"], schedule: short))
    #expect(try claimProblem(shortPlan) == "coverage: claims whole-bible, but no reading gives GEN 50:26")
}

@Test func theCatalogHoldsEachPlansFacts() throws {
    let (root, source) = try fixtureCatalog(plans: ["test-plan.plan": planText()])
    defer { try? FileManager.default.removeItem(at: root) }
    let output = root.appending(path: "Catalog.sqlite")
    try CatalogBuild.write(from: source, to: output, mode: .development)

    let catalog = try Database(path: output.path, access: .readOnly)
    let row = try #require(try catalog.query("SELECT * FROM plan_facts").first)
    #expect(row["plan_id"] == .text("test-plan"))
    #expect(row["unique_verses"] == .integer(56))
    #expect(row["repeats"] == .text(""))
    #expect(row["omitted"] == .text("MRK 2-16; LUK 1-14; LUK 15:11-24:53; JHN 1:1-3:15; JHN 3:17-21:25"))
    #expect(
        [row["words_minimum"], row["words_median"], row["words_maximum"]] == [
            .integer(237), .integer(558), .integer(879),
        ])
    let words = try catalog.query("SELECT words FROM assignments ORDER BY position").map { $0["words"] }
    #expect(words == [.integer(879), .integer(237)])
}

@Test func aBuildRefusesAClaimTheScheduleDoesNotMeet() throws {
    let plan = planText(["coverage": "books", "books": "JUD"], schedule: "1\tJUD 1:1-20")
    let (root, source) = try fixtureCatalog(plans: ["test-plan.plan": plan])
    defer { try? FileManager.default.removeItem(at: root) }
    let output = root.appending(path: "Catalog.sqlite")
    let error = #expect(throws: CatalogError.self) {
        try CatalogBuild.write(from: source, to: output, mode: .development)
    }
    #expect(error?.problem == "coverage: claims books, but no reading gives JUD 1:21-25")
    #expect(!FileManager.default.fileExists(atPath: output.path))
}
