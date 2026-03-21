import Testing
import Foundation
@testable import SundeeFundee

@Suite("BarbellRepository")
struct BarbellRepositoryTests {

    @Test func fetchPresetsReturnsEmpty() {
        let repo = MockBarbellRepository()
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        #expect(presets.isEmpty)
    }

    @Test func saveAndFetchPreset() {
        let repo = MockBarbellRepository()
        let preset = BarbellPresetDTO(id: "p1", userID: "u1", name: "Standard", weightKg: 20.4, isBuiltIn: true, sortOrder: 0)
        try? repo.savePreset(preset)
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        #expect(presets.count == 1)
        #expect(presets.first?.name == "Standard")
    }

    @Test func deletePreset() {
        let repo = MockBarbellRepository()
        let preset = BarbellPresetDTO(id: "p1", userID: "u1", name: "Custom", weightKg: 10.0, isBuiltIn: false, sortOrder: 5)
        try? repo.savePreset(preset)
        try? repo.deletePreset(id: "p1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        #expect(presets.isEmpty)
    }

    @Test func fetchMappingReturnsNilWhenEmpty() {
        let repo = MockBarbellRepository()
        let mapping = try? repo.fetchMapping(exerciseName: "Squat", userID: "u1")
        #expect(mapping == nil)
    }

    @Test func saveAndFetchMapping() {
        let repo = MockBarbellRepository()
        let mapping = ExerciseBarMappingDTO(id: "m1", userID: "u1", exerciseName: "Squat", barbellPresetID: "p1")
        try? repo.saveMapping(mapping)
        let fetched = try? repo.fetchMapping(exerciseName: "Squat", userID: "u1")
        #expect(fetched?.barbellPresetID == "p1")
    }

    @Test func saveMappingUpdatesExisting() {
        let repo = MockBarbellRepository()
        let m1 = ExerciseBarMappingDTO(id: "m1", userID: "u1", exerciseName: "Squat", barbellPresetID: "p1")
        try? repo.saveMapping(m1)
        let m2 = ExerciseBarMappingDTO(id: "m1", userID: "u1", exerciseName: "Squat", barbellPresetID: "p2")
        try? repo.saveMapping(m2)
        let fetched = try? repo.fetchMapping(exerciseName: "Squat", userID: "u1")
        #expect(fetched?.barbellPresetID == "p2")
    }

    @Test func seedBuiltInPresetsCreatesDefaults() {
        let repo = MockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        #expect(presets.count == 4)
        #expect(presets.contains { $0.name == "Standard" })
        #expect(presets.contains { $0.name == "Women's" })
        #expect(presets.contains { $0.name == "Training" })
        #expect(presets.contains { $0.name == "EZ Curl" })
    }

    @Test func seedBuiltInPresetsIsIdempotent() {
        let repo = MockBarbellRepository()
        repo.seedBuiltInPresets(userID: "u1")
        repo.seedBuiltInPresets(userID: "u1")
        let presets = (try? repo.fetchPresets(userID: "u1")) ?? []
        #expect(presets.count == 4)
    }
}
