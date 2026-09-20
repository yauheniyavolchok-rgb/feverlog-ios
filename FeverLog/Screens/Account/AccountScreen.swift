import SwiftUI

struct AccountScreen: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.feverPalette) private var palette

    @State private var showingEmailSheet = false
    @State private var showingJoinSheet = false
    @State private var showingSignOutConfirm = false
    @State private var inviteCode: String?
    @State private var joinSuccessMessage: String?
    @State private var errorMessage: String?
    @State private var isWorking = false

    private static let googleRedirectURL = URL(string: "com.drbaby.feverlog://auth-callback")!

    var body: some View {
        List {
            if authService.isAnonymous {
                notBackedUpSection
            } else {
                linkedSection
                householdSection
            }

            if let joinSuccessMessage {
                Section { Text(joinSuccessMessage).foregroundStyle(palette.success) }
            }
            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(palette.danger) }
            }

            Section {
                Button(L10n.Account.signOut, role: .destructive) { showingSignOutConfirm = true }
                    .accessibilityIdentifier("account.signOut")
            }
        }
        .navigationTitle(L10n.Account.title)
        .disabled(isWorking)
        .sheet(isPresented: $showingEmailSheet) {
            EmailLinkSheet { errorMessage = nil }
        }
        .sheet(isPresented: $showingJoinSheet) {
            JoinHouseholdSheet { joinSuccessMessage = L10n.Account.householdJoinSuccessMessage }
        }
        .confirmationDialog(
            L10n.Account.signOutConfirmTitle,
            isPresented: $showingSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.Account.signOutConfirmConfirm, role: .destructive) { Task { await signOut() } }
            Button(L10n.Account.signOutConfirmCancel, role: .cancel) {}
        } message: {
            Text(L10n.Account.signOutConfirmMessage)
        }
    }

    private var notBackedUpSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(L10n.Account.notBackedUpTitle)
                    .font(Typography.sectionTitle)
                    .foregroundStyle(palette.primaryText)
                Text(L10n.Account.notBackedUpMessage)
                    .font(Typography.body)
                    .foregroundStyle(palette.secondaryText)
            }
            Button(L10n.Account.continueWithApple) { Task { await linkApple() } }
                .accessibilityIdentifier("account.continueWithApple")
            Button(L10n.Account.continueWithGoogle) { Task { await linkGoogle() } }
                .accessibilityIdentifier("account.continueWithGoogle")
            Button(L10n.Account.continueWithEmail) { showingEmailSheet = true }
                .accessibilityIdentifier("account.continueWithEmail")
        }
    }

    private var linkedSection: some View {
        Section {
            Text(L10n.Account.linkedTitle)
                .font(Typography.sectionTitle)
                .foregroundStyle(palette.primaryText)
            Text(L10n.Account.linkedMessage)
                .font(Typography.body)
                .foregroundStyle(palette.secondaryText)
        }
    }

    private var householdSection: some View {
        Section(L10n.Account.householdTitle) {
            if let inviteCode {
                HStack {
                    Text(L10n.Account.householdInviteCodeLabel)
                    Spacer()
                    Text(inviteCode)
                        .font(.system(.body, design: .monospaced))
                        .accessibilityIdentifier("account.inviteCodeValue")
                }
            }
            Button(L10n.Account.householdGenerateInvite) { Task { await generateInvite() } }
                .accessibilityIdentifier("account.generateInvite")
            Button(L10n.Account.householdJoinTitle) { showingJoinSheet = true }
                .accessibilityIdentifier("account.joinHousehold")
        }
    }

    private func linkApple() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            let result = try await AppleSignInCoordinator().performSignIn()
            try await authService.linkApple(idToken: result.idToken, nonce: result.nonce)
        } catch AppleSignInError.cancelled {
            // User-initiated cancellation; nothing to report.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func linkGoogle() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            try await authService.beginGoogleLink(redirectTo: Self.googleRedirectURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func generateInvite() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            let coordinator = HouseholdSyncCoordinator(
                authService: authService,
                syncClient: SupabaseClientProvider.shared.map(LiveSupabaseHouseholdSyncClient.init),
                context: modelContext
            )
            inviteCode = try await coordinator.createInvite()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func signOut() async {
        try? await authService.signOut()
    }
}
