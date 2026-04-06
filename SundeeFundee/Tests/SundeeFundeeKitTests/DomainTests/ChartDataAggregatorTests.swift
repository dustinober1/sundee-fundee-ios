import Testing
import Foundation
@testable import SundeeFundeeKit

// MARK: - Test Helpers

private let calendar = Calendar.current

private func makeDate(year: Int, month: Int, day: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
}

private func makeWorkout(
    date: Date,
    completedAt: Date? = nil,
    volume: Double = 0
) -> Workout {
    let sets: [ExerciseSet]
    if volume > 0 {
        // Create a single set with the desired volume: reps * weight = volume
        sets = [ExerciseSet(
            reps: 1,
            prescribedWeight: volume,
            type: .fixed,
            completedWeight: volume
        )]
    } else {
        sets = []
    }
    return Workout(
        id: UUID().uuidString,
        date: date,
        name: "Test Workout",
        exercises: [
            Exercise(
                id: UUID().uuidString,
                name: "Squat",
                category: .compound,
                bodyweight: 0,
                targetSets: sets
            )
        ],
        completedAt: completedAt
    )
}

private func makeORM(
    exerciseName: String,
    weight: Double,
    unit: WeightUnit = .lbs,
    date: Date
) -> OneRepMaxRecord {
    OneRepMaxRecord(
        id: UUID().uuidString,
        exerciseName: exerciseName,
        weight: weight,
        unit: unit,
        date: date
    )
}

private func makePhase(
    phase: CyclePhase,
    confidence: Double = 0.9,
    start: Date,
    end: Date
) -> CyclePhaseInfo {
    CyclePhaseInfo(phase: phase, confidence: confidence, startDate: start, endDate: end)
}

// MARK: - TimeRange Tests

@Suite("TimeRange startDate calculations")
struct TimeRangeTests {

    @Test("lastMonth is approximately 1 month ago")
    func lastMonth() {
        let now = makeDate(year: 2026, month: 4, day: 6)
        let start = TimeRange.lastMonth.startDate(relativeTo: now)
        let expected = calendar.date(byAdding: .month, value: -1, to: now)!
        #expect(calendar.isDate(start, inSameDayAs: expected))
    }

    @Test("lastThreeMonths is approximately 3 months ago")
    func lastThreeMonths() {
        let now = makeDate(year: 2026, month: 4, day: 6)
        let start = TimeRange.lastThreeMonths.startDate(relativeTo: now)
        let expected = calendar.date(byAdding: .month, value: -3, to: now)!
        #expect(calendar.isDate(start, inSameDayAs: expected))
    }

    @Test("lastSixMonths is approximately 6 months ago")
    func lastSixMonths() {
        let now = makeDate(year: 2026, month: 4, day: 6)
        let start = TimeRange.lastSixMonths.startDate(relativeTo: now)
        let expected = calendar.date(byAdding: .month, value: -6, to: now)!
        #expect(calendar.isDate(start, inSameDayAs: expected))
    }

    @Test("lastYear is approximately 1 year ago")
    func lastYear() {
        let now = makeDate(year: 2026, month: 4, day: 6)
        let start = TimeRange.lastYear.startDate(relativeTo: now)
        let expected = calendar.date(byAdding: .year, value: -1, to: now)!
        #expect(calendar.isDate(start, inSameDayAs: expected))
    }

    @Test("allTime is distant past")
    func allTime() {
        let now = makeDate(year: 2026, month: 4, day: 6)
        let start = TimeRange.allTime.startDate(relativeTo: now)
        #expect(start == Date.distantPast)
    }
}

// MARK: - Strength Progression Tests

@Suite("Strength Progression")
struct StrengthProgressionTests {

    let refDate = makeDate(year: 2026, month: 4, day: 6)

    @Test("empty input returns empty array")
    func emptyInput() {
        let result = ChartDataAggregator.strengthProgression(
            from: [], timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.isEmpty)
    }

    @Test("single exercise produces sorted data points")
    func singleExercise() {
        let records = [
            makeORM(exerciseName: "Bench Press", weight: 185, date: makeDate(year: 2026, month: 2, day: 1)),
            makeORM(exerciseName: "Bench Press", weight: 195, date: makeDate(year: 2026, month: 3, day: 1)),
            makeORM(exerciseName: "Bench Press", weight: 205, date: makeDate(year: 2026, month: 4, day: 1)),
        ]
        let result = ChartDataAggregator.strengthProgression(
            from: records, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 3)
        #expect(result[0].weight == 185)
        #expect(result[1].weight == 195)
        #expect(result[2].weight == 205)
        #expect(result.map(\.exerciseName).allSatisfy { $0 == "Bench Press" })
    }

