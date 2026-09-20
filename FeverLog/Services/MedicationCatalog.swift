import FeverLogEngine
import Foundation

/// Loads the bundled medication reference database (see
/// `FeverLogEngine.MedicationDatabase`) and provides simple brand/active-
/// ingredient search over it. This is static reference data shipped inside
/// the app bundle, so it works fully offline with no local caching needed.
enum MedicationCatalog {
    static func loadBundled() -> [MedicationRule] {
        (try? MedicationDatabase.loadBundled())?.filter(\.isActive) ?? []
    }

    /// Searches by brand or active ingredient. An empty/whitespace-only
    /// query returns every medication.
    static func search(_ medications: [MedicationRule], query: String) -> [MedicationRule] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return medications }
        let lowered = trimmed.lowercased()
        return medications.filter {
            $0.brand.lowercased().contains(lowered) || $0.activeIngredient.lowercased().contains(lowered)
        }
    }
}
