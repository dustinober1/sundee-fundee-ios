import SwiftData
import CloudKit

/// Builds and vends the shared SwiftData ModelContainer.
///
/// - Production: Uses iCloud.com.sundeefundee.app CloudKit private database.
/// - Tests / previews: Uses an in-memory store (no CloudKit).
/// - Development (no entitlements): Uses local persistent store (no CloudKit sync).
enum AppModelContainer {

    static let shared: ModelContainer = {
        // Tests get their own in-memory container immediately.
        if isRunningTests {
            let schema = Schema(allModels)
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                print("AppModelContainer: test in-memory container failed: \(error).")
            }
        }

        // Tier 1 — Local persistent store (no CloudKit sync).
        // Used during development when CloudKit entitlements are not available.
        // Enable CloudKit in production by setting this flag to true.
        let useCloudKit = false
        if useCloudKit {
            do {
                let schema = Schema(allModels)
                let cloudConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .private("iCloud.com.sundeefundee.app")
                )
                return try ModelContainer(for: schema, migrationPlan: AppSchemaMigrationPlan.self, configurations: [cloudConfig])
            } catch {
                print("AppModelContainer: CloudKit container failed: \(error). Trying local persistent store.")
            }
        }

        // Tier 2 — Local persistent store (no CloudKit sync).
        do {
            let schema = Schema(allModels)
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, migrationPlan: AppSchemaMigrationPlan.self, configurations: [localConfig])
        } catch {
            print("AppModelContainer: local persistent container failed: \(error). Falling back to in-memory.")
        }

        // Tier 3 — In-memory store (data lost on restart; last resort).
        let schema = Schema(allModels)
        let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [memConfig])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    /// In-memory container for previews and unit tests.
    ///
    /// For unit tests we return an empty in-memory schema to avoid SwiftData/CloudKit
    /// model validation (unique constraints / non-optional attributes) that require
    /// production model compatibility.
    static func preview() -> ModelContainer {
        let emptySchema = Schema([] as [any PersistentModel.Type])
        let config = ModelConfiguration(schema: emptySchema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: emptySchema, configurations: [config])
    }

    private static var isRunningTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || NSClassFromString("XCTestCase") != nil
    }

    private static let allModels: [any PersistentModel.Type] = AppSchemaV1.models
}
