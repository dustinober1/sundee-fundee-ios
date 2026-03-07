import Foundation
import CloudKit

enum WODDecodingError: Error {
    case missingFields
}

// MARK: - WOD

struct WOD: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let date: String
    let title: String
    let description: String
    let exercises: [ProgramExercise]

    static func == (lhs: WOD, rhs: WOD) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    init(id: String, date: String, title: String, description: String, exercises: [ProgramExercise]) {
        self.id = id
        self.date = date
        self.title = title
        self.description = description
        self.exercises = exercises
    }

    init(record: CKRecord) throws {
        guard let id = record["id"] as? String,
              let date = record["date"] as? String,
              let title = record["title"] as? String,
              let description = record["description"] as? String else {
            throw WODDecodingError.missingFields
        }
        self.id = id
        self.date = date
        self.title = title
        self.description = description

        if let exercisesJSON = record["exercisesJSON"] as? String,
           let data = exercisesJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([ProgramExercise].self, from: data) {
            self.exercises = decoded
        } else {
            self.exercises = []
        }
    }
}
