import XCTest
@testable import SundeeFundeeKit

final class CelebrationEventTests: XCTestCase {

    // MARK: - celebrationTitle

    func testTitle_WorkoutCompleted() {
        let event = CelebrationEvent.workoutCompleted(durationSeconds: 3600)
        XCTAssertEqual(celebrationTitle(event), "Workout Complete!")
    }

    func testTitle_NewPersonalRecord() {
        let event = CelebrationEvent.newPersonalRecord(exerciseName: "Back Squat", weightKg: 100)
        XCTAssertEqual(celebrationTitle(event), "New Personal Record!")
    }

    func testTitle_ProgramCompleted() {
        let event = CelebrationEvent.programCompleted(programName: "Strength Block")
        XCTAssertEqual(celebrationTitle(event), "Program Complete!")
    }

    func testTitle_WeightMilestone() {
        let event = CelebrationEvent.weightMilestone(exerciseName: "Deadlift", thresholdKg: 200)
        XCTAssertEqual(celebrationTitle(event), "Weight Milestone!")
    }

    func testTitle_NewConditioningPR() {
        let event = CelebrationEvent.newConditioningPR(exerciseName: "Fran", value: 300, scoringType: .time)
        XCTAssertEqual(celebrationTitle(event), "New Conditioning PR!")
    }

    // MARK: - celebrationSubtitle

    func testSubtitle_WorkoutCompleted_ShowsMinutes() {
        let event = CelebrationEvent.workoutCompleted(durationSeconds: 3600)
        let sub = celebrationSubtitle(event)
        XCTAssertTrue(sub.contains("60 min"))
    }

    func testSubtitle_WorkoutCompleted_ShortDuration() {
        let event = CelebrationEvent.workoutCompleted(durationSeconds: 30)
        XCTAssertEqual(celebrationSubtitle(event), "Workout saved!")
    }

    func testSubtitle_WorkoutCompleted_Exactly60Seconds() {
        let event = CelebrationEvent.workoutCompleted(durationSeconds: 60)
        let sub = celebrationSubtitle(event)
        XCTAssertTrue(sub.contains("1 min"))
    }

    func testSubtitle_NewPersonalRecord_Kg() {
        let event = CelebrationEvent.newPersonalRecord(exerciseName: "Back Squat", weightKg: 100)
        let sub = celebrationSubtitle(event, unit: "kg")
        XCTAssertTrue(sub.contains("Back Squat"))
        XCTAssertTrue(sub.contains("100 kg"))
        XCTAssertTrue(sub.contains("estimated 1RM"))
    }

    func testSubtitle_NewPersonalRecord_Lb() {
        let event = CelebrationEvent.newPersonalRecord(exerciseName: "Deadlift", weightKg: 100)
        let sub = celebrationSubtitle(event, unit: "lb")
        XCTAssertTrue(sub.contains("lb"))
        XCTAssertFalse(sub.contains("100 kg"))
    }

    func testSubtitle_ProgramCompleted() {
        let event = CelebrationEvent.programCompleted(programName: "Stronglift 5x5")
        let sub = celebrationSubtitle(event)
        XCTAssertTrue(sub.contains("Stronglift 5x5"))
        XCTAssertTrue(sub.contains("level up"))
    }

    func testSubtitle_WeightMilestone_Kg() {
        let event = CelebrationEvent.weightMilestone(exerciseName: "Bench Press", thresholdKg: 100)
        let sub = celebrationSubtitle(event, unit: "kg")
        XCTAssertTrue(sub.contains("Bench Press"))
        XCTAssertTrue(sub.contains("100"))
    }

    func testSubtitle_WeightMilestone_Lb() {
        let event = CelebrationEvent.weightMilestone(exerciseName: "Bench Press", thresholdKg: 100)
        let sub = celebrationSubtitle(event, unit: "lb")
        XCTAssertTrue(sub.contains("lb"))
    }

    func testSubtitle_ConditioningPR_Time() {
        let event = CelebrationEvent.newConditioningPR(exerciseName: "Fran", value: 185, scoringType: .time)
        let sub = celebrationSubtitle(event)
        XCTAssertTrue(sub.contains("Fran"))
        XCTAssertTrue(sub.contains("3:05"))
    }

    func testSubtitle_ConditioningPR_Reps() {
        let event = CelebrationEvent.newConditioningPR(exerciseName: "Cindy", value: 15, scoringType: .reps)
        let sub = celebrationSubtitle(event)
        XCTAssertTrue(sub.contains("15 reps"))
    }

    func testSubtitle_ConditioningPR_RoundsAndReps() {
        let event = CelebrationEvent.newConditioningPR(exerciseName: "Cindy", value: 150003, scoringType: .roundsAndReps)
        let sub = celebrationSubtitle(event)
        XCTAssertTrue(sub.contains("15 rounds"))
        XCTAssertTrue(sub.contains("3 reps"))
    }
}
