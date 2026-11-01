// Generated from design/tokens.json by scripts/tokens.swift. Do not edit.

import SwiftUI

/// The design's colors (docs/design.md). Each follows light and dark mode.
enum Palette {
    /// The dawn accent: the primary action, today's date, the next reading's plan label, and links.
    static let accent = Color("Accent")
    /// The selected section and quiet celebrations; text on it is always text, never accent.
    static let accentTint = Color("AccentTint")
    /// The page or screen behind everything.
    static let background = Color("Background")
    /// Error messages only.
    static let danger = Color("Danger")
    /// Hairline borders around cards; never text.
    static let line = Color("Line")
    /// Text and symbols on the accent.
    static let onAccent = Color("OnAccent")
    /// Cards and the tab bar.
    static let surface = Color("Surface")
    /// Secondary buttons, chips, and day cells.
    static let surfaceSoft = Color("SurfaceSoft")
    /// Body text and references.
    static let text = Color("Text")
    /// Secondary text: labels, estimates, captions.
    static let textMuted = Color("TextMuted")
}

/// Corner radii, in points.
enum Radius {
    static let chip: CGFloat = 18
    static let card: CGFloat = 24
    static let cardLarge: CGFloat = 28
    static let control: CGFloat = 999
}

/// Spacing steps, in points.
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let s: CGFloat = 12
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
}

/// The type scale (docs/design.md). Sizes are at the default text size and
/// scale with Dynamic Type relative to their text style (Typography.swift).
enum TypeScale {
    /// Running text.
    static let body = TypeStyle(size: 17, weight: .regular, relativeTo: .body)
    /// Estimates, rules, and legends.
    static let caption = TypeStyle(size: 13, weight: .regular, relativeTo: .footnote)
    /// The count on Progress.
    static let figure = TypeStyle(size: 48, weight: .bold, relativeTo: .largeTitle)
    /// A plan's label above a reading.
    static let label = TypeStyle(size: 14, weight: .semibold, relativeTo: .subheadline)
    /// A plan page's title.
    static let planTitle = TypeStyle(size: 30, weight: .bold, relativeTo: .title)
    /// The desk-glance reference on Today.
    static let reference = TypeStyle(size: 38, weight: .semibold, relativeTo: .largeTitle)
    /// References in a card with several readings, and in lists.
    static let referenceList = TypeStyle(size: 21, weight: .semibold, relativeTo: .title2)
    /// Today, Plans, Progress.
    static let screenTitle = TypeStyle(size: 34, weight: .bold, relativeTo: .largeTitle)
}
