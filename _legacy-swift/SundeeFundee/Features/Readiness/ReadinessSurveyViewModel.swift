import Foundation

@MainActor
@Observable
final class ReadinessSurveyViewModel {
    var sleepQuality: Double = 5
    var stressLevel: Double = 5
    var sorenessLevel: Double = 5

    private let defaults: UserDefaults
    private let healthKitScore: Double?

    var livePreview: ReadinessResult {
        let survey = ReadinessSurvey.score(
            sleepQuality: sleepQuality,
            stressLevel: stressLevel,
            sorenessLevel: sorenessLevel
        )
        return ReadinessSurvey.blendWithHealthKit(
            surveyScore: survey.score,
            healthKitScore: healthKitScore
        )
    }

    init(
        defaults: UserDefaults = .standard,
        healthKitScore: Double? = nil,
        healthKitSleepHours: Double? = nil
    ) {
        self.defaults = defaults
        self.healthKitScore = healthKitScore
        if let hours = healthKitSleepHours {
            self.sleepQuality = min(10, max(1, (hours / 9.0 * 10).rounded()))
        }
    }

    func submit() {
        let result = livePreview
        ReadinessSurvey.saveTodayResult(result, defaults: defaults)
    }

    static func hasScoreToday(defaults: UserDefaults = .standard) -> Bool {
        ReadinessSurvey.loadTodayResult(defaults: defaults) != nil
    }
}