    @Test("multiple exercises are all included sorted by date")
    func multipleExercises() {
        let records = [
            makeORM(exerciseName: "Squat", weight: 225, date: makeDate(year: 2026, month: 1, day: 15)),
            makeORM(exerciseName: "Bench Press", weight: 185, date: makeDate(year: 2026, month: 2, day: 1)),
            makeORM(exerciseName: "Deadlift", weight: 315, date: makeDate(year: 2026, month: 2, day: 10)),
        ]
        let result = ChartDataAggregator.strengthProgression(
            from: records, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 3)
        // Sorted by date
        #expect(result[0].exerciseName == "Squat")
        #expect(result[1].exerciseName == "Bench Press")
        #expect(result[2].exerciseName == "Deadlift")
    }

    @Test("time range filtering excludes old records")
    func timeRangeFiltering() {
        let records = [
            makeORM(exerciseName: "Bench Press", weight: 135, date: makeDate(year: 2025, month: 1, day: 1)),
            makeORM(exerciseName: "Bench Press", weight: 185, date: makeDate(year: 2026, month: 3, day: 1)),
            makeORM(exerciseName: "Bench Press", weight: 195, date: makeDate(year: 2026, month: 4, day: 1)),
        ]
        let result = ChartDataAggregator.strengthProgression(
            from: records, timeRange: .lastSixMonths, referenceDate: refDate
        )
        // Jan 2025 is more than 6 months before April 2026, so should be filtered out
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.weight > 150 })
    }

    @Test("preserves weight unit")
    func preservesUnit() {
        let records = [
            makeORM(exerciseName: "Squat", weight: 100, unit: .kg, date: makeDate(year: 2026, month: 3, day: 1)),
        ]
        let result = ChartDataAggregator.strengthProgression(
            from: records, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 1)
        #expect(result[0].unit == .kg)
    }
}

// MARK: - Training Volume Tests

@Suite("Training Volume")
struct TrainingVolumeTests {

    let refDate = makeDate(year: 2026, month: 4, day: 6)

    @Test("empty input returns empty array")
    func emptyInput() {
        let result = ChartDataAggregator.trainingVolume(
            from: [], timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.isEmpty)
    }

    @Test("incomplete workouts (completedAt nil) are excluded")
    func incompleteWorkoutsExcluded() {
        let workouts = [
            makeWorkout(date: makeDate(year: 2026, month: 3, day: 1), completedAt: nil, volume: 1000),
        ]
        let result = ChartDataAggregator.trainingVolume(
            from: workouts, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.isEmpty)
    }

    @Test("single completed workout produces one data point")
    func singleWorkout() {
        let completedDate = makeDate(year: 2026, month: 3, day: 1)
        let workouts = [
            makeWorkout(date: completedDate, completedAt: completedDate, volume: 5000),
        ]
        let result = ChartDataAggregator.trainingVolume(
            from: workouts, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 1)
        #expect(result[0].totalVolume == 5000)
        #expect(result[0].workoutCount == 1)
    }

    @Test("multiple workouts in the same week are aggregated")
    func sameWeekAggregation() {
        // Monday and Wednesday of the same ISO week
        let mon = makeDate(year: 2026, month: 3, day: 2)  // Monday
        let wed = makeDate(year: 2026, month: 3, day: 4)  // Wednesday

        let workouts = [
            makeWorkout(date: mon, completedAt: mon, volume: 3000),
            makeWorkout(date: wed, completedAt: wed, volume: 2000),
        ]
        let result = ChartDataAggregator.trainingVolume(
            from: workouts, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 1)
        #expect(result[0].totalVolume == 5000)
        #expect(result[0].workoutCount == 2)
    }

    @Test("workouts in different weeks produce separate data points")
    func crossWeekAggregation() {
        let week1 = makeDate(year: 2026, month: 2, day: 23)
        let week2 = makeDate(year: 2026, month: 3, day: 2)

        let workouts = [
            makeWorkout(date: week1, completedAt: week1, volume: 4000),
            makeWorkout(date: week2, completedAt: week2, volume: 3000),
        ]
        let result = ChartDataAggregator.trainingVolume(
            from: workouts, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 2)
        #expect(result[0].totalVolume == 4000)
        #expect(result[1].totalVolume == 3000)
    }

    @Test("time range filtering excludes old workouts")
    func timeRangeFiltering() {
        let old = makeDate(year: 2025, month: 6, day: 1)
        // refDate is April 6; lastMonth cutoff is ~March 6, so use March 15
        let recent = makeDate(year: 2026, month: 3, day: 15)

        let workouts = [
            makeWorkout(date: old, completedAt: old, volume: 5000),
            makeWorkout(date: recent, completedAt: recent, volume: 3000),
        ]
        let result = ChartDataAggregator.trainingVolume(
            from: workouts, timeRange: .lastMonth, referenceDate: refDate
        )
        #expect(result.count == 1)
        #expect(result[0].totalVolume == 3000)
    }

