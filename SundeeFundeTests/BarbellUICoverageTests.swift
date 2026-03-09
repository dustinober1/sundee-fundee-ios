import Testing
import Foundation
@testable import SundeeFundee

// MARK: - Helpers (mirror BarbellViewModelCoverageTests)

private func makeExercise(
    name: String = "Back Squat",
    sets: ExerciseValue = .fixed(3),
    reps: ExerciseValue = .fixed(5),
    percent1RM: Double? = nil,
    restMinutes: Double? = 2
) -> ProgramExercise {
    ProgramExercise(
        exercise: name,
        variant: nil,
        sets: sets,
        reps: reps,
        percent1RM: percent1RM,
        restMinutes: restMinutes,
        notes: nil
    )
}

private func makeSession(id: String = "s1") -> ProgramSession {
    ProgramSession(
        sessionID: id,
        sessionName: "Session \(id)",
        sessionType: "strength",
        focus: "Lower",
        exercises: [makeExercise()]
    )
}

private func makeWeek(_ week: Int, sessions: [ProgramSession]) -> ProgramWeek {
    ProgramWeek(week: week, phaseID: "", isTestWeek: false, sessions: sessions)
}

private func makeProgram(id: String = "p1", weeks: [ProgramWeek]) -> Program {
    Program(
        id: id,
        name: "Program \(id)",
        category: "Strength",
        description: "",
        durationWeeks: weeks.count,
        sessionsPerWeek: weeks.first?.sessions.count ?? 1,
        difficulty: "beginner",
        phases: [],
        cycleAdjustmentProfile: nil,
        weeks: weeks
    )
}

@MainActor
private func makeVM() -> WorkoutExecutionViewModel {
    let session = makeSession()
    let program = makeProgram(weeks: [makeWeek(1, sessions: [session])])
    let enrollment = EnrolledProgram(id: "e1", userID: "u1", programID: "p1", startDate: .now)
    return WorkoutExecutionViewModel(
        session: session,
        enrollment: enrollment,
        program: program
    )
}

// MARK: - PlateCalculatorSheet.presetLabel

@Suite("PlateCalculatorSheet.presetLabel")
struct PlateCalculatorSheetPresetLabelTests {

    @Test func labelWithPounds() {
        let preset = BarbellPresetDTO(
            id: "1", userID: "u1", name: "Standard",
            weightKg: 20.0, isBuiltIn: true, sortOrder: 0
        )
        let label = PlateCalculatorSheet.presetLabel(preset: preset, weightUnit: .pounds)
        #expect(label.contains("Standard"))
        #expect(label.contains("lb"))
    }

    @Test func labelWithKilograms() {
        let preset = BarbellPresetDTO(
            id: "2", userID: "u1", name: "Olympic",
            weightKg: 20.0, isBuiltIn: true, sortOrder: 0
        )
        let label = PlateCalculatorSheet.presetLabel(preset: preset, weightUnit: .kilograms)
        #expect(label.contains("Olympic"))
        #expect(label.contains("kg"))
        #expect(label.contains("20"))
    }
}

// MARK: - BarbellPresetsView.weightLabel

@Suite("BarbellPresetsView.weightLabel")
struct BarbellPresetsViewWeightLabelTests {

    @Test func labelWithPounds() {
        let preset = BarbellPresetDTO(
            id: "1", userID: "u1", name: "Standard",
            weightKg: 20.0, isBuiltIn: true, sortOrder: 0
        )
        let label = BarbellPresetsView.weightLabel(preset: preset, weightUnit: .pounds)
        #expect(label.contains("lb"))
    }

    @Test func labelWithKilograms() {
        let preset = BarbellPresetDTO(
            id: "2", userID: "u1", name: "Standard",
            weightKg: 20.0, isBuiltIn: true, sortOrder: 0
        )
        let label = BarbellPresetsView.weightLabel(preset: preset, weightUnit: .kilograms)
        #expect(label.contains("kg"))
        #expect(label.contains("20"))
    }
}

// MARK: - AddBarbellSheet.canSave

@Suite("AddBarbellSheet.canSave")
struct AddBarbellSheetCanSaveTests {

    @Test func emptyNameReturnsFalse() {
        #expect(AddBarbellSheet.canSave(name: "", weightValue: "10") == false)
    }

    @Test func whitespaceOnlyNameReturnsFalse() {
        #expect(AddBarbellSheet.canSave(name: "   ", weightValue: "10") == false)
    }

    @Test func invalidWeightReturnsFalse() {
        #expect(AddBarbellSheet.canSave(name: "Bar", weightValue: "abc") == false)
    }

    @Test func zeroWeightReturnsFalse() {
        #expect(AddBarbellSheet.canSave(name: "Bar", weightValue: "0") == false)
    }

    @Test func negativeWeightReturnsFalse() {
        #expect(AddBarbellSheet.canSave(name: "Bar", weightValue: "-5") == false)
    }

    @Test func validInputReturnsTrue() {
        #expect(AddBarbellSheet.canSave(name: "My Bar", weightValue: "45") == true)
    }

    @Test func emptyWeightReturnsFalse() {
        #expect(AddBarbellSheet.canSave(name: "Bar", weightValue: "") == false)
    }
}

// MARK: - ExerciseSetCard.actualWeightPlateCalcAction

@Suite("ExerciseSetCard.actualWeightPlateCalcAction")
@MainActor
struct ExerciseSetCardActualWeightPlateCalcTests {

    @Test func actionUsesActualWeightWhenAvailable() {
        let vm = makeVM()
        let sets = [SetExecutionState(
            prescribedReps: "5",
            prescribedWeightKg: 80.0,
            actualWeightKg: 100.0
        )]
        let action = ExerciseSetCard.actualWeightPlateCalcAction(
            viewModel: vm, exerciseName: "Squat", setIndex: 0, sets: sets
        )
        action()
        #expect(vm.showPlateCalc == true)
        #expect(vm.plateCalcWeightKg == 100.0)
        #expect(vm.plateCalcExerciseName == "Squat")
    }

    @Test func actionFallsToPrescribedWeight() {
        let vm = makeVM()
        let sets = [SetExecutionState(
            prescribedReps: "5",
            prescribedWeightKg: 80.0,
            actualWeightKg: nil
        )]
        let action = ExerciseSetCard.actualWeightPlateCalcAction(
            viewModel: vm, exerciseName: "Bench", setIndex: 0, sets: sets
        )
        action()
        #expect(vm.plateCalcWeightKg == 80.0)
    }

    @Test func actionDefaultsToZeroWhenNoWeights() {
        let vm = makeVM()
        let sets = [SetExecutionState(
            prescribedReps: "5",
            prescribedWeightKg: nil,
            actualWeightKg: nil
        )]
        let action = ExerciseSetCard.actualWeightPlateCalcAction(
            viewModel: vm, exerciseName: "OHP", setIndex: 0, sets: sets
        )
        action()
        #expect(vm.plateCalcWeightKg == 0)
    }
}
