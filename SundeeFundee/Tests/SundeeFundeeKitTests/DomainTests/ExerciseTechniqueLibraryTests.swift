import XCTest
@testable import SundeeFundeeKit

final class ExerciseTechniqueLibraryTests: XCTestCase {
    private let coveredExerciseNames = [
        "Back Squat",
        "Goblet Squat",
        "Flat Barbell Bench Press",
        "Dumbbell Bench Press",
        "Romanian Deadlift (No Straps)",
        "Dumbbell Row",
        "Kettlebell Swing",
        "Push-Up"
    ]

    func testCoveredExercisesExposeConciseTechniqueCues() {
        for exerciseName in coveredExerciseNames {
            let cue = ExerciseTechniqueLibrary.cue(for: exerciseName)

            XCTAssertNotNil(cue, "Missing technique cue for \(exerciseName)")
            XCTAssertEqual(cue?.exerciseName, exerciseName)
            XCTAssertTrue((2...4).contains(cue?.setupCues.count ?? 0), "\(exerciseName) should have 2 to 4 setup cues")
            XCTAssertTrue((1...3).contains(cue?.commonMistakes.count ?? 0), "\(exerciseName) should have 1 to 3 common mistakes")
        }
    }

    func testTechniqueCopyAvoidsMedicalPromiseLanguage() {
        let bannedFragments = ["treat", "heal", "injury cure"]

        for exerciseName in coveredExerciseNames {
            guard let cue = ExerciseTechniqueLibrary.cue(for: exerciseName) else {
                XCTFail("Missing technique cue for \(exerciseName)")
                continue
            }

            let copy = cue.setupCues + cue.commonMistakes + [cue.regression].compactMap { $0 }
            for phrase in copy {
                let normalized = phrase.lowercased()
                for bannedFragment in bannedFragments {
                    XCTAssertFalse(
                        normalized.contains(bannedFragment),
                        "\(exerciseName) contains banned medical promise language: \(phrase)"
                    )
                }
            }
        }
    }

    func testUnknownExerciseReturnsNil() {
        XCTAssertNil(ExerciseTechniqueLibrary.cue(for: "Mystery Lift"))
    }
}
