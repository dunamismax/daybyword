import ReadingEngine
import Testing

// MARK: Reading plan files

@Test(
    arguments: [
        // Plan-file text, the passages it reads as (book, first, last verse).
        ("GEN 1", [("GEN", (1, 1), (1, 31))]),
        ("GEN 1-2", [("GEN", (1, 1), (2, 25))]),
        ("JHN 3:16", [("JHN", (3, 16), (3, 16))]),
        ("JHN 3:1-21", [("JHN", (3, 1), (3, 21))]),
        ("JHN 3:16-4:3", [("JHN", (3, 16), (4, 3))]),
        ("PSA 119:1-24; PSA 120", [("PSA", (119, 1), (119, 24)), ("PSA", (120, 1), (120, 7))]),
        ("GEN 50; EXO 1", [("GEN", (50, 1), (50, 26)), ("EXO", (1, 1), (1, 22))]),
        ("ESG 10", [("ESG", (10, 4), (10, 13))]),
        ("JUD 1", [("JUD", (1, 1), (1, 25))]),
        ("PSA 117; PSA 117", [("PSA", (117, 1), (117, 2)), ("PSA", (117, 1), (117, 2))]),
    ] as [(String, [(String, (Int, Int), (Int, Int))])])
func readsThePlanFileFormat(text: String, passages: [(String, (Int, Int), (Int, Int))]) throws {
    let english = try loadEnglish()
    let reading = try ReferenceFormat.reading(text, in: english)
    #expect(reading == (try Reading(passages.map { try passage($0.0, $0.1, $0.2) })))
}

@Test(
    arguments: [
        // Nothing to read.
        ("", ReferenceFormatError.empty),
        ("GEN 1; ", .empty),
        ("GEN 1; ; GEN 2", .empty),
        // Not a book id.
        ("gen 1", .notABook("gen")),
        ("Gen 1", .notABook("Gen")),
        ("Genesis 1", .notABook("Genesis")),
        ("1 Samuel 3", .malformed("1 Samuel 3")),
        // Missing or extra parts and spaces.
        ("GEN", .malformed("GEN")),
        ("GEN ", .malformed("GEN ")),
        (" GEN 1", .malformed(" GEN 1")),
        ("GEN 1 ", .malformed("GEN 1 ")),
        ("GEN  1", .malformed("GEN  1")),
        ("GEN 1 - 2", .malformed("GEN 1 - 2")),
        ("GEN 1:1 -3", .malformed("GEN 1:1 -3")),
        ("GEN\t1", .malformed("GEN\t1")),
        // Separators other than "; ".
        ("GEN 1;GEN 2", .malformed("GEN 1;GEN 2")),
        ("GEN 1,2", .malformed("GEN 1,2")),
        ("GEN 1;  GEN 2", .malformed(" GEN 2")),
        // Numbers.
        ("GEN x", .malformed("GEN x")),
        ("GEN 01", .malformed("GEN 01")),
        ("GEN 1:05", .malformed("GEN 1:05")),
        ("GEN 0", .malformed("GEN 0")),
        ("GEN 1:0", .malformed("GEN 1:0")),
        ("GEN -1", .malformed("GEN -1")),
        ("GEN 1000", .malformed("GEN 1000")),
        ("GEN 1.5", .malformed("GEN 1.5")),
        ("GEN 1a", .malformed("GEN 1a")),
        // Ranges.
        ("GEN 1\u{2013}2", .malformed("GEN 1\u{2013}2")),
        ("GEN 1-", .malformed("GEN 1-")),
        ("GEN -", .malformed("GEN -")),
        ("GEN 1:", .malformed("GEN 1:")),
        ("GEN 1:2-", .malformed("GEN 1:2-")),
        ("GEN 1:2:3", .malformed("GEN 1:2:3")),
        ("GEN 1-2-3", .malformed("GEN 1-2-3")),
        ("GEN 1-2:3", .malformed("GEN 1-2:3")),
        ("GEN 50-EXO 1", .malformed("GEN 50-EXO 1")),
        // Written longer than needed.
        ("GEN 2-2", .redundant("GEN 2-2", shouldBe: "GEN 2")),
        ("GEN 1:5-5", .redundant("GEN 1:5-5", shouldBe: "GEN 1:5")),
        ("JHN 3:1-3:21", .redundant("JHN 3:1-3:21", shouldBe: "JHN 3:1-21")),
        ("JHN 3:16-3:16", .redundant("JHN 3:16-3:16", shouldBe: "JHN 3:16")),
        // Well formed, but not in the English scheme.
        ("LJE 1", .passage(.unknownBook(book("LJE")))),
        ("XYZ 1", .passage(.unknownBook(book("XYZ")))),
        ("GEN 51", .passage(.noSuchChapter(book("GEN"), 51))),
        ("GEN 50-51", .passage(.noSuchChapter(book("GEN"), 51))),
        ("GEN 1:32", .passage(.noSuchVerse(book("GEN"), ChapterVerse(1, 32)))),
        ("PSA 51:21", .passage(.noSuchVerse(book("PSA"), ChapterVerse(51, 21)))),
        ("ESG 10:1-3", .passage(.noSuchVerse(book("ESG"), ChapterVerse(10, 1)))),
        ("GEN 3-2", .passage(.endsBeforeItStarts(book("GEN"), ChapterVerse(3, 1), ChapterVerse(2, 1)))),
        ("GEN 1:9-5", .passage(.endsBeforeItStarts(book("GEN"), ChapterVerse(1, 9), ChapterVerse(1, 5)))),
        ("GEN 2:1-1:5", .passage(.endsBeforeItStarts(book("GEN"), ChapterVerse(2, 1), ChapterVerse(1, 5)))),
        // The first problem in a reading is the one reported.
        ("GEN 1; GEN 51; gen 2", .passage(.noSuchChapter(book("GEN"), 51))),
    ] as [(String, ReferenceFormatError)])
