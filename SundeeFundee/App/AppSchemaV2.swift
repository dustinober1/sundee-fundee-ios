import SwiftData

/// Schema V2 — replaces the freeform `Benchmark` model with the catalog-driven
/// `BenchmarkDefinition` and `BenchmarkResult` models.
///
/// Version history:
///   V1 — initial schema (Benchmark model, freeform benchmarks)
///   V2 — adds BenchmarkDefinition + BenchmarkResult, removes Benchmark
enum AppSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

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
