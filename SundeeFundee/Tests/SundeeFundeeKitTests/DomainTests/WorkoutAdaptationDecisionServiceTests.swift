import XCTest
@testable import SundeeFundeeKit

final class WorkoutAdaptationDecisionServiceTests: XCTestCase {
    func testRecordingAdaptationStoresOriginalAndAdaptedWorkoutJSONStrings() async throws {
        let dataClient = MockCloudKitClient()
        let original = makeWorkout(name: "Base", reps: 8)
        let adapted = makeWorkout(id: original.id, name: "Adapted", reps: 6)
        let summary = ProgramAdaptationSummary(
            headline: "Session adapted to your current readiness and pain context.",
            changes: [
                ProgramAdaptationChange(
                    reasonCode: .recoveryAdjustment,
                    exerciseName: "Back Squat",
                    detail: "Recovery context reduced volume and intensity."
                )
            ]
        )

        let record = try await WorkoutAdaptationDecisionService.record(
            originalWorkout: original,
            adaptedWorkout: adapted,
            summary: summary,
            context: ProgramSessionAdaptationContext(recoveryScore: 38),
            dataClient: dataClient,
            dateCreated: Date(timeIntervalSince1970: 100)
        )

        let stored: [WorkoutAdaptationDecisionRecord] = try await dataClient.fetchAll(
            recordType: "WorkoutAdaptationDecisionRecord"
        )
        XCTAssertEqual(stored, [record])

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedOriginal = try decoder.decode(Workout.self, from: Data(record.originalWorkoutJSON.utf8))
        let decodedAdapted = try decoder.decode(Workout.self, from: Data(record.adaptedWorkoutJSON.utf8))
        XCTAssertEqual(decodedOriginal, original)
        XCTAssertEqual(decodedAdapted, adapted)
    }

    func testUndoSucceedsWhenNoSetsAreComplete() throws {
        let original = makeWorkout(name: "Base", reps: 8)
        let adapted = makeWorkout(id: original.id, name: "Adapted", reps: 6)
        let record = try WorkoutAdaptationDecisionService.makeRecord(
            originalWorkout: original,
            adaptedWorkout: adapted,
            summary: ProgramAdaptationSummary(headline: "Adapted", changes: []),
            context: ProgramSessionAdaptationContext(),
            dateCreated: Date(timeIntervalSince1970: 100)
        )

        let result = WorkoutAdaptationDecisionService.undo(record: record, currentWorkout: adapted)

        XCTAssertEqual(result, .restored(original))
    }

    func testUndoFailsWithUserFacingReasonOnceProgressIsLogged() throws {
        let original = makeWorkout(name: "Base", reps: 8)
        var adapted = makeWorkout(id: original.id, name: "Adapted", reps: 6)
        adapted.exercises[0].targetSets[0].isComplete = true
        let record = try WorkoutAdaptationDecisionService.makeRecord(
            originalWorkout: original,
            adaptedWorkout: makeWorkout(id: original.id, name: "Adapted", reps: 6),
            summary: ProgramAdaptationSummary(headline: "Adapted", changes: []),
            context: ProgramSessionAdaptationContext(),
            dateCreated: Date(timeIntervalSince1970: 100)
        )

        let result = WorkoutAdaptationDecisionService.undo(record: record, currentWorkout: adapted)

        XCTAssertEqual(
            result,
            .blocked(reason: "Changes can only be undone before you log a set.")
        )
    }

    func testUndoFailsWhenDecisionRecordBelongsToDifferentWorkout() throws {
        let original = makeWorkout(name: "Base", reps: 8)
        let adapted = makeWorkout(id: "workout-1", name: "Adapted", reps: 6)
        let otherWorkout = makeWorkout(id: "workout-2", name: "Other", reps: 6)
        let record = try WorkoutAdaptationDecisionService.makeRecord(
            originalWorkout: original,
            adaptedWorkout: adapted,
            summary: ProgramAdaptationSummary(headline: "Adapted", changes: []),
            context: ProgramSessionAdaptationContext(),
            dateCreated: Date(timeIntervalSince1970: 100)
        )

        let result = WorkoutAdaptationDecisionService.undo(record: record, currentWorkout: otherWorkout)

        XCTAssertEqual(
            result,
            .blocked(reason: "These changes belong to a different workout, so they can't be undone here.")
        )
    }

