import SwiftUI
import SwiftData

@main
struct SundeeFundeeApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let config = ModelConfiguration(
                "SundeeFundee",
                cloudKitDatabase: .private("iCloud.com.sundeefundee.app")
            )
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
                configurations: config
            )
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
