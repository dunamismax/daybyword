/// A book of the Bible, by its USFM 3.0 identifier: three characters, capital
/// ASCII letters and digits, such as `GEN`, `1SA`, or `S3Y`. Every book the
/// catalog names is registered in `catalog/scripture/books.json`
/// (docs/decisions.md E27).
public struct BookID: Hashable, Sendable, Codable, CustomStringConvertible, CodingKeyRepresentable {
    public let rawValue: String

    /// Returns nil for text that is not shaped like a USFM book id. Whether
    /// the book is registered is a question for `BookRegistry`.
    public init?(_ text: String) {
        let bytes = Array(text.utf8)
        guard bytes.count == 3, bytes.allSatisfy({ Self.letters.contains($0) || Self.digits.contains($0) }),
            bytes.contains(where: Self.letters.contains)
        else { return nil }
        rawValue = text
    }

    public var description: String { rawValue }

    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let id = BookID(text) else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "not a book id: \(text)"))
        }
        self = id
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var codingKey: any CodingKey { Key(stringValue: rawValue) }

    public init?<T: CodingKey>(codingKey: T) {
        self.init(codingKey.stringValue)
    }

    private static let letters = UInt8(ascii: "A")...UInt8(ascii: "Z")
    private static let digits = UInt8(ascii: "0")...UInt8(ascii: "9")

    private struct Key: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }
}
