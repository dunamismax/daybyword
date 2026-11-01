/// A place in a book: a chapter and a verse.
public struct ChapterVerse: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let chapter: Int
    public let verse: Int

    public init(_ chapter: Int, _ verse: Int) {
        self.chapter = chapter
        self.verse = verse
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.chapter, lhs.verse) < (rhs.chapter, rhs.verse)
    }

    public var description: String { "\(chapter):\(verse)" }
}

/// A continuous run of verses inside one book, from a first verse to a last,
/// checked against a versification scheme when it is made. Whole chapters
/// are stored as their verses, so `GEN 1` and `GEN 1:1-31` are the same
/// passage, and whether a passage covers whole chapters is asked of it
/// (docs/decisions.md E30).
public struct Passage: Hashable, Sendable, CustomStringConvertible {
    public let scheme: Versification.Scheme
    public let book: BookID
    public let start: ChapterVerse
    public let end: ChapterVerse

    /// The verses from `start` to `end`, inclusive.
    public init(_ book: BookID, from start: ChapterVerse, to end: ChapterVerse, in versification: Versification)
        throws(PassageError)
    {
        guard versification.chapters(of: book) != nil else { throw .unknownBook(book) }
        for place in [start, end] {
            guard let verses = versification.verses(of: book, chapter: place.chapter) else {
                throw .noSuchChapter(book, place.chapter)
            }
            guard verses.contains(place.verse) else { throw .noSuchVerse(book, place) }
        }
        guard start <= end else { throw .endsBeforeItStarts(book, start, end) }
        self.scheme = versification.scheme
        self.book = book
        self.start = start
        self.end = end
    }

    /// Whole chapters, from the first verse of the first to the last verse of
    /// the last.
    public init(_ book: BookID, chapters: ClosedRange<Int>, in versification: Versification) throws(PassageError) {
        guard versification.chapters(of: book) != nil else { throw .unknownBook(book) }
        guard let first = versification.verses(of: book, chapter: chapters.lowerBound) else {
            throw .noSuchChapter(book, chapters.lowerBound)
        }
        guard let last = versification.verses(of: book, chapter: chapters.upperBound) else {
            throw .noSuchChapter(book, chapters.upperBound)
        }
        try self.init(
            book, from: ChapterVerse(chapters.lowerBound, first.lowerBound),
            to: ChapterVerse(chapters.upperBound, last.upperBound), in: versification)
    }

    /// One whole chapter.
    public init(_ book: BookID, chapter: Int, in versification: Versification) throws(PassageError) {
        try self.init(book, chapters: chapter...chapter, in: versification)
    }

    /// The chapters the passage touches, wholly or in part.
    public var chapters: ClosedRange<Int> { start.chapter...end.chapter }

    /// Whether the passage begins at the start of its first chapter and ends
    /// at the end of its last, so it can be shown as chapters alone.
    public func isWholeChapters(in versification: Versification) -> Bool {
        precondition(versification.scheme == scheme, "a passage is read under its own scheme")
        return versification.verses(of: book, chapter: start.chapter)?.lowerBound == start.verse
            && versification.verses(of: book, chapter: end.chapter)?.upperBound == end.verse
    }

    /// How many verses the passage holds.
    public func verseCount(in versification: Versification) -> Int {
        precondition(versification.scheme == scheme, "a passage is read under its own scheme")
        return chapters.reduce(0) { total, chapter in
            guard let verses = versification.verses(of: book, chapter: chapter) else { return total }
            let first = chapter == start.chapter ? start.verse : verses.lowerBound
            let last = chapter == end.chapter ? end.verse : verses.upperBound
            return total + (last - first + 1)
        }
    }

    /// For logs and test failures: `GEN 1:1-2:25`. Readers see the formatter's
    /// wording (P3.4).
    public var description: String {
        start.chapter == end.chapter
            ? "\(book) \(start)-\(end.verse)"
            : "\(book) \(start)-\(end)"
    }
}

/// What a reader is given to read at one sitting: one or more passages, in
/// the plan's order, all under one scheme. A reading may cross books
/// (`GEN 50; EXO 1`) and may repeat verses, which coverage counts once (P3.5).
public struct Reading: Hashable, Sendable, CustomStringConvertible {
    public let passages: [Passage]

    public init(_ passages: [Passage]) throws(PassageError) {
        guard let first = passages.first else { throw .emptyReading }
        guard passages.allSatisfy({ $0.scheme == first.scheme }) else { throw .mixedSchemes }
        self.passages = passages
    }

    public var scheme: Versification.Scheme { passages[0].scheme }

    /// How many verses the reading holds, counting a repeated verse each time
    /// it is given.
    public func verseCount(in versification: Versification) -> Int {
        passages.reduce(0) { $0 + $1.verseCount(in: versification) }
    }

    public var description: String { passages.map(\.description).joined(separator: "; ") }
}

public enum PassageError: Error, Equatable, CustomStringConvertible {
    case unknownBook(BookID)
    case noSuchChapter(BookID, Int)
    case noSuchVerse(BookID, ChapterVerse)
    case endsBeforeItStarts(BookID, ChapterVerse, ChapterVerse)
    case emptyReading
    case mixedSchemes

    public var description: String {
        switch self {
        case .unknownBook(let book): "\(book) is not numbered in this scheme"
        case .noSuchChapter(let book, let chapter): "\(book) has no chapter \(chapter)"
        case .noSuchVerse(let book, let place): "\(book) has no verse \(place)"
        case .endsBeforeItStarts(let book, let start, let end): "\(book) \(start)-\(end) ends before it starts"
        case .emptyReading: "a reading needs at least one passage"
        case .mixedSchemes: "a reading's passages must share one versification scheme"
        }
    }
}
