/// A plan's identifier, as it appears in the catalog and in addresses
/// (docs/urls.md): one to 64 lowercase ASCII letters and digits, in words
/// joined by single hyphens, such as `gospels-at-your-pace` or
/// `mcheyne-1842`. The catalog compiler, the server, and the app all check
/// ids here, so an address that works on one works on all of them.
public struct PlanID: Hashable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String

    /// Returns nil for text that is not a plan id.
    public init?(_ text: String) {
        guard Self.isValid(text) else { return nil }
        rawValue = text
    }

    public var description: String { rawValue }

    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let id = PlanID(text) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "not a plan id: \(text)"))
        }
        self = id
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    private static func isValid(_ text: String) -> Bool {
        let bytes = Array(text.utf8)
        guard (1...64).contains(bytes.count), bytes.first != hyphen, bytes.last != hyphen else { return false }
        for (index, byte) in bytes.enumerated() {
            switch byte {
            case UInt8(ascii: "a")...UInt8(ascii: "z"), UInt8(ascii: "0")...UInt8(ascii: "9"): continue
            case hyphen where bytes[index - 1] != hyphen: continue
            default: return false
            }
        }
        return true
    }

    private static let hyphen = UInt8(ascii: "-")
}
