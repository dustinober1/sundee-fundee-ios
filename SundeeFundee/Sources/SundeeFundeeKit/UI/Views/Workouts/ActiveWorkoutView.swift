import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - ActiveWorkoutView
//
// Full-screen modal that guides users through a workout set-by-set.
// Connects to ActiveWorkoutSessionViewModel which handles all business logic.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ActiveWorkoutView: View {
    @ObservedObject var viewModel: ActiveWorkoutSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @ObservedObject private var syncDiagnostics = SyncQueueDiagnosticsService.shared
    @State private var showAbandonAlert = false
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    @State private var showingSwapSheet = false
    @State private var showingSwapConfirm = false
    @State private var showingWorkoutShare = false
    @State private var showingWorkoutDetails = false
    @State private var showingWorkoutOptionsDialog = false
    @State private var pendingSwap: SubstitutionRanker.RankedSubstitution?
    @State private var showingStationTakenPicker = false
    @State private var showingStationTakenSwapSheet = false
    @State private var selectedBlockedStation: BlockedStationKind?
    @State private var stationTakenExercise: StationTakenExerciseSnapshot?
    @State private var pendingStationTakenExercise: StationTakenExerciseSnapshot?
    @State private var stationTakenSwaps: [SubstitutionRanker.RankedSubstitution] = []
    @State private var showingEquipmentConversionPicker = false
    @State private var selectedSetRPE: Int?
    @State private var pendingCompletionInput: CompletionInput?
    @State private var showingSessionEffortDialog = false
    @State private var showingCompletionCheckIn = false
    @State private var undoBlockedReason: String?
    @State private var equipmentProfiles: [EquipmentProfile] = []
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool

    private struct CompletionInput {
        let reps: Int
        let weight: Double
        let setRPE: Int?
    }

    public init(viewModel: ActiveWorkoutSessionViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            if viewModel.isComplete {
                completionView
            } else {
                activeWorkoutView
            }
        }
        .artDecoBackground()
        .alert("Abandon Workout?", isPresented: $showAbandonAlert) {
            Button("Keep Going", role: .cancel) { }
            Button("Abandon", role: .destructive) {
                Task {
                    await viewModel.abandonWorkout()
                    dismiss()
                }
            }
        } message: {
            Text("Your progress will be saved. Are you sure you want to stop this workout?")
        }
        .alert("Couldn't undo changes", isPresented: Binding(
            get: { undoBlockedReason != nil },
            set: { if !$0 { undoBlockedReason = nil } }
        )) {
            Button("OK") { undoBlockedReason = nil }
        } message: {
            Text(undoBlockedReason ?? "")
        }
        .onAppear {
            viewModel.beginSession()
            Task {
                await loadEquipmentProfiles()
            }
        }
        #if canImport(UIKit)
        .sheet(item: $viewModel.pendingPRShare) { pr in
            ShareCardSheet(
                variant: .newPR(
                    exerciseName: pr.exerciseName,
                    weight: pr.weight,
                    unit: pr.unit,
                    previousBest: pr.previousBest
                ),
                defaultAspect: .story,
                shareContext: ShareContext(
                    surface: .personalRecord,
                    sourceID: pr.exerciseName,
                    title: "\(pr.exerciseName) \(pr.weight) \(pr.unit)"
                )
            )
        }
        #endif
        #if canImport(UIKit)
        .sheet(isPresented: $showingWorkoutShare) {
            ShareCardSheet(
                variant: .completedWorkout(workout: viewModel.workout, personalRecords: []),
                defaultAspect: .story,
                shareContext: ShareContext(
                    surface: .completedWorkout,
                    sourceID: viewModel.workout.id,
                    title: viewModel.workout.name
                )
            )
        }
        #endif
        .sheet(isPresented: $showingSwapSheet) {
            if let exercise = viewModel.currentExercise {
                SubstitutionPickerSheet(exerciseName: exercise.name) { sub in
                    selectSubstitution(sub)
                }
            }
        }
        .sheet(isPresented: $showingStationTakenSwapSheet) {
            stationTakenSwapSheet
        }
        .alert("Swap mid-exercise?", isPresented: $showingSwapConfirm, presenting: pendingSwap) { sub in
            Button("Swap & reset progress", role: .destructive) {
                let wasStationTakenSwap = pendingStationTakenExercise != nil
                if let stationTakenExercise = pendingStationTakenExercise,
                   !currentExerciseMatches(stationTakenExercise) {
                    resetStationTakenState()
                    pendingSwap = nil
                    return
                }
                viewModel.swapCurrentExercise(to: sub.exerciseName, reason: sub.reason)
                if wasStationTakenSwap {
                    resetStationTakenState()
                } else {
                    pendingStationTakenExercise = nil
                }
                pendingSwap = nil
            }
            Button("Cancel", role: .cancel) {
                pendingStationTakenExercise = nil
                pendingSwap = nil
            }
        } message: { _ in
            Text("You've already logged sets on this exercise. Swapping will clear that progress.")
        }
        .sheet(isPresented: $viewModel.showStartingWeightCalibrationSheet) {
            StartingWeightCalibrationSheet(
                suggestions: viewModel.startingWeightSuggestions,
                onApplyAll: {
                    Task {
                        await viewModel.applyStartingWeightSuggestions()
                    }
                },
                onSkip: {
                    viewModel.skipStartingWeightCalibration()
                }
            )
        }
        .confirmationDialog("Convert Equipment", isPresented: $showingEquipmentConversionPicker) {
            ForEach(equipmentProfiles) { profile in
                Button("\(profile.name) - \(profile.equipment.displayName)") {
                    Task {
                        await viewModel.convertWorkout(to: profile.equipment)
                    }
                }
            }

            ForEach(EquipmentAccess.userSelectableDefaults, id: \.self) { equipment in
                Button(equipment.displayName) {
                    Task {
                        await viewModel.convertWorkout(to: equipment)
                    }
                }
            }
        } message: {
            Text("Update this workout to match your available equipment.")
        }
        .confirmationDialog("Workout Options", isPresented: $showingWorkoutOptionsDialog) {
            Button(showingWorkoutDetails ? "Hide details" : "Show details") {
                showingWorkoutDetails.toggle()
            }

            Button("Convert Equipment") {
                showingEquipmentConversionPicker = true
            }

            Button("Swap Exercise") {
                showingSwapSheet = true
            }

            Button("Station Taken") {
                showingStationTakenPicker = true
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose an adjustment for this workout.")
        }
        .confirmationDialog("Station taken", isPresented: $showingStationTakenPicker) {
            ForEach(BlockedStationKind.allCases, id: \.self) { station in
                Button(station.displayName) {
                    guard let exercise = currentStationTakenExerciseSnapshot() else {
                        resetStationTakenState()
                        return
                    }
                    selectedBlockedStation = station
                    stationTakenExercise = exercise
                    Task {
                        await loadStationTakenSwaps(
                            blockedStation: station,
                            exercise: exercise
                        )
                    }
                }
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Which station is unavailable?")
        }
        .confirmationDialog("How did the workout feel?", isPresented: $showingSessionEffortDialog) {
            ForEach(6...10, id: \.self) { rpe in
                Button("RPE \(rpe)") {
                    completePendingSet(sessionRPE: rpe)
                }
            }
            Button("Skip", role: .cancel) {
                completePendingSet(sessionRPE: nil)
            }
        } message: {
            Text("Quick effort check before finishing.")
        }
        .sheet(isPresented: $showingCompletionCheckIn) {
            WorkoutCompletionCheckInSheet(
                viewModel: WorkoutCompletionCheckInViewModel(workoutID: viewModel.workout.id)
            ) {
                showingCompletionCheckIn = false
            }
        }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            if isComplete {
                showingCompletionCheckIn = true
            }
        }
        .onChange(of: viewModel.currentExerciseIndex) { _, _ in
            if let exercise = stationTakenExercise,
               !currentExerciseMatches(exercise) {
                resetStationTakenState()
            }
        }
    }

    // MARK: - Active Workout View

    private var activeWorkoutView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                headerBar
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.lg)

                // Progress Section
                progressSection
                    .padding(.horizontal, AppTheme.Spacing.lg)

                if showingWorkoutDetails {
                    if let decision = viewModel.adaptationDecisionRecord, viewModel.completedSets == 0 {
                        adaptationDecisionCard(decision)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                    }

                    if !viewModel.lastEquipmentConversionChanges.isEmpty {
                        conversionSummaryCard
                            .padding(.horizontal, AppTheme.Spacing.lg)
                    }

                    if viewModel.canStartWarmup, let warmupBlock = viewModel.pendingWarmupBlock {
                        warmupStartCard(warmupBlock)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                    }
                }

                // Rest Timer (conditional)
                if viewModel.isResting {
                    restTimerCard
                        .padding(.horizontal, AppTheme.Spacing.lg)
                }

                // Current Exercise Card
                currentExerciseCard
                    .padding(.horizontal, AppTheme.Spacing.lg)

                // Spacer for button
                Spacer()
                    .frame(height: AppTheme.Spacing.xxl)
            }
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .safeAreaInset(edge: .bottom) {
            completeSetButton
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.Background.cream)
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            // Close button
            Button {
                showAbandonAlert = true
            } label: {
                Text("Close")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Text.secondary)
            }
            .accessibilityLabel("Abandon workout")

            Spacer()

            // Workout name
            Text(viewModel.workout.name)
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)
                .lineLimit(1)

            Spacer()

            // Elapsed time
            Text(elapsedTimeText)
                .font(AppTheme.Typography.monoLarge)
                .foregroundColor(AppTheme.Text.orange)

            Button {
                showingWorkoutOptionsDialog = true
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(AppTheme.Text.secondary)
            }
            .accessibilityLabel("Workout options")
        }
    }

    private var elapsedTimeText: String {
        let minutes = Int(viewModel.elapsedSeconds) / 60
        let seconds = Int(viewModel.elapsedSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    @MainActor
    private func loadEquipmentProfiles() async {
        let service = EquipmentProfileService(dataClient: DataClientFactory.shared.client)
        equipmentProfiles = await service.loadProfiles()
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Segmented bar
            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(0..<viewModel.workout.exercises.count, id: \.self) { index in
                    let exercise = viewModel.workout.exercises[index]
                    let isComplete = exercise.targetSets.allSatisfy { $0.isComplete }
                    let isCurrent = index == viewModel.currentExerciseIndex

                    RoundedRectangle(cornerRadius: 3)
                        .fill(isComplete ? AppTheme.Accent.orange :
                              isCurrent ? AppTheme.Accent.orange.opacity(0.5) :
                                AppTheme.Text.secondary.opacity(0.2))
                        .frame(height: 6)
                        .frame(maxWidth: .infinity)
                }
            }

            // Progress text
            HStack(spacing: AppTheme.Spacing.xs) {
                Text("\(viewModel.completedSets) of \(viewModel.totalSets) sets")
                Text("·")
                Text("Exercise \(viewModel.currentExerciseIndex + 1) of \(viewModel.workout.exercises.count)")
            }
            .font(AppTheme.Typography.labelSmall)
            .foregroundColor(AppTheme.Text.secondary)
        }
    }

    private func adaptationDecisionCard(_ decision: WorkoutAdaptationDecisionRecord) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(AppTheme.Accent.gold)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("What changed")
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Text.primary)

                        ForEach(decision.reasonText.prefix(4), id: \.self) { reason in
                            Text(reason)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if !viewModel.currentExerciseHasProgress && viewModel.completedSets == 0 {
                    Button {
                        Task {
                            let result = await viewModel.undoAdaptationChanges()
                            if case .blocked(let reason) = result {
                                undoBlockedReason = reason
                            }
                        }
                    } label: {
                        Label("Undo changes", systemImage: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ArtDecoButtonStyle(style: .secondary))
                }
            }
        }
    }

    private var conversionSummaryCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Equipment Conversion Applied")
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Text.primary)

                ForEach(viewModel.lastEquipmentConversionChanges.prefix(2)) { change in
                    Text("\(change.fromExercise) -> \(change.toExercise)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }
            }
        }
    }

    private func warmupStartCard(_ block: WarmupBlock) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "figure.flexibility")
                        .font(.title3)
                        .foregroundColor(AppTheme.Accent.gold)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(block.title)
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Text.primary)

                        Text("\(block.estimatedMinutes) min · \(block.exercises.count) moves")
                            .font(AppTheme.Typography.labelSmall)
                            .foregroundColor(AppTheme.Text.secondary)

                        if let reason = block.reasons.first {
                            Text(reason)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Button {
                    Task {
                        await viewModel.applyWarmup()
                    }
                } label: {
                    Label("Start Warmup", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ArtDecoButtonStyle(style: .secondary))
            }
        }
    }

    // MARK: - Current Exercise Card

    private var currentExerciseCard: some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.md) {
                if let exercise = viewModel.currentExercise {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(exercise.name)
                            .font(AppTheme.Typography.headlineLarge)
                            .foregroundColor(AppTheme.Text.primary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let cue = ExerciseTechniqueLibrary.cue(for: exercise.name) {
                        techniqueDisclosure(cue)
                    }

                    if let set = viewModel.currentSet {
                        Text("Set \(viewModel.currentSetIndex + 1) of \(exercise.targetSets.count)")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: AppTheme.Spacing.sm) {
                            statBox(value: "\(set.reps)", label: "Reps")

                            let weightText: String = {
                                if exercise.bodyweight > 0 && set.prescribedWeight == 0 {
                                    return "BW"
                                }
                                if set.prescribedWeight > 0 {
                                    return "\(Int(set.prescribedWeight))"
                                }
                                if let pct = set.prescribedPercentage {
                                    return "\(Int(pct * 100))%"
                                }
                                return "--"
                            }()
                            statBox(value: weightText, label: "Weight")

                            let restText = exercise.restMinutes > 0
                                ? "\(Int(exercise.restMinutes * 60))s"
                                : "—"
                            statBox(value: restText, label: "Rest")
                        }

                        // Reps input (always shown)
                        repsInputSection(prescribedReps: set.reps)
                            .padding(.top, AppTheme.Spacing.xs)

                        if exercise.bodyweight == 0 {
                            weightInputSection(prescribedWeight: set.prescribedWeight)
                                .padding(.top, AppTheme.Spacing.xs)
                        }

                        DisclosureGroup {
                            effortPicker
                                .padding(.top, AppTheme.Spacing.xs)
                        } label: {
                            Label(
                                selectedSetRPE.map { "Effort: RPE \($0)" } ?? "Add effort",
                                systemImage: "gauge.with.dots.needle.33percent"
                            )
                            .font(AppTheme.Typography.labelLarge)
                            .foregroundColor(AppTheme.Text.primary)
                        }
                        .tint(AppTheme.Accent.gold)
                        .padding(.top, AppTheme.Spacing.xs)
                    }
                } else {
                    Text("No current exercise")
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                }
            }
        }
        .onChange(of: viewModel.currentSetIndex) { _, _ in resetWeightInput() }
        .onChange(of: viewModel.currentExerciseIndex) { _, _ in resetWeightInput() }
        .onAppear { resetWeightInput() }
    }

    private var effortPicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Effort")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.secondary)

            HStack(spacing: AppTheme.Spacing.xs) {
                effortButton(title: "Skip", value: nil)
                ForEach(6...10, id: \.self) { rpe in
                    effortButton(title: "\(rpe)", value: rpe)
                }
            }
        }
    }

    private func effortButton(title: String, value: Int?) -> some View {
        let isSelected = selectedSetRPE == value
        return Button {
            selectedSetRPE = value
        } label: {
            Text(title)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(isSelected ? AppTheme.Text.cream : AppTheme.Text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(isSelected ? AppTheme.Accent.orange : AppTheme.Background.cream.opacity(0.55))
                .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(value.map { "RPE \($0)" } ?? "Skip effort")
    }

    private func techniqueDisclosure(_ cue: ExerciseTechniqueCue) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                techniqueCueList(title: "Setup", items: cue.setupCues)
                techniqueCueList(title: "Watch for", items: cue.commonMistakes)

                if let regression = cue.regression {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Scale")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Text.secondary)

                        Text(regression)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.primary)
                    }
                }
            }
            .padding(.top, AppTheme.Spacing.sm)
        } label: {
            Label("Form", systemImage: "figure.strengthtraining.traditional")
                .font(AppTheme.Typography.labelLarge)
                .foregroundColor(AppTheme.Text.primary)
        }
        .tint(AppTheme.Accent.gold)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Background.cream.opacity(0.45))
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.Accent.gold.opacity(0.25), lineWidth: 1)
        )
    }

    private func techniqueCueList(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.secondary)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "circle.fill")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Accent.gold)
                        .padding(.top, AppTheme.Spacing.xs)

                    Text(item)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func repsInputSection(prescribedReps: Int) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Reps")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.secondary)

            TextField(
                "\(prescribedReps)",
                text: $repsInput
            )
            .font(AppTheme.Typography.displaySmall)
            .foregroundColor(AppTheme.Text.primary)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.md)
            .frame(minHeight: 52)
            .background(AppTheme.Background.cream.opacity(0.5))
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isRepsFocused ? AppTheme.Accent.gold : AppTheme.Text.secondary.opacity(0.3), lineWidth: 1.5)
            )
            .focused($isRepsFocused)
            #if os(iOS)
            .keyboardType(.numberPad)
            #endif
        }
    }

    private func weightInputSection(prescribedWeight: Double) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Weight Lifted (lb)")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.secondary)

            TextField(
                prescribedWeight > 0 ? "\(Int(prescribedWeight))" : "Enter weight",
                text: $weightInput
            )
            .font(AppTheme.Typography.displaySmall)
            .foregroundColor(AppTheme.Text.primary)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.md)
            .frame(minHeight: 52)
            .background(AppTheme.Background.cream.opacity(0.5))
            .cornerRadius(AppTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isWeightFocused ? AppTheme.Accent.gold : AppTheme.Text.secondary.opacity(0.3), lineWidth: 1.5)
            )
            .focused($isWeightFocused)
            #if os(iOS)
            .keyboardType(.decimalPad)
            #endif
        }
    }

    private func resetWeightInput() {
        if let set = viewModel.currentSet {
            repsInput = "\(set.reps)"
            if set.prescribedWeight > 0 {
                weightInput = "\(Int(set.prescribedWeight))"
            } else if let completedWeight = viewModel.lastCompletedWeight, completedWeight > 0 {
                weightInput = "\(Int(completedWeight))"
            } else {
                weightInput = ""
            }
        } else {
            weightInput = ""
            repsInput = ""
        }
        selectedSetRPE = nil
        isWeightFocused = false
        isRepsFocused = false
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(value)
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Background.cream.opacity(0.5))
        .cornerRadius(AppTheme.CornerRadius.small)
    }

    // MARK: - Rest Timer Card

    private var restTimerCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // REST label
            Text("REST")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Accent.gold)

            // Countdown
            Text(restTimerText)
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(AppTheme.Text.cream)

            // Next set info
            if let nextSet = nextSetText {
                Text(nextSet)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Accent.gold)
            }

            if let reason = viewModel.restGuidanceReason {
                Text(reason)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.cream.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Skip Rest button
            Button {
                viewModel.skipRest()
            } label: {
                Text("Skip Rest")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Accent.gold)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Background.navy.opacity(0.5))
                    .cornerRadius(AppTheme.CornerRadius.medium)
            }
            .accessibilityHint("Skip the remaining rest time")
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.Background.navy)
        .cornerRadius(AppTheme.CornerRadius.large)
    }

    private var restTimerText: String {
        let seconds = Int(max(0, viewModel.restTimeRemaining))
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private var nextSetText: String? {
        guard let exercise = viewModel.currentExercise else { return nil }

        if viewModel.isResting, let set = viewModel.currentSet {
            return "Next: Set \(viewModel.currentSetIndex + 1) · \(set.reps) reps"
        }

        if viewModel.hasNextSet {
            let nextSetIndex = viewModel.currentSetIndex + 1
            if let nextSet = exercise.targetSets[safe: nextSetIndex] {
                return "Next: Set \(nextSetIndex + 1) · \(nextSet.reps) reps"
            }
        } else if viewModel.hasNextExercise {
            let nextExerciseIndex = viewModel.currentExerciseIndex + 1
            if let nextExercise = viewModel.workout.exercises[safe: nextExerciseIndex],
               let firstSet = nextExercise.targetSets.first {
                return "Next: \(nextExercise.name) · \(firstSet.reps) reps"
            }
        }
        return nil
    }

    // MARK: - Complete Set Button

    private var completeSetButton: some View {
        Button {
            guard let set = viewModel.currentSet else { return }
            let enteredReps = Int(repsInput) ?? set.reps
            let enteredWeight = Double(weightInput) ?? set.prescribedWeight
            let input = CompletionInput(
                reps: enteredReps,
                weight: enteredWeight,
                setRPE: selectedSetRPE
            )

            if viewModel.isLastSetOfWorkout,
               !viewModel.hasLoggedSetEffort,
               selectedSetRPE == nil {
                pendingCompletionInput = input
                showingSessionEffortDialog = true
            } else {
                completeSet(input, sessionRPE: nil)
            }
        } label: {
            Text("Complete Set")
                .font(AppTheme.Typography.labelLarge)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ArtDecoButtonStyle(style: .accent))
        .disabled(isCompleteSetButtonDisabled)
        .opacity(isCompleteSetButtonDisabled ? 0.6 : 1.0)
    }

    private var isCompleteSetButtonDisabled: Bool {
        viewModel.isResting ||
            viewModel.isComplete ||
            viewModel.isFinishing ||
            viewModel.isCompletingSet
    }

    private func completePendingSet(sessionRPE: Int?) {
        guard let input = pendingCompletionInput else { return }
        pendingCompletionInput = nil
        completeSet(input, sessionRPE: sessionRPE)
    }

    private func completeSet(_ input: CompletionInput, sessionRPE: Int?) {
        Task {
            await viewModel.completeSet(
                actualReps: input.reps,
                completedWeight: input.weight,
                setRPE: input.setRPE,
                sessionRPEForFinish: sessionRPE
            )
        }
    }

    private var stationTakenSwapSheet: some View {
        NavigationStack {
            Group {
                if stationTakenSwaps.isEmpty {
                    stationTakenEmptyState
                } else {
                    stationTakenList
                }
            }
            .navigationTitle(stationTakenTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingStationTakenSwapSheet = false
                    }
                }
            }
        }
    }

    private var stationTakenTitle: String {
        if let station = selectedBlockedStation {
            return "\(station.displayName) taken"
        }
        return "Station taken"
    }

    private var stationTakenList: some View {
        List {
            ForEach(stationTakenSwaps.prefix(5), id: \.exerciseName) { sub in
                Button {
                    selectStationTakenSubstitution(sub)
                } label: {
                    stationTakenRow(sub)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }

    private var stationTakenEmptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title)
                .foregroundColor(AppTheme.Text.secondary)
            Text("No station-safe swaps found")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)
            Text("Try the regular swap list or choose a different equipment setup.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .padding(AppTheme.Spacing.xxl)
    }

    private func stationTakenRow(_ sub: SubstitutionRanker.RankedSubstitution) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(sub.exerciseName)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)
                Text(sub.reason)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .lineLimit(2)
            }

            Spacer()
            swapScoreDots(for: sub.score)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sub.exerciseName), \(Int(sub.score * 5)) out of 5")
    }

    private func swapScoreDots(for score: Double) -> some View {
        let filled = Int((score * 5).rounded())
        return HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { idx in
                Circle()
                    .fill(idx < filled ? AppTheme.Accent.gold : AppTheme.Accent.gold.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }

    @MainActor
    private func loadStationTakenSwaps(
        blockedStation: BlockedStationKind,
        exercise: StationTakenExerciseSnapshot
    ) async {
        let dataClient = DataClientFactory.shared.client
        let painLogs: [DailyPainLog] = (try? await dataClient.fetchAll(recordType: "DailyPainLog")) ?? []

        guard currentExerciseMatches(exercise) else {
            resetStationTakenState()
            return
        }

        stationTakenSwaps = StationTakenSwapService.rankedSwaps(
            request: StationTakenSwapRequest(
                exerciseName: exercise.name,
                blockedStation: blockedStation,
                equipment: exercise.equipment,
                painLogs: painLogs
            )
        )
        showingStationTakenSwapSheet = true
    }

    private func selectSubstitution(_ sub: SubstitutionRanker.RankedSubstitution) {
        pendingStationTakenExercise = nil
        if viewModel.currentExerciseHasProgress {
            pendingSwap = sub
            showingSwapConfirm = true
        } else {
            viewModel.swapCurrentExercise(to: sub.exerciseName, reason: sub.reason)
        }
    }

    private func selectStationTakenSubstitution(_ sub: SubstitutionRanker.RankedSubstitution) {
        guard let exercise = stationTakenExercise,
              currentExerciseMatches(exercise) else {
            resetStationTakenState()
            return
        }

        showingStationTakenSwapSheet = false
        if viewModel.currentExerciseHasProgress {
            pendingStationTakenExercise = exercise
            pendingSwap = sub
            showingSwapConfirm = true
        } else {
            viewModel.swapCurrentExercise(to: sub.exerciseName, reason: sub.reason)
            resetStationTakenState()
        }
    }

    private func currentStationTakenExerciseSnapshot() -> StationTakenExerciseSnapshot? {
        guard let exercise = viewModel.currentExercise else { return nil }
        return StationTakenExerciseSnapshot(
            index: viewModel.currentExerciseIndex,
            id: exercise.id,
            name: exercise.name,
            equipment: viewModel.defaultEquipment
        )
    }

    private func currentExerciseMatches(_ exercise: StationTakenExerciseSnapshot) -> Bool {
        guard viewModel.currentExerciseIndex == exercise.index,
              let current = viewModel.currentExercise else {
            return false
        }
        return current.id == exercise.id && current.name == exercise.name
    }

    private func resetStationTakenState() {
        showingStationTakenSwapSheet = false
        selectedBlockedStation = nil
        stationTakenExercise = nil
        pendingStationTakenExercise = nil
        stationTakenSwaps = []
    }

    // MARK: - Completion View

    private var completionView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()
                    .frame(height: AppTheme.Spacing.xxl)

                // Trophy icon
                Image(systemName: "trophy.fill")
                    .font(.system(.largeTitle))
                    .foregroundColor(AppTheme.Accent.gold)

                // Title
                Text("Workout Complete!")
                    .font(AppTheme.Typography.displayLarge)
                    .foregroundColor(AppTheme.Text.primary)

                // Elapsed time
                Text(elapsedTimeText)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                // Sync status indicator (only non-synced states)
                completionSyncIndicator

                // Stats row
                HStack(spacing: AppTheme.Spacing.lg) {
                    statBox(value: "\(viewModel.completedSets)", label: "Sets")
                    statBox(value: "\(viewModel.workout.exercises.count)", label: "Exercises")
                    statBox(value: "\(viewModel.workout.duration)", label: "Minutes")
                }
                .padding(.horizontal, AppTheme.Spacing.lg)

                // Celebration events
                if !viewModel.celebrationEvents.isEmpty {
                    VStack(spacing: AppTheme.Spacing.md) {
                        ForEach(Array(viewModel.celebrationEvents.enumerated()), id: \.offset) { _, event in
                            celebrationCard(event)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }

                // Share actions
                Button {
                    showingWorkoutShare = true
                } label: {
                    Label("Share Workout", systemImage: "square.and.arrow.up")
                        .font(AppTheme.Typography.labelLarge)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ArtDecoButtonStyle(style: .accent))
                .padding(.horizontal, AppTheme.Spacing.lg)

                ShareLink(
                    item: ShareURL.caption(for: ShareContext(
                        surface: .challenge,
                        sourceID: viewModel.workout.id,
                        title: "I just finished \(viewModel.workout.name). Think you can match it?"
                    ))
                ) {
                    Label("Challenge a Friend", systemImage: "flag.fill")
                        .font(AppTheme.Typography.labelLarge)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ArtDecoButtonStyle(style: .secondary))
                .simultaneousGesture(
                    TapGesture().onEnded {
                        HapticFeedback.success()
                        Task {
                            await GrowthAnalyticsService().track(
                                GrowthEventName.challengeInviteShared,
                                source: "workout_completion",
                                properties: ["workoutID": viewModel.workout.id]
                            )
                        }
                    }
                )
                .padding(.horizontal, AppTheme.Spacing.lg)

                // Done button
                Button {
                    NotificationCenter.default.post(name: .workoutCompleted, object: nil)
                    dismiss()
                } label: {
                    Text("Done")
                        .font(AppTheme.Typography.labelLarge)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ArtDecoButtonStyle(style: .primary))
                .padding(.horizontal, AppTheme.Spacing.lg)

                Spacer()
                    .frame(height: AppTheme.Spacing.xxl)
            }
        }
    }

    // MARK: - Completion Sync Indicator

    private var completionSyncStatus: SyncStatus {
        SyncStatusService.status(
            isGuest: authViewModel.isGuest,
            pendingMutationCount: syncDiagnostics.pendingCount,
            stuckMutationCount: syncDiagnostics.stuckCount
        )
    }

    @ViewBuilder
    private var completionSyncIndicator: some View {
        let status = completionSyncStatus
        // Only show when there's something actionable (hide happy-path synced)
        if status.kind == .synced {
            EmptyView()
        } else {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: status.systemImage)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(syncStatusColor(for: status.kind))

                Text(status.title)
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(AppTheme.Background.navy.opacity(0.08))
            )
        }
    }

    private func syncStatusColor(for kind: SyncStatusKind) -> Color {
        switch kind {
        case .localOnly: return AppTheme.Accent.gold
        case .synced: return AppTheme.Recovery.green
        case .queued: return AppTheme.Accent.orange
        case .needsAttention: return AppTheme.Semantic.warning
        }
    }

    private func celebrationCard(_ event: CelebrationEvent) -> some View {
        ArtDecoCard {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.Accent.gold)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(celebrationTitle(event))
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Text(celebrationSubtitle(event, unit: "lb"))
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Safe Array Subscript

extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
private struct StationTakenExerciseSnapshot: Sendable, Equatable {
    let index: Int
    let id: String
    let name: String
    let equipment: EquipmentAccess
}
