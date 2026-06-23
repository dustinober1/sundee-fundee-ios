import Foundation

public struct WarmupRequest: Sendable, Equatable {
    public let workout: Workout
    public let cyclePhase: CyclePhase?
    public let painLogs: [DailyPainLog]
    public let maxMinutes: Int

    public init(
        workout: Workout,
        cyclePhase: CyclePhase?,
        painLogs: [DailyPainLog],
        maxMinutes: Int
    ) {
        self.workout = workout
        self.cyclePhase = cyclePhase
        self.painLogs = painLogs
        self.maxMinutes = maxMinutes
    }

    public static func == (lhs: WarmupRequest, rhs: WarmupRequest) -> Bool {
        lhs.workout == rhs.workout
            && lhs.cyclePhase == rhs.cyclePhase
            && lhs.painLogs.warmupComparableValue == rhs.painLogs.warmupComparableValue
            && lhs.maxMinutes == rhs.maxMinutes
    }
}

public struct WarmupBlock: Sendable, Equatable {
    public let title: String
    public let estimatedMinutes: Int
    public let exercises: [Exercise]
    public let reasons: [String]

    public init(
        title: String,
        estimatedMinutes: Int,
        exercises: [Exercise],
        reasons: [String]
    ) {
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.exercises = exercises
        self.reasons = reasons
    }
}

public enum WarmupBuilder {
    public static func build(request: WarmupRequest) -> WarmupBlock? {
        guard request.maxMinutes > 0 else { return nil }
        guard !request.workout.exercises.contains(where: { $0.category == .warmup }) else { return nil }
        guard let firstWorkingExercise = request.workout.exercises.first(where: { exercise in
            exercise.category != .warmup && exercise.category != .cooldown
        }) else {
            return nil
        }

        let highPain = request.painLogs.contains { $0.intensity >= 6 }
        let lowRecovery = highPain || request.cyclePhase == .menstrual || request.cyclePhase == .luteal
        let kneePain = hasActivePain(in: "knee", painLogs: request.painLogs)
        let movement = movementPattern(for: firstWorkingExercise)
        let minuteCap = lowRecovery ? min(request.maxMinutes, 5) : request.maxMinutes
        let plan = exercises(
            movement: movement,
            lowRecovery: lowRecovery,
            kneePain: kneePain
        )
        let trimmedPlan = Array(plan.prefix(max(1, minuteCap)))
        guard !trimmedPlan.isEmpty else { return nil }

        return WarmupBlock(
            title: title(for: movement),
            estimatedMinutes: min(minuteCap, trimmedPlan.count),
            exercises: trimmedPlan,
            reasons: reasons(
                movement: movement,
                lowRecovery: lowRecovery,
                kneePain: kneePain,
                cyclePhase: request.cyclePhase
            )
        )
    }

    private static func movementPattern(for exercise: Exercise) -> WarmupMovementPattern {
        let name = exercise.name.lowercased()
        if name.contains("squat") || name.contains("thruster") || name.contains("wall ball") {
            return .squat
        }
        if name.contains("deadlift") || name.contains("hinge") || name.contains("swing") {
            return .hinge
        }
        if name.contains("press") || name.contains("bench") || name.contains("push") {
            return .press
        }
        if name.contains("pull") || name.contains("row") || name.contains("chin") {
            return .pull
        }
        return .general
    }

