import Foundation
import Combine
#if canImport(UIKit) && os(iOS)
import UIKit
#endif

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public class ActiveWorkoutSessionViewModel: ObservableObject, Identifiable {

    // MARK: - Published State

    @Published public private(set) var workout: Workout

    public let id: String
    @Published public private(set) var currentExerciseIndex: Int = 0
    @Published public private(set) var currentSetIndex: Int = 0
    @Published public private(set) var restTimeRemaining: TimeInterval = 0
    @Published public private(set) var isResting: Bool = false
    @Published public private(set) var elapsedSeconds: TimeInterval = 0
    @Published public private(set) var isComplete: Bool = false
    @Published public private(set) var isFinishing: Bool = false
    @Published public var celebrationEvents: [CelebrationEvent] = []
    @Published public var errorMessage: String?
    @Published public var pendingPRShare: PendingPRShare?
    @Published public private(set) var defaultEquipment: EquipmentAccess = .fullGym
    @Published public private(set) var lastEquipmentConversionChanges: [EquipmentConversionChange] = []
    @Published public private(set) var startingWeightSuggestions: [StartingWeightSuggestion] = []
    @Published public var showStartingWeightCalibrationSheet: Bool = false
    @Published public private(set) var pendingWarmupBlock: WarmupBlock?

    // MARK: - PR Share Prompt

    public struct PendingPRShare: Identifiable, Equatable {
        public let id: UUID = UUID()
        public let exerciseName: String
        public let weight: Double
        public let unit: String
        public let previousBest: Double?
    }

    // MARK: - Private Properties

    private let dataClient: DataClientProtocol
    private let healthClient: HealthClientProtocol
    private let startedAt: Date
    private var restTimerCancellable: AnyCancellable?
    private var elapsedTimerCancellable: AnyCancellable?
    private var restStartedAt: Date?
    private var restTargetDuration: TimeInterval = 0
    private var acceptedSubstitutions: [String] = []
    private var usedPainAwareSwap = false
    private var personalRecordExerciseNames: Set<String> = []
    private var hasEvaluatedStartingCalibration = false
    private var hasAppliedStartingCalibration = false
#if canImport(ActivityKit) && os(iOS)
    private var liveActivityManager: LiveWorkoutActivityManager?
#endif

    // MARK: - Computed Properties

    public var currentExercise: Exercise? {
        guard currentExerciseIndex < workout.exercises.count else { return nil }
        return workout.exercises[currentExerciseIndex]
    }

    public var currentSet: ExerciseSet? {
        guard let exercise = currentExercise,
              currentSetIndex < exercise.targetSets.count else { return nil }
        return exercise.targetSets[currentSetIndex]
    }

    public var totalSets: Int {
        workout.exercises.reduce(0) { $0 + $1.targetSets.count }
    }

    public var completedSets: Int {
        workout.exercises.reduce(0) { $0 + $1.targetSets.filter(\.isComplete).count }
    }

    public var hasNextSet: Bool {
        guard let exercise = currentExercise else { return false }
        return currentSetIndex + 1 < exercise.targetSets.count
    }

    public var hasNextExercise: Bool {
        currentExerciseIndex + 1 < workout.exercises.count
    }

    public var isLastSetOfWorkout: Bool {
        !hasNextSet && !hasNextExercise
    }

    public var lastCompletedWeight: Double? {
        for exercise in workout.exercises {
            for set in exercise.targetSets {
                if let w = set.completedWeight, w > 0 {
                    return w
                }
            }
        }
        return nil
    }

    public var canStartWarmup: Bool {
        pendingWarmupBlock != nil
            && currentExerciseIndex == 0
            && currentSetIndex == 0
            && completedSets == 0
            && !workout.exercises.contains(where: { $0.category == .warmup })
    }

    // MARK: - Initialization

    public init(
        workout: Workout,
        dataClient: DataClientProtocol = DataClientFactory.shared.client,
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client
    ) {
        self.workout = workout
        self.id = workout.id
        self.dataClient = dataClient
        self.healthClient = healthClient
        self.startedAt = Date()
    }

    // MARK: - Session Lifecycle

    public func beginSession() {
#if canImport(ActivityKit) && os(iOS)
        liveActivityManager = LiveWorkoutActivityManager()
#endif
        startElapsedTimer()
        updateLiveActivity()
        Task {
            await bootstrapSessionPreferences()
            await prepareWarmupIfNeeded()
        }
    }

    public func convertWorkout(to equipment: EquipmentAccess) async {
        let converted = EquipmentConversionService.convert(workout: workout, to: equipment)
        workout = converted.workout
        defaultEquipment = equipment
        lastEquipmentConversionChanges = converted.changes
        await saveProgress()
    }

    public func applyStartingWeightSuggestions() async {
        guard !hasAppliedStartingCalibration else {
            showStartingWeightCalibrationSheet = false
            return
        }
        guard !startingWeightSuggestions.isEmpty else {
            showStartingWeightCalibrationSheet = false
            return
        }

        var updated = workout
        for exerciseIndex in updated.exercises.indices {
            let exerciseName = updated.exercises[exerciseIndex].name
            guard let suggestion = startingWeightSuggestions.first(where: {
                $0.exerciseName.compare(exerciseName, options: [.caseInsensitive]) == .orderedSame
            }),
            let suggestedWeight = suggestion.suggestedWeight else { continue }

            for setIndex in updated.exercises[exerciseIndex].targetSets.indices {
                updated.exercises[exerciseIndex].targetSets[setIndex].prescribedWeight = suggestedWeight
            }
        }

        workout = updated
        hasAppliedStartingCalibration = true
        showStartingWeightCalibrationSheet = false
        await saveProgress()
    }

    public func skipStartingWeightCalibration() {
        showStartingWeightCalibrationSheet = false
        hasAppliedStartingCalibration = true
    }

    public func applyWarmup() async {
        guard canStartWarmup, let pendingWarmupBlock else { return }

        var updated = workout
        updated.exercises.insert(contentsOf: pendingWarmupBlock.exercises, at: 0)
        workout = updated
        currentExerciseIndex = 0
        currentSetIndex = 0
        self.pendingWarmupBlock = nil
        await saveProgress()
    }

    public func completeSet(actualReps: Int, completedWeight: Double) async {
        guard currentExerciseIndex < workout.exercises.count,
              currentSetIndex < workout.exercises[currentExerciseIndex].targetSets.count else { return }

        // 1. Mark set complete
        workout.exercises[currentExerciseIndex].targetSets[currentSetIndex].isComplete = true
        workout.exercises[currentExerciseIndex].targetSets[currentSetIndex].actualReps = actualReps
        workout.exercises[currentExerciseIndex].targetSets[currentSetIndex].completedWeight = completedWeight
        HapticFeedback.light()

        // 2. Check for PR using Epley formula
        let exerciseName = workout.exercises[currentExerciseIndex].name
        await checkAndRecordPR(exerciseName: exerciseName, reps: actualReps, weight: completedWeight)

        // 3. Save progress
        await saveProgress()

        // 4. Check if workout is done
        if isLastSetOfWorkout {
            await finishWorkout()
            return
        }

        // 5. Advance to next set
        advanceToNextSet()

        // 6. Start rest timer if applicable
        if let exercise = currentExercise, exercise.restMinutes > 0 {
            startRestTimer(duration: exercise.restMinutes * 60)
        }

        // 7. Update Live Activity
        updateLiveActivity()
    }

    public func skipRest() {
        stopRestTimer()
        updateLiveActivity()
    }

    /// Swaps the current exercise with an alternative. Preserves set structure
    /// (reps / prescribed weight) but clears any logged progress on the current
    /// exercise — callers should confirm with the user before calling if any
    /// sets have already been completed on this exercise.
    public func swapCurrentExercise(to newName: String, reason: String? = nil) {
        guard currentExerciseIndex < workout.exercises.count else { return }
        var updated = workout
        var existing = updated.exercises[currentExerciseIndex]
        let oldName = existing.name
        let resetSets = existing.targetSets.map { set in
            ExerciseSet(
                id: UUID().uuidString,
                reps: set.reps,
                prescribedWeight: set.prescribedWeight,
                type: set.type,
                completedWeight: nil,
                actualReps: nil,
                isComplete: false
            )
        }
        existing = Exercise(
            id: existing.id,
            name: newName,
            category: existing.category,
            bodyweight: existing.bodyweight,
            targetSets: resetSets
        )
        updated.exercises[currentExerciseIndex] = existing
        workout = updated
        acceptedSubstitutions.append("\(oldName) -> \(newName)")
        if Self.isPainAwareSwapReason(reason) {
            usedPainAwareSwap = true
        }
        currentSetIndex = 0
    }

    public func stationTakenSwaps(
        blockedStation: BlockedStationKind,
        painLogs: [DailyPainLog]
    ) -> [SubstitutionRanker.RankedSubstitution] {
        guard let exercise = currentExercise else { return [] }
        return StationTakenSwapService.rankedSwaps(
            request: StationTakenSwapRequest(
                exerciseName: exercise.name,
                blockedStation: blockedStation,
                equipment: defaultEquipment,
                painLogs: painLogs
            )
        )
    }

    /// True when at least one set of the current exercise has been logged —
    /// UI uses this to prompt the user before swapping mid-exercise.
    public var currentExerciseHasProgress: Bool {
        guard let ex = currentExercise else { return false }
        return ex.targetSets.contains(where: \.isComplete)
    }

    public func finishWorkout() async {
        isFinishing = true

        for i in workout.exercises.indices {
            for j in workout.exercises[i].targetSets.indices {
                if !workout.exercises[i].targetSets[j].isComplete {
                    workout.exercises[i].targetSets[j].isComplete = true
                    if workout.exercises[i].targetSets[j].completedWeight == nil,
                       workout.exercises[i].targetSets[j].prescribedWeight > 0 {
                        workout.exercises[i].targetSets[j].completedWeight = workout.exercises[i].targetSets[j].prescribedWeight
                    }
                    if workout.exercises[i].targetSets[j].actualReps == nil {
                        workout.exercises[i].targetSets[j].actualReps = workout.exercises[i].targetSets[j].reps
                    }
                }
            }
        }

        workout.completedAt = Date()
        workout.duration = max(1, Int(elapsedSeconds / 60))

        // Save to CloudKit
        do {
            try await dataClient.save(workout, recordType: "Workout")
        } catch {
            errorMessage = "Failed to save workout: \(error.localizedDescription)"
        }

        // Update challenge volume
        do {
            let challengeService = ChallengeService(dataClient: dataClient)
            let challengeCelebrations = try await challengeService.recordWorkoutVolume(workout)
            for celebration in challengeCelebrations {
                switch celebration {
                case .challengeTierCompleted:
                    HapticFeedback.medium()
                case .challengeCompleted:
                    HapticFeedback.success()
                default:
                    break
                }
            }
            celebrationEvents.append(contentsOf: challengeCelebrations)
        } catch {
            // Challenge update is non-critical
        }

        // Save celebration
        if !celebrationEvents.isEmpty {
            for event in celebrationEvents {
                let record = CelebrationEventRecord(
                    id: UUID().uuidString,
                    description: "\(celebrationTitle(event)) \(celebrationSubtitle(event))",
                    date: Date()
                )
                try? await dataClient.save(record, recordType: "CelebrationEventRecord")
            }
        }

        // Workout completion celebration
        let completionEvent = CelebrationEvent.workoutCompleted(durationSeconds: Int(elapsedSeconds))
        celebrationEvents.append(completionEvent)

        // Save to HealthKit
        do {
            let energyEstimate = Double(completedSets) * 6.0 // ~6 cal per working set
            try await healthClient.saveWorkout(
                startDate: startedAt,
                endDate: Date(),
                totalEnergyBurned: energyEstimate,
                exercises: workout.exercises
            )
        } catch {
            // HealthKit save is non-critical
        }

        await CoachMemoryService(dataClient: dataClient).recordWorkoutCompletion(
            WorkoutCompletionMemory(
                workoutID: workout.id,
                exerciseNames: workout.exercises.map(\.name),
                substitutionsAccepted: acceptedSubstitutions
            )
        )

        await GrowthAnalyticsService(dataClient: dataClient).track(
            GrowthEventName.firstWorkoutCompleted,
            source: "active_workout",
            properties: ["workoutID": workout.id]
        )

        await requestReviewIfEligible()

        // End Live Activity
        let finalSnapshot = buildSnapshot(status: .completed)
#if canImport(ActivityKit) && os(iOS)
        liveActivityManager?.end(finalSnapshot: finalSnapshot)
#endif

        stopRestTimer()
        elapsedTimerCancellable?.cancel()
        isComplete = true
        isFinishing = false
    }

    public func abandonWorkout() async {
        // Save whatever was completed
        workout.duration = max(1, Int(elapsedSeconds / 60))
        try? await dataClient.save(workout, recordType: "Workout")

        let finalSnapshot = buildSnapshot(status: .completed)
#if canImport(ActivityKit) && os(iOS)
        liveActivityManager?.end(finalSnapshot: finalSnapshot)
#endif

        stopRestTimer()
        elapsedTimerCancellable?.cancel()
    }

    private func bootstrapSessionPreferences() async {
        guard !hasEvaluatedStartingCalibration else { return }
        hasEvaluatedStartingCalibration = true

        let settings = await loadUserSettings()
        defaultEquipment = settings.defaultEquipment
        await evaluateStartingWeightCalibration(using: settings)
    }

    private func evaluateStartingWeightCalibration(using settings: WorkoutCalibrationSettings) async {
        let loadedExercises = workout.exercises.filter { exercise in
            exercise.bodyweight == 0 && isWeightliftingExercise(exercise.name)
        }
        guard !loadedExercises.isEmpty else { return }

        let maxRecords: [OneRepMaxRecord] = (try? await dataClient.fetchAll(recordType: "OneRepMaxRecord")) ?? []
        let recentThreshold = Calendar.current.date(byAdding: .day, value: -120, to: Date()) ?? Date.distantPast
        let hasRecentMaxForWorkout = maxRecords.contains { record in
            loadedExercises.contains(where: {
                $0.name.compare(record.exerciseName, options: [.caseInsensitive]) == .orderedSame
            }) && record.date >= recentThreshold
        }
        guard !hasRecentMaxForWorkout else { return }

        let suggestions = StartingWeightCalibrationService.suggestions(
            for: workout,
            maxRecords: maxRecords,
            experienceLevel: settings.experienceLevel,
            recoveryScore: nil,
            unit: settings.weightUnit
        )
        let weightedSuggestions = suggestions.filter { $0.suggestedWeight != nil }
        guard !weightedSuggestions.isEmpty else { return }

        startingWeightSuggestions = weightedSuggestions
        showStartingWeightCalibrationSheet = true
    }

    private func prepareWarmupIfNeeded() async {
        guard completedSets == 0,
              currentExerciseIndex == 0,
              !workout.exercises.contains(where: { $0.category == .warmup }) else {
            pendingWarmupBlock = nil
            return
        }

        async let painLogs = loadPainLogsForWarmup()
        async let recoveryContext = loadRecoveryContextForWarmup()
        let context = await recoveryContext
        guard completedSets == 0,
              currentExerciseIndex == 0,
              !workout.exercises.contains(where: { $0.category == .warmup }) else {
            pendingWarmupBlock = nil
            return
        }

        pendingWarmupBlock = WarmupBuilder.build(
            request: WarmupRequest(
                workout: workout,
                recoveryScoreTotal: context?.totalScore,
                cyclePhase: context?.cyclePhase,
                painLogs: await painLogs,
                maxMinutes: 6
            )
        )
    }

    private func loadPainLogsForWarmup() async -> [DailyPainLog] {
        (try? await dataClient.fetchAll(recordType: "DailyPainLog")) ?? []
    }

    private func loadRecoveryContextForWarmup() async -> ActiveWarmupReadinessContext? {
        let records: [RecoveryScoreRecord] = (try? await dataClient.fetchAll(recordType: "RecoveryScore")) ?? []
        let dayString = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
        guard let record = records
            .filter({ $0.scoreDate == dayString })
            .sorted(by: { $0.dateCreated > $1.dateCreated })
            .first
        else { return nil }

        return ActiveWarmupReadinessContext(
            totalScore: record.totalScore,
            cyclePhase: record.cyclePhaseRaw.flatMap(CyclePhase.init(rawValue:))
        )
    }

    private func loadUserSettings() async -> WorkoutCalibrationSettings {
        let records: [UserSettingsRecord] = (try? await dataClient.fetchAll(recordType: "UserSettings")) ?? []
        guard let settings = records.last else {
            return WorkoutCalibrationSettings(
                experienceLevel: .beginner,
                weightUnit: .lbs,
                defaultEquipment: .fullGym
            )
        }

        return WorkoutCalibrationSettings(
            experienceLevel: ExperienceLevel(rawValue: settings.experienceLevel) ?? .beginner,
            weightUnit: WeightUnit(rawValue: settings.weightUnit) ?? .lbs,
            defaultEquipment: settings.defaultEquipment
        )
    }

    // MARK: - Private: Timers

    private func startElapsedTimer() {
        elapsedTimerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsedSeconds = Date().timeIntervalSince(self.startedAt)
                if !self.isResting {
                    self.updateLiveActivity()
                }
            }
    }

    private func startRestTimer(duration: TimeInterval) {
        restTimeRemaining = duration
        restTargetDuration = duration
        restStartedAt = Date()
        isResting = true

        restTimerCancellable = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let startedAt = self.restStartedAt else { return }
                let elapsed = Date().timeIntervalSince(startedAt)
                let remaining = duration - elapsed

                if remaining <= 0 {
                    self.restTimeRemaining = 0
                    self.isResting = false
                    self.restTimerCancellable?.cancel()
                    self.restTimerCancellable = nil
                    self.restStartedAt = nil
                    // Haptic feedback
#if canImport(UIKit) && os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
#endif
                } else {
                    self.restTimeRemaining = remaining
                }
                self.updateLiveActivity()
            }
    }

    private func stopRestTimer() {
        restTimerCancellable?.cancel()
        restTimerCancellable = nil
        restTimeRemaining = 0
        isResting = false
        restStartedAt = nil
    }

    // MARK: - Private: Navigation

    private func advanceToNextSet() {
        guard let exercise = currentExercise else { return }

        if currentSetIndex + 1 < exercise.targetSets.count {
            currentSetIndex += 1
        } else if currentExerciseIndex + 1 < workout.exercises.count {
            currentExerciseIndex += 1
            currentSetIndex = 0
        }
    }

    // MARK: - Private: Epley PR Check

    private func checkAndRecordPR(exerciseName: String, reps: Int, weight: Double) async {
        guard let estimated = estimatedOneRepMax(weight: weight, reps: reps) else { return }

        do {
            let records: [OneRepMaxRecord] = try await dataClient.fetchAll(
                recordType: "OneRepMaxRecord"
            )
            let currentMax = records
                .filter { $0.exerciseName == exerciseName }
                .max(by: { $0.weight < $1.weight })

            if estimated > (currentMax?.weight ?? 0) {
                let newRecord = OneRepMaxRecord(
                    id: UUID().uuidString,
                    exerciseName: exerciseName,
                    weight: estimated,
                    unit: .lbs,
                    date: Date()
                )
                try await dataClient.save(newRecord, recordType: "OneRepMaxRecord")
                celebrationEvents.append(.newPersonalRecord(exerciseName: exerciseName, weightKg: estimated / 2.20462))
                pendingPRShare = PendingPRShare(
                    exerciseName: exerciseName,
                    weight: estimated,
                    unit: "lb",
                    previousBest: currentMax?.weight
                )
                personalRecordExerciseNames.insert(exerciseName)
                HapticFeedback.success()
            }
        } catch {
            errorMessage = "Could not check PR: \(error.localizedDescription)"
        }
    }

    // MARK: - Private: Persistence

    private func saveProgress() async {
        do {
            try await dataClient.save(workout, recordType: "Workout")
        } catch {
            errorMessage = "Failed to save progress: \(error.localizedDescription)"
        }
    }

    private func requestReviewIfEligible() async {
        let completedWorkoutCount = await loadCompletedWorkoutCount()
        var triggers: [(ReviewPromptTrigger, String)] = [
            (.thirdWorkoutCompleted, "third-workout")
        ]

        if isCoachPlanWorkout {
            triggers.append((.firstCoachPlanCompleted, "coach-plan:\(workout.id)"))
        }

        if usedPainAwareSwap {
            triggers.append((.painAwareSwapWorkoutCompleted, "pain-aware-swap:\(workout.id)"))
        }

        for exerciseName in personalRecordExerciseNames.sorted() {
            triggers.append((.personalRecordLogged, "pr:\(exerciseName.lowercased())"))
        }

        for trigger in triggers {
            let didRequest = ReviewPromptCoordinator.recordSuccessfulAction(
                trigger: trigger.0,
                triggerID: trigger.1,
                completedWorkoutCount: completedWorkoutCount
            )
            if didRequest { break }
        }
    }

    private func loadCompletedWorkoutCount() async -> Int {
        do {
            let workouts: [Workout] = try await dataClient.fetchAll(recordType: "Workout")
            return workouts.filter(\.isComplete).count
        } catch {
            return workout.isComplete ? 1 : 0
        }
    }

    private var isCoachPlanWorkout: Bool {
        workout.name.localizedCaseInsensitiveContains("Coach Plan") ||
            (workout.notes?.localizedCaseInsensitiveContains("Coach Plan") ?? false)
    }

    private static func isPainAwareSwapReason(_ reason: String?) -> Bool {
        guard let reason = reason?.lowercased() else { return false }
        return reason.contains("pain") ||
            reason.contains("tightness") ||
            reason.contains("sore") ||
            reason.contains("injury")
    }

    // MARK: - Private: Live Activity

    private func updateLiveActivity() {
        let status: ActiveWorkoutStatus = isResting ? .resting : .active
        let snapshot = buildSnapshot(status: status)
#if canImport(ActivityKit) && os(iOS)
        liveActivityManager?.update(snapshot)
#endif
    }

    private func buildSnapshot(status: ActiveWorkoutStatus) -> ActiveWorkoutState {
        let totalSetsCount = totalSets
        let completedSetsCount = completedSets
        let totalExercisesCount = workout.exercises.count
        let completedExercisesCount = workout.exercises.filter { $0.targetSets.allSatisfy(\.isComplete) }.count

        let progress = ActiveWorkoutProgress(
            completedSets: completedSetsCount,
            totalSets: totalSetsCount,
            remainingSets: totalSetsCount - completedSetsCount,
            completedExercises: completedExercisesCount,
            totalExercises: totalExercisesCount
        )

        let currentStep: ActiveWorkoutState.Current? = currentExercise.map { exercise in
            let completedInExercise = exercise.targetSets.filter(\.isComplete).count
            let set = currentSet
            return ActiveWorkoutState.Current(
                exerciseName: exercise.name,
                exerciseIndex: currentExerciseIndex,
                setIndex: currentSetIndex,
                completedExerciseSets: completedInExercise,
                totalExerciseSets: exercise.targetSets.count,
                prescribedRepsText: set.map { "\($0.reps)" } ?? "",
                prescribedWeight: set?.prescribedWeight ?? 0,
                actualReps: set?.actualReps,
                completedWeight: set?.completedWeight,
                restSecondsAfterSet: exercise.restMinutes * 60
            )
        }

        // Build nextUp
        let nextUp: ActiveWorkoutState.NextUp?
        if hasNextSet {
            let exercise = workout.exercises[currentExerciseIndex]
            let nextSet = exercise.targetSets[currentSetIndex + 1]
            nextUp = ActiveWorkoutState.NextUp(
                exerciseName: exercise.name,
                exerciseIndex: currentExerciseIndex,
                setIndex: currentSetIndex + 1,
                prescribedRepsText: "\(nextSet.reps)",
                prescribedWeight: nextSet.prescribedWeight
            )
        } else if hasNextExercise {
            let nextExercise = workout.exercises[currentExerciseIndex + 1]
            let nextSet = nextExercise.targetSets[0]
            nextUp = ActiveWorkoutState.NextUp(
                exerciseName: nextExercise.name,
                exerciseIndex: currentExerciseIndex + 1,
                setIndex: 0,
                prescribedRepsText: "\(nextSet.reps)",
                prescribedWeight: nextSet.prescribedWeight
            )
        } else {
            nextUp = nil
        }

        // Build rest
        let rest: ActiveWorkoutState.Rest?
        if isResting, let restStart = restStartedAt {
            rest = ActiveWorkoutState.Rest(
                sourceExerciseName: workout.exercises[currentExerciseIndex].name,
                sourceSetIndex: currentSetIndex,
                targetDurationSeconds: restTargetDuration,
                startedAt: restStart
            )
        } else {
            rest = nil
        }

        return ActiveWorkoutState(
            workoutID: workout.id,
            workoutName: workout.name,
            status: status,
            lastUpdatedAt: Date(),
            elapsedSeconds: elapsedSeconds,
            progress: progress,
            current: currentStep,
            nextUp: nextUp,
            rest: rest
        )
    }
}

private struct WorkoutCalibrationSettings {
    let experienceLevel: ExperienceLevel
    let weightUnit: WeightUnit
    let defaultEquipment: EquipmentAccess
}

private struct ActiveWarmupReadinessContext {
    let totalScore: Int
    let cyclePhase: CyclePhase?
}
