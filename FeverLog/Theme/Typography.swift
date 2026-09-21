import SwiftUI

/// Semantic typography tokens. All styles use the rounded system font and
/// scale with Dynamic Type.
enum Typography {
    static let largeTemperature = scaledSystemFont(size: 54, weight: .bold, relativeTo: .largeTitle)
    static let screenTitle = scaledSystemFont(size: 34, weight: .bold, relativeTo: .largeTitle)
    static let sectionTitle = scaledSystemFont(size: 22, weight: .semibold, relativeTo: .title3)
    static let body = scaledSystemFont(size: 17, weight: .regular, relativeTo: .body)
    static let caption = scaledSystemFont(size: 13, weight: .regular, relativeTo: .caption)

    /// `Font.system(size:weight:design:)` renders at a fixed point size and
    /// does not participate in Dynamic Type scaling — only semantic text
    /// styles (`.body`, `.largeTitle`, etc.) or `Font.custom(_:size:
    /// relativeTo:)` do. Since these tokens need specific point sizes that
    /// don't map onto `Font.custom`'s named-font API, this builds a `UIFont`
    /// at the target size and design, then wraps it with `UIFontMetrics` so
    /// it scales the same way a semantic style relative to `textStyle`
    /// would.
    private static func scaledSystemFont(size: CGFloat, weight: UIFont.Weight, relativeTo textStyle: Font.TextStyle) -> Font {
        let uiTextStyle = textStyle.uiTextStyle
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
        let roundedBase = UIFont(descriptor: descriptor, size: size)
        let scaled = UIFontMetrics(forTextStyle: uiTextStyle).scaledFont(for: roundedBase)
        return Font(scaled)
    }
}

private extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .body: .body
        case .callout: .callout
        case .subheadline: .subheadline
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        @unknown default: .body
        }
    }
}
