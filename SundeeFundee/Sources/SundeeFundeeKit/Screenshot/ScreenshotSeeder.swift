import Foundation
import HealthKit

// MARK: - ScreenshotSeeder
//
// Populates local data stores with realistic sample data for App Store screenshots.
// Activated by passing --seed-screenshots as a launch argument.
//
// Usage (in App.swift):
//   if CommandLine.arguments.contains("--seed-screenshots") {
//       await ScreenshotSeeder.seed()
//   }

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public enum ScreenshotSeeder {

    /// Seeds all data stores with realistic screenshot data.
    @MainActor
    public static func seed() async {
        // 1. Configure factories for local/mock storage
        let localClient = LocalDataClient()
        DataClientFactory.shared.client = localClient

        let mockHealth = MockHealthKitClient()
        mockHealth.isAvailable = true
        mockHealth.authorizationGranted = true
        HealthClientFactory.shared.client = mockHealth

        // 2. Clear any previous data
        try? await localClient.deleteAllData()

        // 3. Seed data
        await seedOneRepMaxes(into: localClient)
        await seedWorkouts(into: localClient)
        await seedProgram(into: localClient)
        await seedCelebrations(into: localClient)
        await seedSettings(into: localClient)
        await seedCycleSettings(into: localClient)
        await seedBenchmarkResults(into: localClient)
        seedHealthKitWorkouts(into: mockHealth)
        seedMenstrualCycles(into: mockHealth)

        // 4. Mark onboarding complete and set user name
        _ = KeychainHelper.save(key: KeychainHelper.userIDKey, value: AuthViewModel.guestUserID)
        _ = KeychainHelper.save(key: "onboarding_complete", value: "true")
        _ = KeychainHelper.save(key: KeychainHelper.userNameKey, value: "Sarah")

        print("[ScreenshotSeeder] Data seeded successfully")
    }

    // MARK: - One Rep Maxes

    private static func seedOneRepMaxes(into client: LocalDataClient) async {
        let cal = Calendar.current
        let now = Date()

        let maxes = [
            OneRepMaxRecord(
                id: "max-1",
                exerciseName: "Back Squat",
                weight: 225,
                unit: .lbs,
                date: cal.date(byAdding: .day, value: -3, to: now)!
            ),
            OneRepMaxRecord(
                id: "max-2",
                exerciseName: "Bench Press",
                weight: 155,
                unit: .lbs,
                date: cal.date(byAdding: .day, value: -5, to: now)!
            ),
            OneRepMaxRecord(
                id: "max-3",
                exerciseName: "Deadlift",
                weight: 275,
                unit: .lbs,
                date: cal.date(byAdding: .day, value: -7, to: now)!
            ),
            OneRepMaxRecord(
                id: "max-4",
                exerciseName: "Overhead Press",
                weight: 95,
                unit: .lbs,
                date: cal.date(byAdding: .day, value: -10, to: now)!
            ),
            OneRepMaxRecord(
                id: "max-5",
                exerciseName: "Front Squat",
                weight: 185,
                unit: .lbs,
                date: cal.date(byAdding: .day, value: -14, to: now)!
            ),
            OneRepMaxRecord(
                id: "max-6",
                exerciseName: "Barbell Row",
                weight: 135,
                unit: .lbs,
                date: cal.date(byAdding: .day, value: -12, to: now)!
            ),
        ]

        try? await client.save(maxes, recordType: "OneRepMaxRecord")
    }

    // MARK: - Workouts

    private static func seedWorkouts(into client: LocalDataClient) async {
        let cal = Calendar.current
        let now = Date()

        let workouts = [
            makeWorkout(
                id: "w-1",
                name: "Upper Body Strength",
                date: cal.date(byAdding: .day, value: -1, to: now)!,
                duration: 52,
                exercises: [
                    makeExercise("Bench Press", .compound, sets: [(5, 135), (5, 135), (5, 135)]),
                    makeExercise("Barbell Row", .compound, sets: [(8, 115), (8, 115), (8, 115)]),
                    makeExercise("Overhead Press", .compound, sets: [(8, 75), (8, 75), (8, 75)]),
                    makeExercise("Lat Pulldown", .accessory, sets: [(10, 90), (10, 90), (10, 90)]),
                ]
            ),
            makeWorkout(
                id: "w-2",
                name: "Lower Body Power",
                date: cal.date(byAdding: .day, value: -3, to: now)!,
                duration: 58,
                exercises: [
                    makeExercise("Back Squat", .compound, sets: [(5, 195), (5, 195), (3, 215), (1, 225)]),
                    makeExercise("Romanian Deadlift", .compound, sets: [(8, 135), (8, 135), (8, 135)]),
                    makeExercise("Walking Lunges", .accessory, sets: [(12, 50), (12, 50), (12, 50)]),
                    makeExercise("Leg Curl", .isolation, sets: [(10, 70), (10, 70)]),
                ]
            ),
            makeWorkout(
                id: "w-3",
                name: "Push Day",
                date: cal.date(byAdding: .day, value: -5, to: now)!,
                duration: 48,
                exercises: [
                    makeExercise("Bench Press", .compound, sets: [(3, 145), (3, 145), (1, 155)]),
                    makeExercise("Incline Dumbbell Press", .compound, sets: [(8, 50), (8, 50), (8, 50)]),
                    makeExercise("Lateral Raise", .isolation, sets: [(12, 15), (12, 15), (12, 15)]),
                    makeExercise("Tricep Pushdown", .isolation, sets: [(12, 40), (12, 40)]),
                ]
            ),
            makeWorkout(
                id: "w-4",
                name: "Full Body",
                date: cal.date(byAdding: .day, value: -6, to: now)!,
                duration: 62,
                exercises: [
                    makeExercise("Deadlift", .compound, sets: [(5, 225), (5, 225), (3, 255), (1, 275)]),
                    makeExercise("Dumbbell Bench Press", .compound, sets: [(8, 55), (8, 55), (8, 55)]),
                    makeExercise("Pull-ups", .compound, sets: [(8, 0), (7, 0), (6, 0)]),
                    makeExercise("Plank", .accessory, sets: [(1, 0)]),
                ]
            ),
            makeWorkout(
                id: "w-5",
                name: "Lower Body Hypertrophy",
                date: cal.date(byAdding: .day, value: -8, to: now)!,
                duration: 55,
                exercises: [
                    makeExercise("Front Squat", .compound, sets: [(8, 155), (8, 155), (8, 155)]),
                    makeExercise("Leg Press", .compound, sets: [(10, 270), (10, 270), (10, 270)]),
                    makeExercise("Leg Extension", .isolation, sets: [(12, 80), (12, 80)]),
                    makeExercise("Calf Raise", .isolation, sets: [(15, 90), (15, 90), (15, 90)]),
                ]
            ),
            makeWorkout(
                id: "w-6",
                name: "Pull Day",
                date: cal.date(byAdding: .day, value: -10, to: now)!,
                duration: 50,
                exercises: [
                    makeExercise("Barbell Row", .compound, sets: [(5, 125), (5, 125), (3, 135)]),
                    makeExercise("Lat Pulldown", .compound, sets: [(10, 100), (10, 100), (10, 100)]),
                    makeExercise("Face Pull", .accessory, sets: [(15, 30), (15, 30), (15, 30)]),
                    makeExercise("Bicep Curl", .isolation, sets: [(10, 25), (10, 25)]),
                ]
            ),
        ]

        try? await client.save(workouts, recordType: "Workout")
    }

    // MARK: - Program

    private static func seedProgram(into client: LocalDataClient) async {
        let program = EnrolledProgramRecord(
            id: "prog-1",
            name: "Strength Basics",
            isActive: true
        )
        try? await client.save([program], recordType: "EnrolledProgramRecord")
    }

    // MARK: - Celebrations

    private static func seedCelebrations(into client: LocalDataClient) async {
        let cal = Calendar.current
        let now = Date()

        let wins = [
            CelebrationEventRecord(
                id: "cel-1",
                description: "New PR: Back Squat 225 lbs",
                date: cal.date(byAdding: .day, value: -3, to: now)!
            ),
            CelebrationEventRecord(
                id: "cel-2",
                description: "4 workouts completed this week",
                date: cal.date(byAdding: .day, value: -1, to: now)!
            ),
            CelebrationEventRecord(
                id: "cel-3",
                description: "New PR: Deadlift 275 lbs",
                date: cal.date(byAdding: .day, value: -7, to: now)!
            ),
        ]

        try? await client.save(wins, recordType: "CelebrationEventRecord")
    }

    // MARK: - Settings

    private static func seedSettings(into client: LocalDataClient) async {
        struct UserSettingsRecord: Codable, Sendable {
            let id: String
            let cycleTrackingEnabled: Bool
            let weightUnit: String
            let experienceLevel: String
            let primaryGoal: String
        }

        let settings = UserSettingsRecord(
            id: "default",
            cycleTrackingEnabled: true,
            weightUnit: "lbs",
            experienceLevel: "intermediate",
            primaryGoal: "strength"
        )

        try? await client.save([settings], recordType: "UserSettings")
    }

    // MARK: - Cycle Settings

    private static func seedCycleSettings(into client: LocalDataClient) async {
        let settings = CycleSettings(
            averageCycleLengthDays: 28,
            averagePeriodLengthDays: 5,
            lutealPhaseLengthDays: 14
        )

        try? await client.save([settings], recordType: "CycleSettings")
    }

    // MARK: - Benchmark Results

    private static func seedBenchmarkResults(into client: LocalDataClient) async {
        let cal = Calendar.current
        let now = Date()

        let results = [
            BenchmarkResult(
                id: "bench-1",
                benchmarkId: "fran",
                benchmarkName: "Fran",
                score: 50012,
                notes: "Felt strong in follicular phase",
                date: cal.date(byAdding: .day, value: -14, to: now)!,
                cyclePhase: .follicular
            ),
            BenchmarkResult(
                id: "bench-2",
                benchmarkId: "grace",
                benchmarkName: "Grace",
                score: 30208,
                notes: nil,
                date: cal.date(byAdding: .day, value: -21, to: now)!,
                cyclePhase: .ovulation
            ),
        ]

        try? await client.save(results, recordType: "BenchmarkResult")
    }

    // MARK: - HealthKit Workouts

    private static func seedHealthKitWorkouts(into client: MockHealthKitClient) {
        let cal = Calendar.current
        let now = Date()

        // 4 workouts this week
        for dayOffset in [0, -1, -3, -5] {
            let start = cal.date(byAdding: .day, value: dayOffset, to: now)!
            let workout = MockHealthKitClient.createMockWorkout(
                startDate: cal.date(byAdding: .hour, value: -1, to: start)!,
                endDate: start,
                totalEnergyBurned: Double.random(in: 250...400)
            )
            client.addMockWorkout(workout)
        }

        // A few more from previous weeks
        for dayOffset in [-8, -10, -12, -15] {
            let start = cal.date(byAdding: .day, value: dayOffset, to: now)!
            let workout = MockHealthKitClient.createMockWorkout(
                startDate: cal.date(byAdding: .hour, value: -1, to: start)!,
                endDate: start,
                totalEnergyBurned: Double.random(in: 200...350)
            )
            client.addMockWorkout(workout)
        }
    }

    // MARK: - Menstrual Cycles

    private static func seedMenstrualCycles(into client: MockHealthKitClient) {
        let cal = Calendar.current
        let now = Date()

        // Create several months of cycle data to establish a pattern.
        // Position us in the follicular phase (days 6-13, rising energy).
        // Last period started ~8 days ago, lasted 5 days.
        let lastPeriodStart = cal.date(byAdding: .day, value: -8, to: now)!

        // Generate flow samples for the last period (5 days)
        for dayOffset in 0..<5 {
            let date = cal.date(byAdding: .day, value: dayOffset, to: lastPeriodStart)!
            let flowValue: Int
            switch dayOffset {
            case 0: flowValue = 2  // light
            case 1, 2: flowValue = 4  // heavy
            case 3: flowValue = 3  // medium
            case 4: flowValue = 2  // light
            default: flowValue = 1
            }

            if let sample = MockHealthKitClient.createMockMenstrualCycle(
                startDate: date,
                endDate: cal.date(byAdding: .day, value: 1, to: date)!,
                value: flowValue,
                isStartOfCycle: dayOffset == 0
            ) {
                client.addMockMenstrualCycle(sample)
            }
        }

        // Previous cycles (3 months back) for confidence
        for cycleBack in 1...3 {
            let periodStart = cal.date(byAdding: .day, value: -(cycleBack * 28) - 8, to: now)!
            for dayOffset in 0..<5 {
                let date = cal.date(byAdding: .day, value: dayOffset, to: periodStart)!
                if let sample = MockHealthKitClient.createMockMenstrualCycle(
                    startDate: date,
                    endDate: cal.date(byAdding: .day, value: 1, to: date)!,
                    value: dayOffset < 3 ? 4 : 2,
                    isStartOfCycle: dayOffset == 0
                ) {
                    client.addMockMenstrualCycle(sample)
                }
            }
        }
    }

    // MARK: - Helpers

    private static func makeWorkout(
        id: String,
        name: String,
        date: Date,
        duration: Int,
        exercises: [Exercise]
    ) -> Workout {
        Workout(
            id: id,
            date: date,
            name: name,
            exercises: exercises,
            duration: duration,
            completedAt: date
        )
    }

    private static func makeExercise(
        _ name: String,
        _ category: ExerciseCategory,
        sets: [(Int, Double)]
    ) -> Exercise {
        Exercise(
            id: UUID().uuidString,
            name: name,
            category: category,
            bodyweight: 140,
            targetSets: sets.map { reps, weight in
                ExerciseSet(
                    reps: reps,
                    prescribedWeight: weight,
                    type: .fixed,
                    completedWeight: weight,
                    actualReps: reps,
                    isComplete: true
                )
            },
            restMinutes: category == .compound ? 2.5 : 1.5
        )
    }
}
