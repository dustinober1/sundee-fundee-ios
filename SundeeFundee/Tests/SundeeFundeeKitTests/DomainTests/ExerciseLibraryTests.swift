import XCTest
@testable import SundeeFundeeKit

final class ExerciseLibraryTests: XCTestCase {

    private let equipment = EquipmentAccess.userSelectableDefaults

    /// A pool smaller than the movement-count ceiling forces long sessions to
    /// repeat themselves, which is what made every duration look alike.
    func testEveryPoolCanFillAFullLengthSession() {
        for equipment in equipment {
            for focus in WorkoutFocus.allCasesForTesting {
                for energy in [EnergyLevel.low, .medium, .high] {
                    let pool = workoutExercisePool(focus: focus, equipment: equipment, energyLevel: energy)
                    XCTAssertGreaterThanOrEqual(
                        pool.count,
                        WorkoutVolumePlanner.defaultMaxExercises,
                        "\(equipment.rawValue)/\(focus.rawValue)/\(energy.rawValue) has only \(pool.count) candidates"
                    )
                }
            }
        }
    }

    /// Validation caps how much of one pattern a session may contain, and the
    /// cap is tightest for the unfocused days. A pool with too few patterns
    /// cannot fill a long session without tripping it.
    func testPoolsSpanEnoughPatternsForTheirValidationCap() {
        let required: [WorkoutFocus: Int] = [
            .fullBody: 3, .conditioning: 3, .upperBody: 2, .lowerBody: 2
        ]
        for equipment in equipment {
            for (focus, minimum) in required {
                let patterns = Set(
                    workoutExercisePool(focus: focus, equipment: equipment, energyLevel: .low)
                        .map(\.pattern)
                )
                XCTAssertGreaterThanOrEqual(
                    patterns.count,
                    minimum,
                    "\(equipment.rawValue)/\(focus.rawValue) spans only \(patterns.count) patterns"
                )
            }
        }
    }

    /// `movementPattern(for:)` resolves a name by first match across every pool,
    /// so a name carrying two different patterns would make validation disagree
    /// with selection. Same for the bodyweight flag, which drives rest times.
    func testExerciseNamesCarryConsistentMetadataAcrossPools() {
        var seen: [String: WorkoutExerciseCandidate] = [:]
        for equipment in EquipmentAccess.allPoolCasesForTesting {
            for focus in WorkoutFocus.allCasesForTesting {
                for candidate in workoutExercisePool(focus: focus, equipment: equipment, energyLevel: .high) {
                    guard let existing = seen[candidate.name] else {
                        seen[candidate.name] = candidate
                        continue
                    }
                    XCTAssertEqual(existing.pattern, candidate.pattern, "\(candidate.name) has two movement patterns")
                    XCTAssertEqual(existing.bodyweightOnly, candidate.bodyweightOnly, "\(candidate.name) has two bodyweight flags")
                }
            }
        }
    }

    func testEveryPoolCandidateIsLegalForItsEquipment() {
        for equipment in equipment {
            for focus in WorkoutFocus.allCasesForTesting {
                for candidate in workoutExercisePool(focus: focus, equipment: equipment, energyLevel: .high) {
                    XCTAssertTrue(
                        isExerciseAllowed(candidate.name, for: equipment),
                        "\(candidate.name) is in the \(equipment.rawValue) pool but not on its allowlist"
                    )
                }
            }
        }
    }

    func testGeneratedExercisesAreAlsoLoggableFromTheCatalog() {
        let catalogIDs = Set(trainingExerciseCatalog.map(\.id))
        let missing = knownWorkoutExerciseNames().subtracting(catalogIDs).sorted()
        XCTAssertTrue(missing.isEmpty, "Not searchable in the exercise picker: \(missing)")
    }

    func testCatalogHasNoDuplicateEntries() {
        let ids = trainingExerciseCatalog.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }
}

extension EquipmentAccess {
    /// Every case that maps to a distinct pool, including `.outdoor`.
    static let allPoolCasesForTesting: [EquipmentAccess] =
        userSelectableDefaults + [.outdoor]
}
