import XCTest
@testable import SundeeFundeeKit

final class ExerciseTechniqueLibraryTests: XCTestCase {

    func testEveryCueIsConciseAndWellFormed() {
        for (key, cue) in ExerciseTechniqueLibrary.cues {
            XCTAssertEqual(cue.exerciseName, key, "Cue keyed as \(key) is labelled \(cue.exerciseName)")
            XCTAssertTrue((2...4).contains(cue.setupCues.count), "\(key) should have 2 to 4 setup cues")
            XCTAssertTrue((1...3).contains(cue.commonMistakes.count), "\(key) should have 1 to 3 common mistakes")
            XCTAssertTrue(cue.setupCues.allSatisfy { !$0.isEmpty }, "\(key) has an empty setup cue")
            XCTAssertTrue(cue.commonMistakes.allSatisfy { !$0.isEmpty }, "\(key) has an empty mistake")
        }
    }

    /// A cue keyed to a name no exercise actually uses never renders, and
    /// nothing reports the mismatch — so typos are the real failure mode here.
    func testEveryCueIsKeyedToARealCatalogExercise() {
        let catalogIDs = Set(trainingExerciseCatalog.map(\.id))
        let orphaned = ExerciseTechniqueLibrary.cues.keys
            .filter { !catalogIDs.contains($0) }
            .sorted()
        XCTAssertTrue(orphaned.isEmpty, "Cues keyed to unknown exercises: \(orphaned)")
    }

    /// Coverage is partial by design, but the movement a session opens with is
    /// the one someone is most likely to be unsure about, so it must never be
    /// bare. This asserts the guarantee rather than a fixed exercise list, so it
    /// keeps holding as the generator's selection changes.
    func testEveryGeneratedSessionOpensWithACoveredMovement() {
        for equipment in EquipmentAccess.userSelectableDefaults {
            for focus in WorkoutFocus.allCasesForTesting {
                for energy in [EnergyLevel.low, .medium, .high] {
                    let result = QuickWorkoutBuilder.build(
                        request: QuickWorkoutRequest(
                            timeMinutes: 45,
                            focus: focus,
                            energyLevel: energy,
                            equipment: equipment,
                            todayDecisionKind: .modify,
                            painLogs: []
                        )
                    )
                    guard let opener = result.workout.exercises.first else {
                        XCTFail("\(equipment.rawValue)/\(focus.rawValue) generated nothing")
                        continue
                    }
                    XCTAssertNotNil(
                        ExerciseTechniqueLibrary.cue(for: opener.name),
                        "\(equipment.rawValue)/\(focus.rawValue)/\(energy.rawValue) opens with \(opener.name), which has no technique cue"
                    )
                }
            }
        }
    }

    func testTechniqueCopyAvoidsMedicalPromiseLanguage() {
        let bannedFragments = ["treat", "heal", "injury cure", "diagnose", "prevents injury"]

        for (key, cue) in ExerciseTechniqueLibrary.cues {
            let copy = cue.setupCues + cue.commonMistakes + [cue.regression].compactMap { $0 }
            for phrase in copy {
                let normalized = phrase.lowercased()
                for bannedFragment in bannedFragments {
                    XCTAssertFalse(
                        normalized.contains(bannedFragment),
                        "\(key) contains banned medical promise language: \(phrase)"
                    )
                }
            }
        }
    }

    func testShippedExerciseNameAliasesResolveToCanonicalCues() {
        let aliases = [
            ("Bench Press", "Flat Barbell Bench Press"),
            ("Romanian Deadlift", "Romanian Deadlift (No Straps)")
        ]

        for (alias, canonicalName) in aliases {
            let aliasCue = ExerciseTechniqueLibrary.cue(for: alias)
            let canonicalCue = ExerciseTechniqueLibrary.cue(for: canonicalName)

            XCTAssertNotNil(aliasCue, "Missing technique cue alias for \(alias)")
            XCTAssertEqual(aliasCue, canonicalCue)
        }
    }

    func testUnknownExerciseReturnsNil() {
        XCTAssertNil(ExerciseTechniqueLibrary.cue(for: "Mystery Lift"))
    }
}
