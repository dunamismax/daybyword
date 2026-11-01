import Foundation
import ReadingEngine
import Testing

/// The registry the catalog is compiled from, read from the repository.
let registryURL = URL(filePath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
    .appending(path: "catalog/scripture/books.json")

func loadRegistry() throws -> BookRegistry {
    try BookRegistry(json: Data(contentsOf: registryURL))
}

func book(_ text: String) -> BookID {
    BookID(text)!
}

// MARK: Book ids

@Test(arguments: ["GEN", "1SA", "S3Y", "PS2", "3JN"])
func acceptsBookIDs(text: String) throws {
    #expect(try #require(BookID(text)).rawValue == text)
}

@Test(arguments: ["", "GE", "GENE", "gen", "Gen", "123", "G N", "ÉST", "GE-"])
func refusesOtherBookIDs(text: String) {
    #expect(BookID(text) == nil)
}

// MARK: The registry in catalog/

@Test func theRegistryReads() throws {
    let registry = try loadRegistry()
    #expect(registry.conventions.map(\.id) == NamingConvention.allCases)
    #expect(registry.books.count == 78)
}

@Test func theProtestantCanonHas66Books() throws {
    let canon = try #require(try loadRegistry().canon("protestant"))
    #expect(canon.books.count == 66)
    #expect(canon.books.first == book("GEN"))
    #expect(canon.books[38] == book("MAL"))
    #expect(canon.books[39] == book("MAT"))
    #expect(canon.books.last == book("REV"))
    #expect(canon.includes.isEmpty)
}

@Test func theCatholicCanonHas73BooksInTwoOrders() throws {
    let canon = try #require(try loadRegistry().canon("catholic"))
    #expect(canon.books.count == 73)
    #expect(canon.orders.map(\.id) == ["usccb", "vulgate"])
    let usccb = canon.orders[0].books
    let vulgate = canon.orders[1].books
    // The two printed orders differ only in where 1 and 2 Maccabees stand.
    #expect(usccb[19...20] == [book("1MA"), book("2MA")])
    #expect(vulgate[44...45] == [book("1MA"), book("2MA")])
    #expect(
        usccb.filter { $0 != book("1MA") && $0 != book("2MA") }
            == vulgate.filter { $0 != book("1MA") && $0 != book("2MA") })
}

@Test func theCatholicCanonHasTheProtestantBooksAndSevenMore() throws {
    let registry = try loadRegistry()
    let protestant = try #require(registry.canon("protestant"))
    let catholic = try #require(registry.canon("catholic"))
    #expect(Set(protestant.books).isSubset(of: Set(catholic.books)))
    #expect(
        Set(catholic.books).subtracting(protestant.books)
            == Set(["TOB", "JDT", "1MA", "2MA", "WIS", "SIR", "BAR"].map(book)))
}

@Test(arguments: [
    ("S3Y", "DAN"), ("SUS", "DAN"), ("BEL", "DAN"), ("ESG", "EST"), ("LJE", "BAR"),
])
func catholicBooksHoldTheGreekAdditions(part: String, holder: String) throws {
    let registry = try loadRegistry()
    let catholic = try #require(registry.canon("catholic"))
    #expect(catholic.bookIncluding(book(part)) == book(holder))
    #expect(catholic.contains(book(part)))
    #expect(registry.canons(containing: book(part)).map(\.id) == ["catholic"])
}

@Test(arguments: ["GEN", "PSA", "MAT", "REV"])
func everyCanonHasTheSharedBooks(id: String) throws {
    #expect(try loadRegistry().canons(containing: book(id)).map(\.id) == ["protestant", "catholic"])
}

@Test(arguments: ["TOB", "SIR", "2MA"])
func onlyTheCatholicCanonHasTheDeuterocanonicalBooks(id: String) throws {
    let registry = try loadRegistry()
    #expect(registry.canons(containing: book(id)).map(\.id) == ["catholic"])
    #expect(registry.canon("catholic")?.bookIncluding(book(id)) == nil)
}

