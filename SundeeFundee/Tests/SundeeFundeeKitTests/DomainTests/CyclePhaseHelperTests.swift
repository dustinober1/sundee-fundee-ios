import HealthKit
import XCTest
@testable import SundeeFundeeKit

final class CyclePhaseHelperTests: XCTestCase {

    // MARK: - convertToPeriodLogs

    func testConvertToPeriodLogs_EmptySamples() {
        let logs = CyclePhaseHelper.convertToPeriodLogs([])
        XCTAssertTrue(logs.isEmpty)
    }

    // MARK: - calculateConfidence

    func testConfidence_NoPeriodLogs() {
        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: 0,
            lastPeriodStart: nil
        )
        XCTAssertEqual(confidence, 0.0)
    }

    func testConfidence_OnePeriodLog_Recent() {
        let lastStart = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: 1,
            lastPeriodStart: lastStart
        )
        // 1 log = 0.4 base, recent = 1.0 multiplier
        XCTAssertEqual(confidence, 0.4, accuracy: 0.01)
    }

    func testConfidence_ThreePeriodLogs_Recent() {
        let lastStart = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: 3,
            lastPeriodStart: lastStart
        )
        // 3 logs = 0.8 base, recent = 1.0 multiplier
        XCTAssertEqual(confidence, 0.8, accuracy: 0.01)
    }

    func testConfidence_ManyPeriodLogs_Recent() {
        let lastStart = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: 6,
            lastPeriodStart: lastStart
        )
        // 6+ logs = 0.9 base, recent = 1.0 multiplier
        XCTAssertEqual(confidence, 0.9, accuracy: 0.01)
    }

    func testConfidence_StaleData() {
        let lastStart = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: 3,
            lastPeriodStart: lastStart
        )
        // 3 logs = 0.8 base, >60 days = 0.5 multiplier
        XCTAssertEqual(confidence, 0.4, accuracy: 0.01)
    }

    func testConfidence_ModeratelyStale() {
        let lastStart = Calendar.current.date(byAdding: .day, value: -45, to: Date())!
        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: 3,
            lastPeriodStart: lastStart
        )
        // 3 logs = 0.8 base, 35-60 days = 0.8 multiplier
        XCTAssertEqual(confidence, 0.64, accuracy: 0.01)
    }

    func testConfidence_WithBiomarkerConfirmation_BoostsConfidence() {
        let lastStart = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let biomarker = OvulationBiomarkerEvidence(
            lhSurgeDate: lastStart,
            estimatedOvulationDate: lastStart,
            hasThermalShift: true,
            thermalShiftCelsius: 0.32
        )
        let confidence = CyclePhaseHelper.calculateConfidence(
            periodLogCount: 1, // Without biomarker, would be 0.40
            lastPeriodStart: lastStart,
            biomarkerEvidence: biomarker
        )
        XCTAssertGreaterThanOrEqual(confidence, 0.95)
    }

    // MARK: - detectOvulationBiomarkers

    func testDetectOvulationBiomarkers_LHSurge() {
        let refDate = Date()
        let surgeDate = Calendar.current.date(byAdding: .day, value: -2, to: refDate)!
        let sample = MockHealthKitClient.createMockOvulationTestResult(
            startDate: surgeDate,
            endDate: surgeDate,
            value: HKCategoryValueOvulationTestResult.positive.rawValue
        )!

        let evidence = CyclePhaseHelper.detectOvulationBiomarkers(
            temperatureSamples: [],
            ovulationTestSamples: [sample],
            referenceDate: refDate
        )

        XCTAssertTrue(evidence.hasBiomarkerConfirmation)
        XCTAssertEqual(evidence.lhSurgeDate, surgeDate)
        XCTAssertNotNil(evidence.estimatedOvulationDate)
    }

    func testDetectOvulationBiomarkers_ThermalShift() {
        let refDate = Date()
        var tempSamples: [HKQuantitySample] = []

        // 4 days of baseline temp at 36.3°C
        for dayOffset in (4...7).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: refDate)!
            if let sample = MockHealthKitClient.createMockWristTemperature(startDate: date, endDate: date, celsius: 36.3) {
                tempSamples.append(sample)
            }
        }
        // 3 days of elevated temp at 36.65°C (+0.35°C shift)
        for dayOffset in (1...3).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: refDate)!
            if let sample = MockHealthKitClient.createMockWristTemperature(startDate: date, endDate: date, celsius: 36.65) {
                tempSamples.append(sample)
            }
        }

        let evidence = CyclePhaseHelper.detectOvulationBiomarkers(
            temperatureSamples: tempSamples,
            ovulationTestSamples: [],
            referenceDate: refDate
        )

        XCTAssertTrue(evidence.hasThermalShift)
        XCTAssertTrue(evidence.hasBiomarkerConfirmation)
        XCTAssertGreaterThanOrEqual(evidence.thermalShiftCelsius ?? 0, 0.20)
    }

    // MARK: - calculateCycleStatus with Biomarkers

    func testCalculateCycleStatus_BiomarkerRefinesPhaseToLuteal() {
        let refDate = Date()
        // Period 10 days ago (normally follicular in a 28-day cycle)
        let periodStart = Calendar.current.date(byAdding: .day, value: -10, to: refDate)!
        let periodEnd = Calendar.current.date(byAdding: .day, value: -6, to: refDate)!
        let logs = [PeriodLog(startDate: periodStart, endDate: periodEnd)]

        let statusWithoutBiomarker = calculateCycleStatus(
            periodLogs: logs,
            settings: CycleSettings(),
            referenceDate: refDate
        )
        XCTAssertEqual(statusWithoutBiomarker?.currentPhase, .follicular)

        // With thermal shift detected, user is confirmed to have ovulated and entered luteal phase
        let biomarker = OvulationBiomarkerEvidence(
            hasThermalShift: true,
            thermalShiftCelsius: 0.30
        )
        let statusWithBiomarker = calculateCycleStatus(
            periodLogs: logs,
            settings: CycleSettings(),
            referenceDate: refDate,
            biomarkerEvidence: biomarker
        )
        XCTAssertEqual(statusWithBiomarker?.currentPhase, .luteal)
    }
}
