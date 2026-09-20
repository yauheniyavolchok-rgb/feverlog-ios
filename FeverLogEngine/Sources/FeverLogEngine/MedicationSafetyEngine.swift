import Foundation

/// The child's weight at the administration instant, as resolved by the
/// application layer (the latest non-deleted `WeightHistory` entry whose
/// effective date is on or before the administration time). The engine
/// never infers a weight — `.missing` is an explicit, first-class state.
public enum WeightInput: Equatable, Sendable {
    case known(kilograms: Decimal)
    case missing
}

public enum MedicationSafetyStatus: String, Equatable, Hashable, Sendable {
    case normal
    case missingWeight
    case missingRule
    case intervalWarning
    case approachingMaximum
    case unusualDose
    case maximumExceeded
    case invalidInput
}

/// Typed, non-localized reason codes. The application layer maps these to
/// localized, non-diagnostic copy — the engine never produces user-facing
/// text itself.
public enum MedicationExplanationCode: String, Equatable, Hashable, Sendable {
    case intervalNotElapsed
    case approachingDailyMaximum
    case dailyMaximumExceeded
    case missingWeightForCalculation
    case missingConfiguredRule
    case invalidVolumeOrConcentration
    case noPriorDose
}

/// The full result of evaluating one candidate dose. All rolling-window
/// values (`rollingTotalMilligrams`, `rollingTotalMilligramsPerKilogram`,
/// `doseCount`) are **projected/post-save** figures — i.e. prior doses in
/// the rolling window plus this candidate dose — since that is what a
/// caller deciding whether to save actually needs to know.
public struct MedicationSafetyResult: Equatable, Sendable {
    public let statuses: Set<MedicationSafetyStatus>
    public let calculatedMilligrams: Decimal?
    public let calculatedMilligramsPerKilogram: Decimal?
    public let rollingTotalMilligrams: Decimal?
    public let rollingTotalMilligramsPerKilogram: Decimal?
    public let doseCount: Int?
    public let nextEligibleDate: Date?
    public let explanationCodes: [MedicationExplanationCode]
}

public struct MedicationDoseEvaluationInput: Sendable {
    public let rule: MedicationRule
    public let volumeMilliliters: Decimal
    public let weight: WeightInput
    public let administrationTime: Date
    /// All of the child's prior dose administrations (any active
    /// ingredient) — the engine filters to the matching normalized key
    /// internally.
    public let priorDoses: [DoseAdministration]

    public init(
        rule: MedicationRule,
        volumeMilliliters: Decimal,
        weight: WeightInput,
        administrationTime: Date,
        priorDoses: [DoseAdministration]
    ) {
        self.rule = rule
        self.volumeMilliliters = volumeMilliliters
        self.weight = weight
        self.administrationTime = administrationTime
        self.priorDoses = priorDoses
    }
}

/// The rolling-window totals projected to include the candidate dose being
/// evaluated, alongside the normalized grouping key used to compute them.
private struct ProjectedTotals {
    let normalizedKey: String
    let totalMilligrams: Decimal
    let totalMilligramsPerKilogram: Decimal?
    let doseCount: Int

    init(input: MedicationDoseEvaluationInput, calculatedMilligrams: Decimal, weightKilograms: Decimal?) {
        normalizedKey = input.rule.normalizedActiveIngredientKey
        let windowResult = RollingWindow.doses(
            from: input.priorDoses,
            matchingNormalizedKey: normalizedKey,
            at: input.administrationTime
        )
        let total = windowResult.totalMilligrams + calculatedMilligrams
        totalMilligrams = total
        doseCount = windowResult.doseCount + 1
        totalMilligramsPerKilogram = weightKilograms.map { total / $0 }
    }
}

/// Accumulates findings while evaluating one dose. Kept private — callers
/// only ever see the immutable `MedicationSafetyResult`.
private struct EvaluationFindings {
    var statuses: Set<MedicationSafetyStatus> = []
    var explanationCodes: [MedicationExplanationCode] = []

    mutating func addExceeded() {
        statuses.insert(.maximumExceeded)
        addExplanationOnce(.dailyMaximumExceeded)
    }

    mutating func addApproaching() {
        statuses.insert(.approachingMaximum)
        addExplanationOnce(.approachingDailyMaximum)
    }

    mutating func addExplanationOnce(_ code: MedicationExplanationCode) {
        if !explanationCodes.contains(code) {
            explanationCodes.append(code)
        }
    }
}

/// Deterministic, dependency-free medication dose safety evaluation. This
/// is not a diagnostic tool and does not provide medical advice — it
/// calculates against the configured rule and reports findings; the
/// application layer is responsible for non-diagnostic, localized
/// presentation and for telling users to verify against the product label
/// or a qualified professional.
public enum MedicationSafetyEngine {
    /// TODO(Phase 6, safety copy contract): validate this threshold with product/medical review
    /// alongside the rest of the safety copy contract.
    static let approachingMaximumThresholdFraction: Decimal = 0.8