@Test(
    arguments: [
        // Book, convention, name, abbreviation (nil: shown in full).
        ("SNG", NamingConvention.common, "Song of Songs", "Song"),
        ("SNG", .kjv, "Song of Solomon", "Song"),
        ("SNG", .douay, "Canticle of Canticles", "Cant"),
        ("SIR", .common, "Sirach", "Sir"),
        ("SIR", .kjv, "Ecclesiasticus", "Sir"),
        ("SIR", .douay, "Ecclesiasticus", "Sir"),
        ("1SA", .common, "1 Samuel", "1 Sam"),
        ("1SA", .kjv, "1 Samuel", "1 Sam"),
        ("1SA", .douay, "1 Kings", nil),
        ("1KI", .common, "1 Kings", "1 Kgs"),
        ("1KI", .douay, "3 Kings", nil),
        ("2KI", .douay, "4 Kings", nil),
        ("1CH", .douay, "1 Paralipomenon", nil),
        ("EZR", .douay, "1 Esdras", nil),
        ("NEH", .douay, "2 Esdras", nil),
        ("ISA", .douay, "Isaias", nil),
        ("HOS", .douay, "Osee", nil),
        ("OBA", .douay, "Abdias", nil),
        ("ZEP", .douay, "Sophonias", nil),
        ("1MA", .douay, "1 Machabees", nil),
        ("REV", .common, "Revelation", "Rev"),
        ("REV", .kjv, "Revelation", "Rev"),
        ("REV", .douay, "Apocalypse", nil),
        ("ESG", .common, "Additions to Esther", "Add Esth"),
        ("ESG", .kjv, "Rest of Esther", nil),
        ("ESG", .douay, "Additions to Esther", "Add Esth"),
        ("LJE", .common, "Letter of Jeremiah", "Ep Jer"),
        ("LJE", .kjv, "Epistle of Jeremiah", "Ep Jer"),
        ("S3Y", .kjv, "Song of the Three Children", nil),
        ("PSA", .common, "Psalms", "Ps"),
        ("PHM", .common, "Philemon", "Phlm"),
        ("JAS", .douay, "James", "Jas"),
        ("WIS", .common, "Wisdom", "Wis"),
    ] as [(String, NamingConvention, String, String?)])
func namesFollowTheConvention(id: String, convention: NamingConvention, name: String, abbreviation: String?) throws {
    let entry = try #require(try loadRegistry().book(book(id)))
    #expect(entry.name(in: convention) == BookRegistry.BookName(name: name, abbreviation: abbreviation))
}

@Test func everyOrderAndConventionCitesASource() throws {
    let registry = try loadRegistry()
    #expect(registry.conventions.allSatisfy { !$0.sources.isEmpty })
    #expect(registry.canons.flatMap(\.orders).allSatisfy { !$0.sources.isEmpty })
    #expect(registry.sources.allSatisfy { $0.url.hasPrefix("https://") && $0.checked == "2026-11-01" })
}

// MARK: What the registry refuses

/// A small registry that passes, which each refusal case breaks in one way.
func fixture(
    books: String = """
    { "id": "GEN", "testament": "old", "name": "Genesis", "abbreviation": "Gen" },
    { "id": "DAN", "testament": "old", "name": "Daniel", "abbreviation": "Dan" },
    { "id": "SUS", "testament": "old", "name": "Susanna", "abbreviation": "Sus" },
    { "id": "MAT", "testament": "new", "name": "Matthew", "abbreviation": "Matt",
      "names": { "douay": { "name": "Saint Matthew" } } }
    """,
    orders: String = """
    { "id": "first", "label": "First", "sources": ["s"], "books": ["GEN", "DAN", "MAT"] },
    { "id": "second", "label": "Second", "sources": ["s"], "books": ["DAN", "GEN", "MAT"] }
    """,
    includes: String = #""includes": { "DAN": ["SUS"] }, "includesSources": ["s"],"#,
    conventions: String = """
    { "id": "common", "label": "C", "example": "e", "rule": "r", "sources": ["s"] },
    { "id": "kjv", "label": "K", "example": "e", "rule": "r", "sources": ["s"] },
    { "id": "douay", "label": "D", "example": "e", "rule": "r", "sources": ["s"] }
    """,
    sources: String = """
    { "id": "s", "title": "T", "publisher": "P", "url": "https://example.org", "checked": "2026-11-01", "usedFor": "u" }
    """,
    format: Int = 1
) -> Data {
    Data(
        """
        { "format": \(format),
          "conventions": [\(conventions)],
          "books": [\(books)],
          "canons": [{ "id": "c", "label": "L", "description": "D", \(includes) "orders": [\(orders)] }],
          "sources": [\(sources)] }
        """.utf8)
}

@Test func theFixturePasses() throws {
    let registry = try BookRegistry(json: fixture())
    #expect(registry.books.map(\.id.rawValue) == ["GEN", "DAN", "SUS", "MAT"])
    #expect(registry.book(book("MAT"))?.name(in: .douay).name == "Saint Matthew")
    #expect(registry.book(book("MAT"))?.name(in: .kjv).name == "Matthew")
}

