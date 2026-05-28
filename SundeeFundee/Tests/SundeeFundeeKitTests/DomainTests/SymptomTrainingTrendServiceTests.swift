import XCTest
@testable import SundeeFundeeKit

final class SymptomTrainingTrendServiceTests: XCTestCase {

    // MARK: - High cramps + missed workouts -> neutral pattern insight

    func testHighCrampsAndMissedWorkoutsProducesPatternInsight() {
        let symptoms = [
            makeSymptom(cramps: 8, fatigue: 4, energy: 3, dayOffset: 0),
            makeSymptom(cramps: 7, fatigue: 5, energy: 2, dayOffset: 1),
            makeSymptom(cramps: 9, fatigue: 6, energy: 4, dayOffset: 3),
        ]
        let workouts: [Workout] = []

        let insights = SymptomTrainingTrendService.insights(
            symptoms: symptoms,
            workouts: workouts,
            cyclePhase: .menstrual
        )

        XCTAssertFalse(insights.isEmpty, "Expected at least one insight for high cramps and zero workouts")

        let patternInsight = insights.first { insight in
            insight.message.localizedCaseInsensitiveContains("cramp")
                || insight.message.localizedCaseInsensitiveContains("pattern")
        }
        XCTAssertNotNil(patternInsight, "Expected an insight mentioning cramps or patterns")
    }

    // MARK: - High energy + completed workouts -> positive consistency insight

    func testHighEnergyAndCompletedWorkoutsProducesConsistencyInsight() {
        let symptoms = [
            makeSymptom(cramps: 1, fatigue: 2, energy: 8, dayOffset: 0),
            makeSymptom(cramps: 0, fatigue: 1, energy: 9, dayOffset: 2),
            makeSymptom(cramps: 2, fatigue: 3, energy: 8, dayOffset: 4),
        ]
        let workouts = [
            makeCompletedWorkout(dayOffset: 0),
            makeCompletedWorkout(dayOffset: 2),
            makeCompletedWorkout(dayOffset: 4),
        ]

        let insights = SymptomTrainingTrendService.insights(
            symptoms: symptoms,
            workouts: workouts,
            cyclePhase: .follicular
        )

        XCTAssertFalse(insights.isEmpty, "Expected at least one insight for high energy and completed workouts")

        let consistencyInsight = insights.first { insight in
            insight.title.localizedCaseInsensitiveContains("consistency")
                || insight.title.localizedCaseInsensitiveContains("strong")
        }
        XCTAssertNotNil(consistencyInsight, "Expected a positive consistency insight")
    }

    // MARK: - No diagnostic language

    func testInsightsNeverUseDiagnosticLanguage() {
        let diagnosticWords = ["diagnose", "treat", "condition"]

        // Scenario 1: high cramps, low workouts
        let symptoms1 = [
            makeSymptom(cramps: 9, fatigue: 8, energy: 2, dayOffset: 0),
            makeSymptom(cramps: 8, fatigue: 7, energy: 3, dayOffset: 1),
        ]
        let insights1 = SymptomTrainingTrendService.insights(
            symptoms: symptoms1,
            workouts: [],
            cyclePhase: .menstrual
        )

        for insight in insights1 {
            for word in diagnosticWords {
                XCTAssertFalse(
                    insight.title.localizedCaseInsensitiveContains(word),
                    "Insight title contains diagnostic word '\(word)': \(insight.title)"
                )
                XCTAssertFalse(
                    insight.message.localizedCaseInsensitiveContains(word),
                    "Insight message contains diagnostic word '\(word)': \(insight.message)"
                )
            }
        }

        // Scenario 2: high energy, many workouts
        let symptoms2 = [
            makeSymptom(cramps: 0, fatigue: 1, energy: 10, dayOffset: 0),
        ]
        let workouts2 = [
            makeCompletedWorkout(dayOffset: 0),
            makeCompletedWorkout(dayOffset: 1),
            makeCompletedWorkout(dayOffset: 2),
        ]
        let insights2 = SymptomTrainingTrendService.insights(
            symptoms: symptoms2,
            workouts: workouts2,
            cyclePhase: .ovulation
        )

        for insight in insights2 {
            for word in diagnosticWords {
                XCTAssertFalse(
                    insight.title.localizedCaseInsensitiveContains(word),
                    "Insight title contains diagnostic word '\(word)': \(insight.title)"
                )
                XCTAssertFalse(
                    insight.message.localizedCaseInsensitiveContains(word),
                    "Insight message contains diagnostic word '\(word)': \(insight.message)"
                )
            }
        }
    }

    // MARK: - No symptoms and no workouts -> empty insights

    func testNoSymptomsAndNoWorkoutsReturnsEmptyInsights() {
        let insights = SymptomTrainingTrendService.insights(
            symptoms: [],
            workouts: [],
            cyclePhase: nil
        )

        XCTAssertTrue(insights.isEmpty, "Expected empty insights when there are no symptoms and no workouts")
    }

    // MARK: - High fatigue + low workouts -> rest balance insight

    func testHighFatigueAndLowWorkoutsProducesRestBalanceInsight() {
        let symptoms = [
            makeSymptom(cramps: 2, fatigue: 8, energy: 3, dayOffset: 0),
            makeSymptom(cramps: 1, fatigue: 9, energy: 2, dayOffset: 2),
            makeSymptom(cramps: 3, fatigue: 7, energy: 4, dayOffset: 4),
        ]
        let workouts: [Workout] = []

        let insights = SymptomTrainingTrendService.insights(
            symptoms: symptoms,
            workouts: workouts,
            cyclePhase: .luteal
        )

        XCTAssertFalse(insights.isEmpty, "Expected at least one insight for high fatigue and zero workouts")

        let restInsight = insights.first { insight in
            insight.message.localizedCaseInsensitiveContains("rest")
                || insight.message.localizedCaseInsensitiveContains("fatigue")
                || insight.message.localizedCaseInsensitiveContains("balance")
        }
        XCTAssertNotNil(restInsight, "Expected an insight about rest balance for high fatigue")
    }

    // MARK: - Helpers

    private func makeSymptom(
        cramps: Int,
        fatigue: Int,
        soreness: Int = 0,
        energy: Int,
        dayOffset: Int
    ) -> SymptomCheckInRecord {
        let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
        return SymptomCheckInRecord(
            id: UUID().uuidString,
            symptomDate: date,
            cramps: cramps,
            fatigue: fatigue,
            soreness: soreness,
            energy: energy,
            notes: nil,
            dateCreated: date
        )
    }

    private func makeCompletedWorkout(dayOffset: Int) -> Workout {
        let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
        return Workout(
            id: UUID().uuidString,
            date: date,
            name: "Test Workout",
            exercises: [],
            completedAt: date
        )
    }
}
