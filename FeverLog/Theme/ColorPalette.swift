import SwiftUI

/// Semantic color tokens. Feature views must never reference `Color` literals
/// directly — always go through a `ColorPalette` resolved from the current
/// `ThemeManager` (see `ThemeEnvironment.swift`).
struct ColorPalette: Sendable {
    let background: Color
    let surface: Color
    let secondarySurface: Color
    let primaryText: Color
    let secondaryText: Color

    let accentMint: Color
    let accentLavender: Color
    let accentPeach: Color
    let accentBlue: Color
    let accentCoral: Color
    let accentCrimson: Color

    let success: Color
    let warning: Color
    let danger: Color

    // Temperature status colors are presentation tokens only. They must
    // never be reused as medication safety thresholds — those live in
    // FeverLogEngine and are entirely independent of this palette.
    let temperatureNormal: Color
    let temperatureElevated: Color
    let temperatureHigh: Color
    let temperatureVeryHigh: Color
    let temperatureCritical: Color

    let chartColors: [Color]

    func color(for status: TemperatureStatus) -> Color {
        switch status {
        case .normal: temperatureNormal
        case .elevated: temperatureElevated
        case .high: temperatureHigh
        case .veryHigh: temperatureVeryHigh
        case .critical: temperatureCritical
        }
    }
}

extension ColorPalette {
    static let light = ColorPalette(
        background: Color(red: 0.98, green: 0.98, blue: 0.99),
        surface: Color(red: 1.0, green: 1.0, blue: 1.0),
        secondarySurface: Color(red: 0.94, green: 0.94, blue: 0.96),
        primaryText: Color(red: 0.11, green: 0.11, blue: 0.13),
        secondaryText: Color(red: 0.45, green: 0.45, blue: 0.49),

        accentMint: Color(red: 0.55, green: 0.85, blue: 0.75),
        accentLavender: Color(red: 0.75, green: 0.70, blue: 0.92),
        accentPeach: Color(red: 0.98, green: 0.78, blue: 0.62),
        accentBlue: Color(red: 0.42, green: 0.62, blue: 0.95),
        accentCoral: Color(red: 0.96, green: 0.55, blue: 0.52),
        accentCrimson: Color(red: 0.80, green: 0.20, blue: 0.27),

        success: Color(red: 0.30, green: 0.72, blue: 0.48),
        warning: Color(red: 0.92, green: 0.66, blue: 0.20),
        danger: Color(red: 0.85, green: 0.28, blue: 0.28),

        temperatureNormal: Color(red: 0.30, green: 0.72, blue: 0.48),
        temperatureElevated: Color(red: 0.92, green: 0.75, blue: 0.30),
        temperatureHigh: Color(red: 0.95, green: 0.58, blue: 0.25),
        temperatureVeryHigh: Color(red: 0.90, green: 0.35, blue: 0.28),
        temperatureCritical: Color(red: 0.72, green: 0.14, blue: 0.20),

        chartColors: [
            Color(red: 0.42, green: 0.62, blue: 0.95),
            Color(red: 0.55, green: 0.85, blue: 0.75),
            Color(red: 0.75, green: 0.70, blue: 0.92),
            Color(red: 0.98, green: 0.78, blue: 0.62),
            Color(red: 0.96, green: 0.55, blue: 0.52)
        ]
    )

    static let dark = ColorPalette(
        background: Color(red: 0.05, green: 0.05, blue: 0.07),
        surface: Color(red: 0.11, green: 0.11, blue: 0.13),
        secondarySurface: Color(red: 0.16, green: 0.16, blue: 0.19),
        primaryText: Color(red: 0.96, green: 0.96, blue: 0.97),
        secondaryText: Color(red: 0.66, green: 0.66, blue: 0.70),

        accentMint: Color(red: 0.45, green: 0.75, blue: 0.66),
        accentLavender: Color(red: 0.65, green: 0.60, blue: 0.85),
        accentPeach: Color(red: 0.88, green: 0.68, blue: 0.54),
        accentBlue: Color(red: 0.48, green: 0.64, blue: 0.92),
        accentCoral: Color(red: 0.88, green: 0.52, blue: 0.50),
        accentCrimson: Color(red: 0.82, green: 0.30, blue: 0.36),

        success: Color(red: 0.40, green: 0.75, blue: 0.55),
        warning: Color(red: 0.90, green: 0.70, blue: 0.32),
        danger: Color(red: 0.88, green: 0.40, blue: 0.40),

        temperatureNormal: Color(red: 0.40, green: 0.75, blue: 0.55),
        temperatureElevated: Color(red: 0.88, green: 0.72, blue: 0.35),
        temperatureHigh: Color(red: 0.90, green: 0.58, blue: 0.32),
        temperatureVeryHigh: Color(red: 0.88, green: 0.42, blue: 0.36),
        temperatureCritical: Color(red: 0.80, green: 0.24, blue: 0.30),

        chartColors: [
            Color(red: 0.48, green: 0.64, blue: 0.92),
            Color(red: 0.45, green: 0.75, blue: 0.66),
            Color(red: 0.65, green: 0.60, blue: 0.85),
            Color(red: 0.88, green: 0.68, blue: 0.54),
            Color(red: 0.88, green: 0.52, blue: 0.50)
        ]
    )

    /// Calm Night: no pure white/black, reduced saturation, warm gray
    /// typography, extra-dim surfaces, limited glow, no bright full-screen
    /// backgrounds.
    static let calmNight = ColorPalette(
        background: Color(red: 0.08, green: 0.075, blue: 0.09),
        surface: Color(red: 0.13, green: 0.125, blue: 0.14),
        secondarySurface: Color(red: 0.17, green: 0.165, blue: 0.18),
        primaryText: Color(red: 0.82, green: 0.80, blue: 0.76),
        secondaryText: Color(red: 0.58, green: 0.56, blue: 0.53),

        accentMint: Color(red: 0.40, green: 0.58, blue: 0.53),
        accentLavender: Color(red: 0.52, green: 0.48, blue: 0.62),
        accentPeach: Color(red: 0.62, green: 0.52, blue: 0.44),
        accentBlue: Color(red: 0.40, green: 0.48, blue: 0.62),
        accentCoral: Color(red: 0.62, green: 0.42, blue: 0.40),
        accentCrimson: Color(red: 0.58, green: 0.28, blue: 0.32),

        success: Color(red: 0.38, green: 0.55, blue: 0.44),
        warning: Color(red: 0.62, green: 0.52, blue: 0.30),
        danger: Color(red: 0.62, green: 0.34, blue: 0.34),

        // Limited glow: temperature colors are muted relative to Light/Dark.
        temperatureNormal: Color(red: 0.38, green: 0.55, blue: 0.44),
        temperatureElevated: Color(red: 0.60, green: 0.52, blue: 0.34),
        temperatureHigh: Color(red: 0.62, green: 0.44, blue: 0.32),
        temperatureVeryHigh: Color(red: 0.60, green: 0.36, blue: 0.32),
        temperatureCritical: Color(red: 0.54, green: 0.26, blue: 0.30),

        chartColors: [
            Color(red: 0.40, green: 0.48, blue: 0.62),
            Color(red: 0.40, green: 0.58, blue: 0.53),
            Color(red: 0.52, green: 0.48, blue: 0.62),
            Color(red: 0.62, green: 0.52, blue: 0.44),
            Color(red: 0.62, green: 0.42, blue: 0.40)
        ]
    )
}
