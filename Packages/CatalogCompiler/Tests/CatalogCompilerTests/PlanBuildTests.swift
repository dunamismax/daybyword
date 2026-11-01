import CatalogCompiler
import Foundation
import ReadingData
import ReadingEngine
import Testing

/// A copy of the repository's catalog sources with these plan files, and
/// SOURCES.md with these entries added, in a temporary directory.
func fixtureCatalog(plans: [String: String], sources: String = "") throws -> (root: URL, source: URL) {
    let root = temporaryDirectory()
    let source = root.appending(path: "catalog")
    try FileManager.default.createDirectory(at: source.appending(path: "plans"), withIntermediateDirectories: true)
    try FileManager.default.copyItem(
        at: catalogSource.appending(path: "scripture"), to: source.appending(path: "scripture"))
    let registry = try String(contentsOf: catalogSource.appending(path: "SOURCES.md"), encoding: .utf8)
    try (registry + sources).write(to: source.appending(path: "SOURCES.md"), atomically: true, encoding: .utf8)
    for (name, text) in plans {
        try text.write(to: source.appending(path: "plans/\(name)"), atomically: true, encoding: .utf8)
    }
    return (root, source)
}

func entry(_ id: String, _ status: String) -> String {
    "\n## \(id): A source for the tests\n\n- **Status:** `\(status)`.\n"
}

@Test func theRepositorysSourcesHaveStatuses() throws {
    let sources = try CatalogBuild.readSources(from: catalogSource)
    #expect(sources.statuses["daybyword-original"] == .cleared)
    #expect(sources.statuses["kjv-1769-ebible"] == .cleared)
    #expect(sources.statuses["web-ebible"] == .cleared)
    #expect(sources.statuses["stepbible-tvtms"] == .cleared)
}

@Test(
    arguments: [
        (
            "## daybyword-original: Ours\n\n- **Status:** `kept`.\n",
            "line 3: a status is one of `cleared`, `pending`, `rejected`, `reference`"
        ),
        ("## daybyword-original: Ours\n\n- **Edition:** none.\n", "line 1: has no status"),
        ("## Ours\n", "line 1: an entry's heading is \"## id: title\""),
        ("## a: A\n- **Status:** `cleared`.\n## a: A again\n", "line 3: a has two entries"),
    ])
