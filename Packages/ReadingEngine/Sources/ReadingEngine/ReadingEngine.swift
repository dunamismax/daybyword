/// The reading engine: references, schedules, progress, and reminder rules.
///
/// `ReadingEngine` is the single implementation of Day by Word's reading logic
/// (docs/decisions.md E4). The app, its extensions, the server, and the catalog
/// compiler all use it, and nothing else reimplements it. `docs/engine.md`
/// specifies it (BUILD.md P5.1), and its table-driven cases pin it.
public enum ReadingEngine {
    /// The version of `docs/engine.md` this build implements. It is 0 until the
    /// specification is written (BUILD.md P5.1).
    public static let specificationVersion = 0
}
