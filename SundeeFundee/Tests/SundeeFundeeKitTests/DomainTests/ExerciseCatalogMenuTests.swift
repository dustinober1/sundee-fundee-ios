import Foundation
import Testing
@testable import SundeeFundeeKit

// Verifies the catalog that feeds `ExerciseCatalogMenu` — every entry is
// uniquely identified, every category maps to at least one exercise, and
// a custom (off-catalog) name still round-trips through OneRepMaxRecord.

@Suite("ExerciseCatalog + Maxes entry")
struct ExerciseCatalogMenuTests {

    @Test("All catalog ids are unique")
    func uniqueIDs() {
        let ids = weightliftingExercises.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("Every category has at least one entry")
    func everyCategoryCovered() {
        for category in WeightliftingCategory.allCases {
            let count = weightliftingExercises.filter { $0.category == category }.count
            #expect(count > 0, "category \(category.rawValue) has no entries")
        }
    }

    @Test("Catalog entry round-trips through OneRepMaxRecord")
    func catalogRoundTrip() {
        let entry = weightliftingExercises.first { $0.category == .squat }
        let name = entry?.id ?? "Back Squat"
        let record = OneRepMaxRecord(
            id: UUID().uuidString,
            exerciseName: name,
            weight: 315,
            unit: .lbs,
            date: Date()
        )
        #expect(record.exerciseName == name)
    }

    @Test("Custom name (off-catalog) still valid in OneRepMaxRecord")
    func customNameAccepted() {
        let record = OneRepMaxRecord(
            id: UUID().uuidString,
            exerciseName: "Landmine Press",
            weight: 95,
            unit: .lbs,
            date: Date()
        )
        #expect(!record.exerciseName.isEmpty)
        #expect(weightliftingExercises.contains(where: { $0.id == record.exerciseName }) == false)
    }
}
