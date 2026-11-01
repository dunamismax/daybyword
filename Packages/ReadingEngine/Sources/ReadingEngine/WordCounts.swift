/// The words in each verse of the books a counting text covers, numbered by a
/// versification scheme and read from a file such as
/// `catalog/scripture/words/web.tsv` (docs/decisions.md E31). They are numbers
/// only, used for workload estimates; Day by Word keeps no Bible text (D13).
public struct WordCounts: Sendable {
    public let scheme: Versification.Scheme
    /// The books counted, in the file's order.
    public let books: [BookID]

    /// Reads a file of a line per chapter: the book's USFM id, the chapter,
    /// and each verse's words in order. Every chapter of a counted book must be
    /// there, with a count for each of its verses under the scheme. Lines
    /// starting with `#` are comments.
    public init(tsv: String, versification: Versification) throws(WordCountsError) {
        var books: [BookID] = []
        var chapters: [BookID: [Int: [Int]]] = [:]
        for (index, line) in tsv.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let number = index + 1
            if line.isEmpty || line.hasPrefix("#") { continue }
            let cells = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard cells.count == 3, let book = BookID(String(cells[0])), let chapter = Int(cells[1]) else {
                throw .malformedLine(number)
            }
            let words = cells[2].split(separator: " ", omittingEmptySubsequences: false).map { Int($0) }
            guard !words.isEmpty, words.allSatisfy({ ($0 ?? -1) >= 0 }) else { throw .malformedLine(number) }
            guard let verses = versification.verses(of: book, chapter: chapter) else {
                throw .noSuchChapter(book, chapter)
            }
            guard words.count == verses.count else {
                throw .wrongVerseCount(book, chapter, expected: verses.count, found: words.count)
            }
            if chapters[book] == nil { books.append(book) }
            guard chapters[book]?[chapter] == nil else { throw .duplicateChapter(book, chapter) }
            chapters[book, default: [:]][chapter] = words.map { $0! }
        }
        var totals: [BookID: [Int]] = [:]
        for book in books {
            var running = [0]
            for chapter in versification.chapters(of: book)! {
                guard let words = chapters[book]?[chapter] else { throw .missingChapter(book, chapter) }
                for count in words { running.append(running.last! + count) }
            }
            totals[book] = running
        }
        self.scheme = versification.scheme
        self.books = books
        self.runningTotals = totals
        self.versification = versification
    }

    /// The words in a passage, or nil if its book is not counted.
    public func words(in passage: Passage) -> Int? {
        precondition(passage.scheme == scheme, "a passage is counted under its own scheme")
        guard let totals = runningTotals[passage.book] else { return nil }
        // A passage is checked against its scheme when it is made, so both ends
        // have positions.
        let first = versification.position(of: passage.start, in: passage.book)!
        let last = versification.position(of: passage.end, in: passage.book)!
        return totals[last + 1] - totals[first]
    }

    /// The words in a reading, counting a repeated passage each time it is
    /// given, or nil if any of its books is not counted.
    public func words(in reading: Reading) -> Int? {
        var total = 0
        for passage in reading.passages {
            guard let words = words(in: passage) else { return nil }
            total += words
        }
        return total
    }

    /// The words in a book, or nil if it is not counted.
    public func words(of book: BookID) -> Int? { runningTotals[book]?.last }

    /// For each counted book, the words before each verse position, with the
    /// book's total last, so a passage's words are one subtraction.
    private let runningTotals: [BookID: [Int]]
    private let versification: Versification
}

public enum WordCountsError: Error, Equatable, CustomStringConvertible {
    case malformedLine(Int)
    case noSuchChapter(BookID, Int)
    case wrongVerseCount(BookID, Int, expected: Int, found: Int)
    case duplicateChapter(BookID, Int)
    case missingChapter(BookID, Int)

    public var description: String {
        switch self {
        case .malformedLine(let line): "line \(line) is not a book id, a chapter, and its verses' word counts"
        case .noSuchChapter(let book, let chapter): "\(book) \(chapter) is not a chapter of the scheme"
        case .wrongVerseCount(let book, let chapter, let expected, let found):
            "\(book) \(chapter) has \(expected) verses in the scheme but \(found) counts"
        case .duplicateChapter(let book, let chapter): "\(book) \(chapter) is counted twice"
        case .missingChapter(let book, let chapter): "\(book) \(chapter) is not counted"
        }
    }
}
