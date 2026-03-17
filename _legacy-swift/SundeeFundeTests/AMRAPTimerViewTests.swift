import Testing
import Foundation
@testable import SundeeFundee

@Suite("AMRAPTimerView Static Helpers")
struct AMRAPTimerViewTests {

    // MARK: - formatTimeRemaining

    @Test func formatTimeRemainingFullMinutes() {
        #expect(AMRAPTimerView.formatTimeRemaining(720) == "12:00")
    }

    @Test func formatTimeRemainingWithSeconds() {
        #expect(AMRAPTimerView.formatTimeRemaining(125) == "2:05")
    }

    @Test func formatTimeRemainingZero() {
        #expect(AMRAPTimerView.formatTimeRemaining(0) == "0:00")
    }

    @Test func formatTimeRemainingSingleDigitSeconds() {
        #expect(AMRAPTimerView.formatTimeRemaining(61) == "1:01")
    }

    @Test func formatTimeRemainingLargeValue() {
        #expect(AMRAPTimerView.formatTimeRemaining(3599) == "59:59")
    }

    // MARK: - roundDisplayText

    @Test func roundDisplayTextNoReps() {
        #expect(AMRAPTimerView.roundDisplayText(round: 3, reps: 0) == "Round 3")
    }

    @Test func roundDisplayTextWithReps() {
        #expect(AMRAPTimerView.roundDisplayText(round: 2, reps: 7) == "Round 2 + 7 reps")
    }

    @Test func roundDisplayTextFirstRound() {
        #expect(AMRAPTimerView.roundDisplayText(round: 1, reps: 0) == "Round 1")
    }

    @Test func roundDisplayTextOneRep() {
        #expect(AMRAPTimerView.roundDisplayText(round: 5, reps: 1) == "Round 5 + 1 reps")
    }

    // MARK: - extractTimeCap

    @Test func extractTimeCapFromTextReps() {
        let exercises = [
            ProgramExercise(exercise: "Timer", variant: nil, sets: .fixed(1),
                            reps: .text("15 min"), percent1RM: nil, restMinutes: nil, notes: nil)
        ]
        #expect(AMRAPTimerView.extractTimeCap(from: exercises) == 15)
    }

    @Test func extractTimeCapNoMinText() {
        let exercises = [
            ProgramExercise(exercise: "Squats", variant: nil, sets: .fixed(3),
                            reps: .fixed(10), percent1RM: nil, restMinutes: nil, notes: nil)
        ]
        #expect(AMRAPTimerView.extractTimeCap(from: exercises) == 12)
    }

    @Test func extractTimeCapEmptyExercises() {
        #expect(AMRAPTimerView.extractTimeCap(from: []) == 12)
    }

    @Test func extractTimeCapMinSuffix() {
        let exercises = [
            ProgramExercise(exercise: "Timer", variant: nil, sets: .fixed(1),
                            reps: .text("20min"), percent1RM: nil, restMinutes: nil, notes: nil)
        ]
        #expect(AMRAPTimerView.extractTimeCap(from: exercises) == 20)
    }

    @Test func extractTimeCapNonNumericTextFallsThrough() {
        let exercises = [
            ProgramExercise(exercise: "Timer", variant: nil, sets: .fixed(1),
                            reps: .text("as many as possible"), percent1RM: nil, restMinutes: nil, notes: nil)
        ]
        #expect(AMRAPTimerView.extractTimeCap(from: exercises) == 12)
    }

    @Test func extractTimeCapUsesFirstMatch() {
        let exercises = [
            ProgramExercise(exercise: "Squats", variant: nil, sets: .fixed(3),
                            reps: .fixed(10), percent1RM: nil, restMinutes: nil, notes: nil),
            ProgramExercise(exercise: "Timer1", variant: nil, sets: .fixed(1),
                            reps: .text("8 min"), percent1RM: nil, restMinutes: nil, notes: nil),
            ProgramExercise(exercise: "Timer2", variant: nil, sets: .fixed(1),
                            reps: .text("20 min"), percent1RM: nil, restMinutes: nil, notes: nil)
        ]
        #expect(AMRAPTimerView.extractTimeCap(from: exercises) == 8)
    }
}
