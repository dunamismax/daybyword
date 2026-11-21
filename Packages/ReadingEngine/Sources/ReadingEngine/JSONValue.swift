/// Any JSON value. The journal's wire form is read through it, so a malformed
/// event is told from a well-formed one field by field, with the same answer
/// as the TypeScript runtime (docs/engine.md, "The journal").
public enum JSONValue: Hashable, Sendable, Codable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .number(let value):
            // Whole numbers are written as whole numbers, never `1.0`.
            if let whole = Int(exactly: value) { try container.encode(whole) } else { try container.encode(value) }
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    /// A whole number within JavaScript's safe integers, or nil.
    var whole: Int? {
        guard case .number(let value) = self, value.rounded() == value, abs(value) <= 9_007_199_254_740_991 else {
            return nil
        }
        return Int(value)
    }

    var text: String? {
        if case .string(let value) = self { value } else { nil }
    }
}
