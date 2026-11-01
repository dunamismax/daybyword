import ReadingEngine
import Testing

func verses(_ text: String) throws -> VerseSet {
    let english = try loadEnglish()
    return VerseSet(try ReferenceFormat.reading(text, in: english).passages, in: english)
}

func written(_ set: VerseSet) throws -> String {
    let english = try loadEnglish()
    return set.passages(in: english).map { ReferenceFormat.text(of: $0, in: english) }.joined(separator: "; ")
}

@Test(
    arguments: [
        // Positions count on across chapter ends, from 0 at the book's first verse.
        ("GEN", (1, 1), 0), ("GEN", (1, 31), 30), ("GEN", (2, 1), 31), ("GEN", (50, 26), 1532),
        ("ESG", (10, 4), 0), ("ESG", (11, 1), 10), ("JUD", (1, 25), 24),
    ] as [(String, (Int, Int), Int)])
func versesHavePositionsInTheirBook(id: String, place: (Int, Int), position: Int) throws {
    let english = try loadEnglish()
    let verse = ChapterVerse(place.0, place.1)
    #expect(english.position(of: verse, in: book(id)) == position)
    #expect(english.place(at: position, in: book(id)) == verse)
}

@Test func positionsStopAtTheBooksEdges() throws {
    let english = try loadEnglish()
    #expect(english.position(of: ChapterVerse(1, 32), in: book("GEN")) == nil)
    #expect(english.position(of: ChapterVerse(10, 3), in: book("ESG")) == nil)
    #expect(english.place(at: -1, in: book("GEN")) == nil)
    #expect(english.place(at: 1533, in: book("GEN")) == nil)
    #expect(english.place(at: 0, in: book("LJE")) == nil)
}

@Test(
    arguments: [
        // A set's passages, and the fewest passages that write it.
        ("GEN 1; GEN 2", "GEN 1-2"),
        ("GEN 1:1-2:3; GEN 2:4-25", "GEN 1-2"),
        ("GEN 2; GEN 1", "GEN 1-2"),
        ("GEN 1:1-10; GEN 1:5-20", "GEN 1:1-20"),
        ("GEN 1:1-10; GEN 1:12-20", "GEN 1:1-10; GEN 1:12-20"),
        ("JHN 1; GEN 1; JHN 1:5", "GEN 1; JHN 1"),
        ("GEN 50; EXO 1", "GEN 50; EXO 1"),
    ])
func setsJoinTouchingAndOverlappingPassages(text: String, shortest: String) throws {
    #expect(try written(verses(text)) == shortest)
}

@Test func setsCountEachVerseOnce() throws {
    let set = try verses("PSA 117; PSA 117; PSA 119:1-24; PSA 119:9-16")
    #expect(set.count == 2 + 24)
    #expect(set.count(in: book("PSA")) == 26)
    #expect(set.count(in: book("GEN")) == 0)
    #expect(set.books == [book("PSA")])
    let english = try loadEnglish()
    #expect(set.contains(book("PSA"), ChapterVerse(119, 24), in: english))
    #expect(!set.contains(book("PSA"), ChapterVerse(119, 25), in: english))
    #expect(VerseSet().isEmpty && VerseSet().count == 0)
}

@Test(
    arguments: [
        // a, b, a ∪ b, a ∩ b, a − b.
        ("GEN 1", "GEN 2", "GEN 1-2", "", "GEN 1"),
        ("GEN 1-3", "GEN 2", "GEN 1-3", "GEN 2", "GEN 1; GEN 3"),
        ("GEN 1:1-20", "GEN 1:10-2:5", "GEN 1:1-2:5", "GEN 1:10-20", "GEN 1:1-9"),
        ("GEN 1; EXO 1", "EXO 1:1-5; LEV 1", "GEN 1; EXO 1; LEV 1", "EXO 1:1-5", "GEN 1; EXO 1:6-22"),
        (
            "JHN 1-21", "JHN 3:16; JHN 7:53-8:11", "JHN 1-21", "JHN 3:16; JHN 7:53-8:11",
            "JHN 1:1-3:15; JHN 3:17-7:52; JHN 8:12-21:25"
        ),
    ])
func setsCombine(a: String, b: String, union: String, intersection: String, difference: String) throws {
    let (left, right) = (try verses(a), try verses(b))
    #expect(try written(left.union(right)) == union)
    #expect(try written(left.intersection(right)) == intersection)
    #expect(try written(left.subtracting(right)) == difference)
}

@Test func repeatsAreTheVersesGivenMoreThanOnce() throws {
    let english = try loadEnglish()
    let passages = try ReferenceFormat.reading("PSA 1; PSA 2; PSA 1:1-3; PSA 2:6; PSA 2:6; GEN 1", in: english).passages
    #expect(try written(VerseSet.repeats(in: passages, in: english)) == "PSA 1:1-3; PSA 2:6")
    #expect(VerseSet.repeats(in: [], in: english).isEmpty)
}

@Test func chaptersAreWholeOrPartlyCovered() throws {
    let english = try loadEnglish()
    let coverage = try verses("GEN 1; GEN 2:1-3; GEN 3:24-4:1; ESG 10").chapters(in: english)
    let expected: [(String, Int, Int, Int)] = [
        ("GEN", 1, 31, 31), ("GEN", 2, 3, 25), ("GEN", 3, 1, 24), ("GEN", 4, 1, 26), ("ESG", 10, 10, 10),
    ]
    #expect(
        coverage.map { [$0.book.rawValue, "\($0.chapter)", "\($0.covered)", "\($0.verses)"] }
            == expected.map { [$0.0, "\($0.1)", "\($0.2)", "\($0.3)"] })
    #expect(coverage.map(\.isWhole) == [true, false, false, false, true])
}

/// Every operation agrees with a plain set of verses, over many passages
/// drawn from a fixed seed.
@Test func setsAgreeWithAPlainSetOfVerses() throws {
    let english = try loadEnglish()
    let books = [book("GEN"), book("RUT"), book("PSA"), book("JUD")]
    var seed: UInt64 = 2026
    func next(_ bound: Int) -> Int {
        seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int((seed >> 33) % UInt64(bound))
    }
    func randomPassages() -> [Passage] {
        (0..<next(6)).map { _ in
            let id = books[next(books.count)]
            let size = english.verseCount(of: id)
            let first = next(size)
            let last = min(size - 1, first + next(80))
            return try! Passage(
                id, from: english.place(at: first, in: id)!, to: english.place(at: last, in: id)!, in: english)
        }
    }
    func plain(_ passages: [Passage]) -> Set<String> {
        Set(
            passages.flatMap { passage in
                (english.position(of: passage.start, in: passage.book)!...english.position(
                    of: passage.end, in: passage.book)!).map { "\(passage.book) \($0)" }
            })
    }
    for _ in 0..<500 {
        let (a, b) = (randomPassages(), randomPassages())
        let (left, right) = (VerseSet(a, in: english), VerseSet(b, in: english))
        #expect(plain(left.union(right).passages(in: english)) == plain(a).union(plain(b)))
        #expect(plain(left.intersection(right).passages(in: english)) == plain(a).intersection(plain(b)))
        #expect(plain(left.subtracting(right).passages(in: english)) == plain(a).subtracting(plain(b)))
        #expect(left.count == plain(a).count)
        #expect(VerseSet(left.passages(in: english), in: english) == left)
    }
}
