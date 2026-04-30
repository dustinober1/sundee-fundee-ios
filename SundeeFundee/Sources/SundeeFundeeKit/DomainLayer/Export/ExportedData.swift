import Foundation

// MARK: - ExportedData

/// Top-level container for all user data exported from the app.
///
/// Holds every record type the user has created, plus metadata about when
/// the export was produced and which app version generated it. All array
/// fields default to empty and `cycleSettings` defaults to nil so that
/// an empty-state export is valid.
public struct ExportedData: Codable, Sendable {

    // MARK: - Metadata

    /// Timestamp of when this export was generated.
    public let exportDate: Date

    /// App version that produced the export (e.g. "1.0.0").
    public let appVersion: String

    // MARK: - Record Collections

    /// Saved workouts.
    public var workouts: [Workout]

    /// One-rep-max tracking records.
    public var oneRepMaxRecords: [OneRepMaxRecord]

    /// Completed workout history entries.
    public var completedWorkoutRecords: [CompletedWorkoutRecord]

    /// Menstrual cycle phase information.
    public var cyclePhaseInfo: [CyclePhaseInfo]

    /// Benchmark attempt results.
    public var benchmarkResults: [BenchmarkResult]

    /// Logged injuries and chronic conditions.
    public var injuries: [Injury]

    /// Daily pain log entries.
    public var painLogs: [DailyPainLog]

    /// Milestone celebration events.
    public var celebrations: [CelebrationEventRecord]

    /// Programs the user is enrolled in.
    public var enrolledPrograms: [EnrolledProgramRecord]

    /// User's cycle tracking settings (at most one record).
    public var cycleSettings: CycleSettingsRecord?

    // MARK: - Initialization

    public init(
        exportDate: Date = Date(),
        appVersion: String = "1.0.0",
        workouts: [Workout] = [],
        oneRepMaxRecords: [OneRepMaxRecord] = [],
        completedWorkoutRecords: [CompletedWorkoutRecord] = [],
        cyclePhaseInfo: [CyclePhaseInfo] = [],
        benchmarkResults: [BenchmarkResult] = [],
        injuries: [Injury] = [],
        painLogs: [DailyPainLog] = [],
        celebrations: [CelebrationEventRecord] = [],
        enrolledPrograms: [EnrolledProgramRecord] = [],
        cycleSettings: CycleSettingsRecord? = nil
    ) {
        self.exportDate = exportDate
        self.appVersion = appVersion
        self.workouts = workouts
        self.oneRepMaxRecords = oneRepMaxRecords
        self.completedWorkoutRecords = completedWorkoutRecords
        self.cyclePhaseInfo = cyclePhaseInfo
        self.benchmarkResults = benchmarkResults
        self.injuries = injuries
        self.painLogs = painLogs
        self.celebrations = celebrations
        self.enrolledPrograms = enrolledPrograms
        self.cycleSettings = cycleSettings
    }

    // MARK: - Factory

    /// Creates an `ExportedData` instance with the current timestamp and app version.
    public static func current() -> ExportedData {
        ExportedData(
            exportDate: Date(),
            appVersion: "1.0.0"
        )
    }

    // MARK: - Category Counts

    /// A dictionary mapping category names to record counts for summary display.
    public var categoryCounts: [String: Int] {
        [
            "Workouts": workouts.count,
            "One Rep Maxes": oneRepMaxRecords.count,
            "Completed Workouts": completedWorkoutRecords.count,
            "Cycle Phases": cyclePhaseInfo.count,
            "Cycle Settings": cycleSettings == nil ? 0 : 1,
            "Benchmarks": benchmarkResults.count,
            "Injuries": injuries.count,
            "Pain Logs": painLogs.count,
            "Celebrations": celebrations.count,
            "Programs": enrolledPrograms.count,
        ]
    }
}
