import Foundation

public struct QuickWorkoutRequest: Sendable, Equatable {
    public let timeMinutes: Int
    public let focus: WorkoutFocus
    public let energyLevel: EnergyLevel
    public let equipment: EquipmentAccess
    public let todayDecisionKind: TodayTrainingDecisionKind
    public let painLogs: [DailyPainLog]
    public let workoutKind: WorkoutKind

    public init(
        timeMinutes: Int,
        focus: WorkoutFocus,
        energyLevel: EnergyLevel,
        equipment: EquipmentAccess,
        todayDecisionKind: TodayTrainingDecisionKind,
        painLogs: [DailyPainLog],
        workoutKind: WorkoutKind = .standard
    ) {
        self.timeMinutes = timeMinutes
        self.focus = focus
        self.energyLevel = energyLevel
        self.equipment = equipment
        self.todayDecisionKind = todayDecisionKind
        self.painLogs = painLogs
        self.workoutKind = workoutKind
    }

    public static func == (lhs: QuickWorkoutRequest, rhs: QuickWorkoutRequest) -> Bool {
        lhs.timeMinutes == rhs.timeMinutes
            && lhs.focus == rhs.focus
            && lhs.energyLevel == rhs.energyLevel
            && lhs.equipment == rhs.equipment
            && lhs.todayDecisionKind == rhs.todayDecisionKind
            && lhs.painLogs.quickWorkoutComparableValue == rhs.painLogs.quickWorkoutComparableValue
            && lhs.workoutKind == rhs.workoutKind
    }
}

public struct QuickWorkoutResult: Sendable, Equatable {
    public let workout: Workout
    public let estimatedMinutes: Int
    public let reasons: [String]

    public init(workout: Workout, estimatedMinutes: Int, reasons: [String]) {
        self.workout = workout
        self.estimatedMinutes = estimatedMinutes
        self.reasons = reasons
    }
}

public enum QuickWorkoutBuilder {
    public static func build(request: QuickWorkoutRequest) -> QuickWorkoutResult {
        let timeLimit = max(1, request.timeMinutes)
        let lowRecovery = request.todayDecisionKind == .recover
            || request.energyLevel == .low
            || request.painLogs.contains { $0.intensity >= 6 }
        let targetCount = targetExerciseCount(timeMinutes: timeLimit, lowRecovery: lowRecovery)
        let workingSets = initialWorkingSets(timeMinutes: timeLimit, energyLevel: request.energyLevel, lowRecovery: lowRecovery)
        let restMinutes = restMinutes(focus: request.focus, lowRecovery: lowRecovery)

        let selected = selectCandidates(
            request: request,
            targetCount: targetCount,
            lowRecovery: lowRecovery
        )
        var plans = selected.map {
            QuickExercisePlan(candidate: $0, sets: workingSets, restMinutes: restMinutes)
        }
        trimToFit(plans: &plans, timeLimit: timeLimit)

        let estimatedMinutes = estimateMinutes(plans)
        let painAvoidanceApplied = painFilterIsActive(request.painLogs)
            && !plans.isEmpty
            && plans.allSatisfy { isAllowedForPain($0.candidate, painLogs: request.painLogs) }
        let reasons = buildReasons(
            request: request,
            timeLimit: timeLimit,
            estimatedMinutes: estimatedMinutes,
            lowRecovery: lowRecovery,
            painAvoidanceApplied: painAvoidanceApplied
        )
        let exercises = plans.map(makeExercise)

        return QuickWorkoutResult(
            workout: Workout(
                date: Date(),
                name: "Best Next \(timeLimit) Minutes",
                exercises: exercises,
                notes: reasons.joined(separator: " "),
                duration: max(timeLimit, estimatedMinutes),
                kind: request.workoutKind
            ),
            estimatedMinutes: estimatedMinutes,
            reasons: reasons
        )
    }

    private static func targetExerciseCount(timeMinutes: Int, lowRecovery: Bool) -> Int {
        if timeMinutes <= 4 { return 1 }
        if timeMinutes <= 14 { return 2 }
        if lowRecovery { return 2 }
        if timeMinutes >= 25 { return 4 }
        return 3
    }

