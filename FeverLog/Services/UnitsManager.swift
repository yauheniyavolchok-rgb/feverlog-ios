import Observation
import SwiftUI

/// Owns the device-local default weight unit, used to pre-fill new weight
/// entries. Never affects previously-recorded weights, which keep whatever
/// unit they were entered in.
@Observable
@MainActor
final class UnitsManager {
    private static let weightUnitKey = "units.defaultWeightUnit"

    private let settingsStore: AppSettingsStore

    var defaultWeightUnit: WeightUnit {
        didSet {
            guard defaultWeightUnit != oldValue else { return }
            settingsStore.setString(defaultWeightUnit.rawValue, forKey: Self.weightUnitKey)
        }
    }

    init(settingsStore: AppSettingsStore = UserDefaultsSettingsStore()) {
        self.settingsStore = settingsStore
        if let raw = settingsStore.string(forKey: Self.weightUnitKey), let saved = WeightUnit(rawValue: raw) {
            defaultWeightUnit = saved
        } else {
            defaultWeightUnit = .kilograms
        }
    }
}
