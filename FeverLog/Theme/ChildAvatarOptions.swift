import SwiftUI

enum ChildAvatarOption: String, CaseIterable, Identifiable, Sendable {
    case star = "star.fill"
    case moon = "moon.stars.fill"
    case leaf = "leaf.fill"
    case cloud = "cloud.sun.fill"
    case paw = "pawprint.fill"
    case smile = "face.smiling.fill"

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
