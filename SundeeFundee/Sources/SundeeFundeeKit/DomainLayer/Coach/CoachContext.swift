import Foundation

// MARK: - CoachContext

/// Compact context assembled from multiple data sources for the coach.
///
/// Instead of passing raw full history, this builds rolling summaries
/// that fit within on-device model context windows. Each field is
/// optional because not all data may be available for every user.
public struct CoachContext: Sendable {

    // MARK: - User Profile

    /// Current cycle phase (nil if cycle tracking is off).
    public let cyclePhase: CyclePhase?

    /// Cycle phase confidence (0.0–1.0).
    public let cycleConfidence: Double?

    /// User's experience level.
    public let experienceLevel: String?

    /// User's primary training goal.
    public let primaryGoal: String?

    /// Current subscription tier (determines available features).
    public let tier: SubscriptionTier

    // MARK: - Training State

    /// User's current 1RM records (most recent per exercise).
    public let maxes: [ExerciseMax]

    /// Active injuries with recovery phases.
    public let injuries: [Injury]

    /// Workouts completed this week.
    public let workoutsThisWeek: Int

    /// Weekly summaries (last 4 weeks).
    public let weeklySummaries: [WeeklyLoadAnalyzer.WeeklySummary]

    /// Detected load trends.
    public let trends: [WeeklyLoadAnalyzer.LoadTrend]

    /// Detected strength plateau alerts.
    public let plateaus: [PlateauDetector.PlateauAlert]

    /// Detected volume plateau alerts.
    public let volumePlateaus: [PlateauDetector.PlateauAlert]

    /// Early warnings for slowing progress.
    public let progressWarnings: [PlateauDetector.RateOfProgressAlert]

    // MARK: - Equipment

    /// Available equipment.
    public let equipment: EquipmentAccess

    // MARK: - Initialization

    public init(
        cyclePhase: CyclePhase? = nil,
        cycleConfidence: Double? = nil,
        experienceLevel: String? = nil,
        primaryGoal: String? = nil,
        tier: SubscriptionTier = .free,
        maxes: [ExerciseMax] = [],
        injuries: [Injury] = [],
        workoutsThisWeek: Int = 0,
        weeklySummaries: [WeeklyLoadAnalyzer.WeeklySummary] = [],
        trends: [WeeklyLoadAnalyzer.LoadTrend] = [],
        plateaus: [PlateauDetector.PlateauAlert] = [],
        volumePlateaus: [PlateauDetector.PlateauAlert] = [],
        progressWarnings: [PlateauDetector.RateOfProgressAlert] = [],
        equipment: EquipmentAccess = .fullGym
    ) {
        self.cyclePhase = cyclePhase
        self.cycleConfidence = cycleConfidence
        self.experienceLevel = experienceLevel
        self.primaryGoal = primaryGoal
        self.tier = tier
        self.maxes = maxes
        self.injuries = injuries
        self.workoutsThisWeek = workoutsThisWeek
        self.weeklySummaries = weeklySummaries
        self.trends = trends
        self.plateaus = plateaus
        self.volumePlateaus = volumePlateaus
        self.progressWarnings = progressWarnings
        self.equipment = equipment
    }
}

// MARK: - CoachContextBuilder

