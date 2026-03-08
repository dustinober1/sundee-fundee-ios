import SwiftUI
import SwiftData

/// WOD execution screen — set-by-set logging for standalone Workout of the Day.
struct WODExecutionView: View {
    @State var viewModel: WODExecutionViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var showFinishConfirm = false

    init(viewModel: WODExecutionViewModel) {
        _viewModel = State(initialValue: viewModel)
        _showFinishConfirm = State(initialValue: false)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            switch viewModel.resolvedTemplateType {
            case .strength:
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        wodHeader
                        ForEach(viewModel.wod.exercises, id: \.exercise, content: exerciseCard(for:))
                        finishButton
                            .padding(.bottom, AppTheme.Spacing.xl)
                    }
                    .padding(AppTheme.Spacing.md)
                }
            case .amrap:
                AMRAPTimerView(exercises: viewModel.wod.exercises)
            case .emom:
                EMOMTimerView(exercises: viewModel.wod.exercises)
            case .forTime:
                ForTimeTimerView(exercises: viewModel.wod.exercises)
            case .circuit:
                CircuitGroupView(exercises: viewModel.wod.exercises)
            }

            if viewModel.showRestTimer {
                RestTimerOverlay(
                    seconds: $viewModel.restTimerSeconds,
                    onDismiss: viewModel.dismissRestTimer
                )
            }
        }
        .navigationTitle(viewModel.wod.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isSaving)
        .sheet(isPresented: $viewModel.showPlateCalc) {
            PlateCalculatorSheet(
                weightKg: viewModel.plateCalcWeightKg,
                barbellWeightKg: viewModel.barbellWeightKg,
                weightUnit: viewModel.weightUnit
            )
        }
        .confirmationDialog(
            "Finish WOD?",
            isPresented: $showFinishConfirm,
            actions: {
                Button("Save & Finish") {
                    let userID = appState.currentUserID ?? ""
                    viewModel.finishWorkout(modelContext: modelContext, userID: userID)
                }
            },
            message: { Text("Your progress will be saved.") }
        )
        .navigationDestination(isPresented: $viewModel.isFinished) {
            if let workout = viewModel.completedWorkout {
                WorkoutSummaryView(workout: workout)
            } else {
                Text("Workout saved!")
            }
        }
    }

    // MARK: - Subviews

    private var wodHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("WORKOUT OF THE DAY")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accentOrange)
                .tracking(1.5)
            Text(viewModel.wod.description)
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.7))
            Text("\(viewModel.wod.exercises.count) exercises")
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func exerciseCard(for exercise: ProgramExercise) -> some View {
        WODExerciseSetCard(viewModel: viewModel, exercise: exercise)
    }

    private var finishButton: some View {
        Button(viewModel.isSaving ? "Saving..." : "Finish WOD") {
            showFinishConfirm = true
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.isSaving)
    }
}

// MARK: - WODExerciseSetCard

struct WODExerciseSetCard: View {
    @Bindable var viewModel: WODExecutionViewModel
    let exercise: ProgramExercise

    var sets: [SetExecutionState] {
        viewModel.exerciseSets[exercise.exercise] ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.exercise)
                        .font(AppTheme.Fonts.subheading)
                        .foregroundStyle(AppTheme.Colors.navy)
                    if let variant = exercise.variant {
                        Text(variant)
                            .font(AppTheme.Fonts.caption)
                            .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    }
                }
                Spacer()
                if !exercise.bodyweightOnly, let kg = sets.first?.prescribedWeightKg {
                    Button { viewModel.openPlateCalc(forWeight: kg) } label: {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(AppTheme.Colors.accentOrange)
                    }
                }
            }

            if let notes = exercise.notes {
                Text(notes)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    .italic()
            }

            HStack {
                Text("Set").frame(width: 30, alignment: .center)
                Text("Target").frame(maxWidth: .infinity)
                if !exercise.bodyweightOnly {
                    Text("Reps").frame(width: 70, alignment: .center)
                    Text(viewModel.weightUnit.symbol.uppercased()).frame(width: 80, alignment: .center)
                }
                Text("\u{2713}").frame(width: 32, alignment: .center)
            }
            .font(AppTheme.Fonts.caption)
            .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))

            Divider()

            ForEach(sets.indices, id: \.self) { idx in
                SetRow(
                    setNumber: idx + 1,
                    state: sets[idx],
                    onRepsChange: { viewModel.updateActualReps($0, exerciseName: exercise.exercise, setIndex: idx) },
                    onWeightChange: { viewModel.updateActualWeight($0, exerciseName: exercise.exercise, setIndex: idx) },
                    weightUnit: viewModel.weightUnit,
                    bodyweightOnly: exercise.bodyweightOnly,
                    onToggle: { viewModel.toggleSetCompleted(exerciseName: exercise.exercise, setIndex: idx) }
                )
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
