import Foundation
import SwiftUI

// MARK: - ProgramDetailViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class ProgramDetailViewModel: ObservableObject {
    @Published var generatedProgram: GeneratedProgram?
    @Published var errorMessage: String?
    @Published var startingSessionId: String?
    @Published var completedSessionIds: Set<String> = []
    @Published var inProgressSessionIds: Set<String> = []
    @Published var latestAdaptationSummary: ProgramAdaptationSummary?
    private var adaptationPreviewBySessionId: [String: ProgramAdaptationSummary] = [:]
    private var sessionWorkoutMap: [String: String] = [:]

    private let program: ProgramListItem
    private let dataClient: DataClientProtocol

    private let healthClient: HealthClientProtocol

    init(
        program: ProgramListItem,
        dataClient: DataClientProtocol = DataClientFactory.shared.client,
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client
    ) {
        self.program = program
        self.dataClient = dataClient
        self.healthClient = healthClient
    }

    func generateSessions() {
        guard let template = program.template else {
            // Fallback: build a minimal program structure from metadata without sessions
            generatedProgram = GeneratedProgram(
                id: program.id,
                name: program.name,
                category: program.category,
                description: program.description,
                durationWeeks: program.durationWeeks,
                sessionsPerWeek: program.sessionsPerWeek,
                difficulty: program.difficulty,
                phases: [],
                weeks: []
            )
            return
        }
        generatedProgram = generateProgram(
            template: template,
            name: program.name,
            durationWeeks: program.durationWeeks,
            sessionsPerWeek: program.sessionsPerWeek
        )
    }

    func loadSessionProgress() async {
        do {
            let allRecords: [ProgramSessionRecord] = try await dataClient.fetchAll(recordType: "ProgramSessionRecord")
            let programRecords = allRecords.filter { $0.programId == program.id }
            guard !programRecords.isEmpty else { return }

            let allWorkouts: [Workout] = try await dataClient.fetchAll(recordType: "Workout")
            let completedWorkoutIds = Set(allWorkouts.filter(\.isComplete).map(\.id))

            var newInProgress: Set<String> = []
            var newCompleted: Set<String> = []
            var newWorkoutMap: [String: String] = [:]
            for record in programRecords {
                newInProgress.insert(record.sessionId)
                newWorkoutMap[record.sessionId] = record.workoutId
                if completedWorkoutIds.contains(record.workoutId) {
                    newCompleted.insert(record.sessionId)
                }
            }

            inProgressSessionIds = newInProgress
            completedSessionIds = newCompleted
            sessionWorkoutMap = newWorkoutMap
        } catch {
            // Non-critical — progress display is best-effort
        }
    }

    func resumeWorkoutId(for sessionId: String) -> String? {
        let workoutId = sessionWorkoutMap[sessionId]
        guard let workoutId, inProgressSessionIds.contains(sessionId),
              !completedSessionIds.contains(sessionId) else { return nil }
        return workoutId
    }

    func adaptationPreview(for sessionId: String) -> ProgramAdaptationSummary? {
        adaptationPreviewBySessionId[sessionId]
    }

    func loadAdaptationPreviews() async {
        guard let generatedProgram else { return }
        let context = await loadAdaptationContext()
        var previews: [String: ProgramAdaptationSummary] = [:]

        for week in generatedProgram.weeks {
            for session in week.sessions {
                let result = ProgramSessionAdaptationService.adaptWithSummary(
                    session.exercises,
                    context: context
                )
                previews[session.sessionId] = result.summary
            }
        }

        adaptationPreviewBySessionId = previews
    }

    func startSession(
        _ session: GeneratedProgramSession,
        week: Int,
        programName: String,
        quickEdit: ProgramSessionQuickEdit? = nil
    ) async -> ProgramSessionLaunchResult? {
        guard startingSessionId == nil else { return nil }
        startingSessionId = session.sessionId
        defer { startingSessionId = nil }

        // Load adaptive context and user maxes in parallel. The PDF remains the
        // base plan; the in-app workout adapts before the active session opens.
        async let adaptationContextTask = loadAdaptationContext()
        async let maxesTask = loadMaxes()
        let (adaptationContext, maxes) = await (adaptationContextTask, maxesTask)
        let adaptationResult = ProgramSessionAdaptationService.adaptWithSummary(
            session.exercises,
            context: adaptationContext
        )
        latestAdaptationSummary = adaptationResult.summary
        let originalEdited = Self.applyQuickEdit(quickEdit, to: session.exercises)
        let edited = Self.applyQuickEdit(quickEdit, to: adaptationResult.exercises)
        for edit in edited.edits {
            await CoachMemoryService(dataClient: dataClient).recordWorkoutEdit(edit)
        }
        let cycleMult = aiCyclePhaseMultiplier(adaptationContext.cyclePhase)
        let recoveryMult = InjuryAdaptationEngine.calculateLoadMultiplier(
            baseLoad: 1.0,
            injuries: adaptationContext.injuries
        )
        let workoutID = UUID().uuidString
        let workoutName = "\(programName) — \(session.sessionName)"
        let workoutDate = Date()
        let originalWorkout = Self.makeWorkout(
            id: workoutID,
            date: workoutDate,
            name: workoutName,
            exercises: originalEdited.exercises,
            maxes: maxes,
            cycleMultiplier: 1.0
        )
        let workout = Self.makeWorkout(
            id: workoutID,
            date: workoutDate,
            name: workoutName,
            exercises: edited.exercises,
            maxes: maxes,
            cycleMultiplier: cycleMult,
            recoveryMultiplier: recoveryMult
        )

        do {
            try await dataClient.save(workout, recordType: "Workout")
            let quickEditReasons = Self.quickEditReasons(
                edits: edited.edits,
                quickEdit: quickEdit
            )
            let shouldCreateDecisionRecord = !adaptationResult.summary.changes.isEmpty || !quickEditReasons.isEmpty
            let adaptationDecisionRecord = shouldCreateDecisionRecord
                ? try? await WorkoutAdaptationDecisionService.record(
                    originalWorkout: originalWorkout,
                    adaptedWorkout: workout,
                    summary: adaptationResult.summary,
                    context: adaptationContext,
                    additionalReasons: quickEditReasons,
                    dataClient: dataClient
                )
                : nil

            // Save session record to track progress through the program.
            // Non-critical — workout is already saved; session record is for progress display.
            let sessionRecord = ProgramSessionRecord(
                id: UUID().uuidString,
                programId: program.id,
                sessionId: session.sessionId,
                workoutId: workout.id,
                week: week
            )
            try? await dataClient.save(sessionRecord, recordType: "ProgramSessionRecord")
            inProgressSessionIds.insert(session.sessionId)
            sessionWorkoutMap[session.sessionId] = workout.id

            return ProgramSessionLaunchResult(
                workout: workout,
                adaptationDecisionRecord: adaptationDecisionRecord
            )
        } catch {
            errorMessage = "Couldn't start this session right now. Please try again."
            return nil
        }
    }

    // MARK: - Cycle & Max Helpers

    private static func makeWorkout(
        id: String,
        date: Date,
        name: String,
        exercises: [GeneratedProgramExercise],
        maxes: [OneRepMaxRecord],
        cycleMultiplier: Double,
        recoveryMultiplier: Double = 1.0
    ) -> Workout {
        Workout(
            id: id,
            date: date,
            name: name,
            exercises: exercises.map { ex in
                let setCount: Int
                if case .fixed(let n) = ex.sets { setCount = n } else { setCount = 3 }

                let repCount: Int
                let setType: ExerciseType
                switch ex.reps {
                case .fixed(let n):
                    repCount = n
                    setType = .fixed
                case .amrap:
                    repCount = 0
                    setType = .amrap
                case .range(let lo, let hi):
                    repCount = lo
                    setType = .range(min: lo, max: hi)
                case .text(let t):
                    repCount = 0
                    setType = .text(t)
                }

                var prescribedWeight: Double = 0
                if !ex.bodyweightOnly, ex.percent1RM != nil,
                   let userMax = maxes.first(where: { $0.exerciseName.lowercased() == ex.exercise.lowercased() }) {
                    prescribedWeight = calculatePrescribedWeight(
                        max: userMax.weight,
                        reps: repCount > 0 ? repCount : 5,
                        overridePercentage: ex.percent1RM,
                        cycleMultiplier: cycleMultiplier,
                        recoveryMultiplier: recoveryMultiplier
                    )
                }

                let targetSets = (0..<setCount).map { _ in
                    ExerciseSet(
                        reps: repCount,
                        prescribedWeight: prescribedWeight,
                        prescribedPercentage: ex.percent1RM,
                        type: setType
                    )
                }

                return Exercise(
                    id: UUID().uuidString,
                    name: ex.exercise,
                    category: ex.bodyweightOnly ? .accessory : (isWeightliftingExercise(ex.exercise) ? .compound : .accessory),
                    bodyweight: ex.bodyweightOnly ? 1.0 : 0.0,
                    targetSets: targetSets,
                    restMinutes: ex.restMinutes
                )
            }
        )
    }

    private static func applyQuickEdit(
        _ edit: ProgramSessionQuickEdit?,
        to exercises: [GeneratedProgramExercise]
    ) -> (exercises: [GeneratedProgramExercise], edits: [WorkoutEdit]) {
        guard let edit else { return (exercises, []) }

        switch edit {
        case .shorten(let minutes):
            let targetCount: Int
            switch minutes {
            case ...20: targetCount = 3
            case 21...30: targetCount = 4
            case 31...45: targetCount = 5
            default: targetCount = exercises.count
            }
            let kept = Array(exercises.prefix(max(1, targetCount)))
            let removed = exercises.dropFirst(kept.count)
            return (
                kept,
                removed.map { WorkoutEdit(editType: .removedExercise, exerciseName: $0.exercise) }
            )
        case .reduceVolume:
            var edits: [WorkoutEdit] = []
            let reduced = exercises.map { exercise in
                let reducedSets = reduceSets(exercise.sets)
                if reducedSets != exercise.sets {
                    edits.append(WorkoutEdit(editType: .changedVolume, exerciseName: exercise.exercise))
                }
                return copyProgramExercise(exercise, sets: reducedSets)
            }
            return (reduced, edits)
        case .removeLastExercise:
            guard exercises.count > 1, let removed = exercises.last else { return (exercises, []) }
            return (
                Array(exercises.dropLast()),
                [WorkoutEdit(editType: .removedExercise, exerciseName: removed.exercise)]
            )
        case .swapLastExercise:
            guard let last = exercises.last,
                  let replacement = replacementExercise(for: last, existingExercises: exercises) else {
                return (exercises, [])
            }
            var swapped = exercises
            swapped[swapped.count - 1] = replacement
            return (
                swapped,
                [WorkoutEdit(
                    editType: .swappedExercise,
                    exerciseName: last.exercise,
                    replacementExercise: replacement.exercise
                )]
            )
        case .restoreOriginal:
            return (exercises, [])
        }
    }

    private static func quickEditReasons(
        edits: [WorkoutEdit],
        quickEdit: ProgramSessionQuickEdit?
    ) -> [(id: String, text: String)] {
        guard !edits.isEmpty else { return [] }

        switch quickEdit {
        case .shorten(let minutes):
            return [("quick_edit", "Session was shortened to fit \(minutes) minutes.")]
        case .reduceVolume:
            return [("quick_edit", "Session volume was reduced before adaptation.")]
        case .removeLastExercise:
            return [("quick_edit", "The last exercise was removed before adaptation.")]
        case .swapLastExercise:
            return [("quick_edit", "The last exercise was swapped before adaptation.")]
        case .restoreOriginal, .none:
            return []
        }
    }

    private static func reduceSets(_ sets: ExerciseValue) -> ExerciseValue {
        switch sets {
        case .fixed(let value):
            return .fixed(value: max(1, value - 1))
        case .range(let low, let high):
            return .range(low: max(1, low - 1), high: max(1, high - 1))
        case .amrap, .text:
            return sets
        }
    }

    private static func copyProgramExercise(
        _ exercise: GeneratedProgramExercise,
        sets: ExerciseValue
    ) -> GeneratedProgramExercise {
        GeneratedProgramExercise(
            exercise: exercise.exercise,
            sets: sets,
            reps: exercise.reps,
            percent1RM: exercise.percent1RM,
            restMinutes: exercise.restMinutes,
            bodyweightOnly: exercise.bodyweightOnly
        )
    }

    private static func copyProgramExercise(
        _ exercise: GeneratedProgramExercise,
        exerciseName: String,
        percent1RM: Double?,
        bodyweightOnly: Bool
    ) -> GeneratedProgramExercise {
        GeneratedProgramExercise(
            exercise: exerciseName,
            sets: exercise.sets,
            reps: exercise.reps,
            percent1RM: percent1RM,
            restMinutes: exercise.restMinutes,
            bodyweightOnly: bodyweightOnly
        )
    }

    private static func replacementExercise(
        for exercise: GeneratedProgramExercise,
        existingExercises: [GeneratedProgramExercise]
    ) -> GeneratedProgramExercise? {
        let existingNames = Set(existingExercises.map { $0.exercise.lowercased() })
        let targetDefinition = trainingExerciseCatalog.first {
            $0.id.compare(exercise.exercise, options: [.caseInsensitive]) == .orderedSame
        }
        let targetPattern = targetDefinition?.movementPattern ?? inferredMovementPattern(for: exercise.exercise)
        let targetTags = Set(targetDefinition?.equipmentTags ?? [])
        let targetCategory = targetDefinition?.categoryLabel.lowercased()

        let candidates = trainingExerciseCatalog
            .filter { candidate in
                candidate.movementPattern == targetPattern
                    && !existingNames.contains(candidate.id.lowercased())
                    && !candidate.equipmentTags.contains(.cardio)
            }
            .sorted { lhs, rhs in
                swapCandidateScore(
                    lhs,
                    targetTags: targetTags,
                    targetCategory: targetCategory,
                    targetBodyweightOnly: exercise.bodyweightOnly,
                    targetIsMaxTrackable: targetDefinition?.isMaxTrackable ?? isWeightliftingExercise(exercise.exercise)
                ) > swapCandidateScore(
                    rhs,
                    targetTags: targetTags,
                    targetCategory: targetCategory,
                    targetBodyweightOnly: exercise.bodyweightOnly,
                    targetIsMaxTrackable: targetDefinition?.isMaxTrackable ?? isWeightliftingExercise(exercise.exercise)
                )
            }

        guard let replacement = candidates.first else { return nil }
        return copyProgramExercise(
            exercise,
            exerciseName: replacement.id,
            percent1RM: replacement.isMaxTrackable ? exercise.percent1RM : nil,
            bodyweightOnly: replacement.bodyweightOnly
        )
    }

    private static func inferredMovementPattern(for exerciseName: String) -> WorkoutMovementPattern {
        let lower = exerciseName.lowercased()
        if lower.contains("squat") || lower.contains("lunge") || lower.contains("step-up") {
            return .squat
        }
        if lower.contains("deadlift") || lower.contains("hinge") || lower.contains("good morning") || lower.contains("swing") {
            return .hinge
        }
        if lower.contains("press") || lower.contains("push") || lower.contains("dip") {
            return .push
        }
        if lower.contains("pull") || lower.contains("row") || lower.contains("curl") {
            return .pull
        }
        if lower.contains("carry") || lower.contains("walk") {
            return .carry
        }
        if lower.contains("plank") || lower.contains("bug") || lower.contains("sit-up") || lower.contains("v-up") {
            return .core
        }
        return .conditioning
    }

    private static func swapCandidateScore(
        _ candidate: TrainingExerciseDefinition,
        targetTags: Set<TrainingEquipmentTag>,
        targetCategory: String?,
        targetBodyweightOnly: Bool,
        targetIsMaxTrackable: Bool
    ) -> Int {
        var score = 0
        if !targetTags.isDisjoint(with: candidate.equipmentTags) { score += 20 }
        if candidate.categoryLabel.lowercased() == targetCategory { score += 10 }
        if candidate.bodyweightOnly == targetBodyweightOnly { score += 5 }
        if candidate.isMaxTrackable == targetIsMaxTrackable { score += 3 }
        return score
    }

    private func loadAdaptationContext() async -> ProgramSessionAdaptationContext {
        async let cyclePhase = loadCyclePhase()
        async let cycleConfidence = loadCycleConfidence()
        async let injuries = loadInjuries()
        async let painLogs = loadPainLogs()
        async let equipment = loadDefaultEquipment()
        async let recentEffortRPE = loadRecentEffortRPE()

        let (
            resolvedPhase,
            resolvedConfidence,
            resolvedInjuries,
            resolvedPain,
            resolvedEquipment,
            resolvedEffortRPE
        ) = await (
            cyclePhase,
            cycleConfidence,
            injuries,
            painLogs,
            equipment,
            recentEffortRPE
        )

        let painIntensity = resolvedPain
            .sorted { $0.date > $1.date }
            .first?
            .intensity
        let deload = DeloadDetectionService.recommendation(
            recentPainLogs: resolvedPain
        ).isRecommended

        return ProgramSessionAdaptationContext(
            cyclePhase: resolvedPhase,
            injuries: resolvedInjuries,
            painIntensity: painIntensity,
            equipment: resolvedEquipment,
            cycleConfidence: resolvedConfidence,
            deloadRecommended: deload,
            recentEffortRPE: resolvedEffortRPE
        )
    }

    private func loadCyclePhase() async -> CyclePhase? {
        // Fast path: active manual period = menstrual phase
        do {
            let manualRecords = try await dataClient.fetchAll(
                recordType: "PeriodLogRecord"
            ) as [PeriodLogRecord]
            if manualRecords.contains(where: { $0.isActive }) {
                return .menstrual
            }
        } catch { /* continue */ }

        var periodLogs: [PeriodLog] = []

        if healthClient.isAvailable {
            do {
                try? await healthClient.requestStandardAuthorization()
                let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())
                let cycles = try await healthClient.fetchMenstrualCycles(
                    startDate: sixMonthsAgo, endDate: nil, limit: 100
                )
                if !cycles.isEmpty {
                    periodLogs = CyclePhaseHelper.convertToPeriodLogs(cycles)
                }
            } catch { /* no HealthKit */ }
        }

        do {
            let manualRecords = try await dataClient.fetchAll(
                recordType: "PeriodLogRecord"
            ) as [PeriodLogRecord]
            for log in manualRecords.map({ $0.toPeriodLog() }) {
                let isDuplicate = periodLogs.contains {
                    abs($0.startDate.timeIntervalSince(log.startDate)) < 86400
                }
                if !isDuplicate { periodLogs.append(log) }
            }
        } catch { /* no manual logs */ }

        guard !periodLogs.isEmpty else { return nil }

        var settings = CycleSettings()
        if let records = try? await dataClient.fetchAll(
            recordType: "CycleSettings"
        ) as [CycleSettingsRecord], let first = records.first {
            settings = CycleSettings(averageCycleLengthDays: first.averageCycleLengthDays)
        }

        if let status = calculateCycleStatus(periodLogs: periodLogs, settings: settings) {
            return status.currentPhase
        }
        return nil
    }

    private func loadInjuries() async -> [Injury] {
        (try? await dataClient.fetchAll(recordType: "Injury") as [Injury]) ?? []
    }

    private func loadCycleConfidence() async -> Double? {
        let logs: [PeriodLog] = (try? await dataClient.fetchAll(recordType: "PeriodLogRecord")) ?? []
        guard !logs.isEmpty else { return nil }
        return CyclePhaseHelper.calculateConfidence(
            periodLogCount: logs.count,
            lastPeriodStart: logs.sorted { $0.startDate > $1.startDate }.first?.startDate
        )
    }

    private func loadPainLogs() async -> [DailyPainLog] {
        (try? await dataClient.fetchAll(recordType: "DailyPainLog") as [DailyPainLog]) ?? []
    }

    private func loadDefaultEquipment() async -> EquipmentAccess {
        let records: [UserSettingsRecord] = (try? await dataClient.fetchAll(recordType: "UserSettings")) ?? []
        return records.last?.defaultEquipment ?? .fullGym
    }

    private func loadRecentEffortRPE() async -> Int? {
        let records: [WorkoutEffortLog] = (try? await dataClient.fetchAll(recordType: "WorkoutEffortLog")) ?? []
        return records.sorted { $0.dateCreated > $1.dateCreated }.first?.rpe
    }

    private func loadMaxes() async -> [OneRepMaxRecord] {
        (try? await dataClient.fetchAll(recordType: "OneRepMaxRecord") as [OneRepMaxRecord]) ?? []
    }
}
