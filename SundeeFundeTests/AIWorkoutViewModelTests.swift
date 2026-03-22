import Testing
import Foundation
@testable import SundeeFundee

// MARK: - Test-Only Stub

private final class OfflineAIWorkoutService: AIWorkoutServiceProtocol, @unchecked Sendable {
    private var generatedWorkouts: [GeneratedWorkout] = []

    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout {
        let workout = OfflineWorkoutGenerator.generate(from: context)
        generatedWorkouts.append(workout)
        return workout
    }
    func fetchHistory(userID: String) async throws -> [GeneratedWorkout] { generatedWorkouts }
    func toggleFavorite(workoutID: String, isFavorite: Bool) async throws {
        if let idx = generatedWorkouts.firstIndex(where: { $0.id == workoutID }) {
            generatedWorkouts[idx].isFavorite = isFavorite
        }
    }
    func fetchFavorites(userID: String) async throws -> [GeneratedWorkout] {
        generatedWorkouts.filter(\.isFavorite)
    }
}

// MARK: - WorkoutPreviewViewModel Tests

@Suite("WorkoutPreviewViewModel")
@MainActor
struct WorkoutPreviewViewModelTests {

    private func makeSampleWorkout() -> GeneratedWorkout {
        GeneratedWorkout(
            id: "test-workout",
            coachingSummary: "Test session",
            exercises: [
                GeneratedExercise(id: "ex-1", name: "Back Squat", sets: 4, reps: "5", weightKg: 100, restMinutes: 3.0),
                GeneratedExercise(id: "ex-2", name: "Bench Press", sets: 3, reps: "8", weightKg: 80, restMinutes: 2.0),
                GeneratedExercise(id: "ex-3", name: "Pull-Up", sets: 3, reps: "AMRAP", bodyweightOnly: true),
            ],
            questionnaire: QuestionnaireAnswers(
                timeMinutes: 45, focus: .fullBody, energyLevel: .medium, equipment: .fullGym
            )
        )
    }

    @Test @MainActor func updateWeight() {
        let vm = WorkoutPreviewViewModel(workout: makeSampleWorkout(), aiService: OfflineAIWorkoutService())
        vm.updateWeight(110, forExerciseID: "ex-1")
        #expect(vm.workout.exercises.first { $0.id == "ex-1" }?.weightKg == 110)
    }

    @Test @MainActor func updateWeightNonExistentID() {
        let vm = WorkoutPreviewViewModel(workout: makeSampleWorkout(), aiService: OfflineAIWorkoutService())
        vm.updateWeight(110, forExerciseID: "nonexistent")
        // Should not crash, no change
        #expect(vm.workout.exercises.first?.weightKg == 100)
    }

    @Test @MainActor func updateReps() {
        let vm = WorkoutPreviewViewModel(workout: makeSampleWorkout(), aiService: OfflineAIWorkoutService())
        vm.updateReps("6-8", forExerciseID: "ex-2")
        #expect(vm.workout.exercises.first { $0.id == "ex-2" }?.reps == "6-8")
    }

    @Test @MainActor func updateSets() {
        let vm = WorkoutPreviewViewModel(workout: makeSampleWorkout(), aiService: OfflineAIWorkoutService())
        vm.updateSets(5, forExerciseID: "ex-1")
        #expect(vm.workout.exercises.first { $0.id == "ex-1" }?.sets == 5)
    }

    @Test @MainActor func updateSetsMinimumIsOne() {
        let vm = WorkoutPreviewViewModel(workout: makeSampleWorkout(), aiService: OfflineAIWorkoutService())
        vm.updateSets(0, forExerciseID: "ex-1")
        #expect(vm.workout.exercises.first { $0.id == "ex-1" }?.sets == 1)
    }

    @Test @MainActor func removeExerciseByID() {
        let vm = WorkoutPreviewViewModel(workout: makeSampleWorkout(), aiService: OfflineAIWorkoutService())
        vm.removeExercise(id: "ex-2")
        #expect(vm.workout.exercises.count == 2)
        #expect(!vm.workout.exercises.contains { $0.id == "ex-2" })
    }

    @Test @MainActor func removeExerciseAtOffsets() {
        let vm = WorkoutPreviewViewModel(workout: makeSampleWorkout(), aiService: OfflineAIWorkoutService())
        vm.removeExercise(at: IndexSet(integer: 0))
        #expect(vm.workout.exercises.count == 2)
        #expect(vm.workout.exercises.first?.name == "Bench Press")
    }

