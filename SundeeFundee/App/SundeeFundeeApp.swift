import SwiftUI
import SwiftData

@main
struct SundeeFundeeApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let config: ModelConfiguration
            let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing")
            let isRunningTests = isUITesting
                || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
                || NSClassFromString("XCTestCase") != nil
            if isRunningTests {
                config = ModelConfiguration(
                    "SundeeFundeeTests",
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )
            } else {
                config = ModelConfiguration(
                    "SundeeFundee",
                    cloudKitDatabase: .private("iCloud.com.sundeefundee.app")
                )
            }

            if isUITesting {
                KeychainHelper.delete(key: "com.sundeefundee.appleUserID")
            }

            modelContainer = try ModelContainer(
                for: User.self,
                     ActiveCycle.self,
                     CompletedWorkout.self,
                     CompletedSet.self,
                     OneRepMax.self,
                     PersonalRecord.self,
                     PeriodLog.self,
                     SymptomLog.self,
                     BBTLog.self,
                     SymptomDefinition.self,
                     CycleSettings.self,
                     CustomProgram.self,
                     CustomProgramExercise.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Brand.tint)
        }
        .modelContainer(modelContainer)
    }
}
