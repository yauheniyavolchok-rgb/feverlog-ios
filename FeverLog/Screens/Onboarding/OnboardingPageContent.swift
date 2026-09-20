import Foundation

struct OnboardingPageContent: Identifiable, Sendable {
    let id: String
    let systemImage: String
    let title: String
    let message: String
}

enum OnboardingPages {
    static let all: [OnboardingPageContent] = [
        OnboardingPageContent(
            id: "welcome",
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
