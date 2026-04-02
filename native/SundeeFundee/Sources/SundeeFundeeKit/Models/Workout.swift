import Foundation

struct Workout: Equatable, Codable, Identifiable {
    let id: String
    var date: Date
    var name: String
    var exercises: [Exercise]
    var notes: String?
    var duration: Int  // minutes
    var completedAt: Date?

    init(
        id: String = UUID().uuidString,
        date: Date,
        name: String,
        exercises: [Exercise],
        notes: String? = nil,
        duration: Int = 0,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.exercises = exercises
        self.notes = notes
        self.duration = duration
        self.completedAt = completedAt
    }

    var totalVolume: Double {
        exercises.flatMap { exercise in
            exercise.targetSets.map { set in
                Double(set.reps) * (set.completedWeight ?? set.prescribedWeight)
            }
        }.reduce(0, +)
    }

    var isComplete: Bool {
        completedAt != nil
    }
}
