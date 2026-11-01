/// The one strict way plan files write a reading (docs/decisions.md E30):
/// passages joined by `; `, each a USFM book id, a space, and one of
///
/// - `GEN 1`, a whole chapter, or `GEN 1-2`, whole chapters;
/// - `JHN 3:16`, one verse;
/// - `JHN 3:1-21`, verses in one chapter;
/// - `JHN 3:16-4:3`, verses across chapters.
///
/// Numbers have no leading zeros, there are no other spaces, and the hyphen
/// is ASCII. A range is never written longer than it needs to be: `GEN 2-2`
/// is `GEN 2`, and `JHN 3:1-3:21` is `JHN 3:1-21`. Every passage is checked
/// against the versification as it is read.
public enum ReferenceFormat {
    public static func reading(_ text: String, in versification: Versification) throws(ReferenceFormatError) -> Reading
    {
        guard !text.isEmpty else { throw .empty }
        let passages = try text.split(separator: "; ", omittingEmptySubsequences: false).map {
            (part) throws(ReferenceFormatError) in try passage(String(part), in: versification)
        }
        do {
            return try Reading(passages)
        } catch {
            throw .passage(error)
        }
    }

    public static func passage(_ text: String, in versification: Versification) throws(ReferenceFormatError) -> Passage
    {
        guard !text.isEmpty else { throw .empty }
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        guard words.count == 2 else { throw .malformed(text) }
        guard let book = BookID(String(words[0])) else { throw .notABook(String(words[0])) }
        let written = words[1].split(separator: "-", omittingEmptySubsequences: false)
        let sides = written.compactMap(Place.init)
        guard (1...2).contains(written.count), sides.count == written.count else { throw .malformed(text) }
        func shorter(_ range: String) -> ReferenceFormatError { .redundant(text, shouldBe: "\(book) \(range)") }

        // The first and last chapters of whole chapters, or the first and last
        // verses of a run of verses.
        let chapters: (first: Int, last: Int)?
        let verses: (first: ChapterVerse, last: ChapterVerse)?
        switch (sides[0], sides.count == 2 ? sides[1] : nil) {
        case (.chapter(let chapter), nil):
            (chapters, verses) = ((chapter, chapter), nil)
        case (.verse(let chapter, let verse), nil):
            (chapters, verses) = (nil, (ChapterVerse(chapter, verse), ChapterVerse(chapter, verse)))
        case (.chapter(let first), .chapter(let last)):
            if first == last { throw shorter("\(first)") }
            (chapters, verses) = ((first, last), nil)
        case (.verse(let chapter, let first), .chapter(let last)):
            if first == last { throw shorter("\(chapter):\(first)") }
            (chapters, verses) = (nil, (ChapterVerse(chapter, first), ChapterVerse(chapter, last)))
        case (.verse(let chapter, let first), .verse(let endChapter, let last)):
            if chapter == endChapter {
                throw shorter(first == last ? "\(chapter):\(first)" : "\(chapter):\(first)-\(last)")
            }
            (chapters, verses) = (nil, (ChapterVerse(chapter, first), ChapterVerse(endChapter, last)))
        case (.chapter, .verse):
            throw .malformed(text)
        }

        do throws(PassageError) {
            if let (first, last) = chapters {
                guard first <= last else {
                    throw .endsBeforeItStarts(book, ChapterVerse(first, 1), ChapterVerse(last, 1))
                }
                return try Passage(book, chapters: first...last, in: versification)
            }
            let (first, last) = verses!
            return try Passage(book, from: first, to: last, in: versification)
        } catch {
            throw .passage(error)
        }
    }

    /// The shortest plan-file writing of a reading, which reads back as the
    /// same reading: whole chapters are written as chapters.
    public static func text(of reading: Reading, in versification: Versification) -> String {
        reading.passages.map { text(of: $0, in: versification) }.joined(separator: "; ")
    }

    public static func text(of passage: Passage, in versification: Versification) -> String {
        let (start, end) = (passage.start, passage.end)
        let range: String =
            if passage.isWholeChapters(in: versification) {
                start.chapter == end.chapter ? "\(start.chapter)" : "\(start.chapter)-\(end.chapter)"
            } else if start == end {
                "\(start)"
            } else if start.chapter == end.chapter {
                "\(start)-\(end.verse)"
            } else {
                "\(start)-\(end)"
            }
        return "\(passage.book) \(range)"
    }

    /// One side of a range: a chapter, or a chapter and verse. After the
    /// hyphen in `JHN 3:1-21`, a lone number is the last verse.
    private enum Place {
        case chapter(Int)
        case verse(Int, Int)

        init?(_ text: Substring) {
            let numbers = text.split(separator: ":", omittingEmptySubsequences: false).map(Place.number)
            switch (numbers.count, numbers.first ?? nil, numbers.last ?? nil) {
            case (1, let chapter?, _): self = .chapter(chapter)
            case (2, let chapter?, let verse?): self = .verse(chapter, verse)
            default: return nil
            }
        }

        /// A chapter or verse number: one to three digits, the first not zero.
        private static func number(_ text: Substring) -> Int? {
            let bytes = Array(text.utf8)
            guard (1...3).contains(bytes.count), bytes[0] != UInt8(ascii: "0"),
                bytes.allSatisfy({ (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) })
            else { return nil }
            return Int(text)
        }
    }
}

public enum ReferenceFormatError: Error, Equatable, CustomStringConvertible {
    /// Nothing, or nothing between two separators.
    case empty
    /// The passage is not written in the plan-file format.
    case malformed(String)
    /// The passage does not start with a USFM book id.
    case notABook(String)
    /// The range is written longer than it needs to be.
    case redundant(String, shouldBe: String)
    /// The passage is well formed, but the scheme does not have it.
    case passage(PassageError)

    public var description: String {
        switch self {
        case .empty: "a reading is missing, or has an empty passage between \"; \" separators"
        case .malformed(let text):
            "\"\(text)\" is not written as BOOK 1, BOOK 1-2, BOOK 1:2, BOOK 1:2-3, or BOOK 1:2-3:4"
        case .notABook(let text): "\"\(text)\" is not a USFM book id"
        case .redundant(let text, let shorter): "\"\(text)\" should be written \"\(shorter)\""
        case .passage(let error): error.description
        }
    }
}
