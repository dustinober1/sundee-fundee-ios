#if canImport(ActivityKit)
import ActivityKit
#endif
import Foundation

public enum ActiveWorkoutStatus: String, Codable, Hashable, Sendable {
    case active
    case resting
    case completed
}

public struct ActiveWorkoutProgress: Codable, Hashable, Sendable {
    public var completedSets: Int
    public var totalSets: Int
    public var remainingSets: Int
    public var completedExercises: Int
    public var totalExercises: Int

    public init(
        completedSets: Int = 0,
        totalSets: Int = 0,
        remainingSets: Int = 0,
        completedExercises: Int = 0,
        totalExercises: Int = 0
    ) {
        self.completedSets = completedSets
        self.totalSets = totalSets
        self.remainingSets = remainingSets
        self.completedExercises = completedExercises
        self.totalExercises = totalExercises
    }
}

public struct ActiveWorkoutState: Codable, Hashable, Sendable {
    public struct Current: Codable, Hashable, Sendable {
        public var exerciseName: String
        public var exerciseIndex: Int
        public var setIndex: Int
        public var completedExerciseSets: Int
        public var totalExerciseSets: Int
        public var prescribedRepsText: String
        public var prescribedWeight: Double
        public var actualReps: Int?
        public var completedWeight: Double?
        public var restSecondsAfterSet: TimeInterval

        public init(
            exerciseName: String = "",
            exerciseIndex: Int = 0,
            setIndex: Int = 0,
            completedExerciseSets: Int = 0,
            totalExerciseSets: Int = 0,
            prescribedRepsText: String = "",
            prescribedWeight: Double = 0,
            actualReps: Int? = nil,
            completedWeight: Double? = nil,
            restSecondsAfterSet: TimeInterval = 0
        ) {
            self.exerciseName = exerciseName
            self.exerciseIndex = exerciseIndex
            self.setIndex = setIndex
            self.completedExerciseSets = completedExerciseSets
            self.totalExerciseSets = totalExerciseSets
            self.prescribedRepsText = prescribedRepsText
            self.prescribedWeight = prescribedWeight
            self.actualReps = actualReps
            self.completedWeight = completedWeight
            self.restSecondsAfterSet = restSecondsAfterSet
        }
    }

    public struct NextUp: Codable, Hashable, Sendable {
        public var exerciseName: String
        public var exerciseIndex: Int
        public var setIndex: Int
        public var prescribedRepsText: String
        public var prescribedWeight: Double

        public init(
            exerciseName: String = "",
            exerciseIndex: Int = 0,
            setIndex: Int = 0,
            prescribedRepsText: String = "",
            prescribedWeight: Double = 0
        ) {
            self.exerciseName = exerciseName
            self.exerciseIndex = exerciseIndex
            self.setIndex = setIndex
            self.prescribedRepsText = prescribedRepsText
            self.prescribedWeight = prescribedWeight
        }
    }

    public struct Rest: Codable, Hashable, Sendable {
        public var sourceExerciseName: String
        public var sourceSetIndex: Int
        public var targetDurationSeconds: TimeInterval
        public var startedAt: Date

        public init(
            sourceExerciseName: String = "",
            sourceSetIndex: Int = 0,
            targetDurationSeconds: TimeInterval = 0,
            startedAt: Date = .distantPast
        ) {
            self.sourceExerciseName = sourceExerciseName
            self.sourceSetIndex = sourceSetIndex
            self.targetDurationSeconds = targetDurationSeconds
            self.startedAt = startedAt
        }
    }

    public var workoutID: String
    public var workoutName: String
    public var status: ActiveWorkoutStatus
    public var lastUpdatedAt: Date
    public var elapsedSeconds: TimeInterval
    public var progress: ActiveWorkoutProgress
    public var current: Current?
    public var nextUp: NextUp?
    public var rest: Rest?

    public init(
        workoutID: String = "",
        workoutName: String = "",
        status: ActiveWorkoutStatus = .active,
        lastUpdatedAt: Date = .now,
        elapsedSeconds: TimeInterval = 0,
        progress: ActiveWorkoutProgress = .init(),
        current: Current? = nil,
        nextUp: NextUp? = nil,
        rest: Rest? = nil
    ) {
        self.workoutID = workoutID
        self.workoutName = workoutName
        self.status = status
        self.lastUpdatedAt = lastUpdatedAt
        self.elapsedSeconds = elapsedSeconds
        self.progress = progress
        self.current = current
        self.nextUp = nextUp
        self.rest = rest
    }
}

