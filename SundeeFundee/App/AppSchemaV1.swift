import SwiftData
import Foundation

// MARK: - V1 Legacy Model Stub

/// Stub retained for schema migration purposes only.
/// The live `Benchmark` model was replaced by `BenchmarkResult` in V2.
/// Do NOT use this type anywhere other than `AppSchemaV1.models`.
@Model
final class Benchmark {
    var id: String = ""
    var userID: String = ""
    var name: String = ""
    var score: Double = 0
    var notes: String = ""
    var performedAt: Date = Date()
    init() {}
}

/// The initial versioned schema for the Sundee Fundee persistent store.
///
/// Version history:
///   V1 — initial schema (15 models, no @Attribute(.unique) for CloudKit compatibility)
enum AppSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            User.self,
            ActiveCycle.self,
            CompletedWorkout.self,
            CompletedSet.self,
            OneRepMax.self,
            PersonalRecord.self,
            LiftMax.self,
            PeriodLog.self,
            SymptomLog.self,
            CycleSettings.self,
            CycleAdaptationPreferences.self,
            InjuryProfile.self,
            EnrolledProgram.self,
            EnrollmentEvent.self,
            Benchmark.self,
        ]
    }
}
