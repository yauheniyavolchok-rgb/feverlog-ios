import SwiftUI

private struct FeverPaletteKey: EnvironmentKey {
    static let defaultValue: ColorPalette = .light
}

extension EnvironmentValues {
    var feverPalette: ColorPalette {
        get { self[FeverPaletteKey.self] }
        set { self[FeverPaletteKey.self] = newValue }
    }
}
