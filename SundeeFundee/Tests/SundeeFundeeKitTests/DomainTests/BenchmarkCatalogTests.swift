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

    func testStrengthBackSquat_IsScoredByLoad() {
        let strength = BenchmarkCatalog.benchmark(id: "strength-back-squat-1rm")
        XCTAssertNotNil(strength)
        XCTAssertEqual(strength?.scoringType, .load)
    }

    func testMuscleUpMaxReps_IsScoredByReps() {
        let muscleup = BenchmarkCatalog.benchmark(id: "gymnastics-max-muscle-ups")
        XCTAssertNotNil(muscleup)
        XCTAssertEqual(muscleup?.scoringType, .reps)
    }
}
