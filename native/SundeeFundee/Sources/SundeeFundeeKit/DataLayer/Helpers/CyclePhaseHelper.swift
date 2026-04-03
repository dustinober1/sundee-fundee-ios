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
    /// - Returns: A CycleStatusResult if sufficient data, otherwise nil
    public static func calculatePhase(
        from samples: [HKCategorySample],
        settings: CycleSettings = CycleSettings(),
        referenceDate: Date = Date()
    ) -> CycleStatusResult? {
        let periodLogs = convertToPeriodLogs(samples)
        guard !periodLogs.isEmpty else { return nil }
        return calculateCycleStatus(
            periodLogs: periodLogs,
            settings: settings,
            referenceDate: referenceDate
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
        var currentStart: Date? = nil
        var currentEnd: Date? = nil

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

    /// Calculate confidence based on available cycle data.
    ///
    /// More period logs = higher confidence. Recent data = higher confidence.
    public static func calculateConfidence(
        periodLogCount: Int,
        lastPeriodStart: Date?,
        referenceDate: Date = Date()
    ) -> Double {
        guard periodLogCount > 0, let lastStart = lastPeriodStart else {
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

        return min(countConfidence * recencyMultiplier, 1.0)
    }
}
