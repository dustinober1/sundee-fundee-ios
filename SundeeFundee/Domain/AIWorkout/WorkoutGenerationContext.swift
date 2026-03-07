import Foundation

// MARK: - Questionnaire Enums

enum WorkoutFocus: String, Codable, Sendable, CaseIterable {
    case upperBody = "upper_body"
    case lowerBody = "lower_body"
    case fullBody = "full_body"
    case push
    case pull
    case core
    case conditioning
    case strength
    case olympicLifts = "olympic_lifts"
    case gymnastics
    case mobility
    case stretching

    var displayName: String {
        switch self {
        case .upperBody: "Upper Body"
        case .lowerBody: "Lower Body"
        case .fullBody: "Full Body"
        case .push: "Push"
        case .pull: "Pull"
        case .core: "Core"
        case .conditioning: "Conditioning"
        case .strength: "Strength"
        case .olympicLifts: "Olympic Lifts"
        case .gymnastics: "Gymnastics"
        case .mobility: "Mobility"
        case .stretching: "Stretching"
        }
    }
}

enum EnergyLevel: String, Codable, Sendable, CaseIterable {
    case low, medium, high

    var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    var icon: String {
        switch self {
        case .low: "battery.25"
        case .medium: "battery.50"
        case .high: "battery.100"
        }
    }
}

enum EquipmentAccess: String, Codable, Sendable, CaseIterable {
    case fullGym = "full_gym"
    case homeDumbbells = "home_dumbbells"
    case bodyweightOnly = "bodyweight_only"
    case outdoor

    var displayName: String {
        switch self {
        case .fullGym: "Full Gym"
        case .homeDumbbells: "Home Dumbbells"
        case .bodyweightOnly: "Bodyweight Only"
        case .outdoor: "Outdoor"
        }
    }

    var icon: String {
        switch self {
        case .fullGym: "building.2"
        case .homeDumbbells: "dumbbell"
        case .bodyweightOnly: "figure.strengthtraining.traditional"
        case .outdoor: "sun.max"
        }
    }
}

// MARK: - Sub-models for context

struct ExerciseMax: Codable, Sendable {
    let name: String
    let weightKg: Double
}

struct RecentWorkoutSummary: Codable, Sendable {
    let date: Date
    let focus: String
    let exercises: [String]
    let durationMinutes: Int
}

struct InjurySummary: Codable, Sendable {
    let location: String
    let phase: String
    let restrictions: [String]
}

struct BenchmarkSummary: Codable, Sendable {
    let name: String
    let bestScore: Double
    let scoringType: String
}

struct PainActivitySummary: Codable, Sendable {
    let injuryID: String
    let lastPainLevel: Int
    let lastRecordedDate: Date
}

// MARK: - WorkoutGenerationContext

struct WorkoutGenerationContext: Codable, Sendable {
    let userID: String
    let timeMinutes: Int
    let focus: WorkoutFocus
    let energyLevel: EnergyLevel
    let equipment: EquipmentAccess

    let maxes: [ExerciseMax]
    let recentWorkouts: [RecentWorkoutSummary]
    let cyclePhase: String?
    let readinessTier: String?
    let activeInjuries: [InjurySummary]
    let experienceLevel: String
    let primaryGoal: String
    let gender: String
    let weightUnit: String

    let desiredSkills: [String]
    let benchmarkSummaries: [BenchmarkSummary]
    let bodyWeightKg: Double?
    let recentPainActivity: [PainActivitySummary]
    let workoutCompletionRate: Double?

    init(
        userID: String, timeMinutes: Int, focus: WorkoutFocus, energyLevel: EnergyLevel,
        equipment: EquipmentAccess, maxes: [ExerciseMax], recentWorkouts: [RecentWorkoutSummary],
        cyclePhase: String?, readinessTier: String?, activeInjuries: [InjurySummary],
        experienceLevel: String, primaryGoal: String, gender: String, weightUnit: String,
        desiredSkills: [String] = [], benchmarkSummaries: [BenchmarkSummary] = [],
        bodyWeightKg: Double? = nil, recentPainActivity: [PainActivitySummary] = [],
        workoutCompletionRate: Double? = nil
    ) {
        self.userID = userID
        self.timeMinutes = timeMinutes
        self.focus = focus
        self.energyLevel = energyLevel
        self.equipment = equipment
        self.maxes = maxes
        self.recentWorkouts = recentWorkouts
        self.cyclePhase = cyclePhase
        self.readinessTier = readinessTier
        self.activeInjuries = activeInjuries
        self.experienceLevel = experienceLevel
        self.primaryGoal = primaryGoal
        self.gender = gender
        self.weightUnit = weightUnit
        self.desiredSkills = desiredSkills
        self.benchmarkSummaries = benchmarkSummaries
        self.bodyWeightKg = bodyWeightKg
        self.recentPainActivity = recentPainActivity
        self.workoutCompletionRate = workoutCompletionRate
    }
}
