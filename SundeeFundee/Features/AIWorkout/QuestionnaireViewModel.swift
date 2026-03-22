import Foundation
import SwiftData

@MainActor
@Observable
final class QuestionnaireViewModel {
    // Questionnaire answers
    var timeMinutes: Int = 45
    var focus: WorkoutFocus = .fullBody
    var energyLevel: EnergyLevel = .medium
    var equipment: EquipmentAccess = .fullGym

    // State
    var isGenerating = false
    var generatedWorkout: GeneratedWorkout?
    var errorMessage: String?
    var currentPage: Int = 0

    private let aiService: any AIWorkoutServiceProtocol

    static let timeOptions: [Int] = [30, 45, 60, 75]

    init(aiService: any AIWorkoutServiceProtocol) {
        self.aiService = aiService
    }

    /// Whether the user has exceeded their AI workout limit for the current tier.
    var isAtUsageLimit = false

    func checkUsageLimit(tier: SubscriptionTier) {
        let used = AIUsageTracker.usageThisMonth()
        isAtUsageLimit = !FeatureEntitlement.canGenerateAIWorkout(tier: tier, usedThisMonth: used)
    }

    func generateWorkout(modelContext: ModelContext, userID: String, tier: SubscriptionTier) async {
        guard !isGenerating else { return }

        let used = AIUsageTracker.usageThisMonth()
        guard FeatureEntitlement.canGenerateAIWorkout(tier: tier, usedThisMonth: used) else {
            isAtUsageLimit = true
            return
        }

        isGenerating = true
        errorMessage = nil

        let context = buildContext(modelContext: modelContext, userID: userID)

        do {
            generatedWorkout = try await aiService.generateWorkout(context: context)
            AIUsageTracker.incrementUsage()
        } catch {
            errorMessage = "Failed to generate workout. Please try again."
        }

        isGenerating = false
    }

    // MARK: - Context Building

    func buildContext(modelContext: ModelContext, userID: String) -> WorkoutGenerationContext {
        let userRepo = SwiftDataUserRepository(context: modelContext)
        let liftRepo = SwiftDataLiftRepository(context: modelContext)
        let cycleRepo = SwiftDataCycleRepository(context: modelContext)
        let injuryRepo = SwiftDataInjuryRepository(context: modelContext)
        let workoutRepo = SwiftDataWorkoutRepository(context: modelContext)

        let currentUser = try? userRepo.fetchCurrentUser()
        let maxes = buildMaxes(liftRepo: liftRepo)
        let recentWorkouts = buildRecentWorkouts(workoutRepo: workoutRepo)
        let cyclePhase = buildCyclePhase(cycleRepo: cycleRepo)
        let injuries = buildInjuries(injuryRepo: injuryRepo, userID: userID)

        return WorkoutGenerationContext(
            userID: userID,
            timeMinutes: timeMinutes,
            focus: focus,
            energyLevel: energyLevel,
            equipment: equipment,
            maxes: maxes,
            recentWorkouts: recentWorkouts,
            cyclePhase: cyclePhase,
            readinessTier: nil,
            activeInjuries: injuries,
            experienceLevel: currentUser?.experienceLevel.rawValue ?? "beginner",
            primaryGoal: currentUser?.primaryGoal.rawValue ?? "strength",
            gender: currentUser?.gender.rawValue ?? "prefer_not_to_say",
            weightUnit: currentUser?.weightUnit.rawValue ?? "lb"
        )
    }

    private func buildMaxes(liftRepo: SwiftDataLiftRepository) -> [ExerciseMax] {
        let orms = (try? liftRepo.fetchOneRepMaxes()) ?? []
        var seen = Set<String>()
        return orms.compactMap { orm in
            guard !seen.contains(orm.exerciseID) else { return nil }
            seen.insert(orm.exerciseID)
            return ExerciseMax(name: orm.exerciseID, weightKg: orm.weightKg)
        }
    }

    private func buildRecentWorkouts(workoutRepo: SwiftDataWorkoutRepository) -> [RecentWorkoutSummary] {
        let workouts = (try? workoutRepo.fetchWorkouts()) ?? []
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
        return workouts
            .filter { $0.completedAt >= twoWeeksAgo }
            .prefix(10)
            .map { workout in
                RecentWorkoutSummary(
                    date: workout.completedAt,
                    focus: workout.sessionID,
                    exercises: [],
                    durationMinutes: workout.durationSeconds / 60
                )
            }
    }

    private func buildCyclePhase(cycleRepo: SwiftDataCycleRepository) -> String? {
        let settings = try? cycleRepo.fetchCycleSettings()
        let logs = (try? cycleRepo.fetchPeriodLogs()) ?? []
        guard let settings else { return nil }
        let status = CycleCalculations.calculateCycleStatus(periodLogs: logs, settings: settings)
        return status?.currentPhase.rawValue
    }

    private func buildInjuries(injuryRepo: SwiftDataInjuryRepository, userID: String) -> [InjurySummary] {
        let injuries = (try? injuryRepo.fetchActiveInjuries(userID: userID)) ?? []
        return injuries.map { injury in
            InjurySummary(
                location: injury.location,
                phase: injury.recoveryPhase.rawValue,
                restrictions: InjuryAdaptationEngine.normalizedBodyRegions(from: [injury])
            )
        }
    }

    // MARK: - Validation

    var canGenerate: Bool {
        timeMinutes > 0
    }
}
