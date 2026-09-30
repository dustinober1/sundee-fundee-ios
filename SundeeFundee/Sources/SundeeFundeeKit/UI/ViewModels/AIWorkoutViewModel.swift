import Foundation
import SwiftUI

// MARK: - AIWorkoutViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class AIWorkoutViewModel: ObservableObject {
    enum ViewState: Equatable {
        case questionnaire
        case generating
        case preview
        case error(String)
    }

    @Published var state: ViewState = .questionnaire
    @Published var timeMinutes: Int = 45
    @Published var focus: WorkoutFocus = .fullBody
    @Published var energyLevel: EnergyLevel = .medium
    @Published var equipment: EquipmentAccess = .fullGym
    @Published var selectedEquipmentProfileID: String?
    @Published var equipmentProfiles: [EquipmentProfile] = []
    @Published var cyclePhase: CyclePhase?
    @Published var generatedWorkout: GeneratedWorkout?
    @Published var coachingTips: [String] = []
    @Published var swapState: ExerciseSwapState?
    @Published var workoutRationale: WorkoutRationale?
    @Published var changeNotes: [WorkoutChangeNote] = []
    @Published var submittedFeedback: CoachPlanFeedbackRating?

    private let coachService: CoachServiceProtocol
    private let contextBuilder: CoachContextBuilder
    private let memoryService: CoachMemoryService
    private let dataClient: DataClientProtocol
    private let equipmentProfileService: EquipmentProfileService
    private let feedbackService: CoachPlanFeedbackService
    private let todayPreferenceService: TodayWorkoutPreferenceService
    private var cachedContext: CoachContext?
    private var editableDraft: EditableWorkoutDraft?
    private var hasLoadedDefaultEquipment = false

    init(
        coachService: CoachServiceProtocol = CoachServiceFactory.makeService(),
        contextBuilder: CoachContextBuilder = CoachContextBuilder(),
        memoryService: CoachMemoryService = CoachMemoryService(),
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.coachService = coachService
        self.contextBuilder = contextBuilder
        self.memoryService = memoryService
        self.dataClient = dataClient
        self.equipmentProfileService = EquipmentProfileService(dataClient: dataClient)
        self.feedbackService = CoachPlanFeedbackService(dataClient: dataClient)
        self.todayPreferenceService = TodayWorkoutPreferenceService(dataClient: dataClient)
    }

    func loadContext() async {
        if equipmentProfiles.isEmpty {
            equipmentProfiles = await equipmentProfileService.loadProfiles()
        }
        if !hasLoadedDefaultEquipment {
            equipment = await loadDefaultEquipment()
            hasLoadedDefaultEquipment = true
        }
        let context = await contextBuilder.build(equipment: equipment)
        cyclePhase = context.cyclePhase
    }

    private func loadDefaultEquipment() async -> EquipmentAccess {
        let hasPersistedProfiles = await equipmentProfileService.hasPersistedProfiles()
        let legacyDefaultEquipment = hasPersistedProfiles ? nil : await loadLegacyDefaultEquipment()
        let selection = AIWorkoutEquipmentDefaultResolver.resolve(
            profiles: equipmentProfiles,
            hasPersistedProfiles: hasPersistedProfiles,
            legacyDefaultEquipment: legacyDefaultEquipment
        )
        selectedEquipmentProfileID = selection.selectedProfileID
        return selection.equipment
    }

    private func loadLegacyDefaultEquipment() async -> EquipmentAccess? {
        do {
            let records = try await dataClient.fetchAll(
                recordType: "UserSettings"
            ) as [UserSettingsRecord]
            return records.last?.defaultEquipment
        } catch {
            return nil
        }
    }

    func selectEquipmentProfile(_ profile: EquipmentProfile) {
        selectedEquipmentProfileID = profile.id
        equipment = profile.equipment
    }

    func selectRawEquipment(_ equipment: EquipmentAccess) {
        selectedEquipmentProfileID = nil
        self.equipment = equipment
    }

    func isRawEquipmentSelected(_ equipment: EquipmentAccess) -> Bool {
        selectedEquipmentProfileID == nil && self.equipment == equipment
    }

    func generateWorkout() async {
        state = .generating

        let questionnaire = QuestionnaireAnswers(
            timeMinutes: timeMinutes,
            focus: focus,
            energyLevel: energyLevel,
            equipment: equipment
        )

        do {
            let context = await contextBuilder.build(equipment: equipment)
            cachedContext = context
            let response = try await coachService.generateWorkout(
                context: context,
                preferences: questionnaire
            )

            let adjustment = CycleAwareAdjustmentService.adjustment(
                phase: context.cyclePhase,
                energyLevel: energyLevel,
                goal: context.primaryGoal,
                equipment: equipment
            )
            let adjustedWorkout = CycleAwareAdjustmentService.apply(adjustment, to: response.workout)
            generatedWorkout = adjustedWorkout
            editableDraft = EditableWorkoutDraft(workout: adjustedWorkout)
            if let packet = response.decisionPacket {
                workoutRationale = CoachRationaleBuilder.rationale(from: packet)
            } else {
                workoutRationale = adjustment.rationale
            }
            changeNotes = WorkoutChangeExplanationService.notes(
                context: context,
                energyLevel: energyLevel,
                equipment: equipment
            )
            coachingTips = response.tips
            cyclePhase = context.cyclePhase
            state = .preview
            await GrowthAnalyticsService(dataClient: dataClient).track(
                GrowthEventName.aiWorkoutGenerated,
                source: "ai_workout"
            )
            if context.cyclePhase != nil {
                await GrowthAnalyticsService(dataClient: dataClient).track(
                    GrowthEventName.cycleAwareAdjustmentShown,
                    source: "ai_workout"
                )
            }
        } catch {
            state = .error("Could not generate workout. Please try again.")
        }
    }

    var canRemoveExercise: Bool {
        (generatedWorkout?.exercises.count ?? 0) > 1
    }

    func shortenWorkout(to minutes: Int) {
        mutateDraft { draft in
            draft.shorten(to: minutes)
        }
        Task { try? await todayPreferenceService.saveDurationPreference(minutes: minutes) }
    }

    func reduceVolume() {
        mutateDraft { draft in
            draft.reduceVolume()
        }
        Task { try? await todayPreferenceService.saveReducedVolume() }
    }

    func removeExercise(id: String) {
        mutateDraft { draft in
            draft.removeExercise(id: id)
        }
    }

    func restoreOriginalWorkout() {
        guard var draft = editableDraft else { return }
        draft.restoreOriginal()
        editableDraft = draft
        generatedWorkout = draft.workout
    }

    func trackWorkoutStarted() async {
        await GrowthAnalyticsService(dataClient: dataClient).track(
            GrowthEventName.aiWorkoutStarted,
            source: "ai_workout"
        )
    }

    func submitFeedback(_ rating: CoachPlanFeedbackRating) async {
        submittedFeedback = rating
        let reasonCodes = workoutRationale.map { rationale in
            [rationale.headline] + rationale.reasons + rationale.cautions
        } ?? []

        try? await feedbackService.submit(
            rating: rating,
            surface: "coach_plan_preview",
            workoutID: generatedWorkout?.id,
            copySource: "coach_plan_copy",
            promptVersion: "v1",
            reasonCodes: reasonCodes
        )
        await GrowthAnalyticsService(dataClient: dataClient).track(
            rating == .helpful
                ? GrowthEventName.coachPlanFeedbackHelpful
                : GrowthEventName.coachPlanFeedbackNotHelpful,
            source: "coach_plan"
        )
    }

    func loadSubstitutions(for exerciseId: String) async {
        guard let workout = generatedWorkout,
              let exercise = workout.exercises.first(where: { $0.id == exerciseId }) else { return }

        swapState = ExerciseSwapState(exerciseId: exerciseId, exerciseName: exercise.name, substitutions: [], isLoading: true)

        do {
            let context: CoachContext
            if let cached = cachedContext {
                context = cached
            } else {
                context = await contextBuilder.build(equipment: equipment)
            }
            cachedContext = context
            let response = try await coachService.suggestSubstitutions(
                for: exercise.name,
                context: context
            )
            let painLogs: [DailyPainLog] = (try? await dataClient.fetchAll(recordType: "DailyPainLog")) ?? []
            let painAware = PainAwareSubstitutionService.rank(
                currentExercise: exercise.name,
                recentPainLogs: painLogs,
                injuries: context.injuries,
                equipment: equipment,
                limit: 3
            ).map(\.substitution)
            swapState = ExerciseSwapState(
                exerciseId: exerciseId,
                exerciseName: exercise.name,
                substitutions: uniqueSubstitutions(painAware + response.substitutions),
                explanation: response.explanation,
                isLoading: false
            )
        } catch {
            swapState = ExerciseSwapState(
                exerciseId: exerciseId,
                exerciseName: exercise.name,
                substitutions: [],
                isLoading: false
            )
        }
    }

    func swapExercise(with substitution: SubstitutionRanker.RankedSubstitution) {
        guard let workout = generatedWorkout,
              let index = workout.exercises.firstIndex(where: { $0.id == swapState?.exerciseId }) else { return }

        let old = workout.exercises[index]
        let isBodyweight = !SubstitutionRanker.rank(substitutesFor: substitution.exerciseName, limit: 1).isEmpty
            || substitution.exerciseName.lowercased().contains("push-up")
            || substitution.exerciseName.lowercased().contains("pull-up")
            || substitution.exerciseName.lowercased().contains("air squat")
            || substitution.exerciseName.lowercased().contains("burpee")
            || substitution.exerciseName.lowercased().contains("plank")
            || substitution.exerciseName.lowercased().contains("sit-up")
            || substitution.exerciseName.lowercased().contains("v-up")
            || substitution.exerciseName.lowercased().contains("dip")

        let newExercise = GeneratedExercise(
            id: UUID().uuidString,
            name: substitution.exerciseName,
            sets: old.sets,
            reps: old.reps,
            weightKg: nil,
            restMinutes: nil,
            notes: "Swapped for \(old.name)",
            reasoning: substitution.reason,
            bodyweightOnly: isBodyweight
        )

        let eMult = energyMultiplier(energyLevel)
        let cMult = aiCyclePhaseMultiplier(cyclePhase)
        let context = cachedContext
        let maxes = context?.maxes ?? []
        let rMult = InjuryAdaptationEngine.calculateLoadMultiplier(
            baseLoad: 1.0,
            injuries: cachedContext?.injuries ?? []
        )
        let weighted = applyWeights(
            exercises: {
                var updatedExercises = workout.exercises
                updatedExercises[index] = newExercise
                return updatedExercises
            }(),
            maxes: maxes,
            energyMult: eMult,
            cycleMult: cMult,
            recoveryMult: rMult
        )
        let final = weighted.map { ex -> GeneratedExercise in
            guard ex.restMinutes == nil else { return ex }
            return GeneratedExercise(
                id: ex.id, name: ex.name, sets: ex.sets, reps: ex.reps,
                weightKg: ex.weightKg,
                restMinutes: assignRestMinutes(bodyweight: ex.bodyweightOnly, reps: ex.reps),
                notes: ex.notes, reasoning: ex.reasoning, bodyweightOnly: ex.bodyweightOnly,
                percentageOfMax: ex.percentageOfMax
            )
        }

        if var draft = editableDraft, final.indices.contains(index) {
            let previousEditCount = draft.edits.count
            _ = draft.swapExercise(id: old.id, replacement: final[index])
            editableDraft = draft
            generatedWorkout = draft.workout
            recordDraftEdits(Array(draft.edits.dropFirst(previousEditCount)))
        } else {
            generatedWorkout = GeneratedWorkout(
                id: workout.id,
                createdAt: workout.createdAt,
                isFavorite: workout.isFavorite,
                coachingSummary: workout.coachingSummary,
                exercises: final,
                questionnaire: workout.questionnaire
            )
        }

        Task {
            await memoryService.recordSubstitutionDecision(
                AcceptedSubstitution(
                    originalExercise: old.name,
                    substituteExercise: substitution.exerciseName,
                    accepted: true,
                    reason: substitution.reason
                )
            )
            if substitution.reason.lowercased().contains("pain") ||
                substitution.reason.lowercased().contains("tightness") {
                await GrowthAnalyticsService(dataClient: dataClient).track(
                    GrowthEventName.painAwareSubstitutionUsed,
                    source: "ai_workout",
                    properties: [
                        "from": old.name,
                        "to": substitution.exerciseName
                    ]
                )
            }
        }

        swapState = nil
    }

    func dismissSwap() {
        swapState = nil
    }

    func buildWorkoutForSession() -> Workout? {
        guard let generated = generatedWorkout else { return nil }
        return buildWorkout(
            from: generated,
            name: "\(focus.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) Coach Plan",
            notesPrefix: "Coach Plan"
        )
    }

    private func mutateDraft(_ mutation: (inout EditableWorkoutDraft) -> Bool) {
        guard var draft = editableDraft else { return }
        let previousEditCount = draft.edits.count
        guard mutation(&draft) else { return }
        editableDraft = draft
        generatedWorkout = draft.workout
        recordDraftEdits(Array(draft.edits.dropFirst(previousEditCount)))
    }

    private func recordDraftEdits(_ edits: [WorkoutEdit]) {
        guard !edits.isEmpty else { return }
        Task {
            for edit in edits {
                await memoryService.recordWorkoutEdit(edit)
            }
        }
    }

    private func uniqueSubstitutions(
        _ substitutions: [SubstitutionRanker.RankedSubstitution]
    ) -> [SubstitutionRanker.RankedSubstitution] {
        var seen = Set<String>()
        return substitutions.filter { substitution in
            seen.insert(substitution.exerciseName).inserted
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ExerciseSwapState: Equatable {
    let exerciseId: String
    let exerciseName: String
    let substitutions: [SubstitutionRanker.RankedSubstitution]
    let explanation: String?
    let isLoading: Bool

    init(exerciseId: String, exerciseName: String,
         substitutions: [SubstitutionRanker.RankedSubstitution] = [],
         explanation: String? = nil, isLoading: Bool = false) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.substitutions = substitutions
        self.explanation = explanation
        self.isLoading = isLoading
    }

    static func == (lhs: ExerciseSwapState, rhs: ExerciseSwapState) -> Bool {
        lhs.exerciseId == rhs.exerciseId &&
        lhs.exerciseName == rhs.exerciseName &&
        lhs.substitutions == rhs.substitutions &&
        lhs.explanation == rhs.explanation &&
        lhs.isLoading == rhs.isLoading
    }
}
