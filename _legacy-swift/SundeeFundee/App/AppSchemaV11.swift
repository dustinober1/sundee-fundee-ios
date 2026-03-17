import SwiftData

/// Schema V11 — adds BarbellPreset and ExerciseBarMapping for per-exercise barbell configuration.
enum AppSchemaV11: VersionedSchema {
    static let versionIdentifier = Schema.Version(11, 0, 0)

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
            ConditioningPR.self,
            GeneratedWorkoutRecord.self,
            SharedWorkoutTemplateRecord.self,
            BarbellPreset.self,
            ExerciseBarMapping.self,
        ]
    }
}
