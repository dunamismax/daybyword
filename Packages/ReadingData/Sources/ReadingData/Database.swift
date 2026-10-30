import Foundation

#if canImport(SQLite3)
    import SQLite3
#else
    import CSQLite
#endif

/// A value stored in or read from SQLite.
public enum SQLiteValue: Sendable, Hashable {
    case null
    case integer(Int64)
    case real(Double)
    case text(String)
    case blob([UInt8])
}

/// An error reported by SQLite, with SQLite's own result code and message.
public struct SQLiteError: Error, Sendable, CustomStringConvertible {
    public let code: Int32
    public let message: String

    public var description: String { "SQLite error \(code): \(message)" }
}

/// One row of a query result, with its column names in result order.
public struct SQLiteRow: Sendable, Hashable {
    public let columns: [String]
    public let values: [SQLiteValue]

    /// The value of the named column, or `nil` if the row has no such column.
    public subscript(column: String) -> SQLiteValue? {
        columns.firstIndex(of: column).map { values[$0] }
    }
}

/// A connection to one SQLite database, through the system SQLite3 library
/// (docs/decisions.md E9).
///
/// A connection belongs to one isolation domain at a time, so it is not
/// `Sendable`. Code that shares a database across tasks owns its connection
/// inside an actor.
public final class Database {
    /// How a database file is opened.
    public enum Access: Sendable {
        /// Reading only; the file must exist. The server opens the catalog so.
        case readOnly
        /// Reading and writing; the file must exist.
        case readWrite
        /// Reading and writing, creating the file if it does not exist.
        case create
    }

    private let handle: OpaquePointer

    /// The version of the SQLite library this process links, such as "3.51.0".
    public static var libraryVersion: String { String(cString: sqlite3_libversion()) }

    /// Opens the database at `path`.
    public init(path: String, access: Access) throws {
        let flags: Int32
        switch access {
        case .readOnly: flags = SQLITE_OPEN_READONLY
        case .readWrite: flags = SQLITE_OPEN_READWRITE
        case .create: flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
        }
        var opened: OpaquePointer?
        let code = sqlite3_open_v2(path, &opened, flags, nil)
        guard code == SQLITE_OK, let opened else {
            let message = opened.map { String(cString: sqlite3_errmsg($0)) } ?? "cannot open \(path)"
            sqlite3_close_v2(opened)
            throw SQLiteError(code: code, message: message)
        }
        handle = opened
        sqlite3_extended_result_codes(handle, 1)
    }

    /// Opens a new, empty database that lives only in memory.
    public static func inMemory() throws -> Database {
        try Database(path: ":memory:", access: .create)
    }

    deinit {
        sqlite3_close_v2(handle)
    }

    /// Runs one or more statements that take no parameters, such as a schema.
    public func execute(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        let code = sqlite3_exec(handle, sql, nil, nil, &errorMessage)
        guard code == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? lastErrorMessage
            sqlite3_free(errorMessage)
            throw SQLiteError(code: code, message: message)
        }
    }

    /// Runs one statement with its parameters bound in order, ignoring any rows.
    public func run(_ sql: String, _ values: [SQLiteValue] = []) throws {
        try withStatement(sql, values) { statement in
            while try step(statement) {}
        }
    }

    /// Runs one query with its parameters bound in order and returns its rows.
    public func query(_ sql: String, _ values: [SQLiteValue] = []) throws -> [SQLiteRow] {
        try withStatement(sql, values) { statement in
            let count = sqlite3_column_count(statement)
            let columns = (0..<count).map { String(cString: sqlite3_column_name(statement, $0)) }
            var rows: [SQLiteRow] = []
            while try step(statement) {
                let values = (0..<count).map { column(statement, $0) }
                rows.append(SQLiteRow(columns: columns, values: values))
            }
            return rows
        }
    }

    /// Runs `body` inside a transaction, committing if it returns and rolling
    /// back if it throws.
    public func transaction<T>(_ body: () throws -> T) throws -> T {
        try execute("BEGIN IMMEDIATE")
        do {
            let result = try body()
            try execute("COMMIT")
            return result
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    // MARK: - Statements

    private var lastErrorMessage: String { String(cString: sqlite3_errmsg(handle)) }

    private func withStatement<T>(
        _ sql: String,
        _ values: [SQLiteValue],
        _ body: (OpaquePointer) throws -> T
    ) throws -> T {
        var prepared: OpaquePointer?
        let code = sqlite3_prepare_v2(handle, sql, -1, &prepared, nil)
        guard code == SQLITE_OK, let statement = prepared else {
            throw SQLiteError(code: code, message: lastErrorMessage)
        }
        defer { sqlite3_finalize(statement) }
        for (offset, value) in values.enumerated() {
            try bind(value, at: Int32(offset + 1), in: statement)
        }
        return try body(statement)
    }

    /// Steps the statement, returning `true` while it has a row to read.
    private func step(_ statement: OpaquePointer) throws -> Bool {
        switch sqlite3_step(statement) {
        case SQLITE_ROW: return true
        case SQLITE_DONE: return false
        case let code: throw SQLiteError(code: code, message: lastErrorMessage)
        }
    }

    private func bind(_ value: SQLiteValue, at index: Int32, in statement: OpaquePointer) throws {
        let code: Int32
        switch value {
        case .null:
            code = sqlite3_bind_null(statement, index)
        case .integer(let integer):
            code = sqlite3_bind_int64(statement, index, integer)
        case .real(let real):
            code = sqlite3_bind_double(statement, index, real)
        case .text(let text):
            code = sqlite3_bind_text(statement, index, text, -1, transient)
        case .blob(let bytes) where bytes.isEmpty:
            code = sqlite3_bind_zeroblob(statement, index, 0)
        case .blob(let bytes):
            code = bytes.withUnsafeBytes { buffer in
                sqlite3_bind_blob(statement, index, buffer.baseAddress, Int32(buffer.count), transient)
            }
        }
        guard code == SQLITE_OK else {
            throw SQLiteError(code: code, message: lastErrorMessage)
        }
    }

    private func column(_ statement: OpaquePointer, _ index: Int32) -> SQLiteValue {
        switch sqlite3_column_type(statement, index) {
        case SQLITE_INTEGER:
            return .integer(sqlite3_column_int64(statement, index))
        case SQLITE_FLOAT:
            return .real(sqlite3_column_double(statement, index))
        case SQLITE_TEXT:
            let count = Int(sqlite3_column_bytes(statement, index))
            guard let text = sqlite3_column_text(statement, index) else { return .text("") }
            return .text(String(decoding: UnsafeBufferPointer(start: text, count: count), as: UTF8.self))
        case SQLITE_BLOB:
            let count = Int(sqlite3_column_bytes(statement, index))
            guard let blob = sqlite3_column_blob(statement, index) else { return .blob([]) }
            return .blob(Array(UnsafeRawBufferPointer(start: blob, count: count)))
        default:
            return .null
        }
    }

    /// Tells SQLite to copy bound text and blobs before the call returns.
    private var transient: sqlite3_destructor_type {
        unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    }
}
