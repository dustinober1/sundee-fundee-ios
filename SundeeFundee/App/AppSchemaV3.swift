import SwiftData

/// Schema V3 — adds `InjuryProfile.recoveryPhaseRaw` for 5-phase recovery arc.
///
/// Version history:
///   V1 — initial schema
///   V2 — BenchmarkDefinition + BenchmarkResult, removes Benchmark
///   V3 — adds recoveryPhaseRaw to InjuryProfile
enum AppSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

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
        ]
    }
}
