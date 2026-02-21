import SwiftData
import XCTest
@testable import SundeeFundee

final class SwiftDataCloudKitCompatibilityTests: XCTestCase {
    func testModelContainer_initializesWithCloudKitConfiguration() {
        let config = ModelConfiguration(
            "SundeeFundeeCloudKitTests",
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .private("iCloud.com.sundeefundee.app")
        )

        XCTAssertNoThrow(
            try ModelContainer(
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
        )
    }
}
