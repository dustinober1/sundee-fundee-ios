import FoundationModels

@Generable
struct AIWorkoutOutput: Sendable {
    @Guide(description: "Short motivational coaching note for the workout")
    var coachingSummary: String

    @Guide(description: "List of exercises for the workout")
    var exercises: [AIExerciseOutput]
}

@Generable
struct AIExerciseOutput: Sendable {
    @Guide(description: "Exercise name, e.g. Barbell Back Squat")
    var name: String

    @Guide(description: "Number of sets, typically 3-5")
    var sets: Int

    @Guide(description: "Exact number of reps as a single integer like 8 or 12. Never use ranges. Use 0 for AMRAP.")
    var reps: Int

    @Guide(description: "True if this exercise uses no equipment")
    var bodyweightOnly: Bool

    @Guide(description: "Optional coaching note for form or technique")
    var notes: String?
}
