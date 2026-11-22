import ReadingEngine
import SwiftUI
import UIKit

/// A plan's week as a checklist (BUILD.md P8.10b, P13.1): the plan and its
/// label, seven days with a box to tick beside each reading, and the
/// plan's source note. The same view is the screen and the page of the PDF
/// the share sheet sends, in ordinary or large print.
struct WeekChecklist: View {
    let title: String
    /// "By Day by Word · Read in order".
    let label: String
    /// What the week is: the plan's first week, or the days appointed.
    let note: String
    let days: [(date: CivilDate, references: [ReferenceText])]
    let source: String
    var large = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            header
            ForEach(days, id: \.date) { day in row(day) }
            footer
        }
    }

    /// The plan, its label, and what the week is.
    var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(verbatim: title)
                .typeStyle(large ? TypeScale.planTitle : TypeStyle(size: 22, weight: .bold, relativeTo: .title2))
                .foregroundStyle(Palette.text)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: label)
                .typeStyle(text(TypeScale.label))
                .foregroundStyle(Palette.textMuted)
            Text(verbatim: note)
                .typeStyle(text(TypeScale.body))
                .foregroundStyle(Palette.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, Spacing.xs)
    }

    /// One day: its date, and each reading with a box to tick, or "Rest day".
    func row(_ day: (date: CivilDate, references: [ReferenceText])) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider().overlay(Palette.line)
            Text(verbatim: PlanPresentation.dayText(day.date))
                .typeStyle(text(TypeScale.label))
                .foregroundStyle(Palette.textMuted)
            if day.references.isEmpty {
                Text("Rest day").typeStyle(text(TypeScale.body)).foregroundStyle(Palette.textMuted)
            }
            ForEach(day.references, id: \.display) { reference in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                    Image(systemName: "square")
                        .font(.system(size: large ? 26 : 20))
                        .foregroundStyle(Palette.textMuted)
                        .accessibilityHidden(true)
                    Text(verbatim: reference.unbroken)
                        .typeStyle(
                            large ? TypeStyle(size: 28, weight: .semibold, relativeTo: .title) : TypeScale.referenceList
                        )
                        .foregroundStyle(Palette.text)
                        .accessibilityLabel(reference.spoken)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// How to use it, and where the plan comes from.
    var footer: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Divider().overlay(Palette.line)
            Text("Tick each reading as you read it.")
                .typeStyle(text(TypeScale.caption))
                .foregroundStyle(Palette.textMuted)
            Text("**Source.** \(source)")
                .typeStyle(text(TypeScale.caption))
                .foregroundStyle(Palette.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// A step of the type scale, raised for large print: about 18-point
    /// text and 15-point notes, as on the web.
    private func text(_ style: TypeStyle) -> TypeStyle {
        guard large else { return style }
        return TypeStyle(size: max(style.size + 7, 20), weight: style.weight, relativeTo: style.relativeTo)
    }
}

/// The checklist as a PDF to share or print: US Letter where the device
/// measures in inches, A4 elsewhere, with 0.75-inch margins. Days are never
/// split across pages; a day that does not fit starts the next page.
@MainActor
enum WeekPDF {
    static let margin: CGFloat = 54

    /// The page size for the device's region.
    static var pageSize: CGSize {
        Locale.current.measurementSystem == .us ? CGSize(width: 612, height: 792) : CGSize(width: 595, height: 842)
    }

    /// Writes the checklist to a PDF in the temporary folder and returns it.
    static func file(_ checklist: WeekChecklist, named name: String, page: CGSize = pageSize) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(name).pdf")
        var box = CGRect(origin: .zero, size: page)
        guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { throw WeekPDFError.cannotWrite }
        let width = page.width - 2 * margin
        let usable = page.height - 2 * margin
        var y: CGFloat = 0
        context.beginPDFPage(nil)
        var blocks: [AnyView] = [AnyView(checklist.header)]
        blocks += checklist.days.map { AnyView(checklist.row($0)) }
        blocks.append(AnyView(checklist.footer))
        for block in blocks {
            let renderer = ImageRenderer(
                content:
                    block
                    .frame(width: width, alignment: .leading)
                    // Paper is light, whatever the screen is (docs/design.md).
                    .environment(\.colorScheme, .light)
                    .environment(\.dynamicTypeSize, .large))
            renderer.proposedSize = ProposedViewSize(width: width, height: nil)
            renderer.render { size, draw in
                if y > 0, y + size.height > usable {
                    context.endPDFPage()
                    context.beginPDFPage(nil)
                    y = 0
                }
                context.saveGState()
                context.translateBy(x: margin, y: page.height - margin - y - size.height)
                draw(context)
                context.restoreGState()
                y += size.height + Spacing.s
            }
        }
        context.endPDFPage()
        context.closePDF()
        return url
    }
}

enum WeekPDFError: Error, CustomStringConvertible {
    case cannotWrite

    var description: String { "The checklist could not be made into a PDF." }
}
