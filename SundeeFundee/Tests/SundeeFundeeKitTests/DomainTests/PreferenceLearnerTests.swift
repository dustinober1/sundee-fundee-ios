import XCTest
@testable import SundeeFundeeKit

final class PreferenceLearnerTests: XCTestCase {

    // MARK: - Helpers

    private func makeWorkout(
        daysAgo: Int = 0,
        duration: Int = 60,
        exercises: [String] = ["Back Squat", "Flat Barbell Bench Press"]
    ) -> CompletedWorkoutRecord {
        CompletedWorkoutRecord(
            id: UUID().uuidString,
            name: "Workout",
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            duration: duration,
            exerciseNames: exercises,
            isComplete: true
        )
    }

    private func makeQuestionnaire(
        time: Int = 45,
        focus: WorkoutFocus = .fullBody,
        energy: EnergyLevel = .medium,
        equipment: EquipmentAccess = .fullGym
    ) -> QuestionnaireAnswers {
        QuestionnaireAnswers(
            timeMinutes: time,
            focus: focus,
            energyLevel: energy,
            equipment: equipment
        )
    }

    // MARK: - Learn: Session Duration

    func testLearn_SessionDuration_AveragesQuestionnaires() {
        let qs = [
            makeQuestionnaire(time: 30),
            makeQuestionnaire(time: 60),
            makeQuestionnaire(time: 60),
        ]
        let profile = PreferenceLearner.learn(
            existingProfile: CoachProfile(),
            workouts: [],
            questionnaires: qs
        )
        XCTAssertEqual(profile.preferredSessionMinutes, 50) // (30+60+60)/3
    }

    // MARK: - Learn: Focus Areas

    func testLearn_FocusAreas_RankedByFrequency() {
        let qs = [
            makeQuestionnaire(focus: .upperBody),
            makeQuestionnaire(focus: .upperBody),
            makeQuestionnaire(focus: .lowerBody),
            makeQuestionnaire(focus: .fullBody),
        ]
        let profile = PreferenceLearner.learn(
            existingProfile: CoachProfile(),
            workouts: [],
            questionnaires: qs
        )
        XCTAssertEqual(profile.preferredFocusAreas.first, "upper_body")
    }

    // MARK: - Learn: Favorite Exercises

    func testLearn_FavoriteExercises_TopByFrequency() {
        let workouts = [
            makeWorkout(exercises: ["Back Squat", "Bench Press"]),
            makeWorkout(exercises: ["Back Squat", "Deadlift"]),
            makeWorkout(exercises: ["Back Squat", "Bench Press"]),
        ]
        let profile = PreferenceLearner.learn(
            existingProfile: CoachProfile(),
            workouts: workouts
        )
        XCTAssertEqual(profile.favoriteExercises.first, "Back Squat")
    }

    // MARK: - Learn: Avoided Exercises

    func testLearn_AvoidedExercises_FromEdits() {
        let edits = [
            WorkoutEdit(editType: .removedExercise, exerciseName: "Burpee"),
            WorkoutEdit(editType: .removedExercise, exerciseName: "Burpee"),
            WorkoutEdit(editType: .removedExercise, exerciseName: "Thruster"),
        ]
        let profile = PreferenceLearner.learn(
            existingProfile: CoachProfile(),
            workouts: [],
            edits: edits
        )
        // Burpee removed 2+ times → avoided
        XCTAssertTrue(profile.avoidedExercises.contains("Burpee"))
        // Thruster only once → not avoided yet
        XCTAssertFalse(profile.avoidedExercises.contains("Thruster"))
    }

    func testLearn_AvoidedExercises_FromAcceptedSubstitutions() {
        let subs = [
            AcceptedSubstitution(
                originalExercise: "Back Squat",
                substituteExercise: "Goblet Squat",
                accepted: true,
                reason: "equipment"
            ),
            AcceptedSubstitution(
                originalExercise: "Back Squat",
                substituteExercise: "Leg Press",
                accepted: true,
                reason: "preference"
            ),
        ]
        let profile = PreferenceLearner.learn(
            existingProfile: CoachProfile(),
            workouts: [],
            substitutions: subs
        )
        // Accepted moving away from Back Squat 2x → avoided
        XCTAssertTrue(profile.avoidedExercises.contains("Back Squat"))
    }

    // MARK: - Learn: Energy Distribution

    func testLearn_EnergyDistribution() {
        let qs = [
            makeQuestionnaire(energy: .low),
            makeQuestionnaire(energy: .medium),
            makeQuestionnaire(energy: .medium),
            makeQuestionnaire(energy: .high),
        ]
        let profile = PreferenceLearner.learn(
            existingProfile: CoachProfile(),
            workouts: [],
            questionnaires: qs
        )
        XCTAssertEqual(profile.energyDistribution.dominant, .medium)
        XCTAssertEqual(profile.energyDistribution.total, 4)
    }

