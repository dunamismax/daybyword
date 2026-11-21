/// The reading engine: references, schedules, progress, and reminder rules.
///
/// `ReadingEngine` is the Swift runtime of `docs/engine.md`, used by the app,
/// its extensions, and the catalog compiler; the web's TypeScript module
/// (`web/src/lib/domain/`) is the other, and both answer the same shared cases
/// in `tests/fixtures/` (docs/decisions.md E33). Nothing else reimplements it.
public enum ReadingEngine {
    /// The version of `docs/engine.md` this build implements. Version 0 covers
    /// references, verse sets, word counts, and workload; version 1 adds
    /// civil dates, the journal, the three behaviors, returning, progress and
    /// reminders (P5.1 to P5.12). The web module states the same version.
    public static let specificationVersion = 1
}
