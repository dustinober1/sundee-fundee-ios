import Foundation
import HealthKit
import os.log
import SwiftUI
import WidgetKit

private let recoveryLogger = Logger(subsystem: "com.sundeefundee.app", category: "RecoveryScore")

// MARK: - RecoveryScoreViewModel

/// ViewModel orchestrating recovery score fetch, compute, persist, and history.
///
/// Coordinates parallel data fetches from HealthKit (HRV, sleep), CloudKit
/// (workouts, pain logs, period logs, cycle settings), and CyclePhaseCache
/// to compute a daily recovery score and publish reactive state for SwiftUI.
///
/// ## Lifecycle
/// - `loadScore(cyclePhase:isGuest:)` called from DashboardView `.task` on foreground
/// - `loadHistory()` called lazily when breakdown/trend view appears
///
/// ## Graceful Degradation (D-08)
/// Each input fetch uses independent do/catch blocks that silently skip on
/// failure. The calculator handles nil inputs by redistributing weights among
/// present inputs. A score is produced as long as at least one input is available.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public final class RecoveryScoreViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var score: RecoveryScore?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var historicalScores: [RecoveryScoreRecord] = []
    @Published public private(set) var phaseBands: [(startDate: Date, endDate: Date, phase: CyclePhase)] = []
    @Published public private(set) var isGuest: Bool = false
    @Published public private(set) var topExplanations: [RecoveryExplanation] = []
    @Published public private(set) var deloadRecommendation: DeloadRecommendation?

    // MARK: - Dependencies

    private let healthClient: HealthClientProtocol
    private let dataClient: DataClientProtocol

    // MARK: - Initialization

    public init(
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.healthClient = healthClient
        self.dataClient = dataClient
    }

    // MARK: - Public Methods

    /// Loads today's recovery score. Called from DashboardView.task (D-11: foreground only).
    ///
    /// - Parameters:
    ///   - cyclePhase: Current cycle phase from CyclePhaseCache (may be nil if not loaded yet).
    ///   - isGuest: Whether the user is in guest mode (D-09: skip CloudKit writes).
    public func loadScore(
        cyclePhase: CyclePhase?,
        isGuest: Bool
    ) async {
        self.isGuest = isGuest
        guard !isGuest else {
            recoveryLogger.info("Guest user -- skipping recovery score")
            self.score = nil
            self.topExplanations = RecoveryExplanationService.topExplanations(from: nil)
            self.deloadRecommendation = nil
            return
        }

        isLoading = true
        errorMessage = nil

        // Fetch all 5 inputs (silent catch per input -- D-08 graceful degradation)
        var hrvMs: Double?
        var sleepHours: Double?
        var weeklySummaries: [WeeklyLoadAnalyzer.WeeklySummary]?
        var painIntensity: Int?

        // HRV: use fetchHeartRateVariability for last 24h, take most recent sample
        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .hour, value: -24, to: endDate) ?? endDate
            let samples = try await healthClient.fetchHeartRateVariability(startDate: startDate, endDate: endDate)
            if let latest = samples.first {
                hrvMs = latest.quantity.doubleValue(for: HKUnit(from: "ms"))
            }
        } catch {
            recoveryLogger.info("HRV fetch skipped: \(error.localizedDescription)")
        }

        // Sleep: fetch last 48h, convert to domain intervals, deduplicate
        do {
            let samples = try await healthClient.fetchRecentSleepAnalysis()
            let values = samples.map { sample in
                (
                    start: sample.startDate,
                    end: sample.endDate,
                    value: sample.value,
                    sourceName: sample.sourceRevision.source.name
                )
            }
            let intervals = SleepDeduplicator.convertSamples(values: values)
            let totalSeconds = SleepDeduplicator.deduplicate(intervals)
            sleepHours = totalSeconds / 3600.0
        } catch {
            recoveryLogger.info("Sleep fetch skipped: \(error.localizedDescription)")
        }

        // Training load: fetch workouts, compute weekly summaries
        do {
            let workouts: [CompletedWorkoutRecord] = try await dataClient.fetchAll(recordType: "Workout")
            weeklySummaries = WeeklyLoadAnalyzer.weeklySummaries(from: workouts, weekCount: 4)
        } catch {
            recoveryLogger.info("Training load fetch skipped: \(error.localizedDescription)")
        }

        // Pain: fetch today's DailyPainLog (most recent). DailyPainLog.date is the field name.
        do {
            let logs: [DailyPainLog] = try await dataClient.fetchAll(recordType: "DailyPainLog")
            let today = Calendar.current.startOfDay(for: Date())
            if let todayLog = logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                painIntensity = todayLog.intensity
            }
        } catch {
            recoveryLogger.info("Pain log fetch skipped: \(error.localizedDescription)")
        }

        // Compute score
        let inputs = RecoveryScoreInputs(
            hrvMilliseconds: hrvMs,
            sleepDurationHours: sleepHours,
            weeklySummaries: weeklySummaries,
            cyclePhase: cyclePhase,
            painIntensity: painIntensity
        )
        self.score = RecoveryScoreCalculator.calculate(inputs: inputs)
        self.topExplanations = RecoveryExplanationService.topExplanations(from: self.score)

        if let score = self.score {
            recoveryLogger.info("Recovery score: \(score.total) (\(score.recommendation.rawValue)) with \(score.presentInputCount)/5 inputs")
            // Persist to CloudKit
            await persistScore(score, cyclePhase: cyclePhase)
            // Snapshot to App Group for widgets
            SharedSnapshotStore.writeRecovery(
                RecoverySnapshot(
                    total: score.total,
                    recommendationRaw: score.recommendation.rawValue,
                    capturedAt: Date(),
                    presentInputCount: score.presentInputCount
                )
            )
            WidgetCenter.shared.reloadTimelines(ofKind: "RecoveryScoreWidget")
        }

        do {
            let history: [RecoveryScoreRecord] = try await dataClient.fetchAll(recordType: "RecoveryScore")
            let painLogs: [DailyPainLog] = try await dataClient.fetchAll(recordType: "DailyPainLog")
            deloadRecommendation = DeloadDetectionService.recommendation(
                recentScores: history,
                recentPainLogs: painLogs
            )
        } catch {
            deloadRecommendation = nil
        }

        isLoading = false
    }

    /// Loads 30-day historical scores and computes phase bands for trend chart.
    /// Called lazily when breakdown view appears.
    public func loadHistory() async {
        guard !isGuest else { return }

        // Step 1: Fetch historical scores
        do {
            let allRecords: [RecoveryScoreRecord] = try await dataClient.fetchAll(recordType: "RecoveryScore")
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let formatter = ISO8601DateFormatter()
            historicalScores = allRecords
                .filter { record in
                    guard let date = formatter.date(from: record.scoreDate) else { return false }
                    return date >= thirtyDaysAgo
                }
                .sorted { $0.scoreDate < $1.scoreDate }
            recoveryLogger.info("Loaded \(self.historicalScores.count) historical scores")
        } catch {
            recoveryLogger.error("Failed to load history: \(error.localizedDescription)")
        }

        // Step 2: Fetch PeriodLog + CycleSettings and compute phase bands (D-07)
        do {
            let periodLogs: [PeriodLog] = try await dataClient.fetchAll(recordType: "PeriodLogRecord")
            let settingsRecords: [CycleSettingsRecord] = try await dataClient.fetchAll(recordType: "CycleSettings")
            if let settingsRecord = settingsRecords.first {
                let settings = CycleSettings(averageCycleLengthDays: settingsRecord.averageCycleLengthDays)
                computePhaseBands(periodLogs: periodLogs, settings: settings)
                recoveryLogger.info("Computed \(self.phaseBands.count) phase bands")
            }
        } catch {
            recoveryLogger.info("Phase bands skipped: \(error.localizedDescription)")
        }
    }

    /// Computes per-day cycle phase bands for the 30-day trend chart window.
    /// Uses CycleCalculations.calculateCycleStatus with each past date as referenceDate.
    /// Per RESEARCH.md Pitfall 6: must pre-compute date ranges, not just use today's phase.
    public func computePhaseBands(
        periodLogs: [PeriodLog],
        settings: CycleSettings
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) else { return }
        var bands: [(startDate: Date, endDate: Date, phase: CyclePhase)] = []
        var currentBandStart: Date = thirtyDaysAgo
        var currentPhase: CyclePhase?

        for dayOffset in 0...30 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: thirtyDaysAgo) else { continue }
            let status = calculateCycleStatus(
                periodLogs: periodLogs, settings: settings, referenceDate: day
            )
            let phase = status?.currentPhase

            if phase != currentPhase {
                // Close previous band
                if let prev = currentPhase {
                    bands.append((startDate: currentBandStart, endDate: day, phase: prev))
                }
                currentBandStart = day
                currentPhase = phase
            }
        }
        // Close final band
        if let last = currentPhase {
            let endDate = calendar.date(byAdding: .day, value: 1, to: today) ?? today
            bands.append((startDate: currentBandStart, endDate: endDate, phase: last))
        }
        self.phaseBands = bands
    }

    // MARK: - Private Methods

    private func persistScore(_ score: RecoveryScore, cyclePhase: CyclePhase?) async {
        let formatter = ISO8601DateFormatter()
        let record = RecoveryScoreRecord(
            scoreDate: formatter.string(from: Calendar.current.startOfDay(for: Date())),
            totalScore: score.total,
            hrvSubScore: score.subScores[.hrv],
            sleepSubScore: score.subScores[.sleep],
            loadSubScore: score.subScores[.trainingLoad],
            cyclePhaseSubScore: score.subScores[.cyclePhase],
            painSubScore: score.subScores[.pain],
            presentInputCount: score.presentInputCount,
            cyclePhaseRaw: cyclePhase?.rawValue,
            recommendationRaw: score.recommendation.rawValue
        )
        do {
            try await dataClient.save(record, recordType: "RecoveryScore")
            recoveryLogger.info("Score persisted for \(record.scoreDate)")
        } catch {
            recoveryLogger.error("Failed to persist score: \(error.localizedDescription)")
        }
    }
}
