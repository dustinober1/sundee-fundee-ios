import SwiftData
import Foundation

@Model
final class CompletedWorkout {
    @Attribute(.unique) var id: String
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
        notes: String? = nil
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
    }
}

@Model
final class CompletedSet {
    @Attribute(.unique) var id: String
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
        completedAt: Date = .now
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
    }
}
