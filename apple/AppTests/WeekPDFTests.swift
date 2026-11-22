import Foundation
import PDFKit
import ReadingData
import ReadingEngine
import Testing

@testable import DayByWord

/// The week's checklist as a PDF (BUILD.md P13.1, P13.5): the page size, the
/// readings as text, large print, and days that never split across pages.
@MainActor
private func checklist(_ plan: String, from start: String, large: Bool) throws -> WeekChecklist {
    let url = try #require(Bundle.main.url(forResource: "Catalog", withExtension: "sqlite"))
    let catalog = try Catalog(path: url.path)
    let entry = try #require(catalog.plan(PlanID(plan)!))
    let presented = PlanPresentation(catalog: catalog, plan: entry)
    return WeekChecklist(
        title: entry.title, label: "\(presented.byline) · \(presented.kind)", note: "A week.",
        days: presented.week(from: try CivilDate(start)), source: entry.source, large: large)
}

private let letter = CGSize(width: 612, height: 792)

@MainActor
@Test func aWeekIsOneLetterPageWithItsReadingsAsText() throws {
    // Monday 4 January 2027: five readings, then two rest days.
    let week = try checklist("gospels-at-your-pace", from: "2027-01-04", large: false)
    let url = try WeekPDF.file(week, named: "test-week", page: letter)
    let document = try #require(PDFDocument(url: url))
    #expect(document.pageCount == 1)
    let page = try #require(document.page(at: 0))
    #expect(page.bounds(for: .mediaBox).size == letter)
    let text = try #require(document.string)
    #expect(text.contains("Gospels at your pace"))
    for reference in ["Matthew 1", "Matthew 4", "Matthew 10"] { #expect(text.contains(reference)) }
    #expect(text.contains("Rest day"))
    #expect(text.contains("Tick each reading as you read it."))
    #expect(text.contains("Source."))
}

@MainActor
@Test func largePrintKeepsEveryDayWholeAcrossPages() throws {
    let ordinary = try WeekPDF.file(
        try checklist("bible-in-a-year", from: "2027-01-04", large: false), named: "test-ordinary", page: letter)
    let large = try WeekPDF.file(
        try checklist("bible-in-a-year", from: "2027-01-04", large: true), named: "test-large", page: letter)
    let small = try #require(PDFDocument(url: ordinary))
    let big = try #require(PDFDocument(url: large))
    #expect(big.pageCount >= small.pageCount)
    // A small page forces breaks: each day's date and its readings stay on
    // one page, and nothing is lost.
    let tight = try WeekPDF.file(
        try checklist("bible-in-a-year", from: "2027-01-04", large: true), named: "test-tight",
        page: CGSize(width: 612, height: 400))
    let pages = try #require(PDFDocument(url: tight))
    #expect(pages.pageCount > 1)
    let all = (0..<pages.pageCount).compactMap { pages.page(at: $0)?.string }
    for day in ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"] {
        let holding = all.filter { $0.contains(day) }
        #expect(holding.count == 1, "\(day) is on \(holding.count) pages")
        #expect(holding.first?.contains("Genesis") == true || holding.first?.contains("Exodus") == true)
    }
}
