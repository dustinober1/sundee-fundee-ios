import Testing
import Foundation
@testable import SundeeFundee

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
        let vm = makeBarbellTestVM()
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
        let vm = makeBarbellTestVM()
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
        let vm = makeBarbellTestVM()
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
