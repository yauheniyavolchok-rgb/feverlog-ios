import SwiftUI

struct AboutScreen: View {
    @Environment(\.feverPalette) private var palette

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(L10n.Root.appName)
                        .font(Typography.sectionTitle)
                        .foregroundStyle(palette.primaryText)
                    Text(L10n.About.offlineFirstMessage)
                        .font(Typography.body)
                        .foregroundStyle(palette.secondaryText)
                }
                LabeledContent(L10n.About.versionLabel, value: versionString)
            }

            Section(L10n.About.disclaimerTitle) {
                Text(L10n.About.disclaimerMessage)
                    .font(Typography.body)
                    .foregroundStyle(palette.secondaryText)
            }
        }
        .navigationTitle(L10n.About.title)
    }
}

#Preview {
    NavigationStack { AboutScreen() }
        .feverThemed()
}
