import SwiftData
import Foundation

@Model
final class CompletedWorkout {
    var id: String
    var userID: String
    var activeCycleID: String
    var programID: String
    var enrollmentID: String?
    var week: Int
    var day: Int
    var sessionID: String
    var completedAt: Date
    var durationSeconds: Int
    var notes: String?
    var perceivedEffort: Int?

    init(
        id: String,
        userID: String,
        activeCycleID: String,
        programID: String,
        enrollmentID: String? = nil,
        week: Int,
        day: Int,
        sessionID: String,
        completedAt: Date = .now,
        durationSeconds: Int = 0,
        notes: String? = nil,
        perceivedEffort: Int? = nil
    ) {
        self.id = id
        self.userID = userID
        self.activeCycleID = activeCycleID
        self.programID = programID
        self.enrollmentID = enrollmentID
        self.week = week
        self.day = day
        self.sessionID = sessionID
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
        self.notes = notes
        self.perceivedEffort = perceivedEffort
    }
}

@Model
final class CompletedSet {
    var id: String
    var userID: String
    var workoutID: String
    var exerciseName: String
    var setIndex: Int
    var prescribedReps: String   // e.g. "5", "8-10", "AMRAP"
    var actualReps: Int?
    var prescribedWeightKg: Double?
    var actualWeightKg: Double?
    var isCompleted: Bool
    var completedAt: Date
    var actualTimeSeconds: Double?
    var scoringTypeRaw: String?
    var generatedWorkoutID: String?

    init(
        id: String,
        userID: String,
        workoutID: String,
        exerciseName: String,
        setIndex: Int,
        prescribedReps: String,
        actualReps: Int? = nil,
        prescribedWeightKg: Double? = nil,
        actualWeightKg: Double? = nil,
        isCompleted: Bool = false,
        completedAt: Date = .now,
        actualTimeSeconds: Double? = nil,
        scoringTypeRaw: String? = nil,
        generatedWorkoutID: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.workoutID = workoutID
        self.exerciseName = exerciseName
        self.setIndex = setIndex
        self.prescribedReps = prescribedReps
        self.actualReps = actualReps
        self.prescribedWeightKg = prescribedWeightKg
        self.actualWeightKg = actualWeightKg
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.actualTimeSeconds = actualTimeSeconds
        self.scoringTypeRaw = scoringTypeRaw
        self.generatedWorkoutID = generatedWorkoutID
    }
}
