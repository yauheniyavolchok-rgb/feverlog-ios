import SwiftUI

/// Two-step in-app flow: request a one-time code sent to the given email,
/// then confirm it. This links the email to the current (typically
/// anonymous) user without creating a new one — see `AuthService`.
struct EmailLinkSheet: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.feverPalette) private var palette

    var onLinked: () -> Void = {}

    @State private var email = ""
    @State private var code = ""
    @State private var codeWasSent = false
    @State private var errorMessage: String?
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.Account.emailLabel, text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .disabled(codeWasSent)
                        .accessibilityIdentifier("emailLink.email")
                }

                if codeWasSent {
                    Section {
                        Text(L10n.Account.emailCodeSentMessage)
                            .foregroundStyle(palette.secondaryText)
                        TextField(L10n.Account.emailCodeLabel, text: $code)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("emailLink.code")
                    }
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(palette.danger)
                }
            }
            .navigationTitle(L10n.Account.emailPromptTitle)
            .disabled(isWorking)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Account.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if codeWasSent {
                        Button(L10n.Account.emailConfirm) { Task { await confirmCode() } }
                            .disabled(code.isEmpty)
                            .accessibilityIdentifier("emailLink.confirm")
                    } else {
                        Button(L10n.Account.emailSend) { Task { await sendCode() } }
                            .disabled(email.isEmpty)
                            .accessibilityIdentifier("emailLink.send")
                    }
                }
            }
        }
    }

    private func sendCode() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            try await authService.requestEmailLinkCode(email: email)
            codeWasSent = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func confirmCode() async {
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }
        do {
            try await authService.confirmEmailLinkCode(email: email, code: code)
            onLinked()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
