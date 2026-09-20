import Observation

@Observable
@MainActor
final class OnboardingStateStore {
    private static let completedKey = "onboarding.completed"

    private let settingsStore: AppSettingsStore

    private(set) var isCompleted: Bool

    init(settingsStore: AppSettingsStore = UserDefaultsSettingsStore()) {
        self.settingsStore = settingsStore
        self.isCompleted = settingsStore.bool(forKey: Self.completedKey)
    }

    func complete() {
        isCompleted = true
        settingsStore.setBool(true, forKey: Self.completedKey)
    }
}
