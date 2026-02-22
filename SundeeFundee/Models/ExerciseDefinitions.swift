import Foundation

enum LiftCategory: String, CaseIterable, Identifiable {
    case squats = "Squat Variations"
    case olympic = "Olympic Lifts"
    case bench = "Bench Press Variations"
    case deadlifts = "Deadlifts"
    case overheadPress = "Overhead Pressing"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .squats: return "figure.strengthtraining.traditional"
        case .olympic: return "figure.highintensity.intervaltraining"
        case .bench: return "figure.strengthtraining.functional"
        case .deadlifts: return "figure.core.training"
        case .overheadPress: return "figure.arms.open"
        }
    }
}

struct ExerciseDefinition: Identifiable {
    let id: String
    let name: String
    let category: String
    let liftCategory: LiftCategory
    let muscleGroups: [String]
    let description: String
    let supportsStraps: Bool

    init(
        id: String,
        name: String,
        category: String,
        liftCategory: LiftCategory,
        muscleGroups: [String],
        description: String,
        supportsStraps: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.liftCategory = liftCategory
        self.muscleGroups = muscleGroups
        self.description = description
        self.supportsStraps = supportsStraps
    }
}

enum Exercises {

    // MARK: - Squat Variations

    static let squats: [ExerciseDefinition] = [
        ExerciseDefinition(
            id: "back-squat-high-bar",
            name: "Back Squat (High Bar)",
            category: "squats",
            liftCategory: .squats,
            muscleGroups: ["quadriceps", "glutes", "core"],
            description: "Bar rests on the traps; keeps the torso more upright, heavily targeting the quads"
        ),
        ExerciseDefinition(
            id: "back-squat-low-bar",
            name: "Back Squat (Low Bar)",
            category: "squats",
            liftCategory: .squats,
            muscleGroups: ["glutes", "hamstrings", "quadriceps"],
            description: "Bar rests across the rear delts; recruits the posterior chain to move more weight"
        ),
        ExerciseDefinition(
            id: "front-squat",
            name: "Front Squat",
            category: "squats",
            liftCategory: .squats,
            muscleGroups: ["quadriceps", "core", "upper-back"],
            description: "Bar rests on the front rack; requires massive core stabilization and isolates the quads"
        ),
        ExerciseDefinition(
            id: "overhead-squat",
            name: "Overhead Squat",
            category: "squats",
            liftCategory: .squats,
            muscleGroups: ["quadriceps", "shoulders", "core"],
            description: "Bar locked out overhead with a wide grip while squatting; tests shoulder mobility and balance"
        ),
        ExerciseDefinition(
            id: "box-squat",
            name: "Box Squat",
            category: "squats",
            liftCategory: .squats,
            muscleGroups: ["quadriceps", "glutes", "hamstrings"],
            description: "Squat to a box before exploding up; builds starting strength out of the hole"
        ),
        ExerciseDefinition(
            id: "zercher-squat",
            name: "Zercher Squat",
            category: "squats",
            liftCategory: .squats,
            muscleGroups: ["quadriceps", "glutes", "core", "biceps"],
            description: "Bar held in the crook of the elbows; punishes the core and upper back"
        ),
        ExerciseDefinition(
            id: "bulgarian-split-squat",
            name: "Bulgarian Split Squat",
            category: "squats",
            liftCategory: .squats,
            muscleGroups: ["quadriceps", "glutes", "core"],
            description: "Unilateral squat with the rear foot elevated on a bench"
        ),
        ExerciseDefinition(
            id: "goblet-squat",
            name: "Goblet Squat",
            category: "squats",
            liftCategory: .squats,
            muscleGroups: ["quadriceps", "glutes", "core"],
            description: "Dumbbell or kettlebell held at the chest; great for grooving movement patterns"
        ),
        ExerciseDefinition(
            id: "pause-squat",
            name: "Pause Squat",
            category: "squats",
            liftCategory: .squats,
            muscleGroups: ["quadriceps", "glutes", "core"],
            description: "Holding the bottom position for 2–3 seconds to eliminate the stretch reflex"
        ),
    ]

    // MARK: - Olympic Lifts — Clean Family

