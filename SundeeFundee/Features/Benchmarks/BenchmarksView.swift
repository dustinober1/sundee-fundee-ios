import SwiftUI
import SwiftData

/// Benchmarks screen — named performance tests with history.
struct BenchmarksView: View {
    @State private var viewModel = BenchmarksViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showAdd = false
    
    static func deleteAction(viewModel: BenchmarksViewModel, entry: Benchmark) -> () -> Void {
        { viewModel.delete(entry) }
    }
    
    static func addSheetContent(viewModel: BenchmarksViewModel) -> () -> AddBenchmarkSheet {
        { AddBenchmarkSheet(viewModel: viewModel) }
    }

    static func presentAddSheetAction(isPresented: Binding<Bool>) -> () -> Void {
        { isPresented.wrappedValue = true }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            Group {
                if viewModel.groups.isEmpty {
                    ContentUnavailableView(
                        "No Benchmarks",
                        systemImage: "checkmark.seal",
                        description: Text("Log a named benchmark to track your progress over time.")
                    )
                } else {
                    List {
                        ForEach(viewModel.groups) { group in
                            Section {
                                ForEach(group.entries) { entry in
                                    BenchmarkEntryRow(entry: entry)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive, action: Self.deleteAction(viewModel: viewModel, entry: entry)) {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            } header: {
                                BenchmarkGroupHeader(group: group)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Benchmarks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: Self.presentAddSheetAction(isPresented: $showAdd)) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add benchmark")
            }
        }
        .sheet(isPresented: $showAdd, content: Self.addSheetContent(viewModel: viewModel))
        .task { await viewModel.load(modelContext: modelContext) }
    }
}

// MARK: - BenchmarkGroupHeader

struct BenchmarkGroupHeader: View {
    let group: BenchmarksViewModel.BenchmarkGroup

    var body: some View {
        HStack {
            Text(group.name)
                .font(AppTheme.Fonts.subheading)
                .foregroundStyle(AppTheme.Colors.navy)
            Spacer()
            Text("\(group.entries.count) \(group.entries.count == 1 ? "entry" : "entries")")
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
        }
        .textCase(nil)
    }
}

// MARK: - BenchmarkEntryRow

struct BenchmarkEntryRow: View {
    let entry: Benchmark

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.exercise)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f kg × %d", entry.weightKg, entry.reps))
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
                Text(entry.performedAt, style: .date)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - AddBenchmarkSheet

struct AddBenchmarkSheet: View {
    @Bindable var viewModel: BenchmarksViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var benchmarkName: String
    @State private var selectedExercise: String
    @State private var weightKg: String
    @State private var reps: Int
    @State private var notes: String
    
    init(
        viewModel: BenchmarksViewModel,
        benchmarkName: String = "",
        selectedExercise: String = WeightliftingExerciseCatalog.defaultExerciseID,
        weightKg: String = "",
        reps: Int = 1,
        notes: String = ""
    ) {
        self.viewModel = viewModel
        _benchmarkName = State(initialValue: benchmarkName)
        _selectedExercise = State(initialValue: selectedExercise)
        _weightKg = State(initialValue: weightKg)
        _reps = State(initialValue: reps)
        _notes = State(initialValue: notes)
    }

    private var canSave: Bool {
        Self.canSave(benchmarkName: benchmarkName, weightKg: weightKg)
    }
    
    static func canSave(benchmarkName: String, weightKg: String) -> Bool {
        !benchmarkName.trimmingCharacters(in: .whitespaces).isEmpty && Double(weightKg) != nil
    }
    
    static func saveAction(
        viewModel: BenchmarksViewModel,
        benchmarkName: String,
        selectedExercise: String,
        weightKg: String,
        reps: Int,
        notes: String,
        dismiss: @escaping () -> Void
    ) -> () -> Void {
        {
            guard Self.canSave(benchmarkName: benchmarkName, weightKg: weightKg), let kg = Double(weightKg) else { return }
            viewModel.add(
                name: benchmarkName.trimmingCharacters(in: .whitespaces),
                exercise: selectedExercise,
                weightKg: kg,
                reps: reps,
                notes: notes
            )
            dismiss()
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Benchmark") {
                    TextField("Name (e.g. Month 1 Baseline)", text: $benchmarkName)
                }
                Section("Exercise") {
                    Picker("Exercise", selection: $selectedExercise) {
                        ForEach(WeightliftingExerciseCatalog.sortedByCategory) { entry in
                            Text(entry.id).tag(entry.id)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("Performance") {
                    TextField("Weight (kg)", text: $weightKg)
                        .keyboardType(.decimalPad)
                    Stepper("Reps: \(reps)", value: $reps, in: 1...20)
                }
                Section("Notes") {
                    TextField("Optional notes", text: $notes)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.cream)
            .navigationTitle("Add Benchmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: Self.saveAction(
                        viewModel: viewModel,
                        benchmarkName: benchmarkName,
                        selectedExercise: selectedExercise,
                        weightKg: weightKg,
                        reps: reps,
                        notes: notes,
                        dismiss: dismiss.callAsFunction
                    ))
                    .disabled(!canSave)
                }
            }
        }
    }
}
