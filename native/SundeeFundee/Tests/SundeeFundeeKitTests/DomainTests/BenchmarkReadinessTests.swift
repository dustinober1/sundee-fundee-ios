import XCTest
@testable import SundeeFundeeKit

final class BenchmarkReadinessTests: XCTestCase {

    // MARK: - No cycle data

    func testNoCyclePhase_ReturnsModerate() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: nil,
            benchmarkIntensity: .three,
            movementTags: nil
        )
        XCTAssertEqual(result.tier, .moderate)
        XCTAssertEqual(result.phaseMultiplier, 1.0, accuracy: 0.01)
    }

    // MARK: - Menstrual phase

    func testMenstrual_HighIntensity_ReturnsRecovery() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .menstrual,
            benchmarkIntensity: .four,
            movementTags: nil
        )
        XCTAssertEqual(result.tier, .recovery)
        XCTAssertEqual(result.phaseMultiplier, 0.85, accuracy: 0.01)
    }

    func testMenstrual_HeavyTag_ReturnsRecovery() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .menstrual,
            benchmarkIntensity: .two,
            movementTags: ["Heavy Lift"]
        )
        XCTAssertEqual(result.tier, .recovery)
    }

    func testMenstrual_HighCardioTag_ReturnsRecovery() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .menstrual,
            benchmarkIntensity: .two,
            movementTags: ["High Cardio"]
        )
        XCTAssertEqual(result.tier, .recovery)
    }

    func testMenstrual_LowIntensity_ReturnsModerate() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .menstrual,
            benchmarkIntensity: .two,
            movementTags: ["Skill"]
        )
        XCTAssertEqual(result.tier, .moderate)
    }

    // MARK: - Follicular phase

    func testFollicular_LowIntensity_ReturnsPeak() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .follicular,
            benchmarkIntensity: .two,
            movementTags: nil
        )
        XCTAssertEqual(result.tier, .peak)
        XCTAssertEqual(result.phaseMultiplier, 1.0, accuracy: 0.01)
    }

    func testFollicular_HighIntensity_ReturnsPeak() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .follicular,
            benchmarkIntensity: .five,
            movementTags: ["Max Effort"]
        )
        XCTAssertEqual(result.tier, .peak)
    }

    func testFollicular_HeavyTag_ReturnsPeak() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .follicular,
            benchmarkIntensity: .four,
            movementTags: ["Heavy Pull"]
        )
        XCTAssertEqual(result.tier, .peak)
    }

    // MARK: - Ovulation phase

    func testOvulation_AlwaysPeak() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .ovulation,
            benchmarkIntensity: .five,
            movementTags: ["Max Effort", "Heavy"]
        )
        XCTAssertEqual(result.tier, .peak)
        XCTAssertEqual(result.phaseMultiplier, 1.05, accuracy: 0.01)
    }

    func testOvulation_LowIntensity_StillPeak() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .ovulation,
            benchmarkIntensity: .one,
            movementTags: nil
        )
        XCTAssertEqual(result.tier, .peak)
    }

    // MARK: - Luteal phase

    func testLuteal_MaxIntensity_ReturnsRecovery() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .luteal,
            benchmarkIntensity: .five,
            movementTags: nil
        )
        XCTAssertEqual(result.tier, .recovery)
        XCTAssertEqual(result.phaseMultiplier, 0.95, accuracy: 0.01)
    }

    func testLuteal_HeavyTag_ReturnsRecovery() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .luteal,
            benchmarkIntensity: .three,
            movementTags: ["Heavy Lift"]
        )
        XCTAssertEqual(result.tier, .recovery)
    }

    func testLuteal_IntensityFour_ReturnsModerate() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .luteal,
            benchmarkIntensity: .four,
            movementTags: nil
        )
        XCTAssertEqual(result.tier, .moderate)
    }

    func testLuteal_LowIntensity_ReturnsModerate() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .luteal,
            benchmarkIntensity: .two,
            movementTags: nil
        )
        XCTAssertEqual(result.tier, .moderate)
    }

    // MARK: - Phase multipliers

    func testPhaseMultipliers_CorrectValues() {
        XCTAssertEqual(CyclePhaseMultiplier.multiplier(for: .menstrual), 0.85, accuracy: 0.01)
        XCTAssertEqual(CyclePhaseMultiplier.multiplier(for: .follicular), 1.0, accuracy: 0.01)
        XCTAssertEqual(CyclePhaseMultiplier.multiplier(for: .ovulation), 1.05, accuracy: 0.01)
        XCTAssertEqual(CyclePhaseMultiplier.multiplier(for: .luteal), 0.95, accuracy: 0.01)
    }

    // MARK: - getBestAttemptWindow

    func testBestAttemptWindow_28DayCycle() {
        let lastPeriod = makeDate(2026, 3, 1)
        let window = BenchmarkReadinessCalculator.getBestAttemptWindow(
            averageCycleLength: 28,
            lastPeriodStart: lastPeriod
        )
        // 28 * 0.45 = 12.6 -> 12, window: day 10 to day 14
        let expectedStart = Calendar.current.date(byAdding: .day, value: 10, to: lastPeriod)!
        let expectedEnd = Calendar.current.date(byAdding: .day, value: 14, to: lastPeriod)!
        XCTAssertEqual(window.startDate, expectedStart)
        XCTAssertEqual(window.endDate, expectedEnd)
    }

    func testBestAttemptWindow_35DayCycle() {
        let lastPeriod = makeDate(2026, 3, 1)
        let window = BenchmarkReadinessCalculator.getBestAttemptWindow(
            averageCycleLength: 35,
            lastPeriodStart: lastPeriod
        )
        // 35 * 0.45 = 15.75 -> 15, window: day 13 to day 17
        let expectedStart = Calendar.current.date(byAdding: .day, value: 13, to: lastPeriod)!
        let expectedEnd = Calendar.current.date(byAdding: .day, value: 17, to: lastPeriod)!
        XCTAssertEqual(window.startDate, expectedStart)
        XCTAssertEqual(window.endDate, expectedEnd)
    }

    func testBestAttemptWindow_ReasonMentionsOvulation() {
        let window = BenchmarkReadinessCalculator.getBestAttemptWindow(
            averageCycleLength: 28,
            lastPeriodStart: Date()
        )
        XCTAssertTrue(window.reason.lowercased().contains("ovulation"))
    }

    // MARK: - Nil defaults

    func testNilIntensity_DefaultsToThree() {
        // With nil intensity (defaults to .three), follicular should be peak
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .follicular,
            benchmarkIntensity: nil,
            movementTags: nil
        )
        XCTAssertEqual(result.tier, .peak)
    }

    func testNilMovementTags_DoesNotCrash() {
        let result = BenchmarkReadinessCalculator.calculateReadiness(
            phase: .menstrual,
            benchmarkIntensity: .five,
            movementTags: nil
        )
        XCTAssertEqual(result.tier, .recovery)
    }

    // MARK: - Helpers

    private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}
