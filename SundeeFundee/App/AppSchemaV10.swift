import SwiftData

/// Schema V10 — adds subscription tier, body weight tracking, AI workout completion state, and shared workout templates.
/// New fields on User: subscriptionTierRaw, bodyWeightKg
/// New fields on CompletedSet: generatedWorkoutID
/// New fields on GeneratedWorkoutRecord: isCompleted, contributedToDatabase
/// New model: SharedWorkoutTemplateRecord
enum AppSchemaV10: VersionedSchema {
    static let versionIdentifier = Schema.Version(10, 0, 0)

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
        ]
    }
}
