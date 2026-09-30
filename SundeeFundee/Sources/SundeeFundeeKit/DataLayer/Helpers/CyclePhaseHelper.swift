import Foundation
import HealthKit

// MARK: - Cycle Phase Helper

/// Bridges HealthKit menstrual data to domain cycle calculations.
/// Converts HKCategorySample menstrual flow events into PeriodLog entries,
/// then uses calculateCycleStatus() to determine the current cycle phase.
public struct CyclePhaseHelper {
    /// Calculate the current cycle phase from HealthKit menstrual samples.
    ///
    /// - Parameters:
    ///   - samples: Menstrual flow samples from HealthKit (HKCategoryTypeIdentifier.menstrualFlow)
    ///   - settings: Cycle settings (defaults to standard 28-day cycle)
    ///   - referenceDate: Date to calculate phase for (defaults to now)
    ///   - biomarkerEvidence: Optional objective biomarker evidence from wrist temperature or LH surge
    /// - Returns: A CycleStatusResult if sufficient data, otherwise nil
    public static func calculatePhase(
        from samples: [HKCategorySample],
        settings: CycleSettings = CycleSettings(),
        referenceDate: Date = Date(),
        biomarkerEvidence: OvulationBiomarkerEvidence? = nil
    ) -> CycleStatusResult? {
        let periodLogs = convertToPeriodLogs(samples)
        guard !periodLogs.isEmpty else { return nil }
        return calculateCycleStatus(
            periodLogs: periodLogs,
            settings: settings,
            referenceDate: referenceDate,
            biomarkerEvidence: biomarkerEvidence
        )
    }

    /// Convert HealthKit menstrual flow samples to PeriodLog entries.
    ///
    /// Groups consecutive menstrual flow days into period log entries.
    /// Each group becomes one PeriodLog with startDate = first day, endDate = last day.
    public static func convertToPeriodLogs(_ samples: [HKCategorySample]) -> [PeriodLog] {
        guard !samples.isEmpty else { return [] }

        // Sort by start date ascending
        let sorted = samples.sorted { $0.startDate < $1.startDate }

        var logs: [PeriodLog] = []
        var currentStart: Date?
        var currentEnd: Date?

        for sample in sorted {
            let sampleDate = Calendar.current.startOfDay(for: sample.startDate)

            if let end = currentEnd {
                // If this sample is within 2 days of the last, extend the period
                let daysSinceEnd = Calendar.current.dateComponents(
                    [.day],
                    from: Calendar.current.startOfDay(for: end),
                    to: sampleDate
                ).day ?? 0

                if daysSinceEnd <= 2 {
                    currentEnd = sample.endDate
                    continue
                }
            }

            // Save previous period if exists
            if let start = currentStart {
                logs.append(PeriodLog(startDate: start, endDate: currentEnd))
            }

            // Start new period
            currentStart = sample.startDate
            currentEnd = sample.endDate
        }

        // Save last period
        if let start = currentStart {
            logs.append(PeriodLog(startDate: start, endDate: currentEnd))
        }

        return logs
    }

    /// Analyzes HealthKit nocturnal sleeping wrist temperatures and ovulation test samples
    /// to detect objective physiological signs of ovulation.
    ///
    /// - Parameters:
    ///   - temperatureSamples: Sleeping wrist temperature quantity samples.
    ///   - ovulationTestSamples: Ovulation test result category samples.
    ///   - referenceDate: Reference calculation date (defaults to now).
    /// - Returns: An `OvulationBiomarkerEvidence` summarizing biomarker findings.
    public static func detectOvulationBiomarkers(
        temperatureSamples: [HKQuantitySample],
        ovulationTestSamples: [HKCategorySample],
        referenceDate: Date = Date()
    ) -> OvulationBiomarkerEvidence {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: referenceDate) ?? referenceDate

        // 1. Check for LH surge (positive / luteinizingHormoneSurge ovulation test result)
        var detectedLHSurgeDate: Date?
        var estimatedOvulationDate: Date?

