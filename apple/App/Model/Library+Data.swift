import Foundation
import ReadingData
import ReadingEngine

/// The reader's data, theirs to take and to remove (docs/product.md,
/// "Privacy by design"; BUILD.md P8.13).
extension Library {
    /// Every event in the journal, as a JSON file the reader can keep: the
    /// same wire form the engine reads, so nothing is lost or reworded.
    func export() throws -> ReadingRecord {
        let events = (journal?.events ?? []).map(\.wire)
        let file = JSONValue.object([
            "format": .string("day-by-word-journal"),
            "version": .number(1),
            "exported": .string(Date.now.formatted(.iso8601)),
            "events": .array(events),
        ])
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return ReadingRecord(data: try encoder.encode(file))
    }
}

/// An exported reading record.
struct ReadingRecord {
    let data: Data

    /// Writes the record to a temporary file named for the reader, for the
    /// share sheet, and returns its address.
    func file() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "Day by Word reading record.json")
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }
}
