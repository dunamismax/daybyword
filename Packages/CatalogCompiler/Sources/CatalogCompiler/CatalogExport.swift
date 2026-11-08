import Foundation
import ReadingData

/// The catalog's transport document for the server's PostgreSQL import
/// (docs/catalog-format.md, "The export"; BUILD.md PM.14).
///
/// It is read from a compiled catalog, so it carries exactly the normalized
/// schema-3 data the compiler checked: every column's value as written, the
/// plans in the compiler's order (which the content checksum follows), and
/// each plan's rights status from `SOURCES.md`, so the import can refuse what
/// a release may not serve. The same catalog always exports the same bytes.
public struct CatalogExport: Codable, Equatable, Sendable {
    /// The document's name, which an importer checks first.
    public static let format = "daybyword-catalog-export"
    /// Raised whenever the document's meaning changes.
    public static let formatVersion = 1

    public struct Facts: Codable, Equatable, Sendable {
        public var verses: Int
        public var uniqueVerses: Int
        public var repeats: String
        public var omitted: String
        public var wholeChapters: Int
        public var partialChapters: Int
        public var wordsMinimum: Int
        public var wordsMedian: Int
        public var wordsMaximum: Int
    }

    public struct Assignment: Codable, Equatable, Sendable {
        public var id: Int
        public var position: Int
        public var reading: String
        public var words: Int
    }

    public struct Plan: Codable, Equatable, Sendable {
        public var id: String
        public var version: Int
        public var title: String
        public var creator: String
        public var summary: String
        public var suits: String
        public var schedule: String
        public var behaviors: String
        public var readingDays: Int
        public var coverage: String
        public var canon: String
        public var books: String
        public var limitations: String
        public var instructions: String
        public var source: String
        public var rights: String
        /// The rights entry's status in `SOURCES.md` when exported.
        public var rightsStatus: String
        public var review: String
        public var facts: Facts
        public var assignments: [Assignment]
    }

    public struct Resource: Codable, Equatable, Sendable {
        public var name: String
        public var content: String
    }

    public var format: String
    public var formatVersion: Int
    public var schemaVersion: Int
    public var buildMode: String
    public var contentSha256: String
    public var plans: [Plan]
    public var scripture: [Resource]

    /// Reads the compiled catalog at `catalog` and the rights statuses in
    /// `sources`.
    public init(catalog: URL, sources: SourcesRegistry) throws {
        let database = try Database(path: catalog.path, access: .readOnly)
        var meta: [String: String] = [:]
        for row in try database.query("SELECT key, value FROM catalog_meta") {
            if case .text(let key) = row["key"], case .text(let value) = row["value"] { meta[key] = value }
        }
        guard let schema = meta["schema_version"].flatMap(Int.init), schema == CatalogBuild.schemaVersion else {
            throw CatalogError(
                file: catalog,
                problem: "is schema \(meta["schema_version"] ?? "unknown"), not \(CatalogBuild.schemaVersion)")
        }
        format = Self.format
        formatVersion = Self.formatVersion
        schemaVersion = schema
        buildMode = meta["build_mode"] ?? ""
        contentSha256 = meta["content_sha256"] ?? ""

        func text(_ row: SQLiteRow, _ column: String) throws -> String {
            guard case .text(let value) = row[column] else {
                throw CatalogError(file: catalog, problem: "\(column) is not text")
            }
            return value
        }
        func number(_ row: SQLiteRow, _ column: String) throws -> Int {
            guard case .integer(let value) = row[column] else {
                throw CatalogError(file: catalog, problem: "\(column) is not a whole number")
            }
            return Int(value)
        }

        // The compiler inserted plans in the order its checksum follows.
        plans = try database.query("SELECT * FROM plans ORDER BY rowid").map { row in
            let id = try text(row, "id")
            let rights = try text(row, "rights")
            guard let status = sources.statuses[rights] else {
                throw CatalogError(file: catalog, problem: "plan \(id): rights \(rights) has no entry in SOURCES.md")
            }
            guard let facts = try database.query("SELECT * FROM plan_facts WHERE plan_id = ?", [.text(id)]).first
            else { throw CatalogError(file: catalog, problem: "plan \(id) has no facts") }
            let assignments = try database.query(
                "SELECT id, position, reading, words FROM assignments WHERE plan_id = ? ORDER BY position", [.text(id)]
            ).map {
                Assignment(
                    id: try number($0, "id"), position: try number($0, "position"), reading: try text($0, "reading"),
                    words: try number($0, "words"))
            }
            return Plan(
                id: id, version: try number(row, "version"), title: try text(row, "title"),
                creator: try text(row, "creator"), summary: try text(row, "summary"), suits: try text(row, "suits"),
                schedule: try text(row, "schedule"), behaviors: try text(row, "behaviors"),
                readingDays: try number(row, "reading_days"), coverage: try text(row, "coverage"),
                canon: try text(row, "canon"), books: try text(row, "books"),
                limitations: try text(row, "limitations"), instructions: try text(row, "instructions"),
                source: try text(row, "source"), rights: rights, rightsStatus: status.rawValue,
                review: try text(row, "review"),
                facts: Facts(
                    verses: try number(facts, "verses"), uniqueVerses: try number(facts, "unique_verses"),
                    repeats: try text(facts, "repeats"), omitted: try text(facts, "omitted"),
                    wholeChapters: try number(facts, "whole_chapters"),
                    partialChapters: try number(facts, "partial_chapters"),
                    wordsMinimum: try number(facts, "words_minimum"), wordsMedian: try number(facts, "words_median"),
                    wordsMaximum: try number(facts, "words_maximum")),
                assignments: assignments)
        }
        scripture = try database.query("SELECT name, content FROM scripture ORDER BY name").map {
            Resource(name: try text($0, "name"), content: try text($0, "content"))
        }
    }

    /// The document as JSON: sorted keys, two-space indents, and a final
    /// newline, so the same catalog always gives the same bytes.
    public func json() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        return try encoder.encode(self) + Data("\n".utf8)
    }

    /// Exports the compiled catalog at `catalog` to `output`, replacing any
    /// file there only once the new one is written.
    public static func write(catalog: URL, sources: SourcesRegistry, to output: URL) throws {
        let data = try CatalogExport(catalog: catalog, sources: sources).json()
        try FileManager.default.createDirectory(
            at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: output, options: .atomic)
    }
}
