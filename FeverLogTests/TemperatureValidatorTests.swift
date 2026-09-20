import Testing
@testable import FeverLog

@Suite("TemperatureValidator")
struct TemperatureValidatorTests {
    @Test(
        "accepts values within the supported range",
        arguments: [34.0, 34.1, 37.0, 40.0, 42.0]
    )
    func acceptsInRangeValues(value: Double) {
        let result = TemperatureValidator.validate(value)
        #expect(result == .success(value))
    }

    @Test(
        "rejects values outside the supported range",
        arguments: [33.9, 20.0, 42.1, 50.0, 0.0, -5.0]
    )
    func rejectsOutOfRangeValues(value: Double) {
        let result = TemperatureValidator.validate(value)
        #expect(result == .failure(.outOfRange))
    }

    @Test("rounds to one decimal place")
    func roundsToOneDecimal() {
        let result = TemperatureValidator.validate(37.049)
        #expect(result == .success(37.0))

        let result2 = TemperatureValidator.validate(37.05)
        #expect(result2 == .success(37.1))
    }
}
