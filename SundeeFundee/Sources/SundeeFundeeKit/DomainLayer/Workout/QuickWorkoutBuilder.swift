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
        let restMinutes = WorkoutVolumePlanner.restMinutes(focus: request.focus, lowRecovery: lowRecovery)

        // Select generously, then let the volume plan decide how much of the
        // shortlist the requested window can actually pay for.
        let shortlist = selectCandidates(
            request: request,
            targetCount: WorkoutVolumePlanner.defaultMaxExercises,
            lowRecovery: lowRecovery
        )
        let volume = WorkoutVolumePlanner.plan(
            timeMinutes: timeLimit,
            availableExercises: shortlist.count,
            restMinutes: restMinutes,
            model: .interactiveSession,
            maxSets: WorkoutVolumePlanner.maxSets(
                energyLevel: request.energyLevel,
                lowRecovery: lowRecovery
            ),
            minExercises: minimumExerciseCount(timeLimit: timeLimit),
            maxExercises: lowRecovery ? 5 : WorkoutVolumePlanner.defaultMaxExercises
        )

        let plans = zip(shortlist, volume.setsPerExercise).map { candidate, sets in
            QuickExercisePlan(candidate: candidate, sets: sets, restMinutes: restMinutes)
        }

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

        return spreadAcrossPatterns(
            preferred,
            targetCount: targetCount,
            focus: request.focus
        )
    }

    /// Picks candidates in pattern round-robin: one movement per pattern, then a
    /// second, and so on. Variety lands at the front of the list, which matters
    /// because the volume plan front-loads sets onto the earliest picks.
    private static func spreadAcrossPatterns(
        _ candidates: [WorkoutExerciseCandidate],
        targetCount: Int,
        focus: WorkoutFocus
    ) -> [WorkoutExerciseCandidate] {
        let patternLimit = maxExercisesPerPattern(focus: focus, exerciseCount: targetCount)
        var selected = [WorkoutExerciseCandidate]()
        var takenPerPattern = [WorkoutMovementPattern: Int]()

        for tier in 0..<max(1, patternLimit) {
            for candidate in candidates where selected.count < targetCount {
                guard takenPerPattern[candidate.pattern, default: 0] == tier else { continue }
                guard !selected.contains(candidate) else { continue }
                selected.append(candidate)
                takenPerPattern[candidate.pattern, default: 0] += 1
            }
        }

        return selected
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
        case "knee":
            return ["squat", "lunge", "step-up", "box jump", "wall ball", "thruster", "wall sit", "jump"]
        case "ankle":
            return ["squat", "lunge", "step-up", "box jump", "wall ball", "thruster", "calf raise", "jump", "run"]
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
    let candidate: WorkoutExerciseCandidate
    let sets: Int
    let restMinutes: Double
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
