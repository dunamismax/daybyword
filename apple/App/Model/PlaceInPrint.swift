import Foundation
import ReadingEngine

/// Where a reading is in a printed Bible, for physical Bible mode
/// (docs/product.md): the book, then the chapter and verses called out, so
/// the reader can find the place by the running heads and chapter numbers
/// ("Mark · chapter 4 · verses 1–20").
enum PlaceInPrint {
    static func lines(_ reading: Reading, formatter: ReferenceFormatter) -> [String] {
        reading.passages.map { line($0, formatter: formatter) }
    }

    static func line(_ passage: Passage, formatter: ReferenceFormatter) -> String {
        let (start, end) = (passage.start, passage.end)
        let book =
            formatter.registry.book(passage.book)?.name(in: formatter.convention).name ?? passage.book.rawValue
        let oneChapterBook = formatter.versification.chapters(of: passage.book)?.count == 1
        let dash = "\u{2013}"
        if passage.isWholeChapters(in: formatter.versification) {
            if oneChapterBook { return book }
            return start.chapter == end.chapter
                ? String(localized: "\(book) · chapter \(start.chapter)")
                : String(localized: "\(book) · chapters \(start.chapter)\(dash)\(end.chapter)")
        }
        if start.chapter != end.chapter {
            return String(
                localized:
                    "\(book) · chapter \(start.chapter), verse \(start.verse) to chapter \(end.chapter), verse \(end.verse)"
            )
        }
        let verses =
            start.verse == end.verse
            ? String(localized: "verse \(start.verse)")
            : String(localized: "verses \(start.verse)\(dash)\(end.verse)")
        if oneChapterBook { return "\(book) · \(verses)" }
        return String(localized: "\(book) · chapter \(start.chapter) · \(verses)")
    }
}
