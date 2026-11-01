import SwiftUI
import UIKit

// The app's shared components (BUILD.md P2.6), in the Morning design
// (docs/design.md). The web has the same set (Server/.../Components.swift).

// MARK: - Cards and buttons

extension View {
    /// A card: the surface color, a hairline border, and rounded corners.
    func card(padding: CGFloat = Spacing.l) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.line))
    }
}

/// The one thing to do next on a screen: a dawn-colored pill.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typeStyle(TypeStyle(size: 17, weight: .semibold, relativeTo: .body))
            .foregroundStyle(Palette.onAccent)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.xxs)
            .background(Palette.accent, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// Every other action: a soft, neutral pill. Stacked in an `ActionRow`, it
/// spans the row.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SecondaryButton(configuration: configuration)
    }

    private struct SecondaryButton: View {
        let configuration: Configuration
        @Environment(\.actionsStacked) private var stacked

        var body: some View {
            configuration.label
                .typeStyle(TypeStyle(size: 15, weight: .medium, relativeTo: .subheadline))
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.center)
                .frame(maxWidth: stacked ? .infinity : nil, minHeight: 44)
                .padding(.horizontal, Spacing.m + 2)
                .padding(.vertical, Spacing.xxs)
                .background(Palette.surfaceSoft, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .opacity(configuration.isPressed ? 0.7 : 1)
        }
    }
}

extension EnvironmentValues {
    /// Whether an `ActionRow` has stacked its actions vertically.
    @Entry var actionsStacked = false
}

/// Secondary actions side by side when they fit, and stacked at full width
/// when they do not (large text, narrow screens), so no label breaks mid-word.
struct ActionRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.xs) { content.fixedSize() }
            VStack(spacing: Spacing.xs) { content }
                .environment(\.actionsStacked, true)
        }
    }
}

// MARK: - References

/// A reference as it is shown ("Mark 4:1–20") and as VoiceOver reads it
/// ("Mark, chapter 4, verses 1 to 20"). ReadingEngine's formatter produces both
/// (BUILD.md P3.4); views only display them.
struct ReferenceText: Hashable, Sendable {
    let display: String
    let spoken: String

    /// The display text with word joiners around range dashes, so "4:1–20"
    /// never breaks across lines at the dash.
    var unbroken: String {
        display.replacingOccurrences(of: "–", with: "\u{2060}–\u{2060}")
    }
}

/// A reference set large enough to read from across a desk: selectable, and read
/// naturally by VoiceOver.
struct ReferenceBlock: View {
    let reference: ReferenceText
    var style = TypeScale.reference

    var body: some View {
        Text(verbatim: reference.unbroken)
            .typeStyle(style)
            .tracking(-0.4)
            .foregroundStyle(Palette.text)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .accessibilityLabel(reference.spoken)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Copies a reference's text for pasting into any Bible app or website.
struct CopyReferenceButton: View {
    let reference: ReferenceText
    @State private var copied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = reference.display
            copied = true
        } label: {
            Text(copied ? "Copied" : "Copy reference")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityHint(Text("Copies \(reference.spoken)"))
    }
}

// MARK: - Reading status

/// How a reading stands, always in words and a symbol as well as color, so color
/// never carries the meaning alone (docs/product.md).
enum ReadingStatus: CaseIterable, Sendable {
    case read
    case partlyRead
    case skipped
    case unread

    var label: LocalizedStringResource {
        switch self {
        case .read: "Read"
        case .partlyRead: "Part read"
        case .skipped: "Skipped"
        case .unread: "Not yet read"
        }
    }

    var symbol: String {
        switch self {
        case .read: "✓"
        case .partlyRead: "◐"
        case .skipped: "↷"
        case .unread: "○"
        }
    }
}

/// One reading in a list: its label, its reference, and its status.
struct AssignmentRow: View {
    let label: String
    let reference: ReferenceText
    let status: ReadingStatus

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(verbatim: label)
                    .typeStyle(TypeScale.caption)
                    .foregroundStyle(Palette.textMuted)
                Text(verbatim: reference.unbroken)
                    .typeStyle(TypeScale.referenceList)
                    .foregroundStyle(Palette.text)
            }
            Spacer(minLength: Spacing.s)
            Text("\(status.symbol) \(Text(status.label))")
                .typeStyle(TypeScale.label)
                .foregroundStyle(status == .read ? Palette.text : Palette.textMuted)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(label), \(reference.spoken), \(Text(status.label))"))
    }
}

// MARK: - Plans

/// "About 12 minutes. Estimates vary." Time estimates are always approximate,
/// and the app says so (AGENTS.md §3).
struct WorkloadLine: View {
    let minutes: Int

    var body: some View {
        Text(Self.text(minutes: minutes))
            .typeStyle(TypeScale.caption)
            .foregroundStyle(Palette.textMuted)
    }

    nonisolated static func text(minutes: Int) -> LocalizedStringResource {
        minutes == 1 ? "About 1 minute. Estimates vary." : "About \(minutes) minutes. Estimates vary."
    }
}

