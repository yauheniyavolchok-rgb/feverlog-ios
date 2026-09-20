import SwiftUI

extension View {
    /// Injects a `ColorPalette` for use in SwiftUI previews without needing
    /// the full `RootView` / `ThemeManager` stack.
    func feverThemed(_ palette: ColorPalette = .light) -> some View {
        environment(\.feverPalette, palette)
    }
}
