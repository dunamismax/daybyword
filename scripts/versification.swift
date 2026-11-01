// Writes catalog/scripture/versification/english.tsv, the chapter and verse
// counts of the English (KJV) scheme, from eBible.org's public-domain King
// James Version (BUILD.md P3.2a), and compares them with two independent
// sources. The downloads live in the gitignored research/ folder (D21):
//
//   research/ebible/eng-kjv/   https://ebible.org/Scriptures/eng-kjv_usfm.zip
//   research/ebible/eng-web/   https://ebible.org/Scriptures/eng-web_usfm.zip
//   research/stepbible/tvtms.txt  STEPBible-Data's TVTMS file (CC BY 4.0)
//
//   swift scripts/versification.swift generate   rewrite english.tsv from the KJV
//   swift scripts/versification.swift compare    list every difference from the
//                                                World English Bible and every
//                                                TVTMS "=Last" test in its
//                                                English column that disagrees
//
// The counting method: a chapter's verses are the numbers its \v markers
// carry, a bridge such as \v 1-2 counting each verse; every chapter must run
// without gaps. Only books registered in catalog/scripture/books.json are
// written, so the KJV's 1 Esdras, 2 Esdras, and Prayer of Manasses wait for
// the registry (P3.1b).
import Foundation

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let output = root.appending(path: "catalog/scripture/versification/english.tsv")

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("versification: \(message)\n".utf8))
    exit(1)
}

/// Verse ranges by chapter, by book, as a text's USFM files number them.
typealias Counts = [String: [Int: ClosedRange<Int>]]

/// Reads a text's counts. Every chapter of the text the counts come from
/// must run without gaps; a comparison text's gaps are listed instead.
func readUSFM(_ directory: String, strict: Bool) -> Counts {
    let folder = root.appending(path: directory)
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: folder.path) else {
        fail("\(directory) is missing; download it first (see the top of this script)")
    }
    let marker = #/\\(c|v) (\d+)(?:-(\d+))?/#
    var counts: Counts = [:]
    for file in files.sorted() where file.hasSuffix(".usfm") {
        // eBible names files like "02-GENeng-kjv.usfm".
        let book = String(file.dropFirst(3).prefix(3))
        guard let text = try? String(contentsOf: folder.appending(path: file), encoding: .utf8) else {
            fail("cannot read \(file)")
        }
        var chapter = 0
        var verses: [Int: [Int]] = [:]
        for match in text.matches(of: marker) {
            let number = Int(match.2)!
            if match.1 == "c" {
                chapter = number
                verses[chapter] = []
            } else {
                verses[chapter, default: []].append(contentsOf: number...(match.3.flatMap { Int($0) } ?? number))
            }
        }
        verses[0] = nil
        if verses.isEmpty { continue }
        counts[book] = verses.compactMapValues { list in
            guard let first = list.min(), let last = list.max() else { return nil }
            if list != Array(first...last) {
                if strict { fail("\(file) has a chapter whose verses do not run without gaps") }
                print("\(book): a chapter's verses do not run in order without gaps in \(directory)")
            }
            return first...last
        }
    }
    return counts
}

func registeredBooks() -> [String] {
    struct Registry: Decodable {
        struct Book: Decodable { let id: String }
        let books: [Book]
    }
    let url = root.appending(path: "catalog/scripture/books.json")
    guard let data = try? Data(contentsOf: url), let registry = try? JSONDecoder().decode(Registry.self, from: data)
    else { fail("cannot read \(url.path)") }
    return registry.books.map(\.id)
}

func describe(_ range: ClosedRange<Int>?) -> String {
    guard let range else { return "absent" }
    return range.lowerBound == 1 ? "\(range.upperBound) verses" : "verses \(range.lowerBound)–\(range.upperBound)"
}