    public static func evaluate(_ input: MedicationDoseEvaluationInput) -> MedicationSafetyResult {
        let milligramsResult = DoseCalculator.milligrams(
            volumeMilliliters: input.volumeMilliliters,
            concentration: input.rule.concentration
        )

        guard case .success(let calculatedMilligrams) = milligramsResult else {
            return MedicationSafetyResult(
                statuses: [.invalidInput],
                calculatedMilligrams: nil,
                calculatedMilligramsPerKilogram: nil,
                rollingTotalMilligrams: nil,
                rollingTotalMilligramsPerKilogram: nil,
                doseCount: nil,
                nextEligibleDate: nil,
                explanationCodes: [.invalidVolumeOrConcentration]
            )
        }

        var findings = EvaluationFindings()

        let weightKilograms = resolvedWeightKilograms(input.weight, findings: &findings)
        let calculatedMgPerKg = weightKilograms.map { calculatedMilligrams / $0 }
        let projected = ProjectedTotals(input: input, calculatedMilligrams: calculatedMilligrams, weightKilograms: weightKilograms)

        let nextEligibleDate = checkInterval(input: input, normalizedKey: projected.normalizedKey, findings: &findings)
        checkRuleConfigured(rule: input.rule, findings: &findings)
        checkDailyMaximums(rule: input.rule, projected: projected, findings: &findings)
        checkSingleDose(
            rule: input.rule,
            calculatedMilligrams: calculatedMilligrams,
            calculatedMgPerKg: calculatedMgPerKg,
            findings: &findings
        )

        if findings.statuses.isEmpty {
            findings.statuses.insert(.normal)
        }

        return MedicationSafetyResult(
            statuses: findings.statuses,
            calculatedMilligrams: calculatedMilligrams,
            calculatedMilligramsPerKilogram: calculatedMgPerKg,
            rollingTotalMilligrams: projected.totalMilligrams,
            rollingTotalMilligramsPerKilogram: projected.totalMilligramsPerKilogram,
            doseCount: projected.doseCount,
            nextEligibleDate: nextEligibleDate,
            explanationCodes: findings.explanationCodes
        )
    }

    private static func resolvedWeightKilograms(_ weight: WeightInput, findings: inout EvaluationFindings) -> Decimal? {
        if case .known(let kilograms) = weight, kilograms > 0 {
            return kilograms
        }
        findings.statuses.insert(.missingWeight)
        findings.addExplanationOnce(.missingWeightForCalculation)
        return nil
    }

    private static func checkInterval(
        input: MedicationDoseEvaluationInput,
        normalizedKey: String,
        findings: inout EvaluationFindings
    ) -> Date? {
        guard let priorDose = MedicationGrouping.mostRecentPriorDose(
            in: input.priorDoses,
            matchingNormalizedKey: normalizedKey,
            before: input.administrationTime
        ) else {
            findings.addExplanationOnce(.noPriorDose)
            return nil
        }

        guard let minInterval = input.rule.dailyMaximumRule?.minimumIntervalSeconds else {
            return nil
        }

        let elapsed = input.administrationTime.timeIntervalSince(priorDose.administeredAt)
        if elapsed < minInterval {
            findings.statuses.insert(.intervalWarning)
            findings.addExplanationOnce(.intervalNotElapsed)
        }
        return priorDose.administeredAt.addingTimeInterval(minInterval)
    }

    private static func checkRuleConfigured(rule: MedicationRule, findings: inout EvaluationFindings) {
        guard rule.singleDoseRule == nil, rule.dailyMaximumRule == nil else { return }
        findings.statuses.insert(.missingRule)
        findings.addExplanationOnce(.missingConfiguredRule)
    }

    private static func checkDailyMaximums(rule: MedicationRule, projected: ProjectedTotals, findings: inout EvaluationFindings) {
        guard let dailyMax = rule.dailyMaximumRule else { return }

        if let maxMgPerDay = dailyMax.maxMilligramsPerDay {
            applyMaximumCheck(value: projected.totalMilligrams, limit: maxMgPerDay, findings: &findings)
        }
        if let maxMgPerKgPerDay = dailyMax.maxMilligramsPerKilogramPerDay, let perKg = projected.totalMilligramsPerKilogram {
            applyMaximumCheck(value: perKg, limit: maxMgPerKgPerDay, findings: &findings)
        }
        if let maxDoses = dailyMax.maxDosesPerDay, projected.doseCount > maxDoses {
            findings.addExceeded()
        }
    }

    private static func checkSingleDose(
        rule: MedicationRule,
        calculatedMilligrams: Decimal,
        calculatedMgPerKg: Decimal?,
        findings: inout EvaluationFindings
    ) {
        guard let singleDose = rule.singleDoseRule else { return }

        if let maxPerDose = singleDose.maxMilligramsPerDose, calculatedMilligrams > maxPerDose {
            findings.statuses.insert(.unusualDose)
        }
        if let maxMgPerKg = singleDose.maxMilligramsPerKilogram, let calculatedMgPerKg, calculatedMgPerKg > maxMgPerKg {
            findings.statuses.insert(.unusualDose)
        }
        if let minMgPerKg = singleDose.minMilligramsPerKilogram, let calculatedMgPerKg, calculatedMgPerKg < minMgPerKg {
            findings.statuses.insert(.unusualDose)
        }
    }

    private static func applyMaximumCheck(value: Decimal, limit: Decimal, findings: inout EvaluationFindings) {
        if value > limit {
            findings.addExceeded()
        } else if value >= limit * approachingMaximumThresholdFraction {
            findings.addApproaching()
        }
    }
}
