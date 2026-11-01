/// A set of verses under one versification scheme, each counted once. It is
/// how Day by Word says what a plan or a reader's history covers: union,
/// intersection, and difference give unique coverage, repeats, and what is
/// left out, and each chapter it touches is whole or partly covered (P4.4,
/// P11.4).
public struct VerseSet: Hashable, Sendable {
    public let scheme: Versification.Scheme
    /// Each book's verses as sorted, separate runs of positions in the book
    /// (`Versification.position(of:in:)`), with no two runs touching.
    private var runs: [BookID: [Range<Int>]]

    public init(scheme: Versification.Scheme = .english) {
        self.scheme = scheme
        runs = [:]
    }

    public init(_ passage: Passage, in versification: Versification) {
        self.init(scheme: passage.scheme)
        insert(passage, in: versification)
    }

    public init(_ passages: some Sequence<Passage>, in versification: Versification) {
        self.init(scheme: versification.scheme)
        for passage in passages { insert(passage, in: versification) }
    }

    public mutating func insert(_ passage: Passage, in versification: Versification) {
        precondition(passage.scheme == scheme && versification.scheme == scheme, "one scheme per set")
        // A passage is checked against its scheme when it is made, so both ends
        // have positions.
        let first = versification.position(of: passage.start, in: passage.book)!
        let last = versification.position(of: passage.end, in: passage.book)!
        runs[passage.book] = Self.union(runs[passage.book] ?? [], [first..<(last + 1)])
    }

    public var isEmpty: Bool { runs.isEmpty }

    /// How many verses the set holds.
    public var count: Int { runs.values.reduce(0) { $0 + $1.reduce(0) { $0 + $1.count } } }

    /// How many verses of the book the set holds.
    public func count(in book: BookID) -> Int { runs[book]?.reduce(0) { $0 + $1.count } ?? 0 }

    public var books: Set<BookID> { Set(runs.keys) }

    public func contains(_ book: BookID, _ place: ChapterVerse, in versification: Versification) -> Bool {
        guard let position = versification.position(of: place, in: book), let runs = runs[book] else { return false }
        return runs.contains { $0.contains(position) }
    }

    public func union(_ other: VerseSet) -> VerseSet {
        combine(other) { Self.union($0, $1) }
    }

    public func intersection(_ other: VerseSet) -> VerseSet {
        combine(other) { Self.intersection($0, $1) }
    }

    public func subtracting(_ other: VerseSet) -> VerseSet {
        combine(other) { Self.difference($0, $1) }
    }

    /// The verses given more than once among the passages, as a plan's
    /// repeats or a reader's rereadings.
    public static func repeats(in passages: some Sequence<Passage>, in versification: Versification) -> VerseSet {
        var seen = VerseSet(scheme: versification.scheme)
        var repeated = seen
        for passage in passages {
            let verses = VerseSet(passage, in: versification)
            repeated = repeated.union(seen.intersection(verses))
            seen = seen.union(verses)
        }
        return repeated
    }

    /// The set as the fewest passages, in the scheme's book order: what a
    /// plan leaves out, for example, shown as "Genesis 1:1–2:3".
    public func passages(in versification: Versification) -> [Passage] {
        precondition(versification.scheme == scheme, "one scheme per set")
        return versification.books.flatMap { book in
            (runs[book] ?? []).map { run in
                try! Passage(
                    book, from: versification.place(at: run.lowerBound, in: book)!,
                    to: versification.place(at: run.upperBound - 1, in: book)!, in: versification)
            }
        }
    }

    /// One chapter the set touches: how many of its verses the set holds.
    public struct ChapterCoverage: Hashable, Sendable {
        public let book: BookID
        public let chapter: Int
        public let covered: Int
        public let verses: Int

        public var isWhole: Bool { covered == verses }
    }

    /// Every chapter the set touches, whole or in part, in the scheme's book
    /// order. A chapter with even one verse in the set is listed, so a partly
    /// read chapter is never counted as read.
    public func chapters(in versification: Versification) -> [ChapterCoverage] {
        precondition(versification.scheme == scheme, "one scheme per set")
        return versification.books.flatMap { book -> [ChapterCoverage] in
            guard let runs = runs[book], let chapters = versification.chapters(of: book) else { return [] }
            return chapters.compactMap { chapter in
                let verses = versification.verses(of: book, chapter: chapter)!
                let first = versification.position(of: ChapterVerse(chapter, verses.lowerBound), in: book)!
                let covered = Self.intersection(runs, [first..<(first + verses.count)]).reduce(0) { $0 + $1.count }
                return covered == 0
                    ? nil : ChapterCoverage(book: book, chapter: chapter, covered: covered, verses: verses.count)
            }
        }
    }

    private func combine(_ other: VerseSet, _ operation: ([Range<Int>], [Range<Int>]) -> [Range<Int>]) -> VerseSet {
        precondition(other.scheme == scheme, "one scheme per set")
        var result = VerseSet(scheme: scheme)
        for book in books.union(other.books) {
            let runs = operation(self.runs[book] ?? [], other.runs[book] ?? [])
            if !runs.isEmpty { result.runs[book] = runs }
        }
        return result
    }

    // MARK: Runs

    /// Sorted, separate runs covering every position in either list.
    private static func union(_ a: [Range<Int>], _ b: [Range<Int>]) -> [Range<Int>] {
        var result: [Range<Int>] = []
        for run in (a + b).sorted(by: { $0.lowerBound < $1.lowerBound }) {
            if let last = result.last, run.lowerBound <= last.upperBound {
                result[result.count - 1] = last.lowerBound..<max(last.upperBound, run.upperBound)
            } else {
                result.append(run)
            }
        }
        return result
    }

    /// The positions in both lists, each sorted and separate.
    private static func intersection(_ a: [Range<Int>], _ b: [Range<Int>]) -> [Range<Int>] {
        var result: [Range<Int>] = []
        var (i, j) = (0, 0)
        while i < a.count && j < b.count {
            let overlap = a[i].clamped(to: b[j])
            if !overlap.isEmpty { result.append(overlap) }
            if a[i].upperBound < b[j].upperBound { i += 1 } else { j += 1 }
        }
        return result
    }

    /// The positions in the first list and not the second, each sorted and
    /// separate.
    private static func difference(_ a: [Range<Int>], _ b: [Range<Int>]) -> [Range<Int>] {
        var result: [Range<Int>] = []
        var j = 0
        for run in a {
            var start = run.lowerBound
            while j < b.count && b[j].upperBound <= start { j += 1 }
            var k = j
            while k < b.count && b[k].lowerBound < run.upperBound {
                if b[k].lowerBound > start { result.append(start..<b[k].lowerBound) }
                start = max(start, b[k].upperBound)
                k += 1
            }
            if start < run.upperBound { result.append(start..<run.upperBound) }
        }
        return result
    }
}
