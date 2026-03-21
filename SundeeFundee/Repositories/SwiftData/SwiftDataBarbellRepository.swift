import SwiftData
import Foundation

final class SwiftDataBarbellRepository: BarbellRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchPresets(userID: String) throws -> [BarbellPresetDTO] {
        let descriptor = FetchDescriptor<BarbellPreset>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try context.fetch(descriptor).map {
            BarbellPresetDTO(id: $0.id, userID: $0.userID, name: $0.name, weightKg: $0.weightKg, isBuiltIn: $0.isBuiltIn, sortOrder: $0.sortOrder)
        }
    }

    func savePreset(_ preset: BarbellPresetDTO) throws {
        let presetID = preset.id
        let descriptor = FetchDescriptor<BarbellPreset>(
            predicate: #Predicate { $0.id == presetID }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.name = preset.name
            existing.weightKg = preset.weightKg
            existing.isBuiltIn = preset.isBuiltIn
            existing.sortOrder = preset.sortOrder
        } else {
            context.insert(BarbellPreset(
                id: preset.id,
                userID: preset.userID,
                name: preset.name,
                weightKg: preset.weightKg,
                isBuiltIn: preset.isBuiltIn,
                sortOrder: preset.sortOrder
            ))
        }
        try context.save()
    }

    func deletePreset(id: String) throws {
        let descriptor = FetchDescriptor<BarbellPreset>(
            predicate: #Predicate { $0.id == id }
        )
        if let preset = try context.fetch(descriptor).first {
            context.delete(preset)
            try context.save()
        }
    }

    func fetchMapping(exerciseName: String, userID: String) throws -> ExerciseBarMappingDTO? {
        let descriptor = FetchDescriptor<ExerciseBarMapping>(
            predicate: #Predicate { $0.exerciseName == exerciseName && $0.userID == userID }
        )
        return try context.fetch(descriptor).first.map {
            ExerciseBarMappingDTO(id: $0.id, userID: $0.userID, exerciseName: $0.exerciseName, barbellPresetID: $0.barbellPresetID)
        }
    }

    func saveMapping(_ mapping: ExerciseBarMappingDTO) throws {
        let exerciseName = mapping.exerciseName
        let userID = mapping.userID
        let descriptor = FetchDescriptor<ExerciseBarMapping>(
            predicate: #Predicate { $0.exerciseName == exerciseName && $0.userID == userID }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.barbellPresetID = mapping.barbellPresetID
        } else {
            context.insert(ExerciseBarMapping(
                id: mapping.id,
                userID: mapping.userID,
                exerciseName: mapping.exerciseName,
                barbellPresetID: mapping.barbellPresetID
            ))
        }
        try context.save()
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
