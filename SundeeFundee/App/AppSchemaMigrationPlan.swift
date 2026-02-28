import SwiftData

/// Migration plan for the Sundee Fundee SwiftData store.
///
/// Add a new `SchemaMigrationStage` here whenever a model property is added,
/// removed, or renamed between app versions. Lightweight migrations (adding
/// optional properties) need only a `willMigrate` / `didMigrate` closure.
/// Custom migrations that transform data require a `custom` stage.
enum AppSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self, AppSchemaV6.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV6]
    }

    /// V1 → V6: Lightweight migration covering all schema additions since V1.
    /// Adds BenchmarkDefinition, BenchmarkResult, PainLog, and new fields on
    /// InjuryProfile (recoveryPhaseRaw, locationRegionsRaw, acknowledgedDisclaimerIDsRaw)
    /// and PainLog (triggerExercise, symptomTypeRaw, intensityContextRaw).
    static let migrateV1toV6 = MigrationStage.lightweight(
        fromVersion: AppSchemaV1.self,
        toVersion: AppSchemaV6.self
    )
}
