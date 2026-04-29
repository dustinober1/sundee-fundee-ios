import Foundation

// MARK: - The First Margarita: 8-Week Strength Program
//
// A featured, hand-crafted advanced strength program focused on developing
// raw strength in power lifts (Squat, Bench, Deadlift) and foundational
// Olympic lifts. Three phases: Accumulation (Weeks 1-4), Intensification
// (Weeks 5-7), Deload & Testing (Week 8).

/// Generate the complete First Margarita program with all 24 hand-crafted sessions.
func generateFirstMargaritaProgram() -> GeneratedProgram {
    let phases: [GeneratedProgramPhase] = [
        GeneratedProgramPhase(
            id: "accumulation",
            name: "Strength Accumulation",
            goal: "Build work capacity and technical proficiency at moderate intensity (75\u{2013}85% 1RM)",
            weekRange: [1, 4]
        ),
        GeneratedProgramPhase(
            id: "intensification",
            name: "Strength Intensification",
            goal: "Increase intensity and decrease volume to peak strength capacity (85\u{2013}95% 1RM)",
            weekRange: [5, 7]
        ),
        GeneratedProgramPhase(
            id: "deload",
            name: "Deload & Testing",
            goal: "Reduce fatigue and test new maximal lifts",
            weekRange: [8, 8]
        ),
    ]

    return GeneratedProgram(
        id: ProgramTemplate.firstMargarita.stableID,
        name: "The First Margarita",
        category: "Strength",
        description: "Focused on developing raw strength in power lifts (Squat, Bench, Deadlift) and foundational Olympic lifts. Three phases: Accumulation, Intensification, and Deload & Testing.",
        durationWeeks: 8,
        sessionsPerWeek: 3,
        difficulty: "Advanced",
        phases: phases,
        weeks: [
            fmWeek1(), fmWeek2(), fmWeek3(), fmWeek4(),
            fmWeek5(), fmWeek6(), fmWeek7(),
            fmWeek8(),
        ]
    )
}

// MARK: - Helpers

private func fmEx(
    _ name: String, sets: Int, reps: Int,
    pct: Double? = nil, rest: Double = 2.0, bw: Bool = false
) -> GeneratedProgramExercise {
    GeneratedProgramExercise(
        exercise: name, sets: .fixed(value: sets), reps: .fixed(value: reps),
        percent1RM: pct, restMinutes: rest, bodyweightOnly: bw
    )
}

private func fmSession(
    _ week: Int, _ day: Int, name: String, focus: String,
    _ exercises: [GeneratedProgramExercise]
) -> GeneratedProgramSession {
    GeneratedProgramSession(
        sessionId: "w\(week)d\(day)", sessionName: name,
        sessionType: "strength", focus: focus, exercises: exercises
    )
}

// MARK: - Phase 1: Strength Accumulation (Weeks 1-4)

private func fmWeek1() -> GeneratedProgramWeek {
    GeneratedProgramWeek(week: 1, phaseId: "accumulation", sessions: [
        // Day 1 - Squat Focus & Pulling Power
        fmSession(1, 1, name: "Day 1 \u{2014} Squat Focus & Pulling Power", focus: "squat", [
            fmEx("Back Squat", sets: 3, reps: 5, pct: 0.78, rest: 3.0),
            fmEx("Romanian Deadlift", sets: 2, reps: 8, rest: 2.5),
            fmEx("Overhead Press", sets: 2, reps: 5, rest: 2.5),
            fmEx("Barbell Row", sets: 2, reps: 8, rest: 1.5),
        ]),
        // Day 2 - Bench Focus & Olympic Pulls
        fmSession(1, 2, name: "Day 2 \u{2014} Bench Focus & Olympic Pulls", focus: "bench", [
            fmEx("Bench Press", sets: 3, reps: 5, pct: 0.77, rest: 3.0),
            fmEx("Snatch Pull", sets: 3, reps: 3, rest: 2.0),
            fmEx("Close Grip Bench Press", sets: 2, reps: 8, rest: 2.0),
            fmEx("Dumbbell Row", sets: 2, reps: 8, rest: 1.5),
        ]),
        // Day 3 - Deadlift Focus & Accessory
        fmSession(1, 3, name: "Day 3 \u{2014} Deadlift Focus & Accessory", focus: "deadlift", [
            fmEx("Deadlift", sets: 4, reps: 5, pct: 0.75, rest: 3.0),
            fmEx("Clean Pull", sets: 3, reps: 3, rest: 2.0),
            fmEx("Pause Squat", sets: 2, reps: 5, rest: 2.5),
            fmEx("Face Pull", sets: 1, reps: 15, rest: 1.0),
        ]),
    ])
}

