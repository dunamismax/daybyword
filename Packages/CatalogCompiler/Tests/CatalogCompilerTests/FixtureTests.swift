import CatalogCompiler
import Foundation
import ReadingEngine
import Testing

// The compiler's shared fixture in tests/fixtures/ (its README): invented plan
// files and what the compiler makes of them, for the PostgreSQL import to
// check against (BUILD.md PM.14). Set DBW_RECORD_FIXTURES=1 to rewrite the
// outputs from the code, then review the diff before committing.

private struct PlanFileFixture: Codable {
    struct Input: Codable {
        /// The file name, without `.plan`; `test-plan` when absent.
        var name: String?
        /// Front matter values replaced, or removed (null).
        var changes: [String: String?]?
        /// The schedule, when not the base schedule.
        var schedule: String?
        /// Text put before the plan file.
        var prefix: String?
        /// Pairs of text replaced in the plan file, in order.
        var replace: [[String]]?
    }

    struct Output: Codable, Equatable {
        struct Assignment: Codable, Equatable {
            var id: Int
            var reading: String
        }

        struct Facts: Codable, Equatable {
            var verses: Int
            var uniqueVerses: Int
            var repeats: [String]
            var omitted: [String]
            var wholeChapters: Int
            var partialChapters: Int
            var words: [Int]
            var workload: [Int]
            /// Why the coverage claim fails, when it does.
            var claimNotMet: String?
        }

        var error: String?
        var id: String?
        var version: Int?
        var schedule: String?
        var behaviors: [String]?
        var readingDays: Int?
        var coverage: String?
        var canon: String?
        var books: [String]?
        var review: String?
        var rights: String?
        var assignments: [Assignment]?
        var facts: Facts?
    }

    struct Case: Codable {
        var input: Input
        var output: Output?
    }

    var fixture: String
    var version: Int
    var about: String
    /// The base plan file's front matter, in order, and its schedule.
    var frontMatter: [[String]]
    var schedule: String
    var cases: [Case]

    func text(of input: Input) -> String {
        let lines = frontMatter.compactMap { pair -> String? in
            let value = input.changes?[pair[0]] ?? pair[1]
            return value.map { "\(pair[0]): \($0)" }
        }
        var text =
            (input.prefix ?? "") + lines.joined(separator: "\n") + "\n---\n" + (input.schedule ?? schedule) + "\n"
        for pair in input.replace ?? [] { text = text.replacingOccurrences(of: pair[0], with: pair[1]) }
        return text
    }
}

@Test func planFilesMatchTheirFixture() throws {
    let url = catalogSource.deletingLastPathComponent().appending(path: "tests/fixtures/plan-files.json")
    var file = try JSONDecoder().decode(PlanFileFixture.self, from: Data(contentsOf: url))
    let registry = try CatalogBuild.readRegistry(from: catalogSource)
    let english = try #require(try CatalogBuild.readVersifications(from: catalogSource, registry: registry)[.english])
    let counts = try CatalogBuild.readWordCounts(from: catalogSource, versification: english)

    func compile(_ input: PlanFileFixture.Input) -> PlanFileFixture.Output {
        let plan: Plan
        do {
            plan = try PlanFile.read(
                file.text(of: input), name: input.name ?? "test-plan", registry: registry, versification: english)
        } catch {
            return .init(error: error.description)
        }
        let facts: PlanFacts
        do {
            facts = try PlanFacts(plan, versification: english, counts: counts)
        } catch {
            return .init(error: error.description)
        }
        var claimNotMet: String?
        do { try facts.check(plan, versification: english) } catch { claimNotMet = error.description }
        let text = { (passage: Passage) in ReferenceFormat.text(of: passage, in: english) }
        return .init(
            id: plan.id.rawValue, version: plan.version, schedule: plan.schedule.rawValue,
            behaviors: plan.behaviors.map(\.rawValue), readingDays: plan.readingDays, coverage: plan.coverage.rawValue,
            canon: plan.canon, books: plan.books.map(\.rawValue), review: plan.review.rawValue, rights: plan.rights,
            assignments: plan.assignments.map {
                .init(id: $0.id, reading: ReferenceFormat.text(of: $0.reading, in: english))
            },
            facts: .init(
                verses: facts.verses, uniqueVerses: facts.uniqueVerses, repeats: facts.repeats.map(text),
                omitted: facts.omitted.map(text), wholeChapters: facts.wholeChapters,
                partialChapters: facts.partialChapters, words: facts.words,
                workload: [facts.workload.minimum.words, facts.workload.median.words, facts.workload.maximum.words],
                claimNotMet: claimNotMet))
    }

    #expect(file.fixture == "plan-files")
    if ProcessInfo.processInfo.environment["DBW_RECORD_FIXTURES"] != nil {
        for index in file.cases.indices { file.cases[index].output = compile(file.cases[index].input) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try (encoder.encode(file) + Data("\n".utf8)).write(to: url, options: .atomic)
        return
    }
    #expect(!file.cases.isEmpty)
    for (index, testCase) in file.cases.enumerated() {
        #expect(testCase.output == compile(testCase.input), "plan-files case \(index)")
    }
}
