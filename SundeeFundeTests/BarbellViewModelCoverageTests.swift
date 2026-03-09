import Testing
import Foundation
@testable import SundeeFundee

// MARK: - Tests

@Suite("WorkoutExecutionViewModel.PlateCalcForActual")
@MainActor
struct WorkoutExecVMPlateCalcTests {

    @Test func openPlateCalcForActualSetsProperties() {
        let vm = makeBarbellTestVM()
        vm.openPlateCalcForActual(exerciseName: "Squat", weightKg: 100.0)
        #expect(vm.showPlateCalc == true)
        #expect(vm.plateCalcWeightKg == 100.0)
        #expect(vm.plateCalcExerciseName == "Squat")
    }

    @Test func openPlateCalcForActualLooksUpMapping() {
        let repo = MockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        let ezID = presets.first { $0.name == "EZ Curl" }!.id
        try? repo.saveMapping(ExerciseBarMappingDTO(id: "m1", userID: "u1", exerciseName: "Curl", barbellPresetID: ezID))

        let vm = makeBarbellTestVM(barbellRepo: repo, userID: "u1")
        vm.loadBarbellPresets()
        vm.openPlateCalcForActual(exerciseName: "Curl", weightKg: 30.0)
        #expect(vm.selectedPresetID == ezID)
    }

    @Test func openPlateCalcForActualCreatesDefaultMapping() {
        let repo = MockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")

        let vm = makeBarbellTestVM(barbellRepo: repo, userID: "u1", gender: .male)
        vm.loadBarbellPresets()
        vm.openPlateCalcForActual(exerciseName: "Barbell Curl", weightKg: 30.0)

        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        let ezID = presets.first { $0.name == "EZ Curl" }!.id
        #expect(vm.selectedPresetID == ezID)
    }

    @Test func updateBarSelectionSavesMapping() {
        let repo = MockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        let womensID = presets.first { $0.name == "Women's" }!.id

        let vm = makeBarbellTestVM(barbellRepo: repo, userID: "u1")
        vm.loadBarbellPresets()
        vm.plateCalcExerciseName = "Squat"
        vm.updateBarSelection(presetID: womensID)

        let mapping = try? repo.fetchMapping(exerciseName: "Squat", userID: "u1")
        #expect(mapping?.barbellPresetID == womensID)
    }

    @Test func selectedBarbellWeightKgReturnsCorrectWeight() {
        let repo = MockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        let ezID = presets.first { $0.name == "EZ Curl" }!.id

        let vm = makeBarbellTestVM(barbellRepo: repo, userID: "u1")
        vm.loadBarbellPresets()
        vm.selectedPresetID = ezID

        let expectedKg = 15.0 / WeightUnitConversion.poundsPerKilogram
        #expect(abs(vm.selectedBarbellWeightKg - expectedKg) < 0.01)
    }

    @Test func selectedBarbellWeightKgFallsBackToStandard() {
        let vm = makeBarbellTestVM()
        #expect(abs(vm.selectedBarbellWeightKg - PlateCalculation.standardBarKg) < 0.01)
    }

    @Test func loadBarbellPresetsWithNoRepoIsNoOp() {
        let vm = makeBarbellTestVM()
        vm.loadBarbellPresets()
        #expect(vm.barbellPresets.isEmpty)
    }

    @Test func updateBarSelectionWithEmptyExerciseNameIsNoOp() {
        let repo = MockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")

        let vm = makeBarbellTestVM(barbellRepo: repo, userID: "u1")
        vm.loadBarbellPresets()
        vm.plateCalcExerciseName = ""
        vm.updateBarSelection(presetID: "some-id")

        // No mapping should be saved since exercise name is empty
        let mapping = try? repo.fetchMapping(exerciseName: "", userID: "u1")
        #expect(mapping == nil)
    }

    @Test func openPlateCalcForActualWithNoRepoStillShowsCalc() {
        let vm = makeBarbellTestVM()
        vm.openPlateCalcForActual(exerciseName: "Squat", weightKg: 80.0)
        #expect(vm.showPlateCalc == true)
        #expect(vm.selectedPresetID == nil)
    }

    @Test func openPlateCalcForActualFallsBackToFirstPreset() {
        let repo = MockBarbellRepository()
        // Add only a custom preset with a name that won't match suggestions
        try? repo.savePreset(BarbellPresetDTO(
            id: "custom1",
            userID: "u1",
            name: "Custom Bar",
            weightKg: 10.0,
            isBuiltIn: false,
            sortOrder: 0
        ))

        let vm = makeBarbellTestVM(barbellRepo: repo, userID: "u1", gender: .male)
        vm.loadBarbellPresets()
        // "Squat" suggests "Standard" but no preset named "Standard" exists
        vm.openPlateCalcForActual(exerciseName: "Squat", weightKg: 60.0)
        #expect(vm.selectedPresetID == "custom1")
    }
}
