import SwiftUI
import SwiftData

/// Main workout execution screen — set-by-set logging with rest timer and plate calc.
struct WorkoutExecutionView: View {
    @State var viewModel: WorkoutExecutionViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var showFinishConfirm = false

    init(viewModel: WorkoutExecutionViewModel) {
        _viewModel = State(initialValue: viewModel)
        _showFinishConfirm = State(initialValue: false)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    sessionHeader
                    ForEach(viewModel.session.exercises, id: \.exercise, content: exerciseCard(for:))
                    finishButton
                        .padding(.bottom, AppTheme.Spacing.xl)
                }
                .padding(AppTheme.Spacing.md)
            }

            // Rest timer overlay
            if viewModel.showRestTimer {
                RestTimerOverlay(
                    seconds: $viewModel.restTimerSeconds,
                    onDismiss: viewModel.dismissRestTimer
                )
            }
        }
        .navigationTitle(viewModel.session.sessionName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isSaving)
        .sheet(isPresented: $viewModel.showPlateCalc, content: plateCalculatorSheet)
        .onAppear { viewModel.loadBarbellPresets() }
        .confirmationDialog(
            "Finish Workout?",
            isPresented: $showFinishConfirm,
            actions: finishConfirmationActions,
            message: finishConfirmationMessage
        )
        .navigationDestination(isPresented: $viewModel.isFinished, destination: summaryDestination)
    }

    // MARK: - Subviews

    private func exerciseCard(for exercise: ProgramExercise) -> some View {
        ExerciseSetCard(viewModel: viewModel, exercise: exercise)
    }

    private func plateCalculatorSheet() -> some View {
        PlateCalculatorSheet(
            weightKg: viewModel.plateCalcWeightKg,
            barbellWeightKg: viewModel.selectedBarbellWeightKg,
            weightUnit: viewModel.weightUnit,
            presets: viewModel.barbellPresets,
            selectedPresetID: viewModel.selectedPresetID,
            onBarChange: { viewModel.updateBarSelection(presetID: $0) }
        )
    }

    @ViewBuilder
    private func finishConfirmationActions() -> some View {
        Button(
            "Save & Finish",
            action: Self.finishConfirmationAction(
                viewModel: viewModel,
                appState: appState,
                modelContext: modelContext
            )
        )
    }

    private func finishConfirmationMessage() -> some View {
        Text("Your progress will be saved.")
    }

    @ViewBuilder
    private func summaryDestination() -> some View {
        Self.summaryDestinationView(workout: viewModel.completedWorkout)
    }

    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(viewModel.session.focus)
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.accentOrange)
                .textCase(.uppercase)
            Text("Week \(viewModel.enrollment?.currentWeek ?? 0) • Day \(viewModel.enrollment?.currentDay ?? 0)")
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var finishButton: some View {
        Button(
            Self.finishButtonTitle(isSaving: viewModel.isSaving),
            action: Self.finishButtonAction(isPresented: $showFinishConfirm)
        )
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.isSaving)
    }

    static func finishButtonTitle(isSaving: Bool) -> String {
        isSaving ? "Saving…" : "Finish Workout"
    }

    static func finishButtonAction(isPresented: Binding<Bool>) -> () -> Void {
        { presentFinishConfirmation(&isPresented.wrappedValue) }
    }

    static func presentFinishConfirmation(_ isPresented: inout Bool) {
        isPresented = true
    }

    static func finishConfirmationAction(
        viewModel: WorkoutExecutionViewModel,
        appState: AppState,
        modelContext: ModelContext
    ) -> () -> Void {
        { finishWorkout(viewModel: viewModel, appState: appState, modelContext: modelContext) }
    }

    static func cancelFinishAction() {}

    static func finishWorkout(viewModel: WorkoutExecutionViewModel, appState: AppState, modelContext: ModelContext) {
        let userID = appState.currentUserID ?? ""
        viewModel.finishWorkout(modelContext: modelContext, userID: userID)
    }

    enum SummaryDestinationState: Equatable {
        case summary
        case fallback
    }

    static func summaryDestinationState(workout: CompletedWorkout?) -> SummaryDestinationState {
        workout == nil ? .fallback : .summary
    }

    @ViewBuilder
    static func summaryDestinationView(workout: CompletedWorkout?) -> some View {
        if let workout {
            WorkoutSummaryView(workout: workout)
        } else {
            Text("Workout saved!")
        }
    }

}

// MARK: - ExerciseSetCard

struct ExerciseSetCard: View {
    @Bindable var viewModel: WorkoutExecutionViewModel
    let exercise: ProgramExercise