    private static func initialWorkingSets(
        timeMinutes: Int,
        energyLevel: EnergyLevel,
        lowRecovery: Bool
    ) -> Int {
        if timeMinutes <= 12 { return 1 }
        if lowRecovery { return 2 }

        switch energyLevel {
        case .high:
            return 3
        case .medium, .low:
            return 2
        }
    }

    private static func restMinutes(focus: WorkoutFocus, lowRecovery: Bool) -> Double {
        if lowRecovery { return 1.0 }
        if focus == .conditioning { return 0.75 }
        return 1.25
    }

    private static func selectCandidates(
        request: QuickWorkoutRequest,
        targetCount: Int,
        lowRecovery: Bool
    ) -> [WorkoutExerciseCandidate] {
        let pool = workoutExercisePool(
            focus: request.focus,
            equipment: request.equipment,
            energyLevel: request.energyLevel
        )
        let lowStressPool = lowRecovery ? pool.filter { !isHighStress($0.name) } : pool
        let preferred: [WorkoutExerciseCandidate]
        if painFilterIsActive(request.painLogs) {
            let painFilteredPool = filterForPain(lowStressPool, painLogs: request.painLogs)
            let neutralFallbackPool = filterForPain(
                neutralFallbackCandidates(
                    equipment: request.equipment,
                    energyLevel: request.energyLevel
                ),
                painLogs: request.painLogs
            )

            let painSafePool = orderedUniqueCandidates(painFilteredPool + neutralFallbackPool)
            preferred = painSafePool.isEmpty ? lowStressPool : painSafePool
        } else {
            preferred = lowStressPool
        }

        let uniquePatternSelection = preferred.reduce(into: (selected: [WorkoutExerciseCandidate](), used: Set<String>())) { result, candidate in
            guard result.selected.count < targetCount else { return }
            guard !result.used.contains(candidate.pattern.rawValue) else { return }
            result.selected.append(candidate)
            result.used.insert(candidate.pattern.rawValue)
        }.selected

        if uniquePatternSelection.count >= min(2, targetCount) {
            return uniquePatternSelection
        }

        var selected = uniquePatternSelection
        for candidate in preferred where selected.count < targetCount && !selected.contains(candidate) {
            selected.append(candidate)
        }

        return Array(selected.prefix(max(2, min(4, selected.count))))
    }

    private static func neutralFallbackCandidates(
        equipment: EquipmentAccess,
        energyLevel: EnergyLevel
    ) -> [WorkoutExerciseCandidate] {
        workoutExercisePool(
            focus: .core,
            equipment: equipment,
            energyLevel: energyLevel
        )
    }

    private static func orderedUniqueCandidates(
        _ candidates: [WorkoutExerciseCandidate]
    ) -> [WorkoutExerciseCandidate] {
        candidates.reduce(into: [WorkoutExerciseCandidate]()) { result, candidate in
            guard !result.contains(candidate) else { return }
            result.append(candidate)
        }
    }

    private static func painFilterIsActive(_ painLogs: [DailyPainLog]) -> Bool {
        !activePainKeywordRules(from: painLogs).isEmpty
    }

    private static func isAllowedForPain(
        _ candidate: WorkoutExerciseCandidate,
        painLogs: [DailyPainLog]
    ) -> Bool {
        filterForPain([candidate], painLogs: painLogs).isEmpty == false
    }

    private static func filterForPain(
        _ candidates: [WorkoutExerciseCandidate],
        painLogs: [DailyPainLog]
    ) -> [WorkoutExerciseCandidate] {
        let rules = activePainKeywordRules(from: painLogs)
        guard !rules.isEmpty else { return candidates }

        return candidates.filter { candidate in
            let normalizedName = candidate.name.lowercased()
            return rules.allSatisfy { keywords in
                keywords.allSatisfy { !normalizedName.contains($0) }
            }
        }
    }

    private static func activePainKeywordRules(from painLogs: [DailyPainLog]) -> [[String]] {
        Set(
            painLogs
                .filter { $0.intensity >= 4 }
                .flatMap(\.bodyRegions)
                .map(\.engineKey)
        )
        .map(painKeywords)
        .filter { !$0.isEmpty }
    }

