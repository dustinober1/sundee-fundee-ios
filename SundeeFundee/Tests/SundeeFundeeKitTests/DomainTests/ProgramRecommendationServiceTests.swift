import XCTest
@testable import SundeeFundeeKit

final class ProgramRecommendationServiceTests: XCTestCase {
    func testBandsOnlyRecommendsCoachPlanAheadOfBarbellPrograms() {
        let recommendations = ProgramRecommendationService.recommend(
            goal: .strength,
            experience: .intermediate,
            daysPerWeek: 3,
            equipment: .resistanceBands
        )

        XCTAssertEqual(recommendations.first?.kind, .coachPlan(equipment: .resistanceBands))
        XCTAssertFalse(recommendations.prefix(1).contains { $0.kind == .program(.russianSquat) })
    }

    func testDumbbellsRecommendDumbbellStrengthProgram() {
        let recommendations = ProgramRecommendationService.recommend(
            goal: .strength,
            experience: .intermediate,
            daysPerWeek: 4,
            equipment: .homeDumbbells
        )

        XCTAssertEqual(recommendations.first?.kind, .program(.dumbbellStrength))
    }

    func testBeginnerFullGymRecommendsBeginnerStrength() {
        let recommendations = ProgramRecommendationService.recommend(
            goal: .strength,
            experience: .beginner,
            daysPerWeek: 3,
            equipment: .fullGym
        )

        XCTAssertEqual(recommendations.first?.kind, .program(.beginnerStrength))
    }
}
