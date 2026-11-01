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
            self.plans = try Self.plans(in: database, versification: versification)
        } catch let error as CatalogReadError {
            throw error
        } catch {
            throw CatalogReadError(path: path, problem: "cannot be read (\(error))")
        }
    }

    public func plan(_ id: PlanID) -> Plan? {
        plans.first { $0.id == id }
    }

    private static func plans(in database: Database, versification: Versification) throws -> [Plan] {
        var assignments: [String: [Plan.Assignment]] = [:]
        for row in try database.query("SELECT plan_id, id, reading FROM assignments ORDER BY plan_id, position") {
            assignments[try text(row, "plan_id"), default: []].append(
                Plan.Assignment(
                    id: try integer(row, "id"),
                    reading: try ReferenceFormat.reading(try text(row, "reading"), in: versification)))
        }
        return try database.query("SELECT * FROM plans ORDER BY id").map { row in
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
