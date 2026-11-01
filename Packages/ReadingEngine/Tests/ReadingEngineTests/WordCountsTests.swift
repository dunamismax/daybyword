import Foundation
import ReadingEngine
import Testing

/// The word counts the catalog is compiled with, read from the repository.
func loadWordCounts() throws -> WordCounts {
    let url = registryURL.deletingLastPathComponent().appending(path: "words/web.tsv")
    return try WordCounts(tsv: String(contentsOf: url, encoding: .utf8), versification: loadEnglish())
}

/// The WEB's 66 books come to 754,449 words by scripts/wordcounts.swift's
/// method (BUILD.md P3.6).
@Test func theCountsCoverTheProtestantCanon() throws {
    let counts = try loadWordCounts()
    let protestant = try #require(try loadRegistry().canon("protestant")).books
    #expect(counts.books == protestant)
    #expect(protestant.reduce(0) { $0 + (counts.words(of: $1) ?? 0) } == 754_449)
    #expect(counts.words(of: book("TOB")) == nil)
}

@Test(
    arguments: [
        // A reading, its words, counted by hand from the WEB.
        ("GEN 1:1", 10),
        ("GEN 1:2", 25),
        ("GEN 1:1-2", 35),
        // Psalm 3's title counts toward its first verse.
        ("PSA 3:1", 25),
        ("PSA 117", 25),
        ("PSA 117; PSA 117", 50),
        // Verses the WEB gives only in a footnote count no words.
        ("LUK 17:36", 0),
        // The WEB prints Romans' doxology as 14:24-26; it is counted as 16:25-27.
        ("ROM 16:25-27", 35 + 30 + 15),
    ])
func readingsHaveTheirWords(text: String, words: Int) throws {
    let reading = try ReferenceFormat.reading(text, in: loadEnglish())
    #expect(try loadWordCounts().words(in: reading) == words)
}

@Test func passagesAddUpToTheirBook() throws {
    let english = try loadEnglish()
    let counts = try loadWordCounts()
    for id in ["GEN", "PSA", "JHN", "JUD"].map(book) {
        let chapters = try #require(english.chapters(of: id))
        let byChapter = try chapters.map { try #require(counts.words(in: Passage(id, chapter: $0, in: english))) }
        #expect(byChapter.reduce(0, +) == counts.words(of: id))
        #expect(counts.words(in: try Passage(id, chapters: chapters, in: english)) == counts.words(of: id))
    }
}

@Test func uncountedBooksHaveNoWords() throws {
    let english = try loadEnglish()
    let reading = try ReferenceFormat.reading("GEN 1; TOB 1", in: english)
    #expect(try loadWordCounts().words(in: reading) == nil)
}

@Test(
    arguments: [
        ("GEN\t1", WordCountsError.malformedLine(1)),
        ("GEN\tx\t1", .malformedLine(1)),
        ("OBA\t1\t" + Array(repeating: "1", count: 20).joined(separator: " ") + " -1", .malformedLine(1)),
        ("OBA\t1\t" + Array(repeating: "1", count: 20).joined(separator: " ") + "  1", .malformedLine(1)),
        ("OBA\t2\t1", .noSuchChapter(book("OBA"), 2)),
        ("LJE\t1\t1", .noSuchChapter(book("LJE"), 1)),
        ("OBA\t1\t1 2 3", .wrongVerseCount(book("OBA"), 1, expected: 21, found: 3)),
        ("JON\t1\t" + Array(repeating: "1", count: 17).joined(separator: " "), .missingChapter(book("JON"), 2)),
    ] as [(String, WordCountsError)])
func refusesCountsThatDoNotFitTheScheme(tsv: String, error: WordCountsError) throws {
    let english = try loadEnglish()
    #expect(throws: error) { try WordCounts(tsv: tsv, versification: english) }
}

@Test func refusesAChapterCountedTwice() throws {
    let english = try loadEnglish()
    let obadiah = "OBA\t1\t" + Array(repeating: "1", count: 21).joined(separator: " ")
    #expect(throws: WordCountsError.duplicateChapter(book("OBA"), 1)) {
        try WordCounts(tsv: obadiah + "\n" + obadiah, versification: english)
    }
    #expect(try WordCounts(tsv: "# a comment\n" + obadiah, versification: english).words(of: book("OBA")) == 21)
}
