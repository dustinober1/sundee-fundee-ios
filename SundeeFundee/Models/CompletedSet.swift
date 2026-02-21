import Foundation
import SwiftData

@Model
final class CompletedSet {
    @Attribute(.unique) var id: String
    var workoutId: String
    var exerciseId: String
    var setNumber: Int
    var prescribedWeight: Double?
    var actualWeight: Double?
    var prescribedReps: Int?
    var actualReps: Int?
    var rpe: Double?
    var restSeconds: Int?
    var overrideReason: String?

    var workout: CompletedWorkout?

    init(
        id: String = UUID().uuidString,
        workoutId: String,
        exerciseId: String,
        setNumber: Int,
        prescribedWeight: Double? = nil,
        actualWeight: Double? = nil,
        prescribedReps: Int? = nil,
        actualReps: Int? = nil,
        rpe: Double? = nil,
        restSeconds: Int? = nil,
        overrideReason: String? = nil
    ) {
        self.id = id
        self.workoutId = workoutId
        self.exerciseId = exerciseId
        self.setNumber = setNumber
        self.prescribedWeight = prescribedWeight
        self.actualWeight = actualWeight
        self.prescribedReps = prescribedReps
        self.actualReps = actualReps
        self.rpe = rpe
        self.restSeconds = restSeconds
        self.overrideReason = overrideReason
    }
}
