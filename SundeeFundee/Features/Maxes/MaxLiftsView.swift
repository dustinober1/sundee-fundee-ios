import SwiftUI
import SwiftData

/// Max lifts and personal records screen.
struct MaxLiftsView: View {
    @State private var viewModel = MaxLiftsViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var showAddMax = false

    private var filteredExercises: [String] {
        guard !searchText.isEmpty else { return viewModel.exerciseNames }
        return viewModel.exerciseNames.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            List {
                if filteredExercises.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Lift Data" : "No Results",
                        systemImage: "dumbbell",
                        description: Text(searchText.isEmpty
                            ? "Complete workouts to automatically track your 1RM."
                            : "Try a different search term.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredExercises, id: \.self) { exercise in
                        NavigationLink(value: exercise) {
                            LiftMaxRow(
                                exercise: exercise,
                                oneRepMax: viewModel.oneRepMaxes[exercise],
                                prs: viewModel.personalRecords[exercise] ?? []
                            )
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
                Button { showAddMax = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: String.self) { exercise in
            ExerciseDetailView(exercise: exercise, viewModel: viewModel)
        }
        .sheet(isPresented: $showAddMax) {
            AddLiftMaxSheet(viewModel: viewModel)
        }
        .task { await viewModel.load(modelContext: modelContext) }
    }
}

// MARK: - LiftMaxRow

struct LiftMaxRow: View {
    let exercise: String
    let oneRepMax: OneRepMax?
    let prs: [PersonalRecord]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(prs.prefix(3)) { pr in
                        PRBadge(pr: pr)
                    }
                }
            }
            Spacer()
            if let orm = oneRepMax {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f kg", orm.weightKg))
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

    var body: some View {
        Text("\(pr.reps)RM: \(String(format: "%.1f", pr.weightKg))kg")
            .font(AppTheme.Fonts.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppTheme.Colors.accentOrange)
            .clipShape(Capsule())
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
                            Text(String(format: "%.1f kg", orm.weightKg))
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
                                Text(String(format: "%.1f kg", pr.weightKg))
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

    @State private var exerciseName = ""
    @State private var weightKg = ""
    @State private var reps = 1
    @State private var isEstimated = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Exercise name", text: $exerciseName)
                TextField("Weight (kg)", text: $weightKg)
                    .keyboardType(.decimalPad)
                Stepper("Reps: \(reps)", value: $reps, in: 1...20)
                Toggle("Estimated (via Epley formula)", isOn: $isEstimated)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.cream)
            .navigationTitle("Add Lift Max")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !exerciseName.isEmpty,
                              let kg = Double(weightKg) else { return }
                        viewModel.addMax(
                            exercise: exerciseName,
                            weightKg: kg,
                            reps: reps,
                            isEstimated: isEstimated
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
