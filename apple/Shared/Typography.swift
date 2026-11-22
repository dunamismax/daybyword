import SwiftUI

/// A step of the type scale (docs/design.md): its size at the default text size,
/// its weight, and the text style whose Dynamic Type scaling it follows, so every
/// step grows with the reader's text size up to AX5. The steps themselves are
/// generated from design/tokens.json into `TypeScale` (DesignTokens.swift).
struct TypeStyle: Sendable {
    let size: CGFloat
    let weight: Font.Weight
    let relativeTo: Font.TextStyle
}

extension View {
    /// Sets the system font at a step of the type scale, scaled with Dynamic Type.
    func typeStyle(_ style: TypeStyle) -> some View {
        modifier(ScaledTypeStyle(style: style))
    }
}

private struct ScaledTypeStyle: ViewModifier {
    @ScaledMetric private var size: CGFloat
    @Environment(\.legibilityWeight) private var legibilityWeight
    private let weight: Font.Weight

    init(style: TypeStyle) {
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: style.relativeTo)
        weight = style.weight
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: legibilityWeight == .bold ? Self.bolder(weight) : weight))
    }

    /// One step heavier, for Bold Text (BUILD.md P17.2): a font given its
    /// own weight does not follow the setting by itself.
    private static func bolder(_ weight: Font.Weight) -> Font.Weight {
        switch weight {
        case .ultraLight, .thin, .light: .regular
        case .regular: .semibold
        case .medium, .semibold: .bold
        default: .heavy
        }
    }
}
