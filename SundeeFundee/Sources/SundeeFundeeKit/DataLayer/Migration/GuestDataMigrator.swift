import Foundation
import os.log

private let migrationLogger = Logger(subsystem: "com.sundeefundee.app", category: "GuestMigration")

// MARK: - GuestMigrationResult

/// Summary of a guest-to-CloudKit data migration.
///
/// Each field records the number of records of that type that were
/// copied from the source (local) client to the destination (CloudKit)
/// client. Counts reflect what was fetched from the source; if a
/// destination save fails mid-migration, the migrator throws and does
/// NOT clear the source.
public struct GuestMigrationResult: Sendable, Equatable {
    public let workoutsMigrated: Int
    public let challengesMigrated: Int
    public let injuriesMigrated: Int
    public let oneRepMaxesMigrated: Int
    public let benchmarkResultsMigrated: Int
    public let enrolledProgramsMigrated: Int
    public let settingsMigrated: Int
    public let celebrationsMigrated: Int

    public init(
        workoutsMigrated: Int = 0,
        challengesMigrated: Int = 0,
        injuriesMigrated: Int = 0,
        oneRepMaxesMigrated: Int = 0,
        benchmarkResultsMigrated: Int = 0,
        enrolledProgramsMigrated: Int = 0,
        settingsMigrated: Int = 0,
        celebrationsMigrated: Int = 0
    ) {
        self.workoutsMigrated = workoutsMigrated
        self.challengesMigrated = challengesMigrated
        self.injuriesMigrated = injuriesMigrated
        self.oneRepMaxesMigrated = oneRepMaxesMigrated
        self.benchmarkResultsMigrated = benchmarkResultsMigrated
        self.enrolledProgramsMigrated = enrolledProgramsMigrated
        self.settingsMigrated = settingsMigrated
        self.celebrationsMigrated = celebrationsMigrated
    }

    public var totalCount: Int {
        workoutsMigrated + challengesMigrated + injuriesMigrated
            + oneRepMaxesMigrated + benchmarkResultsMigrated
            + enrolledProgramsMigrated + settingsMigrated + celebrationsMigrated
    }
}

// MARK: - GuestDataMigrator

/// Copies a guest user's local data to a destination (CloudKit) client on sign-in.
///
/// Semantics:
/// 1. Every supported record type is fetched from `source`.
/// 2. If any fetch throws, the migrator throws and the source is untouched.
/// 3. Each record type is saved to `destination`.
/// 4. If any save throws, the migrator throws and the source is untouched.
/// 5. Only when every save succeeds is the source cleared (`deleteAllData`).
///
/// The migrator does not mutate state beyond calls to `source`/`destination`,
/// is `Sendable`, and can be used across actor boundaries.
public struct GuestDataMigrator: Sendable {
    private let source: any DataClientProtocol
    private let destination: any DataClientProtocol

    public init(source: any DataClientProtocol, destination: any DataClientProtocol) {
        self.source = source
        self.destination = destination
    }

    /// Performs the migration. See type docs for semantics.
    ///
    /// - Returns: Counts of records migrated per type.
    /// - Throws: Whatever the source or destination throws. On throw the
    ///           source is guaranteed to be untouched.
    public func migrate() async throws -> GuestMigrationResult {
        // Phase 1 — fetch everything. If any fetch throws, we throw and
        // the source remains intact.
        let workouts: [Workout] = try await source.fetchAll(recordType: "Workout")
        let challenges: [Challenge] = try await source.fetchAll(recordType: "Challenge")
        let injuries: [Injury] = try await source.fetchAll(recordType: "Injury")
        let oneRepMaxes: [OneRepMaxRecord] = try await source.fetchAll(recordType: "OneRepMaxRecord")
        let benchmarkResults: [BenchmarkResult] = try await source.fetchAll(recordType: "BenchmarkResult")
        let enrolledPrograms: [EnrolledProgramRecord] = try await source.fetchAll(recordType: "EnrolledProgram")
        let userSettings: [UserSettingsRecord] = try await source.fetchAll(recordType: "UserSettings")
        let celebrations: [CelebrationEventRecord] = try await source.fetchAll(recordType: "CelebrationEventRecord")

        // Phase 2 — save to destination. If any save throws, we throw
        // without clearing source so the user can retry later.
        try await saveIfNonEmpty(workouts, recordType: "Workout")
        try await saveIfNonEmpty(challenges, recordType: "Challenge")
        try await saveIfNonEmpty(injuries, recordType: "Injury")
        try await saveIfNonEmpty(oneRepMaxes, recordType: "OneRepMaxRecord")
        try await saveIfNonEmpty(benchmarkResults, recordType: "BenchmarkResult")
        try await saveIfNonEmpty(enrolledPrograms, recordType: "EnrolledProgram")
        try await saveIfNonEmpty(userSettings, recordType: "UserSettings")
        try await saveIfNonEmpty(celebrations, recordType: "CelebrationEventRecord")

        // Phase 3 — clear source. Only reached if every save above succeeded.
        try await source.deleteAllData()

        let result = GuestMigrationResult(
            workoutsMigrated: workouts.count,
            challengesMigrated: challenges.count,
            injuriesMigrated: injuries.count,
            oneRepMaxesMigrated: oneRepMaxes.count,
            benchmarkResultsMigrated: benchmarkResults.count,
            enrolledProgramsMigrated: enrolledPrograms.count,
            settingsMigrated: userSettings.count,
            celebrationsMigrated: celebrations.count
        )

        migrationLogger.info("✅ Guest migration copied \(result.totalCount) records")
        return result
    }

    // MARK: - Private

    private func saveIfNonEmpty<T>(_ records: [T], recordType: String) async throws
        where T: Encodable & Sendable {
        guard !records.isEmpty else { return }
        try await destination.save(records, recordType: recordType)
    }
}