    @Test @MainActor func moveExercise() {
        let vm = WorkoutPreviewViewModel(workout: makeSampleWorkout(), aiService: OfflineAIWorkoutService())
        vm.moveExercise(from: IndexSet(integer: 2), to: 0)
        #expect(vm.workout.exercises.first?.name == "Pull-Up")
    }

    @Test @MainActor func addExercise() {
        let vm = WorkoutPreviewViewModel(workout: makeSampleWorkout(), aiService: OfflineAIWorkoutService())
        let newEx = GeneratedExercise(id: "ex-new", name: "Dumbbell Curl", sets: 3, reps: "12")
        vm.addExercise(newEx)
        #expect(vm.workout.exercises.count == 4)
        #expect(vm.workout.exercises.last?.name == "Dumbbell Curl")
    }

    @Test @MainActor func toggleFavorite() async {
        let vm = WorkoutPreviewViewModel(workout: makeSampleWorkout(), aiService: OfflineAIWorkoutService())
        #expect(vm.workout.isFavorite == false)
        await vm.toggleFavorite(userID: "user-1")
        #expect(vm.workout.isFavorite == true)
        await vm.toggleFavorite(userID: "user-1")
        #expect(vm.workout.isFavorite == false)
    }

    @Test @MainActor func toggleExpanded() {
        let vm = WorkoutPreviewViewModel(workout: makeSampleWorkout(), aiService: OfflineAIWorkoutService())
        #expect(vm.expandedExerciseID == nil)
        vm.toggleExpanded(exerciseID: "ex-1")
        #expect(vm.expandedExerciseID == "ex-1")
        vm.toggleExpanded(exerciseID: "ex-1")
        #expect(vm.expandedExerciseID == nil)
        vm.toggleExpanded(exerciseID: "ex-1")
        vm.toggleExpanded(exerciseID: "ex-2")
        #expect(vm.expandedExerciseID == "ex-2")
    }

    @Test func exerciseSummaryWithWeight() {
        let ex = GeneratedExercise(name: "Squat", sets: 4, reps: "5", weightKg: 100)
        let summary = WorkoutPreviewViewModel.exerciseSummary(ex)
        #expect(summary == "4 x 5 @ 100kg")
    }

    @Test func exerciseSummaryBodyweight() {
        let ex = GeneratedExercise(name: "Pull-Up", sets: 3, reps: "AMRAP", bodyweightOnly: true)
        let summary = WorkoutPreviewViewModel.exerciseSummary(ex)
        #expect(summary == "3 x AMRAP")
    }

    @Test func exerciseSummaryZeroWeight() {
        let ex = GeneratedExercise(name: "Test", sets: 3, reps: "10", weightKg: 0)
        let summary = WorkoutPreviewViewModel.exerciseSummary(ex)
        #expect(summary == "3 x 10")
    }

    @Test func restLabelMinutes() {
        #expect(WorkoutPreviewViewModel.restLabel(2.0) == "2min rest")
        #expect(WorkoutPreviewViewModel.restLabel(1.5) == "1.5min rest")
    }

    @Test func restLabelSeconds() {
        #expect(WorkoutPreviewViewModel.restLabel(0.5) == "30s rest")
    }

    @Test func restLabelNil() {
        #expect(WorkoutPreviewViewModel.restLabel(nil) == nil)
    }

    @Test func restLabelZero() {
        #expect(WorkoutPreviewViewModel.restLabel(0) == nil)
    }
}

// MARK: - QuestionnaireViewModel Tests

@Suite("QuestionnaireViewModel")
@MainActor
struct QuestionnaireViewModelTests {

    @Test func defaultValues() {
        let vm = QuestionnaireViewModel(aiService: OfflineAIWorkoutService())
        #expect(vm.timeMinutes == 45)
        #expect(vm.focus == .fullBody)
        #expect(vm.energyLevel == .medium)
        #expect(vm.equipment == .fullGym)
        #expect(vm.isGenerating == false)
        #expect(vm.generatedWorkout == nil)
        #expect(vm.errorMessage == nil)
        #expect(vm.currentPage == 0)
    }

    @Test func canGenerateIsTrue() {
        let vm = QuestionnaireViewModel(aiService: OfflineAIWorkoutService())
        #expect(vm.canGenerate == true)
    }

    @Test func timeOptionsAreSorted() {
        let options = QuestionnaireViewModel.timeOptions
        #expect(options == [30, 45, 60, 75])
    }
}

