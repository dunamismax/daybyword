/// A translation on Bible.com, by the number its addresses use
/// (docs/destinations.md, "Translations"). The reader chooses one; there is
/// no default.
public struct BibleTranslation: Hashable, Sendable, Identifiable {
    /// Bible.com's version number, which decides the translation.
    public let id: Int
    public let abbreviation: String
    public let name: String

    /// The translations Day by Word links to, in alphabetical order of name,
    /// each checked on Bible.com (docs/destinations.md).
    public static let all: [BibleTranslation] = [
        .init(id: 12, abbreviation: "ASV", name: "American Standard Version"),
        .init(id: 1588, abbreviation: "AMP", name: "Amplified Bible"),
        .init(id: 3034, abbreviation: "BSB", name: "Berean Standard Bible"),
        .init(id: 1713, abbreviation: "CSB", name: "Christian Standard Bible"),
        .init(id: 37, abbreviation: "CEB", name: "Common English Bible"),
        .init(id: 392, abbreviation: "CEV", name: "Contemporary English Version"),
        .init(id: 55, abbreviation: "DRC1752", name: "Douay-Rheims Challoner Revision 1752"),
        .init(id: 59, abbreviation: "ESV", name: "English Standard Version 2025"),
        .init(id: 68, abbreviation: "GNT", name: "Good News Translation"),
        .init(id: 1, abbreviation: "KJV", name: "King James Version"),
        .init(id: 3345, abbreviation: "LSB", name: "Legacy Standard Bible"),
        .init(id: 463, abbreviation: "NABRE", name: "New American Bible, revised edition"),
        .init(id: 100, abbreviation: "NASB1995", name: "New American Standard Bible (1995)"),
        .init(id: 2692, abbreviation: "NASB2020", name: "New American Standard Bible (2020)"),
        .init(id: 107, abbreviation: "NET", name: "New English Translation"),
        .init(id: 111, abbreviation: "NIV", name: "New International Version"),
        .init(id: 114, abbreviation: "NKJV", name: "New King James Version"),
        .init(id: 116, abbreviation: "NLT", name: "New Living Translation"),
        .init(id: 3523, abbreviation: "NRSVUE", name: "New Revised Standard Version, Updated Edition"),
        .init(id: 2020, abbreviation: "RSV", name: "Revised Standard Version"),
        .init(id: 97, abbreviation: "MSG", name: "The Message"),
        .init(id: 206, abbreviation: "WEBUS", name: "World English Bible, American English Edition"),
    ]

    /// The translation with Bible.com's number `id`, if Day by Word links to it.
    public static func withID(_ id: Int) -> BibleTranslation? { all.first { $0.id == id } }

    private init(id: Int, abbreviation: String, name: String) {
        self.id = id
        self.abbreviation = abbreviation
        self.name = name
    }
}

/// Where a reading opens in YouVersion and on Bible.com (D26,
/// docs/destinations.md): one Bible.com address, which opens the YouVersion
/// app where it is installed and the website otherwise. Opening it is never
/// a reading; the reader marks what they read.
public struct BibleLink: Hashable, Sendable {
    /// The Bible.com address.
    public let address: String
    /// Whether the address holds the whole reading. When it does not, it
    /// opens at `book` and `chapter`, where the reading begins.
    public let isWholeReading: Bool
    public let book: BookID
    public let chapter: Int

    /// The link for `reading` in `translation`: its verses when they lie in
    /// one chapter, and otherwise its first chapter, since Bible.com has no
    /// address for a range across chapters or books.
    public init(_ reading: Reading, translation: BibleTranslation, in versification: Versification) {
        let first = reading.passages[0]
        book = first.book
        chapter = first.start.chapter
        let suffix = ".\(translation.abbreviation)"
        let base = "https://www.bible.com/bible/\(translation.id)/\(first.book.rawValue).\(first.start.chapter)"

        // Every passage in the first one's chapter, in order, none overlapping.
        let inOneChapter = reading.passages.allSatisfy {
            $0.book == first.book && $0.start.chapter == first.start.chapter && $0.end.chapter == first.start.chapter
        }
        let inOrder = zip(reading.passages, reading.passages.dropFirst()).allSatisfy { $0.end.verse < $1.start.verse }
        guard inOneChapter, inOrder else {
            address = base + suffix
            isWholeReading = false
            return
        }
        isWholeReading = true
        if reading.passages.count == 1, first.isWholeChapters(in: versification) {
            address = base + suffix
        } else {
            let verses = reading.passages.map {
                $0.start.verse == $0.end.verse ? "\($0.start.verse)" : "\($0.start.verse)-\($0.end.verse)"
            }
            address = base + "." + verses.joined(separator: ",") + suffix
        }
    }
}
