/// Shows a reading as the reader sees it, under their naming convention
/// (D29): "John 3:1–21", "Genesis 1–2", "Psalm 119:1–24; Psalm 120", or,
/// abbreviated, "Gen 1–2". Ranges take an en dash. Whole chapters are shown
/// as chapters, a single psalm is "Psalm", and a one-chapter book is cited by
/// its verses alone ("Jude 3–5", or "Jude" for the whole book), by app
/// convention (docs/decisions.md E30).
public struct ReferenceFormatter: Sendable {
    public enum Style: Sendable {
        case full
        case abbreviated
    }

    public let registry: BookRegistry
    public let versification: Versification
    public let convention: NamingConvention

    public init(registry: BookRegistry, versification: Versification, convention: NamingConvention = .common) {
        self.registry = registry
        self.versification = versification
        self.convention = convention
    }

    public func string(for reading: Reading, style: Style = .full) -> String {
        reading.passages.map { string(for: $0, style: style) }.joined(separator: "; ")
    }

    public func string(for passage: Passage, style: Style = .full) -> String {
        let (start, end) = (passage.start, passage.end)
        let oneChapterBook = versification.chapters(of: passage.book)?.count == 1
        let name = bookName(passage.book, style: style, onePsalm: start.chapter == end.chapter)
        let range: String? =
            if passage.isWholeChapters(in: versification) {
                if oneChapterBook {
                    nil
                } else if start.chapter == end.chapter {
                    "\(start.chapter)"
                } else {
                    "\(start.chapter)\(Self.dash)\(end.chapter)"
                }
            } else if oneChapterBook {
                start == end ? "\(start.verse)" : "\(start.verse)\(Self.dash)\(end.verse)"
            } else if start == end {
                "\(start)"
            } else if start.chapter == end.chapter {
                "\(start)\(Self.dash)\(end.verse)"
            } else {
                "\(start)\(Self.dash)\(end)"
            }
        return range.map { "\(name) \($0)" } ?? name
    }

    private func bookName(_ id: BookID, style: Style, onePsalm: Bool) -> String {
        guard let names = registry.book(id)?.name(in: convention) else { return id.rawValue }
        switch style {
        case .abbreviated: return names.abbreviation ?? names.name
        case .full: return id == Self.psalms && onePsalm && names.name == "Psalms" ? "Psalm" : names.name
        }
    }

    private static let dash = "\u{2013}"
    private static let psalms = BookID("PSA")!
}