    static let cleans: [ExerciseDefinition] = [
        ExerciseDefinition(
            id: "squat-clean",
            name: "Squat Clean",
            category: "olympic-clean",
            liftCategory: .olympic,
            muscleGroups: ["quadriceps", "glutes", "traps", "upper-back"],
            description: "Full movement: pulling the bar from the floor and catching it in a deep front squat"
        ),
        ExerciseDefinition(
            id: "power-clean",
            name: "Power Clean",
            category: "olympic-clean",
            liftCategory: .olympic,
            muscleGroups: ["quadriceps", "glutes", "traps", "upper-back"],
            description: "Catching the bar high (above parallel) rather than riding into a squat"
        ),
        ExerciseDefinition(
            id: "hang-clean",
            name: "Hang Clean",
            category: "olympic-clean",
            liftCategory: .olympic,
            muscleGroups: ["quadriceps", "glutes", "traps"],
            description: "Starting from the knees or mid-thigh; focuses on the explosive second pull"
        ),
        ExerciseDefinition(
            id: "block-clean",
            name: "Block Clean",
            category: "olympic-clean",
            liftCategory: .olympic,
            muscleGroups: ["quadriceps", "glutes", "traps"],
            description: "Pulling from elevated blocks to focus on specific phases of the pull"
        ),
        ExerciseDefinition(
            id: "muscle-clean",
            name: "Muscle Clean",
            category: "olympic-clean",
            liftCategory: .olympic,
            muscleGroups: ["traps", "shoulders", "biceps"],
            description: "Pulling and turning the bar over strictly without re-bending the knees"
        ),
    ]

    // MARK: - Olympic Lifts — Jerk Family

    static let jerks: [ExerciseDefinition] = [
        ExerciseDefinition(
            id: "split-jerk",
            name: "Split Jerk",
            category: "olympic-jerk",
            liftCategory: .olympic,
            muscleGroups: ["shoulders", "triceps", "quadriceps", "core"],
            description: "Driving the bar overhead while splitting the legs forward and backward"
        ),
        ExerciseDefinition(
            id: "push-jerk",
            name: "Push Jerk",
            category: "olympic-jerk",
            liftCategory: .olympic,
            muscleGroups: ["shoulders", "triceps", "quadriceps"],
            description: "Driving overhead and catching with a slight knee bend, feet parallel"
        ),
        ExerciseDefinition(
            id: "squat-jerk",
            name: "Squat Jerk",
            category: "olympic-jerk",
            liftCategory: .olympic,
            muscleGroups: ["shoulders", "triceps", "quadriceps", "core"],
            description: "Dropping into a full overhead squat to catch the bar; requires elite mobility"
        ),
    ]

    // MARK: - Olympic Lifts — Snatch Family

    static let snatches: [ExerciseDefinition] = [
        ExerciseDefinition(
            id: "squat-snatch",
            name: "Squat Snatch",
            category: "olympic-snatch",
            liftCategory: .olympic,
            muscleGroups: ["quadriceps", "shoulders", "traps", "core"],
            description: "Pulling the bar from the floor and catching it overhead in a full deep squat"
        ),
        ExerciseDefinition(
            id: "power-snatch",
            name: "Power Snatch",
            category: "olympic-snatch",
            liftCategory: .olympic,
            muscleGroups: ["quadriceps", "shoulders", "traps"],
            description: "Catching the bar overhead without dipping below parallel"
        ),
        ExerciseDefinition(
            id: "hang-snatch",
            name: "Hang Snatch",
            category: "olympic-snatch",
            liftCategory: .olympic,
            muscleGroups: ["quadriceps", "shoulders", "traps"],
            description: "Starting from the hang position to train the second pull and turnover"
        ),
        ExerciseDefinition(
            id: "block-snatch",
            name: "Block Snatch",
            category: "olympic-snatch",
            liftCategory: .olympic,
            muscleGroups: ["quadriceps", "shoulders", "traps"],
            description: "Starting from blocks to train the second pull and turnover"
        ),
    ]

    // MARK: - Bench Press Variations

    static let benchPress: [ExerciseDefinition] = [
        ExerciseDefinition(
            id: "flat-bench-press",
            name: "Flat Barbell Bench Press",
            category: "bench",
            liftCategory: .bench,
            muscleGroups: ["chest", "triceps", "shoulders"],
            description: "The standard chest builder"
        ),
        ExerciseDefinition(
            id: "incline-bench-press",
            name: "Incline Bench Press",
            category: "bench",
            liftCategory: .bench,
            muscleGroups: ["upper-chest", "shoulders", "triceps"],
            description: "30-45 degree angle; shifts focus to the upper pectorals and anterior deltoids"
        ),
        ExerciseDefinition(
            id: "decline-bench-press",
            name: "Decline Bench Press",
            category: "bench",
            liftCategory: .bench,
            muscleGroups: ["lower-chest", "triceps"],
            description: "Bench angled downward; targets the lower chest with reduced range of motion"
        ),
        ExerciseDefinition(
            id: "close-grip-bench-press",
            name: "Close-Grip Bench Press",
            category: "bench",
            liftCategory: .bench,
            muscleGroups: ["triceps", "chest", "shoulders"],
            description: "Hands at shoulder width or narrower; heavily shifts load onto the triceps"
        ),
        ExerciseDefinition(
            id: "wide-grip-bench-press",
            name: "Wide-Grip Bench Press",
            category: "bench",
            liftCategory: .bench,
            muscleGroups: ["chest", "shoulders"],
            description: "Hands outside standard grip; increases chest stretch"
        ),
        ExerciseDefinition(
            id: "floor-press",
            name: "Floor Press",
            category: "bench",
            liftCategory: .bench,
            muscleGroups: ["triceps", "chest"],
            description: "Pressing from the floor; stops elbows at 90° to build triceps lockout strength"
        ),
        ExerciseDefinition(
            id: "spoto-press",
            name: "Spoto Press",
            category: "bench",
            liftCategory: .bench,
            muscleGroups: ["chest", "triceps"],
            description: "Pausing the bar 1-2 inches above the chest before pressing to build tension"
        ),
        ExerciseDefinition(
            id: "board-press",
            name: "Board Press",
            category: "bench",
            liftCategory: .bench,
            muscleGroups: ["triceps", "chest"],
            description: "Lowering to a board on the chest to target lockout sticking points"
        ),
    ]

