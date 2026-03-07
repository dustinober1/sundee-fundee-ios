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
    var selectedSkills: [String] = []

    // State
    var isGenerating = false
    var generatedWorkout: GeneratedWorkout?
    var errorMessage: String?
    var currentPage: Int = 0

    private let aiService: any AIWorkoutServiceProtocol

    static let timeOptions: [Int] = [15, 30, 45, 60, 75, 90]
    static let skillOptions: [String] = [
        "Handstands", "Pull-ups", "Muscle-ups", "Pistol Squats",
        "Double-Unders", "Snatch", "Clean & Jerk", "L-Sit",
        "Box Jumps", "Rope Climb"
    ]

    init(aiService: any AIWorkoutServiceProtocol) {
        self.aiService = aiService
    }

    func generateWorkout(modelContext: ModelContext, userID: String) async {
        guard !isGenerating else { return }
        isGenerating = true
        errorMessage = nil

        let context = buildContext(modelContext: modelContext, userID: userID)

        do {
            generatedWorkout = try await aiService.generateWorkout(context: context)
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
        let benchmarkDefRepo = SwiftDataBenchmarkDefinitionRepository(context: modelContext)
        let benchmarkResultRepo = SwiftDataBenchmarkResultRepository(context: modelContext)
        let painRepo = SwiftDataPainLogRepository(context: modelContext)

        let currentUser = try? userRepo.fetchCurrentUser()
        let maxes = buildMaxes(liftRepo: liftRepo)
        let recentWorkouts = buildRecentWorkouts(workoutRepo: workoutRepo)
        let cyclePhase = buildCyclePhase(cycleRepo: cycleRepo)
        let injuries = buildInjuries(injuryRepo: injuryRepo, userID: userID)
        let benchmarks = buildBenchmarkSummaries(defRepo: benchmarkDefRepo, resultRepo: benchmarkResultRepo)
        let recentPain = buildRecentPainActivity(painRepo: painRepo, userID: userID)
        let completionRate = buildCompletionRate(workoutRepo: workoutRepo)

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
            weightUnit: currentUser?.weightUnit.rawValue ?? "lb",
            desiredSkills: selectedSkills,
            benchmarkSummaries: benchmarks,
            bodyWeightKg: currentUser?.bodyWeightKg,
            recentPainActivity: recentPain,
            workoutCompletionRate: completionRate
        )
    }

    private func buildMaxes(liftRepo: SwiftDataLiftRepository) -> [ExerciseMax] {
        let orms = (try? liftRepo.fetchOneRepMaxes()) ?? []
        var seen = Set<String>()
        return orms.compactMap { orm in
            guard !seen.contains(orm.exerciseID) else { return nil }
            seen.insert(orm.exerciseID)
            // Convert kg to lbs for LLM
            let weightLb = orm.weightKg * 2.2046226218
            return ExerciseMax(name: orm.exerciseID, weightLb: weightLb)
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

    private func buildBenchmarkSummaries(defRepo: SwiftDataBenchmarkDefinitionRepository, resultRepo: SwiftDataBenchmarkResultRepository) -> [BenchmarkSummary] {
        let definitions = (try? defRepo.fetchAll()) ?? []
        var summaries: [BenchmarkSummary] = []

        for definition in definitions {
            let results = (try? resultRepo.fetchResults(forDefinitionID: definition.id)) ?? []
            guard let best = results.max(by: { $0.scoreValue < $1.scoreValue }) else { continue }
            summaries.append(BenchmarkSummary(
                name: definition.name,
                bestScore: best.scoreValue,
                scoringType: definition.scoringTypeRaw
            ))
        }

        return summaries
    }

    private func buildRecentPainActivity(painRepo: SwiftDataPainLogRepository, userID: String) -> [PainActivitySummary] {
        let painLogs = (try? painRepo.fetchAllLogs()) ?? []
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now

        var painByInjury: [String: PainActivitySummary] = [:]

        for log in painLogs.filter({ $0.recordedAt >= sevenDaysAgo }) {
            let key = log.injuryProfileID
            if let existing = painByInjury[key],
               existing.lastRecordedDate < log.recordedAt {
                painByInjury[key] = PainActivitySummary(
                    injuryID: key,
                    lastPainLevel: log.painLevel,
                    lastRecordedDate: log.recordedAt
                )
            } else if painByInjury[key] == nil {
                painByInjury[key] = PainActivitySummary(
                    injuryID: key,
                    lastPainLevel: log.painLevel,
                    lastRecordedDate: log.recordedAt
                )
            }
        }

        return Array(painByInjury.values)
    }

    private func buildCompletionRate(workoutRepo: SwiftDataWorkoutRepository) -> Double? {
        let workouts = (try? workoutRepo.fetchWorkouts()) ?? []
        let twentyEightDaysAgo = Calendar.current.date(byAdding: .day, value: -28, to: .now) ?? .now

        let completedCount = workouts.filter { $0.completedAt >= twentyEightDaysAgo }.count
        let expectedSessions = 4 * 4  // 4 weeks × 4 sessions/week default

        return Double(completedCount) / Double(expectedSessions)
    }

    // MARK: - Validation

    var canGenerate: Bool {
        timeMinutes > 0
    }
}