    var sets: [SetExecutionState] {
        if let sets = viewModel.exerciseSets[exercise.exercise] {
            return sets
        }
        return []
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
                if !(exercise.bodyweightOnly), let kg = Self.plateCalculatorWeight(for: sets) {
                    Button(action: Self.plateCalculatorAction(viewModel: viewModel, weightKg: kg)) {
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
                if !(exercise.bodyweightOnly) {
                    Text("Reps").frame(width: 70, alignment: .center)
                    Text(viewModel.weightUnit.symbol.uppercased()).frame(width: 80, alignment: .center)
                }
                Text("✓").frame(width: 32, alignment: .center)
            }
            .font(AppTheme.Fonts.caption)
            .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))

            Divider()

            // Set rows
            ForEach(sets.indices, id: \.self, content: rowView(for:))
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private func rowView(for idx: Int) -> some View {
        SetRow(
            setNumber: idx + 1,
            state: sets[idx],
            onRepsChange: Self.repsChangeAction(
                viewModel: viewModel,
                exerciseName: exercise.exercise,
                setIndex: idx
            ),
            onWeightChange: Self.weightChangeAction(
                viewModel: viewModel,
                exerciseName: exercise.exercise,
                setIndex: idx
            ),
            weightUnit: viewModel.weightUnit,
            bodyweightOnly: exercise.bodyweightOnly,
            onToggle: Self.toggleAction(
                viewModel: viewModel,
                exerciseName: exercise.exercise,
                setIndex: idx
            ),
            onPlateCalc: exercise.bodyweightOnly ? nil : Self.actualWeightPlateCalcAction(
                viewModel: viewModel,
                exerciseName: exercise.exercise,
                setIndex: idx,
                sets: sets
            )
        )
    }

    static func plateCalculatorWeight(for sets: [SetExecutionState]) -> Double? {
        sets.first?.prescribedWeightKg
    }

    static func plateCalculatorAction(viewModel: WorkoutExecutionViewModel, weightKg: Double) -> () -> Void {
        { openPlateCalculator(viewModel: viewModel, weightKg: weightKg) }
    }

    static func openPlateCalculator(viewModel: WorkoutExecutionViewModel, weightKg: Double) {
        viewModel.openPlateCalc(forWeight: weightKg)
    }

    static func repsChangeAction(
        viewModel: WorkoutExecutionViewModel,
        exerciseName: String,
        setIndex: Int
    ) -> (Int) -> Void {
        { viewModel.updateActualReps($0, exerciseName: exerciseName, setIndex: setIndex) }
    }

    static func weightChangeAction(
        viewModel: WorkoutExecutionViewModel,
        exerciseName: String,
        setIndex: Int
    ) -> (Double) -> Void {
        { viewModel.updateActualWeight($0, exerciseName: exerciseName, setIndex: setIndex) }
    }

    static func toggleAction(
        viewModel: WorkoutExecutionViewModel,
        exerciseName: String,
        setIndex: Int
    ) -> () -> Void {
        { viewModel.toggleSetCompleted(exerciseName: exerciseName, setIndex: setIndex) }
    }

    static func actualWeightPlateCalcAction(
        viewModel: WorkoutExecutionViewModel,
        exerciseName: String,
        setIndex: Int,
        sets: [SetExecutionState]
    ) -> () -> Void {
        {
            let weightKg = sets[setIndex].actualWeightKg ?? sets[setIndex].prescribedWeightKg ?? 0
            viewModel.openPlateCalcForActual(exerciseName: exerciseName, weightKg: weightKg)
        }
    }
}

// MARK: - SetRow

struct SetRow: View {
    let setNumber: Int
    let state: SetExecutionState
    let onRepsChange: (Int) -> Void
    let onWeightChange: (Double) -> Void
    let weightUnit: WeightUnit
    let bodyweightOnly: Bool
    let onToggle: () -> Void
    let onPlateCalc: (() -> Void)?

    @State private var repsText: String = ""
    @State private var weightText: String = ""

    init(
        setNumber: Int,
        state: SetExecutionState,
        onRepsChange: @escaping (Int) -> Void,
        onWeightChange: @escaping (Double) -> Void,
        weightUnit: WeightUnit = .pounds,
        bodyweightOnly: Bool = false,
        onToggle: @escaping () -> Void,
        onPlateCalc: (() -> Void)? = nil
    ) {
        self.setNumber = setNumber
        self.state = state
        self.onRepsChange = onRepsChange
        self.onWeightChange = onWeightChange
        self.weightUnit = weightUnit
        self.bodyweightOnly = bodyweightOnly
        self.onToggle = onToggle
        self.onPlateCalc = onPlateCalc
        _repsText = State(initialValue: "")
        _weightText = State(initialValue: "")
    }

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

