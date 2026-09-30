import Foundation
import os.log
#if canImport(WidgetKit)
import WidgetKit
#endif

private let dashLogger = Logger(subsystem: "com.sundeefundee.app", category: "Dashboard")

// MARK: - DashboardViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var isLoading: Bool = false
    @Published public var isInitialLoad: Bool = true
    @Published public var navigateToLogMax: Bool = false
    @Published public var errorMessage: String?

    @Published public var workoutsThisWeek: Int = 0
    @Published public var prsThisMonth: Int = 0
    @Published public var activeProgramName: String?
    @Published public var nextWorkout: String?
    @Published var nextProgramListItem: ProgramListItem?
    @Published public var canGenerateAIWorkout: Bool = false
    @Published public var isGeneratingWorkout: Bool = false
    @Published public var recentWins: [String] = []
    @Published public var insightsSummary: String?
    @Published public var insightsActions: [String] = []
    @Published public var activeChallengeData: (Challenge, ChallengeProgress)?
    @Published public var weeklyPlanProgress: WeeklyPlanProgress?
    @Published public var weeklyStreak: WeeklyStreak?
    @Published public var cycleTrackingEnabled: Bool = false
    @Published public var cycleForecast: [CycleDayForecast] = []
    @Published public var todayAction: TodayAction?
    @Published public var firstWeekChecklist: [FirstWeekChecklistItem] = []
    @Published public var navigateToPainTracking: Bool = false
    @Published public var todayTrainingDecision: TodayTrainingDecision?
    @Published public var deloadRecommendation: DeloadRecommendation?
    @Published public var missedWorkoutRecoveryPlan: MissedWorkoutRecoveryPlan?

    // MARK: - Dependencies

    private let healthClient: HealthClientProtocol
    private let dataClient: DataClientProtocol
    private var hasRequestedHealthAuth = false
    private var hasTrackedFirstWorkoutPrompt = false

    // MARK: - Initialization

    public init(
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.healthClient = healthClient
        self.dataClient = dataClient
    }

    public var showsNewUserEmptyState: Bool {
        !isInitialLoad
            && todayAction?.kind == .startFirstWorkout
    }

    public var todaySecondarySectionInput: [TodaySecondarySection] {
        MinimalSurfacePolicy.todaySecondarySections(
            input: TodaySecondarySectionInput(
                hasWeeklyPlan: weeklyPlanProgress != nil,
                hasMissedWorkoutPlan: missedWorkoutRecoveryPlan != nil,
                hasFirstWeekChecklist: shouldShowFirstWeekChecklist,
                hasActiveChallenge: activeChallengeData != nil,
                hasCoachInsights: insightsSummary != nil || !insightsActions.isEmpty,
                hasRecentWins: !recentWins.isEmpty
            )
        )
    }

    // MARK: - Public Methods

    public func loadData(cyclePhaseCache: CyclePhaseCache) async {
        isLoading = true
        errorMessage = nil
        let settings = await loadUserSettings()
        cycleTrackingEnabled = settings.cycleTrackingEnabled

        if !hasRequestedHealthAuth {
            hasRequestedHealthAuth = true
            if healthClient.isAvailable {
                try? await healthClient.requestStandardAuthorization()
            }
        }

        // Tier 1: Load critical data in parallel
        async let statsTask: Void = loadStats()
        async let programTask: Void = loadProgramInfo()
        async let winsTask: Void = loadRecentWins()
        async let cycleTask: Void = cyclePhaseCache.refreshIfNeeded()
        _ = await (statsTask, programTask, winsTask, cycleTask)

        canGenerateAIWorkout = true
        isLoading = false
        isInitialLoad = false

        // Tier 2: Non-critical data loads after UI is visible
        await loadCoachingInsights()
        await loadActiveChallenge()
        await loadWeeklyPlan(cyclePhase: cyclePhaseCache.currentPhase)
        await loadTodayGuidance(cyclePhaseCache: cyclePhaseCache)
        await trackFirstWorkoutPromptIfNeeded()

        if cycleTrackingEnabled {
            let periodLogs: [PeriodLogRecord] = (try? await dataClient.fetchAll(recordType: "PeriodLogRecord")) ?? []
            var settings = CycleSettings()
            if let settingsRecords = try? await dataClient.fetchAll(recordType: "CycleSettings") as [CycleSettingsRecord],
               let first = settingsRecords.first {
                settings = CycleSettings(averageCycleLengthDays: first.averageCycleLengthDays)
            }
            cycleForecast = CycleForecastService.generateSevenDayForecast(
                periodLogs: periodLogs.map { $0.toPeriodLog() },
                settings: settings,
                mode: cyclePhaseCache.cycleTrackingMode
            )
        } else {
            cycleForecast = []
        }
    }

    public func resetWeeklyPlan() async {
        let service = WeeklyPlanService(dataClient: dataClient)
        _ = try? await service.createOrUpdateCurrentPlan(
            targetWorkoutCount: 3,
            preferredWeekdays: [2, 4, 6]
        )
        await loadWeeklyPlan()
        await loadTodayGuidance(cyclePhaseCache: nil)
    }

    public func applyMissedWorkoutRecovery() async {
        missedWorkoutRecoveryPlan = nil
        await loadWeeklyPlan()
        await loadTodayGuidance(cyclePhaseCache: nil)
    }

    public func buildStarterWorkout() async -> Workout {
        let settings = await loadUserSettings()
        let workout = StarterWorkoutBuilder.build(
            context: StarterWorkoutContext(
                experienceLevel: settings.experienceLevel,
                primaryGoal: settings.primaryGoal,
                weightUnit: settings.weightUnit,
                cycleTrackingEnabled: settings.cycleTrackingEnabled,
                defaultEquipment: settings.defaultEquipment
            )
        )
        await GrowthAnalyticsService(dataClient: dataClient).track(
            GrowthEventName.firstWorkoutStarted,
            source: "dashboard"
        )
        return workout
    }

    public func buildActiveRecoveryWorkout(cyclePhase: CyclePhase?) async -> Workout {
        let settings = await loadUserSettings()
        return ActiveRecoveryWorkoutBuilder.build(
            equipment: settings.defaultEquipment,
            cyclePhase: cyclePhase
        )
    }

    public func buildQuickWorkout() async -> Workout {
        let settings = await loadUserSettings()
        let painLogs: [DailyPainLog] = (try? await dataClient.fetchAll(recordType: "DailyPainLog")) ?? []
        let recentCutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentPainLogs = painLogs.filter { $0.date >= recentCutoff }
        let decisionKind = todayTrainingDecision?.kind ?? .modify

        let request = QuickWorkoutRequest(
            timeMinutes: 20,
            focus: .fullBody,
            energyLevel: .medium,
            equipment: settings.defaultEquipment,
            todayDecisionKind: decisionKind,
            painLogs: recentPainLogs,
            workoutKind: decisionKind == .recover ? .activeRecovery : .standard
        )

        return QuickWorkoutBuilder.build(request: request).workout
    }

    /// Generates an AI workout based on cycle phase and energy
    public func generateAIWorkout() async {
        isGeneratingWorkout = true

        // Simulate AI generation
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        isGeneratingWorkout = false

        // In real implementation, this would call the AI service
        // and navigate to the built workout
    }

    // MARK: - Private Methods

    private func loadStats() async {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start
        let monthStart = calendar.date(byAdding: .month, value: -1, to: now) ?? now

        if healthClient.isAvailable {
            do {
                let workouts = try await healthClient.fetchWorkouts(startDate: weekStart, endDate: nil, limit: 30)
                if let weekStart {
                    workoutsThisWeek = workouts.filter { $0.startDate >= weekStart }.count
                }
            } catch {
                // HealthKit not authorized or query failed
            }
        }

        if workoutsThisWeek == 0 {
            do {
                let recentWorkouts: [Workout] = try await dataClient.fetch(
                    recordType: "Workout",
                    predicate: NSPredicate(value: true),
                    sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
                )
                if let weekStart {
                    workoutsThisWeek = recentWorkouts.filter { $0.completedAt != nil && $0.completedAt! >= weekStart }.count
                }
            } catch {
                // CloudKit unavailable — leave at default 0
            }
        }

        do {
            let prs: [OneRepMaxRecord] = try await dataClient.fetch(
                recordType: "OneRepMaxRecord",
                predicate: NSPredicate(value: true),
                sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
            )
            prsThisMonth = prs.filter { $0.date >= monthStart }.count
        } catch {
            // CloudKit unavailable — leave prsThisMonth at default 0
        }
    }

    public func loadProgramInfo() async {
        do {
            let programs = try await dataClient.fetchAll(
                recordType: "EnrolledProgramRecord"
            ) as [EnrolledProgramRecord]

            let currentProgramIds = Set(ProgramTemplate.allCases.map(\.stableID))
            if let program = programs.first(where: { $0.isActive && currentProgramIds.contains($0.id) }),
               let template = ProgramTemplate(rawValue: program.id) {
                activeProgramName = program.name
                let generated = generateProgram(template: template, name: program.name)
                nextWorkout = await Self.nextSessionName(for: program.id, generated: generated, dataClient: dataClient)
                nextProgramListItem = ProgramListItem(
                    id: generated.id,
                    name: program.name,
                    category: generated.category,
                    description: generated.description,
                    durationWeeks: generated.durationWeeks,
                    sessionsPerWeek: generated.sessionsPerWeek,
                    difficulty: generated.difficulty,
                    isEnrolled: true,
                    template: template,
                    printablePDFURL: template.printablePDFURL
                )
            } else {
                activeProgramName = nil
                nextWorkout = nil
                nextProgramListItem = nil
            }
        } catch {
            // CloudKit unavailable — leave program info at defaults
        }
    }

    /// Name of the first session in program order that has no completed
    /// workout yet, mirroring `ProgramDetailViewModel.loadSessionProgress()`.
    /// Falls back to the first session when progress can't be determined or
    /// every session is already complete.
    private static func nextSessionName(
        for programId: String,
        generated: GeneratedProgram,
        dataClient: DataClientProtocol
    ) async -> String? {
        let orderedSessions = generated.weeks.flatMap(\.sessions)
        guard let firstSession = orderedSessions.first else { return nil }

        do {
            let sessionRecords: [ProgramSessionRecord] = try await dataClient.fetchAll(
                recordType: "ProgramSessionRecord"
            )
            let workouts: [Workout] = try await dataClient.fetchAll(recordType: "Workout")
            let completedWorkoutIds = Set(workouts.filter(\.isComplete).map(\.id))

            let completedSessionIds = Set(
                sessionRecords
                    .filter { $0.programId == programId && completedWorkoutIds.contains($0.workoutId) }
                    .map(\.sessionId)
            )

            let nextSession = orderedSessions.first { !completedSessionIds.contains($0.sessionId) }
            return (nextSession ?? firstSession).sessionName
        } catch {
            return firstSession.sessionName
        }
    }

    private func loadCoachingInsights() async {
        let coachService = CoachServiceFactory.makeService()
        let contextBuilder = CoachContextBuilder(
            healthClient: healthClient,
            dataClient: dataClient
        )
        let context = await contextBuilder.build()
        do {
            let insights = try await coachService.getInsights(context: context)
            insightsSummary = insights.summary
            insightsActions = insights.priorityActions
        } catch {
            // Coaching insights are non-critical — degrade gracefully
        }
    }

    private func loadRecentWins() async {
        do {
            let wins = try await dataClient.fetchAll(
                recordType: "CelebrationEventRecord"
            ) as [CelebrationEventRecord]

            recentWins = wins.map { win in
                String(win.description.prefix(50))
            }
        } catch {
            // Recent wins are non-critical — degrade gracefully
        }
    }

    private func loadActiveChallenge(cachedWorkouts: [Workout]? = nil) async {
        let service = ChallengeService(dataClient: dataClient)
        do {
            let workouts: [Workout]
            if let cached = cachedWorkouts {
                workouts = cached
                dashLogger.info("📊 Challenge: using cached \(workouts.count) workouts")
            } else {
                workouts = try await dataClient.fetchAll(recordType: "Workout")
                dashLogger.info("📊 Challenge: fetched \(workouts.count) workouts")
            }
            let challenge = try await service.ensureLifetimeChallenge(from: workouts)
            dashLogger.info("📊 Challenge: ensured lifetime challenge = \(challenge?.id ?? "nil")")
            if let closest = try await service.closestToCompletion() {
                dashLogger.info("📊 Challenge: closest = \(closest.0.title), \(Int(closest.1.percentComplete * 100))%")
                activeChallengeData = closest
            } else {
                dashLogger.info("📊 Challenge: no active challenge found by closestToCompletion")
            }
        } catch {
            dashLogger.error("📊 Challenge load failed: \(error.localizedDescription)")
        }
    }

    private func loadWeeklyPlan(
        cyclePhase: CyclePhase? = nil
    ) async {
        let workouts: [Workout] = (try? await dataClient.fetchAll(recordType: "Workout")) ?? []
        let service = WeeklyPlanService(dataClient: dataClient)
        var plan = await service.currentPlan()
        if plan == nil {
            plan = try? await service.createOrUpdateCurrentPlan(
                targetWorkoutCount: 3,
                preferredWeekdays: [2, 4, 6]
            )
        }
        if let plan {
            weeklyPlanProgress = await service.progress(
                plan: plan,
                workouts: workouts,
                cyclePhase: cyclePhase
            )
            weeklyStreak = StreakService.calculate(workouts: workouts, targetPerWeek: plan.targetWorkoutCount)

            // Compute missed-workout recovery plan
            let calendar = Calendar.current
            let now = Date()
            let currentDay = calendar.component(.weekday, from: now)
            // Convert to Monday=1 convention used by ScheduleReshuffler
            let reshufflerDay = ((currentDay + 5) % 7) + 1

            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
            let completedWorkoutDays = Set(
                workouts
                    .filter { $0.completedAt != nil && $0.completedAt! >= weekStart }
                    .compactMap { calendar.component(.weekday, from: $0.completedAt!) }
                    .map { (($0 + 5) % 7) + 1 }
            )

            let missedDays = Set(plan.preferredWeekdays.filter { day in
                day < reshufflerDay && !completedWorkoutDays.contains(day)
            })

            let plannedSessions = plan.preferredWeekdays.map { day in
                ScheduleReshuffler.PlannedSession(
                    dayOfWeek: day,
                    sessionName: "Workout",
                    focus: "Strength",
                    estimatedMinutes: 45,
                    priority: .compound
                )
            }

            missedWorkoutRecoveryPlan = MissedWorkoutRecoveryService.recoveryPlan(
                weeklyPlan: plannedSessions,
                completedDays: completedWorkoutDays,
                missedDays: missedDays,
                currentDay: reshufflerDay
            )
        }
    }

    public var shouldShowFirstWeekChecklist: Bool {
        !firstWeekChecklist.isEmpty && firstWeekChecklist.contains { !$0.isComplete }
    }

    private func loadTodayGuidance(cyclePhaseCache: CyclePhaseCache?) async {
        let calendar = Calendar.current
        let now = Date()
        let workouts: [Workout] = (try? await dataClient.fetchAll(
            recordType: "Workout",
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
        )) ?? []
        let maxes: [OneRepMaxRecord] = (try? await dataClient.fetchAll(recordType: "OneRepMaxRecord")) ?? []
        let hasWeeklyPlan = weeklyPlanProgress != nil
        let checklist = TodayGuidanceService.firstWeekChecklist(
            completedWorkoutCount: workouts.filter { $0.completedAt != nil }.count,
            maxCount: maxes.count,
            hasWeeklyPlan: hasWeeklyPlan
        )

        let painLogs: [DailyPainLog] = (try? await dataClient.fetchAll(recordType: "DailyPainLog")) ?? []
        let painIntensityToday = painLogs
            .filter { calendar.isDate($0.date, inSameDayAs: now) }
            .map(\.intensity)
            .max()

        let deload = DeloadDetectionService.recommendation(
            recentPainLogs: painLogs,
            recentWorkouts: workouts
        )
        let decision = TodayTrainingDecisionService.decision(
            cyclePhase: cyclePhaseCache?.currentPhase,
            cycleConfidence: cyclePhaseCache?.confidence,
            painIntensity: painIntensityToday,
            energyLevel: nil,
            weeklyPlanProgress: weeklyPlanProgress,
            deloadRecommended: deload.isRecommended
        )

        firstWeekChecklist = checklist
        deloadRecommendation = deload
        todayTrainingDecision = decision
        let action = TodayGuidanceService.primaryAction(
            workouts: workouts,
            weeklyPlanProgress: weeklyPlanProgress,
            firstWeekChecklist: checklist,
            now: now
        )
        todayAction = action

        let workoutTitle = nextWorkout ?? action.title
        let rec = decision.kind.rawValue
        let guidance = decision.headline
        SharedSnapshotStore.writeNextWorkout(
            NextWorkoutSnapshot(
                workoutName: workoutTitle,
                recommendationRaw: rec,
                guidanceDetail: guidance,
                scheduledDate: now,
                capturedAt: now
            )
        )
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "NextWorkoutWidget")
        #endif
    }

    private func trackFirstWorkoutPromptIfNeeded() async {
        guard showsNewUserEmptyState, !hasTrackedFirstWorkoutPrompt else { return }
        hasTrackedFirstWorkoutPrompt = true
        await GrowthAnalyticsService(dataClient: dataClient).track(
            GrowthEventName.firstWorkoutPromptSeen,
            source: "dashboard"
        )
    }

    private func loadUserSettings() async -> DashboardUserSettings {
        let records: [UserSettingsRecord] = (try? await dataClient.fetchAll(recordType: "UserSettings")) ?? []
        guard let settings = records.last else {
            return DashboardUserSettings(
                experienceLevel: .beginner,
                primaryGoal: .strength,
                weightUnit: .lbs,
                cycleTrackingEnabled: false,
                defaultEquipment: .fullGym
            )
        }
        return DashboardUserSettings(
            experienceLevel: ExperienceLevel(rawValue: settings.experienceLevel) ?? .beginner,
            primaryGoal: PrimaryGoal(rawValue: settings.primaryGoal) ?? .strength,
            weightUnit: WeightUnit(rawValue: settings.weightUnit) ?? .lbs,
            cycleTrackingEnabled: settings.cycleTrackingEnabled,
            defaultEquipment: settings.defaultEquipment
        )
    }
}

private struct DashboardUserSettings: Sendable {
    let experienceLevel: ExperienceLevel
    let primaryGoal: PrimaryGoal
    let weightUnit: WeightUnit
    let cycleTrackingEnabled: Bool
    let defaultEquipment: EquipmentAccess
}

extension FirstWeekChecklistKind {
    var actionTitle: String {
        switch self {
        case .firstWorkout: return "Start first workout"
        case .logMax: return "Log a max"
        case .weeklySchedule: return "Set schedule"
        }
    }
}
