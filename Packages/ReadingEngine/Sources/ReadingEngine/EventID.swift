/// The id of a journal event or an enrollment (docs/engine.md, "The
/// journal"): a UUIDv7 (RFC 9562) in lowercase with hyphens, such as
/// `0195a7c2-3f10-7abc-8def-0123456789ab`. Its first 48 bits are Unix
/// milliseconds, so ids sort, as text, by the time they were made; journal
/// order is that order.
public struct EventID: Hashable, Comparable, Sendable, Codable, CustomStringConvertible {
    public let rawValue: String

    /// Returns nil unless the text has a UUIDv7's shape, version, and variant.
    public init?(_ text: String) {
        let bytes = Array(text.utf8)
        guard bytes.count == 36 else { return nil }
        for (index, byte) in bytes.enumerated() {
            switch index {
            case 8, 13, 18, 23: guard byte == UInt8(ascii: "-") else { return nil }
            case 14: guard byte == UInt8(ascii: "7") else { return nil }
            case 19: guard Self.variants.contains(byte) else { return nil }
            default: guard Self.digits.contains(byte) else { return nil }
            }
        }
        rawValue = text
    }

    /// An id from a millisecond count and ten random bytes, which the client
    /// supplies so the engine stays pure. Returns nil unless the count is
    /// from 0 up to, not including, 2^48 and there are ten bytes.
    public init?(milliseconds: Int, random: [UInt8]) {
        guard (0..<(1 << 48)).contains(milliseconds), random.count == 10 else { return nil }
        var bytes = (0..<6).map { UInt8(truncatingIfNeeded: milliseconds >> (8 * (5 - $0))) }
        bytes.append(0x70 | (random[0] & 0x0F))
        bytes.append(random[1])
        bytes.append(0x80 | (random[2] & 0x3F))
        bytes.append(contentsOf: random[3...])
        var text = ""
        for (index, byte) in bytes.enumerated() {
            if [4, 6, 8, 10].contains(index) { text.append("-") }
            text.append(Self.digit(byte >> 4))
            text.append(Self.digit(byte & 0x0F))
        }
        rawValue = text
    }

    /// The Unix milliseconds the id was made at: its first 48 bits.
    public var milliseconds: Int {
        var value = 0
        for byte in rawValue.utf8.prefix(13) where byte != UInt8(ascii: "-") {
            value =
                value << 4 | Int(byte < UInt8(ascii: "a") ? byte - UInt8(ascii: "0") : byte - UInt8(ascii: "a") + 10)
        }
        return value
    }

    public var description: String { rawValue }

    /// Text order, which for ids is the order of their bytes.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.utf8.lexicographicallyPrecedes(rhs.rawValue.utf8)
    }

    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let id = EventID(text) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "not a UUIDv7 id: \(text)"))
        }
        self = id
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    private static let digits = Set("0123456789abcdef".utf8)
    private static let variants = Set("89ab".utf8)

    private static func digit(_ value: UInt8) -> Character {
        Character(Unicode.Scalar(value < 10 ? UInt8(ascii: "0") + value : UInt8(ascii: "a") + value - 10))
    }
}
