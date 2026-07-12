import Foundation
import HealthKit

public protocol HealthReadinessProviding: Sendable {
    func load(assessmentDate: Date, calendar: Calendar) async -> PhysiologicalReadinessSnapshot
}

public actor HealthReadinessProvider: HealthReadinessProviding {
    private let healthClient: any HealthClientProtocol

    public init(healthClient: any HealthClientProtocol = HealthClientFactory.shared.client) {
        self.healthClient = healthClient
    }

    public func load(assessmentDate: Date, calendar: Calendar) async -> PhysiologicalReadinessSnapshot {
        guard healthClient.isAvailable else { return .empty }

        let startDate = calendar.date(byAdding: .day, value: -29, to: assessmentDate) ?? assessmentDate
        async let hrvResult = try? healthClient.fetchHeartRateVariability(
            startDate: startDate, endDate: assessmentDate
        )
        async let restingHeartRateResult = try? healthClient.fetchRestingHeartRate(
            startDate: startDate, endDate: assessmentDate
        )
        async let sleepResult = try? healthClient.fetchSleepAnalysis(
            startDate: startDate, endDate: assessmentDate
        )

        let (hrvSamples, restingHeartRateSamples, sleepSamples) = await (
            hrvResult ?? [], restingHeartRateResult ?? [], sleepResult ?? []
        )

        return PhysiologicalReadinessSnapshot(
            sleepHours: sleepSnapshot(sleepSamples, calendar: calendar),
            hrvMilliseconds: quantitySnapshot(
                hrvSamples,
                unit: .secondUnit(with: .milli),
                calendar: calendar
            ),
            restingHeartRateBPM: quantitySnapshot(
                restingHeartRateSamples,
                unit: .count().unitDivided(by: .minute()),
                calendar: calendar
            )
        )
    }

    private func quantitySnapshot(
        _ samples: [HKQuantitySample],
        unit: HKUnit,
        calendar: Calendar
    ) -> ReadinessMetricSnapshot? {
        let daily = Dictionary(grouping: samples) { calendar.startOfDay(for: $0.endDate) }
            .compactMap { day, values -> (Date, Double)? in
                guard let value = ReadinessBaselineNormalizer.median(
                    values.map { $0.quantity.doubleValue(for: unit) }
                ), value > 0 else { return nil }
                return (day, value)
            }
            .sorted { $0.0 > $1.0 }

        guard let current = daily.first else { return nil }
        return ReadinessMetricSnapshot(
            currentValue: current.1,
            baselineValues: Array(daily.dropFirst().prefix(28).map(\.1)),
            observedAt: current.0
        )
    }

    private func sleepSnapshot(
        _ samples: [HKCategorySample],
        calendar: Calendar
    ) -> ReadinessMetricSnapshot? {
        let daily = Dictionary(grouping: samples) { calendar.startOfDay(for: $0.endDate) }
            .compactMap { day, values -> (Date, Double)? in
                let rawSamples = values.map {
                    SleepDeduplicator.SleepSampleValue(
                        start: $0.startDate,
                        end: $0.endDate,
                        value: $0.value,
                        sourceName: $0.sourceRevision.source.name
                    )
                }
                let intervals = SleepDeduplicator.convertSamples(values: rawSamples)
                let hours = SleepDeduplicator.deduplicate(intervals) / 3600
                guard hours > 0 else { return nil }
                return (day, hours)
            }
            .sorted { $0.0 > $1.0 }

        guard let current = daily.first else { return nil }
        return ReadinessMetricSnapshot(
            currentValue: current.1,
            baselineValues: Array(daily.dropFirst().prefix(28).map(\.1)),
            observedAt: current.0
        )
    }
}
