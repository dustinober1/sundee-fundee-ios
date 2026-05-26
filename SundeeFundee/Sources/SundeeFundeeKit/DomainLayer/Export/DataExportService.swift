import Foundation
import os.log

private let exportLogger = Logger(subsystem: "com.sundeefundee.app", category: "DataExport")

// MARK: - DataExportService

/// Fetches all user record types in parallel and produces an `ExportedData` container.
///
/// Each record type is fetched independently. If an individual fetch fails the
/// service logs the error and continues with an empty result for that type rather
/// than aborting the entire export.
public struct DataExportService: Sendable {

    // MARK: - Dependencies

    private let dataClient: DataClientProtocol

    // MARK: - Initialization

    public init(dataClient: DataClientProtocol) {
        self.dataClient = dataClient
    }

    // MARK: - Public API

    /// Fetches all user record types in parallel and wraps them in an `ExportedData`.
    ///
    /// Individual fetch failures are tolerated — the corresponding array will be
    /// empty in the returned data. This ensures a partial export is still useful.
    public func exportAll() async -> ExportedData {
        // Fetch all record types in parallel, tolerating individual failures.
        async let workoutsResult: [Workout] = safeFetch(recordType: "Workout")
        async let ormResult: [OneRepMaxRecord] = safeFetch(recordType: "OneRepMaxRecord")
        async let completedResult: [CompletedWorkoutRecord] = safeFetch(recordType: "CompletedWorkoutRecord")
        async let cyclePhasesResult: [CyclePhaseInfo] = safeFetch(recordType: "CyclePhaseInfo")
        async let recoveryScoresResult: [RecoveryScoreRecord] = safeFetch(recordType: "RecoveryScore")
        async let cycleSettingsResult: [CycleSettingsRecord] = safeFetch(recordType: "CycleSettings")
        async let benchmarksResult: [BenchmarkResult] = safeFetch(recordType: "BenchmarkResult")
        async let injuriesResult: [Injury] = safeFetch(recordType: "Injury")
        async let painLogsResult: [DailyPainLog] = safeFetch(recordType: "DailyPainLog")
        async let celebrationsResult: [CelebrationEventRecord] = safeFetch(recordType: "CelebrationEventRecord")
        async let programsResult: [EnrolledProgramRecord] = safeFetch(recordType: "EnrolledProgramRecord")
        async let weeklyPlansResult: [WeeklyTrainingPlan] = safeFetch(recordType: "WeeklyTrainingPlan")

        // Await all results simultaneously.
        let (
            workouts,
            ormRecords,
            completedWorkouts,
            cyclePhases,
            recoveryScores,
            cycleSettingsRecords,
            benchmarkResults,
            injuries,
            painLogs,
            celebrations,
            enrolledPrograms,
            weeklyPlans
        ) = await (
            workoutsResult,
            ormResult,
            completedResult,
            cyclePhasesResult,
            recoveryScoresResult,
            cycleSettingsResult,
            benchmarksResult,
            injuriesResult,
            painLogsResult,
            celebrationsResult,
            programsResult,
            weeklyPlansResult
        )

        return ExportedData(
            workouts: workouts,
            oneRepMaxRecords: ormRecords,
            completedWorkoutRecords: completedWorkouts,
            cyclePhaseInfo: cyclePhases,
            recoveryScoreRecords: recoveryScores,
            benchmarkResults: benchmarkResults,
            injuries: injuries,
            painLogs: painLogs,
            celebrations: celebrations,
            enrolledPrograms: enrolledPrograms,
            weeklyTrainingPlans: weeklyPlans,
            cycleSettings: cycleSettingsRecords.first
        )
    }

    /// Encodes `ExportedData` to JSON with ISO 8601 dates and sorted keys.
    ///
    /// - Parameter data: The export data to encode.
    /// - Returns: JSON `Data`.
    /// - Throws: Encoding errors.
    public func encode(_ data: ExportedData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try encoder.encode(data)
    }

    // MARK: - Private Helpers

    /// Fetches all records of a given type, returning an empty array on failure.
    private func safeFetch<T: Decodable & Sendable>(recordType: String) async -> [T] {
        do {
            return try await dataClient.fetchAll(recordType: recordType)
        } catch {
            // Log but don't propagate — a partial export is better than none.
            exportLogger.error("Failed to fetch \(recordType): \(error.localizedDescription)")
            return []
        }
    }
}