func refusesABrokenSourcesRegistry(markdown: String, problem: String) {
    #expect(throws: SourcesError.self) { try SourcesRegistry(markdown: markdown) }
    do { _ = try SourcesRegistry(markdown: markdown) } catch { #expect(error.description == problem) }
}

@Test func writesPlansAndTheirAssignments() throws {
    let (root, source) = try fixtureCatalog(plans: ["test-plan.plan": planText()])
    defer { try? FileManager.default.removeItem(at: root) }
    let output = root.appending(path: "Catalog.sqlite")
    try CatalogBuild.write(from: source, to: output, mode: .development)

    let catalog = try Database(path: output.path, access: .readOnly)
    let plans = try catalog.query("SELECT id, version, schedule, behaviors, books, review FROM plans")
    #expect(plans.count == 1)
    #expect(plans.first?["id"] == .text("test-plan"))
    #expect(plans.first?["behaviors"] == .text("pace, finish-date"))
    #expect(plans.first?["books"] == .text("MRK, LUK, JHN"))
    let assignments = try catalog.query("SELECT id, position, reading FROM assignments ORDER BY position")
    #expect(assignments.map { $0["reading"] } == [.text("MRK 1"), .text("LUK 15:1-10; JHN 3:16")])
    #expect(assignments.map { $0["id"] } == [.integer(1), .integer(2)])
    let count = try catalog.query("SELECT value FROM catalog_meta WHERE key = 'plans'")
    #expect(count.first?["value"] == .text("1"))
}

@Test func theChecksumFollowsTheContentAlone() throws {
    let (root, source) = try fixtureCatalog(plans: ["test-plan.plan": planText()])
    defer { try? FileManager.default.removeItem(at: root) }
    func checksum(_ mode: CatalogBuild.Mode) throws -> SQLiteValue? {
        let output = root.appending(path: "Catalog-\(mode.rawValue).sqlite")
        try CatalogBuild.write(from: source, to: output, mode: mode)
        return try Database(path: output.path, access: .readOnly)
            .query("SELECT value FROM catalog_meta WHERE key = 'content_sha256'").first?["value"]
    }
    let first = try checksum(.development)
    #expect(try checksum(.development) == first)
    try planText(["title": "Another title"]).write(
        to: source.appending(path: "plans/test-plan.plan"), atomically: true, encoding: .utf8)
    #expect(try checksum(.development) != first)
}

@Test func aReleaseLeavesOutPlansThatAreNotReviewed() throws {
    let reviewed = planText(["id": "reviewed-plan", "review": "reviewed"])
    let (root, source) = try fixtureCatalog(plans: ["test-plan.plan": planText(), "reviewed-plan.plan": reviewed])
    defer { try? FileManager.default.removeItem(at: root) }
    let output = root.appending(path: "Catalog.sqlite")

    #expect(try CatalogBuild.write(from: source, to: output, mode: .release) == [PlanID("test-plan")!])
    let released = try Database(path: output.path, access: .readOnly).query("SELECT id FROM plans")
    #expect(released.map { $0["id"] } == [.text("reviewed-plan")])

    #expect(try CatalogBuild.write(from: source, to: output, mode: .development).isEmpty)
    let developed = try Database(path: output.path, access: .readOnly).query("SELECT id FROM plans ORDER BY id")
    #expect(developed.map { $0["id"] } == [.text("reviewed-plan"), .text("test-plan")])
}

@Test(
    arguments: [
        // The plan's rights, the build, and the problem (nil: it builds).
        ("unlisted-source", CatalogBuild.Mode.development, "rights: unlisted-source has no entry in SOURCES.md"),
        ("pending-source", .development, nil),
        ("pending-source", .release, "rights: pending-source is pending, so the plan cannot be released"),
        ("rejected-source", .development, "rights: rejected-source is rejected, so nothing from it ships"),
        ("reference-source", .release, "rights: reference-source is reference, so nothing from it ships"),
    ] as [(String, CatalogBuild.Mode, String?)])
func plansNeedASourceTheirBuildAllows(rights: String, mode: CatalogBuild.Mode, problem: String?) throws {
    let sources =
        entry("pending-source", "pending") + entry("rejected-source", "rejected")
        + entry("reference-source", "reference")
    let plan = planText(["rights": rights, "review": "reviewed"])
    let (root, source) = try fixtureCatalog(plans: ["test-plan.plan": plan], sources: sources)
    defer { try? FileManager.default.removeItem(at: root) }
    let output = root.appending(path: "Catalog.sqlite")
    if let problem {
        let error = #expect(throws: CatalogError.self) { try CatalogBuild.write(from: source, to: output, mode: mode) }
        #expect(error?.problem == problem)
        #expect(!FileManager.default.fileExists(atPath: output.path))
    } else {
        try CatalogBuild.write(from: source, to: output, mode: mode)
    }
}

@Test func refusesFilesThatAreNotPlans() throws {
    let (root, source) = try fixtureCatalog(plans: ["test-plan.pln": planText(), ".DS_Store": ""])
    defer { try? FileManager.default.removeItem(at: root) }
    let error = #expect(throws: CatalogError.self) {
        try CatalogBuild.write(from: source, to: root.appending(path: "Catalog.sqlite"), mode: .development)
    }
    #expect(error?.problem == "is not a .plan file")
}

@Test func namesTheFileAndLineOfABrokenPlan() throws {
    let (root, source) = try fixtureCatalog(plans: ["test-plan.plan": planText(schedule: "1\tMRK 17")])
    defer { try? FileManager.default.removeItem(at: root) }
    let error = #expect(throws: CatalogError.self) {
        try CatalogBuild.write(from: source, to: root.appending(path: "Catalog.sqlite"), mode: .development)
    }
    #expect(error?.file.lastPathComponent == "test-plan.plan")
    #expect(error?.problem == "line 19: MRK has no chapter 17")
}

/// The app and the server read back exactly the plans the compiler checked.
@Test func theCatalogReadsBackAsCompiled() throws {
    let days = (1...31).map { "\($0)\tPRO \($0)" }.joined(separator: "\n")
    let monthly = planText(
        [
            "id": "monthly-plan", "schedule": "day-of-month", "behaviors": "calendar", "books": "PRO",
            "coverage": "books",
        ],
        schedule: days)
    let (root, source) = try fixtureCatalog(plans: ["test-plan.plan": planText(), "monthly-plan.plan": monthly])
    defer { try? FileManager.default.removeItem(at: root) }
    let output = root.appending(path: "Catalog.sqlite")
    try CatalogBuild.write(from: source, to: output, mode: .development)

    let catalog = try Catalog(path: output.path)
    #expect(catalog.metadata.schemaVersion == CatalogMetadata.currentSchemaVersion)
    #expect(catalog.plans.map(\.id.rawValue) == ["monthly-plan", "test-plan"])
    #expect(catalog.plan(PlanID("test-plan")!) == (try readPlan(planText())))
    #expect(catalog.plan(PlanID("monthly-plan")!) == (try readPlan(monthly, name: "monthly-plan")))
    #expect(catalog.registry.canon("protestant")?.books.count == 66)
    #expect(catalog.versification.verseCount(of: BookID("PSA")!) == 2461)
}

@Test func theRepositorysCatalogOpens() throws {
    let root = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let output = root.appending(path: "Catalog.sqlite")
    try CatalogBuild.write(from: catalogSource, to: output, mode: .release)
    #expect(try Catalog(path: output.path).metadata.buildMode == "release")
}