private func fmWeek2() -> GeneratedProgramWeek {
    GeneratedProgramWeek(week: 2, phaseId: "accumulation", sessions: [
        fmSession(2, 1, name: "Day 1 \u{2014} Squat Focus & Pulling Power", focus: "squat", [
            fmEx("Back Squat", sets: 3, reps: 5, pct: 0.80, rest: 3.0),
            fmEx("Deficit Deadlift", sets: 2, reps: 5, rest: 2.5),
            fmEx("Overhead Press", sets: 2, reps: 5, pct: 0.75, rest: 2.5),
            fmEx("Pendlay Row", sets: 2, reps: 5, rest: 1.5),
        ]),
        fmSession(2, 2, name: "Day 2 \u{2014} Bench Focus & Olympic Pulls", focus: "bench", [
            fmEx("Bench Press", sets: 3, reps: 5, pct: 0.80, rest: 3.0),
            fmEx("Snatch High Pull", sets: 3, reps: 3, rest: 2.0),
            fmEx("Spoto Press", sets: 2, reps: 5, rest: 2.0),
            fmEx("Pull-Up", sets: 2, reps: 8, rest: 2.0, bw: true),
        ]),
        fmSession(2, 3, name: "Day 3 \u{2014} Deadlift Focus & Accessory", focus: "deadlift", [
            fmEx("Deadlift", sets: 4, reps: 5, pct: 0.78, rest: 3.0),
            fmEx("Hang Clean", sets: 3, reps: 3, rest: 2.0),
            fmEx("Front Squat", sets: 2, reps: 5, rest: 2.5),
            fmEx("Nordic Curl", sets: 2, reps: 8, rest: 1.5, bw: true),
        ]),
    ])
}

private func fmWeek3() -> GeneratedProgramWeek {
    GeneratedProgramWeek(week: 3, phaseId: "accumulation", sessions: [
        fmSession(3, 1, name: "Day 1 \u{2014} Squat Focus & Pulling Power", focus: "squat", [
            fmEx("Back Squat", sets: 3, reps: 5, pct: 0.80, rest: 3.0),
            fmEx("Block Pull", sets: 2, reps: 5, rest: 2.5),
            fmEx("Overhead Press", sets: 2, reps: 5, pct: 0.78, rest: 2.5),
            fmEx("Meadows Row", sets: 2, reps: 8, rest: 1.5),
        ]),
        fmSession(3, 2, name: "Day 2 \u{2014} Bench Focus & Olympic Pulls", focus: "bench", [
            fmEx("Bench Press", sets: 3, reps: 5, pct: 0.80, rest: 3.0),
            fmEx("Snatch Pull", sets: 3, reps: 3, rest: 2.0),
            fmEx("Board Press", sets: 2, reps: 5, rest: 2.0),
            fmEx("Incline Dumbbell Press", sets: 2, reps: 8, rest: 1.5),
        ]),
        fmSession(3, 3, name: "Day 3 \u{2014} Deadlift Focus & Accessory", focus: "deadlift", [
            fmEx("Deadlift", sets: 4, reps: 5, pct: 0.82, rest: 3.0),
            fmEx("Jerk Practice", sets: 2, reps: 3, rest: 2.0),
            fmEx("Pause Squat", sets: 3, reps: 5, rest: 2.5),
            fmEx("Farmer's Carry", sets: 2, reps: 1, rest: 1.5),
        ]),
    ])
}

