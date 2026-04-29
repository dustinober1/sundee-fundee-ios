import Foundation
import XCTest
@testable import SundeeFundeeKit

#if canImport(ActivityKit) && os(iOS)

final class LiveWorkoutActivityStateTests: XCTestCase {
    func testContentState_WithActiveSnapshot_MapsPresentationOnlyFields() {
        let snapshot = makeSnapshot(status: .active)

        let attributes = LiveWorkoutActivityAttributes.attributes(from: snapshot)
        let state = LiveWorkoutActivityAttributes.contentState(from: snapshot)

        XCTAssertEqual(attributes.workoutID, "workout-1")
        XCTAssertEqual(attributes.workoutName, "Leg Day")

        XCTAssertEqual(state.status, .active)
        XCTAssertEqual(state.lastUpdatedAt, snapshot.lastUpdatedAt)
        XCTAssertEqual(state.elapsedSeconds, 600)
        XCTAssertEqual(state.progress.completedSets, 2)
        XCTAssertEqual(state.progress.totalSets, 5)
        XCTAssertEqual(state.progress.remainingSets, 3)
        XCTAssertEqual(state.progress.completedExercises, 0)
        XCTAssertEqual(state.progress.totalExercises, 2)
        XCTAssertEqual(state.progress.fractionComplete, 0.4, accuracy: 0.0001)

        XCTAssertEqual(state.current?.exerciseName, "Back Squat")
        XCTAssertEqual(state.current?.setIndex, 2)
        XCTAssertEqual(state.current?.setDisplayText, "Set 3 of 4")
        XCTAssertEqual(state.current?.prescribedRepsText, "5")
        XCTAssertEqual(state.current?.prescribedWeight, 185)
        XCTAssertEqual(state.current?.restSecondsAfterSet, 180)

        XCTAssertEqual(state.nextUp?.exerciseName, "Walking Lunge")
        XCTAssertEqual(state.nextUp?.setIndex, 0)
        XCTAssertEqual(state.nextUp?.setDisplayText, "Set 1")
        XCTAssertEqual(state.nextUp?.prescribedWeight, 40)

        XCTAssertNil(state.rest)
    }

	    func testContentState_WithRestingSnapshot_DerivesRestTimingFromSnapshotTimestamps() {
	        let snapshot = makeSnapshot(
	            status: .resting,
	            lastUpdatedAt: Date(timeIntervalSince1970: 1_100),
	            rest: ActiveWorkoutState.Rest(
	                sourceExerciseName: "Back Squat",
	                sourceSetIndex: 1,
	                targetDurationSeconds: 120,
	                startedAt: Date(timeIntervalSince1970: 1_040)
	            )
	        )

	        let state = LiveWorkoutActivityAttributes.contentState(from: snapshot)

	        XCTAssertEqual(state.status, LiveWorkoutActivityAttributes.Status.resting)
	        XCTAssertEqual(state.rest?.sourceExerciseName, "Back Squat")
	        XCTAssertEqual(state.rest?.sourceSetIndex, 1)
	        XCTAssertEqual(state.rest?.targetDurationSeconds, 120)
	        XCTAssertEqual(state.rest?.elapsedSeconds, 60)
        XCTAssertEqual(state.rest?.remainingSeconds, 60)
        XCTAssertEqual(state.current?.exerciseName, "Back Squat")
        XCTAssertEqual(state.nextUp?.exerciseName, "Walking Lunge")
    }

    func testContentState_WithCompletedSnapshot_HasNoCurrentNextUpOrRestAndClampsProgress() {
        let snapshot = ActiveWorkoutState(
            workoutID: "workout-finished",
            workoutName: "Finish Strong",
            status: .completed,
            lastUpdatedAt: Date(timeIntervalSince1970: 2_620),
            elapsedSeconds: 620,
            progress: ActiveWorkoutProgress(completedSets: 5, totalSets: 5, completedExercises: 2, totalExercises: 2),
            current: nil,
            nextUp: nil,
            rest: nil
        )

        let state = LiveWorkoutActivityAttributes.contentState(from: snapshot)

        XCTAssertEqual(state.status, .completed)
        XCTAssertEqual(state.elapsedSeconds, 620)
        XCTAssertEqual(state.progress.fractionComplete, 1.0, accuracy: 0.0001)
        XCTAssertNil(state.current)
        XCTAssertNil(state.nextUp)
        XCTAssertNil(state.rest)
    }

