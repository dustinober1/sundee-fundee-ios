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
    let templateType: String

    static func == (lhs: WOD, rhs: WOD) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    init(id: String, date: String, title: String, description: String, exercises: [ProgramExercise], templateType: String = "strength") {
        self.id = id
        self.date = date
        self.title = title
        self.description = description
        self.exercises = exercises
        self.templateType = templateType
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
        self.templateType = (record["templateType"] as? String) ?? "strength"

        if let exercisesJSON = record["exercisesJSON"] as? String,
           let data = exercisesJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([ProgramExercise].self, from: data) {
            self.exercises = decoded
        } else {
            self.exercises = []
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, date, title, description, exercises, templateType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        date = try container.decode(String.self, forKey: .date)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        exercises = try container.decode([ProgramExercise].self, forKey: .exercises)
        templateType = (try? container.decodeIfPresent(String.self, forKey: .templateType)) ?? "strength"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(exercises, forKey: .exercises)
        try container.encode(templateType, forKey: .templateType)
    }
}
