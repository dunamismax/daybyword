// Writes the schedules of Day by Word's own plans (catalog/plans/*.plan)
// from the English versification and the word counts, under the rules in
// docs/plans.md. A plan's front matter is written by hand and reviewed
// (docs/editorial.md); its schedule, everything after the "---" line, is
// computed here and never typed. Nothing is copied from any other plan,
// app, or publisher (AGENTS.md §6), and no Scripture text is read (D13).
//
//   swift scripts/plans.swift generate   rewrite each plan file's schedule
//   swift scripts/plans.swift check      fail if a schedule is not what its rule gives
//   swift scripts/plans.swift facts      print each plan's readings and words
//
// The balance rule (docs/plans.md, "Balanced readings"): chapters, in order,
// are divided into a given number of readings of whole chapters so that the
// sum of the squares of the readings' word counts is as small as it can be,
// which makes them as even as whole chapters allow. Of equal divisions, the
// one that breaks later is taken.
import Foundation

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let plansURL = root.appending(path: "catalog/plans", directoryHint: .isDirectory)

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("plans: \(message)\n".utf8))
    exit(1)
}

/// A chapter, or a run of its verses where a rule divides one.
struct Chapter {
    let book: String
    let number: Int
    /// The verses' words, in verse order.
    let verses: [Int]
    /// The first verse given, and whether every verse of the chapter is.
    var first = 1
    var whole = true
    /// The chapter's own number of verses, where only some are given.
    var total: Int?
    var words: Int { verses.reduce(0, +) }
    /// Whether the run reads on to the chapter's last verse.
    var endsChapter: Bool { whole || first + verses.count - 1 == (total ?? verses.count) }

    /// The chapter in runs of `size` verses: "PSA 119:1-16", "PSA 119:17-32".
    func sections(of size: Int) -> [Chapter] {
        stride(from: 0, to: verses.count, by: size).map { start in
            Chapter(
                book: book, number: number, verses: Array(verses[start..<min(start + size, verses.count)]),
                first: start + 1, whole: false, total: verses.count)
        }
    }
}

/// Every chapter of the 66 books with its words, in the word-count file's
/// order, which is the English scheme's.
func loadChapters() -> [Chapter] {
    let url = root.appending(path: "catalog/scripture/words/web.tsv")
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { fail("cannot read web.tsv") }
    return text.split(separator: "\n").filter { !$0.hasPrefix("#") }.map { line in
        let cells = line.split(separator: "\t")
        guard cells.count == 3, let number = Int(cells[1]) else { fail("web.tsv: malformed line \(line)") }
        return Chapter(
            book: String(cells[0]), number: number, verses: cells[2].split(separator: " ").map { Int($0)! })
    }
}

/// The books of each testament in the Protestant canon's order, from the
/// book registry.
func loadTestaments() -> (old: [String], new: [String]) {
    let url = root.appending(path: "catalog/scripture/books.json")
    guard let data = try? Data(contentsOf: url),
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let books = json["books"] as? [[String: Any]], let canons = json["canons"] as? [[String: Any]],
        let protestant = canons.first(where: { $0["id"] as? String == "protestant" }),
        let orders = protestant["orders"] as? [[String: Any]], let order = orders.first?["books"] as? [String]
    else { fail("cannot read the Protestant canon from books.json") }
    var testament: [String: String] = [:]
    for book in books {
        if let id = book["id"] as? String { testament[id] = book["testament"] as? String }
    }
    return (order.filter { testament[$0] == "old" }, order.filter { testament[$0] == "new" })
}

/// Halves away from zero, as docs/engine.md's "Numbers" rounds.
func rounded(_ value: Int, over divisor: Int) -> Int { (2 * value + divisor) / (2 * divisor) }

