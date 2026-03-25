import SwiftData
import Foundation

/// Schema V7 — adds ConditioningPR model and conditioning fields to CompletedSet.
///
/// Uses a frozen `CompletedWorkout` snapshot (without `perceivedEffort`)
/// so that V7 and V8 produce different checksums. V8 references the live
/// `CompletedWorkout` which includes `perceivedEffort`.
enum AppSchemaV7: VersionedSchema {
    static let versionIdentifier = Schema.Version(7, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            User.self,
            ActiveCycle.self,
            AppSchemaV7.CompletedWorkout.self,
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
            BenchmarkDefinition.self,
            BenchmarkResult.self,
            PainLog.self,
            ConditioningPR.self,
        ]
    }

    /// Frozen snapshot of CompletedWorkout as it existed in V7 — before V8
    /// added `perceivedEffort`. Required so SwiftData sees V7 and V8 as
    /// distinct schema versions (different checksums).
    @Model
    final class CompletedWorkout {
        var id: String = ""
        var userID: String = ""
        var activeCycleID: String = ""
        var programID: String = ""
        var enrollmentID: String?
        var week: Int = 0
        var day: Int = 0
        var sessionID: String = ""
        var completedAt: Date = Date()
        var durationSeconds: Int = 0
        var notes: String?
        init() {}
    }
}
