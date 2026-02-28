import SwiftData
import Foundation

#if DEBUG
/// Seeds sample data for manual UAT testing.
///
/// Creates a user, enrolls them in the bundled program, sets up
/// starter 1RM values, and configures cycle tracking defaults.
/// Activated from the Settings screen debug section.
enum DebugSeedData {

    @MainActor
    static func seed(modelContext: ModelContext) async {
        // Avoid double-seeding
        let existingUsers = try! modelContext.fetch(FetchDescriptor<User>())
        if !existingUsers.isEmpty { return }

        let userID = UUID().uuidString

        // 1. Create user
        let user = User(
            id: userID,
            name: "Test Athlete",
            experienceLevel: .intermediate,
            primaryGoal: .strength,
            gender: .female,
            appleUserID: "debug-\(userID)",
            cycleTrackingEnabled: true,
            onboardingComplete: true
        )
        modelContext.insert(user)

        // 2. Enroll in the bundled program
        let enrollment = EnrolledProgram(
            id: UUID().uuidString,
            userID: userID,
            programID: "squad-squat-12-week-peak",
            startDate: .now
        )
        modelContext.insert(enrollment)

        // 3. Seed starter 1RM values (kg)
        let maxes: [(String, Double)] = [
            ("Back Squat", 100),
            ("Front Squat", 80),
            ("Conventional Deadlift (No Straps)", 120),
            ("Romanian Deadlift (No Straps)", 90),
            ("Bench Press", 70),
            ("Overhead Press", 45),
            ("Barbell Row", 65),
        ]

        for (exercise, weight) in maxes {
            let orm = OneRepMax(
                id: UUID().uuidString,
                userID: userID,
                exerciseID: exercise,
                weightKg: weight,
                isEstimated: true
            )
            modelContext.insert(orm)

            let lm = LiftMax(
                id: UUID().uuidString,
                userID: userID,
                exerciseID: exercise,
                weightKg: weight
            )
            modelContext.insert(lm)
        }

        // 4. Cycle settings
        let cycleSettings = CycleSettings(
            id: UUID().uuidString,
            userID: userID,
            averageCycleLengthDays: 28,
            averagePeriodLengthDays: 5,
            lutealPhaseLengthDays: 14
        )
        modelContext.insert(cycleSettings)

        // 5. A recent period log for cycle phase display
        let periodStart = Calendar.current.date(byAdding: .day, value: -3, to: .now)!
        let periodLog = PeriodLog(
            id: UUID().uuidString,
            userID: userID,
            startDate: periodStart
        )
        modelContext.insert(periodLog)

        try? modelContext.save()
    }

    @MainActor
    static func clearAll(modelContext: ModelContext) {
        let types: [any PersistentModel.Type] = AppSchemaV6.models
        for type in types {
            try? modelContext.delete(model: type)
        }
        try? modelContext.save()
    }
}
#endif
