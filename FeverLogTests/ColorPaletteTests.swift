import SwiftUI
import Testing
import UIKit
@testable import FeverLog

@Suite("ColorPalette")
struct ColorPaletteTests {
    @Test(
        "temperature status maps to a distinct token per palette",
        arguments: [ColorPalette.light, .dark, .calmNight]
    )
    func temperatureStatusMapsToDistinctTokens(palette: ColorPalette) {
        let colors = TemperatureStatus.allCases.map { palette.color(for: $0) }
        let uniqueComponents = Set(colors.map(\.rgbaComponents))
        #expect(uniqueComponents.count == TemperatureStatus.allCases.count)
    }

    @Test("Calm Night avoids pure white and pure black on primary surfaces")
    func calmNightAvoidsPureWhiteAndBlack() {
        let palette = ColorPalette.calmNight
        for color in [palette.background, palette.surface, palette.secondarySurface, palette.primaryText] {
            let components = color.rgbaComponents
            let isPureBlack = components.red == 0 && components.green == 0 && components.blue == 0
            let isPureWhite = components.red == 1 && components.green == 1 && components.blue == 1
            #expect(!isPureBlack)
            #expect(!isPureWhite)
        }
    }

    @Test("Calm Night surfaces are extra-dim (low brightness)")
    func calmNightSurfacesAreDim() {
        let palette = ColorPalette.calmNight
        for color in [palette.background, palette.surface, palette.secondarySurface] {
            let components = color.rgbaComponents
            let brightness = (components.red + components.green + components.blue) / 3
            #expect(brightness < 0.25)
        }
    }

    @Test("Calm Night primary text is a warm gray, not pure white")
    func calmNightTextIsWarmGray() {
        let components = ColorPalette.calmNight.primaryText.rgbaComponents
        #expect(components.red < 1 && components.green < 1 && components.blue < 1)
        // "Warm" here means the red channel is not lower than blue (no cool/blue cast).
        #expect(components.red >= components.blue)
    }
}

struct RGBAComponents: Hashable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat
}

extension Color {
    var rgbaComponents: RGBAComponents {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return RGBAComponents(red: red, green: green, blue: blue, alpha: alpha)
    }
}
