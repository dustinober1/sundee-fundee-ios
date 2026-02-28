import Foundation
import HealthKit

/// Reads sleep and HRV data from HealthKit to compute readiness metrics.
/// Read-only — no data is persisted to SwiftData.
final class HealthKitReadinessRepository: ReadinessRepository, @unchecked Sendable {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        ]
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    func fetchLatestMetrics() async throws -> ReadinessMetrics {
        async let sleep = fetchSleepHours()
        async let hrv = fetchHRV()
        async let rhr = fetchRestingHeartRate()
        return try await ReadinessMetrics(sleepHours: sleep, hrvRMSSD: hrv, restingHeartRate: rhr)
    }

    // MARK: - Private queries

    private func fetchSleepHours() async throws -> Double? {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 100
        )
        let samples = try await descriptor.result(for: healthStore)

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
        ]

        let totalSeconds = samples
            .filter { asleepValues.contains($0.value) }
            .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

        return totalSeconds > 0 ? totalSeconds / 3600.0 : nil
    }

    private func fetchHRV() async throws -> Double? {
        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: hrvType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        let samples = try await descriptor.result(for: healthStore)
        return samples.first?.quantity.doubleValue(for: .secondUnit(with: .milli))
    }

    private func fetchRestingHeartRate() async throws -> Double? {
        let rhrType = HKQuantityType(.restingHeartRate)
        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: rhrType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        let samples = try await descriptor.result(for: healthStore)
        return samples.first?.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
    }
}
