import XCTest
@testable import SundeeFundeeKit

final class RestGuidanceServiceTests: XCTestCase {
    func testHeavyCompoundWorkRecommendsLongerRestThanIsolationWork() {
        let heavyCompound = RestGuidanceService.guidance(
            context: context(
                exercise: exercise(name: "Back Squat", category: .compound, reps: 5, restMinutes: 2.0),
                completedSet: set(reps: 5, actualReps: 5, weight: 225)
            )
        )
        let isolation = RestGuidanceService.guidance(
            context: context(
                exercise: exercise(name: "Cable Curl", category: .isolation, reps: 12, restMinutes: 1.0),
                completedSet: set(reps: 12, actualReps: 12, weight: 25)
            )
        )

        XCTAssertGreaterThan(heavyCompound.seconds, isolation.seconds)
        XCTAssertTrue(heavyCompound.reason.localizedCaseInsensitiveContains("heavy"))
    }

    func testHighRPEOrMissedRepsAddsRest() {
        let baseline = RestGuidanceService.guidance(
            context: context(
                exercise: exercise(name: "Bench Press", category: .compound, reps: 5),
                completedSet: set(reps: 5, actualReps: 5),
                lastRPE: 8
            )
        )
        let highRPE = RestGuidanceService.guidance(
            context: context(
                exercise: exercise(name: "Bench Press", category: .compound, reps: 5),
                completedSet: set(reps: 5, actualReps: 5),
                lastRPE: 9
            )
        )
        let missedReps = RestGuidanceService.guidance(
            context: context(
                exercise: exercise(name: "Bench Press", category: .compound, reps: 5),
                completedSet: set(reps: 5, actualReps: 3),
                lastRPE: 8
            )
        )

        XCTAssertGreaterThan(highRPE.seconds, baseline.seconds)
        XCTAssertGreaterThan(missedReps.seconds, baseline.seconds)
        XCTAssertTrue(highRPE.reason.localizedCaseInsensitiveContains("hard"))
        XCTAssertTrue(missedReps.reason.localizedCaseInsensitiveContains("missed"))
    }

    func testLowRecoveryAddsRestButCapsAtFiveMinutes() {
        let normalRecovery = RestGuidanceService.guidance(
            context: context(
                exercise: exercise(name: "Back Squat", category: .compound, reps: 3, restMinutes: 4.5),
                completedSet: set(reps: 3, actualReps: 3),
                recoveryScoreTotal: 80
            )
        )
        let lowRecovery = RestGuidanceService.guidance(
            context: context(
                exercise: exercise(name: "Back Squat", category: .compound, reps: 3, restMinutes: 4.5),
                completedSet: set(reps: 3, actualReps: 2),
                lastRPE: 9,
                recoveryScoreTotal: 30
            )
        )

        XCTAssertGreaterThan(lowRecovery.seconds, normalRecovery.seconds)
        XCTAssertEqual(lowRecovery.seconds, 300)
        XCTAssertTrue(lowRecovery.reason.localizedCaseInsensitiveContains("recovery"))
    }

    func testConditioningWorkKeepsRestShortUnlessRepsWereMissed() {
        let completed = RestGuidanceService.guidance(
            context: context(
                exercise: exercise(name: "Bike Erg Intervals", category: .accessory, reps: 30, restMinutes: 2.0),
                completedSet: set(reps: 30, actualReps: 30, type: .amrap)
            )
        )
        let missed = RestGuidanceService.guidance(
            context: context(
                exercise: exercise(name: "Bike Erg Intervals", category: .accessory, reps: 30, restMinutes: 2.0),
                completedSet: set(reps: 30, actualReps: 20, type: .amrap)
            )
        )

        XCTAssertLessThanOrEqual(completed.seconds, 75)
        XCTAssertGreaterThan(missed.seconds, completed.seconds)
        XCTAssertTrue(completed.reason.localizedCaseInsensitiveContains("conditioning"))
    }

    private func context(
        exercise: Exercise,
        completedSet: ExerciseSet,
        lastRPE: Int? = nil,
        recoveryScoreTotal: Int? = nil
    ) -> RestGuidanceContext {
        RestGuidanceContext(
            exercise: exercise,
            completedSet: completedSet,
            lastRPE: lastRPE,
            recoveryScoreTotal: recoveryScoreTotal
        )
    }

    private func exercise(
        name: String,
        category: ExerciseCategory,
        reps: Int,
        restMinutes: Double = 2.0
    ) -> Exercise {
        Exercise(
            id: name.lowercased().replacingOccurrences(of: " ", with: "-"),
            name: name,
            category: category,
            bodyweight: 0,
            targetSets: [set(reps: reps, actualReps: nil)],
            restMinutes: restMinutes
        )
    }

    private func set(
        reps: Int,
        actualReps: Int?,
        weight: Double = 135,
        type: ExerciseType = .fixed
    ) -> ExerciseSet {
        ExerciseSet(
            reps: reps,
            prescribedWeight: weight,
            type: type,
            completedWeight: weight,
            actualReps: actualReps,
            isComplete: actualReps != nil
        )
    }
}
