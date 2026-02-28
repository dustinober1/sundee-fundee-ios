import SwiftUI
import SwiftData
import Charts

/// Detail screen for a single benchmark — shows description, personal best, progress chart, and history.
struct BenchmarkDetailView: View {
    let definition: BenchmarkDefinition
    @State private var viewModel: BenchmarkDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showLogResult = false

    init(definition: BenchmarkDefinition) {
        self.definition = definition
        _viewModel = State(initialValue: BenchmarkDetailViewModel(definition: definition))
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            List {
                // Description
                Section {
                    Text(definition.workoutDescription)
                        .font(AppTheme.Fonts.body)
                        .foregroundStyle(AppTheme.Colors.navy)
                        .padding(.vertical, 4)
                }

                // Personal best
                if let best = viewModel.bestResult {
                    Section("Personal Best") {
                        HStack {
                            Text(viewModel.formatted(score: best.scoreValue, for: definition.scoringType))
                                .font(AppTheme.Fonts.heading)
                                .foregroundStyle(AppTheme.Colors.accentOrange)
                            Spacer()
                            Text(best.performedAt, style: .date)
                                .font(AppTheme.Fonts.caption)
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                        }
                    }
                }

                // Progress chart
                if viewModel.results.count > 1 {
                    Section("Progress") {
                        BenchmarkProgressChart(
                            results: viewModel.results,
                            scoringType: definition.scoringType,
                            viewModel: viewModel
                        )
                        .frame(height: 160)
                        .padding(.vertical, 4)
                    }
                }

                // History
                if !viewModel.results.isEmpty {
                    Section("History") {
                        ForEach(viewModel.results) { result in
                            BenchmarkResultRow(result: result, viewModel: viewModel, definition: definition)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deleteResult(result)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(definition.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showLogResult = true } label: {
                    Label("Log Result", systemImage: "plus")
                }
                .accessibilityLabel("Log result")
            }
        }
        .sheet(isPresented: $showLogResult) {
            LogBenchmarkResultSheet(viewModel: viewModel, definition: definition)
        }
        .task { await viewModel.load(modelContext: modelContext) }
    }
}

// MARK: - BenchmarkResultRow

struct BenchmarkResultRow: View {
    let result: BenchmarkResult
    let viewModel: BenchmarkDetailViewModel
    let definition: BenchmarkDefinition

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.formatted(score: result.scoreValue, for: definition.scoringType))
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.navy)
                if !result.notes.isEmpty {
                    Text(result.notes)
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(result.performedAt, style: .date)
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - BenchmarkProgressChart

struct BenchmarkProgressChart: View {
    let results: [BenchmarkResult]
    let scoringType: BenchmarkScoringType
    let viewModel: BenchmarkDetailViewModel

    var body: some View {
        let sorted = results.sorted { $0.performedAt < $1.performedAt }
        Chart {
            ForEach(sorted) { result in
                LineMark(
                    x: .value("Date", result.performedAt),
                    y: .value("Score", result.scoreValue)
                )
                .foregroundStyle(AppTheme.Colors.accentOrange)
                PointMark(
                    x: .value("Date", result.performedAt),
                    y: .value("Score", result.scoreValue)
                )
                .foregroundStyle(AppTheme.Colors.accentOrange)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(viewModel.formatted(score: v, for: scoringType))
                            .font(.caption2)
                    }
                }
            }
        }
    }
}

// MARK: - LogBenchmarkResultSheet

struct LogBenchmarkResultSheet: View {
    let viewModel: BenchmarkDetailViewModel
    let definition: BenchmarkDefinition
    @Environment(\.dismiss) private var dismiss

    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    @State private var weightKg: String = ""
    @State private var repCount: Int = 1
    @State private var performedAt: Date = .now
    @State private var notes: String = ""

    private var scoringType: BenchmarkScoringType { definition.scoringType }

    private var canSave: Bool {
        switch scoringType {
        case .time, .distance: return minutes > 0 || seconds > 0
        case .weight:          return Double(weightKg) != nil
        case .reps:            return repCount > 0
        }
    }

    private var scoreValue: Double {
        switch scoringType {
        case .time, .distance: return Double(minutes * 60 + seconds)
        case .weight:          return Double(weightKg) ?? 0
        case .reps:            return Double(repCount)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Result") {
                    switch scoringType {
                    case .time, .distance:
                        HStack {
                            Stepper("Min: \(minutes)", value: $minutes, in: 0...999)
                            Stepper("Sec: \(seconds)", value: $seconds, in: 0...59)
                        }
                    case .weight:
                        TextField("Weight (kg)", text: $weightKg)
                            .keyboardType(.decimalPad)
                    case .reps:
                        Stepper("Reps / Rounds: \(repCount)", value: $repCount, in: 1...9999)
                    }
                }
                Section("Date") {
                    DatePicker("Date", selection: $performedAt, displayedComponents: .date)
                }
                Section("Notes") {
                    TextField("Optional notes", text: $notes)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.cream)
            .navigationTitle("Log Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.logResult(scoreValue: scoreValue, notes: notes, performedAt: performedAt)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
