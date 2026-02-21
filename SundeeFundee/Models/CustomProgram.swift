import Foundation
import SwiftData

/// A user-created reusable workout template.
@Model
final class CustomProgram {
    var id: String = UUID().uuidString
    var userId: String = ""
    var name: String = ""
    var notes: String?
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \CustomProgramExercise.program)
    var exercises: [CustomProgramExercise]? = []

    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        notes: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.exercises = []
    }

    /// Returns exercises sorted by their display order.
    var sortedExercises: [CustomProgramExercise] {
        (exercises ?? []).sorted { $0.order < $1.order }
    }
}

/// A single exercise entry inside a CustomProgram.
@Model
final class CustomProgramExercise {
    var id: String = UUID().uuidString
    var exerciseId: String = ""
    var sets: Int = 3
    var reps: Int = 8
    var restMinutes: Double = 2.0
    var notes: String?
    var order: Int = 0

    var program: CustomProgram?

    init(
        id: String = UUID().uuidString,
        exerciseId: String,
        sets: Int = 3,
        reps: Int = 8,
        restMinutes: Double = 2.0,
        notes: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.sets = sets
        self.reps = reps
        self.restMinutes = restMinutes
        self.notes = notes
        self.order = order
    }
}
