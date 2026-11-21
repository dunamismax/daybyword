import Foundation
import ReadingEngine

extension ReferenceText {
    /// A reading as it is shown ("Mark 4:1–20", from the engine's formatter)
    /// and as VoiceOver says it ("Mark, chapter 4, verses 1 to 20"), the
    /// same words the web uses (web/src/lib/reference.ts).
    init(_ reading: Reading, formatter: ReferenceFormatter) {
        let spoken = reading.passages.map { Self.spoken($0, formatter: formatter) }
        self.init(
            display: formatter.string(for: reading),
            spoken: spoken.dropFirst().reduce(spoken.first ?? "") { first, next in
                String(localized: "\(first); then \(next)")
            })
    }

    /// "Mark, chapter 4, verses 1 to 20", "Matthew, chapters 1 to 3", "Psalm
    /// 23", "Jude".
    static func spoken(_ passage: Passage, formatter: ReferenceFormatter) -> String {
        let (start, end) = (passage.start, passage.end)
        let book =
            formatter.registry.book(passage.book)?.name(in: formatter.convention).name ?? passage.book.rawValue
        let oneChapterBook = formatter.versification.chapters(of: passage.book)?.count == 1
        let (chapter, verse) = (start.chapter, start.verse)
        if passage.isWholeChapters(in: formatter.versification) {
            if oneChapterBook { return book }
            if passage.book.rawValue == "PSA" && book == "Psalms" {
                return start.chapter == end.chapter
                    ? String(localized: "Psalm \(chapter)")
                    : String(localized: "Psalms \(chapter) to \(end.chapter)")
            }
            return start.chapter == end.chapter
                ? String(localized: "\(book), chapter \(chapter)")
                : String(localized: "\(book), chapters \(chapter) to \(end.chapter)")
        }
        if start.chapter != end.chapter {
            return String(
                localized: "\(book), chapter \(chapter), verse \(verse), to chapter \(end.chapter), verse \(end.verse)")
        }
        let one = start.verse == end.verse
        if oneChapterBook {
            return one
                ? String(localized: "\(book), verse \(verse)")
                : String(localized: "\(book), verses \(verse) to \(end.verse)")
        }
        return one
            ? String(localized: "\(book), chapter \(chapter), verse \(verse)")
            : String(localized: "\(book), chapter \(chapter), verses \(verse) to \(end.verse)")
    }
}
