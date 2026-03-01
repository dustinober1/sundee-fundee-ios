import SwiftUI
import SwiftData

/// Max lifts and personal records screen.
struct MaxLiftsView: View {
    @State private var viewModel = MaxLiftsViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var showAddMax = false

    static func filteredExercises(searchText: String, exerciseNames: [String]) -> [String] {
        guard !searchText.isEmpty else { return exerciseNames }
        return exerciseNames.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    static func exerciseDestination(viewModel: MaxLiftsViewModel) -> (String) -> ExerciseDetailView {
        { exercise in
            ExerciseDetailView(exercise: exercise, viewModel: viewModel)
        }
    }
    
    static func addSheetContent(viewModel: MaxLiftsViewModel) -> () -> AddLiftMaxSheet {
        { AddLiftMaxSheet(viewModel: viewModel) }
    }

    static func presentAddSheetAction(isPresented: Binding<Bool>) -> () -> Void {
        { isPresented.wrappedValue = true }
    }

    static func emptyStateTitle(searchText: String) -> String {
        searchText.isEmpty ? "No Lift Data" : "No Results"
    }

    static func emptyStateDescription(searchText: String) -> String {
        searchText.isEmpty
            ? "Complete workouts to automatically track your 1RM."
            : "Try a different search term."
    }

    static func personalRecords(for exercise: String, records: [String: [PersonalRecord]]) -> [PersonalRecord] {
        records[exercise, default: []]
    }
    
    private var filteredExercises: [String] {
        Self.filteredExercises(searchText: searchText, exerciseNames: viewModel.exerciseNames)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            List {
                if filteredExercises.isEmpty {
                    ContentUnavailableView(
                        Self.emptyStateTitle(searchText: searchText),
                        systemImage: "dumbbell",
                        description: Text(Self.emptyStateDescription(searchText: searchText))
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredExercises, id: \.self) { exercise in
                        NavigationLink(value: exercise) {
                            LiftMaxRow(
                                exercise: exercise,
                                oneRepMax: viewModel.oneRepMaxes[exercise],
                                prs: Self.personalRecords(for: exercise, records: viewModel.personalRecords),
                                weightUnit: viewModel.weightUnit
                            )
                        }
                    }

                    if !viewModel.conditioningExerciseNames.isEmpty {
                        Section {
                            ForEach(viewModel.conditioningPRs, id: \.id) { pr in
                                ConditioningPRRow(pr: pr)
                            }
                        } header: {
                            Text("Conditioning PRs")
                                .font(AppTheme.Fonts.subheading)
                                .foregroundStyle(AppTheme.Colors.navy)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .searchable(text: $searchText, prompt: "Search exercises")
        }
        .navigationTitle("Lift Maxes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: Self.presentAddSheetAction(isPresented: $showAddMax)) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add lift max")
            }
        }
        .navigationDestination(for: String.self, destination: Self.exerciseDestination(viewModel: viewModel))
        .sheet(isPresented: $showAddMax, content: Self.addSheetContent(viewModel: viewModel))
        .task { await viewModel.load(modelContext: modelContext) }
        .onReceive(NotificationCenter.default.publisher(for: .didSaveNewPRs)) { _ in
            Task { await viewModel.load(modelContext: modelContext) }
        }
    }
}

// MARK: - LiftMaxRow

struct LiftMaxRow: View {
    let exercise: String
    let oneRepMax: OneRepMax?
    let prs: [PersonalRecord]
    let weightUnit: WeightUnit

    init(
        exercise: String,
        oneRepMax: OneRepMax?,
        prs: [PersonalRecord],
        weightUnit: WeightUnit = .kilograms
    ) {
        self.exercise = exercise
        self.oneRepMax = oneRepMax
        self.prs = prs
        self.weightUnit = weightUnit
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(prs.prefix(3)) { pr in
                        PRBadge(pr: pr, weightUnit: weightUnit)
                    }
                }
            }
            Spacer()
            if let orm = oneRepMax {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(WeightUnitConversion.formatWithUnit(kilograms: orm.weightKg, unit: weightUnit))
                        .font(AppTheme.Fonts.subheading)
                        .foregroundStyle(AppTheme.Colors.navy)
                    Text("Est. 1RM")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PRBadge: View {
    let pr: PersonalRecord
    let weightUnit: WeightUnit

    init(pr: PersonalRecord, weightUnit: WeightUnit = .kilograms) {
        self.pr = pr
        self.weightUnit = weightUnit
    }

    var body: some View {
        Text("\(pr.reps)RM: \(WeightUnitConversion.formatWithUnit(kilograms: pr.weightKg, unit: weightUnit, maximumFractionDigits: 1))")
            .font(AppTheme.Fonts.caption)
            .foregroundStyle(AppTheme.Colors.navy)   // navy on orange passes WCAG AA (~4.7:1)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppTheme.Colors.accentOrange)
            .clipShape(Capsule())
    }
}

// MARK: - ConditioningPRRow

struct ConditioningPRRow: View {
    let pr: ConditioningPR

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pr.exerciseID)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                if let kg = pr.weightKg, kg > 0 {
                    Text("@ \(Int(kg)) kg")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(pr.scoringType.formatValue(pr.bestValue))
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
                Text(pr.achievedAt, style: .date)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ExerciseDetailView

struct ExerciseDetailView: View {
    let exercise: String
    @Bindable var viewModel: MaxLiftsViewModel

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            List {
                if let orm = viewModel.oneRepMaxes[exercise] {
                    Section("Estimated 1RM") {
                        HStack {
                            Text(WeightUnitConversion.formatWithUnit(kilograms: orm.weightKg, unit: viewModel.weightUnit))
                                .font(AppTheme.Fonts.heading)
                                .foregroundStyle(AppTheme.Colors.navy)
                            Spacer()
                            Text(orm.date, style: .date)
                                .font(AppTheme.Fonts.caption)
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                        }
                    }

                }

                let prs = viewModel.personalRecords[exercise] ?? []
                if !prs.isEmpty {
                    Section("Personal Records") {
                        ForEach(prs) { pr in
                            HStack {
                                Text("\(pr.reps)-Rep Max")
                                    .font(AppTheme.Fonts.body)
                                    .foregroundStyle(AppTheme.Colors.navy)
                                Spacer()
                                Text(WeightUnitConversion.formatWithUnit(kilograms: pr.weightKg, unit: viewModel.weightUnit))
                                    .font(AppTheme.Fonts.subheading)
                                    .foregroundStyle(AppTheme.Colors.accentOrange)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(exercise)
    }
}

// MARK: - AddLiftMaxSheet

struct AddLiftMaxSheet: View {
    @Bindable var viewModel: MaxLiftsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedExercise: String
    @State private var weightKg: String
    @State private var reps: Int
    @State private var isEstimated: Bool
    
    init(
        viewModel: MaxLiftsViewModel,
        selectedExercise: String = WeightliftingExerciseCatalog.defaultExerciseID,
        weightKg: String = "",
        reps: Int = 1,
        isEstimated: Bool = false
    ) {
        self.viewModel = viewModel
        _selectedExercise = State(initialValue: selectedExercise)
        _weightKg = State(initialValue: weightKg)
        _reps = State(initialValue: reps)
        _isEstimated = State(initialValue: isEstimated)
    }
    
    static func saveAction(
        viewModel: MaxLiftsViewModel,
        selectedExercise: String,
        weightKg: String,
        reps: Int,
        isEstimated: Bool,
        weightUnit: WeightUnit = .kilograms,
        dismiss: @escaping () -> Void
    ) -> () -> Void {
        {
            guard let kg = WeightUnitConversion.parseInputToKilograms(weightKg, unit: weightUnit) else { return }
            viewModel.addMax(
                exercise: selectedExercise,
                weightKg: kg,
                reps: reps,
                isEstimated: isEstimated
            )
            dismiss()
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    Picker("Exercise", selection: $selectedExercise) {
                        ForEach(WeightliftingExerciseCatalog.sortedByCategory) { entry in
                            Text(entry.id).tag(entry.id)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("Performance") {
                    TextField("Weight (\(viewModel.weightUnit.symbol))", text: $weightKg)
                        .keyboardType(.decimalPad)
                    Stepper("Reps: \(reps)", value: $reps, in: 1...20)
                    Toggle("Estimated (via Epley formula)", isOn: $isEstimated)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.cream)
            .navigationTitle("Add Lift Max")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Self.saveAction(
                            viewModel: viewModel,
                            selectedExercise: selectedExercise,
                            weightKg: weightKg,
                            reps: reps,
                            isEstimated: isEstimated,
                            weightUnit: viewModel.weightUnit,
                            dismiss: dismiss.callAsFunction
                        )()
                    }
                }
            }
        }
    }
}
