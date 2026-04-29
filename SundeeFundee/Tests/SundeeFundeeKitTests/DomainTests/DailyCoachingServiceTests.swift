import XCTest
@testable import SundeeFundeeKit

final class DailyCoachingServiceTests: XCTestCase {

    private func makeDayString() -> String {
        ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
    }

    private func makeContext(
        cyclePhase: CyclePhase? = .luteal,
        cycleConfidence: Double? = 0.8,
        workoutsThisWeek: Int = 6,
        trends: [WeeklyLoadAnalyzer.LoadTrend] = [],
        plateaus: [PlateauDetector.PlateauAlert] = []
    ) -> CoachContext {
        CoachContext(
            cyclePhase: cyclePhase,
            cycleConfidence: cycleConfidence,
            experienceLevel: "intermediate",
            primaryGoal: "strength",
            tier: .premium,
            maxes: [],
            injuries: [],
            workoutsThisWeek: workoutsThisWeek,
            weeklySummaries: [],
            trends: trends,
            plateaus: plateaus,
            volumePlateaus: [],
            progressWarnings: [],
            equipment: .fullGym
        )
    }

    func testRecommendationPersistsAndDeloadsOnOverreachingTrend() async throws {
        let dataClient = MockCloudKitClient()
        let day = makeDayString()

        try await dataClient.save(
            RecoveryScoreRecord(
                scoreDate: day,
                totalScore: 62,
                hrvSubScore: 60,
                sleepSubScore: 70,
                loadSubScore: 55,
                cyclePhaseSubScore: 60,
                painSubScore: 65,
                presentInputCount: 5,
                cyclePhaseRaw: CyclePhase.luteal.rawValue,
                recommendationRaw: TrainingRecommendation.moderate.rawValue
            ),
            recordType: "RecoveryScore"
        )

        let service = DailyCoachingService(
            dataClient: dataClient,
            contextBuilder: CoachContextBuilder(
                healthClient: MockHealthKitClient(),
                dataClient: dataClient
            ),
            coachService: StubCoachService()
        )

        let trend = WeeklyLoadAnalyzer.LoadTrend(
            type: .overreaching,
            message: "High volume recently.",
            severity: .warning
        )
        let recommendation = await service.loadRecommendation(
            context: makeContext(trends: [trend]),
            insights: CoachInsightsResponse(
                plateaus: [],
                trends: [trend],
                summary: "High volume recently.",
                priorityActions: ["Pull back a little."]
            ),
            isGuest: false
        )

        XCTAssertEqual(recommendation.status, .deload)
        XCTAssertEqual(recommendation.primaryActionRaw, DailyCoachingPrimaryAction.startAdjustedWorkout.rawValue)

        let saved: [DailyCoachingRecommendationRecord] = try await dataClient.fetchAll(
            recordType: "DailyCoachingRecommendation"
        )
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.statusRaw, DailyCoachingStatus.deload.rawValue)
        XCTAssertEqual(saved.first?.recommendationDate, day)
    }

    func testGuestRecommendationDoesNotPersist() async throws {
        let dataClient = MockCloudKitClient()
        let service = DailyCoachingService(
            dataClient: dataClient,
            contextBuilder: CoachContextBuilder(
                healthClient: MockHealthKitClient(),
                dataClient: dataClient
            ),
            coachService: StubCoachService()
        )

        _ = await service.loadRecommendation(
            context: makeContext(cyclePhase: .follicular),
            insights: CoachInsightsResponse(plateaus: [], trends: [], summary: "", priorityActions: []),
            isGuest: true
        )

        let saved: [DailyCoachingRecommendationRecord] = try await dataClient.fetchAll(
            recordType: "DailyCoachingRecommendation"
        )
        XCTAssertTrue(saved.isEmpty)
    }

    func testAdjustedWorkoutUsesExistingCoachGenerator() async throws {
        let dataClient = MockCloudKitClient()
        let service = DailyCoachingService(
            dataClient: dataClient,
            contextBuilder: CoachContextBuilder(
                healthClient: MockHealthKitClient(),
                dataClient: dataClient
            ),
            coachService: StubCoachService()
        )

        let recommendation = DailyCoachingRecommendation(
            recommendationDate: makeDayString(),
            statusRaw: DailyCoachingStatus.build.rawValue,
            title: "Build day",
            summary: "Keep the session productive.",
            primaryActionRaw: DailyCoachingPrimaryAction.startAdjustedWorkout.rawValue,
            primaryActionTitle: "Start build workout",
            reasonCodes: ["Recovery score 82"],
            recoveryScoreTotal: 82,
            recoveryRecommendationRaw: TrainingRecommendation.pushDay.rawValue,
            cyclePhaseRaw: CyclePhase.follicular.rawValue,
            cycleConfidence: 0.9,
            trainingLoadTrendRaw: WeeklyLoadAnalyzer.TrendType.consistent.rawValue,
            painIntensity: 1,
            workoutFocusRaw: WorkoutFocus.fullBody.rawValue,
            energyLevelRaw: EnergyLevel.medium.rawValue,
            equipmentRaw: EquipmentAccess.fullGym.rawValue,
            timeMinutes: 45
        )

        let workout = await service.buildAdjustedWorkout(from: recommendation)

        XCTAssertEqual(workout?.name, "Adjusted Workout")
        XCTAssertEqual(workout?.exercises.count, 1)
        XCTAssertTrue(workout?.notes?.contains("Daily coaching") == true)
        XCTAssertTrue(workout?.notes?.contains("Balanced build") == true)
    }
}

private final class StubCoachService: CoachServiceProtocol, @unchecked Sendable {
    func generateWorkout(context: CoachContext, preferences: QuestionnaireAnswers) async throws -> CoachWorkoutResponse {
        let workout = GeneratedWorkout(
            id: "generated",
            createdAt: Date(timeIntervalSince1970: 1),
            isFavorite: false,
            coachingSummary: "Balanced build",
            exercises: [
                GeneratedExercise(
                    id: "ex-1",
                    name: "Push-Up",
                    sets: 3,
                    reps: "8-10",
                    bodyweightOnly: true
                )
            ],
            questionnaire: preferences
        )
        return CoachWorkoutResponse(workout: workout, coachingSummary: workout.coachingSummary, tips: [])
    }

    func getInsights(context: CoachContext) async throws -> CoachInsightsResponse {
        CoachInsightsResponse(plateaus: [], trends: [], summary: "", priorityActions: [])
    }

    func suggestSubstitutions(
        for exercise: String,
        context: CoachContext
    ) async throws -> CoachSubstitutionResponse {
        CoachSubstitutionResponse(
            originalExercise: exercise,
            substitutions: [],
            explanation: ""
        )
    }

    func adaptWeeklyPlan(
        plan: [ScheduleReshuffler.PlannedSession],
        completedDays: Set<Int>,
        missedDays: Set<Int>,
        currentDay: Int,
        context: CoachContext
    ) async throws -> CoachPlanResponse {
        CoachPlanResponse(
            result: ScheduleReshuffler.reshuffle(
                plan: plan,
                completedDays: completedDays,
                missedDays: missedDays,
                currentDay: currentDay
            ),
            explanation: ""
        )
    }
}
