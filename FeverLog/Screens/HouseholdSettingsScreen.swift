import SwiftData
import SwiftUI

struct HouseholdSettingsScreen: View {
    @Environment(ChildStore.self) private var childStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    @State private var displayName = ""
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section(L10n.HouseholdSettings.nameLabel) {
                TextField(L10n.HouseholdSettings.nameLabel, text: $displayName)
                    .accessibilityIdentifier("householdSettings.name")
                Button(L10n.HouseholdSettings.save, action: save)
                    .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("householdSettings.save")
            }

            if let members = childStore.household?.members, !members.isEmpty {
                Section(L10n.HouseholdSettings.membersTitle) {
                    ForEach(members.sorted { $0.createdAt < $1.createdAt }, id: \.id) { member in
                        HStack {
                            Text(member.displayName.isEmpty ? L10n.HouseholdSettings.title : member.displayName)
                            Spacer()
                            Text(member.role == .owner ? L10n.HouseholdSettings.roleOwner : L10n.HouseholdSettings.roleMember)
                                .foregroundStyle(palette.secondaryText)
                        }
                    }
                }
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(palette.danger) }
            }
        }
        .navigationTitle(L10n.HouseholdSettings.title)
        .task { displayName = childStore.household?.displayName ?? "" }
    }

    private func save() {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let household = childStore.household else { return }
        errorMessage = nil
        household.displayName = trimmed
        do {
            try SwiftDataHouseholdRepository(context: modelContext).update(household)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack { HouseholdSettingsScreen() }
        .environment(ChildStore())
        .feverThemed()
}
