// WatchWorkoutManager.swift
// SundeeFundeeWatch
//
// Standalone workout session manager for Apple Watch with live optical sensor metrics.

import Foundation
import HealthKit
import SwiftUI
import WatchKit
import SundeeFundeeKit

@MainActor
public final class WatchWorkoutManager: ObservableObject {
    public static let shared = WatchWorkoutManager()

    // MARK: - Published State

    @Published public private(set) var isTrackingStandalone: Bool = false
    @Published public private(set) var currentHeartRate: Double = 0.0
    @Published public private(set) var activeCalories: Double = 0.0
    @Published public private(set) var elapsedSeconds: TimeInterval = 0.0
    @Published public private(set) var completedSets: Int = 0
    @Published public private(set) var isResting: Bool = false
    @Published public private(set) var restRemainingSeconds: Int = 0

    // MARK: - HealthKit Properties

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var delegateForwarder: HealthKitWorkoutDelegateForwarder?
    private var workoutStartDate: Date?
    private var timer: Timer?
    private var restTimer: Timer?
    private var lastHapticSecond: Int?

    private init() {}

    // MARK: - Workout Control

    public func startStandaloneWorkout() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        } catch {
            return
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()

            let forwarder = HealthKitWorkoutDelegateForwarder(manager: self)
            self.delegateForwarder = forwarder
            session?.delegate = forwarder
            builder?.delegate = forwarder

            builder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            let startDate = Date()
            workoutStartDate = startDate
            session?.startActivity(with: startDate)
            builder?.beginCollection(withStart: startDate) { _, _ in }

            isTrackingStandalone = true
            completedSets = 0
            currentHeartRate = 0
            activeCalories = 0
            elapsedSeconds = 0
            isResting = false

            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, let start = self.workoutStartDate else { return }
                    self.elapsedSeconds = Date().timeIntervalSince(start)
                }
            }

            WKInterfaceDevice.current().play(.start)
        } catch {
            isTrackingStandalone = false
        }
    }

    public func logSetCompleted() {
        completedSets += 1
        WKInterfaceDevice.current().play(.success)
        startRest(seconds: 90)
    }

    public func startRest(seconds: Int) {
        isResting = true
        restRemainingSeconds = seconds
        lastHapticSecond = nil

        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.restRemainingSeconds > 0 {
                    self.restRemainingSeconds -= 1
                    self.playCountdownHapticsIfNeeded(seconds: self.restRemainingSeconds)
                } else {
                    self.skipRest()
                }
            }
        }
    }

    public func skipRest() {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
        restRemainingSeconds = 0
        WKInterfaceDevice.current().play(.click)
    }

    public func addRest(seconds: Int = 30) {
        restRemainingSeconds += seconds
        WKInterfaceDevice.current().play(.click)
    }

    public func endStandaloneWorkout() async {
        timer?.invalidate()
        timer = nil
        restTimer?.invalidate()
        restTimer = nil

        session?.end()
        if let builder {
            _ = try? await builder.endCollection(at: Date())
            _ = try? await builder.finishWorkout()
        }

        WKInterfaceDevice.current().play(.stop)

        isTrackingStandalone = false
        isResting = false
        session = nil
        builder = nil
        delegateForwarder = nil
    }

    // MARK: - Internal Delegate Callbacks

    func updateHeartRate(_ rate: Double) {
        currentHeartRate = rate
    }

    func updateCalories(_ calories: Double) {
        activeCalories = calories
    }

    func handleSessionFailed() {
        isTrackingStandalone = false
    }

    // MARK: - Haptics

    private func playCountdownHapticsIfNeeded(seconds: Int) {
        guard lastHapticSecond != seconds else { return }
        lastHapticSecond = seconds

        switch seconds {
        case 3, 2, 1:
            WKInterfaceDevice.current().play(.click)
        case 0:
            WKInterfaceDevice.current().play(.stop)
        default:
            break
        }
    }
}

// MARK: - HealthKitWorkoutDelegateForwarder

private final class HealthKitWorkoutDelegateForwarder: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, @unchecked Sendable {
    private weak var manager: WatchWorkoutManager?

    init(manager: WatchWorkoutManager) {
        self.manager = manager
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {}

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        Task { @MainActor [weak manager] in
            manager?.handleSessionFailed()
        }
    }

    func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            let statistics = workoutBuilder.statistics(for: quantityType)

            if quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                if let value = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) {
                    Task { @MainActor [weak manager] in
                        manager?.updateHeartRate(value)
                    }
                }
            } else if quantityType == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                let calorieUnit = HKUnit.kilocalorie()
                if let value = statistics?.sumQuantity()?.doubleValue(for: calorieUnit) {
                    Task { @MainActor [weak manager] in
                        manager?.updateCalories(value)
                    }
                }
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
