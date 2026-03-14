import Foundation

public struct WOD: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let date: String
    public let title: String
    public let description: String
    public let exercises: [ProgramExercise]
    public let templateType: String
    public let publishDate: String
    public let status: String

    public init(id: String, date: String, title: String, description: String, exercises: [ProgramExercise], templateType: String = "strength", publishDate: String? = nil, status: String = "published") {
        self.id = id; self.date = date; self.title = title; self.description = description; self.exercises = exercises; self.templateType = templateType; self.publishDate = publishDate ?? date; self.status = status
    }

    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    public static func == (lhs: WOD, rhs: WOD) -> Bool { lhs.id == rhs.id }

    enum CodingKeys: String, CodingKey {
        case id, date, title, description, exercises, templateType, publishDate, status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        date = try container.decode(String.self, forKey: .date)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        exercises = try container.decode([ProgramExercise].self, forKey: .exercises)
        templateType = (try? container.decodeIfPresent(String.self, forKey: .templateType)) ?? "strength"
        let decodedDate = date
        publishDate = (try? container.decodeIfPresent(String.self, forKey: .publishDate)) ?? decodedDate
        status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? "published"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(exercises, forKey: .exercises)
        try container.encode(templateType, forKey: .templateType)
        try container.encode(publishDate, forKey: .publishDate)
        try container.encode(status, forKey: .status)
    }
}
