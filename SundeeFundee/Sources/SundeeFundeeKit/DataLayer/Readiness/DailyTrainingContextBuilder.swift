import Foundation

/// Concurrently assembles physiological and historical readiness signals for a day.
public actor DailyTrainingContextBuilder {
    private let healthProvider: any HealthReadinessProviding
    private let historyProvider: any HistoryReadinessProviding

    public init(
        healthProvider: any HealthReadinessProviding,
        historyProvider: any HistoryReadinessProviding
    ) {
        self.healthProvider = healthProvider
        self.historyProvider = historyProvider
    }

    public init(
        healthClient: any HealthClientProtocol = HealthClientFactory.shared.client,
        dataClient: any DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.healthProvider = HealthReadinessProvider(healthClient: healthClient)
        self.historyProvider = HistoryReadinessProvider(dataClient: dataClient)
    }

    public func build(
        assessmentDate: Date = Date(),
        timeZone: TimeZone = .current,
        cyclePhase: CyclePhase?,
        cycleConfidence: Double?
    ) async -> DailyTrainingContext {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let healthCalendar = calendar
        let historyCalendar = calendar

        async let health = healthProvider.load(assessmentDate: assessmentDate, calendar: healthCalendar)
        async let history = historyProvider.load(assessmentDate: assessmentDate, calendar: historyCalendar)
        let (physiological, recorded) = await (health, history)

        return DailyTrainingContext(
            assessmentDate: assessmentDate,
            timeZoneIdentifier: timeZone.identifier,
            physiological: physiological,
            subjective: recorded.subjective,
            training: recorded.training,
            pain: recorded.pain,
            cyclePhase: cyclePhase,
            cycleConfidence: cycleConfidence
        )
    }
}
