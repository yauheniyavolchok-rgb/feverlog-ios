import Foundation

struct OnboardingPageContent: Identifiable, Sendable {
    let id: String
    /// When set, takes priority over `systemImage` — used for the real
    /// app logo rather than a placeholder SF Symbol.
    let logoImageName: String?
    let systemImage: String
    let title: String
    let message: String

    init(id: String, logoImageName: String? = nil, systemImage: String, title: String, message: String) {
        self.id = id
        self.logoImageName = logoImageName
        self.systemImage = systemImage
        self.title = title
        self.message = message
    }
}

enum OnboardingPages {
    static let all: [OnboardingPageContent] = [
        OnboardingPageContent(
            id: "welcome",
            logoImageName: "Logo",
            systemImage: Icon.temperature,
            title: L10n.Onboarding.welcomeTitle,
            message: L10n.Onboarding.welcomeMessage
        ),
        OnboardingPageContent(
            id: "familySharing",
            systemImage: "person.2.fill",
            title: L10n.Onboarding.familySharingTitle,
            message: L10n.Onboarding.familySharingMessage
        ),
        OnboardingPageContent(
            id: "medicationSafety",
            systemImage: "cross.case.fill",
            title: L10n.Onboarding.medicationSafetyTitle,
            message: L10n.Onboarding.medicationSafetyMessage
        )
    ]
}