    func testContentState_WithNoCurrentOrNextUpAndZeroTotals_MapsPredictably() {
        let snapshot = ActiveWorkoutState(
            workoutID: "workout-edge",
            workoutName: "Edge Cases",
            status: .active,
            lastUpdatedAt: Date(timeIntervalSince1970: 3_010),
            elapsedSeconds: -4,
            progress: ActiveWorkoutProgress(completedSets: 0, totalSets: 0, completedExercises: 0, totalExercises: 0),
            current: nil,
            nextUp: nil,
            rest: nil
        )

        let state = LiveWorkoutActivityAttributes.contentState(from: snapshot)

        XCTAssertEqual(state.elapsedSeconds, 0)
        XCTAssertEqual(state.progress.remainingSets, 0)
        XCTAssertEqual(state.progress.fractionComplete, 0)
        XCTAssertNil(state.current)
        XCTAssertNil(state.nextUp)
        XCTAssertNil(state.rest)
    }

    func testContentState_ClampsImpossibleProgressAndExpiredRestToSafeValues() {
        let snapshot = ActiveWorkoutState(
            workoutID: "workout-clamped",
            workoutName: "Clamped",
            status: .resting,
            lastUpdatedAt: Date(timeIntervalSince1970: 4_500),
            elapsedSeconds: 500,
            progress: ActiveWorkoutProgress(completedSets: 7, totalSets: 5, completedExercises: 3, totalExercises: 2),
            current: ActiveWorkoutState.Current(
                exerciseName: "Bike Erg",
                exerciseIndex: 0,
                setIndex: 0,
                completedExerciseSets: 0,
                totalExerciseSets: 1,
                prescribedRepsText: "90 sec",
                prescribedWeight: -1,
                actualReps: nil,
                completedWeight: nil,
                restSecondsAfterSet: -15
            ),
	            nextUp: ActiveWorkoutState.NextUp(
	                exerciseName: "Run",
	                exerciseIndex: 1,
	                setIndex: 0,
	                prescribedRepsText: "400m",
	                prescribedWeight: -10
	            ),
	            rest: ActiveWorkoutState.Rest(
	                sourceExerciseName: "Bike Erg",
	                sourceSetIndex: 0,
	                targetDurationSeconds: 60,
	                startedAt: Date(timeIntervalSince1970: 4_100)
	            )
	        )

        let state = LiveWorkoutActivityAttributes.contentState(from: snapshot)

        XCTAssertEqual(state.progress.remainingSets, 0)
        XCTAssertEqual(state.progress.fractionComplete, 1.0, accuracy: 0.0001)
        XCTAssertEqual(state.current?.prescribedWeight, 0)
        XCTAssertEqual(state.current?.restSecondsAfterSet, 0)
        XCTAssertEqual(state.nextUp?.prescribedWeight, 0)
        XCTAssertEqual(state.rest?.elapsedSeconds, 400)
        XCTAssertEqual(state.rest?.remainingSeconds, 0)
    }

    private func makeSnapshot(
        status: ActiveWorkoutStatus,
        lastUpdatedAt: Date = Date(timeIntervalSince1970: 1_000),
        rest: ActiveWorkoutState.Rest? = nil
    ) -> ActiveWorkoutState {
	        ActiveWorkoutState(
	            workoutID: "workout-1",
	            workoutName: "Leg Day",
	            status: status,
	            lastUpdatedAt: lastUpdatedAt,
	            elapsedSeconds: 600,
	            progress: ActiveWorkoutProgress(
	                completedSets: 2,
	                totalSets: 5,
	                remainingSets: 3,
	                completedExercises: 0,
	                totalExercises: 2
	            ),
	            current: ActiveWorkoutState.Current(
	                exerciseName: "Back Squat",
	                exerciseIndex: 0,
	                setIndex: 2,
                completedExerciseSets: 2,
                totalExerciseSets: 4,
                prescribedRepsText: "5",
                prescribedWeight: 185,
                actualReps: nil,
                completedWeight: nil,
                restSecondsAfterSet: 180
            ),
            nextUp: ActiveWorkoutState.NextUp(
                exerciseName: "Walking Lunge",
                exerciseIndex: 1,
                setIndex: 0,
                prescribedRepsText: "10 / leg",
                prescribedWeight: 40
            ),
            rest: rest
        )
    }
}

#endif
