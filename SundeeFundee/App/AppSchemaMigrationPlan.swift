import SwiftData

/// Migration plan for the Sundee Fundee SwiftData store.
///
/// Add a new `SchemaMigrationStage` here whenever a model property is added,
/// removed, or renamed between app versions. Lightweight migrations (adding
/// optional properties) need only a `willMigrate` / `didMigrate` closure.
/// Custom migrations that transform data require a `custom` stage.
enum AppSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self, AppSchemaV6.self, AppSchemaV7.self, AppSchemaV8.self, AppSchemaV9.self, AppSchemaV10.self, AppSchemaV11.self, AppSchemaV12.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV6, migrateV6toV7, migrateV7toV8, migrateV8toV9, migrateV9toV10, migrateV10toV11, migrateV11toV12]
    }

    /// V1 → V6: Lightweight migration covering all schema additions since V1.
    /// Adds BenchmarkDefinition, BenchmarkResult, PainLog, and new fields on
    /// InjuryProfile (recoveryPhaseRaw, locationRegionsRaw, acknowledgedDisclaimerIDsRaw)
    /// and PainLog (triggerExercise, symptomTypeRaw, intensityContextRaw).
    static let migrateV1toV6 = MigrationStage.lightweight(
        fromVersion: AppSchemaV1.self,
        toVersion: AppSchemaV6.self
    )

    /// V6 → V7: Adds ConditioningPR model and conditioning fields to CompletedSet.
    static let migrateV6toV7 = MigrationStage.lightweight(
        fromVersion: AppSchemaV6.self,
        toVersion: AppSchemaV7.self
    )

    /// V7 → V8: Adds perceivedEffort (spicy rating) to CompletedWorkout.
    static let migrateV7toV8 = MigrationStage.lightweight(
        fromVersion: AppSchemaV7.self,
        toVersion: AppSchemaV8.self
    )

    /// V8 → V9: Adds GeneratedWorkoutRecord for AI workout persistence.
    static let migrateV8toV9 = MigrationStage.lightweight(
        fromVersion: AppSchemaV8.self,
        toVersion: AppSchemaV9.self
    )

    /// V9 → V10: Adds subscription tier, body weight tracking, AI workout completion state, and shared templates.
    /// - User: adds subscriptionTierRaw?, bodyWeightKg?
    /// - CompletedSet: adds generatedWorkoutID?
    /// - GeneratedWorkoutRecord: adds isCompleted, contributedToDatabase
    /// - New model: SharedWorkoutTemplateRecord for local CloudKit cache
    static let migrateV9toV10 = MigrationStage.lightweight(
        fromVersion: AppSchemaV9.self,
        toVersion: AppSchemaV10.self
    )

    /// V10 → V11: Adds BarbellPreset and ExerciseBarMapping models for per-exercise barbell configuration.
    static let migrateV10toV11 = MigrationStage.lightweight(
        fromVersion: AppSchemaV10.self,
        toVersion: AppSchemaV11.self
    )

    /// V11 → V12: Adds travelModeEnabled to User.
    static let migrateV11toV12 = MigrationStage.lightweight(
        fromVersion: AppSchemaV11.self,
        toVersion: AppSchemaV12.self
    )
}
