import Foundation

// MARK: - DailyCoachingService

/// Builds a single daily recommendation from coach context and recent training signals.
public actor DailyCoachingService {
    private let dataClient: DataClientProtocol
    private let contextBuilder: CoachContextBuilder
    private let coachService: CoachServiceProtocol

    public init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client,
        contextBuilder: CoachContextBuilder = CoachContextBuilder(),
        coachService: CoachServiceProtocol = CoachServiceFactory.makeService()
    ) {
        self.dataClient = dataClient
        self.contextBuilder = contextBuilder
        self.coachService = coachService
    }

    public func loadRecommendation(
        isGuest: Bool,
        equipment: EquipmentAccess = .fullGym
    ) async -> DailyCoachingRecommendation {
        let context = await contextBuilder.build(equipment: equipment)
        let insights = (try? await coachService.getInsights(context: context))
            ?? CoachInsightsResponse(plateaus: [], trends: [], summary: "", priorityActions: [])
        return await loadRecommendation(context: context, insights: insights, isGuest: isGuest)
    }

    public func loadRecommendation(
        context: CoachContext,
        insights: CoachInsightsResponse,
        isGuest: Bool
    ) async -> DailyCoachingRecommendation {
        let today = Self.dayString(for: Date())
        let painIntensity = await loadTodayPainIntensity()
        let recommendation = Self.makeRecommendation(
            dateString: today,
            context: context,
            insights: insights,
            painIntensity: painIntensity
        )

        if !isGuest {
            let record = DailyCoachingRecommendationRecord(
                id: recommendation.id,
                recommendationDate: recommendation.recommendationDate,
                statusRaw: recommendation.statusRaw,
                title: recommendation.title,
                summary: recommendation.summary,
                primaryActionRaw: recommendation.primaryActionRaw,
                primaryActionTitle: recommendation.primaryActionTitle,
                reasonCodes: recommendation.reasonCodes,
                cyclePhaseRaw: recommendation.cyclePhaseRaw,
                cycleConfidence: recommendation.cycleConfidence,
                trainingLoadTrendRaw: recommendation.trainingLoadTrendRaw,
                painIntensity: recommendation.painIntensity,
                workoutFocusRaw: recommendation.workoutFocusRaw,
                energyLevelRaw: recommendation.energyLevelRaw,
                equipmentRaw: recommendation.equipmentRaw,
                timeMinutes: recommendation.timeMinutes,
                dateCreated: recommendation.dateCreated
            )
            try? await dataClient.save(record, recordType: "DailyCoachingRecommendation")
        }

        return recommendation
    }

    public func buildAdjustedWorkout(
        from recommendation: DailyCoachingRecommendation
    ) async -> Workout? {
        guard recommendation.primaryActionRaw != DailyCoachingPrimaryAction.rest.rawValue else {
            return nil
        }

        guard
            let focus = WorkoutFocus(rawValue: recommendation.workoutFocusRaw ?? WorkoutFocus.fullBody.rawValue),
            let energy = EnergyLevel(rawValue: recommendation.energyLevelRaw ?? EnergyLevel.medium.rawValue),
            let equipment = EquipmentAccess(rawValue: recommendation.equipmentRaw ?? EquipmentAccess.fullGym.rawValue)
        else {
            return nil
        }

        let context = await contextBuilder.build(equipment: equipment)
        let questionnaire = QuestionnaireAnswers(
            timeMinutes: recommendation.timeMinutes ?? 45,
            focus: focus,
            energyLevel: energy,
            equipment: equipment
        )

        do {
            let response = try await coachService.generateWorkout(context: context, preferences: questionnaire)
            return buildWorkout(
                from: response.workout,
                name: "Adjusted Workout",
                notesPrefix: "Daily coaching"
            )
        } catch {
            return nil
        }
    }

    private func loadTodayPainIntensity() async -> Int? {
        do {
            let logs: [DailyPainLog] = try await dataClient.fetchAll(recordType: "DailyPainLog")
            let today = Calendar.current.startOfDay(for: Date())
            return logs
                .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
                .map(\.intensity)
                .max()
        } catch {
            return nil
        }
    }

    private static func dayString(for date: Date) -> String {
        ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: date))
    }

    private static func makeRecommendation(
        dateString: String,
        context: CoachContext,
        insights: CoachInsightsResponse,
        painIntensity: Int?
    ) -> DailyCoachingRecommendation {
        let cyclePhase = context.cyclePhase
        let cycleConfidence = context.cycleConfidence
        let loadTrend = insights.trends.first?.type.rawValue
        let hasPlateau = !insights.plateaus.isEmpty || !context.volumePlateaus.isEmpty || !context.progressWarnings.isEmpty
        let overreaching = insights.trends.contains(where: { $0.type == .overreaching })

        let status: DailyCoachingStatus
        if let pain = painIntensity, pain >= 8 {
            status = .rest
        } else if let pain = painIntensity, pain >= 6 {
            status = .activeRecovery
        } else if overreaching || hasPlateau {
            status = .deload
        } else if cyclePhase == .follicular || cyclePhase == .ovulation {
            status = .push
        } else if cyclePhase != nil {
            status = .build
        } else {
            status = .maintain
        }

        let values = recommendationValues(
            for: status,
            cyclePhase: cyclePhase,
            painIntensity: painIntensity,
            insights: insights
        )

        return DailyCoachingRecommendation(
            recommendationDate: dateString,
            statusRaw: status.rawValue,
            title: values.title,
            summary: values.summary,
            primaryActionRaw: values.action.rawValue,
            primaryActionTitle: values.actionTitle,
            reasonCodes: values.reasons,
            cyclePhaseRaw: cyclePhase?.rawValue,
            cycleConfidence: cycleConfidence,
            trainingLoadTrendRaw: loadTrend,
            painIntensity: painIntensity,
            workoutFocusRaw: values.focus.rawValue,
            energyLevelRaw: values.energy.rawValue,
            equipmentRaw: values.equipment.rawValue,
            timeMinutes: values.timeMinutes
        )
    }

    private static func recommendationValues(
        for status: DailyCoachingStatus,
        cyclePhase: CyclePhase?,
        painIntensity: Int?,
        insights: CoachInsightsResponse
    ) -> (
        title: String,
        summary: String,
        action: DailyCoachingPrimaryAction,
        actionTitle: String,
        focus: WorkoutFocus,
        energy: EnergyLevel,
        equipment: EquipmentAccess,
        timeMinutes: Int,
        reasons: [String]
    ) {
        let reasons = buildReasons(
            cyclePhase: cyclePhase,
            painIntensity: painIntensity,
            insights: insights
        )

        switch status {
        case .rest:
            return (
                "Rest day",
                "Skip loading work today and keep the next session for tomorrow if recovery rebounds.",
                .rest,
                "Rest today",
                .fullBody,
                .low,
                .outdoor,
                20,
                reasons
            )
        case .activeRecovery:
            return (
                "Active recovery",
                "Keep moving, but keep the work light so you can recover and come back ready.",
                .takeActiveRecovery,
                "Start recovery session",
                .conditioning,
                .low,
                .bodyweightOnly,
                25,
                reasons
            )
        case .deload:
            return (
                "Deload today",
                "Trim the load and volume so you can recover without losing momentum.",
                .startAdjustedWorkout,
                "Start deload workout",
                .fullBody,
                .low,
                .fullGym,
                40,
                reasons
            )
        case .push:
            return (
                "Push day",
                "Your available training signals support quality work and heavier loading.",
                .startAdjustedWorkout,
                "Start push workout",
                .fullBody,
                .high,
                .fullGym,
                55,
                reasons
            )
        case .build:
            return (
                "Build day",
                "Keep the session productive and build from the work you've already put in.",
                .startAdjustedWorkout,
                "Start build workout",
                .fullBody,
                .medium,
                .fullGym,
                45,
                reasons
            )
        case .maintain:
            return (
                "Maintain today",
                "Stay consistent with a moderate session and leave some room in the tank.",
                .startAdjustedWorkout,
                "Start workout",
                .fullBody,
                .medium,
                .fullGym,
                45,
                reasons
            )
        }
    }

    private static func buildReasons(
        cyclePhase: CyclePhase?,
        painIntensity: Int?,
        insights: CoachInsightsResponse
    ) -> [String] {
        var reasons: [String] = []
        if let phase = cyclePhase {
            reasons.append("\(phase.rawValue.capitalized) phase")
        }
        if let painIntensity, painIntensity > 0 {
            reasons.append("Pain \(painIntensity)/10")
        }
        if !insights.plateaus.isEmpty {
            reasons.append("\(insights.plateaus.count) plateau\(insights.plateaus.count == 1 ? "" : "s")")
        }
        if insights.trends.contains(where: { $0.type == .overreaching }) {
            reasons.append("Overreaching trend")
        }
        if reasons.isEmpty {
            reasons.append("No major blockers detected")
        }
        return reasons
    }
}