    private static func painKeywords(for region: String) -> [String] {
        switch region {
        case "knee", "ankle":
            return ["squat", "lunge", "step-up", "box jump", "wall ball", "thruster"]
        case "hip":
            return ["deadlift", "good morning", "hip thrust", "lunge", "step-up", "swing"]
        case "back":
            return ["deadlift", "good morning", "row", "swing", "clean", "snatch", "back squat"]
        case "shoulder":
            return ["press", "push-up", "dip", "thruster", "snatch", "jerk"]
        case "wrist", "elbow":
            return ["curl", "press", "push-up", "clean", "snatch", "dip"]
        default:
            return []
        }
    }

    private static func isHighStress(_ name: String) -> Bool {
        let normalizedName = name.lowercased()
        let highStressTerms = [
            "1rm",
            "max",
            "barbell",
            "back squat",
            "deadlift",
            "clean",
            "snatch",
            "box jump",
            "burpee",
            "thruster",
            "weighted"
        ]
        return highStressTerms.contains { normalizedName.contains($0) }
    }

    private static func trimToFit(plans: inout [QuickExercisePlan], timeLimit: Int) {
        while estimateMinutes(plans) > timeLimit {
            if let index = plans.lastIndex(where: { $0.sets > 1 }) {
                plans[index].sets -= 1
            } else if plans.count > minimumExerciseCount(timeLimit: timeLimit) {
                plans.removeLast()
            } else {
                return
            }
        }
    }

    private static func minimumExerciseCount(timeLimit: Int) -> Int {
        timeLimit <= 4 ? 1 : 2
    }

    private static func estimateMinutes(_ plans: [QuickExercisePlan]) -> Int {
        let total = plans.reduce(0.0) { partial, plan in
            let setMinutes = Double(plan.sets)
            let restMinutes = Double(max(0, plan.sets - 1)) * plan.restMinutes
            return partial + setMinutes + restMinutes + 1.0
        }
        return Int(ceil(total))
    }

    private static func makeExercise(from plan: QuickExercisePlan) -> Exercise {
        Exercise(
            id: UUID().uuidString,
            name: plan.candidate.name,
            category: category(for: plan.candidate.pattern),
            bodyweight: plan.candidate.bodyweightOnly ? 1.0 : 0.0,
            targetSets: (0..<plan.sets).map { _ in
                ExerciseSet(
                    reps: reps(for: plan.candidate.pattern),
                    prescribedWeight: 0,
                    type: .fixed
                )
            },
            restMinutes: plan.restMinutes
        )
    }

    private static func category(for pattern: WorkoutMovementPattern) -> ExerciseCategory {
        switch pattern {
        case .squat, .hinge, .push, .pull:
            return .compound
        case .core, .carry, .conditioning:
            return .accessory
        }
    }

    private static func reps(for pattern: WorkoutMovementPattern) -> Int {
        switch pattern {
        case .core, .carry:
            return 30
        case .conditioning:
            return 10
        case .squat, .hinge, .push, .pull:
            return 8
        }
    }

    private static func buildReasons(
        request: QuickWorkoutRequest,
        timeLimit: Int,
        estimatedMinutes: Int,
        lowRecovery: Bool,
        painAvoidanceApplied: Bool
    ) -> [String] {
        var reasons = [String]()

        if estimatedMinutes > timeLimit {
            reasons.append("Requested a \(timeLimit)-minute window.")
            reasons.append("Minimum viable workout is about \(estimatedMinutes) minutes, which exceeds the request.")
        } else {
            reasons.append("Built to fit a \(timeLimit)-minute window.")
        }

        reasons.append("Uses \(request.equipment.displayName.lowercased()) movements.")

        if lowRecovery {
            reasons.append("Today context kept the work submaximal.")
        }

        if request.todayDecisionKind == .modify {
            reasons.append("Today calls for a modified session, so volume stays focused.")
        }

        if painAvoidanceApplied {
            reasons.append("Pain log context avoided higher-irritation movement patterns.")
        }

        return reasons
    }
}

private struct QuickExercisePlan: Sendable, Equatable {
    var candidate: WorkoutExerciseCandidate
    var sets: Int
    var restMinutes: Double
}

extension Array where Element == DailyPainLog {
    fileprivate var quickWorkoutComparableValue: [String] {
        map { log in
            [
                log.id,
                log.locationIds,
                "\(log.intensity)",
                log.painType.rawValue,
                "\(log.date.timeIntervalSince1970)",
                log.notes ?? ""
            ].joined(separator: "|")
        }
    }
}
