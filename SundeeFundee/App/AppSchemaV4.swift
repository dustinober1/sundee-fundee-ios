import SwiftData

/// Schema V4 — adds `PainLog` model for daily pain tracking.
///
/// Version history:
///   V1 — initial schema
///   V2 — BenchmarkDefinition + BenchmarkResult, removes Benchmark
///   V3 — adds recoveryPhaseRaw to InjuryProfile
///   V4 — adds PainLog model
enum AppSchemaV4: VersionedSchema {
    static let versionIdentifier = Schema.Version(4, 0, 0)

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
            BenchmarkDefinition.self,
            BenchmarkResult.self,
            PainLog.self,
        ]
    }
}