/// A plan in a list: what it is, what it covers, and its workload.
struct PlanCard: View {
    let title: String
    let kind: String
    let summary: String
    let minutes: Int
    let schedule: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(verbatim: kind)
                .typeStyle(TypeScale.label)
                .foregroundStyle(Palette.textMuted)
            Text(verbatim: title)
                .typeStyle(TypeStyle(size: 22, weight: .bold, relativeTo: .title2))
                .foregroundStyle(Palette.text)
            Text(verbatim: summary)
                .typeStyle(TypeScale.body)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Spacing.xs) {
                WorkloadLine(minutes: minutes)
                Text(verbatim: "·").foregroundStyle(Palette.textMuted).accessibilityHidden(true)
                Text(verbatim: schedule)
                    .typeStyle(TypeScale.caption)
                    .foregroundStyle(Palette.textMuted)
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}

/// Where a plan comes from, in a sentence or two.
struct SourceNote: View {
    let text: String

    var body: some View {
        Text("**Source.** \(text)")
            .typeStyle(TypeScale.caption)
            .foregroundStyle(Palette.textMuted)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A plan's sample week: the first few readings, so the reader can see the
/// workload before starting.
struct SampleWeek: View {
    let readings: [(label: String, reference: ReferenceText)]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("A sample week")
                .typeStyle(TypeStyle(size: 15, weight: .bold, relativeTo: .headline))
                .foregroundStyle(Palette.text)
                .accessibilityAddTraits(.isHeader)
            ForEach(readings, id: \.label) { reading in
                HStack {
                    Text(verbatim: reading.label).foregroundStyle(Palette.textMuted)
                    Spacer()
                    Text(verbatim: reading.reference.display).fontWeight(.semibold).foregroundStyle(Palette.text)
                }
                .typeStyle(TypeScale.caption)
                .padding(.vertical, Spacing.xxs)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: "\(reading.label), \(reading.reference.spoken)"))
            }
        }
        .card(padding: Spacing.m)
    }
}

// MARK: - Changes, undo, and states

/// One line of a preview: what changes, from what, to what.
struct PreviewedChange: Hashable, Sendable {
    let what: String
    let before: String
    let after: String
}

/// Shows exactly what a change will do before anything changes (docs/product.md).
/// Nothing happens until the reader confirms.
struct ChangePreview: View {
    let title: String
    let explanation: String
    let changes: [PreviewedChange]
    let confirmLabel: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(verbatim: title)
                .typeStyle(TypeScale.planTitle)
                .foregroundStyle(Palette.text)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: explanation)
                .typeStyle(TypeScale.body)
                .foregroundStyle(Palette.text)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(changes, id: \.self) { change in
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(verbatim: change.what)
                            .typeStyle(TypeScale.label)
                            .foregroundStyle(Palette.textMuted)
                        Text("\(change.before) → \(change.after)")
                            .typeStyle(TypeScale.body)
                            .foregroundStyle(Palette.text)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("\(change.what): from \(change.before) to \(change.after)"))
                }
            }
            .card(padding: Spacing.m)
            Button(confirmLabel, action: onConfirm).buttonStyle(PrimaryButtonStyle())
            Button("Cancel", action: onCancel)
                .buttonStyle(SecondaryButtonStyle())
                .frame(maxWidth: .infinity)
        }
        .padding(Spacing.l)
        .background(Palette.background)
    }
}

/// A quiet confirmation with an Undo button, shown after the reader acts.
struct UndoBanner: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: Spacing.s) {
            Text(verbatim: message)
                .typeStyle(TypeScale.body)
                .foregroundStyle(Palette.text)
            Spacer(minLength: Spacing.xs)
            Button("Undo", action: onUndo)
                .typeStyle(TypeStyle(size: 17, weight: .semibold, relativeTo: .body))
                .foregroundStyle(Palette.accent)
                .frame(minHeight: 44)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.xxs)
        .background(Palette.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Palette.line))
        .accessibilityElement(children: .contain)
    }
}

/// What a screen shows when it has nothing yet, is waiting, is offline, or met
/// an error. Each says plainly what is happening and what the reader can do.
struct StateMessage: View {
    enum Kind {
        case empty(title: String, message: String)
        case loading
        case offline
        case error(message: String, retry: () -> Void)
    }

    let kind: Kind

    var body: some View {
        VStack(spacing: Spacing.s) {
            switch kind {
            case .empty(let title, let message):
                Text(verbatim: title).typeStyle(TypeScale.referenceList).foregroundStyle(Palette.text)
                Text(verbatim: message).typeStyle(TypeScale.body).foregroundStyle(Palette.textMuted)
            case .loading:
                ProgressView().tint(Palette.textMuted)
                Text("Loading…").typeStyle(TypeScale.body).foregroundStyle(Palette.textMuted)
            case .offline:
                Text("You're offline").typeStyle(TypeScale.referenceList).foregroundStyle(Palette.text)
                Text("Your plans and reading record are on this device and work without a connection.")
                    .typeStyle(TypeScale.body)
                    .foregroundStyle(Palette.textMuted)
            case .error(let message, let retry):
                Text("Something went wrong").typeStyle(TypeScale.referenceList).foregroundStyle(Palette.text)
                Text(verbatim: message).typeStyle(TypeScale.body).foregroundStyle(Palette.danger)
                Button("Try again", action: retry).buttonStyle(SecondaryButtonStyle())
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
    }
}