            if !bodyweightOnly {
                TextField("–", text: $repsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
                    .padding(6)
                    .background(AppTheme.Colors.separator.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onChange(of: repsText) { oldValue, newValue in
                        Self.repsTextChangeHandler(onRepsChange: onRepsChange)(oldValue, newValue)
                    }

                HStack(spacing: 2) {
                    TextField("–", text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .onChange(of: weightText) { oldValue, newValue in
                            Self.weightTextChangeHandler(onWeightChange: onWeightChange, weightUnit: weightUnit)(oldValue, newValue)
                        }
                    if let onPlateCalc {
                        Button(action: onPlateCalc) {
                            Image(systemName: "scalemass.fill")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.Colors.accentOrange)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 80)
                .padding(6)
                .background(AppTheme.Colors.separator.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Button(action: onToggle) {
                Image(systemName: state.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(state.isCompleted ? AppTheme.Colors.accentOrange : AppTheme.Colors.separator)
                    .font(.title3)
            }
            .frame(width: 32)
            .accessibilityLabel(state.isCompleted ? "Set completed" : "Mark set complete")
        }
        .onAppear(perform: applyInitialTextValues)
    }

    private func applyInitialTextValues() {
        let initialValues = Self.initialTextValues(for: state, weightUnit: weightUnit)
        repsText = initialValues.repsText
        weightText = initialValues.weightText
    }

    static func initialTextValues(
        for state: SetExecutionState,
        weightUnit: WeightUnit = .pounds
    ) -> (repsText: String, weightText: String) {
        (
            state.actualReps.map { "\($0)" } ?? "",
            state.actualWeightKg.map { formatWeight($0, weightUnit: weightUnit) } ?? ""
        )
    }

    static func repsTextChangeHandler(onRepsChange: @escaping (Int) -> Void) -> (String, String) -> Void {
        { _, new in
            if let reps = parseReps(new) { onRepsChange(reps) }
        }
    }

    static func weightTextChangeHandler(
        onWeightChange: @escaping (Double) -> Void,
        weightUnit: WeightUnit = .pounds
    ) -> (String, String) -> Void {
        { _, new in
            if let weight = parseWeight(new, weightUnit: weightUnit) { onWeightChange(weight) }
        }
    }

    static func parseReps(_ value: String) -> Int? {
        Int(value)
    }

    static func parseWeight(_ value: String, weightUnit: WeightUnit = .pounds) -> Double? {
        WeightUnitConversion.parseInputToKilograms(value, unit: weightUnit)
    }

    static func formatWeight(_ kg: Double, weightUnit: WeightUnit = .pounds) -> String {
        WeightUnitConversion.format(kilograms: kg, unit: weightUnit, maximumFractionDigits: 1)
    }
}

// MARK: - RestTimerOverlay

struct RestTimerOverlay: View {
    @Binding var seconds: Int
    let onDismiss: () -> Void
    @State private var timeLeft: Int = 0
    @State private var timer: Timer?

    init(seconds: Binding<Int>, onDismiss: @escaping () -> Void) {
        _seconds = seconds
        self.onDismiss = onDismiss
        _timeLeft = State(initialValue: 0)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: AppTheme.Spacing.lg) {
                Text("Rest")
                    .font(AppTheme.Fonts.heading)
                    .foregroundStyle(.white)

                Text(timeString)
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundStyle(Self.timerColor(timeLeft: timeLeft))

                Button("Skip Rest", action: onDismiss)
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }
            .padding(AppTheme.Spacing.xl)
        }
        .onAppear(perform: handleAppear)
        .onDisappear(perform: invalidateTimer)
    }

    private var timeString: String {
        Self.timeString(for: timeLeft)
    }

    private func handleAppear() {
        timeLeft = seconds
        startTimer()
    }

    private func invalidateTimer() {
        timer?.invalidate()
    }

    static func timeString(for timeLeft: Int) -> String {
        let m = timeLeft / 60
        let s = timeLeft % 60
        return String(format: "%d:%02d", m, s)
    }

    static func timerColor(timeLeft: Int) -> Color {
        timeLeft > 10 ? .white : AppTheme.Colors.accentOrange
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            Task { @MainActor in
                timeLeft = Self.processTick(
                    timeLeft: timeLeft,
                    invalidateTimer: { timer?.invalidate() },
                    onDismiss: onDismiss
                )
            }
        }
    }

    static func nextTick(timeLeft: Int) -> (timeLeft: Int, shouldDismiss: Bool) {
        if timeLeft > 0 {
            return (timeLeft - 1, false)
        }
        return (0, true)
    }

    static func processTick(
        timeLeft: Int,
        invalidateTimer: () -> Void,
        onDismiss: () -> Void
    ) -> Int {
        let tick = nextTick(timeLeft: timeLeft)
        if tick.shouldDismiss {
            invalidateTimer()
            onDismiss()
        }
        return tick.timeLeft
    }
}

// MARK: - PlateCalculatorSheet

struct PlateCalculatorSheet: View {
    let weightKg: Double
    let barbellWeightKg: Double
    let weightUnit: WeightUnit
    let presets: [BarbellPresetDTO]
    let selectedPresetID: String?
    let onBarChange: ((String) -> Void)?
    @Environment(\.dismiss) private var dismiss

    init(
        weightKg: Double,
        barbellWeightKg: Double = PlateCalculation.standardBarKg,
        weightUnit: WeightUnit = .pounds,
        presets: [BarbellPresetDTO] = [],
        selectedPresetID: String? = nil,
        onBarChange: ((String) -> Void)? = nil
    ) {
        self.weightKg = weightKg
        self.barbellWeightKg = barbellWeightKg
        self.weightUnit = weightUnit
        self.presets = presets
        self.selectedPresetID = selectedPresetID
        self.onBarChange = onBarChange
    }

    private var effectiveBarbellKg: Double {
        if let selectedPresetID,
           let preset = presets.first(where: { $0.id == selectedPresetID }) {
            return preset.weightKg
        }
        return barbellWeightKg
    }

    private var plates: [(weight: Double, count: Int)] {
        PlateCalculation.platesPerSide(totalWeightKg: weightKg, barbellWeightKg: effectiveBarbellKg, weightUnit: weightUnit)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                if !presets.isEmpty {
                    Menu {
                        ForEach(presets, id: \.id) { preset in
                            Button(Self.presetLabel(preset: preset, weightUnit: weightUnit)) {
                                onBarChange?(preset.id)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "scalemass.fill")
                                .foregroundStyle(AppTheme.Colors.accentOrange)
                            if let selectedPresetID,
                               let preset = presets.first(where: { $0.id == selectedPresetID }) {
                                Text(Self.presetLabel(preset: preset, weightUnit: weightUnit))
                                    .font(AppTheme.Fonts.body)
                                    .foregroundStyle(AppTheme.Colors.navy)
                            } else {
                                Text("Select Bar Type")
                                    .font(AppTheme.Fonts.body)
                                    .foregroundStyle(AppTheme.Colors.navy)
                            }
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                        }
                        .padding(AppTheme.Spacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
                    }
                }

                Text(Self.description(
                    totalWeightKg: weightKg,
                    barbellWeightKg: effectiveBarbellKg,
                    plates: plates,
                    weightUnit: weightUnit
                ))
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                    .multilineTextAlignment(.center)
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))

                if Self.hasPlates(plates) {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(plates, id: \.weight, content: plateRow(for:))
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
                } else {
                    Text(Self.barOnlyText(barKg: effectiveBarbellKg, weightUnit: weightUnit))
                        .font(AppTheme.Fonts.subheading)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.cream.ignoresSafeArea())
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }

    private func plateRow(for plate: (weight: Double, count: Int)) -> some View {
        HStack {
            Text("\(plate.count)×")
                .foregroundStyle(AppTheme.Colors.accentOrange)
            Text("\(Self.formatPlateWeight(plate.weight)) \(weightUnit.symbol) plate")
                .foregroundStyle(AppTheme.Colors.navy)
            Spacer()
        }
        .font(AppTheme.Fonts.subheading)
    }

    static func hasPlates(_ plates: [(weight: Double, count: Int)]) -> Bool {
        !plates.isEmpty
    }

    /// Formats a plate weight that is already in the display unit (not kg).
    static func formatPlateWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : WeightUnitConversion.formatValue(value, maximumFractionDigits: 2)
    }

