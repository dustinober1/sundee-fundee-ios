import Testing
import Foundation
@testable import SundeeFundee

@Suite("CircuitGroupView Static Helpers")
struct CircuitGroupViewTests {

    // MARK: - Helper

    private static func makeExercise(_ name: String) -> ProgramExercise {
        ProgramExercise(exercise: name, variant: nil, sets: .fixed(3),
                        reps: .fixed(10), percent1RM: nil, restMinutes: nil,
                        notes: nil, bodyweightOnly: false)
    }

    // MARK: - groupExercises

    @Test func groupExercisesEmpty() {
        let groups = CircuitHelpers.groupExercises([])
        #expect(groups.isEmpty)
    }

    @Test func groupExercisesSingleExercise() {
        let exercises = [Self.makeExercise("A")]
        let groups = CircuitHelpers.groupExercises(exercises)
        #expect(groups.count == 1)
        #expect(groups[0].count == 1)
    }

    @Test func groupExercisesDefault() {
        let exercises = [
            Self.makeExercise("A"),
            Self.makeExercise("B"),
            Self.makeExercise("C"),
            Self.makeExercise("D")
        ]
        let groups = CircuitHelpers.groupExercises(exercises)
        #expect(groups.count == 2)
        #expect(groups[0].count == 2)
        #expect(groups[1].count == 2)
        #expect(groups[0][0].exercise == "A")
        #expect(groups[0][1].exercise == "B")
        #expect(groups[1][0].exercise == "C")
        #expect(groups[1][1].exercise == "D")
    }

    @Test func groupExercisesGroupSizeThree() {
        let exercises = [
            Self.makeExercise("A"),
            Self.makeExercise("B"),
            Self.makeExercise("C"),
            Self.makeExercise("D"),
            Self.makeExercise("E")
        ]
        let groups = CircuitHelpers.groupExercises(exercises, groupSize: 3)
        #expect(groups.count == 2)
        #expect(groups[0].count == 3)
        #expect(groups[1].count == 2)
    }

    @Test func groupExercisesExactMultiple() {
        let exercises = [Self.makeExercise("A"), Self.makeExercise("B"), Self.makeExercise("C")]
        let groups = CircuitHelpers.groupExercises(exercises, groupSize: 3)
        #expect(groups.count == 1)
        #expect(groups[0].count == 3)
    }

    @Test func groupExercisesGroupSizeOne() {
        let exercises = [Self.makeExercise("A"), Self.makeExercise("B")]
        let groups = CircuitHelpers.groupExercises(exercises, groupSize: 1)
        #expect(groups.count == 2)
        #expect(groups[0].count == 1)
        #expect(groups[1].count == 1)
    }

    // MARK: - roundProgressText

    @Test func roundProgressTextBasic() {
        #expect(CircuitHelpers.roundProgressText(currentRound: 1, totalRounds: 3) == "Round 1 of 3")
    }

    @Test func roundProgressTextLastRound() {
        #expect(CircuitHelpers.roundProgressText(currentRound: 5, totalRounds: 5) == "Round 5 of 5")
    }

    @Test func roundProgressTextSingleRound() {
        #expect(CircuitHelpers.roundProgressText(currentRound: 1, totalRounds: 1) == "Round 1 of 1")
    }
}