        let recentTests = ovulationTestSamples.filter { $0.startDate >= thirtyDaysAgo }
        let sortedTests = recentTests.sorted { $0.startDate > $1.startDate }
        if let surgeSample = sortedTests.first(where: {
            $0.value == HKCategoryValueOvulationTestResult.positive.rawValue
        }) {
            detectedLHSurgeDate = surgeSample.startDate
            // Ovulation typically occurs 24-36 hours after LH surge
            estimatedOvulationDate = calendar.date(byAdding: .day, value: 1, to: surgeSample.startDate)
        }

        // 2. Check for thermal shift (Apple Watch sleeping wrist temperature)
        let recentTemps = temperatureSamples.filter { $0.startDate >= thirtyDaysAgo }
        var dailyTemps: [Date: [Double]] = [:]
        for sample in recentTemps {
            let day = calendar.startOfDay(for: sample.startDate)
            let tempC = sample.quantity.doubleValue(for: HKUnit.degreeCelsius())
            dailyTemps[day, default: []].append(tempC)
        }

        // Compute daily averages and sort chronologically
        let sortedDays = dailyTemps.map { (date: $0.key, temp: $0.value.reduce(0.0, +) / Double($0.value.count)) }
            .sorted { $0.date < $1.date }

        var hasThermalShift = false
        var shiftMagnitude: Double?

        // Symptothermal thermal shift rule:
        // Look for at least 2-3 consecutive days with temperatures >= 0.20°C above
        // the average of the preceding baseline days (at least 3 baseline days).
        if sortedDays.count >= 5 {
            for i in 3..<(sortedDays.count - 1) {
                let baselineSlice = sortedDays[max(0, i - 6)..<i]
                let baselineAvg = baselineSlice.map(\.temp).reduce(0.0, +) / Double(baselineSlice.count)

                let postSlice = sortedDays[i..<min(sortedDays.count, i + 3)]
                let postAvg = postSlice.map(\.temp).reduce(0.0, +) / Double(postSlice.count)

                let diff = postAvg - baselineAvg
                if diff >= 0.20 {
                    hasThermalShift = true
                    shiftMagnitude = diff
                    if estimatedOvulationDate == nil {
                        // Ovulation occurs right before the sustained progesterone rise
                        estimatedOvulationDate = sortedDays[i - 1].date
                    }
                    break
                }
            }
        }

        return OvulationBiomarkerEvidence(
            lhSurgeDate: detectedLHSurgeDate,
            estimatedOvulationDate: estimatedOvulationDate,
            hasThermalShift: hasThermalShift,
            thermalShiftCelsius: shiftMagnitude
        )
    }

    /// Calculate confidence based on available cycle data.
    ///
    /// More period logs = higher confidence. Recent data = higher confidence.
    /// Objective biomarkers (sleeping wrist temperature shift or LH surge) boost confidence to >= 0.95.
    public static func calculateConfidence(
        periodLogCount: Int,
        lastPeriodStart: Date?,
        referenceDate: Date = Date(),
        biomarkerEvidence: OvulationBiomarkerEvidence? = nil
    ) -> Double {
        guard periodLogCount > 0, let lastStart = lastPeriodStart else {
            if let biomarker = biomarkerEvidence, biomarker.hasBiomarkerConfirmation {
                return 0.95
            }
            return 0.0
        }

        let daysSince = referenceDate.timeIntervalSince(lastStart) / (60 * 60 * 24)

        // Base confidence from log count
        let countConfidence: Double
        switch periodLogCount {
        case 1: countConfidence = 0.4
        case 2: countConfidence = 0.6
        case 3...5: countConfidence = 0.8
        default: countConfidence = 0.9
        }

        // Recency penalty - data older than 60 days is less reliable
        let recencyMultiplier: Double
        if daysSince <= 35 {
            recencyMultiplier = 1.0
        } else if daysSince <= 60 {
            recencyMultiplier = 0.8
        } else {
            recencyMultiplier = 0.5
        }

        var confidence = min(countConfidence * recencyMultiplier, 1.0)
        if let biomarker = biomarkerEvidence, biomarker.hasBiomarkerConfirmation {
            confidence = max(confidence, 0.95)
        }
        return confidence
    }
}
