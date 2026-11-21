import Foundation
import ReadingEngine

/// A compiled catalog, read whole when it is opened (docs/catalog-format.md).
/// It carries the book registry and the versification it was compiled with,
/// so the app and the server read references exactly as the compiler checked
/// them and need nothing else from `catalog/`.
public struct Catalog: Sendable {
    public let metadata: CatalogMetadata
    public let registry: BookRegistry
    public let versification: Versification
    /// Every plan, sorted by id.
    public let plans: [Plan]
    /// What the compiler computed for each plan (docs/catalog-format.md,
    /// "What the compiler adds"), which its page shows.
    public let facts: [PlanID: Facts]
    /// Each plan's readings' words, by assignment id.
    private let words: [PlanID: [Int: Int]]

    /// What the compiler computed from a plan's schedule. Passages are in
    /// plan-file writing.
    public struct Facts: Hashable, Sendable {
        public let verses: Int
        public let uniqueVerses: Int
        /// The verses read more than once, as the fewest passages.
        public let repeats: [Passage]
        /// The verses of the listed books that no reading gives.
        public let omitted: [Passage]
        public let wholeChapters: Int
        public let partialChapters: Int
        public let workload: PlanWorkload
    }

    /// Opens the catalog at `path` read-only. A missing file, a catalog of
    /// another schema version, or a catalog that does not read back as the
    /// compiler wrote it throws `CatalogReadError`, naming the path.
    public init(path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw CatalogReadError(path: path, problem: "does not exist; run `make catalog`")
        }
        let metadata: CatalogMetadata
        do {
            metadata = try CatalogMetadata.read(path: path)
        } catch {
            throw CatalogReadError(path: path, problem: "is not a Day by Word catalog (\(error))")
        }
        guard metadata.schemaVersion == CatalogMetadata.currentSchemaVersion else {
            throw CatalogReadError(
                path: path,
                problem: "has schema \(metadata.schemaVersion), but this build reads schema "
                    + "\(CatalogMetadata.currentSchemaVersion); run `make catalog`")
        }
        do {
            let database = try Database(path: path, access: .readOnly)
            var scripture: [String: String] = [:]
            for row in try database.query("SELECT name, content FROM scripture") {
                if case .text(let name) = row["name"], case .text(let content) = row["content"] {
                    scripture[name] = content
                }
            }
            guard let books = scripture["books.json"], let english = scripture["versification/english.tsv"] else {
                throw CatalogReadError(path: path, problem: "is missing its scripture data")
            }
            let registry = try BookRegistry(json: Data(books.utf8))
            let versification = try Versification(scheme: .english, tsv: english)
            self.metadata = metadata
            self.registry = registry
            self.versification = versification
            let (plans, words) = try Self.plans(in: database, versification: versification)
            self.plans = plans
            self.words = words
            self.facts = try Self.facts(in: database, versification: versification)
        } catch let error as CatalogReadError {
            throw error
        } catch {
            throw CatalogReadError(path: path, problem: "cannot be read (\(error))")
        }
    }

    public func plan(_ id: PlanID) -> Plan? {
        plans.first { $0.id == id }
    }

    /// A plan as the reading rules take it, with its readings' words.
    public func version(of plan: Plan) -> PlanVersion {
        PlanVersion(
            id: plan.id, version: plan.version, schedule: plan.schedule, behaviors: plan.behaviors,
            readingDays: plan.readingDays, assignments: plan.assignments, words: words[plan.id] ?? [:])
    }

    /// Every plan as the reading rules take it.
    public var versions: [PlanVersion] { plans.map(version(of:)) }

    private static func facts(in database: Database, versification: Versification) throws -> [PlanID: Facts] {
        func passages(_ text: String) throws -> [Passage] {
            text.isEmpty ? [] : try ReferenceFormat.reading(text, in: versification).passages
        }
        var facts: [PlanID: Facts] = [:]
        for row in try database.query("SELECT * FROM plan_facts") {
            let id = try PlanID(text(row, "plan_id")).orThrow("plan_id")
            // The lightest, the middle and the heaviest reading: their own
            // middle is the plan's.
            let words = try ["words_minimum", "words_median", "words_maximum"].map { try integer(row, $0) }
            facts[id] = Facts(
                verses: try integer(row, "verses"), uniqueVerses: try integer(row, "unique_verses"),
                repeats: try passages(text(row, "repeats")), omitted: try passages(text(row, "omitted")),
                wholeChapters: try integer(row, "whole_chapters"),
                partialChapters: try integer(row, "partial_chapters"),
                workload: try PlanWorkload(words: words).orThrow("words_median"))
        }
        return facts
    }

    private static func plans(
        in database: Database, versification: Versification
    ) throws -> ([Plan], [PlanID: [Int: Int]]) {
        var assignments: [String: [Plan.Assignment]] = [:]
        var words: [PlanID: [Int: Int]] = [:]
        for row in try database.query(
            "SELECT plan_id, id, reading, words FROM assignments ORDER BY plan_id, position")
        {
            let planID = try text(row, "plan_id")
            let id = try integer(row, "id")
            assignments[planID, default: []].append(
                Plan.Assignment(
                    id: id, reading: try ReferenceFormat.reading(try text(row, "reading"), in: versification)))
            words[try PlanID(planID).orThrow("plan_id"), default: [:]][id] = try integer(row, "words")
        }
        let plans = try database.query("SELECT * FROM plans ORDER BY id").map { row in
            let id = try text(row, "id")
            func list<T>(_ column: String, _ make: (String) -> T?) throws -> [T] {
                try text(row, column).split(separator: ", ").map { try make(String($0)).orThrow(column) }
            }
            return Plan(
                id: try PlanID(id).orThrow("id"), version: try integer(row, "version"), title: try text(row, "title"),
                creator: try text(row, "creator"), summary: try text(row, "summary"), suits: try text(row, "suits"),
                schedule: try Plan.Schedule(rawValue: text(row, "schedule")).orThrow("schedule"),
                behaviors: try list("behaviors", Plan.Behavior.init(rawValue:)),
                readingDays: try integer(row, "reading_days"),
                coverage: try Plan.Coverage(rawValue: text(row, "coverage")).orThrow("coverage"),
                canon: try text(row, "canon"), books: try list("books", BookID.init),
                limitations: try text(row, "limitations"), instructions: try text(row, "instructions"),
                source: try text(row, "source"), rights: try text(row, "rights"),
                review: try Plan.Review(rawValue: text(row, "review")).orThrow("review"),
                assignments: assignments[id] ?? [])
        }
        return (plans, words)
    }

    private static func text(_ row: SQLiteRow, _ column: String) throws -> String {
        guard case .text(let value) = row[column] else { throw UnexpectedColumn(column: column) }
        return value
    }

    private static func integer(_ row: SQLiteRow, _ column: String) throws -> Int {
        guard case .integer(let value) = row[column] else { throw UnexpectedColumn(column: column) }
        return Int(value)
    }
}

/// A catalog that cannot be opened, and why.
public struct CatalogReadError: Error, Equatable, CustomStringConvertible {
    public let path: String
    public let problem: String

    public init(path: String, problem: String) {
        self.path = path
        self.problem = problem
    }

    public var description: String { "\(path) \(problem)" }
}

private struct UnexpectedColumn: Error, CustomStringConvertible {
    let column: String
    var description: String { "the \(column) column does not hold what the compiler writes" }
}

extension Optional {
    fileprivate func orThrow(_ column: String) throws -> Wrapped {
        guard let self else { throw UnexpectedColumn(column: column) }
        return self
    }
}
