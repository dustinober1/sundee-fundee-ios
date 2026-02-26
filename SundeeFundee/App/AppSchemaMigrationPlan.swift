import SwiftData

/// Migration plan for the Sundee Fundee SwiftData store.
///
/// Add a new `SchemaMigrationStage` here whenever a model property is added,
/// removed, or renamed between app versions. Lightweight migrations (adding
/// optional properties) need only a `willMigrate` / `didMigrate` closure.
/// Custom migrations that transform data require a `custom` stage.
enum AppSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // No stages needed yet — V1 is the baseline.
        []
    }
}
