import Foundation

struct ExerciseDefinition: Identifiable {
    let id: String
    let name: String
    let category: String
    let muscleGroups: [String]
    let description: String
}

enum Exercises {
    static let all: [ExerciseDefinition] = [
        ExerciseDefinition(
            id: "back-squat",
            name: "Back Squat",
            category: "back-squat",
            muscleGroups: ["quadriceps", "glutes", "core"],
            description: "Barbell squat with bar on upper back"
        ),
        ExerciseDefinition(
            id: "front-squat",
            name: "Front Squat",
            category: "front-squat",
            muscleGroups: ["quadriceps", "core", "upper-back"],
            description: "Barbell squat with front rack position"
        ),
        ExerciseDefinition(
            id: "pause-squat",
            name: "Pause Squat",
            category: "back-squat",
            muscleGroups: ["quadriceps", "glutes", "core"],
            description: "Back squat with a 2-3 second pause at the bottom"
        ),
        ExerciseDefinition(
            id: "zombie-squat",
            name: "Zombie Squat",
            category: "back-squat",
            muscleGroups: ["quadriceps", "core", "upper-back"],
            description: "Front squat with arms extended forward, teaches upright torso"
        ),
        ExerciseDefinition(
            id: "zercher-squat",
            name: "Zercher Squat",
            category: "back-squat",
            muscleGroups: ["quadriceps", "glutes", "core", "biceps"],
            description: "Squat with bar held in crook of elbows"
        ),
        ExerciseDefinition(
            id: "bulgarian-split-squat",
            name: "Bulgarian Split Squat",
            category: "back-squat",
            muscleGroups: ["quadriceps", "glutes", "core"],
            description: "Single-leg squat with rear foot elevated on bench"
        ),
        ExerciseDefinition(
            id: "front-rack-hold",
            name: "Front Rack Hold",
            category: "back-squat",
            muscleGroups: ["core", "upper-back", "shoulders"],
            description: "Isometric hold in front rack position, time-based"
        ),
    ]

    static func find(byId id: String) -> ExerciseDefinition? {
        all.first { $0.id == id }
    }
}
