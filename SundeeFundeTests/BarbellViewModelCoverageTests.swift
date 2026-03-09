import Testing
import Foundation
@testable import SundeeFundee

// MARK: - Mock

final class VMTestMockBarbellRepository: BarbellRepository {
    private var presets: [BarbellPresetDTO] = []
    private var mappings: [ExerciseBarMappingDTO] = []

    func fetchPresets(userID: String) throws -> [BarbellPresetDTO] {
        presets.filter { $0.userID == userID }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func savePreset(_ preset: BarbellPresetDTO) throws {
        presets.removeAll { $0.id == preset.id }
        presets.append(preset)
    }

    func deletePreset(id: String) throws {
        presets.removeAll { $0.id == id }
    }

    func fetchMapping(exerciseName: String, userID: String) throws -> ExerciseBarMappingDTO? {
        mappings.first { $0.exerciseName == exerciseName && $0.userID == userID }
    }

    func saveMapping(_ mapping: ExerciseBarMappingDTO) throws {
        mappings.removeAll { $0.exerciseName == mapping.exerciseName && $0.userID == mapping.userID }
        mappings.append(mapping)
    }

    func seedBuiltInPresets(userID: String) {
        let existing = (try? fetchPresets(userID: userID)) ?? []
        guard existing.isEmpty else { return }
        for def in BarbellDefaults.builtInPresets {
            try? savePreset(BarbellPresetDTO(
                id: UUID().uuidString,
                userID: userID,
                name: def.name,
                weightKg: def.weightKg,
                isBuiltIn: true,
                sortOrder: def.sortOrder
            ))
        }
    }
}

// MARK: - Helpers

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
private func makeVM(
    barbellRepo: BarbellRepository? = nil,
    userID: String = "",
    gender: Gender? = nil
) -> WorkoutExecutionViewModel {
    let session = makeSession()
    let program = makeProgram(weeks: [makeWeek(1, sessions: [session])])
    let enrollment = EnrolledProgram(id: "e1", userID: "u1", programID: "p1", startDate: .now)
    return WorkoutExecutionViewModel(
        session: session,
        enrollment: enrollment,
        program: program,
        barbellRepo: barbellRepo,
        userID: userID,
        gender: gender
    )
}

// MARK: - Tests

@Suite("WorkoutExecutionViewModel.PlateCalcForActual")
@MainActor
struct WorkoutExecVMPlateCalcTests {

    @Test func openPlateCalcForActualSetsProperties() {
        let vm = makeVM()
        vm.openPlateCalcForActual(exerciseName: "Squat", weightKg: 100.0)
        #expect(vm.showPlateCalc == true)
        #expect(vm.plateCalcWeightKg == 100.0)
        #expect(vm.plateCalcExerciseName == "Squat")
    }

    @Test func openPlateCalcForActualLooksUpMapping() {
        let repo = VMTestMockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        let ezID = presets.first { $0.name == "EZ Curl" }!.id
        try? repo.saveMapping(ExerciseBarMappingDTO(id: "m1", userID: "u1", exerciseName: "Curl", barbellPresetID: ezID))

        let vm = makeVM(barbellRepo: repo, userID: "u1")
        vm.loadBarbellPresets()
        vm.openPlateCalcForActual(exerciseName: "Curl", weightKg: 30.0)
        #expect(vm.selectedPresetID == ezID)
    }

    @Test func openPlateCalcForActualCreatesDefaultMapping() {
        let repo = VMTestMockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")

        let vm = makeVM(barbellRepo: repo, userID: "u1", gender: .male)
        vm.loadBarbellPresets()
        vm.openPlateCalcForActual(exerciseName: "Barbell Curl", weightKg: 30.0)

        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        let ezID = presets.first { $0.name == "EZ Curl" }!.id
        #expect(vm.selectedPresetID == ezID)
    }

    @Test func updateBarSelectionSavesMapping() {
        let repo = VMTestMockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        let womensID = presets.first { $0.name == "Women's" }!.id

        let vm = makeVM(barbellRepo: repo, userID: "u1")
        vm.loadBarbellPresets()
        vm.plateCalcExerciseName = "Squat"
        vm.updateBarSelection(presetID: womensID)

        let mapping = try? repo.fetchMapping(exerciseName: "Squat", userID: "u1")
        #expect(mapping?.barbellPresetID == womensID)
    }

    @Test func selectedBarbellWeightKgReturnsCorrectWeight() {
        let repo = VMTestMockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        let ezID = presets.first { $0.name == "EZ Curl" }!.id

        let vm = makeVM(barbellRepo: repo, userID: "u1")
        vm.loadBarbellPresets()
        vm.selectedPresetID = ezID

        let expectedKg = 15.0 / WeightUnitConversion.poundsPerKilogram
        #expect(abs(vm.selectedBarbellWeightKg - expectedKg) < 0.01)
    }

    @Test func selectedBarbellWeightKgFallsBackToStandard() {
        let vm = makeVM()
        #expect(abs(vm.selectedBarbellWeightKg - PlateCalculation.standardBarKg) < 0.01)
    }

    @Test func loadBarbellPresetsWithNoRepoIsNoOp() {
        let vm = makeVM()
        vm.loadBarbellPresets()
        #expect(vm.barbellPresets.isEmpty)
    }

    @Test func updateBarSelectionWithEmptyExerciseNameIsNoOp() {
        let repo = VMTestMockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")

        let vm = makeVM(barbellRepo: repo, userID: "u1")
        vm.loadBarbellPresets()
        vm.plateCalcExerciseName = ""
        vm.updateBarSelection(presetID: "some-id")

        // No mapping should be saved since exercise name is empty
        let mapping = try? repo.fetchMapping(exerciseName: "", userID: "u1")
        #expect(mapping == nil)
    }

    @Test func openPlateCalcForActualWithNoRepoStillShowsCalc() {
        let vm = makeVM()
        vm.openPlateCalcForActual(exerciseName: "Squat", weightKg: 80.0)
        #expect(vm.showPlateCalc == true)
        #expect(vm.selectedPresetID == nil)
    }

    @Test func openPlateCalcForActualFallsBackToFirstPreset() {
        let repo = VMTestMockBarbellRepository()
        // Add only a custom preset with a name that won't match suggestions
        try? repo.savePreset(BarbellPresetDTO(
            id: "custom1",
            userID: "u1",
            name: "Custom Bar",
            weightKg: 10.0,
            isBuiltIn: false,
            sortOrder: 0
        ))

        let vm = makeVM(barbellRepo: repo, userID: "u1", gender: .male)
        vm.loadBarbellPresets()
        // "Squat" suggests "Standard" but no preset named "Standard" exists
        vm.openPlateCalcForActual(exerciseName: "Squat", weightKg: 60.0)
        #expect(vm.selectedPresetID == "custom1")
    }
}
