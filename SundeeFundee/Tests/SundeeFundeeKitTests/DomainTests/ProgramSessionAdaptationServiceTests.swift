import XCTest
@testable import SundeeFundeeKit

final class ProgramSessionAdaptationServiceTests: XCTestCase {
    func testMenstrualPhaseReducesLowerBodyVolumeAndIncreasesRest() {
        let exercise = GeneratedProgramExercise(
            exercise: "Back Squat",
            sets: .fixed(value: 4),
            reps: .fixed(value: 10),
            percent1RM: 0.70,
            restMinutes: 2.0,
            bodyweightOnly: false
        )

        let adapted = ProgramSessionAdaptationService.adapt(
            [exercise],
            context: ProgramSessionAdaptationContext(cyclePhase: .menstrual)
        )

        guard let result = adapted.first else {
            return XCTFail("Expected an adapted exercise")
        }
        XCTAssertEqual(result.sets, .fixed(value: 3))
        XCTAssertEqual(result.reps, .fixed(value: 9))
        XCTAssertEqual(result.percent1RM ?? 0, 0.595, accuracy: 0.001)
        XCTAssertEqual(result.restMinutes, 2.4, accuracy: 0.001)
    }

    func testActiveKneeInjuryReplacesContraindicatedSquat() {
        let exercise = GeneratedProgramExercise(
            exercise: "Back Squat",
            sets: .fixed(value: 3),
            reps: .range(low: 8, high: 10),
            percent1RM: 0.65,
            restMinutes: 1.5,
            bodyweightOnly: false
        )
        let injury = Injury(
            id: "knee",
            locationIds: "knee_right",
            name: "Knee irritation",
            recoveryPhase: .rehab,
            dateCreated: Date(),
            phaseUpdated: Date()
        )

        let adapted = ProgramSessionAdaptationService.adapt(
            [exercise],
            context: ProgramSessionAdaptationContext(injuries: [injury])
        )

        guard let result = adapted.first else {
            return XCTFail("Expected an adapted exercise")
        }
        XCTAssertNotEqual(result.exercise, "Back Squat")
        XCTAssertFalse(InjuryAdaptationEngine.isContraindicated(
            exerciseName: result.exercise,
            exerciseCategory: nil,
            injuries: [injury]
        ))
        XCTAssertNil(result.percent1RM)
    }

    func testResolvedInjuryDoesNotChangeProgramExercise() {
        let exercise = GeneratedProgramExercise(
            exercise: "Back Squat",
            sets: .fixed(value: 3),
            reps: .fixed(value: 5),
            percent1RM: 0.75,
            restMinutes: 2.0,
            bodyweightOnly: false
        )
        let injury = Injury(
            id: "knee",
            locationIds: "knee_right",
            name: "Knee irritation",
            recoveryPhase: .resolved,
            dateCreated: Date(),
            phaseUpdated: Date()
        )

        let adapted = ProgramSessionAdaptationService.adapt(
            [exercise],
            context: ProgramSessionAdaptationContext(injuries: [injury])
        )

        XCTAssertEqual(adapted.first?.exercise, "Back Squat")
        XCTAssertEqual(adapted.first?.percent1RM, 0.75)
    }
}
