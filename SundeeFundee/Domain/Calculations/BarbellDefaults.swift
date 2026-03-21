import Foundation

enum BarbellDefaults {

    struct PresetDefinition {
        let name: String
        let weightKg: Double
        let sortOrder: Int
    }

    static let builtInPresets: [PresetDefinition] = [
        PresetDefinition(name: "Standard", weightKg: 45.0 / WeightUnitConversion.poundsPerKilogram, sortOrder: 0),
        PresetDefinition(name: "Women's", weightKg: 35.0 / WeightUnitConversion.poundsPerKilogram, sortOrder: 1),
        PresetDefinition(name: "Training", weightKg: 33.0 / WeightUnitConversion.poundsPerKilogram, sortOrder: 2),
        PresetDefinition(name: "EZ Curl", weightKg: 15.0 / WeightUnitConversion.poundsPerKilogram, sortOrder: 3),
    ]

    private static let ezCurlKeywords = ["curl", "tricep extension", "skull crush"]
    private static let compoundKeywords = ["squat", "bench press", "deadlift", "overhead press", "ohp", "barbell row", "bent over row", "front squat", "incline press"]

    static func suggestedPresetName(for exerciseName: String, gender: Gender?) -> String {
        let lower = exerciseName.lowercased()

        if ezCurlKeywords.contains(where: { lower.contains($0) }) {
            return "EZ Curl"
        }

        if compoundKeywords.contains(where: { lower.contains($0) }) {
            return gender == .female ? "Women's" : "Standard"
        }

        return "Standard"
    }
}
