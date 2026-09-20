import SwiftUI

enum ChildAvatarOption: String, CaseIterable, Identifiable, Sendable {
    case cat = "cat.fill"
    case bird = "bird.fill"
    case sun = "sun.max.fill"
    case moon = "moon.fill"
    case star = "star.fill"
    case car = "car.fill"
    case heart = "heart.fill"
    case leaf = "leaf.fill"
    // No literal "rocket" glyph exists in SF Symbols; this is the closest
    // takeoff-themed stand-in.
    case rocket = "airplane.departure"

    var id: String { rawValue }
}

enum ChildAvatarColorOption: String, CaseIterable, Identifiable, Sendable {
    case mint
    case lavender
    case peach
    case blue
    case coral

    var id: String { rawValue }

    func color(in palette: ColorPalette) -> Color {
        switch self {
        case .mint: palette.accentMint
        case .lavender: palette.accentLavender
        case .peach: palette.accentPeach
        case .blue: palette.accentBlue
        case .coral: palette.accentCoral
        }
    }
}