/// The balance rule: `chapters` in `count` consecutive readings with the
/// least sum of squared words; of equals, the later break.
func balanced(_ chapters: [Chapter], into count: Int) -> [[Chapter]] {
    let n = chapters.count
    guard count >= 1, count <= n else { fail("cannot divide \(n) chapters into \(count) readings") }
    var before = [0]
    for chapter in chapters { before.append(before.last! + chapter.words) }
    // cost[k][i]: the least sum of squares for the first i chapters in k
    // readings; cut[k][i]: where the last of them begins.
    var cost = [[Int]](repeating: [Int](repeating: Int.max, count: n + 1), count: count + 1)
    var cut = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: count + 1)
    cost[0][0] = 0
    for k in 1...count {
        for i in k...(n - (count - k)) {
            var best = Int.max
            var at = 0
            var j = i - 1
            while j >= k - 1 {
                let last = before[i] - before[j]
                // A longer last reading can only cost more than this one alone.
                if last * last > best { break }
                if cost[k - 1][j] != Int.max {
                    let total = cost[k - 1][j] + last * last
                    if total < best {
                        best = total
                        at = j
                    }
                }
                j -= 1
            }
            cost[k][i] = best
            cut[k][i] = at
        }
    }
    var readings: [[Chapter]] = []
    var end = n
    for k in stride(from: count, through: 1, by: -1) {
        let start = cut[k][end]
        readings.append(Array(chapters[start..<end]))
        end = start
    }
    return readings.reversed()
}

/// A reading in the plan-file format, in its shortest writing: "GEN 1-3",
/// "OBA 1; JON 1-2" where it runs from one book into the next, "PSA
/// 119:1-16" for part of a chapter, and "GEN 1:1-2:3" for a run that ends
/// (or begins) inside one.
func text(of reading: [Chapter]) -> String {
    var parts: [String] = []
    var index = 0
    while index < reading.count {
        // A run goes on into the book's next chapter when it reads to the
        // end of this one and the next begins at its first verse.
        var last = index
        while last + 1 < reading.count, reading[last + 1].book == reading[index].book,
            reading[last + 1].number == reading[last].number + 1, reading[last].endsChapter,
            reading[last + 1].first == 1
        {
            last += 1
        }
        let (start, end) = (reading[index], reading[last])
        let lastVerse = end.first + end.verses.count - 1
        if start.first == 1, end.endsChapter {
            parts.append(
                start.number == end.number
                    ? "\(start.book) \(start.number)" : "\(start.book) \(start.number)-\(end.number)")
        } else if start.number == end.number {
            parts.append(
                start.first == lastVerse
                    ? "\(start.book) \(start.number):\(start.first)"
                    : "\(start.book) \(start.number):\(start.first)-\(lastVerse)")
        } else {
            parts.append("\(start.book) \(start.number):\(start.first)-\(end.number):\(lastVerse)")
        }
        index = last + 1
    }
    return parts.joined(separator: "; ")
}

/// The chapters, whole or in part, that a reading in the plan-file format
/// gives, for a plan whose readings are listed rather than computed.
func passages(in reading: String, from all: [Chapter]) -> [Chapter] {
    reading.components(separatedBy: "; ").flatMap { passage -> [Chapter] in
        let pieces = passage.split(separator: " ")
        guard pieces.count == 2 else { fail("\(passage) is not a passage") }
        let book = String(pieces[0])
        func place(_ text: Substring) -> (chapter: Int, verse: Int?) {
            let numbers = text.split(separator: ":").map { Int($0) }
            guard let chapter = numbers.first ?? nil else { fail("\(passage) is not a passage") }
            return (chapter, numbers.count > 1 ? numbers[1] : nil)
        }
        let ends = pieces[1].split(separator: "-")
        let from = place(ends[0])
        var to = from
        if ends.count == 2 {
            if ends[1].contains(":") {
                to = place(ends[1])
            } else if from.verse != nil {
                to = (from.chapter, Int(ends[1]))
            } else {
                to = (Int(ends[1]) ?? 0, nil)
            }
        }
        return (from.chapter...to.chapter).map { number in
            guard let chapter = all.first(where: { $0.book == book && $0.number == number }) else {
                fail("\(passage): \(book) has no chapter \(number)")
            }
            let first = number == from.chapter ? (from.verse ?? 1) : 1
            let last = number == to.chapter ? (to.verse ?? chapter.verses.count) : chapter.verses.count
            guard 1 <= first, first <= last, last <= chapter.verses.count else { fail("\(passage) has no such verses") }
            if first == 1, last == chapter.verses.count { return chapter }
            return Chapter(
                book: book, number: number, verses: Array(chapter.verses[(first - 1)..<last]), first: first,
                whole: false, total: chapter.verses.count)
        }
    }
}

struct Schedule {
    let plan: String
    let readings: [[Chapter]]
}

