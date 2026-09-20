import Testing
@testable import FeverLogEngine

@Suite("DoseCalculator")
struct DoseCalculatorTests {
    @Test("converts milliliters to milligrams using X/Y concentration")
    func convertsMillilitersToMilligrams() {
        let concentration = Concentration(milligrams: 160, milliliters: 5)
        let result = DoseCalculator.milligrams(volumeMilliliters: 5, concentration: concentration)
        #expect(result == .success(160))
    }

    @Test("computes milligrams for a fractional volume")
    func computesFractionalVolume() {
        let concentration = Concentration(milligrams: 100, milliliters: 5)
        let result = DoseCalculator.milligrams(volumeMilliliters: 2.5, concentration: concentration)
        #expect(result == .success(50))
    }

    @Test("rejects zero or negative volume")
    func rejectsInvalidVolume() {
        let concentration = Concentration(milligrams: 160, milliliters: 5)
        #expect(DoseCalculator.milligrams(volumeMilliliters: 0, concentration: concentration) == .failure(.invalidVolume))
        #expect(DoseCalculator.milligrams(volumeMilliliters: -1, concentration: concentration) == .failure(.invalidVolume))
    }

    @Test("rejects zero or negative concentration")
    func rejectsInvalidConcentration() {
        let zeroMilligrams = Concentration(milligrams: 0, milliliters: 5)
        let zeroMilliliters = Concentration(milligrams: 160, milliliters: 0)
        #expect(DoseCalculator.milligrams(volumeMilliliters: 5, concentration: zeroMilligrams) == .failure(.invalidConcentration))
        #expect(DoseCalculator.milligrams(volumeMilliliters: 5, concentration: zeroMilliliters) == .failure(.invalidConcentration))
    }

    @Test("computes milligrams per kilogram")
    func computesMilligramsPerKilogram() {
        let result = DoseCalculator.milligramsPerKilogram(milligrams: 160, weightKilograms: 10)
        #expect(result == 16)
    }

    @Test("returns nil for milligrams per kilogram with a non-positive weight")
    func returnsNilForInvalidWeight() {
        #expect(DoseCalculator.milligramsPerKilogram(milligrams: 160, weightKilograms: 0) == nil)
        #expect(DoseCalculator.milligramsPerKilogram(milligrams: 160, weightKilograms: -5) == nil)
    }

    @Test("decimal precision does not drift at a 0.1 mL boundary")
    func decimalPrecisionAtFineGrainedVolume() {
        let concentration = Concentration(milligrams: 100, milliliters: 5)
        // 5.1 mL * (100/5 mg/mL) should be exactly 102, not 101.99999999.
        let result = DoseCalculator.milligrams(volumeMilliliters: 5.1, concentration: concentration)
        #expect(result == .success(102))
    }
}