    @Test("zero volume workout still counts as a workout")
    func zeroVolumeWorkout() {
        let date = makeDate(year: 2026, month: 3, day: 1)
        let workouts = [
            makeWorkout(date: date, completedAt: date, volume: 0),
        ]
        let result = ChartDataAggregator.trainingVolume(
            from: workouts, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 1)
        #expect(result[0].totalVolume == 0)
        #expect(result[0].workoutCount == 1)
    }
}

// MARK: - Workout Frequency Tests

@Suite("Workout Frequency")
struct WorkoutFrequencyTests {

    let refDate = makeDate(year: 2026, month: 4, day: 6)

    @Test("empty input returns empty array")
    func emptyInput() {
        let result = ChartDataAggregator.workoutFrequency(
            from: [], timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.isEmpty)
    }

    @Test("incomplete workouts are excluded")
    func incompleteExcluded() {
        let workouts = [
            makeWorkout(date: makeDate(year: 2026, month: 3, day: 1), completedAt: nil, volume: 0),
        ]
        let result = ChartDataAggregator.workoutFrequency(
            from: workouts, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.isEmpty)
    }

    @Test("single workout produces one point with count 1")
    func singleWorkout() {
        let date = makeDate(year: 2026, month: 3, day: 1)
        let workouts = [
            makeWorkout(date: date, completedAt: date),
        ]
        let result = ChartDataAggregator.workoutFrequency(
            from: workouts, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 1)
        #expect(result[0].workoutCount == 1)
        #expect(result[0].label.hasPrefix("Week of"))
    }

    @Test("multiple workouts in same week aggregate count")
    func busyWeek() {
        let mon = makeDate(year: 2026, month: 3, day: 2)
        let tue = makeDate(year: 2026, month: 3, day: 3)
        let wed = makeDate(year: 2026, month: 3, day: 4)

        let workouts = [
            makeWorkout(date: mon, completedAt: mon),
            makeWorkout(date: tue, completedAt: tue),
            makeWorkout(date: wed, completedAt: wed),
        ]
        let result = ChartDataAggregator.workoutFrequency(
            from: workouts, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 1)
        #expect(result[0].workoutCount == 3)
    }

    @Test("results are sorted by week start date")
    func sortedOutput() {
        let week1 = makeDate(year: 2026, month: 2, day: 23)
        let week2 = makeDate(year: 2026, month: 3, day: 2)

        let workouts = [
            makeWorkout(date: week2, completedAt: week2),
            makeWorkout(date: week1, completedAt: week1),
        ]
        let result = ChartDataAggregator.workoutFrequency(
            from: workouts, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 2)
        #expect(result[0].weekStartDate < result[1].weekStartDate)
    }
}

// MARK: - Cycle Correlation Tests

@Suite("Cycle Correlation")
struct CycleCorrelationTests {

    let refDate = makeDate(year: 2026, month: 4, day: 6)

    @Test("empty inputs return empty array")
    func emptyInputs() {
        let result = ChartDataAggregator.cycleCorrelation(
            from: [], phases: [], timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.isEmpty)
    }

    @Test("workouts without matching phases produce empty result")
    func noMatchingPhases() {
        let workoutDate = makeDate(year: 2026, month: 3, day: 1)
        let workouts = [
            makeWorkout(date: workoutDate, completedAt: workoutDate, volume: 5000),
        ]
        // Phase is in January — won't match March workout
        let phases = [
            makePhase(phase: .follicular, start: makeDate(year: 2026, month: 1, day: 6), end: makeDate(year: 2026, month: 1, day: 12)),
        ]
        let result = ChartDataAggregator.cycleCorrelation(
            from: workouts, phases: phases, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.isEmpty)
    }

    @Test("workouts outside any phase date range are unmatched")
    func workoutsOutsidePhases() {
        let workoutDate = makeDate(year: 2026, month: 3, day: 20)
        let workouts = [
            makeWorkout(date: workoutDate, completedAt: workoutDate, volume: 3000),
        ]
        let phases = [
            makePhase(phase: .menstrual, start: makeDate(year: 2026, month: 3, day: 1), end: makeDate(year: 2026, month: 3, day: 5)),
            makePhase(phase: .luteal, start: makeDate(year: 2026, month: 3, day: 22), end: makeDate(year: 2026, month: 3, day: 28)),
        ]
        let result = ChartDataAggregator.cycleCorrelation(
            from: workouts, phases: phases, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.isEmpty)
    }

