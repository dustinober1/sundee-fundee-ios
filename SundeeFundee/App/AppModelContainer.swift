import SwiftData
import CloudKit

/// Builds and vends the shared SwiftData ModelContainer.
///
/// - Production: Uses iCloud.com.sundeefundee.app CloudKit private database.
/// - Tests / previews: Uses an in-memory store (no CloudKit).
/// - Development (no entitlements): Uses local persistent store (no CloudKit sync).
enum AppModelContainer {

    enum ContainerRequest: Equatable {
        case testsInMemory
        case cloudKit
        case localPersistent
        case fallbackInMemory
    }

    static let shared: ModelContainer = makeSharedContainer()

    static func makeSharedContainer(
        isRunningTests: Bool = isRunningTests,
        useCloudKit: Bool = false,
        makeContainer: (ContainerRequest) throws -> ModelContainer = { try Self.makeContainer(for: $0) },
        deleteStoreFiles: () throws -> Void = { try Self.deleteStoreFiles() },
        log: (String) -> Void = { print($0) }
    ) -> ModelContainer {
        // Tests get their own in-memory container immediately.
        if isRunningTests {
            do {
                return try makeContainer(.testsInMemory)
            } catch {
                log("AppModelContainer: test in-memory container failed: \(error).")
            }
        }

        // Tier 1 — Local persistent store (no CloudKit sync).
        // Used during development when CloudKit entitlements are not available.
        // Enable CloudKit in production by setting this flag to true.
        if useCloudKit {
            do {
                return try makeContainer(.cloudKit)
            } catch {
                log("AppModelContainer: CloudKit container failed: \(error). Trying local persistent store.")
            }
        }

        // Tier 2 — Local persistent store (no CloudKit sync).
        do {
            return try makeContainer(.localPersistent)
        } catch {
            log("AppModelContainer: local persistent container failed: \(error).")
            log("Attempting to delete corrupted store files and create fresh one...")

            // Delete the corrupted store files and try again
            do {
                try deleteStoreFiles()
                let container = try makeContainer(.localPersistent)
                log("AppModelContainer: Created fresh local store after clearing corrupted data.")
                return container
            } catch {
                log("AppModelContainer: Failed to create fresh store: \(error). Falling back to in-memory.")
            }
        }

        // Tier 3 — In-memory store (data lost on restart; last resort).
        return try! makeContainer(.fallbackInMemory)
    }

    static func makeContainer(for request: ContainerRequest) throws -> ModelContainer {
        let schema = Schema(allModels)

        switch request {
        case .testsInMemory, .fallbackInMemory:
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, configurations: [config])
        case .cloudKit:
            let cloudConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.sundeefundee.app")
            )
            return try ModelContainer(for: schema, migrationPlan: AppSchemaMigrationPlan.self, configurations: [cloudConfig])
        case .localPersistent:
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, migrationPlan: AppSchemaMigrationPlan.self, configurations: [localConfig])
        }
    }

    /// In-memory container for previews and unit tests.
    ///
    /// For unit tests we return an empty in-memory schema to avoid SwiftData/CloudKit
    /// model validation (unique constraints / non-optional attributes) that require
    /// production model compatibility.
    static func preview() -> ModelContainer {
        let emptySchema = Schema([] as [any PersistentModel.Type])
        let config = ModelConfiguration(schema: emptySchema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try! ModelContainer(for: emptySchema, configurations: [config])
    }

    private static var isRunningTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || NSClassFromString("XCTestCase") != nil
    }

    private static let allModels: [any PersistentModel.Type] = AppSchemaV9.models
    
    /// Deletes all SwiftData store files for the app.
    ///
    /// Call this when the store is corrupted or when you want to reset all local data.
    private static func deleteStoreFiles() throws {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let appSupportDirectory = urls.first else { return }
        
        let storeURL = appSupportDirectory.appendingPathComponent("default.store")
        let walURL = appSupportDirectory.appendingPathComponent("default.store-wal")
        let shmURL = appSupportDirectory.appendingPathComponent("default.store-shm")
        
        for url in [storeURL, walURL, shmURL] {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
                print("AppModelContainer: Deleted \(url.lastPathComponent)")
            }
        }
    }
}
