import ReadingEngine
import Testing

/// docs/engine.md's version 1: scheduling, the journal, progress and
/// reminders, beside version 0's references (a web test checks that the
/// specification, this runtime and the TypeScript one state the same).
@Test func implementsSpecificationVersionOne() {
    #expect(ReadingEngine.specificationVersion == 1)
}
