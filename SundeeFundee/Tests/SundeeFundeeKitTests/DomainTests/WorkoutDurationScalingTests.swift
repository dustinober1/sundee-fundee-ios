import XCTest
@testable import SundeeFundeeKit

/// Guards the property the generators used to get wrong: the amount of work in a
/// session has to track the amount of time the user said they had.
final class WorkoutDurationScalingTests: XCTestCase {

    private let durations = [20, 30, 45, 60, 75, 90]

    // MARK: - QuickWorkoutBuilder

    private func quickWorkout(minutes: Int, focus: WorkoutFocus = .fullBody, equipment: EquipmentAccess = .fullGym) -> QuickWorkoutResult {
        QuickWorkoutBuilder.build(
            request: QuickWorkoutRequest(
                timeMinutes: minutes,
                focus: focus,
                energyLevel: .medium,
                equipment: equipment,
                todayDecisionKind: .modify,
                painLogs: []
            )
        )
    }

    private func totalSets(_ workout: Workout) -> Int {
        workout.exercises.reduce(0) { $0 + $1.targetSets.count }
    }

    func testQuickBuilderVolumeGrowsWithEveryDurationStep() {
        var previous = 0
        for minutes in durations {
            let sets = totalSets(quickWorkout(minutes: minutes).workout)
            XCTAssertGreaterThan(
                sets,
                previous,
                "\(minutes) min should prescribe more total sets than the step below it"
            )
            previous = sets
        }
    }

    func testQuickBuilderLongSessionHasMoreMovementsThanShortSession() {
        let short = quickWorkout(minutes: 20).workout
        let long = quickWorkout(minutes: 60).workout
        XCTAssertGreaterThan(long.exercises.count, short.exercises.count)
    }

    func testQuickBuilderNeverOverrunsARealisticWindow() {
        for minutes in durations {
            for equipment in EquipmentAccess.userSelectableDefaults {
                let result = quickWorkout(minutes: minutes, equipment: equipment)
                XCTAssertLessThanOrEqual(
                    result.estimatedMinutes,
                    minutes,
                    "\(equipment.rawValue) at \(minutes) min overran its window"
                )
            }
        }
    }

    func testQuickBuilderUsesMostOfTheRequestedWindow() {
        for minutes in durations {
            let result = quickWorkout(minutes: minutes)
            XCTAssertGreaterThanOrEqual(
                Double(result.estimatedMinutes),
                Double(minutes) * 0.8,
                "\(minutes) min left too much of the window unused"
            )
        }
    }

    // MARK: - DeterministicCoachService

    private func generate(
        minutes: Int,
        focus: WorkoutFocus = .fullBody,
        equipment: EquipmentAccess = .fullGym,
        energy: EnergyLevel = .medium
    ) async throws -> GeneratedWorkout {
        let service = DeterministicCoachService()
        let response = try await service.generateWorkout(
            context: CoachContext(equipment: equipment),
            preferences: QuestionnaireAnswers(
                timeMinutes: minutes,
                focus: focus,
                energyLevel: energy,
                equipment: equipment
            )
        )
        return response.workout
    }

    func testGeneratedVolumeGrowsWithEveryDurationStep() async throws {
        var previous = 0
        for minutes in durations {
            let workout = try await generate(minutes: minutes)
            let sets = workout.exercises.reduce(0) { $0 + $1.sets }
            XCTAssertGreaterThan(
                sets,
                previous,
                "\(minutes) min should prescribe more total sets than the step below it"
            )
            previous = sets
        }
    }

    func testGeneratedLongSessionHasMoreMovementsThanShortSession() async throws {
        let short = try await generate(minutes: 20)
        let long = try await generate(minutes: 90)
        XCTAssertGreaterThan(long.exercises.count, short.exercises.count)
    }

    /// A workout that fails validation gets swapped for a fixed safe template,
    /// which is how long requests used to silently collapse back to a short
    /// session. Every combination must survive validation untouched.
    func testGeneratedWorkoutsValidateAcrossEveryDurationAndEquipment() async throws {
        for minutes in durations {
            for equipment in EquipmentAccess.userSelectableDefaults {
                for focus in WorkoutFocus.allCasesForTesting {
                    let workout = try await generate(minutes: minutes, focus: focus, equipment: equipment)
                    XCTAssertTrue(
                        validateGeneratedWorkout(workout).isEmpty,
                        "\(equipment.rawValue)/\(focus.rawValue) at \(minutes) min: \(validateGeneratedWorkout(workout))"
                    )
                }
            }
        }
    }

    func testGeneratedWorkoutRespectsLowEnergySetCeiling() async throws {
        let workout = try await generate(minutes: 90, energy: .low)
        XCTAssertTrue(workout.exercises.allSatisfy { $0.sets <= 3 })
    }
}