private func fmWeek4() -> GeneratedProgramWeek {
    GeneratedProgramWeek(week: 4, phaseId: "accumulation", sessions: [
        fmSession(4, 1, name: "Day 1 \u{2014} Squat Focus & Pulling Power", focus: "squat", [
            fmEx("Back Squat", sets: 3, reps: 5, pct: 0.82, rest: 3.0),
            fmEx("Romanian Deadlift", sets: 2, reps: 8, rest: 2.5),
            fmEx("Overhead Press", sets: 3, reps: 5, pct: 0.80, rest: 2.5),
            fmEx("Barbell Row", sets: 2, reps: 8, rest: 1.5),
        ]),
        fmSession(4, 2, name: "Day 2 \u{2014} Bench Focus & Olympic Pulls", focus: "bench", [
            fmEx("Bench Press", sets: 3, reps: 5, pct: 0.82, rest: 3.0),
            fmEx("Snatch Pull", sets: 3, reps: 3, rest: 2.0),
            fmEx("Dumbbell Bench Press", sets: 2, reps: 8, rest: 2.0),
            fmEx("Face Pull", sets: 1, reps: 15, rest: 1.0),
        ]),
        fmSession(4, 3, name: "Day 3 \u{2014} Deadlift Focus & Accessory", focus: "deadlift", [
            fmEx("Deadlift", sets: 4, reps: 5, pct: 0.80, rest: 3.0),
            fmEx("Clean Pull", sets: 3, reps: 3, rest: 2.0),
            fmEx("Front Squat", sets: 2, reps: 5, rest: 2.5),
            fmEx("Glute Ham Raise", sets: 2, reps: 8, rest: 1.5),
        ]),
    ])
}

// MARK: - Phase 2: Strength Intensification (Weeks 5-7)

private func fmWeek5() -> GeneratedProgramWeek {
    GeneratedProgramWeek(week: 5, phaseId: "intensification", sessions: [
        fmSession(5, 1, name: "Day 1 \u{2014} Squat Focus & Pulling Power", focus: "squat", [
            fmEx("Back Squat", sets: 4, reps: 3, pct: 0.85, rest: 3.0),
            fmEx("Pause Deadlift", sets: 3, reps: 3, rest: 3.0),
            fmEx("Overhead Press", sets: 3, reps: 3, pct: 0.82, rest: 2.5),
            fmEx("Barbell Row", sets: 2, reps: 5, rest: 2.0),
        ]),
        fmSession(5, 2, name: "Day 2 \u{2014} Bench Focus & Olympic Pulls", focus: "bench", [
            fmEx("Bench Press", sets: 4, reps: 3, pct: 0.85, rest: 3.0),
            fmEx("Snatch Pull", sets: 3, reps: 3, rest: 2.0),
            fmEx("Close Grip Bench Press", sets: 2, reps: 3, rest: 2.5),
            fmEx("Pull-Up", sets: 2, reps: 5, rest: 2.0, bw: true),
        ]),
        fmSession(5, 3, name: "Day 3 \u{2014} Deadlift Focus & Accessory", focus: "deadlift", [
            fmEx("Deadlift", sets: 4, reps: 3, pct: 0.85, rest: 3.0),
            fmEx("Clean", sets: 3, reps: 2, rest: 2.0),
            fmEx("Back Squat", sets: 2, reps: 3, pct: 0.65, rest: 1.5), // Speed work
            fmEx("Ab Rollout", sets: 1, reps: 10, rest: 1.0, bw: true),
        ]),
    ])
}

private func fmWeek6() -> GeneratedProgramWeek {
    GeneratedProgramWeek(week: 6, phaseId: "intensification", sessions: [
        fmSession(6, 1, name: "Day 1 \u{2014} Squat Focus & Pulling Power", focus: "squat", [
            fmEx("Back Squat", sets: 4, reps: 2, pct: 0.88, rest: 3.5),
            fmEx("Deficit Deadlift", sets: 3, reps: 3, rest: 3.0),
            fmEx("Overhead Press", sets: 3, reps: 3, pct: 0.85, rest: 2.5),
            fmEx("Pendlay Row", sets: 2, reps: 5, rest: 2.0),
        ]),
        fmSession(6, 2, name: "Day 2 \u{2014} Bench Focus & Olympic Pulls", focus: "bench", [
            fmEx("Bench Press", sets: 4, reps: 2, pct: 0.88, rest: 3.5),
            fmEx("Snatch High Pull", sets: 3, reps: 3, rest: 2.0),
            fmEx("Spoto Press", sets: 3, reps: 3, rest: 2.5),
            fmEx("Dumbbell Row", sets: 2, reps: 5, rest: 2.0),
        ]),
        fmSession(6, 3, name: "Day 3 \u{2014} Deadlift Focus & Accessory", focus: "deadlift", [
            fmEx("Deadlift", sets: 5, reps: 2, pct: 0.88, rest: 3.5),
            fmEx("Clean Pull", sets: 3, reps: 3, rest: 2.0),
            fmEx("Pause Squat", sets: 3, reps: 2, rest: 3.0),
            fmEx("Face Pull", sets: 1, reps: 15, rest: 1.0),
        ]),
    ])
}