@Test(
    arguments: [
        (fixture(format: 2), BookRegistryError.unsupportedFormat(2)),
        (
            fixture(
                books:
                    #"{ "id": "GEN", "testament": "old", "name": "Genesis" }, { "id": "GEN", "testament": "old", "name": "Gen" }"#
            ),
            .duplicateBook(book("GEN"))
        ),
        (
            fixture(conventions: #"{ "id": "common", "label": "C", "example": "e", "rule": "r", "sources": ["s"] }"#),
            .missingConvention(.kjv)
        ),
        (
            fixture(
                orders: #"{ "id": "first", "label": "F", "sources": ["s"], "books": ["GEN", "DAN", "MAT", "GEN"] }"#),
            .repeatedBook(book("GEN"), in: "first")
        ),
        (
            fixture(
                orders: #"{ "id": "first", "label": "F", "sources": ["s"], "books": ["GEN", "DAN", "MAT", "REV"] }"#),
            .unknownBook(book("REV"), in: "first")
        ),
        (
            fixture(
                orders: """
                    { "id": "first", "label": "F", "sources": ["s"], "books": ["GEN", "DAN", "MAT"] },
                    { "id": "second", "label": "S", "sources": ["s"], "books": ["GEN", "MAT"] }
                    """),
            .ordersDisagree(canon: "c", order: "second")
        ),
        (
            fixture(orders: #"{ "id": "first", "label": "F", "sources": ["s"], "books": ["GEN", "MAT", "DAN"] }"#),
            .testamentsMixed("first")
        ),
        (
            fixture(
                orders: #"{ "id": "first", "label": "F", "sources": ["nowhere"], "books": ["GEN", "DAN", "MAT"] }"#),
            .unknownSource("nowhere", in: "first")
        ),
        (fixture(includes: #""includes": { "DAN": ["SUS"] },"#), .unsourcedIncludes("c")),
        (fixture(includes: ""), .bookInNoCanon(book("SUS"))),
        (
            fixture(includes: #""includes": { "DAN": ["GEN"] }, "includesSources": ["s"],"#),
            .includedTwice(book("GEN"), canon: "c")
        ),
        (
            fixture(
                books: """
                    { "id": "GEN", "testament": "old", "name": "Genesis", "abbreviation": "Gen" },
                    { "id": "DAN", "testament": "old", "name": "Daniel", "abbreviation": "Dan" },
                    { "id": "SUS", "testament": "old", "name": "Susanna", "abbreviation": "Sus" },
                    { "id": "MAT", "testament": "new", "name": "Matthew", "names": { "kjv": { "name": "Daniel" } } }
                    """),
            .duplicateName("Daniel", .kjv)
        ),
        (
            fixture(
                books: """
                    { "id": "GEN", "testament": "old", "name": "Genesis", "abbreviation": "Gen" },
                    { "id": "DAN", "testament": "old", "name": "Daniel", "abbreviation": "Dan" },
                    { "id": "SUS", "testament": "old", "name": "Susanna", "abbreviation": "Sus" },
                    { "id": "MAT", "testament": "new", "name": "Matthew", "abbreviation": "gen" }
                    """),
            .duplicateAbbreviation("gen", .common)
        ),
        (
            fixture(
                books: """
                    { "id": "GEN", "testament": "old", "name": "Genesis", "abbreviation": "Gen",
                      "names": { "kjv": { "name": "Genesis", "abbreviation": "Gen" } } },
                    { "id": "DAN", "testament": "old", "name": "Daniel" },
                    { "id": "SUS", "testament": "old", "name": "Susanna" },
                    { "id": "MAT", "testament": "new", "name": "Matthew" }
                    """),
            .redundantName(book("GEN"), .kjv)
        ),
        (
            fixture(
                books: """
                    { "id": "GEN", "testament": "old", "name": "", "abbreviation": "Gen" },
                    { "id": "DAN", "testament": "old", "name": "Daniel" },
                    { "id": "SUS", "testament": "old", "name": "Susanna" },
                    { "id": "MAT", "testament": "new", "name": "Matthew" }
                    """),
            .emptyName(book("GEN"))
        ),
        (
            fixture(
                sources: """
                    { "id": "s", "title": "T", "publisher": "P", "url": "https://example.org", "checked": "2026-11-01", "usedFor": "u" },
                    { "id": "t", "title": "T", "publisher": "P", "url": "https://example.org", "checked": "2026-11-01", "usedFor": "u" }
                    """),
            .unusedSource("t")
        ),
    ] as [(Data, BookRegistryError)])
func refusesABrokenRegistry(json: Data, error: BookRegistryError) {
    #expect(throws: error) { try BookRegistry(json: json) }
}

/// A convention or a book id the registry does not know is refused as the
/// file is read, before any other check.
@Test(arguments: [
    #"{ "id": "GEN", "testament": "old", "name": "G", "names": { "geneva": { "name": "X" } } }"#,
    #"{ "id": "gen", "testament": "old", "name": "Genesis" }"#,
    #"{ "id": "GEN", "testament": "apocrypha", "name": "Genesis" }"#,
])
func refusesWhatItCannotRead(books: String) {
    let error = #expect(throws: BookRegistryError.self) { try BookRegistry(json: fixture(books: books)) }
    guard case .unreadable = error else {
        Issue.record("expected an unreadable registry, got \(String(describing: error))")
        return
    }
}
