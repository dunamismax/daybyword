/// How long a reading takes, estimated from its words at the adult English
/// rates of Brysbaert's 2019 meta-analysis: about 238 words a minute read
/// silently and 183 read aloud (Research finding 6). An estimate only:
/// reflection, reading aloud slowly, and listening all change it, and the
/// reader is told so ("About 9–11 minutes. Estimates vary.", docs/product.md).
public struct Workload: Hashable, Sendable {
    public static let silentWordsPerMinute = 238.0
    public static let aloudWordsPerMinute = 183.0

    public let words: Int

    public init(words: Int) {
        precondition(words >= 0, "a word count is never negative")
        self.words = words
    }

    public var silentMinutes: Double { Double(words) / Self.silentWordsPerMinute }
    public var aloudMinutes: Double { Double(words) / Self.aloudWordsPerMinute }

    /// The estimate as the reader sees it, from reading silently to reading
    /// aloud, in whole minutes: never less than one, to the nearest minute
    /// below twenty, and to the nearest five from there, so it never looks
    /// more exact than it is. The two ends may round to the same number
    /// ("About 2 minutes").
    public var minutes: ClosedRange<Int> {
        let low = Self.rounded(silentMinutes)
        return low...max(low, Self.rounded(aloudMinutes))
    }

    static func rounded(_ minutes: Double) -> Int {
        if minutes < 20 { return max(1, Int(minutes.rounded())) }
        return Int((minutes / 5).rounded()) * 5
    }
}

/// A plan's workload across its readings: the lightest, the middle, and the
/// heaviest, which the plan page shows (BUILD.md P9.4).
public struct PlanWorkload: Hashable, Sendable {
    public let minimum: Workload
    /// The middle reading's words, or the average of the two middle readings'
    /// words, rounded, when there is an even number of readings.
    public let median: Workload
    public let maximum: Workload

    /// Nil for a plan with no readings.
    public init?(words: [Int]) {
        guard !words.isEmpty else { return nil }
        let sorted = words.sorted()
        let middle = sorted.count / 2
        minimum = Workload(words: sorted[0])
        maximum = Workload(words: sorted[sorted.count - 1])
        median = Workload(
            words: sorted.count.isMultiple(of: 2)
                ? Int((Double(sorted[middle - 1] + sorted[middle]) / 2).rounded()) : sorted[middle])
    }

    /// The workload of each reading, counted from the word counts, or nil if
    /// there are no readings or a reading's book is not counted.
    public init?(readings: [Reading], counts: WordCounts) {
        var words: [Int] = []
        for reading in readings {
            guard let count = counts.words(in: reading) else { return nil }
            words.append(count)
        }
        self.init(words: words)
    }
}
