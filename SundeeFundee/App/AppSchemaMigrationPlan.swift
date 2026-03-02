import SwiftData

/// Migration plan for the Sundee Fundee SwiftData store.
///
/// Add a new `SchemaMigrationStage` here whenever a model property is added,
/// removed, or renamed between app versions. Lightweight migrations (adding
/// optional properties) need only a `willMigrate` / `didMigrate` closure.
/// Custom migrations that transform data require a `custom` stage.
enum AppSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self, AppSchemaV6.self, AppSchemaV7.self, AppSchemaV8.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV6, migrateV6toV7, migrateV7toV8]
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
}
