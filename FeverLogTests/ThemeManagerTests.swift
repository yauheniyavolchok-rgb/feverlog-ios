import SwiftUI
import Testing
@testable import FeverLog

@Suite("ThemeManager")
struct ThemeManagerTests {
    @Test("defaults to system when no persisted value exists")
    func defaultsToSystem() {
        let manager = ThemeManager(settingsStore: InMemorySettingsStore())
        #expect(manager.appearanceMode == .system)
    }

    @Test("appearance mode persists across instances sharing a store")
    func appearanceModePersistsAcrossInstances() {
        let store = InMemorySettingsStore()
        let first = ThemeManager(settingsStore: store)
        first.appearanceMode = .calmNight

        let second = ThemeManager(settingsStore: store)
        #expect(second.appearanceMode == .calmNight)
    }

    @Test("system mode resolves to light or dark based on the environment color scheme")
    func systemModeResolvesToEnvironmentScheme() {
        let manager = ThemeManager(settingsStore: InMemorySettingsStore())
        manager.appearanceMode = .system

        #expect(manager.palette(for: .light).background == ColorPalette.light.background)
        #expect(manager.palette(for: .dark).background == ColorPalette.dark.background)
    }

    @Test(
        "explicit modes resolve regardless of system color scheme",
        arguments: [AppearanceMode.light, .dark, .calmNight]
    )
    func explicitModesIgnoreSystemScheme(mode: AppearanceMode) {
        let manager = ThemeManager(settingsStore: InMemorySettingsStore())
        manager.appearanceMode = mode

        let expected: ColorPalette = switch mode {
        case .system: .light
        case .light: .light
        case .dark: .dark
        case .calmNight: .calmNight
        }

        #expect(manager.palette(for: .light).background == expected.background)
        #expect(manager.palette(for: .dark).background == expected.background)
    }
}