    private static func exercises(
        movement: WarmupMovementPattern,
        lowRecovery: Bool,
        kneePain: Bool
    ) -> [Exercise] {
        switch movement {
        case .squat:
            return [
                makeExercise(id: "warmup-hip-prep", name: "Hip Prep", reps: lowRecovery ? 6 : 8),
                makeExercise(id: "warmup-ankle-prep", name: "Ankle Prep", reps: lowRecovery ? 6 : 8),
                makeExercise(id: "warmup-light-squat-pattern", name: "Light Squat Pattern", reps: lowRecovery ? 5 : 8)
            ]
        case .hinge:
            return [
                makeExercise(id: "warmup-hip-hinge-prep", name: "Hip Hinge Prep", reps: lowRecovery ? 6 : 8),
                makeExercise(id: "warmup-hamstring-sweep", name: "Hamstring Sweep", reps: lowRecovery ? 6 : 8),
                makeExercise(id: "warmup-light-good-morning", name: "Light Good Morning", reps: lowRecovery ? 5 : 8)
            ]
        case .press:
            return [
                makeExercise(id: "warmup-shoulder-circles", name: "Shoulder Circles", reps: lowRecovery ? 6 : 8),
                makeExercise(id: "warmup-scapular-push-up", name: "Scapular Push-Up", reps: lowRecovery ? 5 : 8),
                makeExercise(id: "warmup-light-press-pattern", name: "Light Press Pattern", reps: lowRecovery ? 5 : 8)
            ]
        case .pull:
            return [
                makeExercise(id: "warmup-band-pull-apart", name: "Band Pull-Apart", reps: lowRecovery ? 6 : 10),
                makeExercise(id: "warmup-scapular-row", name: "Scapular Row", reps: lowRecovery ? 6 : 8),
                makeExercise(id: "warmup-light-pull-pattern", name: "Light Pull Pattern", reps: lowRecovery ? 5 : 8)
            ]
        case .general:
            var prep = [
                makeExercise(id: "warmup-breathing-reset", name: "Breathing Reset", reps: 5),
                makeExercise(id: "warmup-joint-prep", name: "Joint Prep", reps: lowRecovery ? 6 : 8)
            ]
            if !kneePain && !lowRecovery {
                prep.append(makeExercise(id: "warmup-light-pogo", name: "Light Pogo Prep", reps: 8))
            }
            return prep
        }
    }

    private static func makeExercise(id: String, name: String, reps: Int) -> Exercise {
        Exercise(
            id: id,
            name: name,
            category: .warmup,
            bodyweight: 1,
            targetSets: [
                ExerciseSet(
                    id: "\(id)-set-1",
                    reps: reps,
                    prescribedWeight: 0,
                    type: .fixed
                )
            ],
            restMinutes: 0
        )
    }

    private static func title(for movement: WarmupMovementPattern) -> String {
        switch movement {
        case .squat:
            return "Squat Warmup"
        case .hinge:
            return "Hinge Warmup"
        case .press:
            return "Press Warmup"
        case .pull:
            return "Pull Warmup"
        case .general:
            return "Ready Warmup"
        }
    }

    private static func reasons(
        movement: WarmupMovementPattern,
        lowRecovery: Bool,
        kneePain: Bool,
        cyclePhase: CyclePhase?
    ) -> [String] {
        var reasons = ["Matches your first \(movement.reasonText) movement."]
        if lowRecovery {
            reasons.append("Today context keeps this easy.")
        }
        if kneePain {
            reasons.append("Knee pain logged, so jump-heavy prep is skipped.")
        }
        if cyclePhase == .menstrual || cyclePhase == .luteal {
            reasons.append("Cycle context favors a gradual start.")
        }
        return reasons
    }

    private static func hasActivePain(in region: String, painLogs: [DailyPainLog]) -> Bool {
        painLogs.contains { log in
            log.intensity >= 4 && log.bodyRegions.contains { $0.engineKey == region }
        }
    }
}

private enum WarmupMovementPattern {
    case squat
    case hinge
    case press
    case pull
    case general

    var reasonText: String {
        switch self {
        case .squat:
            return "squat"
        case .hinge:
            return "hinge"
        case .press:
            return "press"
        case .pull:
            return "pull"
        case .general:
            return "working"
        }
    }
}

private extension Array where Element == DailyPainLog {
    var warmupComparableValue: [String] {
        map { log in
            [
                log.id,
                log.locationIds,
                String(log.intensity),
                log.painType.rawValue,
                String(log.date.timeIntervalSince1970),
                log.notes ?? ""
            ].joined(separator: "|")
        }
    }
}
