import XCTest
@testable import SundeeFundeeKit

final class WarmupBuilderTests: XCTestCase {
    func testSquatFirstWorkoutGetsHipAnkleAndLightSquatPrep() {
        let block = WarmupBuilder.build(
            request: WarmupRequest(
                workout: workout(firstExerciseName: "Back Squat"),
                recoveryScoreTotal: 72,
                cyclePhase: .follicular,
                painLogs: [],
                maxMinutes: 8
            )
        )

        XCTAssertNotNil(block)
        let names = block?.exercises.map(\.name).joined(separator: " ") ?? ""
        XCTAssertTrue(names.localizedCaseInsensitiveContains("Hip"))
        XCTAssertTrue(names.localizedCaseInsensitiveContains("Ankle"))
        XCTAssertTrue(names.localizedCaseInsensitiveContains("Squat"))
        XCTAssertTrue(block?.reasons.contains(where: { $0.localizedCaseInsensitiveContains("squat") }) == true)
        XCTAssertTrue(block?.exercises.allSatisfy { $0.category == .warmup } == true)
    }

    func testLowRecoveryCapsWarmupAtLowIntensity() {
        let block = WarmupBuilder.build(
            request: WarmupRequest(
                workout: workout(firstExerciseName: "Back Squat"),
                recoveryScoreTotal: 32,
                cyclePhase: .luteal,
                painLogs: [],
                maxMinutes: 10
            )
        )

        XCTAssertNotNil(block)
        XCTAssertLessThanOrEqual(block?.estimatedMinutes ?? 99, 5)
        XCTAssertTrue(block?.exercises.allSatisfy { exercise in
            exercise.targetSets.allSatisfy { set in
                set.prescribedWeight == 0 && set.reps <= 8
            }
        } == true)
        XCTAssertTrue(block?.reasons.contains(where: { $0.localizedCaseInsensitiveContains("low recovery") }) == true)
    }

    func testActiveKneePainAvoidsJumpHeavyPrep() {
        let block = WarmupBuilder.build(
            request: WarmupRequest(
                workout: workout(firstExerciseName: "Front Squat"),
                recoveryScoreTotal: 68,
                cyclePhase: nil,
                painLogs: [
                    DailyPainLog(
                        id: "knee-pain",
                        locationIds: "knee_left",
                        intensity: 6,
                        painType: .acute,
                        date: Date()
                    )
                ],
                maxMinutes: 8
            )
        )

        let names = block?.exercises.map(\.name).joined(separator: " ") ?? ""
        XCTAssertFalse(names.localizedCaseInsensitiveContains("Jump"))
        XCTAssertFalse(names.localizedCaseInsensitiveContains("Pogo"))
        XCTAssertTrue(block?.reasons.contains(where: { $0.localizedCaseInsensitiveContains("knee") }) == true)
    }

    func testWorkoutWithNoExercisesReturnsNil() {
        let block = WarmupBuilder.build(
            request: WarmupRequest(
                workout: Workout(date: Date(), name: "Empty", exercises: []),
                recoveryScoreTotal: nil,
                cyclePhase: nil,
                painLogs: [],
                maxMinutes: 8
            )
        )

        XCTAssertNil(block)
    }

    private func workout(firstExerciseName: String) -> Workout {
        Workout(
            date: Date(),
            name: "Strength Day",
            exercises: [
                Exercise(
                    id: "first",
                    name: firstExerciseName,
                    category: .compound,
                    bodyweight: 0,
                    targetSets: [
                        ExerciseSet(reps: 5, prescribedWeight: 135, type: .fixed)
                    ]
                )
            ]
        )
    }
}
