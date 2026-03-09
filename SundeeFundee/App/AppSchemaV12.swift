import SwiftData

/// Schema V12 — adds travelModeEnabled to User for travel mode feature.
enum AppSchemaV12: VersionedSchema {
    static let versionIdentifier = Schema.Version(12, 0, 0)

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