    func testDecisionReasonsIncludeCycleRecoveryPainEquipmentAndEffortWhenPresent() throws {
        let original = makeWorkout(name: "Base", reps: 8)
        let adapted = makeWorkout(id: original.id, name: "Adapted", reps: 6)
        let summary = ProgramAdaptationSummary(
            headline: "Session adapted.",
            changes: [
                ProgramAdaptationChange(
                    reasonCode: .cycleAdjustment,
                    exerciseName: "Back Squat",
                    detail: "Cycle phase adjusted load, reps, or rest."
                ),
                ProgramAdaptationChange(
                    reasonCode: .recoveryAdjustment,
                    exerciseName: "Back Squat",
                    detail: "Recovery context reduced volume and intensity."
                ),
                ProgramAdaptationChange(
                    reasonCode: .painAdjustment,
                    exerciseName: "Back Squat",
                    detail: "Volume and loading reduced for recent pain."
                ),
                ProgramAdaptationChange(
                    reasonCode: .equipmentConversion,
                    exerciseName: "Dumbbell Goblet Squat",
                    detail: "Converted to match your available equipment."
                )
            ]
        )

        let record = try WorkoutAdaptationDecisionService.makeRecord(
            originalWorkout: original,
            adaptedWorkout: adapted,
            summary: summary,
            context: ProgramSessionAdaptationContext(
                cyclePhase: .menstrual,
                recoveryScore: 34,
                painIntensity: 7,
                equipment: .homeDumbbells,
                recentEffortRPE: 9
            ),
            dateCreated: Date(timeIntervalSince1970: 100)
        )

        XCTAssertEqual(record.reasonIDs, ["cycle", "recovery", "pain", "equipment", "effort"])
        XCTAssertTrue(record.reasonText.contains("Cycle phase: menstrual."))
        XCTAssertTrue(record.reasonText.contains("Recovery score 34/100 reduced today's load."))
        XCTAssertTrue(record.reasonText.contains("Pain check-in 7/10 reduced today's strain."))
        XCTAssertTrue(record.reasonText.contains("Equipment matched to Home Dumbbells."))
        XCTAssertTrue(record.reasonText.contains("Recent effort RPE 9 kept today's work in check."))
    }

    func testDecisionReasonsStayEmptyWhenSummaryHasNoChanges() throws {
        let record = try WorkoutAdaptationDecisionService.makeRecord(
            originalWorkout: makeWorkout(name: "Base", reps: 8),
            adaptedWorkout: makeWorkout(name: "Adapted", reps: 8),
            summary: ProgramAdaptationSummary(headline: "Unchanged", changes: []),
            context: ProgramSessionAdaptationContext(
                cyclePhase: .menstrual,
                recoveryScore: 40,
                painIntensity: 5,
                equipment: .fullGym,
                recentEffortRPE: 8
            ),
            dateCreated: Date(timeIntervalSince1970: 100)
        )

        XCTAssertEqual(record.reasonIDs, [])
        XCTAssertEqual(record.reasonText, [])
    }

    private func makeWorkout(
        id: String = "workout-1",
        name: String,
        reps: Int
    ) -> Workout {
        Workout(
            id: id,
            date: Date(timeIntervalSince1970: 0),
            name: name,
            exercises: [
                Exercise(
                    id: "exercise-1",
                    name: "Back Squat",
                    category: .compound,
                    bodyweight: 0,
                    targetSets: [
                        ExerciseSet(
                            id: "set-1",
                            reps: reps,
                            prescribedWeight: 135,
                            type: .fixed
                        )
                    ],
                    restMinutes: 2
                )
            ]
        )
    }
}
