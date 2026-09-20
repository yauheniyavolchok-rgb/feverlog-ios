import SwiftUI

/// Brief, logo-only launch moment shown on every app open — never the full
/// onboarding text, which only ever appears on a genuinely first launch.
struct SplashScreen: View {
    @Environment(\.feverPalette) private var palette

    var body: some View {
        VStack {
            Spacer()
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .accessibilityHidden(true)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
    }
}

#Preview {
    SplashScreen()
        .feverThemed()
}
