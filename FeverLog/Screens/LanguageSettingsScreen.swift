import SwiftUI

struct LanguageSettingsScreen: View {
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        List {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Button {
                    languageManager.language = language
                } label: {
                    HStack {
                        Text(language.localizedLabel)
                        Spacer()
                        if languageManager.language == language {
                            Image(systemName: "checkmark")
                                .accessibilityHidden(true)
                        }
                    }
                    .contentShape(Rectangle())
                    .frame(minHeight: Spacing.xxl)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("languageSettings.option.\(language.rawValue)")
                .accessibilityAddTraits(languageManager.language == language ? [.isButton, .isSelected] : [.isButton])
            }
        }
        .navigationTitle(L10n.LanguageSettings.title)
    }
}

#Preview {
    NavigationStack { LanguageSettingsScreen() }
        .environment(LanguageManager(settingsStore: InMemorySettingsStore()))
        .feverThemed()
}