/// Assembles a CoachContext from the data layer.
///
/// Call `build()` to fetch data from HealthKit and CloudKit/Local storage,
/// then assemble it into a compact context. Tier is always premium.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public actor CoachContextBuilder {
    private let healthClient: HealthClientProtocol
    private let dataClient: DataClientProtocol

    public init(
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.healthClient = healthClient
        self.dataClient = dataClient
    }

    /// Builds a complete context by fetching from all data sources.
    public func build(equipment: EquipmentAccess = .fullGym) async -> CoachContext {
        async let cycleData = loadCycleData()
        async let maxes = loadMaxes()
        async let injuries = loadInjuries()
        async let workoutData = loadWorkoutData()
        async let settings = loadSettings()

        let (cycle, maxResult, injuryResult, workouts, userSettings) = await (
            cycleData, maxes, injuries, workoutData, settings
        )

        // Run analysis on the workout data
        let summaries = WeeklyLoadAnalyzer.weeklySummaries(from: workouts)
        let trends = WeeklyLoadAnalyzer.detectTrends(from: summaries)
        let plateaus = PlateauDetector.detect(from: maxResult.records, catalog: weightliftingExercises)
        let progressWarnings = PlateauDetector.detectSlowingProgress(from: maxResult.records)

        // Load full workouts for volume plateau detection
        let fullWorkouts = await loadFullWorkouts()
        let volumePlateaus = PlateauDetector.detectVolumePlateaus(from: fullWorkouts)

        return CoachContext(
            cyclePhase: cycle.phase,
            cycleConfidence: cycle.confidence,
            experienceLevel: userSettings.experienceLevel,
            primaryGoal: userSettings.primaryGoal,
            tier: .premium,
            maxes: maxResult.maxes,
            injuries: injuryResult,
            workoutsThisWeek: countThisWeek(workouts),
            weeklySummaries: summaries,
            trends: trends,
            plateaus: plateaus,
            volumePlateaus: volumePlateaus,
            progressWarnings: progressWarnings,
            equipment: equipment
        )
    }

    // MARK: - Private Loaders

    private func loadCycleData() async -> (phase: CyclePhase?, confidence: Double?) {
        // Single fetch for manual records — used for both fast path and merge
        let manualRecords: [PeriodLogRecord]
        do {
            manualRecords = try await dataClient.fetchAll(recordType: "PeriodLogRecord")
        } catch {
            manualRecords = []
        }

        // Fast path: active manual period = menstrual phase with full confidence
        if manualRecords.contains(where: { $0.isActive }) {
            return (.menstrual, 1.0)
        }

        var periodLogs: [PeriodLog] = []

        // Load HealthKit cycles if available
        if healthClient.isAvailable {
            do {
                let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())
                let cycles = try await healthClient.fetchMenstrualCycles(
                    startDate: sixMonthsAgo, endDate: nil, limit: 100
                )
                if !cycles.isEmpty {
                    periodLogs = CyclePhaseHelper.convertToPeriodLogs(cycles)
                }
            } catch { /* no HealthKit */ }
        }

        // Merge manual period logs (reusing the single fetch from above)
        for log in manualRecords.map({ $0.toPeriodLog() }) {
            let isDuplicate = periodLogs.contains {
                abs($0.startDate.timeIntervalSince(log.startDate)) < 86400
            }
            if !isDuplicate { periodLogs.append(log) }
        }

        guard !periodLogs.isEmpty else { return (nil, nil) }

        var settings = CycleSettings()
        if let records = try? await dataClient.fetchAll(
            recordType: "CycleSettings"
        ) as [CycleSettingsRecord], let first = records.first {
            settings = CycleSettings(averageCycleLengthDays: first.averageCycleLengthDays)
        }

        guard let status = calculateCycleStatus(periodLogs: periodLogs, settings: settings) else {
            return (nil, nil)
        }

        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: periodLogs.count,
            lastPeriodStart: periodLogs.sorted(by: { $0.startDate > $1.startDate }).first?.startDate
        )
        return (status.currentPhase, confidence)
    }

    private func loadMaxes() async -> (maxes: [ExerciseMax], records: [OneRepMaxRecord]) {
        do {
            let records = try await dataClient.fetchAll(
                recordType: "OneRepMaxRecord"
            ) as [OneRepMaxRecord]
            let maxes = records.map { ExerciseMax(name: $0.exerciseName, weightKg: $0.weight) }
            return (maxes, records)
        } catch {
            return ([], [])
        }
    }

    private func loadInjuries() async -> [Injury] {
        do {
            return try await dataClient.fetchAll(recordType: "Injury") as [Injury]
        } catch {
            return []
        }
    }

    private func loadWorkoutData() async -> [CompletedWorkoutRecord] {
        do {
            let completed = try await dataClient.fetchAll(
                recordType: "CompletedWorkoutRecord"
            ) as [CompletedWorkoutRecord]
            if !completed.isEmpty {
                return completed
            }
        } catch {
            // Fall back to Workout because the app persists completed sessions there.
        }

        let workouts = await loadFullWorkouts()
        return workouts.compactMap(\.completedWorkoutRecord)
    }

    private func loadFullWorkouts() async -> [Workout] {
        do {
            return try await dataClient.fetchAll(recordType: "Workout") as [Workout]
        } catch {
            return []
        }
    }

    private func loadSettings() async -> (experienceLevel: String?, primaryGoal: String?) {
        do {
            let records = try await dataClient.fetchAll(
                recordType: "UserSettings"
            ) as [UserSettingsRecord]
            if let s = records.first {
                return (s.experienceLevel, s.primaryGoal)
            }
        } catch {
            // Settings unavailable — degrade to nil defaults
        }
        return (nil, nil)
    }

    private func countThisWeek(_ workouts: [CompletedWorkoutRecord]) -> Int {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else {
            return 0
        }
        return workouts.filter { $0.date >= weekStart }.count
    }
}
