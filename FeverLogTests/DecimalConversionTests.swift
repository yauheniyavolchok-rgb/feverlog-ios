import Foundation
import Testing
@testable import FeverLog

@Suite("Decimal conversion")
struct DecimalConversionTests {
    @Test("fromUserInput avoids binary floating-point drift")
    func fromUserInputAvoidsDrift() {
        #expect(Decimal.fromUserInput(0.1) == Decimal(string: "0.1"))
        #expect(Decimal.fromUserInput(10.4) == Decimal(string: "10.4"))
    }

    @Test("doubleValue round-trips a simple decimal value")
    func doubleValueRoundTrips() {
        let decimal = Decimal(string: "16.5") ?? 0
        #expect(decimal.doubleValue == 16.5)
    }
}

@Suite("WeightConversion")
struct WeightConversionTests {
    @Test("kilograms input passes through unchanged")
    func kilogramsPassThrough() {
        let result = WeightConversion.kilograms(from: 10.4, unit: .kilograms)
        #expect(result == Decimal(string: "10.4"))
    }

    @Test("pounds are converted to kilograms")
    func poundsAreConverted() {
        let result = WeightConversion.kilograms(from: 22, unit: .pounds)
        // 22 lb ≈ 9.979 kg
        #expect(result > Decimal(string: "9.9") ?? 0)
        #expect(result < Decimal(string: "10.0") ?? 0)
    }
}
