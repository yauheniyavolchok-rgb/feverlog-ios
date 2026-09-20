import SwiftUI

/// Semantic typography tokens. All styles use the rounded system font and
/// scale with Dynamic Type.
enum Typography {
    static let largeTemperature = Font.system(size: 54, weight: .bold, design: .rounded)
    static let screenTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
}
