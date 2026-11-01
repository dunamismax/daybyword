import Foundation
import ReadingEngine
import Testing

/// The English scheme the catalog is compiled with, read from the repository.
func loadEnglish() throws -> Versification {
    let url = registryURL.deletingLastPathComponent().appending(path: "versification/english.tsv")
    return try Versification(scheme: .english, tsv: String(contentsOf: url, encoding: .utf8))
}

@Test func theEnglishSchemeMatchesTheRegistry() throws {
    try loadEnglish().check(against: loadRegistry())
}

/// The KJV's well-known totals for the 66 books: 1,189 chapters and 31,102
/// verses (counted by scripts/versification.swift, BUILD.md P3.2a).
@Test func theProtestantCanonHas1189ChaptersAnd31102Verses() throws {
    let english = try loadEnglish()
    let books = try #require(try loadRegistry().canon("protestant")).books
    #expect(books.reduce(0) { $0 + (english.chapters(of: $1)?.count ?? 0) } == 1189)
    #expect(books.reduce(0) { $0 + english.verseCount(of: $1) } == 31102)
}

@Test(
    arguments: [
        // Book, chapter, its verses (nil: no such chapter).
        ("GEN", 1, 1...31), ("GEN", 50, 1...26), ("GEN", 51, nil),
        ("PSA", 119, 1...176), ("PSA", 117, 1...2), ("PSA", 150, 1...6), ("PSA", 151, nil),
        ("OBA", 1, 1...21), ("MAL", 4, 1...6), ("MAL", 5, nil),
        ("MRK", 16, 1...20), ("ROM", 14, 1...23), ("ROM", 16, 1...27),
        ("2CO", 13, 1...14), ("3JN", 1, 1...14), ("REV", 12, 1...17), ("REV", 22, 1...21),
        // The KJV's Apocrypha: the Rest of Esther begins at 10:4, Baruch's sixth
        // chapter is the Epistle of Jeremiah, and Sirach 33 has 31 verses where
        // the NRSV has 33 (TVTMS).
        ("ESG", 9, nil), ("ESG", 10, 4...13), ("ESG", 16, 1...24),
        ("BAR", 6, 1...73), ("S3Y", 1, 1...68), ("SUS", 1, 1...64), ("BEL", 1, 1...42), ("SIR", 33, 1...31),
        ("EST", 10, 1...3), ("EST", 11, nil), ("DAN", 12, 1...13), ("DAN", 13, nil),
    ] as [(String, Int, ClosedRange<Int>?)])
func englishChaptersHaveTheirVerses(id: String, chapter: Int, verses: ClosedRange<Int>?) throws {
    #expect(try loadEnglish().verses(of: book(id), chapter: chapter) == verses)
}

@Test func theEnglishSchemeLeavesTheLetterOfJeremiahInsideBaruch() throws {
    let english = try loadEnglish()
    #expect(english.chapters(of: book("LJE")) == nil)
    #expect(english.chapters(of: book("ESG")) == 10...16)
    #expect(english.contains(book("BAR"), chapter: 6, verse: 73))
    #expect(!english.contains(book("ESG"), chapter: 10, verse: 3))
}

@Test(
    arguments: [
        ("GEN\t1\t31 25", nil),
        ("ESG\t10\t4-13 12", nil),
        ("GEN\t1", VersificationError.malformedLine(1)),
        ("GEN\t0\t31", .malformedLine(1)),
        ("gen\t1\t31", .malformedLine(1)),
        ("GEN\t1\t31 x", .malformedLine(1)),
        ("GEN\t1\t0", .malformedLine(1)),
        ("GEN\t1\t1-3", .malformedLine(1)),
        ("GEN\t1\t5-3", .malformedLine(1)),
        ("GEN\t1\t", .malformedLine(1)),
        ("# comment\nGEN\t1\t31\nGEN\t1\t31", .duplicateBook(book("GEN"))),
    ] as [(String, VersificationError?)])
func readsOnlyWellFormedLines(tsv: String, error: VersificationError?) {
    if let error {
        #expect(throws: error) { try Versification(scheme: .english, tsv: tsv) }
    } else {
        #expect(throws: Never.self) { try Versification(scheme: .english, tsv: tsv) }
    }
}

@Test func refusesASchemeThatDoesNotMatchTheRegistry() throws {
    let registry = try loadRegistry()
    #expect(throws: VersificationError.unregisteredBook(book("PS2"))) {
        try Versification(scheme: .english, tsv: "PS2\t1\t7").check(against: registry)
    }
    #expect(throws: VersificationError.missingBook(book("GEN"), canon: "protestant")) {
        try Versification(scheme: .english, tsv: "EXO\t1\t22").check(against: registry)
    }
}
