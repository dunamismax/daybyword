// Writes catalog/scripture/words/web.tsv, the words in each verse of the 66
// books, numbered by the English (KJV) scheme, counted from eBible.org's
// public-domain World English Bible (BUILD.md P3.6). Only the numbers are
// written; no text is kept (D13). The download lives in the gitignored
// research/ folder (D21):
//
//   research/ebible/eng-web/   https://ebible.org/Scriptures/eng-web_usfm.zip
//
//   swift scripts/wordcounts.swift generate   rewrite web.tsv from the WEB
//
// The counting method: a verse's words are the text after its \v marker up to
// the next verse or chapter, with footnotes (\f … \f*), cross-references
// (\x … \x*), and word attributes (|strong="…") removed. A psalm's title
// (\d) counts toward its first verse, because the reader reads it there.
// Headings (\mt, \ms, \sp, \cl, and the book's \h and \toc lines) are not
// counted. A word is a run of characters between spaces or dashes that holds
// a letter or a digit, so "God’s" is one word and "—" is none. The WEB prints
// Romans' closing doxology as 14:24–26, which the English scheme numbers
// 16:25–27, so those verses are moved there and the WEB's empty 16:25 (a
// footnote only) is dropped. Four verses the English scheme numbers are
// footnotes only in the WEB (Luke 17:36; Acts 8:37, 15:34, and 24:7), so they
// count no words; any other empty verse stops the script.
import Foundation

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let source = root.appending(path: "research/ebible/eng-web")
let output = root.appending(path: "catalog/scripture/words/web.tsv")

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("wordcounts: \(message)\n".utf8))
    exit(1)
}

/// The English scheme's verses for each book, in the file's order.
func englishScheme() -> [(book: String, chapters: [(chapter: Int, verses: ClosedRange<Int>)])] {
    let url = root.appending(path: "catalog/scripture/versification/english.tsv")
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { fail("cannot read english.tsv") }
    return text.split(separator: "\n").filter { !$0.hasPrefix("#") }.map { line in
        let cells = line.split(separator: "\t")
        let first = Int(cells[1])!
        let chapters = cells[2].split(separator: " ").enumerated().map { index, field in
            let bounds = field.split(separator: "-").map { Int($0)! }
            return (first + index, bounds.count == 1 ? 1...bounds[0] : bounds[0]...bounds[1])
        }
        return (String(cells[0]), chapters)
    }
}

/// The books of the Protestant canon, from the book registry.
func protestantBooks() -> Set<String> {
    let url = root.appending(path: "catalog/scripture/books.json")
    guard let data = try? Data(contentsOf: url),
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let canons = json["canons"] as? [[String: Any]],
        let protestant = canons.first(where: { $0["id"] as? String == "protestant" }),
        let orders = protestant["orders"] as? [[String: Any]], let books = orders.first?["books"] as? [String]
    else { fail("cannot read the Protestant canon from books.json") }
    return Set(books)
}

let headings: Set<String> = ["id", "ide", "h", "toc1", "toc2", "toc3", "mt1", "mt2", "mt3", "ms1", "sp", "cl"]
let paragraphs: Set<String> = ["p", "m", "b", "nb", "mi", "q1", "q2", "li1", "pi1"]
let characterStyles: Set<String> = ["w", "+w", "wj", "qs", "bk"]
/// Verses the WEB gives only in a footnote ("Some Greek manuscripts add …").
let footnoteOnly: Set<String> = ["LUK 17:36", "ACT 8:37", "ACT 15:34", "ACT 24:7"]

func words(in text: Substring) -> Int {
    text.split(whereSeparator: { $0.isWhitespace || $0 == "\u{2014}" || $0 == "\u{2013}" })
        .count(where: { $0.contains(where: { $0.isLetter || $0.isNumber }) })
}

