import Testing
import Foundation
@testable import SundeeFundee

@Suite("ForTimeTimerView Static Helpers")
struct ForTimeTimerViewTests {

    // MARK: - formatElapsed

    @Test func formatElapsedZero() {
        #expect(ForTimeTimerView.formatElapsed(0) == "0:00")
    }

    @Test func formatElapsedOneMinute() {
        #expect(ForTimeTimerView.formatElapsed(60) == "1:00")
    }

    @Test func formatElapsedWithSeconds() {
        #expect(ForTimeTimerView.formatElapsed(125) == "2:05")
    }

    @Test func formatElapsedLargeValue() {
        #expect(ForTimeTimerView.formatElapsed(3661) == "61:01")
    }

    // MARK: - isOverTimeCap

    @Test func isOverTimeCapNilCap() {
        #expect(ForTimeTimerView.isOverTimeCap(elapsed: 999, capMinutes: nil) == false)
    }

    @Test func isOverTimeCapUnderCap() {
        #expect(ForTimeTimerView.isOverTimeCap(elapsed: 599, capMinutes: 10) == false)
    }

    @Test func isOverTimeCapExactlyCap() {
        #expect(ForTimeTimerView.isOverTimeCap(elapsed: 600, capMinutes: 10) == true)
    }

    @Test func isOverTimeCapOverCap() {
        #expect(ForTimeTimerView.isOverTimeCap(elapsed: 700, capMinutes: 10) == true)
    }

    // MARK: - isNearTimeCap

    @Test func isNearTimeCapNilCap() {
        #expect(ForTimeTimerView.isNearTimeCap(elapsed: 500, capMinutes: nil) == false)
    }

    @Test func isNearTimeCapFarFromCap() {
        #expect(ForTimeTimerView.isNearTimeCap(elapsed: 500, capMinutes: 10) == false)
    }

    @Test func isNearTimeCapWithin30Seconds() {
        #expect(ForTimeTimerView.isNearTimeCap(elapsed: 580, capMinutes: 10) == true)
    }

    @Test func isNearTimeCapExactlyAtThreshold() {
        #expect(ForTimeTimerView.isNearTimeCap(elapsed: 570, capMinutes: 10) == true)
    }

    @Test func isNearTimeCapAtCapIsNotNear() {
        // At cap, remaining is 0, which is not > 0
        #expect(ForTimeTimerView.isNearTimeCap(elapsed: 600, capMinutes: 10) == false)
    }

    @Test func isNearTimeCapOverCapIsNotNear() {
        #expect(ForTimeTimerView.isNearTimeCap(elapsed: 650, capMinutes: 10) == false)
    }

    @Test func isNearTimeCapCustomThreshold() {
        // 10 min cap = 600s, elapsed 540 => remaining 60, threshold 60 => near
        #expect(ForTimeTimerView.isNearTimeCap(elapsed: 540, capMinutes: 10, thresholdSeconds: 60) == true)
        // remaining 61 > threshold 60 => not near
        #expect(ForTimeTimerView.isNearTimeCap(elapsed: 539, capMinutes: 10, thresholdSeconds: 60) == false)
    }
}
