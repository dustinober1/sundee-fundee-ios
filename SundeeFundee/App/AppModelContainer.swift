import SwiftData
import CloudKit

/// Builds and vends the shared SwiftData ModelContainer.
///
/// - Production: Uses iCloud.com.sundeefundee.app CloudKit private database.
/// - Tests / previews: Uses an in-memory store (no CloudKit).
enum AppModelContainer {

    static let shared: ModelContainer = {
        let schema = Schema(allModels)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.sundeefundee.app")
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    /// In-memory container for previews and unit tests.
    static func preview() -> ModelContainer {
        let schema = Schema(allModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }

    private static let allModels: [any PersistentModel.Type] = [
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
    ]
}
