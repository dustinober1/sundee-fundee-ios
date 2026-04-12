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
    @State private var showAbandonAlert = false
    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool

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
        .onAppear {
            viewModel.beginSession()
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
        }
    }

    private var elapsedTimeText: String {
        let minutes = Int(viewModel.elapsedSeconds) / 60
        let seconds = Int(viewModel.elapsedSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
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

    // MARK: - Current Exercise Card

    private var currentExerciseCard: some View {
        ArtDecoCard {
            VStack(spacing: AppTheme.Spacing.md) {
                if let exercise = viewModel.currentExercise {
                    Text(exercise.name)
                        .font(AppTheme.Typography.headlineLarge)
                        .foregroundColor(AppTheme.Text.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

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

    private func repsInputSection(prescribedReps: Int) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Reps")
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.secondary)

            TextField(
                "\(prescribedReps)",
                text: $repsInput
            )
            .font(AppTheme.Typography.monoMedium)
            .foregroundColor(AppTheme.Text.primary)
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Background.cream.opacity(0.5))
            .cornerRadius(AppTheme.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(isRepsFocused ? AppTheme.Accent.gold : AppTheme.Text.secondary.opacity(0.3), lineWidth: 1)
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
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.secondary)

            TextField(
                prescribedWeight > 0 ? "\(Int(prescribedWeight))" : "Enter weight",
                text: $weightInput
            )
            .font(AppTheme.Typography.monoMedium)
            .foregroundColor(AppTheme.Text.primary)
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Background.cream.opacity(0.5))
            .cornerRadius(AppTheme.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(isWeightFocused ? AppTheme.Accent.gold : AppTheme.Text.secondary.opacity(0.3), lineWidth: 1)
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
            Task {
                await viewModel.completeSet(
                    actualReps: enteredReps,
                    completedWeight: enteredWeight
                )
            }
        } label: {
            Text("Complete Set")
                .font(AppTheme.Typography.labelLarge)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ArtDecoButtonStyle(style: .accent))
        .disabled(viewModel.isResting || viewModel.isComplete || viewModel.isFinishing)
        .opacity((viewModel.isResting || viewModel.isComplete || viewModel.isFinishing) ? 0.6 : 1.0)
    }

    // MARK: - Completion View

    private var completionView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()
                    .frame(height: AppTheme.Spacing.xxl)

                // Trophy icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.Accent.gold)

                // Title
                Text("Workout Complete!")
                    .font(AppTheme.Typography.displayLarge)
                    .foregroundColor(AppTheme.Text.primary)

                // Elapsed time
                Text(elapsedTimeText)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.secondary)

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

    private func celebrationCard(_ event: CelebrationEvent) -> some View {
        ArtDecoCard {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
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

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
