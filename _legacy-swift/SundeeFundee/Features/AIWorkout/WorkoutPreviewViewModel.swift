import Foundation

@MainActor
@Observable
final class WorkoutPreviewViewModel {
    var workout: GeneratedWorkout
    var expandedExerciseID: String?
    var isRegenerating = false
    var showCoachingSummary = false

    private let aiService: any AIWorkoutServiceProtocol

    init(
        workout: GeneratedWorkout,
        aiService: any AIWorkoutServiceProtocol
    ) {
        self.workout = workout
        self.aiService = aiService
    }

    // MARK: - Edit Operations

    func updateWeight(_ weight: Double, forExerciseID id: String) {
        guard let index = workout.exercises.firstIndex(where: { $0.id == id }) else { return }
        workout.exercises[index].weightLb = weight
    }

    func updateReps(_ reps: String, forExerciseID id: String) {
        guard let index = workout.exercises.firstIndex(where: { $0.id == id }) else { return }
        workout.exercises[index].reps = reps
    }

    func updateSets(_ sets: Int, forExerciseID id: String) {
        guard let index = workout.exercises.firstIndex(where: { $0.id == id }) else { return }
        workout.exercises[index].sets = max(1, sets)
    }

    func removeExercise(at offsets: IndexSet) {
        workout.exercises.remove(atOffsets: offsets)
    }

    func removeExercise(id: String) {
        workout.exercises.removeAll { $0.id == id }
    }

    func moveExercise(from source: IndexSet, to destination: Int) {
        workout.exercises.move(fromOffsets: source, toOffset: destination)
    }

    func addExercise(_ exercise: GeneratedExercise) {
        workout.exercises.append(exercise)
    }

    // MARK: - Favorite

    func toggleFavorite(userID: String) async {
        workout.isFavorite.toggle()
        try? await aiService.toggleFavorite(workoutID: workout.id, isFavorite: workout.isFavorite)
    }

    // MARK: - Toggle expanded

    func toggleExpanded(exerciseID: String) {
        if expandedExerciseID == exerciseID {
            expandedExerciseID = nil
        } else {
            expandedExerciseID = exerciseID
        }
    }

    // MARK: - Display Helpers

    static func exerciseSummary(_ exercise: GeneratedExercise, weightUnit: WeightUnit = .pounds) -> String {
        var parts = ["\(exercise.sets) x \(exercise.reps)"]
        if let weight = exercise.weightLb, weight > 0 {
            let kg = weight / WeightUnitConversion.poundsPerKilogram
            let displayed = WeightUnitConversion.format(kilograms: kg, unit: weightUnit, maximumFractionDigits: 1)
            parts.append("\(displayed) \(weightUnit.symbol)")
        }
        return parts.joined(separator: " @ ")
    }

    static func restLabel(_ minutes: Double?) -> String? {
        guard let minutes, minutes > 0 else { return nil }
        if minutes < 1 {
            return "\(Int(minutes * 60))s rest"
        }
        let formatted = minutes.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(minutes)) : String(minutes)
        return "\(formatted)min rest"
    }
}
