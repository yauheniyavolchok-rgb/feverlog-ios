import SwiftUI

struct ShadowToken: Sendable {
    let color: Color
    let radius: CGFloat
    let offsetX: CGFloat
    let offsetY: CGFloat

    /// Standard card elevation.
    static let card = ShadowToken(color: .black.opacity(0.08), radius: 12, offsetX: 0, offsetY: 4)

    /// Calm Night uses a limited glow — shadows stay subtle and never
    /// brighten the surrounding surface.
    static let calmNightCard = ShadowToken(color: .black.opacity(0.35), radius: 10, offsetX: 0, offsetY: 3)
}

extension View {
    func feverShadow(_ token: ShadowToken) -> some View {
        shadow(color: token.color, radius: token.radius, x: token.offsetX, y: token.offsetY)
    }
}
