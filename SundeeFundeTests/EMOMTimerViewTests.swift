import Testing
import Foundation
@testable import SundeeFundee

@Suite("EMOMTimerView Static Helpers")
struct EMOMTimerViewTests {

    // MARK: - currentMinute

    @Test func currentMinuteAtZero() {
        #expect(EMOMTimerView.currentMinute(elapsedSeconds: 0, intervalSeconds: 60) == 1)
    }

    @Test func currentMinuteAfter59Seconds() {
        #expect(EMOMTimerView.currentMinute(elapsedSeconds: 59, intervalSeconds: 60) == 1)
    }

    @Test func currentMinuteAfter60Seconds() {
        #expect(EMOMTimerView.currentMinute(elapsedSeconds: 60, intervalSeconds: 60) == 2)
    }

    @Test func currentMinuteAfter121Seconds() {
        #expect(EMOMTimerView.currentMinute(elapsedSeconds: 121, intervalSeconds: 60) == 3)
    }

    @Test func currentMinuteWithZeroInterval() {
        #expect(EMOMTimerView.currentMinute(elapsedSeconds: 30, intervalSeconds: 0) == 1)
    }

    // MARK: - timeWithinInterval

    @Test func timeWithinIntervalAtStart() {
        #expect(EMOMTimerView.timeWithinInterval(elapsedSeconds: 0, intervalSeconds: 60) == 0)
    }

    @Test func timeWithinIntervalMidway() {
        #expect(EMOMTimerView.timeWithinInterval(elapsedSeconds: 35, intervalSeconds: 60) == 35)
    }

    @Test func timeWithinIntervalAtBoundary() {
        #expect(EMOMTimerView.timeWithinInterval(elapsedSeconds: 60, intervalSeconds: 60) == 0)
    }

    @Test func timeWithinIntervalSecondMinute() {
        #expect(EMOMTimerView.timeWithinInterval(elapsedSeconds: 75, intervalSeconds: 60) == 15)
    }

    @Test func timeWithinIntervalZeroInterval() {
        #expect(EMOMTimerView.timeWithinInterval(elapsedSeconds: 30, intervalSeconds: 0) == 0)
    }

    // MARK: - exerciseIndex

    @Test func exerciseIndexFirstMinute() {
        #expect(EMOMTimerView.exerciseIndex(minute: 1, exerciseCount: 3) == 0)
    }

    @Test func exerciseIndexSecondMinute() {
        #expect(EMOMTimerView.exerciseIndex(minute: 2, exerciseCount: 3) == 1)
    }

    @Test func exerciseIndexWrapsAround() {
        #expect(EMOMTimerView.exerciseIndex(minute: 4, exerciseCount: 3) == 0)
    }

    @Test func exerciseIndexWithZeroExercises() {
        #expect(EMOMTimerView.exerciseIndex(minute: 1, exerciseCount: 0) == 0)
    }

    @Test func exerciseIndexCyclesThroughAll() {
        #expect(EMOMTimerView.exerciseIndex(minute: 3, exerciseCount: 3) == 2)
        #expect(EMOMTimerView.exerciseIndex(minute: 6, exerciseCount: 3) == 2)
    }

    // MARK: - formatElapsedTime

    @Test func formatElapsedTimeZero() {
        #expect(EMOMTimerView.formatElapsedTime(0) == "0:00")
    }

    @Test func formatElapsedTimeOneMinute() {
        #expect(EMOMTimerView.formatElapsedTime(60) == "1:00")
    }

    @Test func formatElapsedTimeWithSeconds() {
        #expect(EMOMTimerView.formatElapsedTime(95) == "1:35")
    }

    @Test func formatElapsedTimePadsSingleDigit() {
        #expect(EMOMTimerView.formatElapsedTime(5) == "0:05")
    }
}