// MARK: - QuestionnaireView static tests

@Suite("QuestionnaireView Statics")
struct QuestionnaireViewStaticTests {

    @Test func timeLabelNormal() {
        #expect(QuestionnaireView.timeLabel(minutes: 30) == "30")
        #expect(QuestionnaireView.timeLabel(minutes: 45) == "45")
        #expect(QuestionnaireView.timeLabel(minutes: 60) == "60")
    }

    @Test func timeLabelSeventyFivePlus() {
        #expect(QuestionnaireView.timeLabel(minutes: 75) == "75+")
        #expect(QuestionnaireView.timeLabel(minutes: 90) == "75+")
    }
}

// MARK: - WorkoutHistoryView static tests

@Suite("WorkoutHistoryView Statics")
struct WorkoutHistoryViewStaticTests {

    @Test func filterWorkoutsAll() {
        let workouts = [
            GeneratedWorkout(
                coachingSummary: "Upper",
                exercises: [],
                questionnaire: QuestionnaireAnswers(timeMinutes: 45, focus: .upperBody, energyLevel: .medium, equipment: .fullGym)
            ),
            GeneratedWorkout(
                coachingSummary: "Lower",
                exercises: [],
                questionnaire: QuestionnaireAnswers(timeMinutes: 45, focus: .lowerBody, energyLevel: .medium, equipment: .fullGym)
            ),
        ]

        let filtered = WorkoutHistoryView.filterWorkouts(workouts, focus: nil)
        #expect(filtered.count == 2)
    }

    @Test func filterWorkoutsByFocus() {
        let workouts = [
            GeneratedWorkout(
                coachingSummary: "Upper",
                exercises: [],
                questionnaire: QuestionnaireAnswers(timeMinutes: 45, focus: .upperBody, energyLevel: .medium, equipment: .fullGym)
            ),
            GeneratedWorkout(
                coachingSummary: "Lower",
                exercises: [],
                questionnaire: QuestionnaireAnswers(timeMinutes: 45, focus: .lowerBody, energyLevel: .medium, equipment: .fullGym)
            ),
        ]

        let filtered = WorkoutHistoryView.filterWorkouts(workouts, focus: .upperBody)
        #expect(filtered.count == 1)
        #expect(filtered.first?.coachingSummary == "Upper")
    }

    @Test func dateLabelFormats() {
        let date = Date(timeIntervalSince1970: 1000000)
        let label = WorkoutHistoryView.dateLabel(date)
        #expect(!label.isEmpty)
    }
}

// MARK: - OfflineAIWorkoutService Tests

@Suite("OfflineAIWorkoutService")
struct OfflineAIWorkoutServiceTests {

    @Test func generateAndFetchHistory() async throws {
        let service = OfflineAIWorkoutService()
        let context = WorkoutGenerationContext(
            userID: "test-user",
            timeMinutes: 45,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: .fullGym,
            maxes: [],
            recentWorkouts: [],
            cyclePhase: nil,
            readinessTier: nil,
            activeInjuries: [],
            experienceLevel: "beginner",
            primaryGoal: "strength",
            gender: "male",
            weightUnit: "kg"
        )

        let workout = try await service.generateWorkout(context: context)
        #expect(!workout.id.isEmpty)

        let history = try await service.fetchHistory(userID: "user-1")
        #expect(history.count == 1)
        #expect(history.first?.id == workout.id)
    }

    @Test func toggleFavoriteAndFetchFavorites() async throws {
        let service = OfflineAIWorkoutService()
        let context = WorkoutGenerationContext(
            userID: "test-user",
            timeMinutes: 30,
            focus: .upperBody,
            energyLevel: .low,
            equipment: .bodyweightOnly,
            maxes: [],
            recentWorkouts: [],
            cyclePhase: nil,
            readinessTier: nil,
            activeInjuries: [],
            experienceLevel: "beginner",
            primaryGoal: "strength",
            gender: "male",
            weightUnit: "kg"
        )

        let workout = try await service.generateWorkout(context: context)

        var favorites = try await service.fetchFavorites(userID: "user-1")
        #expect(favorites.isEmpty)

        try await service.toggleFavorite(workoutID: workout.id, isFavorite: true)
        favorites = try await service.fetchFavorites(userID: "user-1")
        #expect(favorites.count == 1)

        try await service.toggleFavorite(workoutID: workout.id, isFavorite: false)
        favorites = try await service.fetchFavorites(userID: "user-1")
        #expect(favorites.isEmpty)
    }
}
