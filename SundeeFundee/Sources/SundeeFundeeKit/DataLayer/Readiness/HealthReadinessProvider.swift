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
            sleepHours: sleepSnapshot(sleepSamples, assessmentDate: assessmentDate, calendar: calendar),
            hrvMilliseconds: quantitySnapshot(
                hrvSamples,
                assessmentDate: assessmentDate,
                unit: .secondUnit(with: .milli), calendar: calendar
            ),
            restingHeartRateBPM: quantitySnapshot(
                restingHeartRateSamples,
                assessmentDate: assessmentDate,
                unit: .count().unitDivided(by: .minute()), calendar: calendar
            )
        )
    }

    private func quantitySnapshot(
        _ samples: [HKQuantitySample],
        assessmentDate: Date,
        unit: HKUnit,
        calendar: Calendar
    ) -> ReadinessMetricSnapshot? {
        let assessmentDay = calendar.startOfDay(for: assessmentDate)
        let daily = Dictionary(grouping: samples) { calendar.startOfDay(for: $0.endDate) }
            .compactMap { day, values -> (Date, Double)? in
                guard let value = ReadinessBaselineNormalizer.median(
                    values.map { $0.quantity.doubleValue(for: unit) }
                ), value > 0 else { return nil }
                return (day, value)
            }
            .filter { $0.0 <= assessmentDay }
            .sorted { $0.0 > $1.0 }

        guard let current = daily.first(where: { $0.0 == assessmentDay }) else { return nil }
        return ReadinessMetricSnapshot(
            currentValue: current.1,
            baselineValues: Array(daily.filter { $0.0 < assessmentDay }.prefix(28).map(\.1)),
            observedAt: current.0
        )
    }

    private func sleepSnapshot(
        _ samples: [HKCategorySample],
        assessmentDate: Date,
        calendar: Calendar
    ) -> ReadinessMetricSnapshot? {
        let assessmentDay = calendar.startOfDay(for: assessmentDate)
        let splitSamples = samples.flatMap { splitSleepSample($0, calendar: calendar) }
        let daily = Dictionary(grouping: splitSamples) { calendar.startOfDay(for: $0.start) }
            .compactMap { day, values -> (Date, Double)? in
                let rawSamples = values.map {
                    SleepDeduplicator.SleepSampleValue(
                        start: $0.start, end: $0.end,
                        value: $0.value, sourceName: $0.sourceName
                    )
                }
                let intervals = SleepDeduplicator.convertSamples(values: rawSamples)
                let hours = SleepDeduplicator.deduplicate(intervals) / 3600
                guard hours > 0 else { return nil }
                return (day, hours)
            }
            .filter { $0.0 <= assessmentDay }
            .sorted { $0.0 > $1.0 }

        guard let current = daily.first(where: { $0.0 == assessmentDay }) else { return nil }
        return ReadinessMetricSnapshot(
            currentValue: current.1,
            baselineValues: Array(daily.filter { $0.0 < assessmentDay }.prefix(28).map(\.1)),
            observedAt: current.0
        )
    }

    private func splitSleepSample(
        _ sample: HKCategorySample,
        calendar: Calendar
    ) -> [SleepDeduplicator.SleepSampleValue] {
        guard sample.endDate > sample.startDate else { return [] }
        var result: [SleepDeduplicator.SleepSampleValue] = []
        var cursor = sample.startDate
        while cursor < sample.endDate {
            let dayStart = calendar.startOfDay(for: cursor)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else { break }
            let segmentEnd = min(nextDay, sample.endDate)
            result.append(SleepDeduplicator.SleepSampleValue(
                start: cursor, end: segmentEnd, value: sample.value,
                sourceName: sample.sourceRevision.source.name
            ))
            cursor = segmentEnd
        }
        return result
    }
}
