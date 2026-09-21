import Foundation
import SwiftData

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

    /// Performance measurement (see `PerformanceTests`) needs a realistic
    /// volume of data to be meaningful — an empty Timeline scrolls fast
    /// regardless of whether the query/render path is efficient. This
    /// seeds one child with several months of history directly through
    /// SwiftData (bypassing repositories/sync — irrelevant overhead for
    /// what's being measured here) after the normal state reset, so it
    /// always starts from a known, empty store.
    static func seedLargeDatasetIfRequested(context: ModelContext) {
        guard ProcessInfo.processInfo.arguments.contains("--uitest-seed-large-dataset") else { return }

        let household = Household(displayName: "Perf Household")
        context.insert(household)

        let birthday = Calendar.current.date(byAdding: .year, value: -3, to: .now) ?? .now
        let child = Child(
            household: household,
            name: "Perf Child",
            birthday: birthday,
            avatarIdentifier: ChildAvatarOption.star.rawValue,
            avatarColorIdentifier: ChildAvatarColorOption.mint.rawValue
        )
        context.insert(child)

        let now = Date.now
        let methods = TemperatureMeasurementMethod.allCases
        for index in 0..<300 {
            let log = TemperatureLog(
                child: child,
                temperatureCelsius: 36.5 + Double(index % 6) * 0.3,
                measurementMethod: methods[index % methods.count],
                recordedAt: now.addingTimeInterval(TimeInterval(-index * 3600))
            )
            context.insert(log)
        }

        try? context.save()
    }
}
#endif
