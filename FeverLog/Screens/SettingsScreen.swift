import SwiftUI

struct SettingsScreen: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        List {
            Section {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Button {
                        setAppearanceMode(mode)
                    } label: {
                        HStack {
                            Text(mode.localizedLabel)
                            Spacer()
                            if themeManager.appearanceMode == mode {
                                Image(systemName: "checkmark")
                                    .accessibilityHidden(true)
                            }
                        }
                        .contentShape(Rectangle())
                        .frame(minHeight: Spacing.xxl)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings.appearance.option.\(mode.rawValue)")
                    .accessibilityAddTraits(themeManager.appearanceMode == mode ? [.isButton, .isSelected] : [.isButton])
                }
            } header: {
                Text(L10n.Settings.appearanceTitle)
            }
        }
        .navigationTitle(L10n.Nav.settings)
    }

    private func setAppearanceMode(_ mode: AppearanceMode) {
        if reduceMotion {
            themeManager.appearanceMode = mode
        } else {
            withAnimation {
                themeManager.appearanceMode = mode
            }
        }
    }
}

#Preview {
    NavigationStack { SettingsScreen() }
        .environment(ThemeManager(settingsStore: InMemorySettingsStore()))
        .feverThemed()
}