/// The words Gospels at your pace aims at in a reading (docs/plans.md).
let gospelReadingWords = 1350
/// The readings in the Bible in a year.
let yearReadings = 365
/// The readings in the five-day plans: five a week for 52 weeks.
let fiveDayYearReadings = 260
/// Psalm 119's stanzas are 8 verses each, one for each letter of the
/// Hebrew alphabet; A psalm a day reads two at a time.
let psalm119Section = 16
/// The Story of Scripture's readings (docs/plans.md): narrative passages in
/// the order the story unfolds, each with what it tells. An editorial
/// selection, written here once; `generate` writes them as they are and
/// refuses one not in its shortest writing.
let storyOfScripture: [(reading: String, tells: String)] = [
    ("GEN 1:1-2:3", "the beginning"),
    ("GEN 2:4-3:24", "the garden"),
    ("GEN 6:5-8:22", "the flood"),
    ("GEN 11:1-9; GEN 12:1-9", "Babel; Abram called"),
    ("GEN 15; GEN 22:1-19", "the promise to Abram; Isaac"),
    ("GEN 37", "Joseph sold"),
    ("GEN 45", "Joseph makes himself known"),
    ("EXO 1-2", "oppression in Egypt; Moses"),
    ("EXO 3:1-4:17", "the burning bush"),
    ("EXO 12:1-42", "the Passover"),
    ("EXO 14", "the sea"),
    ("EXO 19-20", "Sinai and the commandments"),
    ("EXO 32", "the golden calf"),
    ("NUM 13-14", "the spies and the wilderness"),
    ("DEU 34; JOS 1", "Moses dies; Joshua"),
    ("JOS 6", "Jericho"),
    ("JDG 2:6-23; JDG 6", "the judges; Gideon"),
    ("RUT 1-2", "Ruth and Naomi"),
    ("RUT 3-4", "Ruth and Boaz"),
    ("1SA 3; 1SA 8", "Samuel; the people ask for a king"),
    ("1SA 16-17", "David anointed; Goliath"),
    ("2SA 7", "the promise to David"),
    ("2SA 11-12", "David and Bathsheba; Nathan"),
    ("1KI 3", "Solomon"),
    ("1KI 8:1-30", "the temple dedicated"),
    ("1KI 12", "the kingdom divided"),
    ("1KI 18", "Elijah on Carmel"),
    ("2KI 17:1-23", "Samaria falls"),
    ("2KI 22:1-23:3", "Josiah and the book of the law"),
    ("2KI 25", "Jerusalem falls"),
    ("DAN 6", "Daniel in exile"),
    ("EZR 1; EZR 3", "the return; the temple begun again"),
    ("NEH 8", "the law read in Jerusalem"),
    ("LUK 1:26-56", "Mary"),
    ("LUK 2:1-40", "Jesus born"),
    ("MRK 1", "Jesus' work begins"),
    ("MAT 5-7", "the Sermon on the Mount"),
    ("MRK 4:35-5:43", "the storm; healings"),
    ("MRK 8:27-9:13", "Peter's answer; the transfiguration"),
    ("LUK 15", "three parables of the lost"),
    ("JHN 11:1-44", "Lazarus"),
    ("LUK 19:1-44", "Zacchaeus; Jerusalem"),
    ("LUK 22", "the last supper; the arrest"),
    ("LUK 23", "the crucifixion"),
    ("LUK 24", "the resurrection"),
    ("ACT 1-2", "the ascension; Pentecost"),
    ("ACT 9:1-31", "Saul"),
    ("ACT 10", "Peter and Cornelius"),
    ("ACT 17", "Paul in Thessalonica, Berea and Athens"),
    ("ACT 28", "Paul in Rome"),
    ("REV 21-22", "the Bible's last two chapters"),
]

/// The letters that bear Paul's name, in printed order.
let paulsLetters = ["ROM", "1CO", "2CO", "GAL", "EPH", "PHP", "COL", "1TH", "2TH", "1TI", "2TI", "TIT", "PHM"]

