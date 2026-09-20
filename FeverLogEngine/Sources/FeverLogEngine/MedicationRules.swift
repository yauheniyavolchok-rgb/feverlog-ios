import Foundation

/// A concentration expressed as X milligrams per Y milliliters, exactly as
/// printed on a product label. The per-milliliter ratio is always derived
/// from both numbers — never inferred or assumed to already be "per mL".
public struct Concentration: Codable, Equatable, Sendable {
    public let milligrams: Decimal
    public let milliliters: Decimal

    public init(milligrams: Decimal, milliliters: Decimal) {
        self.milligrams = milligrams
        self.milliliters = milliliters
    }

    public var milligramsPerMilliliter: Decimal? {
        guard milliliters != 0 else { return nil }
        return milligrams / milliliters
    }
}

/// A single-administration dosing rule, expressed as published by the
/// medication's source. Any field left `nil` means that limit is not
/// configured — the engine must never invent a value for it.
public struct SingleDoseRule: Codable, Equatable, Sendable {
    public let minMilligramsPerKilogram: Decimal?
    public let maxMilligramsPerKilogram: Decimal?
    public let maxMilligramsPerDose: Decimal?

    public init(
        minMilligramsPerKilogram: Decimal? = nil,
        maxMilligramsPerKilogram: Decimal? = nil,
        maxMilligramsPerDose: Decimal? = nil
    ) {
        self.minMilligramsPerKilogram = minMilligramsPerKilogram
        self.maxMilligramsPerKilogram = maxMilligramsPerKilogram
        self.maxMilligramsPerDose = maxMilligramsPerDose
    }
}

/// A rolling 24-hour dosing rule. `minimumIntervalSeconds` governs spacing
/// between doses of the same active ingredient, independent of the maximum
/// checks.
public struct DailyMaximumRule: Codable, Equatable, Sendable {
    public let maxMilligramsPerKilogramPerDay: Decimal?
    public let maxMilligramsPerDay: Decimal?
    public let maxDosesPerDay: Int?
    public let minimumIntervalSeconds: Double?

    public init(
        maxMilligramsPerKilogramPerDay: Decimal? = nil,
        maxMilligramsPerDay: Decimal? = nil,
        maxDosesPerDay: Int? = nil,
        minimumIntervalSeconds: Double? = nil
    ) {
        self.maxMilligramsPerKilogramPerDay = maxMilligramsPerKilogramPerDay
        self.maxMilligramsPerDay = maxMilligramsPerDay
        self.maxDosesPerDay = maxDosesPerDay
        self.minimumIntervalSeconds = minimumIntervalSeconds
    }
}

public enum MedicationReviewStatus: String, Codable, Sendable {
    case unreviewed
    case reviewed
    case deprecated
}

/// Reference data describing one medication product/form, as published by
/// `sourceIdentifier` version `sourceVersion`. This is never a substitute
/// for the product label or a qualified professional's guidance — see
/// `MedicationDatabase` for the full disclaimer.
///
/// Definitions are versioned. Updating a definition later must never change
/// what an already-saved dose log means — the application layer is
/// responsible for snapshotting these values at administration time rather
/// than re-reading the live definition.
public struct MedicationRule: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let brand: String
    public let activeIngredient: String
    public let concentration: Concentration
    public let form: String
    public let strength: String
    public let countryOrLocale: String
    public let singleDoseRule: SingleDoseRule?
    public let dailyMaximumRule: DailyMaximumRule?
    public let sourceIdentifier: String
    public let sourceVersion: String
    public let reviewStatus: MedicationReviewStatus
    public let isActive: Bool
    public let databaseSchemaVersion: Int

    public init(
        id: String,
        brand: String,
        activeIngredient: String,
        concentration: Concentration,
        form: String,
        strength: String,
        countryOrLocale: String,
        singleDoseRule: SingleDoseRule?,
        dailyMaximumRule: DailyMaximumRule?,
        sourceIdentifier: String,
        sourceVersion: String,
        reviewStatus: MedicationReviewStatus,
        isActive: Bool,
        databaseSchemaVersion: Int
    ) {
        self.id = id
        self.brand = brand
        self.activeIngredient = activeIngredient
        self.concentration = concentration
        self.form = form
        self.strength = strength
        self.countryOrLocale = countryOrLocale
        self.singleDoseRule = singleDoseRule
        self.dailyMaximumRule = dailyMaximumRule
        self.sourceIdentifier = sourceIdentifier
        self.sourceVersion = sourceVersion
        self.reviewStatus = reviewStatus
        self.isActive = isActive
        self.databaseSchemaVersion = databaseSchemaVersion
    }

    /// The stable key used to group doses of this medication with doses of
    /// other brands/forms/concentrations that share the same active
    /// ingredient. See `ActiveIngredientNormalizer`.
    public var normalizedActiveIngredientKey: String {
        ActiveIngredientNormalizer.normalize(activeIngredient)
    }
}

/// Errors surfaced while loading or decoding the bundled medication
/// database. These indicate a packaging/build problem, not a user error.
public enum MedicationDatabaseError: Error, Equatable, Sendable {
    case resourceNotFound
    case decodingFailed(String)
}

struct MedicationDatabaseFile: Codable {
    let schemaVersion: Int
    let medications: [MedicationRule]
}

/// Loads the bundled, versioned medication reference database.
///
/// IMPORTANT: The bundled data ships with `reviewStatus == .unreviewed` for
/// every entry until a qualified medical/pharmacy reviewer signs off (see
/// TODO below). None of it is medical advice, and the application layer
/// must always tell users to verify against the product label or a
/// qualified professional — see Phase 6's safety copy requirements.
///
/// TODO(Phase 5, medication data review): Complete medication data review with a qualified
/// medical or pharmacy reviewer before production release.
/// Completion: every production medication definition has documented source provenance,
/// version, locale, and review status of `.reviewed`.
/// Release blocker: yes.
public enum MedicationDatabase {
    public static let schemaVersion = 1

    /// Loads and decodes the bundled medication database from
    /// `Resources/medications.json`.
    public static func loadBundled() throws -> [MedicationRule] {
        guard let url = Bundle.module.url(forResource: "medications", withExtension: "json") else {
            throw MedicationDatabaseError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        do {
            let file = try JSONDecoder().decode(MedicationDatabaseFile.self, from: data)
            return file.medications
        } catch {
            throw MedicationDatabaseError.decodingFailed(String(describing: error))
        }
    }
}
