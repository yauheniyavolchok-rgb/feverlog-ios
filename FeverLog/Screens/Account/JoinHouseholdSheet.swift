import SwiftUI

struct JoinHouseholdSheet: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.feverPalette) private var palette

    var onJoined: () -> Void = {}

    @State private var code = ""
    @State private var errorMessage: String?
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.Account.householdJoinCodeLabel, text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("joinHousehold.code")
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(palette.danger)
                }
            }
            .navigationTitle(L10n.Account.householdJoinTitle)
            .disabled(isWorking)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Account.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Account.householdJoinButton) { Task { await join() } }
                        .disabled(code.isEmpty)
                        .accessibilityIdentifier("joinHousehold.join")
                }
            }
        }
    }

    private func join() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            let coordinator = HouseholdSyncCoordinator(
                authService: authService,
                syncClient: SupabaseClientProvider.shared.map(LiveSupabaseHouseholdSyncClient.init),
                context: modelContext
            )
            try await coordinator.joinHousehold(code: code)
            onJoined()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