public struct LiveWorkoutActivityAttributes: Codable, Hashable, Sendable {
    public let workoutID: String
    public let workoutName: String

    public init(workoutID: String, workoutName: String) {
        self.workoutID = workoutID
        self.workoutName = workoutName
    }

    public struct ContentState: Codable, Hashable, Sendable {
        public let status: Status
        public let lastUpdatedAt: Date
        public let elapsedSeconds: Int
        public let progress: ProgressSummary
        public let current: CurrentStep?
        public let nextUp: UpcomingStep?
        public let rest: RestSummary?

        public init(
            status: Status,
            lastUpdatedAt: Date,
            elapsedSeconds: Int,
            progress: ProgressSummary,
            current: CurrentStep?,
            nextUp: UpcomingStep?,
            rest: RestSummary?
        ) {
            self.status = status
            self.lastUpdatedAt = lastUpdatedAt
            self.elapsedSeconds = elapsedSeconds
            self.progress = progress
            self.current = current
            self.nextUp = nextUp
            self.rest = rest
        }
    }

    public enum Status: String, Codable, Hashable, Sendable {
        case active
        case resting
        case completed
    }

    public struct ProgressSummary: Codable, Hashable, Sendable {
        public let completedSets: Int
        public let totalSets: Int
        public let remainingSets: Int
        public let completedExercises: Int
        public let totalExercises: Int
        public let fractionComplete: Double

        public init(
            completedSets: Int,
            totalSets: Int,
            remainingSets: Int,
            completedExercises: Int,
            totalExercises: Int,
            fractionComplete: Double
        ) {
            self.completedSets = completedSets
            self.totalSets = totalSets
            self.remainingSets = remainingSets
            self.completedExercises = completedExercises
            self.totalExercises = totalExercises
            self.fractionComplete = fractionComplete
        }
    }

    public struct CurrentStep: Codable, Hashable, Sendable {
        public let exerciseName: String
        public let exerciseIndex: Int
        public let setIndex: Int
        public let completedExerciseSets: Int
        public let totalExerciseSets: Int
        public let prescribedRepsText: String
        public let prescribedWeight: Double
        public let actualReps: Int?
        public let completedWeight: Double?
        public let restSecondsAfterSet: Int

        public init(
            exerciseName: String,
            exerciseIndex: Int,
            setIndex: Int,
            completedExerciseSets: Int,
            totalExerciseSets: Int,
            prescribedRepsText: String,
            prescribedWeight: Double,
            actualReps: Int?,
            completedWeight: Double?,
            restSecondsAfterSet: Int
        ) {
            self.exerciseName = exerciseName
            self.exerciseIndex = exerciseIndex
            self.setIndex = setIndex
            self.completedExerciseSets = completedExerciseSets
            self.totalExerciseSets = totalExerciseSets
            self.prescribedRepsText = prescribedRepsText
            self.prescribedWeight = prescribedWeight
            self.actualReps = actualReps
            self.completedWeight = completedWeight
            self.restSecondsAfterSet = restSecondsAfterSet
        }

        public var setDisplayText: String {
            "Set \(setIndex + 1) of \(totalExerciseSets)"
        }
    }

    public struct UpcomingStep: Codable, Hashable, Sendable {
        public let exerciseName: String
        public let exerciseIndex: Int
        public let setIndex: Int
        public let prescribedRepsText: String
        public let prescribedWeight: Double

        public init(
            exerciseName: String,
            exerciseIndex: Int,
            setIndex: Int,
            prescribedRepsText: String,
            prescribedWeight: Double
        ) {
            self.exerciseName = exerciseName
            self.exerciseIndex = exerciseIndex
            self.setIndex = setIndex
            self.prescribedRepsText = prescribedRepsText
            self.prescribedWeight = prescribedWeight
        }

        public var setDisplayText: String {
            "Set \(setIndex + 1)"
        }
    }