private func fmWeek7() -> GeneratedProgramWeek {
    GeneratedProgramWeek(week: 7, phaseId: "intensification", sessions: [
        fmSession(7, 1, name: "Day 1 \u{2014} Squat Focus & Pulling Power", focus: "squat", [
            fmEx("Back Squat", sets: 4, reps: 2, pct: 0.90, rest: 3.5),
            fmEx("Romanian Deadlift", sets: 3, reps: 5, rest: 2.5),
            fmEx("Overhead Press", sets: 3, reps: 3, pct: 0.87, rest: 2.5),
            fmEx("Barbell Row", sets: 2, reps: 5, rest: 2.0),
        ]),
        fmSession(7, 2, name: "Day 2 \u{2014} Bench Focus & Olympic Pulls", focus: "bench", [
            fmEx("Bench Press", sets: 4, reps: 2, pct: 0.90, rest: 3.5),
            fmEx("Snatch Pull", sets: 3, reps: 3, rest: 2.0),
            fmEx("Board Press", sets: 3, reps: 3, rest: 2.5),
            fmEx("Pull-Up", sets: 2, reps: 5, rest: 2.0, bw: true),
        ]),
        fmSession(7, 3, name: "Day 3 \u{2014} Deadlift Focus & Accessory", focus: "deadlift", [
            fmEx("Deadlift", sets: 5, reps: 2, pct: 0.90, rest: 3.5),
            fmEx("Hang Clean", sets: 3, reps: 1, rest: 2.5),
            fmEx("Front Squat", sets: 3, reps: 3, rest: 2.5),
            fmEx("Grip Work", sets: 2, reps: 1, rest: 1.5),
        ]),
    ])
}

// MARK: - Phase 3: Deload & Testing (Week 8)

private func fmWeek8() -> GeneratedProgramWeek {
    GeneratedProgramWeek(week: 8, phaseId: "deload", sessions: [
        // Day 1 - Light Squat & Technique
        fmSession(8, 1, name: "Day 1 \u{2014} Light Squat & Technique", focus: "squat", [
            fmEx("Back Squat", sets: 2, reps: 5, pct: 0.60, rest: 2.0),
            fmEx("Romanian Deadlift", sets: 2, reps: 8, rest: 2.0),
            fmEx("Overhead Press", sets: 2, reps: 5, pct: 0.55, rest: 2.0),
            fmEx("Face Pull", sets: 1, reps: 15, rest: 1.0),
        ]),
        // Day 2 - Light Bench & Technique
        fmSession(8, 2, name: "Day 2 \u{2014} Light Bench & Technique", focus: "bench", [
            fmEx("Bench Press", sets: 2, reps: 5, pct: 0.60, rest: 2.0),
            fmEx("Snatch Pull", sets: 2, reps: 3, rest: 2.0),
            fmEx("Close Grip Bench Press", sets: 2, reps: 8, rest: 2.0),
            fmEx("Band Pull-Apart", sets: 1, reps: 15, rest: 1.0, bw: true),
        ]),
        // Day 3 - Testing Day (Max Effort)
        fmSession(8, 3, name: "Day 3 \u{2014} Testing Day (Max Effort)", focus: "testing", [
            fmEx("Back Squat", sets: 5, reps: 1, rest: 4.0),
            fmEx("Bench Press", sets: 5, reps: 1, rest: 4.0),
            fmEx("Deadlift", sets: 6, reps: 1, rest: 4.0),
        ]),
    ])
}