func schedules() -> [Schedule] {
    let all = loadChapters()
    func chapters(of books: [String]) -> [Chapter] {
        books.flatMap { book in all.filter { $0.book == book } }
    }
    func words(_ list: [Chapter]) -> Int { list.reduce(0) { $0 + $1.words } }

    // Gospels at your pace: each Gospel on its own, in readings of about
    // 1,350 words.
    let gospels = ["MAT", "MRK", "LUK", "JHN"].flatMap { book -> [[Chapter]] in
        let own = chapters(of: [book])
        return balanced(own, into: rounded(words(own), over: gospelReadingWords))
    }

    // The Bible in a year: 365 readings shared between the testaments by
    // their words, each testament balanced on its own.
    let testaments = loadTestaments()
    let (old, new) = (chapters(of: testaments.old), chapters(of: testaments.new))
    guard old.count + new.count == all.count else { fail("the word counts and the canon disagree") }
    func year(in count: Int) -> [[Chapter]] {
        let newReadings = rounded(count * words(new), over: words(old) + words(new))
        return balanced(old, into: count - newReadings) + balanced(new, into: newReadings)
    }

    // Proverbs through the month: the chapter whose number is the day's.
    let proverbs = chapters(of: ["PRO"]).map { [$0] }
    guard proverbs.count == 31 else { fail("Proverbs does not have 31 chapters") }

    // The New Testament in a year, five days a week: its 260 chapters, one
    // a reading.
    guard new.count == fiveDayYearReadings else { fail("the New Testament does not have 260 chapters") }

    // A psalm a day: each psalm a reading, and Psalm 119 two stanzas at a
    // time.
    let psalms = chapters(of: ["PSA"]).flatMap { psalm -> [[Chapter]] in
        psalm.number == 119 ? psalm.sections(of: psalm119Section).map { [$0] } : [[psalm]]
    }
    guard chapters(of: ["PSA"]).first(where: { $0.number == 119 })?.verses.count == 176 else {
        fail("Psalm 119 does not have 176 verses")
    }

    // The Story of Scripture: the listed readings, each in its shortest
    // writing.
    let story = storyOfScripture.map { listed -> [Chapter] in
        let reading = passages(in: listed.reading, from: all)
        guard text(of: reading) == listed.reading else {
            fail("story-of-scripture: \(listed.reading) is written \(text(of: reading)) at its shortest")
        }
        return reading
    }

    return [
        Schedule(plan: "gospels-at-your-pace", readings: gospels),
        Schedule(plan: "bible-in-a-year", readings: year(in: yearReadings)),
        Schedule(plan: "proverbs-through-the-month", readings: proverbs),
        Schedule(plan: "bible-in-a-year-five-days", readings: year(in: fiveDayYearReadings)),
        Schedule(plan: "new-testament-in-a-year-five-days", readings: new.map { [$0] }),
        Schedule(plan: "psalm-a-day", readings: psalms),
        Schedule(plan: "pauls-letters", readings: chapters(of: paulsLetters).map { [$0] }),
        Schedule(plan: "story-of-scripture", readings: story),
    ]
}

/// A plan file's front matter, up to and including its "---" line.
func frontMatter(of plan: String) -> (url: URL, front: String, schedule: String) {
    let url = plansURL.appending(path: "\(plan).plan")
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { fail("cannot read \(url.path)") }
    guard let divider = text.range(of: "\n---\n") else { fail("\(plan).plan has no \"---\" line") }
    return (url, String(text[..<divider.upperBound]), String(text[divider.upperBound...]))
}

func lines(of schedule: Schedule) -> String {
    schedule.readings.enumerated().map { "\($0.offset + 1)\t\(text(of: $0.element))\n" }.joined()
}

guard CommandLine.arguments.count == 2 else { fail("usage: swift scripts/plans.swift generate|check|facts") }
switch CommandLine.arguments[1] {
case "generate":
    for schedule in schedules() {
        let file = frontMatter(of: schedule.plan)
        do {
            try (file.front + lines(of: schedule)).write(to: file.url, atomically: true, encoding: .utf8)
        } catch {
            fail("cannot write \(file.url.path): \(error)")
        }
        print("plans: wrote \(schedule.plan), \(schedule.readings.count) readings")
    }
case "check":
    let computed = schedules()
    for schedule in computed {
        let file = frontMatter(of: schedule.plan)
        guard file.schedule == lines(of: schedule) else {
            fail("\(schedule.plan).plan's schedule is not what its rule gives; run swift scripts/plans.swift generate")
        }
    }
    print("plans: \(computed.count) schedules are what their rules give")
case "facts":
    for schedule in schedules() {
        let words = schedule.readings.map { $0.reduce(0) { $0 + $1.words } }.sorted()
        let chapters = schedule.readings.map(\.count)
        print(
            "\(schedule.plan): \(schedule.readings.count) readings, \(chapters.reduce(0, +)) chapters, "
                + "\(words.reduce(0, +)) words; a reading has \(words.first!) to \(words.last!) words "
                + "(middle \(words[words.count / 2])) and \(chapters.min()!) to \(chapters.max()!) chapters")
    }
default:
    fail("usage: swift scripts/plans.swift generate|check|facts")
}
