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

            Section {
                NavigationLink(L10n.HouseholdSettings.title) {
                    HouseholdSettingsScreen()
                }
                .accessibilityIdentifier("settings.household")

                NavigationLink(L10n.ChildrenSettings.title) {
                    ChildrenSettingsScreen()
                }
                .accessibilityIdentifier("settings.children")
            }

            Section {
                NavigationLink(L10n.MedicationLibrarySettings.title) {
                    MedicationLibrarySettingsScreen()
                }
                .accessibilityIdentifier("settings.medicationLibrary")

                NavigationLink(L10n.UnitsSettings.title) {
                    UnitsSettingsScreen()
                }
                .accessibilityIdentifier("settings.units")

                NavigationLink(L10n.LanguageSettings.title, value: SettingsRoute.language)
                    .accessibilityIdentifier("settings.language")

                NavigationLink(L10n.Reminders.title) {
                    RemindersScreen()
                }
                .accessibilityIdentifier("settings.reminders")
            }

            Section {
                NavigationLink(L10n.Account.title) {
                    AccountScreen()
                }
                .accessibilityIdentifier("settings.account")

                NavigationLink(L10n.SyncStatus.title) {
                    SyncStatusScreen()
                }
                .accessibilityIdentifier("settings.syncStatus")
            }

            Section {
                NavigationLink(L10n.About.title) {
                    AboutScreen()
                }
                .accessibilityIdentifier("settings.about")

                NavigationLink(L10n.Privacy.title) {
                    PrivacyScreen()
                }
                .accessibilityIdentifier("settings.privacy")
            }
        }
        .navigationTitle(L10n.Nav.settings)
        .navigationDestination(for: SettingsRoute.self) { route in
            switch route {
            case .language: LanguageSettingsScreen()
            }
        }
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
