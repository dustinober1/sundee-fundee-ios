import XCTest
@testable import SundeeFundeeKit

/// Guards exercise *identity*: that one movement has exactly one catalog ID, and
/// that a definition's metadata is stated rather than inferred from its name.
///
/// The catalog previously named seven movements twice (`Farmer Carry` /
/// `Farmers Carry`, `Dumbbell Curl` / `Bicep Curl (Dumbbell)`, …), which split a
/// user's logged sets and 1RM history across two IDs and showed both in search.
/// Nothing failed — every existing test passed — because coverage checked that
/// names resolved, not that they were unique.
final class ExerciseIdentityTests: XCTestCase {

    // MARK: - Uniqueness

    func testCatalogIDsAreUnique() {
        var seen = Set<String>()
        let repeated = trainingExerciseCatalog.map(\.id).filter { !seen.insert($0).inserted }
        XCTAssertTrue(repeated.isEmpty, "Duplicate catalog IDs: \(repeated)")
    }

    /// Two IDs that normalize to the same movement, share a movement pattern and
    /// share equipment are the same exercise wearing two names.
    ///
    /// Strap variants are the deliberate exception: `Romanian Deadlift (No
    /// Straps)` and `(With Straps)` are tracked separately on purpose.
    func testNoTwoEntriesDescribeTheSameMovement() {
        func normalized(_ id: String) -> String {
            var name = id.lowercased()
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "(", with: " ")
                .replacingOccurrences(of: ")", with: " ")
            for qualifier in ["barbell", "dumbbell", "kettlebell", "band", "cable", "machine"] {
                name = name.replacingOccurrences(of: qualifier, with: " ")
            }
            return name.split(separator: " ").joined(separator: " ")
        }

        var groups: [String: [String]] = [:]
        for definition in trainingExerciseCatalog {
            let id = definition.id
            guard !id.contains("Straps") else { continue }
            let key = "\(normalized(id))|\(definition.movementPattern)|\(definition.equipmentTags)"
            groups[key, default: []].append(id)
        }

        let collisions = groups.values.filter { $0.count > 1 }
        XCTAssertTrue(collisions.isEmpty, "Same movement under multiple IDs: \(collisions)")
    }

    // MARK: - Legacy Aliases

    func testEveryLegacyAliasResolvesToARealCatalogEntry() {
        let ids = Set(trainingExerciseCatalog.map(\.id))
        for (legacy, canonical) in legacyExerciseAliases {
            XCTAssertTrue(ids.contains(canonical), "Alias \(legacy) points at unknown ID \(canonical)")
            XCTAssertFalse(ids.contains(legacy), "Retired ID \(legacy) is still in the catalog")
        }
    }

    func testCanonicalExerciseIDPassesUnknownNamesThrough() {
        XCTAssertEqual(canonicalExerciseID("Back Squat"), "Back Squat")
        XCTAssertEqual(canonicalExerciseID("Not A Real Exercise"), "Not A Real Exercise")
        XCTAssertEqual(canonicalExerciseID("Farmer Carry"), "Farmers Carry")
    }

    /// A max logged under a retired ID has to keep matching after the collapse,
    /// otherwise the rename silently orphans PR history.
    func testMaxLoggedUnderARetiredIDStillMatchesTheCanonicalName() {
        let legacyMax = ExerciseMax(name: "Dumbbell Shoulder Press", weightKg: 40)
        XCTAssertEqual(findMatchingMax("Dumbbell Overhead Press", maxes: [legacyMax])?.name,
                       "Dumbbell Shoulder Press")
    }

    func testRetiredIDsStayMaxTrackable() {
        for legacy in legacyExerciseAliases.keys where isWeightliftingExercise(legacyExerciseAliases[legacy]!) {
            XCTAssertTrue(isWeightliftingExercise(legacy),
                          "\(legacy) lost max-trackability through the alias")
        }
    }

    // MARK: - Stated Metadata

    /// Conditioning metadata used to be inferred by substring match, which read
    /// "row" in `500m Row` and filed every erg distance under `.pull`.
    func testConditioningEntriesCarryStatedMetadata() {
        for entry in conditioningExercises {
            guard let definition = trainingExerciseCatalog.first(where: { $0.id == entry.id }) else {
                return XCTFail("\(entry.id) missing from catalog")
            }
            XCTAssertEqual(definition.defaultScoringType, entry.defaultScoringType)
        }

        for ergo in ["500m Row", "2K Row", "Rowing (Calories)"] {
            let definition = trainingExerciseCatalog.first { $0.id == ergo }
            XCTAssertEqual(definition?.movementPattern, .conditioning,
                           "\(ergo) should be conditioning, not a pulling movement")
        }
    }

    /// `bodyweightOnly` cannot be derived from `equipmentTags == [.bodyweight]`:
    /// weighted dips and weighted pull-ups use the bodyweight apparatus but take
    /// external load, and the logger skips the weight field when this is wrong.
    func testLoadedLiftsAreNotMarkedBodyweightOnly() {
        for loaded in ["Dips (Weighted)", "Weighted Pull-Up", "Thruster", "Wall Ball"] {
            let definition = trainingExerciseCatalog.first { $0.id == loaded }
            XCTAssertEqual(definition?.bodyweightOnly, false, "\(loaded) takes external load")
        }
        for unloaded in ["Pull-Up", "Air Squat", "Burpee", "Plank Hold"] {
            let definition = trainingExerciseCatalog.first { $0.id == unloaded }
            XCTAssertEqual(definition?.bodyweightOnly, true, "\(unloaded) carries no external load")
        }
    }

    /// The generator's pools and the catalog have to agree, or a session
    /// prescribes a load the logger will not ask for.
    func testPoolsAgreeWithCatalogOnPatternAndLoading() {
        let definitions = Dictionary(
            trainingExerciseCatalog.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        for candidate in allWorkoutCandidates() {
            guard let definition = definitions[candidate.name] else {
                return XCTFail("\(candidate.name) is in a pool but not the catalog")
            }
            XCTAssertEqual(definition.movementPattern, candidate.pattern,
                           "\(candidate.name) pattern disagrees between pool and catalog")
            XCTAssertEqual(definition.bodyweightOnly, candidate.bodyweightOnly,
                           "\(candidate.name) loading disagrees between pool and catalog")
        }
    }
}
