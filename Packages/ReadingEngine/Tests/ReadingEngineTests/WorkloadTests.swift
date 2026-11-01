import ReadingEngine
import Testing

@Test(
    arguments: [
        // Words, minutes silent to aloud as the reader sees them.
        (0, 1...1),
        (25, 1...1),  // Psalm 117
        (238, 1...1),
        (400, 2...2),  // 1.7 and 2.2 minutes
        (500, 2...3),  // 2.1 and 2.7
        (2_067, 9...11),  // the Bible in a year, on average: 8.7 and 11.3
        (2_380, 10...13),  // 10.0 and 13.0
        (4_000, 17...20),  // 16.8 and 21.9
        (4_500, 19...25),  // 18.9 and 24.6
        (9_000, 40...50),  // 37.8 and 49.2
    ] as [(Int, ClosedRange<Int>)])
func workloadsAreRoundedRanges(words: Int, minutes: ClosedRange<Int>) {
    #expect(Workload(words: words).minutes == minutes)
}

@Test func workloadsUseBrysbaertsRates() {
    let workload = Workload(words: 2_380)
    #expect(workload.silentMinutes == 10)
    #expect(abs(workload.aloudMinutes - 13.005) < 0.001)
}

@Test(
    arguments: [
        // Each reading's words, then the minimum, median, and maximum.
        ([300], 300, 300, 300),
        ([500, 100, 300], 100, 300, 500),
        ([400, 100, 300, 200], 100, 250, 400),
        ([1, 2], 1, 2, 2),  // 1.5 rounds to 2
    ] as [([Int], Int, Int, Int)])
func plansHaveALightestMiddleAndHeaviestReading(words: [Int], minimum: Int, median: Int, maximum: Int) throws {
    let workload = try #require(PlanWorkload(words: words))
    #expect([workload.minimum.words, workload.median.words, workload.maximum.words] == [minimum, median, maximum])
}

@Test func plansAreCountedFromTheirReadings() throws {
    let english = try loadEnglish()
    let counts = try loadWordCounts()
    let readings = try ["PSA 117", "GEN 1:1-2", "PSA 117; PSA 117"].map { try ReferenceFormat.reading($0, in: english) }
    let workload = try #require(PlanWorkload(readings: readings, counts: counts))
    #expect([workload.minimum.words, workload.median.words, workload.maximum.words] == [25, 35, 50])
    #expect(PlanWorkload(readings: [], counts: counts) == nil)
    #expect(PlanWorkload(readings: [try ReferenceFormat.reading("TOB 1", in: english)], counts: counts) == nil)
}
