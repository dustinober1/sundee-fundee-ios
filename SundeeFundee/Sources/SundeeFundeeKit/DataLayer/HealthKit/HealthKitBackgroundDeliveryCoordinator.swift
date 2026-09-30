import Foundation
import HealthKit
import WidgetKit

// MARK: - HealthKitBackgroundDeliveryCoordinator

/// Coordinates background delivery and observer queries for autonomous morning readiness signals.
///
/// Observes nocturnal HRV, resting heart rate, and sleep analysis from Apple Watch,
/// refreshing the daily readiness snapshot and widget timeline before the user wakes.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public actor HealthKitBackgroundDeliveryCoordinator {
    // MARK: - Shared Instance

    public static let shared = HealthKitBackgroundDeliveryCoordinator()

    // MARK: - Properties

    private let healthClient: HealthClientProtocol
    private let readinessService: DailyReadinessService
    private var isObserving = false
    private var lastAssessmentTime: Date?

    /// Minimum time between background recalculations (15 minutes) to throttle batch deliveries.
    private let minimumRecalculationInterval: TimeInterval = 900

    // MARK: - Initialization

    public init(
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client,
        readinessService: DailyReadinessService? = nil
    ) {
        self.healthClient = healthClient
        self.readinessService = readinessService ?? DailyReadinessService(
            contextBuilder: DailyTrainingContextBuilder(),
            dataClient: DataClientFactory.shared.client
        )
    }

    // MARK: - Public API

    /// Starts observing background signals for HRV, resting heart rate, and sleep analysis.
    public func startObserving() async {
        guard healthClient.isAvailable, !isObserving else { return }

        isObserving = true

        let sampleTypes: [HKObjectType] = [
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        ].compactMap { $0 }

        for type in sampleTypes {
            do {
                try await healthClient.enableBackgroundDelivery(for: type, frequency: .immediate)
            } catch {
                // Background delivery is best-effort (e.g. if authorization not yet granted)
            }
        }
    }

    /// Triggers an autonomous morning readiness recalculation if enough time has elapsed.
    ///
    /// - Parameters:
    ///   - cyclePhase: Current cycle phase if available.
    ///   - cycleConfidence: Confidence level of cycle phase.
    ///   - force: Whether to bypass the 15-minute throttle interval.
    /// - Returns: True if readiness was updated; false if throttled or unavailable.
    @discardableResult
    public func evaluateMorningReadiness(
        cyclePhase: CyclePhase? = nil,
        cycleConfidence: Double? = nil,
        force: Bool = false
    ) async -> Bool {
        let now = Date()
        if !force, let last = lastAssessmentTime, now.timeIntervalSince(last) < minimumRecalculationInterval {
            return false
        }

        let result = await readinessService.calculateShadowAssessment(
            assessmentDate: now,
            timeZone: .current,
            cyclePhase: cyclePhase,
            cycleConfidence: cycleConfidence
        )

        guard result != nil else { return false }

        lastAssessmentTime = now
        WidgetCenter.shared.reloadTimelines(ofKind: "ReadinessWidget")
        return true
    }
}
