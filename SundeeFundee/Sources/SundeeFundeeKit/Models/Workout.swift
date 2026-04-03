import Foundation

public struct Workout: Equatable, Codable, Identifiable, Sendable {
    public let id: String
    public var date: Date
    public var name: String
    public var exercises: [Exercise]
    public var notes: String?
    public var duration: Int  // minutes
    public var completedAt: Date?

    public init(
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

    public var totalVolume: Double {
        exercises.flatMap { exercise in
            exercise.targetSets.map { set in
                Double(set.reps) * (set.completedWeight ?? set.prescribedWeight)
            }
        }.reduce(0, +)
    }

    public var isComplete: Bool {
        completedAt != nil
    }
}
