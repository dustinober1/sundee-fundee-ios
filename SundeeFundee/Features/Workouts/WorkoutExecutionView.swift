import SwiftUI
import SwiftData

/// Main workout execution screen — set-by-set logging with rest timer and plate calc.
struct WorkoutExecutionView: View {
    @State var viewModel: WorkoutExecutionViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var showFinishConfirm = false

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    sessionHeader
                    ForEach(viewModel.session.exercises, id: \.exercise) { exercise in
                        ExerciseSetCard(viewModel: viewModel, exercise: exercise)
                    }
                    finishButton
                        .padding(.bottom, AppTheme.Spacing.xl)
                }
                .padding(AppTheme.Spacing.md)
            }

            // Rest timer overlay
            if viewModel.showRestTimer {
                RestTimerOverlay(
                    seconds: $viewModel.restTimerSeconds,
                    onDismiss: { viewModel.dismissRestTimer() }
                )
            }
        }
        .navigationTitle(viewModel.session.sessionName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isSaving)
        .sheet(isPresented: $viewModel.showPlateCalc) {
            PlateCalculatorSheet(weightKg: viewModel.plateCalcWeightKg)
        }
        .confirmationDialog("Finish Workout?", isPresented: $showFinishConfirm) {
            Button("Save & Finish") {
                let userID = appState.currentUserID ?? ""
                viewModel.finishWorkout(modelContext: modelContext, userID: userID)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress will be saved.")
        }
        .navigationDestination(isPresented: $viewModel.isFinished) {
            if let workout = viewModel.completedWorkout {
                WorkoutSummaryView(workout: workout)
            } else {
                Text("Workout saved!")
            }
        }
    }

    // MARK: - Subviews

    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(viewModel.session.focus)
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.accentOrange)
                .textCase(.uppercase)
            Text("Week \(viewModel.enrollment.currentWeek) • Day \(viewModel.enrollment.currentDay)")
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var finishButton: some View {
        Button(viewModel.isSaving ? "Saving…" : "Finish Workout") {
            showFinishConfirm = true
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.isSaving)
    }
}

// MARK: - ExerciseSetCard

struct ExerciseSetCard: View {
    @Bindable var viewModel: WorkoutExecutionViewModel
    let exercise: ProgramExercise

    var sets: [SetExecutionState] {
        viewModel.exerciseSets[exercise.exercise] ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Exercise name + plate calc button
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
                if let kg = sets.first?.prescribedWeightKg {
                    Button {
                        viewModel.openPlateCalc(forWeight: kg)
                    } label: {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(AppTheme.Colors.accentOrange)
                    }
                    .accessibilityLabel("Open plate calculator for \(exercise.exercise)")
                }
            }

            if let notes = exercise.notes {
                Text(notes)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    .italic()
            }

            // Column headers
            HStack {
                Text("Set").frame(width: 30, alignment: .center)
                Text("Target").frame(maxWidth: .infinity)
                Text("Reps").frame(width: 70, alignment: .center)
                Text("Kg").frame(width: 80, alignment: .center)
                Text("✓").frame(width: 32, alignment: .center)
            }
            .font(AppTheme.Fonts.caption)
            .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))

            Divider()

            // Set rows
            ForEach(sets.indices, id: \.self) { idx in
                SetRow(
                    setNumber: idx + 1,
                    state: sets[idx],
                    onRepsChange: { viewModel.updateActualReps($0, exerciseName: exercise.exercise, setIndex: idx) },
                    onWeightChange: { viewModel.updateActualWeight($0, exerciseName: exercise.exercise, setIndex: idx) },
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

// MARK: - SetRow

struct SetRow: View {
    let setNumber: Int
    let state: SetExecutionState
    let onRepsChange: (Int) -> Void
    let onWeightChange: (Double) -> Void
    let onToggle: () -> Void

    @State private var repsText: String = ""
    @State private var weightText: String = ""

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text("\(setNumber)")
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                .frame(width: 30, alignment: .center)

            Text(state.prescribedReps)
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.navy)
                .frame(maxWidth: .infinity, alignment: .center)

            TextField("–", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 70)
                .padding(6)
                .background(AppTheme.Colors.separator.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onChange(of: repsText) { _, new in
                    if let r = Int(new) { onRepsChange(r) }
                }

            TextField("–", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 80)
                .padding(6)
                .background(AppTheme.Colors.separator.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .onChange(of: weightText) { _, new in
                    if let w = Double(new) { onWeightChange(w) }
                }

            Button(action: onToggle) {
                Image(systemName: state.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(state.isCompleted ? AppTheme.Colors.accentOrange : AppTheme.Colors.separator)
                    .font(.title3)
            }
            .frame(width: 32)
            .accessibilityLabel(state.isCompleted ? "Set completed" : "Mark set complete")
        }
        .onAppear {
            repsText = state.actualReps.map { "\($0)" } ?? ""
            weightText = state.actualWeightKg.map { formatWeight($0) } ?? ""
        }
    }

    private func formatWeight(_ kg: Double) -> String {
        kg == kg.rounded() ? "\(Int(kg))" : String(format: "%.1f", kg)
    }
}

// MARK: - RestTimerOverlay

struct RestTimerOverlay: View {
    @Binding var seconds: Int
    let onDismiss: () -> Void
    @State private var timeLeft: Int = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: AppTheme.Spacing.lg) {
                Text("Rest")
                    .font(AppTheme.Fonts.heading)
                    .foregroundStyle(.white)

                Text(timeString)
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundStyle(timeLeft > 10 ? .white : AppTheme.Colors.accentOrange)

                Button("Skip Rest", action: onDismiss)
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }
            .padding(AppTheme.Spacing.xl)
        }
        .onAppear {
            timeLeft = seconds
            startTimer()
        }
        .onDisappear { timer?.invalidate() }
    }

    private var timeString: String {
        let m = timeLeft / 60
        let s = timeLeft % 60
        return String(format: "%d:%02d", m, s)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeLeft > 0 {
                timeLeft -= 1
            } else {
                timer?.invalidate()
                onDismiss()
            }
        }
    }
}

// MARK: - PlateCalculatorSheet

struct PlateCalculatorSheet: View {
    let weightKg: Double
    @Environment(\.dismiss) private var dismiss

    private var plates: [(weight: Double, count: Int)] {
        PlateCalculation.platesPerSide(totalWeightKg: weightKg)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                Text(PlateCalculation.description(totalWeightKg: weightKg))
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                    .multilineTextAlignment(.center)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))

                if plates.isEmpty {
                    Text("Bar only (\(Int(PlateCalculation.standardBarKg)) kg)")
                        .font(AppTheme.Fonts.subheading)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                } else {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(plates, id: \.weight) { plate in
                            HStack {
                                Text("\(plate.count)×")
                                    .foregroundStyle(AppTheme.Colors.accentOrange)
                                Text("\(formatWeight(plate.weight)) kg plate")
                                    .foregroundStyle(AppTheme.Colors.navy)
                                Spacer()
                            }
                            .font(AppTheme.Fonts.subheading)
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.cream.ignoresSafeArea())
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formatWeight(_ kg: Double) -> String {
        kg == kg.rounded() ? "\(Int(kg))" : String(format: "%.2g", kg)
    }
}
