import Foundation

/// Abstraction over device-local key/value settings storage (appearance,
/// language, onboarding state, notification preferences, etc).
///
/// Domain data must never be stored here — this is for device-local UI/app
/// preferences only. See the local source-of-truth rule: domain records live
/// in SwiftData, not in settings storage.
protocol AppSettingsStore: Sendable {
    func string(forKey key: String) -> String?
    func setString(_ value: String?, forKey key: String)

    func bool(forKey key: String) -> Bool
    func setBool(_ value: Bool, forKey key: String)
}

/// `UserDefaults` is thread-safe but not marked `Sendable` in the SDK.
final class UserDefaultsSettingsStore: AppSettingsStore, @unchecked Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    func setString(_ value: String?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func bool(forKey key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    func setBool(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }
}

/// In-memory store for previews and unit tests.
final class InMemorySettingsStore: AppSettingsStore, @unchecked Sendable {
    private var strings: [String: String] = [:]
    private var bools: [String: Bool] = [:]
    private let lock = NSLock()

    func string(forKey key: String) -> String? {
        lock.withLock { strings[key] }
    }

    func setString(_ value: String?, forKey key: String) {
        lock.withLock { strings[key] = value }
    }

    func bool(forKey key: String) -> Bool {
        lock.withLock { bools[key] ?? false }
    }

    func setBool(_ value: Bool, forKey key: String) {
        lock.withLock { bools[key] = value }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