    @Test("single workout in a phase produces correct average")
    func singleWorkoutInPhase() {
        let workoutDate = makeDate(year: 2026, month: 3, day: 3)
        let workouts = [
            makeWorkout(date: workoutDate, completedAt: workoutDate, volume: 5000),
        ]
        let phases = [
            makePhase(phase: .menstrual, confidence: 0.85, start: makeDate(year: 2026, month: 3, day: 1), end: makeDate(year: 2026, month: 3, day: 5)),
        ]
        let result = ChartDataAggregator.cycleCorrelation(
            from: workouts, phases: phases, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 1)
        #expect(result[0].phase == .menstrual)
        #expect(result[0].averageVolume == 5000)
        #expect(result[0].workoutCount == 1)
        #expect(result[0].confidence == 0.85)
    }

    @Test("multiple workouts across phases produce correct averages")
    func multiplePhasesWithAverages() {
        let menstrualWorkout1 = makeDate(year: 2026, month: 3, day: 2)
        let menstrualWorkout2 = makeDate(year: 2026, month: 3, day: 3)
        let follicularWorkout = makeDate(year: 2026, month: 3, day: 10)

        let workouts = [
            makeWorkout(date: menstrualWorkout1, completedAt: menstrualWorkout1, volume: 2000),
            makeWorkout(date: menstrualWorkout2, completedAt: menstrualWorkout2, volume: 3000),
            makeWorkout(date: follicularWorkout, completedAt: follicularWorkout, volume: 6000),
        ]
        let phases = [
            makePhase(phase: .menstrual, confidence: 0.9, start: makeDate(year: 2026, month: 3, day: 1), end: makeDate(year: 2026, month: 3, day: 5)),
            makePhase(phase: .follicular, confidence: 0.8, start: makeDate(year: 2026, month: 3, day: 6), end: makeDate(year: 2026, month: 3, day: 14)),
        ]
        let result = ChartDataAggregator.cycleCorrelation(
            from: workouts, phases: phases, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.count == 2)

        let menstrual = result.first { $0.phase == .menstrual }!
        #expect(menstrual.averageVolume == 2500)
        #expect(menstrual.workoutCount == 2)
        #expect(menstrual.confidence == 0.9)

        let follicular = result.first { $0.phase == .follicular }!
        #expect(follicular.averageVolume == 6000)
        #expect(follicular.workoutCount == 1)
        #expect(follicular.confidence == 0.8)
    }

    @Test("incomplete workouts are excluded from correlation")
    func incompleteWorkoutsExcluded() {
        let date = makeDate(year: 2026, month: 3, day: 3)
        let workouts = [
            makeWorkout(date: date, completedAt: nil, volume: 5000),
        ]
        let phases = [
            makePhase(phase: .menstrual, start: makeDate(year: 2026, month: 3, day: 1), end: makeDate(year: 2026, month: 3, day: 5)),
        ]
        let result = ChartDataAggregator.cycleCorrelation(
            from: workouts, phases: phases, timeRange: .allTime, referenceDate: refDate
        )
        #expect(result.isEmpty)
    }

    @Test("time range filtering excludes old workouts")
    func timeRangeFiltering() {
        let oldDate = makeDate(year: 2025, month: 6, day: 3)
        // refDate is April 6; lastMonth cutoff is ~March 6, so use March 15
        let recentDate = makeDate(year: 2026, month: 3, day: 15)

        let workouts = [
            makeWorkout(date: oldDate, completedAt: oldDate, volume: 1000),
            makeWorkout(date: recentDate, completedAt: recentDate, volume: 5000),
        ]
        let phases = [
            makePhase(phase: .menstrual, start: makeDate(year: 2025, month: 6, day: 1), end: makeDate(year: 2025, month: 6, day: 5)),
            makePhase(phase: .menstrual, start: makeDate(year: 2026, month: 3, day: 13), end: makeDate(year: 2026, month: 3, day: 17)),
        ]
        let result = ChartDataAggregator.cycleCorrelation(
            from: workouts, phases: phases, timeRange: .lastMonth, referenceDate: refDate
        )
        #expect(result.count == 1)
        #expect(result[0].averageVolume == 5000)
        #expect(result[0].workoutCount == 1)
    }
}

// MARK: - Exercise Picker Tests

@Suite("Exercise Picker")
struct ExercisePickerTests {

    @Test("empty input returns empty array")
    func emptyInput() {
        let result = ChartDataAggregator.exercises(from: [])
        #expect(result.isEmpty)
    }

    @Test("returns unique sorted exercise names")
    func uniqueSorted() {
        let records = [
            makeORM(exerciseName: "Deadlift", weight: 315, date: Date()),
            makeORM(exerciseName: "Bench Press", weight: 185, date: Date()),
            makeORM(exerciseName: "Squat", weight: 225, date: Date()),
            makeORM(exerciseName: "Bench Press", weight: 195, date: Date()),
            makeORM(exerciseName: "Squat", weight: 235, date: Date()),
        ]
        let result = ChartDataAggregator.exercises(from: records)
        #expect(result == ["Bench Press", "Deadlift", "Squat"])
    }
}