/// Words by verse, by chapter, as one WEB book's USFM file divides them.
func count(_ file: URL) -> [Int: [Int: Int]] {
    guard var text = try? String(contentsOf: file, encoding: .utf8) else {
        fail("cannot read \(file.lastPathComponent)")
    }
    text.replace(#/\\f .*?\\f\*/#, with: " ")
    text.replace(#/\\x .*?\\x\*/#, with: " ")
    text.replace(#/\|[a-z-]+="[^"]*"/#, with: "")

    var counts: [Int: [Int: Int]] = [:]
    var chapter = 0
    var verse: Int?
    // Where text goes: a verse, or nowhere (a heading).
    var target: Int?
    var rest = text[...]
    while let marker = rest.firstMatch(of: #/\\(\+?[a-z]+[0-9]*)(\*?)/#) {
        if let target, chapter > 0 {
            counts[chapter, default: [:]][target, default: 0] += words(in: rest[..<marker.range.lowerBound])
        }
        rest = rest[marker.range.upperBound...]
        let name = String(marker.1)
        switch name {
        case "c", "v":
            guard let number = rest.firstMatch(of: #/^ (\d+) /#), let value = Int(number.1) else {
                fail("\(file.lastPathComponent): \\\(name) without a number")
            }
            rest = rest[number.range.upperBound...]
            if name == "c" {
                (chapter, verse, target) = (value, nil, nil)
            } else {
                (verse, target) = (value, value)
                counts[chapter, default: [:]][value, default: 0] += 0
            }
        case "d": target = 1
        case _ where headings.contains(name): target = nil
        case _ where paragraphs.contains(name): target = verse
        case _ where characterStyles.contains(name): break
        default: fail("\(file.lastPathComponent): \\\(name) is not classified; decide whether it is verse text")
        }
    }
    if let target, chapter > 0 { counts[chapter, default: [:]][target, default: 0] += words(in: rest) }
    return counts
}

guard CommandLine.arguments.dropFirst().first == "generate" else {
    print("usage: swift scripts/wordcounts.swift generate")
    exit(2)
}
guard let files = try? FileManager.default.contentsOfDirectory(atPath: source.path) else {
    fail("research/ebible/eng-web is missing; download it first (see the top of this script)")
}
let protestant = protestantBooks()
var lines: [String] = []
var total = 0
for (book, chapters) in englishScheme() where protestant.contains(book) {
    // eBible names files like "02-GENeng-web.usfm".
    guard let file = files.first(where: { $0.hasSuffix("-\(book)eng-web.usfm") }) else {
        fail("no WEB file for \(book)")
    }
    var web = count(source.appending(path: file))
    if book == "ROM" {
        guard web[16]?[25] == 0, let doxology = web[14], doxology.count == 26 else {
            fail("Romans is not divided as this script expects")
        }
        web[16]![25] = nil
        for verse in 24...26 { web[16]![verse + 1] = doxology[verse] }
        for verse in 24...26 { web[14]![verse] = nil }
    }
    for (chapter, verses) in chapters {
        guard let found = web[chapter], Set(found.keys) == Set(verses) else {
            fail("\(book) \(chapter): the WEB's verses differ from the English scheme's")
        }
        let numbers = verses.map { found[$0]! }
        if let empty = verses.first(where: { found[$0] == 0 && !footnoteOnly.contains("\(book) \(chapter):\($0)") }) {
            fail("\(book) \(chapter):\(empty) has no words")
        }
        total += numbers.reduce(0, +)
        lines.append("\(book)\t\(chapter)\t\(numbers.map(String.init).joined(separator: " "))")
    }
    web = web.filter { chapter, _ in !chapters.contains { $0.chapter == chapter } }
    guard web.isEmpty else { fail("\(book): the WEB has chapters the English scheme does not") }
}

let header = """
    # Words per verse, numbered by the English (KJV) scheme, counted from the
    # World English Bible (eBible.org, public domain) by
    # scripts/wordcounts.swift, which gives the method. Numbers only, for
    # workload estimates; no text (BUILD.md D13, docs/decisions.md E31).
    # A line per chapter: the book's USFM id, the chapter, and each verse's
    # words in order. Total for the 66 books: \(total) words.

    """
try? FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
do {
    try (header + lines.joined(separator: "\n") + "\n").write(to: output, atomically: true, encoding: .utf8)
} catch {
    fail("cannot write \(output.path): \(error)")
}
print("wordcounts: wrote \(lines.count) chapters, \(total) words")
