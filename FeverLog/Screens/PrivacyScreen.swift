import SwiftUI

struct PrivacyScreen: View {
    @Environment(\.feverPalette) private var palette

    var body: some View {
        List {
            privacySection(title: L10n.Privacy.dataStorageTitle, message: L10n.Privacy.dataStorageMessage)
            privacySection(title: L10n.Privacy.syncTitle, message: L10n.Privacy.syncMessage)
            privacySection(title: L10n.Privacy.noTelemetryTitle, message: L10n.Privacy.noTelemetryMessage)
        }
        .navigationTitle(L10n.Privacy.title)
    }

    private func privacySection(title: String, message: String) -> some View {
        Section(title) {
            Text(message)
                .font(Typography.body)
                .foregroundStyle(palette.secondaryText)
        }
    }
}

#Preview {
    NavigationStack { PrivacyScreen() }
        .feverThemed()
}
