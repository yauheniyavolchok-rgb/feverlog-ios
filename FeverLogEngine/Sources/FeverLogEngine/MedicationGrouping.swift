import Foundation

/// Normalizes an active-ingredient name into a stable grouping key,
/// independent of brand, form, concentration, or locale-specific spelling
/// (e.g. US "acetaminophen" vs INN "paracetamol"). Different active
/// ingredients must never collapse into the same key — when in doubt, this
/// normalizer is conservative and leaves names distinct.
public enum ActiveIngredientNormalizer {
    /// Known cross-locale synonyms for the same active ingredient. Keys and
    /// values are already lowercased/folded.
    private static let synonyms: [String: String] = [
        "acetaminophen": "paracetamol",
        "paracetamol": "paracetamol",
        "ibuprofen": "ibuprofen"
    ]

    public static func normalize(_ activeIngredient: String) -> String {
        let folded = activeIngredient
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return synonyms[folded] ?? folded
    }
}

/// Groups and queries dose administrations by normalized active ingredient,
/// aggregating across brand, form, and concentration differences.
public enum MedicationGrouping {
    public static func group(_ doses: [DoseAdministration]) -> [String: [DoseAdministration]] {
        Dictionary(grouping: doses, by: \.normalizedActiveIngredientKey)
    }

    /// The most recent dose strictly before `administrationTime` for the
    /// given normalized key, or `nil` if none exists.
    public static func mostRecentPriorDose(
        in doses: [DoseAdministration],
        matchingNormalizedKey key: String,
        before administrationTime: Date
    ) -> DoseAdministration? {
        doses
            .filter { $0.normalizedActiveIngredientKey == key && $0.administeredAt < administrationTime }
            .max { $0.administeredAt < $1.administeredAt }
    }
}
