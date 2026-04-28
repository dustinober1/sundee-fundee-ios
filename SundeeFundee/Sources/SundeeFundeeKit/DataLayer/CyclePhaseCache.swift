import Foundation
import SwiftUI
import WidgetKit

// MARK: - CyclePhaseCache

/// Shared, time-throttled cache for the current cycle phase.
///
/// Eliminates duplicate CloudKit + HealthKit queries that previously ran
/// independently in DashboardViewModel, SharkWeekMonitor, and CoachContextBuilder.
/// Inject as an `@EnvironmentObject` from MainTabView so all consumers share
/// a single source of truth.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class CyclePhaseCache: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var currentPhase: CyclePhase?
    @Published public private(set) var confidence: Double?
    @Published public private(set) var isSharkWeek: Bool = false
    @Published public private(set) var cycleDay: Int?

    /// Explicit user override that hides the banner after ending a period.
    private var isSharkWeekBannerSuppressed: Bool = SharedSnapshotStore.readSharkWeekBannerSuppressed()

    // MARK: - Dependencies

    private let healthClient: HealthClientProtocol
    private let dataClient: DataClientProtocol

    /// Minimum seconds between full refreshes.
    private let throttleInterval: TimeInterval = 60

    /// Timestamp of last successful refresh.
    private var lastRefreshed: Date?

    // MARK: - Initialization

    public init(
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.healthClient = healthClient
        self.dataClient = dataClient
    }

    // MARK: - Public API

    /// Refreshes cycle phase data if the cache is stale (older than 60 seconds).
    /// Call this from `.task` modifiers — concurrent callers within the throttle
    /// window get the cached result for free.
    public func refreshIfNeeded() async {
        if let last = lastRefreshed,
           Date().timeIntervalSince(last) < throttleInterval {
            return
        }
        await refresh()
    }

    /// Forces a full refresh regardless of throttle. Use after the user
    /// logs a new period or cycle data changes.
    public func refresh() async {
        // Single fetch for manual records — used for both fast path and merge
        let manualRecords: [PeriodLogRecord]
        do {
            manualRecords = try await dataClient.fetchAll(recordType: "PeriodLogRecord")
        } catch {
            manualRecords = []
        }

        // Fast path: active (un-ended) manual period = menstrual phase
        if manualRecords.contains(where: { $0.isActive }) {
            isSharkWeekBannerSuppressed = false
            SharedSnapshotStore.writeSharkWeekBannerSuppressed(false)
            currentPhase = .menstrual
            confidence = 1.0
            isSharkWeek = true
            cycleDay = 1
            lastRefreshed = Date()
            writeSnapshot()
            return
        }

        var periodLogs: [PeriodLog] = []

        // Load HealthKit cycles if available
        if healthClient.isAvailable {
            do {
                let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())
                let cycles = try await healthClient.fetchMenstrualCycles(
                    startDate: sixMonthsAgo,
                    endDate: nil,
                    limit: 100
                )
                if !cycles.isEmpty {
                    periodLogs = CyclePhaseHelper.convertToPeriodLogs(cycles)
                }
            } catch {
                // No HealthKit data — continue
            }
        }

        // Merge manual period logs (using the single fetch from above)
        let manualLogs = manualRecords.map { $0.toPeriodLog() }
        for log in manualLogs {
            let isDuplicate = periodLogs.contains { existing in
                abs(existing.startDate.timeIntervalSince(log.startDate)) < 86400
            }
            if !isDuplicate {
                periodLogs.append(log)
            }
        }

        guard !periodLogs.isEmpty else {
            currentPhase = nil
            confidence = nil
            isSharkWeek = false
            cycleDay = nil
            isSharkWeekBannerSuppressed = false
            SharedSnapshotStore.writeSharkWeekBannerSuppressed(false)
            lastRefreshed = Date()
            writeSnapshot()
            return
        }

        // Load cycle settings
        var settings = CycleSettings()
        if let settingsRecords = try? await dataClient.fetchAll(
            recordType: "CycleSettings"
        ) as [CycleSettingsRecord], let first = settingsRecords.first {
            settings = CycleSettings(averageCycleLengthDays: first.averageCycleLengthDays)
        }

        // Calculate phase
        if let status = calculateCycleStatus(periodLogs: periodLogs, settings: settings) {
            currentPhase = status.currentPhase
            confidence = CyclePhaseHelper.calculateConfidence(
                periodLogCount: periodLogs.count,
                lastPeriodStart: periodLogs.sorted(by: { $0.startDate > $1.startDate }).first?.startDate
            )
            if status.currentPhase != .menstrual {
                isSharkWeekBannerSuppressed = false
                SharedSnapshotStore.writeSharkWeekBannerSuppressed(false)
            }
            isSharkWeek = status.currentPhase == .menstrual && !isSharkWeekBannerSuppressed
            cycleDay = status.cycleDay
        } else {
            currentPhase = nil
            confidence = nil
            isSharkWeek = false
            cycleDay = nil
            isSharkWeekBannerSuppressed = false
            SharedSnapshotStore.writeSharkWeekBannerSuppressed(false)
        }

        lastRefreshed = Date()
        writeSnapshot()
    }

    // MARK: - Optimistic Updates

    /// Optimistically marks the current state as shark week without re-fetching.
    /// Call immediately after the user starts a period, before the async data
    /// store has been re-indexed.
    public func markPeriodStarted() {
        isSharkWeekBannerSuppressed = false
        SharedSnapshotStore.writeSharkWeekBannerSuppressed(false)
        currentPhase = .menstrual
        confidence = 1.0
        isSharkWeek = true
        cycleDay = 1
        writeSnapshot()
        // Don't update lastRefreshed — let the next refreshIfNeeded() do a
        // real fetch to reconcile with the server.
    }

    /// Optimistically clears shark week status without re-fetching.
    /// Call immediately after the user ends (or deletes) the active period.
    public func markPeriodEnded() {
        isSharkWeekBannerSuppressed = true
        SharedSnapshotStore.writeSharkWeekBannerSuppressed(true)
        isSharkWeek = false
        writeSnapshot()
        // Force the next refreshIfNeeded() to do a full fetch.
        lastRefreshed = nil
    }

    // MARK: - Snapshot

    private func writeSnapshot() {
        SharedSnapshotStore.writeCycle(
            CyclePhaseSnapshot(
                phaseRaw: currentPhase?.rawValue,
                cycleDay: cycleDay,
                capturedAt: Date(),
                isSharkWeek: isSharkWeek
            )
        )
        WidgetCenter.shared.reloadTimelines(ofKind: "CyclePhaseWidget")
    }
}