let header = """
    # The English (KJV) versification: each line is a book's USFM id, its first
    # chapter, and each chapter's verses in turn, as a count (verses 1 to N) or
    # a range (F-N) where a chapter does not start at verse 1.
    # Counted from the King James Version (1769 text, with Apocrypha), public
    # domain, from eBible.org (eng-kjv, USFM, 2026-09-26) by
    # scripts/versification.swift, which also lists every difference from the
    # World English Bible and from STEPBible-Data's TVTMS (BUILD.md P3.2a).
    # Do not edit by hand.

    """

switch CommandLine.arguments.dropFirst().first {
case "generate":
    let kjv = readUSFM("research/ebible/eng-kjv", strict: true)
    var lines: [String] = []
    for book in registeredBooks() {
        guard let chapters = kjv[book] else { continue }
        let numbers = chapters.keys.sorted()
        guard let first = numbers.first, numbers == Array(first...numbers.last!) else {
            fail("\(book)'s chapters do not run without gaps")
        }
        let ranges = numbers.map { number in
            let range = chapters[number]!
            return range.lowerBound == 1 ? "\(range.upperBound)" : "\(range.lowerBound)-\(range.upperBound)"
        }
        lines.append("\(book)\t\(first)\t\(ranges.joined(separator: " "))")
    }
    try! (header + lines.joined(separator: "\n") + "\n").write(to: output, atomically: true, encoding: .utf8)
    print("versification: wrote \(lines.count) books to \(output.path)")

case "compare":
    let kjv = readUSFM("research/ebible/eng-kjv", strict: true)
    let web = readUSFM("research/ebible/eng-web", strict: false)
    let books = registeredBooks().filter { kjv[$0] != nil }
    print("== The World English Bible, where it differs")
    for book in books {
        guard let other = web[book] else {
            print("\(book): not in the World English Bible")
            continue
        }
        for chapter in Set(kjv[book]!.keys).union(other.keys).sorted() where kjv[book]![chapter] != other[chapter] {
            print("\(book) \(chapter): KJV \(describe(kjv[book]![chapter])), WEB \(describe(other[chapter]))")
        }
    }

    print("== TVTMS tests in the English column that disagree")
    guard let tvtms = try? String(contentsOf: root.appending(path: "research/stepbible/tvtms.txt"), encoding: .utf8)
    else { fail("research/stepbible/tvtms.txt is missing") }
    let lastTest = #/([1-4A-Z][A-Za-z0-9]{2})\.(\d+):(\d+)=Last/#
    var column: Int?
    var section = ""
    var checked = 0
    var inCondensed = false
    for line in tvtms.split(separator: "\n", omittingEmptySubsequences: false) {
        if line.hasPrefix("#DataStart(Condensed)") { inCondensed = true }
        if line.hasPrefix("#DataEnd(Condensed)") { break }
        guard inCondensed else { continue }
        let cells = line.split(separator: "\t", omittingEmptySubsequences: false)
        if line.hasPrefix("$") {
            section = String(cells[0])
            column = cells.firstIndex { $0.trimmingCharacters(in: .whitespaces).hasPrefix("English") }
        } else if line.hasPrefix("TEST"), let column, column < cells.count {
            for match in cells[column].matches(of: lastTest) {
                // TVTMS writes Additions to Esther as "Ade"; its "Esg" is the
                // whole Greek Esther, which this registry does not register.
                let book = match.1.uppercased() == "ADE" ? "ESG" : match.1.uppercased()
                guard books.contains(book), book != "ESG" || match.1 == "Ade" else { continue }
                checked += 1
                let chapter = Int(match.2)!
                let verse = Int(match.3)!
                if kjv[book]?[chapter]?.upperBound != verse {
                    print("\(section): TVTMS \(book) \(chapter):\(verse) is last; KJV \(describe(kjv[book]?[chapter]))")
                }
            }
        }
    }
    print("== \(checked) TVTMS tests checked")

default:
    fail("usage: swift scripts/versification.swift generate|compare")
}
