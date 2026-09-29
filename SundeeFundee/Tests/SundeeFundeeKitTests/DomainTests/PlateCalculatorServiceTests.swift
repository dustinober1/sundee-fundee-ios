import Foundation
import Testing
@testable import SundeeFundeeKit

@Suite("PlateCalculatorService")
struct PlateCalculatorServiceTests {

    @Test func standard135lbsCalculatesCorrectly() {
        let result = PlateCalculatorService.calculate(
            targetWeight: 135,
            barWeight: 45,
            availablePlates: PlateCalculatorService.defaultImperialPlates
        )

        #expect(result.targetWeight == 135)
        #expect(result.barWeight == 45)
        #expect(result.weightPerSide == 45)
        #expect(result.totalLoadedWeight == 135)
        #expect(result.isExact == true)
        #expect(result.remainder == 0)
        #expect(result.platesPerSide == [PlateCount(weight: 45, countPerSide: 1)])
    }

    @Test func standard185lbsCalculatesCorrectly() {
        let result = PlateCalculatorService.calculate(
            targetWeight: 185,
            barWeight: 45,
            availablePlates: PlateCalculatorService.defaultImperialPlates
        )

        #expect(result.weightPerSide == 70)
        #expect(result.totalLoadedWeight == 185)
        #expect(result.isExact == true)
        #expect(result.platesPerSide == [
            PlateCount(weight: 45, countPerSide: 1),
            PlateCount(weight: 25, countPerSide: 1)
        ])
    }

    @Test func standard225lbsCalculatesCorrectly() {
        let result = PlateCalculatorService.calculate(
            targetWeight: 225,
            barWeight: 45,
            availablePlates: PlateCalculatorService.defaultImperialPlates
        )

        #expect(result.weightPerSide == 90)
        #expect(result.totalLoadedWeight == 225)
        #expect(result.isExact == true)
        #expect(result.platesPerSide == [
            PlateCount(weight: 45, countPerSide: 2)
        ])
    }

    @Test func weightEqualOrLessThanBarWeight() {
        let exactBar = PlateCalculatorService.calculate(
            targetWeight: 45,
            barWeight: 45,
            availablePlates: PlateCalculatorService.defaultImperialPlates
        )
        #expect(exactBar.weightPerSide == 0)
        #expect(exactBar.platesPerSide.isEmpty)
        #expect(exactBar.isExact == true)
        #expect(exactBar.totalLoadedWeight == 45)

        let underBar = PlateCalculatorService.calculate(
            targetWeight: 30,
            barWeight: 45,
            availablePlates: PlateCalculatorService.defaultImperialPlates
        )
        #expect(underBar.weightPerSide == 0)
        #expect(underBar.platesPerSide.isEmpty)
        #expect(underBar.isExact == false)
        #expect(underBar.remainder == -15)
        #expect(underBar.totalLoadedWeight == 45)
    }

    @Test func techniqueBar35lbsCalculatesCorrectly() {
        let result = PlateCalculatorService.calculate(
            targetWeight: 95,
            barWeight: 35,
            availablePlates: PlateCalculatorService.defaultImperialPlates
        )

        #expect(result.barWeight == 35)
        #expect(result.weightPerSide == 30) // (95 - 35) / 2 = 30 -> 1x25 + 1x5
        #expect(result.totalLoadedWeight == 95)
        #expect(result.isExact == true)
        #expect(result.platesPerSide == [
            PlateCount(weight: 25, countPerSide: 1),
            PlateCount(weight: 5, countPerSide: 1)
        ])
    }

    @Test func metricCalculations() {
        let result = PlateCalculatorService.calculate(
            targetWeight: 100,
            barWeight: 20,
            availablePlates: PlateCalculatorService.defaultMetricPlates
        )

        // 100 - 20 = 80 -> 40 per side -> 1x25 + 1x15 (or 2x20 if 20 is first in inventory)
        #expect(result.barWeight == 20)
        #expect(result.weightPerSide == 40)
        #expect(result.totalLoadedWeight == 100)
        #expect(result.isExact == true)
        #expect(result.platesPerSide == [
            PlateCount(weight: 25, countPerSide: 1),
            PlateCount(weight: 15, countPerSide: 1)
        ])
    }

    @Test func handlesOddWeightWithRemainder() {
        // Target 182 with 45 lb bar: needs 137 -> 68.5 per side.
        // Available plates lowest is 2.5: 45 + 20 (no 35) -> 45 + 10 + 10 + 2.5 = 67.5 per side (135 + 45 = 180 total). Remainder = 2.0.
        let result = PlateCalculatorService.calculate(
            targetWeight: 182,
            barWeight: 45,
            availablePlates: [45.0, 25.0, 10.0, 5.0, 2.5]
        )

        #expect(result.isExact == false)
        #expect(result.totalLoadedWeight == 180)
        #expect(result.remainder == 2)
        #expect(result.platesPerSide == [
            PlateCount(weight: 45, countPerSide: 1),
            PlateCount(weight: 10, countPerSide: 2),
            PlateCount(weight: 2.5, countPerSide: 1)
        ])
    }
}
