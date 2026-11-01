import ReadingEngine
import Testing

func passage(_ id: String, _ start: (Int, Int), _ end: (Int, Int)) throws -> Passage {
    try Passage(book(id), from: ChapterVerse(start.0, start.1), to: ChapterVerse(end.0, end.1), in: loadEnglish())
}

@Test func wholeChaptersAreTheirVerses() throws {
    let english = try loadEnglish()
    let genesis1 = try Passage(book("GEN"), chapter: 1, in: english)
    #expect(genesis1 == (try passage("GEN", (1, 1), (1, 31))))
    #expect(genesis1.isWholeChapters(in: english))
    #expect(genesis1.verseCount(in: english) == 31)

    let genesis1to2 = try Passage(book("GEN"), chapters: 1...2, in: english)
    #expect(genesis1to2 == (try passage("GEN", (1, 1), (2, 25))))
    #expect(genesis1to2.chapters == 1...2)
    #expect(genesis1to2.verseCount(in: english) == 56)
    #expect(genesis1to2.description == "GEN 1:1-2:25")
}

@Test(
    arguments: [
        // Start, end, whole chapters, verses.
        ((3, 1), (3, 21), false, 21),  // John 3:1-21
        ((3, 1), (3, 36), true, 36),  // John 3
        ((3, 16), (4, 54), false, 75),  // across a chapter end
        ((1, 1), (21, 25), true, 879),  // the whole book
        ((7, 53), (7, 53), false, 1),  // a single verse
    ] as [((Int, Int), (Int, Int), Bool, Int)])
func passagesCountTheirVerses(start: (Int, Int), end: (Int, Int), whole: Bool, verses: Int) throws {
    let english = try loadEnglish()
    let john = try passage("JHN", start, end)
    #expect(john.isWholeChapters(in: english) == whole)
    #expect(john.verseCount(in: english) == verses)
}

/// The King James Rest of Esther begins at 10:4, so its tenth chapter, whole,
/// is 10:4-13 (docs/decisions.md E28).
@Test func aChapterThatDoesNotStartAtVerseOneIsWholeFromItsFirstVerse() throws {
    let english = try loadEnglish()
    let rest = try Passage(book("ESG"), chapter: 10, in: english)
    #expect(rest.start == ChapterVerse(10, 4))
    #expect(rest.isWholeChapters(in: english))
    #expect(rest.verseCount(in: english) == 10)
    #expect(throws: PassageError.noSuchVerse(book("ESG"), ChapterVerse(10, 1))) {
        try passage("ESG", (10, 1), (10, 13))
    }
}

@Test(
    arguments: [
        ("LJE", (1, 1), (1, 1), PassageError.unknownBook(book("LJE"))),
        ("GEN", (51, 1), (51, 2), .noSuchChapter(book("GEN"), 51)),
        ("GEN", (50, 1), (51, 1), .noSuchChapter(book("GEN"), 51)),
        ("GEN", (0, 1), (1, 1), .noSuchChapter(book("GEN"), 0)),
        ("GEN", (1, 0), (1, 1), .noSuchVerse(book("GEN"), ChapterVerse(1, 0))),
        ("GEN", (1, 1), (1, 32), .noSuchVerse(book("GEN"), ChapterVerse(1, 32))),
        ("PSA", (51, 21), (51, 21), .noSuchVerse(book("PSA"), ChapterVerse(51, 21))),
        ("GEN", (2, 1), (1, 31), .endsBeforeItStarts(book("GEN"), ChapterVerse(2, 1), ChapterVerse(1, 31))),
        ("GEN", (1, 5), (1, 4), .endsBeforeItStarts(book("GEN"), ChapterVerse(1, 5), ChapterVerse(1, 4))),
    ] as [(String, (Int, Int), (Int, Int), PassageError)])
func refusesPassagesTheSchemeDoesNotHave(id: String, start: (Int, Int), end: (Int, Int), error: PassageError) {
    #expect(throws: error) { try passage(id, start, end) }
}

@Test func refusesChaptersTheSchemeDoesNotHave() throws {
    let english = try loadEnglish()
    #expect(throws: PassageError.noSuchChapter(book("OBA"), 2)) {
        try Passage(book("OBA"), chapters: 1...2, in: english)
    }
    #expect(throws: PassageError.unknownBook(book("LJE"))) { try Passage(book("LJE"), chapter: 1, in: english) }
}

@Test func aReadingKeepsItsPassagesInOrder() throws {
    let english = try loadEnglish()
    let reading = try Reading([
        passage("PSA", (119, 1), (119, 24)), Passage(book("PSA"), chapter: 120, in: english),
        Passage(book("GEN"), chapter: 50, in: english), Passage(book("EXO"), chapter: 1, in: english),
    ])
    #expect(reading.passages.map(\.book) == [book("PSA"), book("PSA"), book("GEN"), book("EXO")])
    #expect(reading.verseCount(in: english) == 24 + 7 + 26 + 22)
    #expect(reading.description == "PSA 119:1-24; PSA 120:1-7; GEN 50:1-26; EXO 1:1-22")
    #expect(throws: PassageError.emptyReading) { try Reading([]) }
}

@Test func aReadingCountsARepeatedVerseEachTime() throws {
    let english = try loadEnglish()
    let psalm = try Passage(book("PSA"), chapter: 117, in: english)
    #expect(try Reading([psalm, psalm]).verseCount(in: english) == 4)
}
