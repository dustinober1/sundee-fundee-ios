import Foundation

public struct WOD: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let date: String
    public let title: String
    public let description: String
    public let exercises: [ProgramExercise]

    public init(id: String, date: String, title: String, description: String, exercises: [ProgramExercise]) {
        self.id = id; self.date = date; self.title = title; self.description = description; self.exercises = exercises
    }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: WOD, rhs: WOD) -> Bool { lhs.id == rhs.id }
}
