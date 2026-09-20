import Testing
@testable import FeverLog

@Suite("RootView localization")
struct RootViewTests {
    @Test("app name localization resolves")
    func appNameResolves() {
        #expect(!L10n.Root.appName.isEmpty)
    }

    @Test("development status localization resolves")
    func developmentStatusResolves() {
        #expect(!L10n.Root.developmentStatus.isEmpty)
    }

    @Test("in-memory settings store round-trips values")
    func inMemorySettingsStoreRoundTrips() {
        let store = InMemorySettingsStore()
        store.setString("value", forKey: "key")
        #expect(store.string(forKey: "key") == "value")

        store.setBool(true, forKey: "flag")
        #expect(store.bool(forKey: "flag") == true)
    }
}
