import SwiftData
import Foundation

// MARK: - Enums (stored as raw strings in SwiftData)

enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner, intermediate, advanced
}

enum PrimaryGoal: String, Codable, CaseIterable {
    case strength, hypertrophy, endurance, weightLoss = "weight_loss"
}

enum Gender: String, Codable, CaseIterable {
    case male, female, preferNotToSay = "prefer_not_to_say"
}

// MARK: - User

@Model
final class User {
    var id: String
    var name: String
    var experienceLevelRaw: String
    var primaryGoalRaw: String
    var genderRaw: String
    var appleUserID: String
    var cycleTrackingEnabled: Bool
    var onboardingComplete: Bool
    var createdAt: Date
    var profileUpdatedAt: Date?

    init(
        id: String,
        name: String,
        experienceLevel: ExperienceLevel,
        primaryGoal: PrimaryGoal,
        gender: Gender,
        appleUserID: String,
        cycleTrackingEnabled: Bool = false,
        onboardingComplete: Bool = false,
        createdAt: Date = .now,
        profileUpdatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.experienceLevelRaw = experienceLevel.rawValue
        self.primaryGoalRaw = primaryGoal.rawValue
        self.genderRaw = gender.rawValue
        self.appleUserID = appleUserID
        self.cycleTrackingEnabled = cycleTrackingEnabled
        self.onboardingComplete = onboardingComplete
        self.createdAt = createdAt
        self.profileUpdatedAt = profileUpdatedAt
    }

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

    var hasRequiredOnboardingAnswers: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
