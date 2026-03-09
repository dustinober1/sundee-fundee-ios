import Testing
import Foundation
@testable import SundeeFundee

@Suite("BarbellDefaults")
struct BarbellDefaultsTests {

    @Test func builtInPresetsHasFourEntries() {
        let presets = BarbellDefaults.builtInPresets
        #expect(presets.count == 4)
    }

    @Test func standardPresetIs45Lb() {
        let standard = BarbellDefaults.builtInPresets.first { $0.name == "Standard" }
        #expect(standard != nil)
        let expectedKg = 45.0 / WeightUnitConversion.poundsPerKilogram
        #expect(abs(standard!.weightKg - expectedKg) < 0.01)
    }

    @Test func womensPresetIs35Lb() {
        let womens = BarbellDefaults.builtInPresets.first { $0.name == "Women's" }
        #expect(womens != nil)
        let expectedKg = 35.0 / WeightUnitConversion.poundsPerKilogram
        #expect(abs(womens!.weightKg - expectedKg) < 0.01)
    }

    @Test func trainingPresetIs33Lb() {
        let training = BarbellDefaults.builtInPresets.first { $0.name == "Training" }
        #expect(training != nil)
        let expectedKg = 33.0 / WeightUnitConversion.poundsPerKilogram
        #expect(abs(training!.weightKg - expectedKg) < 0.01)
    }

    @Test func ezCurlPresetIs15Lb() {
        let ez = BarbellDefaults.builtInPresets.first { $0.name == "EZ Curl" }
        #expect(ez != nil)
        let expectedKg = 15.0 / WeightUnitConversion.poundsPerKilogram
        #expect(abs(ez!.weightKg - expectedKg) < 0.01)
    }

    @Test func curlExerciseSuggestsEZCurl() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Barbell Curl", gender: .male) == "EZ Curl")
        #expect(BarbellDefaults.suggestedPresetName(for: "EZ Bar Curl", gender: .female) == "EZ Curl")
        #expect(BarbellDefaults.suggestedPresetName(for: "Preacher Curl", gender: .male) == "EZ Curl")
    }

    @Test func tricepExtensionSuggestsEZCurl() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Tricep Extension", gender: .male) == "EZ Curl")
        #expect(BarbellDefaults.suggestedPresetName(for: "Overhead Tricep Extension", gender: .female) == "EZ Curl")
    }

    @Test func skullCrusherSuggestsEZCurl() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Skull Crusher", gender: .male) == "EZ Curl")
        #expect(BarbellDefaults.suggestedPresetName(for: "Lying Skull Crushers", gender: .female) == "EZ Curl")
    }

    @Test func compoundLiftFemaleDefaultsToWomens() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Back Squat", gender: .female) == "Women's")
        #expect(BarbellDefaults.suggestedPresetName(for: "Bench Press", gender: .female) == "Women's")
        #expect(BarbellDefaults.suggestedPresetName(for: "Deadlift", gender: .female) == "Women's")
        #expect(BarbellDefaults.suggestedPresetName(for: "Overhead Press", gender: .female) == "Women's")
        #expect(BarbellDefaults.suggestedPresetName(for: "Barbell Row", gender: .female) == "Women's")
    }

    @Test func compoundLiftMaleDefaultsToStandard() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Back Squat", gender: .male) == "Standard")
        #expect(BarbellDefaults.suggestedPresetName(for: "Bench Press", gender: .male) == "Standard")
        #expect(BarbellDefaults.suggestedPresetName(for: "Deadlift", gender: .male) == "Standard")
    }

    @Test func unknownExerciseDefaultsToStandard() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Some Weird Exercise", gender: .male) == "Standard")
        #expect(BarbellDefaults.suggestedPresetName(for: "Cable Fly", gender: .female) == "Standard")
    }

    @Test func preferNotToSayDefaultsToStandard() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Back Squat", gender: .preferNotToSay) == "Standard")
    }

    @Test func caseInsensitiveMatching() {
        #expect(BarbellDefaults.suggestedPresetName(for: "barbell curl", gender: .male) == "EZ Curl")
        #expect(BarbellDefaults.suggestedPresetName(for: "BENCH PRESS", gender: .female) == "Women's")
    }

    @Test func ezCurlPriorityOverCompound() {
        #expect(BarbellDefaults.suggestedPresetName(for: "Barbell Curl", gender: .female) == "EZ Curl")
    }
}
