import Foundation
import ReadingData
import ReadingEngine

/// Writes a compiled catalog database.
///
/// It checks the book registry (`scripture/books.json`), the versification
/// schemes (`scripture/versification/`), the word counts (`scripture/words/`),
/// the sources registry (`SOURCES.md`), and every plan in `plans/`
/// (docs/catalog-format.md), and writes the plans and their assignments with
/// a content checksum. A catalog with any problem writes nothing.
public enum CatalogBuild {
    /// How strictly the catalog is built. A release build leaves out plans
    /// reviewed less than `reviewed` and refuses a plan whose source is not
    /// `cleared`; a development build includes every plan whose source is
    /// `cleared` or `pending`.
    public enum Mode: String, Sendable {
        case development
        case release
    }

    /// The version of the catalog's database schema.
    public static let schemaVersion = CatalogMetadata.currentSchemaVersion

    /// The review level a plan needs to be in a release build (AGENTS.md §7).
    public static let releaseReview = Plan.Review.reviewed

    /// Builds the catalog from the `catalog/` directory at `source` and writes
    /// it to `output`, replacing any file there only once the new one is
    /// complete, and returns the ids of plans a release build left out.
    @discardableResult
    public static func write(from source: URL, to output: URL, mode: Mode) throws -> [PlanID] {
        let registry = try readRegistry(from: source)
        let schemes = try readVersifications(from: source, registry: registry)
        let english = schemes[.english]!
        let counts = try readWordCounts(from: source, versification: english)
        let sources = try readSources(from: source)
        let all = try readPlans(from: source, registry: registry, versification: english)
        var facts: [PlanID: PlanFacts] = [:]
        for (url, plan) in all {
            try checkRights(plan, in: url, sources: sources, mode: mode)
            do {
                let computed = try PlanFacts(plan, versification: english, counts: counts)
                try computed.check(plan, versification: english)
                facts[plan.id] = computed
            } catch {
                throw CatalogError(file: url, problem: error.description)
            }
        }
        // The scripture data readers need to read the plans back: the book
        // registry and the scheme every reference was checked against.
        var scripture: [(name: String, content: String)] = []
        for name in ["books.json", "versification/english.tsv"] {
            scripture.append(
                (name, try String(contentsOf: source.appending(path: "scripture/\(name)"), encoding: .utf8)))
        }
        let plans = all.map(\.plan).filter { mode == .development || $0.review >= releaseReview }
        let leftOut = all.map(\.plan).filter { !plans.contains($0) }.map(\.id)

        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: output.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let partial = output.appendingPathExtension("partial")
        try? fileManager.removeItem(at: partial)

        do {
            let database = try Database(path: partial.path, access: .create)
            try database.execute(
                """
                PRAGMA journal_mode = DELETE;
                CREATE TABLE catalog_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL) STRICT;
                CREATE TABLE plans (
                    id TEXT PRIMARY KEY, version INTEGER NOT NULL, title TEXT NOT NULL, creator TEXT NOT NULL,
                    summary TEXT NOT NULL, suits TEXT NOT NULL, schedule TEXT NOT NULL, behaviors TEXT NOT NULL,
                    reading_days INTEGER NOT NULL, coverage TEXT NOT NULL, canon TEXT NOT NULL,
                    books TEXT NOT NULL, limitations TEXT NOT NULL, instructions TEXT NOT NULL,
                    source TEXT NOT NULL, rights TEXT NOT NULL, review TEXT NOT NULL
                ) STRICT;
                CREATE TABLE assignments (
                    plan_id TEXT NOT NULL REFERENCES plans (id), id INTEGER NOT NULL,
                    position INTEGER NOT NULL, reading TEXT NOT NULL, words INTEGER NOT NULL,
                    PRIMARY KEY (plan_id, id), UNIQUE (plan_id, position)
                ) STRICT;
                CREATE TABLE scripture (name TEXT PRIMARY KEY, content TEXT NOT NULL) STRICT;
                CREATE TABLE plan_facts (
                    plan_id TEXT PRIMARY KEY REFERENCES plans (id), verses INTEGER NOT NULL,
                    unique_verses INTEGER NOT NULL, repeats TEXT NOT NULL, omitted TEXT NOT NULL,
                    whole_chapters INTEGER NOT NULL, partial_chapters INTEGER NOT NULL,
                    words_minimum INTEGER NOT NULL, words_median INTEGER NOT NULL, words_maximum INTEGER NOT NULL
                ) STRICT;
                """
            )
            try database.transaction {
                for (name, content) in scripture {
                    try database.run("INSERT INTO scripture VALUES (?, ?)", [.text(name), .text(content)])
                }
                for plan in plans {
                    try database.run(
                        "INSERT INTO plans VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        row(plan).map { $0.value })
                    let planFacts = facts[plan.id]!
                    for (position, assignment) in plan.assignments.enumerated() {
                        try database.run(
                            "INSERT INTO assignments VALUES (?, ?, ?, ?, ?)",
                            [
                                .text(plan.id.rawValue), .integer(Int64(assignment.id)), .integer(Int64(position + 1)),
                                .text(ReferenceFormat.text(of: assignment.reading, in: english)),
                                .integer(Int64(planFacts.words[position])),
                            ])
                    }
                    try database.run(
                        "INSERT INTO plan_facts VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        [.text(plan.id.rawValue)] + row(planFacts, versification: english).map(\.value))
                }
                for (key, value) in metadata(
                    mode: mode, plans: plans, facts: facts, scripture: scripture, versification: english)
                {
                    try database.run("INSERT INTO catalog_meta (key, value) VALUES (?, ?)", [.text(key), .text(value)])
                }
            }
        } catch {
            try? fileManager.removeItem(at: partial)
            throw error
        }

        if fileManager.fileExists(atPath: output.path) {
            _ = try fileManager.replaceItemAt(output, withItemAt: partial)
        } else {
            try fileManager.moveItem(at: partial, to: output)
        }
        return leftOut
    }

    /// Reads every plan in `plans/`, sorted by id. Every file there must be a
    /// plan file (`<id>.plan`); hidden files are ignored.
    public static func readPlans(
        from source: URL, registry: BookRegistry, versification: Versification
    ) throws -> [(url: URL, plan: Plan)] {
        let directory = source.appending(path: "plans", directoryHint: .isDirectory)
        let names: [String]
        do {
            names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        } catch {
            throw CatalogError(file: directory, problem: "cannot be read (\(error.localizedDescription))")
        }
        var plans: [(url: URL, plan: Plan)] = []
        for name in names.sorted() where !name.hasPrefix(".") {
            let url = directory.appending(path: name)
            guard name.hasSuffix(".plan") else { throw CatalogError(file: url, problem: "is not a .plan file") }
            let text: String
            do {
                text = try String(contentsOf: url, encoding: .utf8)
            } catch {
                throw CatalogError(file: url, problem: "cannot be read (\(error.localizedDescription))")
            }
            do {
                let plan = try PlanFile.read(
                    text, name: String(name.dropLast(5)), registry: registry, versification: versification)
                plans.append((url, plan))
            } catch {
                throw CatalogError(file: url, problem: error.description)
            }
        }
        return plans
    }

    /// Reads the sources registry, `SOURCES.md`.
    public static func readSources(from source: URL) throws -> SourcesRegistry {
        let url = source.appending(path: "SOURCES.md")
        let text: String
        do {
            text = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw CatalogError(file: url, problem: "cannot be read (\(error.localizedDescription))")
        }
        do {
            return try SourcesRegistry(markdown: text)
        } catch {
            throw CatalogError(file: url, problem: error.description)
        }
    }

    /// Throws unless the plan's rights entry exists and its status lets the
    /// plan into a build of this mode.
    static func checkRights(_ plan: Plan, in url: URL, sources: SourcesRegistry, mode: Mode) throws {
        guard let status = sources.statuses[plan.rights] else {
            throw CatalogError(file: url, problem: "rights: \(plan.rights) has no entry in SOURCES.md")
        }
        switch (status, mode) {
        case (.cleared, _), (.pending, .development): return
        case (.pending, .release):
            throw CatalogError(file: url, problem: "rights: \(plan.rights) is pending, so the plan cannot be released")
        case (.rejected, _), (.reference, _):
            throw CatalogError(
                file: url, problem: "rights: \(plan.rights) is \(status.rawValue), so nothing from it ships")
        }
    }

    /// A plan's row in the `plans` table, by column.
    static func row(_ plan: Plan) -> [(column: String, value: SQLiteValue)] {
        [
            ("id", .text(plan.id.rawValue)), ("version", .integer(Int64(plan.version))), ("title", .text(plan.title)),
            ("creator", .text(plan.creator)), ("summary", .text(plan.summary)), ("suits", .text(plan.suits)),
            ("schedule", .text(plan.schedule.rawValue)),
            ("behaviors", .text(plan.behaviors.map(\.rawValue).joined(separator: ", "))),
            ("reading_days", .integer(Int64(plan.readingDays))), ("coverage", .text(plan.coverage.rawValue)),
            ("canon", .text(plan.canon)), ("books", .text(plan.books.map(\.rawValue).joined(separator: ", "))),
            ("limitations", .text(plan.limitations)), ("instructions", .text(plan.instructions)),
            ("source", .text(plan.source)), ("rights", .text(plan.rights)), ("review", .text(plan.review.rawValue)),
        ]
    }

    /// Reads and checks the book registry under `source`.
    public static func readRegistry(from source: URL) throws -> BookRegistry {
        let url = source.appending(path: "scripture/books.json")
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw CatalogError(file: url, problem: "cannot be read (\(error.localizedDescription))")
        }
        do {
            return try BookRegistry(json: data)
        } catch let error as BookRegistryError {
            throw CatalogError(file: url, problem: error.description)
        }
    }

    /// Reads every versification scheme under `source` and checks each against
    /// the registry.
    public static func readVersifications(
        from source: URL, registry: BookRegistry
    ) throws -> [Versification.Scheme: Versification] {
        var schemes: [Versification.Scheme: Versification] = [:]
        for scheme in Versification.Scheme.allCases {
            let url = source.appending(path: "scripture/versification/\(scheme.rawValue).tsv")
            let text: String
            do {
                text = try String(contentsOf: url, encoding: .utf8)
            } catch {
                throw CatalogError(file: url, problem: "cannot be read (\(error.localizedDescription))")
            }
            do {
                let versification = try Versification(scheme: scheme, tsv: text)
                try versification.check(against: registry)
                schemes[scheme] = versification
            } catch let error as VersificationError {
                throw CatalogError(file: url, problem: error.description)
            }
        }
        return schemes
    }

    /// Reads the word counts under `source` and checks them against the
    /// scheme they are numbered by.
    public static func readWordCounts(from source: URL, versification: Versification) throws -> WordCounts {
        let url = source.appending(path: "scripture/words/web.tsv")
        let text: String
        do {
            text = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw CatalogError(file: url, problem: "cannot be read (\(error.localizedDescription))")
        }
        do {
            return try WordCounts(tsv: text, versification: versification)
        } catch {
            throw CatalogError(file: url, problem: error.description)
        }
    }

    /// A plan's computed facts in the `plan_facts` table, by column after
    /// `plan_id`. Repeats and omissions are written as plan-file readings, or
    /// empty when there are none.
    static func row(_ facts: PlanFacts, versification: Versification) -> [(column: String, value: SQLiteValue)] {
        func text(_ passages: [Passage]) -> SQLiteValue {
            .text(passages.map { ReferenceFormat.text(of: $0, in: versification) }.joined(separator: "; "))
        }
        return [
            ("verses", .integer(Int64(facts.verses))), ("unique_verses", .integer(Int64(facts.uniqueVerses))),
            ("repeats", text(facts.repeats)), ("omitted", text(facts.omitted)),
            ("whole_chapters", .integer(Int64(facts.wholeChapters))),
            ("partial_chapters", .integer(Int64(facts.partialChapters))),
            ("words_minimum", .integer(Int64(facts.workload.minimum.words))),
            ("words_median", .integer(Int64(facts.workload.median.words))),
            ("words_maximum", .integer(Int64(facts.workload.maximum.words))),
        ]
    }

    /// The metadata written into every catalog, in a fixed order so that two
    /// builds of the same sources write the same rows: the schema version,
    /// the build mode, the number of plans, and a SHA-256 of the scripture
    /// data and the plans' contents and computed facts, which is the same wherever the catalog
    /// is built.
    static func metadata(
        mode: Mode, plans: [Plan], facts: [PlanID: PlanFacts], scripture: [(name: String, content: String)],
        versification: Versification
    ) -> [(String, String)] {
        var content: [UInt8] = []
        for (name, text) in scripture { content += Array("\(name)\n\(text)\n".utf8) }
        for plan in plans {
            for (column, value) in row(plan) + row(facts[plan.id]!, versification: versification) {
                let text: String =
                    switch value {
                    case .text(let text): text
                    case .integer(let number): String(number)
                    default: ""
                    }
                content += Array("\(column)\t\(text)\n".utf8)
            }
            for (assignment, words) in zip(plan.assignments, facts[plan.id]!.words) {
                let reading = ReferenceFormat.text(of: assignment.reading, in: versification)
                content += Array("\(assignment.id)\t\(reading)\t\(words)\n".utf8)
            }
        }
        return [
            ("schema_version", String(schemaVersion)),
            ("build_mode", mode.rawValue),
            ("plans", String(plans.count)),
            ("content_sha256", SHA256.hex(content)),
        ]
    }
}

/// A problem in the catalog's sources, naming the file it is in.
public struct CatalogError: Error, CustomStringConvertible, Equatable {
    public let file: URL
    public let problem: String

    public var description: String { "\(file.path): \(problem)" }
}
