import XCTest
@testable import SundeeFundee

final class ProgramModelsTests: XCTestCase {

    // MARK: - ExerciseValue Decoding

    func testExerciseValue_decodesInt() throws {
        let json = "5"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(ExerciseValue.self, from: data)
        if case .fixed(let v) = value {
            XCTAssertEqual(v, 5)
        } else {
            XCTFail("Expected .fixed")
        }
    }

    func testExerciseValue_decodesAMRAP() throws {
        let json = "\"AMRAP\""
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(ExerciseValue.self, from: data)
        if case .amrap = value {
            // pass
        } else {
            XCTFail("Expected .amrap")
        }
    }

    func testExerciseValue_decodesRange() throws {
        let json = "[6, 8]"
        let data = json.data(using: .utf8)!
        let value = try JSONDecoder().decode(ExerciseValue.self, from: data)
        if case .range(let min, let max) = value {
            XCTAssertEqual(min, 6)
            XCTAssertEqual(max, 8)
        } else {
            XCTFail("Expected .range")
        }
    }

    func testExerciseValue_displayString() {
        XCTAssertEqual(ExerciseValue.fixed(5).displayString, "5")
        XCTAssertEqual(ExerciseValue.amrap.displayString, "AMRAP")
        XCTAssertEqual(ExerciseValue.range(6, 8).displayString, "6-8")
    }

    // MARK: - Full Program Decoding

    func testProgramV2_decodesFromJSON() throws {
        let json = """
        {
          "id": "test-program",
          "name": "Test Program",
          "category": "back-squat",
          "description": "A test program",
          "durationWeeks": 4,
          "sessionsPerWeek": 3,
          "difficulty": "beginner",
          "phases": [
            {
              "id": "phase-1",
              "name": "Phase One",
              "goal": "Build base",
              "weekRange": [1, 4]
            }
          ],
          "weeks": [
            {
              "week": 1,
              "phaseId": "phase-1",
              "sessions": [
                {
                  "sessionId": "w1-a",
                  "sessionName": "Session A",
                  "sessionType": "support",
                  "focus": "Strength",
                  "exercises": [
                    {
                      "exercise": "back-squat",
                      "sets": 3,
                      "reps": 5,
                      "percent1RM": 0.70,
                      "restMinutes": 3
                    }
                  ]
                }
              ]
            }
          ]
        }
        """

        let data = json.data(using: .utf8)!
        let program = try JSONDecoder().decode(ProgramV2.self, from: data)

        XCTAssertEqual(program.id, "test-program")
        XCTAssertEqual(program.name, "Test Program")
        XCTAssertEqual(program.durationWeeks, 4)
        XCTAssertEqual(program.phases.count, 1)
        XCTAssertEqual(program.weeks.count, 1)

        let session = program.weeks[0].sessions[0]
        XCTAssertEqual(session.exercises.count, 1)
        XCTAssertEqual(session.exercises[0].exercise, "back-squat")

        if case .fixed(let sets) = session.exercises[0].sets {
            XCTAssertEqual(sets, 3)
        } else {
            XCTFail("Expected .fixed for sets")
        }
    }

    // MARK: - Exercise Definitions

    func testExerciseDefinitions_findById() {
        let squat = Exercises.find(byId: "back-squat")
        XCTAssertNotNil(squat)
        XCTAssertEqual(squat?.name, "Back Squat")
    }

    func testExerciseDefinitions_notFound() {
        let result = Exercises.find(byId: "nonexistent")
        XCTAssertNil(result)
    }

    func testExerciseDefinitions_allHaveRequiredFields() {
        for exercise in Exercises.all {
            XCTAssertFalse(exercise.id.isEmpty)
            XCTAssertFalse(exercise.name.isEmpty)
            XCTAssertFalse(exercise.category.isEmpty)
            XCTAssertFalse(exercise.muscleGroups.isEmpty)
        }
    }
}
