import SwiftData

/// Migration plan for the Sundee Fundee SwiftData store.
///
/// Add a new `SchemaMigrationStage` here whenever a model property is added,
/// removed, or renamed between app versions. Lightweight migrations (adding
/// optional properties) need only a `willMigrate` / `didMigrate` closure.
/// Custom migrations that transform data require a `custom` stage.
enum AppSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self, AppSchemaV2.self, AppSchemaV3.self, AppSchemaV4.self, AppSchemaV5.self, AppSchemaV6.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4, migrateV4toV5, migrateV5toV6]
    }

    /// V1 → V2: Remove Benchmark, add BenchmarkDefinition and BenchmarkResult.
    /// No data is preserved — existing freeform benchmark history is discarded.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: AppSchemaV1.self,
        toVersion: AppSchemaV2.self
    )

    /// V2 → V3: Add `recoveryPhaseRaw` to InjuryProfile.
    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: AppSchemaV2.self,
        toVersion: AppSchemaV3.self
    )

    /// V3 → V4: Add `PainLog` model.
    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: AppSchemaV3.self,
        toVersion: AppSchemaV4.self
    )

    /// V4 → V5: Add `InjuryProfile.locationRegionsRaw`.
    static let migrateV4toV5 = MigrationStage.lightweight(
        fromVersion: AppSchemaV4.self,
        toVersion: AppSchemaV5.self
    )

    /// V5 → V6: Add trigger fields to PainLog.
    static let migrateV5toV6 = MigrationStage.lightweight(
        fromVersion: AppSchemaV5.self,
        toVersion: AppSchemaV6.self
    )
}
