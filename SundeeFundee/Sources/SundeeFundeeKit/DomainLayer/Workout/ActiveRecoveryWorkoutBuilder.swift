import Foundation

public enum ActiveRecoveryWorkoutBuilder {
    public static func build(
        equipment: EquipmentAccess,
        cyclePhase: CyclePhase?,
        date: Date = Date(),
        name: String = "Active Recovery Session"
    ) -> Workout {
        let exerciseNames = exercises(for: equipment, cyclePhase: cyclePhase)
        let exercises: [Exercise] = exerciseNames.map { item in
            let setCount = item.isMobility ? 2 : 3
            let reps = item.isMobility ? 10 : 12
            return Exercise(
                id: UUID().uuidString,
                name: item.name,
                category: item.isMobility ? .warmup : .accessory,
                bodyweight: item.bodyweightOnly ? 1.0 : 0.0,
                targetSets: (0..<setCount).map { _ in
                    ExerciseSet(
                        reps: reps,
                        prescribedWeight: 0,
                        type: .fixed
                    )
                },
                notes: "Active recovery pace. Stop each set well before failure.",
                restMinutes: 1.0
            )
        }

        return Workout(
            date: date,
            name: name,
            exercises: exercises
        )
    }

    private static func exercises(
        for equipment: EquipmentAccess,
        cyclePhase: CyclePhase?
    ) -> [(name: String, isMobility: Bool, bodyweightOnly: Bool)] {
        var base: [(String, Bool, Bool)] = [
            ("Cat-Cow", true, true),
            ("Bird Dog", true, true),
            ("Glute Bridge", false, true),
            ("Plank Hold", true, true)
        ]

        switch equipment {
        case .resistanceBands:
            base.append(("Band Pull-Apart", false, false))
        case .homeDumbbells:
            base.append(("Dumbbell Row", false, false))
        case .kettlebellOnly:
            base.append(("Kettlebell Swing", false, false))
        case .fullGym:
            base.append(("Cable Row", false, false))
        case .bodyweightOnly, .outdoor:
            base.append(("Air Squat", false, true))
        }

        if cyclePhase == .menstrual || cyclePhase == .luteal {
            base = base.map { exercise in
                if exercise.0.contains("Swing") || exercise.0.contains("Squat") {
                    return ("Walking", true, true)
                }
                return exercise
            }
        }

        var unique = Set<String>()
        return base.filter { unique.insert($0.0).inserted }.prefix(5).map { $0 }
    }
}
