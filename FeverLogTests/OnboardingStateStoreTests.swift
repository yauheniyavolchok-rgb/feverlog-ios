import Testing
@testable import FeverLog

@Suite("OnboardingStateStore")
@MainActor
struct OnboardingStateStoreTests {
    @Test("defaults to not completed")
    func defaultsToNotCompleted() {
        let store = OnboardingStateStore(settingsStore: InMemorySettingsStore())
        #expect(store.isCompleted == false)
    }

    @Test("completion persists across instances sharing a store")
    func completionPersistsAcrossInstances() {
        let settingsStore = InMemorySettingsStore()
        let first = OnboardingStateStore(settingsStore: settingsStore)
        first.complete()

        let second = OnboardingStateStore(settingsStore: settingsStore)
        #expect(second.isCompleted == true)
    }
}
