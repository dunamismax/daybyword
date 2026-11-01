/// The chapters and verses of each book under one versification scheme, read
/// from a file such as `catalog/scripture/versification/english.tsv`
/// (docs/decisions.md E28). A reference is only as good as the scheme it is
/// checked against: Psalm 51:21 exists in Hebrew numbering and not in
/// English, so every passage names its scheme.
public struct Versification: Sendable {
    /// The versification schemes Day by Word knows. Only English is loaded so
    /// far; Hebrew, Greek, and Latin are mapped from TVTMS in P3.2b.
    public enum Scheme: String, Sendable, Codable, CaseIterable {
        case english
    }

    public let scheme: Scheme
    /// The books the scheme numbers, in the file's order.
    public let books: [BookID]

    /// Reads a scheme's file: a line per book with its USFM id, its first
    /// chapter, and each chapter's verses as a count (`31`, verses 1 to 31) or
    /// a range (`4-13`). Lines starting with `#` are comments.
    public init(scheme: Scheme, tsv: String) throws {
        var books: [BookID] = []
        var entries: [BookID: Book] = [:]
        for (index, line) in tsv.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let number = index + 1
            if line.isEmpty || line.hasPrefix("#") { continue }
            let cells = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard cells.count == 3, let book = BookID(String(cells[0])), let first = Int(cells[1]), first >= 1 else {
                throw VersificationError.malformedLine(number)
            }
            guard entries[book] == nil else { throw VersificationError.duplicateBook(book) }
            let verses = try cells[2].split(separator: " ").map { field -> ClosedRange<Int> in
                let bounds = field.split(separator: "-", omittingEmptySubsequences: false).map { Int($0) }
                switch bounds.count {
                case 1: if let last = bounds[0], last >= 1 { return 1...last }
                case 2: if let start = bounds[0], let last = bounds[1], 1 < start, start <= last { return start...last }
                default: break
                }
                throw VersificationError.malformedLine(number)
            }
            guard !verses.isEmpty else { throw VersificationError.malformedLine(number) }
            books.append(book)
            entries[book] = Book(firstChapter: first, verses: verses)
        }
        self.scheme = scheme
        self.books = books
        self.entries = entries
    }

    /// The book's chapter numbers, or nil if the scheme does not number it.
    public func chapters(of book: BookID) -> ClosedRange<Int>? {
        entries[book].map { $0.firstChapter...($0.firstChapter + $0.verses.count - 1) }
    }

    /// The chapter's verse numbers, or nil if the scheme has no such chapter.
    public func verses(of book: BookID, chapter: Int) -> ClosedRange<Int>? {
        guard let entry = entries[book], let range = chapters(of: book), range.contains(chapter) else { return nil }
        return entry.verses[chapter - entry.firstChapter]
    }

    /// Whether the scheme has this verse.
    public func contains(_ book: BookID, chapter: Int, verse: Int) -> Bool {
        verses(of: book, chapter: chapter)?.contains(verse) ?? false
    }

    /// How many verses the scheme gives the book.
    public func verseCount(of book: BookID) -> Int {
        entries[book]?.verses.reduce(0) { $0 + $1.count } ?? 0
    }

    /// The verse's position in its book, counting from 0 at the book's first
    /// verse, or nil if the scheme does not have it. Positions run on across
    /// chapter ends, so Genesis 1:31 is 30 and Genesis 2:1 is 31.
    public func position(of place: ChapterVerse, in book: BookID) -> Int? {
        guard let entry = entries[book], let verses = verses(of: book, chapter: place.chapter),
            verses.contains(place.verse)
        else { return nil }
        return entry.starts[place.chapter - entry.firstChapter] + place.verse - verses.lowerBound
    }

    /// The verse at a position in its book, or nil past the book's end.
    public func place(at position: Int, in book: BookID) -> ChapterVerse? {
        guard let entry = entries[book], position >= 0,
            let index = entry.starts.lastIndex(where: { $0 <= position }),
            position - entry.starts[index] < entry.verses[index].count
        else { return nil }
        return ChapterVerse(entry.firstChapter + index, entry.verses[index].lowerBound + position - entry.starts[index])
    }

    private struct Book: Sendable {
        let firstChapter: Int
        let verses: [ClosedRange<Int>]
        /// The position of each chapter's first verse in the book.
        let starts: [Int]

        init(firstChapter: Int, verses: [ClosedRange<Int>]) {
            self.firstChapter = firstChapter
            self.verses = verses
            starts = Array(verses.reduce(into: [0]) { $0.append($0.last! + $1.count) }.dropLast())
        }
    }

    private let entries: [BookID: Book]
}

public enum VersificationError: Error, Equatable, CustomStringConvertible {
    case malformedLine(Int)
    case duplicateBook(BookID)
    case unregisteredBook(BookID)
    case missingBook(BookID, canon: String)

    public var description: String {
        switch self {
        case .malformedLine(let line): "line \(line) is not a book id, a first chapter, and its chapters' verses"
        case .duplicateBook(let book): "\(book) is numbered twice"
        case .unregisteredBook(let book): "\(book) is not in the book registry"
        case .missingBook(let book, let canon): "\(book), a book of the \(canon) canon, is not numbered"
        }
    }
}

extension Versification {
    /// Throws unless every book the scheme numbers is registered, and every
    /// book a canon lists is numbered. Material a canon includes inside
    /// another book, such as the Letter of Jeremiah inside Baruch, may be
    /// numbered as part of that book instead.
    public func check(against registry: BookRegistry) throws {
        for book in books where registry.book(book) == nil {
            throw VersificationError.unregisteredBook(book)
        }
        for canon in registry.canons {
            for book in canon.books where chapters(of: book) == nil {
                throw VersificationError.missingBook(book, canon: canon.id)
            }
        }
    }
}
