import Foundation

public struct ExerciseTechniqueCue: Sendable, Equatable {
    public let exerciseName: String
    public let setupCues: [String]
    public let commonMistakes: [String]
    public let regression: String?
}

public enum ExerciseTechniqueLibrary {
    private static let aliases: [String: String] = [
        "Bench Press": "Flat Barbell Bench Press",
        "Romanian Deadlift": "Romanian Deadlift (No Straps)"
    ]

    private static let cues: [String: ExerciseTechniqueCue] = [
        "Back Squat": ExerciseTechniqueCue(
            exerciseName: "Back Squat",
            setupCues: [
                "Set the bar across upper back, not the neck.",
                "Brace before each rep and keep ribs stacked.",
                "Sit between the heels with knees tracking over toes."
            ],
            commonMistakes: [
                "Rushing the descent before the brace is set.",
                "Letting knees cave inward on the drive up."
            ],
            regression: "Use a goblet squat or box squat to rehearse the pattern."
        ),
        "Goblet Squat": ExerciseTechniqueCue(
            exerciseName: "Goblet Squat",
            setupCues: [
                "Hold the weight close to the chest.",
                "Keep elbows tucked between the knees.",
                "Press the floor away through the whole foot."
            ],
            commonMistakes: [
                "Letting the weight drift forward.",
                "Collapsing the chest at the bottom."
            ],
            regression: "Use bodyweight squats or a lighter dumbbell."
        ),
        "Flat Barbell Bench Press": ExerciseTechniqueCue(
            exerciseName: "Flat Barbell Bench Press",
            setupCues: [
                "Set eyes under the bar before unracking.",
                "Pin shoulder blades back and down.",
                "Touch the bar to the lower chest with forearms vertical."
            ],
            commonMistakes: [
                "Bouncing the bar off the chest.",
                "Letting elbows flare straight out."
            ],
            regression: "Use dumbbell bench press or push-ups."
        ),
        "Dumbbell Bench Press": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Bench Press",
            setupCues: [
                "Start with dumbbells over the chest.",
                "Keep wrists stacked over elbows.",
                "Lower with control until upper arms are near the bench."
            ],
            commonMistakes: [
                "Letting dumbbells drift behind the shoulders.",
                "Losing even pressure through both feet."
            ],
            regression: "Use a lighter pair or a floor press."
        ),
        "Romanian Deadlift (No Straps)": ExerciseTechniqueCue(
            exerciseName: "Romanian Deadlift (No Straps)",
            setupCues: [
                "Start tall with the bar close to thighs.",
                "Hinge hips back while keeping a soft knee bend.",
                "Keep the bar close as hamstrings load."
            ],
            commonMistakes: [
                "Turning the hinge into a squat.",
                "Reaching the bar away from the body."
            ],
            regression: "Use dumbbells and shorten the range."
        ),
        "Dumbbell Row": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Row",
            setupCues: [
                "Brace with a steady torso.",
                "Pull elbow toward the back pocket.",
                "Pause briefly with shoulder blade pulled back."
            ],
            commonMistakes: [
                "Twisting the torso to start the pull.",
                "Shrugging the shoulder toward the ear."
            ],
            regression: "Use a supported row or lighter dumbbell."
        ),
        "Kettlebell Swing": ExerciseTechniqueCue(
            exerciseName: "Kettlebell Swing",
            setupCues: [
                "Hike the bell back like a football snap.",
                "Drive hips forward to float the bell.",
                "Keep arms relaxed and ribs down."
            ],
            commonMistakes: [
                "Squatting the bell instead of hinging.",
                "Lifting with the shoulders."
            ],
            regression: "Practice kettlebell deadlifts before swinging."
        ),
        "Push-Up": ExerciseTechniqueCue(
            exerciseName: "Push-Up",
            setupCues: [
                "Set hands under shoulders.",
                "Keep body in one long line.",
                "Lower chest between the hands with control."
            ],
            commonMistakes: [
                "Letting hips sag or pike up.",
                "Cutting reps short at the top or bottom."
            ],
            regression: "Use an incline push-up at a bench or rack."
        )
    ]

    public static func cue(for exerciseName: String) -> ExerciseTechniqueCue? {
        cues[exerciseName] ?? aliases[exerciseName].flatMap { cues[$0] }
    }
}
