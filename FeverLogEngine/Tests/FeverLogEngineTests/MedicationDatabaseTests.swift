import Testing
@testable import FeverLogEngine

@Suite("MedicationDatabase")
struct MedicationDatabaseTests {
    @Test("loads the bundled database without throwing")
    func loadsBundledDatabase() throws {
        let medications = try MedicationDatabase.loadBundled()
        #expect(!medications.isEmpty)
    }

    @Test("every bundled entry has source provenance and a review status")
    func everyEntryHasProvenance() throws {
        let medications = try MedicationDatabase.loadBundled()
        for medication in medications {
            #expect(!medication.sourceIdentifier.isEmpty)
            #expect(!medication.sourceVersion.isEmpty)
            #expect(medication.databaseSchemaVersion == MedicationDatabase.schemaVersion)
        }
    }

    @Test("no bundled entry is marked reviewed without a real source (documents current unreviewed state)")
    func noEntryIsPrematurelyMarkedReviewed() throws {
        let medications = try MedicationDatabase.loadBundled()
        // TODO(Phase 5, medication data review): this test should start failing
        // (and be updated) once entries have gone through qualified review.
        for medication in medications {
            #expect(medication.reviewStatus == .unreviewed)
        }
    }

    @Test("decimal concentration values decode without floating-point drift")
    func decimalConcentrationDecodesExactly() throws {
        let medications = try MedicationDatabase.loadBundled()
        let paracetamol = try #require(medications.first { $0.id == "paracetamol-generic-160-5-suspension-example" })
        #expect(paracetamol.concentration.milligrams == 160)
        #expect(paracetamol.concentration.milliliters == 5)
        #expect(paracetamol.concentration.milligramsPerMilliliter == 32)
    }
}
