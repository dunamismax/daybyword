/// What a compiled catalog says about itself: its schema version and how it
/// was built (`docs/decisions.md` E6).
public struct CatalogMetadata: Sendable, Equatable {
    /// The catalog schema this build writes and reads
    /// (docs/catalog-format.md). The compiler writes it; the app and the
    /// server check it.
    public static let currentSchemaVersion = 2

    public let schemaVersion: Int
    public let buildMode: String

    public init(schemaVersion: Int, buildMode: String) {
        self.schemaVersion = schemaVersion
        self.buildMode = buildMode
    }

    /// Reads the metadata of the catalog at `path`, opening it read-only.
    public static func read(path: String) throws -> CatalogMetadata {
        let catalog = try Database(path: path, access: .readOnly)
        var values: [String: String] = [:]
        for row in try catalog.query("SELECT key, value FROM catalog_meta") {
            if case .text(let key) = row["key"], case .text(let value) = row["value"] {
                values[key] = value
            }
        }
        guard let version = values["schema_version"].flatMap(Int.init), let mode = values["build_mode"] else {
            throw SQLiteError(code: 0, message: "\(path) is not a Day by Word catalog: its metadata is missing")
        }
        return CatalogMetadata(schemaVersion: version, buildMode: mode)
    }
}
