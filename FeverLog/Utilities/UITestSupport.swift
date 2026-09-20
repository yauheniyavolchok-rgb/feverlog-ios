import Foundation

#if DEBUG
/// Test-only state reset, gated behind an explicit launch argument and a
/// DEBUG build so it can never run in a release build. UI tests pass
/// `--uitest-reset-state` to guarantee a deterministic starting state
/// (fresh onboarding, empty local database) regardless of what a previous
/// test run left behind on the simulator.
enum UITestSupport {
    static func resetStateIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("--uitest-reset-state") else { return }

        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        guard let supportDirectory = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return }

        let storeURL = supportDirectory.appending(path: "default.store")
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
        }
    }

    /// The simulator has no equivalent of `simctl privacy` for notification
    /// authorization, so UI tests force the denied-permission state through
    /// this launch argument instead of the real (uncontrollable) system
    /// prompt.
    static var forcesNotificationsDenied: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitest-notifications-denied")
    }
}
#endif
