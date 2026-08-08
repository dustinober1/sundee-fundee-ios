import Foundation

// MARK: - Workout Time Model

/// How a generator converts sets and rests into wall-clock minutes.
///
/// The two generators historically estimated duration differently, which meant
/// a plan sized against one model could fail the other's validation. Making the
/// model explicit lets both size their volume against the exact arithmetic that
/// will later be used to judge them.
public struct WorkoutTimeModel: Sendable, Equatable {
    /// Working time for a single set, excluding rest.
    public let setWorkMinutes: Double
    /// Setup and transition time charged once per exercise.
    public let transitionMinutes: Double
    /// Whether rest is charged after the final set of an exercise.
    public let restsAfterFinalSet: Bool

    public init(setWorkMinutes: Double, transitionMinutes: Double, restsAfterFinalSet: Bool) {
        self.setWorkMinutes = setWorkMinutes
        self.transitionMinutes = transitionMinutes
        self.restsAfterFinalSet = restsAfterFinalSet
    }

    /// Matches `QuickWorkoutBuilder`: `sets + (sets - 1) * rest + 1` per exercise.
    public static let interactiveSession = WorkoutTimeModel(
        setWorkMinutes: 1.0,
        transitionMinutes: 1.0,
        restsAfterFinalSet: false
    )

    /// Matches `totalEstimatedMinutes`: `sets * (rest + 0.5)` per exercise.
    public static let generatedWorkout = WorkoutTimeModel(
        setWorkMinutes: 0.5,
        transitionMinutes: 0.0,
        restsAfterFinalSet: true
    )
}

// MARK: - Workout Volume Plan

/// The volume shape of a session: how many movements, and how many sets each.
public struct WorkoutVolumePlan: Sendable, Equatable {
    /// Sets for each selected exercise, index-aligned with the selection.
    /// Front-loaded, so the primary movements carry the extra work.
    public let setsPerExercise: [Int]
    public let restMinutes: Double
    /// Duration implied by this plan under the model it was built with.
    public let estimatedMinutes: Int
    /// True when even the smallest viable session overruns the requested window.
    public let exceedsRequestedTime: Bool

    public var exerciseCount: Int { setsPerExercise.count }
    public var totalSets: Int { setsPerExercise.reduce(0, +) }

    public init(
        setsPerExercise: [Int],
        restMinutes: Double,
        estimatedMinutes: Int,
        exceedsRequestedTime: Bool
    ) {
        self.setsPerExercise = setsPerExercise
        self.restMinutes = restMinutes
        self.estimatedMinutes = estimatedMinutes
        self.exceedsRequestedTime = exceedsRequestedTime
    }
}

// MARK: - Workout Volume Planner

/// Turns a requested duration into an actual amount of work.
///
/// Both generators used to pick a near-constant amount of volume: the quick
/// builder capped out at four exercises of three sets, and the coach kept sets
/// fixed no matter how long the user had. A 25-minute and a 90-minute request
/// produced the same session. This planner spends the whole window instead —
/// adding movements first (variety), then stacking sets once the movement count
/// is capped or the exercise pool runs dry.
public enum WorkoutVolumePlanner {
    /// Movement count ceiling. Beyond this a session stops adding variety and
    /// starts adding sets, which is how longer training days actually work.
    public static let defaultMaxExercises = 8

    public static func plan(
        timeMinutes: Int,
        availableExercises: Int,
        restMinutes: Double,
        model: WorkoutTimeModel,
        maxSets: Int,
        minExercises: Int = 1,
        maxExercises: Int = defaultMaxExercises
    ) -> WorkoutVolumePlan {
        let budget = Double(max(1, timeMinutes))
        let poolCeiling = max(1, min(availableExercises, maxExercises))
        let floor = max(1, min(minExercises, poolCeiling))
        let boundedMaxSets = max(1, maxSets)

        // Size the movement count off a reference three-set exercise, then let
        // the fill loop below spend whatever budget is left.
        let referenceCost = exerciseMinutes(sets: 3, rest: restMinutes, model: model)
        let scaledCount = referenceCost > 0 ? Int((budget / referenceCost).rounded()) : floor
        var count = min(poolCeiling, max(floor, scaledCount))

        // Seed every movement with two sets where possible; a session that
        // cannot afford that drops to singles before it drops movements.
        var seedSets = 2
        while totalMinutes(Array(repeating: seedSets, count: count), rest: restMinutes, model: model) > budget {
            if seedSets > 1 {
                seedSets -= 1
            } else if count > floor {
                count -= 1
            } else {
                break
            }
        }

        var sets = Array(repeating: min(seedSets, boundedMaxSets), count: count)

        // Fill: repeatedly give a set to the lightest movement while it fits.
        while let index = lightestFillableIndex(sets, maxSets: boundedMaxSets) {
            var candidate = sets
            candidate[index] += 1
            guard totalMinutes(candidate, rest: restMinutes, model: model) <= budget else { break }
            sets = candidate
        }

        let total = totalMinutes(sets, rest: restMinutes, model: model)
        return WorkoutVolumePlan(
            setsPerExercise: sets,
            restMinutes: restMinutes,
            estimatedMinutes: max(1, Int(ceil(total))),
            exceedsRequestedTime: total > budget
        )
    }

    /// Rest between sets, in minutes.
    public static func restMinutes(focus: WorkoutFocus, lowRecovery: Bool) -> Double {
        if lowRecovery { return 1.0 }
        if focus == .conditioning { return 0.75 }
        return 1.25
    }

    /// Set ceiling per exercise. Low-recovery days stay well short of it.
    public static func maxSets(energyLevel: EnergyLevel, lowRecovery: Bool) -> Int {
        if lowRecovery { return 3 }
        return energyLevel == .low ? 4 : 6
    }

    // MARK: - Private

    private static func lightestFillableIndex(_ sets: [Int], maxSets: Int) -> Int? {
        var target: Int?
        for index in sets.indices where sets[index] < maxSets {
            if let current = target, sets[index] >= sets[current] { continue }
            target = index
        }
        return target
    }

    private static func totalMinutes(
        _ sets: [Int],
        rest: Double,
        model: WorkoutTimeModel
    ) -> Double {
        sets.reduce(0.0) { partial, count in
            partial + exerciseMinutes(sets: count, rest: rest, model: model)
        }
    }

    private static func exerciseMinutes(
        sets: Int,
        rest: Double,
        model: WorkoutTimeModel
    ) -> Double {
        let restedSets = model.restsAfterFinalSet ? sets : max(0, sets - 1)
        return Double(sets) * model.setWorkMinutes
            + Double(restedSets) * rest
            + model.transitionMinutes
    }
}
