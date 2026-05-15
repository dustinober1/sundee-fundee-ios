import XCTest
@testable import SundeeFundeeKit

final class BenchmarkCatalogTests: XCTestCase {

    // MARK: - allBenchmarks

    func testAllBenchmarks_IsNotEmpty() {
        XCTAssertFalse(BenchmarkCatalog.allBenchmarks.isEmpty)
    }

    func testAllBenchmarks_MatchesWebCatalogCount() {
        XCTAssertEqual(BenchmarkCatalog.allBenchmarks.count, 31)
    }

    func testAllBenchmarks_AllHaveUniqueIDs() {
        let ids = BenchmarkCatalog.allBenchmarks.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "All benchmark IDs should be unique")
    }

    func testAllBenchmarks_AllArePredefined() {
        for bm in BenchmarkCatalog.allBenchmarks {
            XCTAssertTrue(bm.isPredefined, "\(bm.name) should be predefined")
        }
    }

    func testAllBenchmarks_AllHaveValidCategory() {
        let validCategories = Set(BenchmarkCategory.allCases.map(\.rawValue))
        for bm in BenchmarkCatalog.allBenchmarks {
            XCTAssertTrue(validCategories.contains(bm.category),
                         "\(bm.name) has invalid category: \(bm.category)")
        }
    }

    // MARK: - benchmark(id:)

    func testBenchmarkByID_ReturnsCorrectBenchmark() {
        let fran = BenchmarkCatalog.benchmark(id: "classic-fran")
        XCTAssertNotNil(fran)
        XCTAssertEqual(fran?.name, "Fran")
    }

    func testBenchmarkByID_ReturnsNilForUnknown() {
        XCTAssertNil(BenchmarkCatalog.benchmark(id: "nonexistent"))
    }

    func testBenchmarkByID_SundeeFundeeExclusive() {
        let vanessa = BenchmarkCatalog.benchmark(id: "sundee-vanessa")
        XCTAssertNotNil(vanessa)
        XCTAssertEqual(vanessa?.name, "Vanessa")
        XCTAssertEqual(vanessa?.category, BenchmarkCategory.sundeeFundee.rawValue)
        XCTAssertEqual(vanessa?.intensity, .five)
    }

    func testVanessaUsesUpdatedBikeErgLadder() {
        let vanessa = BenchmarkCatalog.benchmark(id: "sundee-vanessa")
        XCTAssertNotNil(vanessa)
        XCTAssertEqual(vanessa?.scoringType, .time)
        XCTAssertEqual(
            vanessa?.workoutDescription,
            "For time: 3-6-9-12-9-6-3 reps of Cleans (95/135 lb), Push Press (95/135 lb), and Burpees Over Bar; after each rung, complete 10 cal BikeERG."
        )
        XCTAssertEqual(vanessa?.equipment, ["barbell", "plates", "BikeERG"])
        XCTAssertTrue(vanessa?.movementTags?.contains("Barbell Cycling") ?? false)
        XCTAssertTrue(vanessa?.movementTags?.contains("Conditioning") ?? false)
        XCTAssertTrue(vanessa?.coachNotes?.contains("transitions") ?? false)
    }

    // MARK: - benchmarks(in:)

    func testBenchmarksByCategory_ReturnsCorrectCount() {
        let classics = BenchmarkCatalog.benchmarks(in: BenchmarkCategory.classicWODs.rawValue)
        XCTAssertEqual(classics.count, 9)
    }

    func testBenchmarksByCategory_ReturnsSortedBySortOrder() {
        let classics = BenchmarkCatalog.benchmarks(in: BenchmarkCategory.classicWODs.rawValue)
        for i in 1..<classics.count {
            XCTAssertLessThanOrEqual(classics[i - 1].sortOrder, classics[i].sortOrder,
                                     "Benchmarks should be sorted by sortOrder")
        }
    }

    func testBenchmarksByCategory_EmptyForInvalidCategory() {
        let results = BenchmarkCatalog.benchmarks(in: "Made Up Category")
        XCTAssertTrue(results.isEmpty)
    }

    func testBenchmarksByCategory_AllCategoriesHaveBenchmarks() {
        for category in BenchmarkCatalog.categories {
            let benchmarks = BenchmarkCatalog.benchmarks(in: category)
            XCTAssertFalse(benchmarks.isEmpty, "Category '\(category)' should have benchmarks")
        }
    }

    // MARK: - categories

    func testCategories_MatchesBenchmarkCategoryEnum() {
        let enumValues = BenchmarkCategory.allCases.map(\.rawValue)
        XCTAssertEqual(BenchmarkCatalog.categories, enumValues)
    }

    func testCategories_HasExpectedCount() {
        XCTAssertEqual(BenchmarkCatalog.categories.count, 6)
    }

    // MARK: - Specific benchmarks

    func testMurph_HasCorrectProperties() {
        let murph = BenchmarkCatalog.benchmark(id: "classic-murph")
        XCTAssertNotNil(murph)
        XCTAssertEqual(murph?.name, "Murph")
        XCTAssertEqual(murph?.scoringType, .time)
        XCTAssertEqual(murph?.intensity, .five)
        XCTAssertEqual(murph?.category, BenchmarkCategory.classicWODs.rawValue)
    }

    func testCindy_IsRoundsAndReps() {
        let cindy = BenchmarkCatalog.benchmark(id: "classic-cindy")
        XCTAssertNotNil(cindy)
        XCTAssertEqual(cindy?.scoringType, .roundsAndReps)
    }

    func testCindy_HasEnhancementFields() {
        let cindy = BenchmarkCatalog.benchmark(id: "classic-cindy")
        XCTAssertNotNil(cindy?.intensity)
        XCTAssertNotNil(cindy?.movementTags)
        XCTAssertNotNil(cindy?.coachNotes)
        XCTAssertEqual(cindy?.intensity, .three)
    }

    func testStrengthBackSquat_IsScoredByLoad() {
        let strength = BenchmarkCatalog.benchmark(id: "strength-back-squat-1rm")
        XCTAssertNotNil(strength)
        XCTAssertEqual(strength?.scoringType, .load)
    }

    func testStrengthBenchmarks_HaveIntensityFive() {
        let heavyLifts = ["strength-back-squat-1rm", "strength-conventional-deadlift-1rm",
                          "strength-bench-press-1rm", "strength-clean-and-jerk-1rm", "strength-snatch-1rm"]
        for id in heavyLifts {
            let bm = BenchmarkCatalog.benchmark(id: id)
            XCTAssertEqual(bm?.intensity, .five, "\(id) should have intensity 5")
        }
    }

    func testStrengthBenchmarks_HaveEquipment() {
        let benchmarks = BenchmarkCatalog.benchmarks(in: BenchmarkCategory.strength.rawValue)
        for bm in benchmarks {
            XCTAssertNotNil(bm.equipment, "\(bm.name) should have equipment list")
            XCTAssertFalse(bm.equipment?.isEmpty ?? true, "\(bm.name) equipment should not be empty")
        }
    }

    func testEnduranceBenchmarks_AreScoredByTime() {
        let benchmarks = BenchmarkCatalog.benchmarks(in: BenchmarkCategory.endurance.rawValue)
        for bm in benchmarks {
            XCTAssertEqual(bm.scoringType, .time,
                           "\(bm.name) should be scored by time (not distance — distance is fixed)")
        }
    }

    func testEnduranceBenchmarks_HaveCoachNotes() {
        let benchmarks = BenchmarkCatalog.benchmarks(in: BenchmarkCategory.endurance.rawValue)
        for bm in benchmarks {
            XCTAssertNotNil(bm.coachNotes, "\(bm.name) should have coach notes")
        }
    }

    func testMuscleUpMaxReps_IsScoredByReps() {
        let muscleup = BenchmarkCatalog.benchmark(id: "gymnastics-max-muscle-ups")
        XCTAssertNotNil(muscleup)
        XCTAssertEqual(muscleup?.scoringType, .reps)
        XCTAssertEqual(muscleup?.intensity, .five)
    }

    func testGymnasticsBenchmarks_HaveEnhancementFields() {
        let benchmarks = BenchmarkCatalog.benchmarks(in: BenchmarkCategory.gymnastics.rawValue)
        for bm in benchmarks {
            XCTAssertNotNil(bm.intensity, "\(bm.name) should have intensity")
            XCTAssertNotNil(bm.movementTags, "\(bm.name) should have movement tags")
            XCTAssertNotNil(bm.coachNotes, "\(bm.name) should have coach notes")
        }
    }

    func testAllBenchmarks_HaveIntensity() {
        for bm in BenchmarkCatalog.allBenchmarks {
            XCTAssertNotNil(bm.intensity, "\(bm.name) is missing intensity")
        }
    }

    func testAllBenchmarks_HaveCoachNotes() {
        for bm in BenchmarkCatalog.allBenchmarks {
            XCTAssertNotNil(bm.coachNotes, "\(bm.name) is missing coach notes")
            XCTAssertFalse(bm.coachNotes?.isEmpty ?? true, "\(bm.name) coach notes should not be empty")
        }
    }
}
