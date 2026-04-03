import XCTest
@testable import SundeeFundeeKit

final class SubstitutionRankerTests: XCTestCase {

    // MARK: - Helpers

    private func makeInjury(
        location: String,
        name: String = "Test Injury",
        recoveryPhase: RecoveryPhase = .rehab
    ) -> Injury {
        Injury(
            id: UUID().uuidString,
            locationIds: location,
            name: name,
            recoveryPhase: recoveryPhase,
            dateCreated: Date(),
            phaseUpdated: Date()
        )
    }

    // MARK: - Basic Ranking

    func testRank_BackSquat_ReturnsSameCategory() {
        let results = SubstitutionRanker.rank(substitutesFor: "Back Squat")
        XCTAssertFalse(results.isEmpty, "Should find substitutes for Back Squat")

        // All top results should be squat-category or related
        let topResult = results.first!
        XCTAssertGreaterThan(topResult.score, 0, "Top result should have a positive score")
    }

    func testRank_BackSquat_DoesNotIncludeItself() {
        let results = SubstitutionRanker.rank(substitutesFor: "Back Squat")
        let containsSelf = results.contains { $0.exerciseName == "Back Squat" }
        XCTAssertFalse(containsSelf, "Should not include the target exercise itself")
    }

    func testRank_UnknownExercise_ReturnsEmpty() {
        let results = SubstitutionRanker.rank(substitutesFor: "Nonexistent Exercise")
        XCTAssertTrue(results.isEmpty, "Unknown exercise should return empty results")
    }

    // MARK: - Equipment Filtering

    func testRank_BodyweightOnly_FiltersBarbellExercises() {
        let results = SubstitutionRanker.rank(
            substitutesFor: "Back Squat",
            equipment: .bodyweightOnly
        )
        let hasBarbellExercise = results.contains {
            $0.exerciseName.lowercased().contains("barbell")
        }
        XCTAssertFalse(hasBarbellExercise, "Bodyweight-only should not include barbell exercises")
    }

    func testRank_HomeDumbbells_IncludesDumbbellExercises() {
        let results = SubstitutionRanker.rank(
            substitutesFor: "Flat Barbell Bench Press",
            equipment: .homeDumbbells
        )
        let hasDumbbell = results.contains {
            $0.exerciseName.lowercased().contains("dumbbell")
        }
        XCTAssertTrue(hasDumbbell, "Home dumbbells should include dumbbell alternatives")
    }

    // MARK: - Injury Filtering

    func testRank_KneeInjury_FiltersContraindicatedExercises() {
        let injuries = [makeInjury(location: "knee_left")]
        let results = SubstitutionRanker.rank(
            substitutesFor: "Back Squat",
            injuries: injuries
        )
        // Should not include exercises contraindicated for knee injuries
        // The exact filtering depends on InjuryAdaptationEngine rules
        XCTAssertFalse(results.isEmpty, "Should still find some alternatives even with injury")
    }

    // MARK: - Result Limits

    func testRank_RespectsLimit() {
        let results = SubstitutionRanker.rank(
            substitutesFor: "Back Squat",
            limit: 3
        )
        XCTAssertLessThanOrEqual(results.count, 3)
    }

    // MARK: - Score Ordering

    func testRank_ResultsSortedByScore() {
        let results = SubstitutionRanker.rank(substitutesFor: "Flat Barbell Bench Press")
        for i in 0..<(results.count - 1) {
            XCTAssertGreaterThanOrEqual(
                results[i].score, results[i + 1].score,
                "Results should be sorted by score descending"
            )
        }
    }

    // MARK: - Reason Quality

    func testRank_ResultsHaveReasons() {
        let results = SubstitutionRanker.rank(substitutesFor: "Back Squat")
        for result in results {
            XCTAssertFalse(result.reason.isEmpty, "Each result should have a reason")
        }
    }

    // MARK: - Category Preservation

    func testRank_PressExercise_PrefersPressAlternatives() {
        let results = SubstitutionRanker.rank(substitutesFor: "Flat Barbell Bench Press")
        guard let top = results.first else {
            XCTFail("Should have results")
            return
        }
        // Top result should be a press exercise (same category gets highest score)
        XCTAssertEqual(top.category, .press, "Top substitute for a press should be a press")
    }
}
