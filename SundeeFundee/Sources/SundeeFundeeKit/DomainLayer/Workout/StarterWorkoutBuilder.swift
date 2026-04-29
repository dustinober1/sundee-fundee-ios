import Foundation

public struct StarterWorkoutContext: Sendable, Equatable {
    public let experienceLevel: ExperienceLevel
    public let primaryGoal: PrimaryGoal
    public let weightUnit: WeightUnit
    public let cycleTrackingEnabled: Bool

    public init(
        experienceLevel: ExperienceLevel,
        primaryGoal: PrimaryGoal,
        weightUnit: WeightUnit,
        cycleTrackingEnabled: Bool
    ) {
        self.experienceLevel = experienceLevel
        self.primaryGoal = primaryGoal
        self.weightUnit = weightUnit
        self.cycleTrackingEnabled = cycleTrackingEnabled
    }
}

public enum StarterWorkoutBuilder {
    public static func build(context: StarterWorkoutContext, date: Date = Date()) -> Workout {
        let prescriptions = prescriptions(for: context)
        return Workout(
            date: date,
            name: "First Sundee Fundee Workout",
            exercises: prescriptions.map(makeExercise),
            notes: context.cycleTrackingEnabled
                ? "Starter workout built from onboarding preferences with cycle-aware training enabled."
                : "Starter workout built from onboarding preferences."
        )
    }

    private static func prescriptions(for context: StarterWorkoutContext) -> [Prescription] {
        switch context.primaryGoal {
        case .weightLoss, .endurance:
            return [
                .init("Bodyweight Squat", .compound, true, 3, 12, 0, 1.0),
                .init("Incline Push-Up", .accessory, true, 3, 10, 0, 1.0),
                .init("Dumbbell Row", .accessory, false, 3, 12, 0, 1.0),
                .init("Glute Bridge", .accessory, true, 3, 12, 0, 1.0),
                .init("Plank", .accessory, true, 2, 30, 0, 0.75)
            ]
        case .strength, .hypertrophy:
            switch context.experienceLevel {
            case .beginner:
                return [
                    .init("Bodyweight Squat", .compound, true, 3, 8, 0, 1.5),
                    .init("Push-Up", .accessory, true, 3, 8, 0, 1.5),
                    .init("Dumbbell Row", .accessory, false, 3, 10, 0, 1.5),
                    .init("Romanian Deadlift", .compound, false, 3, 8, 0, 1.5),
                    .init("Plank", .accessory, true, 2, 30, 0, 1.0)
                ]
            case .intermediate:
                return [
                    .init("Goblet Squat", .compound, false, 3, 8, 0, 2.0),
                    .init("Dumbbell Bench Press", .compound, false, 3, 8, 0, 2.0),
                    .init("One-Arm Dumbbell Row", .accessory, false, 3, 10, 0, 1.5),
                    .init("Romanian Deadlift", .compound, false, 3, 8, 0, 2.0),
                    .init("Dead Bug", .accessory, true, 2, 10, 0, 1.0)
                ]
            case .advanced:
                return [
                    .init("Front Squat", .compound, false, 4, 6, 0, 2.5),
                    .init("Bench Press", .compound, false, 4, 6, 0, 2.5),
                    .init("Barbell Row", .compound, false, 3, 8, 0, 2.0),
                    .init("Romanian Deadlift", .compound, false, 3, 8, 0, 2.0),
                    .init("Side Plank", .accessory, true, 2, 30, 0, 1.0)
                ]
            }
        }
    }

    private static func makeExercise(_ prescription: Prescription) -> Exercise {
        Exercise(
            id: UUID().uuidString,
            name: prescription.name,
            category: prescription.category,
            bodyweight: prescription.bodyweight ? 1.0 : 0.0,
            targetSets: (0..<prescription.sets).map { _ in
                ExerciseSet(
                    reps: prescription.reps,
                    prescribedWeight: prescription.weight,
                    type: .fixed
                )
            },
            restMinutes: prescription.restMinutes
        )
    }

    private struct Prescription {
        let name: String
        let category: ExerciseCategory
        let bodyweight: Bool
        let sets: Int
        let reps: Int
        let weight: Double
        let restMinutes: Double

        init(
            _ name: String,
            _ category: ExerciseCategory,
            _ bodyweight: Bool,
            _ sets: Int,
            _ reps: Int,
            _ weight: Double,
            _ restMinutes: Double
        ) {
            self.name = name
            self.category = category
            self.bodyweight = bodyweight
            self.sets = sets
            self.reps = reps
            self.weight = weight
            self.restMinutes = restMinutes
        }
    }
}
