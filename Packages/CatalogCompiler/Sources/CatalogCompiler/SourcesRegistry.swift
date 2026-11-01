/// The entries of `catalog/SOURCES.md` and their statuses, read as its
/// schema says: an entry's id from its `## id: title` heading, and its status
/// from the first word in backticks on its Status line.
public struct SourcesRegistry: Sendable {
    public enum Status: String, Sendable, CaseIterable {
        case cleared
        case pending
        case rejected
        case reference
    }

    public let statuses: [String: Status]

    public init(markdown: String) throws(SourcesError) {
        var statuses: [String: Status] = [:]
        var current: (id: String, line: Int)?
        func finish() throws(SourcesError) {
            if let current, statuses[current.id] == nil {
                throw SourcesError(line: current.line, problem: "has no status")
            }
        }
        for (index, line) in markdown.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let number = index + 1
            if line.hasPrefix("## ") {
                guard let colon = line.firstIndex(of: ":"), Self.isID(String(line.dropFirst(3)[..<colon])) else {
                    if current == nil, line == "## The schema" { continue }
                    throw SourcesError(line: number, problem: "an entry's heading is \"## id: title\"")
                }
                try finish()
                let id = String(line.dropFirst(3)[..<colon])
                guard !statuses.keys.contains(id), current?.id != id else {
                    throw SourcesError(line: number, problem: "\(id) has two entries")
                }
                current = (id, number)
            } else if let entry = current, line.hasPrefix("- **Status:** ") {
                let words = line.split(separator: "`", omittingEmptySubsequences: false)
                guard words.count >= 3, let status = Status(rawValue: String(words[1])) else {
                    throw SourcesError(
                        line: number,
                        problem:
                            "a status is one of \(Status.allCases.map { "`\($0.rawValue)`" }.joined(separator: ", "))")
                }
                statuses[entry.id] = status
            }
        }
        try finish()
        self.statuses = statuses
    }

    /// Whether the text is shaped like an entry's id: lowercase ASCII letters,
    /// digits, and single hyphens between them.
    public static func isID(_ text: String) -> Bool {
        let bytes = Array(text.utf8)
        guard !bytes.isEmpty, bytes.first != hyphen, bytes.last != hyphen else { return false }
        return bytes.indices.allSatisfy { index in
            switch bytes[index] {
            case UInt8(ascii: "a")...UInt8(ascii: "z"), UInt8(ascii: "0")...UInt8(ascii: "9"): true
            case hyphen: bytes[index - 1] != hyphen
            default: false
            }
        }
    }

    private static let hyphen = UInt8(ascii: "-")
}

public struct SourcesError: Error, Equatable, CustomStringConvertible {
    public let line: Int
    public let problem: String

    public var description: String { "line \(line): \(problem)" }
}
