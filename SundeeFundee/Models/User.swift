import Foundation
import SwiftData

@Model
final class User {
    var id: String = UUID().uuidString
    var name: String = ""
    var experienceLevelRaw: String = ExperienceLevel.beginner.rawValue
    var primaryGoalRaw: String = PrimaryGoal.strength.rawValue
    var genderRaw: String = Gender.preferNotToSay.rawValue
    var createdAt: Date = Date.now
    var appleUserID: String = ""

    var experienceLevel: ExperienceLevel {
        get { ExperienceLevel(rawValue: experienceLevelRaw) ?? .beginner }
        set { experienceLevelRaw = newValue.rawValue }
    }

    var primaryGoal: PrimaryGoal {
        get { PrimaryGoal(rawValue: primaryGoalRaw) ?? .strength }
        set { primaryGoalRaw = newValue.rawValue }
    }

    var gender: Gender {
        get { Gender(rawValue: genderRaw) ?? .preferNotToSay }
        set { genderRaw = newValue.rawValue }
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        experienceLevel: ExperienceLevel,
        primaryGoal: PrimaryGoal,
        gender: Gender = .preferNotToSay,
        appleUserID: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.experienceLevelRaw = experienceLevel.rawValue
        self.primaryGoalRaw = primaryGoal.rawValue
        self.genderRaw = gender.rawValue
        self.appleUserID = appleUserID
        self.createdAt = createdAt
    }
}