    // MARK: - Deadlifts

    static let deadlifts: [ExerciseDefinition] = [
        ExerciseDefinition(
            id: "conventional-deadlift",
            name: "Conventional Deadlift",
            category: "deadlifts",
            liftCategory: .deadlifts,
            muscleGroups: ["hamstrings", "glutes", "lower-back", "traps"],
            description: "Standard stance, hands outside knees; balances load across the posterior chain",
            supportsStraps: true
        ),
        ExerciseDefinition(
            id: "sumo-deadlift",
            name: "Sumo Deadlift",
            category: "deadlifts",
            liftCategory: .deadlifts,
            muscleGroups: ["quadriceps", "glutes", "hamstrings"],
            description: "Ultra-wide stance, hands inside knees; shortens ROM and shifts load to hips and quads",
            supportsStraps: true
        ),
        ExerciseDefinition(
            id: "romanian-deadlift",
            name: "Romanian Deadlift (RDL)",
            category: "deadlifts",
            liftCategory: .deadlifts,
            muscleGroups: ["hamstrings", "glutes"],
            description: "Starting from the top, hinging at the hips with slightly bent knees",
            supportsStraps: true
        ),
        ExerciseDefinition(
            id: "stiff-legged-deadlift",
            name: "Stiff-Legged Deadlift",
            category: "deadlifts",
            liftCategory: .deadlifts,
            muscleGroups: ["hamstrings", "glutes", "lower-back"],
            description: "Similar to RDL but pulling from the floor with straighter legs",
            supportsStraps: true
        ),
        ExerciseDefinition(
            id: "deficit-deadlift",
            name: "Deficit Deadlift",
            category: "deadlifts",
            liftCategory: .deadlifts,
            muscleGroups: ["hamstrings", "glutes", "quadriceps", "lower-back"],
            description: "Standing on a plate or block to increase ROM and build strength off the floor",
            supportsStraps: true
        ),
        ExerciseDefinition(
            id: "trap-bar-deadlift",
            name: "Trap Bar (Hex Bar) Deadlift",
            category: "deadlifts",
            liftCategory: .deadlifts,
            muscleGroups: ["quadriceps", "glutes", "hamstrings", "traps"],
            description: "Hexagonal bar keeps weight centered; a hybrid between a squat and a hinge",
            supportsStraps: true
        ),
    ]

    // MARK: - Overhead Pressing

    static let overheadPress: [ExerciseDefinition] = [
        ExerciseDefinition(
            id: "strict-press",
            name: "Strict Press (Military Press)",
            category: "overhead-press",
            liftCategory: .overheadPress,
            muscleGroups: ["shoulders", "triceps"],
            description: "Standing vertical press with zero leg drive; pure shoulder and triceps strength"
        ),
        ExerciseDefinition(
            id: "push-press",
            name: "Push Press",
            category: "overhead-press",
            liftCategory: .overheadPress,
            muscleGroups: ["shoulders", "triceps", "quadriceps"],
            description: "Using a slight knee dip and drive to launch the weight up, finishing with the arms"
        ),
        ExerciseDefinition(
            id: "z-press",
            name: "Z-Press",
            category: "overhead-press",
            liftCategory: .overheadPress,
            muscleGroups: ["shoulders", "triceps", "core"],
            description: "Pressing while seated on the floor with legs straight; removes all lower body stabilization"
        ),
    ]

    // MARK: - All & Lookup

    static let all: [ExerciseDefinition] =
        squats + cleans + jerks + snatches + benchPress + deadlifts + overheadPress

    static var byCategory: [LiftCategory: [ExerciseDefinition]] {
        Dictionary(grouping: all, by: { $0.liftCategory })
    }

    static func find(byId id: String) -> ExerciseDefinition? {
        all.first { $0.id == id }
    }
}
