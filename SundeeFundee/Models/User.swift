import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: String
    var name: String
    var experienceLevelRaw: String
    var primaryGoalRaw: String
    var createdAt: Date
    var appleUserID: String

    var experienceLevel: ExperienceLevel {
        get { ExperienceLevel(rawValue: experienceLevelRaw) ?? .beginner }
        set { experienceLevelRaw = newValue.rawValue }
    }

    var primaryGoal: PrimaryGoal {
        get { PrimaryGoal(rawValue: primaryGoalRaw) ?? .strength }
        set { primaryGoalRaw = newValue.rawValue }
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        experienceLevel: ExperienceLevel,
        primaryGoal: PrimaryGoal,
        appleUserID: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.experienceLevelRaw = experienceLevel.rawValue
        self.primaryGoalRaw = primaryGoal.rawValue
        self.appleUserID = appleUserID
        self.createdAt = createdAt
    }
}
