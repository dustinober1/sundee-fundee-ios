import SwiftData
import Foundation

/// Schema V6 — adds trigger fields to PainLog (triggerExercise, symptomTypeRaw, intensityContextRaw).
enum AppSchemaV6: VersionedSchema {
    static let versionIdentifier = Schema.Version(6, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            User.self,
            ActiveCycle.self,
            CompletedWorkout.self,
            AppSchemaV6.CompletedSet.self,
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
            BenchmarkDefinition.self,
            BenchmarkResult.self,
            PainLog.self,
        ]
    }

    /// Frozen snapshot of CompletedSet as it existed in V6 — before V7 added
    /// `actualTimeSeconds` and `scoringTypeRaw` for conditioning PR tracking.
    /// SwiftData requires each VersionedSchema to reference model classes whose
    /// properties exactly match that version's on-disk shape.
    @Model
    final class CompletedSet {
        var id: String = ""
        var userID: String = ""
        var workoutID: String = ""
        var exerciseName: String = ""
        var setIndex: Int = 0
        var prescribedReps: String = ""
        var actualReps: Int?
        var prescribedWeightKg: Double?
        var actualWeightKg: Double?
        var isCompleted: Bool = false
        var completedAt: Date = Date()
        init() {}
    }
}