    /// Formats a weight in kg for display in the given unit.
    static func formatWeight(_ kg: Double, weightUnit: WeightUnit = .pounds) -> String {
        WeightUnitConversion.format(kilograms: kg, unit: weightUnit, maximumFractionDigits: 1)
    }

    static func barOnlyText(barKg: Double, weightUnit: WeightUnit = .pounds) -> String {
        "Bar only (\(formatWeight(barKg, weightUnit: weightUnit)) \(weightUnit.symbol))"
    }

    static func presetLabel(preset: BarbellPresetDTO, weightUnit: WeightUnit) -> String {
        let weight = WeightUnitConversion.format(kilograms: preset.weightKg, unit: weightUnit, maximumFractionDigits: 1)
        return "\(preset.name) (\(weight) \(weightUnit.symbol))"
    }

    static func description(
        totalWeightKg: Double,
        barbellWeightKg: Double,
        plates: [(weight: Double, count: Int)],
        weightUnit: WeightUnit = .pounds
    ) -> String {
        if plates.isEmpty {
            return barOnlyText(barKg: barbellWeightKg, weightUnit: weightUnit)
        }
        let parts = plates.map { plate in
            "\(plate.count)×\(formatPlateWeight(plate.weight))\(weightUnit.symbol)"
        }
        return "\(formatWeight(totalWeightKg, weightUnit: weightUnit)) \(weightUnit.symbol) total • \(parts.joined(separator: " + ")) per side"
    }
}