    public struct RestSummary: Codable, Hashable, Sendable {
        public let sourceExerciseName: String
        public let sourceSetIndex: Int
        public let targetDurationSeconds: Int
        public let elapsedSeconds: Int
        public let remainingSeconds: Int

        public init(
            sourceExerciseName: String,
            sourceSetIndex: Int,
            targetDurationSeconds: Int,
            elapsedSeconds: Int,
            remainingSeconds: Int
        ) {
            self.sourceExerciseName = sourceExerciseName
            self.sourceSetIndex = sourceSetIndex
            self.targetDurationSeconds = targetDurationSeconds
            self.elapsedSeconds = elapsedSeconds
            self.remainingSeconds = remainingSeconds
        }
    }

    public static func clampedSeconds(_ value: TimeInterval) -> Int {
        max(Int(value.rounded(.down)), 0)
    }
}

// MARK: - ActiveWorkoutState Mapping (iOS + ActivityKit only)
//
// ActiveWorkoutState, ActiveWorkoutProgress, and ActiveWorkoutStatus are defined
// in the app target and are not available in SPM test builds on macOS.

extension LiveWorkoutActivityAttributes {
    public static func attributes(from snapshot: ActiveWorkoutState) -> Self {
        Self(workoutID: snapshot.workoutID, workoutName: snapshot.workoutName)
    }

    public static func contentState(from snapshot: ActiveWorkoutState) -> ContentState {
        ContentState(
            status: Status(snapshot.status),
            lastUpdatedAt: snapshot.lastUpdatedAt,
            elapsedSeconds: clampedSeconds(snapshot.elapsedSeconds),
            progress: ProgressSummary(
                completedSets: max(snapshot.progress.completedSets, 0),
                totalSets: max(snapshot.progress.totalSets, 0),
                remainingSets: snapshot.progress.remainingSets,
                completedExercises: max(snapshot.progress.completedExercises, 0),
                totalExercises: max(snapshot.progress.totalExercises, 0),
                fractionComplete: fractionComplete(progress: snapshot.progress)
            ),
            current: snapshot.current.map {
                CurrentStep(
                    exerciseName: $0.exerciseName,
                    exerciseIndex: max($0.exerciseIndex, 0),
                    setIndex: max($0.setIndex, 0),
                    completedExerciseSets: max($0.completedExerciseSets, 0),
                    totalExerciseSets: max($0.totalExerciseSets, 0),
                    prescribedRepsText: $0.prescribedRepsText,
                    prescribedWeight: max($0.prescribedWeight, 0),
                    actualReps: $0.actualReps,
                    completedWeight: $0.completedWeight,
                    restSecondsAfterSet: clampedSeconds($0.restSecondsAfterSet)
                )
            },
            nextUp: snapshot.nextUp.map {
                UpcomingStep(
                    exerciseName: $0.exerciseName,
                    exerciseIndex: max($0.exerciseIndex, 0),
                    setIndex: max($0.setIndex, 0),
                    prescribedRepsText: $0.prescribedRepsText,
                    prescribedWeight: max($0.prescribedWeight, 0)
                )
            },
            rest: snapshot.rest.map {
                let elapsed = max(snapshot.lastUpdatedAt.timeIntervalSince($0.startedAt), 0)
                let target = clampedSeconds($0.targetDurationSeconds)
                let elapsedSeconds = clampedSeconds(elapsed)
                return RestSummary(
                    sourceExerciseName: $0.sourceExerciseName,
                    sourceSetIndex: max($0.sourceSetIndex, 0),
                    targetDurationSeconds: target,
                    elapsedSeconds: elapsedSeconds,
                    remainingSeconds: max(target - elapsedSeconds, 0)
                )
            }
        )
    }

    private static func fractionComplete(progress: ActiveWorkoutProgress) -> Double {
        guard progress.totalSets > 0 else { return 0 }
        let rawFraction = Double(progress.completedSets) / Double(progress.totalSets)
        return min(max(rawFraction, 0), 1)
    }
}

extension LiveWorkoutActivityAttributes.Status {
    init(_ status: ActiveWorkoutStatus) {
        switch status {
        case .active:
            self = .active
        case .resting:
            self = .resting
        case .completed:
            self = .completed
        }
    }
}

#if canImport(ActivityKit) && os(iOS)
extension LiveWorkoutActivityAttributes: ActivityAttributes {}
#endif