func refusesEveryOtherWriting(text: String, error: ReferenceFormatError) throws {
    let english = try loadEnglish()
    #expect(throws: error) { try ReferenceFormat.reading(text, in: english) }
}

@Test(
    arguments: [
        // Written, then its shortest writing.
        ("GEN 1:1-31", "GEN 1"),
        ("GEN 1:1-2:25", "GEN 1-2"),
        ("GEN 1:1-2:3", "GEN 1:1-2:3"),
        ("ESG 10:4-13", "ESG 10"),
        ("JHN 3:16", "JHN 3:16"),
        ("JHN 3:1-21", "JHN 3:1-21"),
        ("PSA 119:1-24; PSA 120:1-7", "PSA 119:1-24; PSA 120"),
    ])
func writesReadingsAsBrieflyAsTheFormatAllows(text: String, shortest: String) throws {
    let english = try loadEnglish()
    let reading = try ReferenceFormat.reading(text, in: english)
    #expect(ReferenceFormat.text(of: reading, in: english) == shortest)
    #expect(try ReferenceFormat.reading(shortest, in: english) == reading)
}

// MARK: Showing readings to the reader

@Test(
    arguments: [
        // Plan-file text, full, abbreviated.
        ("JHN 3:1-21", "John 3:1–21", "John 3:1–21"),
        ("JHN 3:16", "John 3:16", "John 3:16"),
        ("JHN 3:16-4:3", "John 3:16–4:3", "John 3:16–4:3"),
        ("GEN 1", "Genesis 1", "Gen 1"),
        ("GEN 1-2", "Genesis 1–2", "Gen 1–2"),
        ("GEN 1:1-2:3", "Genesis 1:1–2:3", "Gen 1:1–2:3"),
        ("GEN 50; EXO 1", "Genesis 50; Exodus 1", "Gen 50; Exod 1"),
        ("1SA 3", "1 Samuel 3", "1 Sam 3"),
        // A single psalm is "Psalm"; more than one is "Psalms".
        ("PSA 23", "Psalm 23", "Ps 23"),
        ("PSA 119:1-24; PSA 120", "Psalm 119:1–24; Psalm 120", "Ps 119:1–24; Ps 120"),
        ("PSA 120-122", "Psalms 120–122", "Ps 120–122"),
        ("PSA 119:169-120:7", "Psalms 119:169–120:7", "Ps 119:169–120:7"),
        // One-chapter books are cited by their verses.
        ("JUD 1", "Jude", "Jude"),
        ("JUD 1:3-5", "Jude 3–5", "Jude 3–5"),
        ("OBA 1:21", "Obadiah 21", "Obad 21"),
        ("PHM 1", "Philemon", "Phlm"),
        // The Rest of Esther starts at 10:4, so 10:4-13 is its whole chapter.
        ("ESG 10", "Additions to Esther 10", "Add Esth 10"),
    ])
func showsReadingsInCommonEnglish(text: String, full: String, abbreviated: String) throws {
    let english = try loadEnglish()
    let formatter = try ReferenceFormatter(registry: loadRegistry(), versification: english)
    let reading = try ReferenceFormat.reading(text, in: english)
    #expect(formatter.string(for: reading) == full)
    #expect(formatter.string(for: reading, style: .abbreviated) == abbreviated)
}

@Test(
    arguments: [
        // Plan-file text, convention, full, abbreviated.
        ("SNG 2", NamingConvention.kjv, "Song of Solomon 2", "Song 2"),
        ("SNG 2", .douay, "Canticle of Canticles 2", "Cant 2"),
        ("1SA 3", .douay, "1 Kings 3", "1 Kings 3"),
        ("REV 21:1-4", .douay, "Apocalypse 21:1–4", "Apocalypse 21:1–4"),
        ("OBA 1", .douay, "Abdias", "Abdias"),
        ("PSA 23", .douay, "Psalm 23", "Ps 23"),
    ])
func showsReadingsUnderTheReadersConvention(
    text: String, convention: NamingConvention, full: String, abbreviated: String
) throws {
    let english = try loadEnglish()
    let formatter = try ReferenceFormatter(registry: loadRegistry(), versification: english, convention: convention)
    let reading = try ReferenceFormat.reading(text, in: english)
    #expect(formatter.string(for: reading) == full)
    #expect(formatter.string(for: reading, style: .abbreviated) == abbreviated)
}