    // MARK: - Learn: Average Weekly Workouts

    func testLearn_AvgWorkoutsPerWeek() {
        // 8 workouts in the last 4 weeks = 2.0/week
        let workouts = (0..<8).map { i in
            makeWorkout(daysAgo: i * 3)
        }
        let profile = PreferenceLearner.learn(
            existingProfile: CoachProfile(),
            workouts: workouts
        )
        XCTAssertGreaterThan(profile.avgWorkoutsPerWeek, 0)
    }

    // MARK: - Learn: Effort Tolerance

    func testLearn_RepeatedHighRPE_ReducesFutureVolumeProxy() {
        let profile = PreferenceLearner.learn(
            existingProfile: CoachProfile(preferredSessionMinutes: 45),
            workouts: [],
            effortLogs: [
                WorkoutEffortLog(workoutID: "w1", exerciseName: "Back Squat", setID: "s1", rpe: 9),
                WorkoutEffortLog(workoutID: "w1", exerciseName: "Back Squat", setID: "s2", rpe: 10),
                WorkoutEffortLog(workoutID: "w2", exerciseName: nil, setID: nil, rpe: 9),
            ]
        )

        XCTAssertLessThan(profile.preferredSessionMinutes, 45)
    }

    func testLearn_RepeatedHighRPE_IsIdempotentForSameLogs() {
        let effortLogs = [
            WorkoutEffortLog(workoutID: "w1", exerciseName: "Back Squat", setID: "s1", rpe: 9),
            WorkoutEffortLog(workoutID: "w1", exerciseName: "Back Squat", setID: "s2", rpe: 10),
            WorkoutEffortLog(workoutID: "w2", exerciseName: nil, setID: nil, rpe: 9),
        ]
        let firstPass = PreferenceLearner.learn(
            existingProfile: CoachProfile(preferredSessionMinutes: 45),
            workouts: [],
            effortLogs: effortLogs
        )
        let secondPass = PreferenceLearner.learn(
            existingProfile: firstPass,
            workouts: [],
            effortLogs: effortLogs
        )

        XCTAssertEqual(secondPass.preferredSessionMinutes, firstPass.preferredSessionMinutes)
    }

    func testLearn_RepeatedLowRPE_AllowsNormalProgression() {
        let profile = PreferenceLearner.learn(
            existingProfile: CoachProfile(preferredSessionMinutes: 45),
            workouts: [],
            effortLogs: [
                WorkoutEffortLog(workoutID: "w1", exerciseName: "Back Squat", setID: "s1", rpe: 4),
                WorkoutEffortLog(workoutID: "w1", exerciseName: "Back Squat", setID: "s2", rpe: 5),
                WorkoutEffortLog(workoutID: "w2", exerciseName: nil, setID: nil, rpe: 5),
            ]
        )

        XCTAssertEqual(profile.preferredSessionMinutes, 45)
    }

    // MARK: - Weekly Summary

    func testGenerateWeeklySummary_WithWorkouts() {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())!.start
        let workouts = [
            CompletedWorkoutRecord(
                id: "1", name: "Push", date: weekStart,
                duration: 60, exerciseNames: ["Flat Barbell Bench Press", "Strict Press"], isComplete: true
            ),
            CompletedWorkoutRecord(
                id: "2", name: "Pull", date: calendar.date(byAdding: .day, value: 1, to: weekStart)!,
                duration: 45, exerciseNames: ["Barbell Row", "Pull-Up"], isComplete: true
            ),
        ]
        let summary = PreferenceLearner.generateWeeklySummary(
            workouts: workouts,
            weekStart: weekStart,
            profile: CoachProfile()
        )
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.workoutsCompleted, 2)
        XCTAssertEqual(summary?.totalMinutes, 105)
        XCTAssertFalse(summary!.muscleGroupsHit.isEmpty)
    }

    func testGenerateWeeklySummary_NoWorkouts_ReturnsNil() {
        let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: -10, to: Date())!
        let summary = PreferenceLearner.generateWeeklySummary(
            workouts: [],
            weekStart: weekStart,
            profile: CoachProfile()
        )
        XCTAssertNil(summary)
    }

    // MARK: - Empty Input

    func testLearn_EmptyInput_ReturnsDefaults() {
        let profile = PreferenceLearner.learn(
            existingProfile: CoachProfile(),
            workouts: []
        )
        XCTAssertEqual(profile.totalWorkoutsObserved, 0)
        XCTAssertTrue(profile.favoriteExercises.isEmpty)
        XCTAssertTrue(profile.avoidedExercises.isEmpty)
    }
}
