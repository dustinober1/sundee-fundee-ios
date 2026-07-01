import SwiftUI

// MARK: - Benchmarks List View
//
// Lists all available benchmarks by category with readiness indicators.
// Shows user's previous results and PRs.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct BenchmarksListView: View {
    @StateObject private var viewModel = BenchmarksListViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.benchmarks.isEmpty {
                    ProgressView("Loading benchmarks...")
                } else if viewModel.benchmarks.isEmpty {
                    EmptyStateView(
                        icon: "target",
                        title: "No Benchmarks in This Category",
                        subtitle: "Try selecting a different category above, or pull to refresh.",
                        actionLabel: "Show All",
                        action: {
                            if let first = BenchmarkCatalog.categories.first {
                                viewModel.selectCategory(first)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    benchmarkList
                }
            }
            .navigationTitle("Benchmarks")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(BenchmarkCatalog.categories, id: \.self) { category in
                    Button(category) {
                        viewModel.selectCategory(category)
                    }
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(viewModel.selectedCategory == category ? AppTheme.Text.cream : AppTheme.Text.secondary)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(viewModel.selectedCategory == category ? AppTheme.Background.navy : AppTheme.Background.cream.opacity(0.5))
                    .cornerRadius(AppTheme.CornerRadius.small)
                    .accessibilityLabel("\(category) category")
                    .accessibilityAddTraits(viewModel.selectedCategory == category ? .isSelected : [])
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
    }

    // MARK: - Benchmark List

    private var benchmarkList: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Category Picker
                categoryPicker

                // Benchmarks
                ForEach(viewModel.benchmarks) { benchmark in
                    BenchmarkRow(
                        benchmark: benchmark,
                        readiness: viewModel.getReadiness(for: benchmark),
                        hasCompleted: viewModel.hasCompletedBenchmark(benchmark.id),
                        bestResult: viewModel.getBestResult(for: benchmark.id)
                    )
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
    }
}

// MARK: - Benchmark Row

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct BenchmarkRow: View {
    let benchmark: ContentBenchmark
    let readiness: BenchmarkReadiness
    let hasCompleted: Bool
    let bestResult: BenchmarkResult?

    var body: some View {
        NavigationLink(destination: BenchmarkDetailView(benchmarkId: benchmark.id)) {
            ArtDecoCard {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    // Header
                    HStack {
                        Text(benchmark.name)
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        Spacer()

                        // Completion status
                        if hasCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.Accent.gold)
                                .accessibilityLabel("Completed")
                        }

                        // Readiness indicator
                        Text(readiness.emoji)
                            .font(.headline)
                            .accessibilityHidden(true)
                    }

                    // Readiness Banner
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text(readiness.tier.rawValue.capitalized)
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(readinessTierColor(readiness.tier))

                        Text("•")
                            .foregroundColor(AppTheme.Text.secondary)

                        Text(readiness.reason)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                    }

                    // Description
                    Text(benchmark.workoutDescription)
                        .font(AppTheme.Typography.bodyMedium)
                        .foregroundColor(AppTheme.Text.primary)
                        .lineLimit(3)

                    // Tags
                    if let tags = benchmark.movementTags, !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.xs) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(AppTheme.Typography.labelMedium)
                                        .foregroundColor(AppTheme.Accent.gold)
                                        .padding(.horizontal, AppTheme.Spacing.sm)
                                        .padding(.vertical, AppTheme.Spacing.xs)
                                        .background(AppTheme.Accent.goldLight)
                                        .cornerRadius(AppTheme.CornerRadius.small)
                                }
                            }
                        }
                    }

                    // Best Result
                    if let result = bestResult {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(AppTheme.Accent.gold)
                                .accessibilityHidden(true)

                            Text("Best: \(formatScore(result.score))")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Text.primary)

                            Spacer()

                            Text(result.date, style: .date)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                    }

                    // Intensity indicator
                    intensityIndicator
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("View benchmark details and log results")
    }

    private var accessibilitySummary: String {
        var parts: [String] = [benchmark.name]
        parts.append("Readiness: \(readiness.tier.rawValue.capitalized)")
        if hasCompleted { parts.append("Completed") }
        if let result = bestResult {
            parts.append("Best: \(formatScore(result.score))")
        }
        return parts.joined(separator: ". ")
    }

    private var intensityIndicator: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Text("Intensity:")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.secondary)

            ForEach(1...5, id: \.self) { level in
                if let intensity = benchmark.intensity {
                    Circle()
                        .fill(level <= intensity ? AppTheme.Accent.gold : AppTheme.Accent.gold.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .accessibilityLabel("Intensity: \(benchmark.intensity ?? 0) out of 5")
    }

    private func readinessTierColor(_ tier: ReadinessTier) -> Color {
        switch tier {
        case .peak: return .green
        case .moderate: return AppTheme.Accent.gold
        case .recovery: return AppTheme.Accent.orange
        }
    }

    private func formatScore(_ score: Double) -> String {
        switch benchmark.scoringType {
        case "time":
            let minutes = Int(score) / 60
            let seconds = Int(score) % 60
            return String(format: "%d:%02d", minutes, seconds)
        case "roundsAndReps":
            let rounds = Int(score) / 10000
            let reps = Int(score) % 10000
            return "\(rounds) + \(reps)"
        case "load":
            return "\(Int(score)) lb"
        case "reps":
            return "\(Int(score)) reps"
        case "calories":
            return "\(Int(score)) cal"
        case "distance":
            return "\(Int(score)) m"
        default:
            return "\(Int(score))"
        }
    }
}

// MARK: - Benchmark Detail View

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct BenchmarkDetailView: View {
    let benchmarkId: String
    @StateObject private var viewModel = BenchmarkDetailViewModel()
    @Environment(\.dismiss) private var dismiss

    public init(benchmarkId: String) {
        self.benchmarkId = benchmarkId
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.benchmark == nil {
                    ProgressView("Loading benchmark...")
                } else if let benchmark = viewModel.benchmark {
                    benchmarkContent(benchmark)
                } else {
                    Text("Benchmark not found")
                        .foregroundColor(AppTheme.Text.secondary)
                }
            }
            .navigationTitle(viewModel.benchmark?.name ?? "Benchmark")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Log Result") {
                        viewModel.showingScoreEntry = true
                    }
                    .artDecoButton(style: .primary)
                    .accessibilityLabel("Log benchmark result")
                }
            }
            .task {
                await viewModel.loadBenchmark(id: benchmarkId)
            }
            .sheet(isPresented: $viewModel.showingScoreEntry) {
                if let benchmark = viewModel.benchmark {
                    BenchmarkScoreEntryView(
                        benchmark: benchmark,
                        viewModel: viewModel
                    )
                }
            }
        }
    }

    // MARK: - Benchmark Content

    private func benchmarkContent(_ benchmark: BenchmarkDefinition) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                // Readiness Card
                if let readiness = viewModel.readiness {
                    readinessCard(readiness)
                }

                // Description Card
                ArtDecoCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Workout")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        Text(benchmark.workoutDescription)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Text.primary)
                    }
                }

                // Details
                detailsSection(benchmark)

                // Coach Notes
                if let notes = benchmark.coachNotes {
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Label("Coach Notes", systemImage: "lightbulb.fill")
                                .font(AppTheme.Typography.headlineMedium)
                                .foregroundColor(AppTheme.Accent.gold)

                            Text(notes)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Text.primary)
                        }
                    }
                }

                // Previous Results
                if !viewModel.previousResults.isEmpty {
                    previousResultsSection
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
    }

    private func readinessCard(_ readiness: BenchmarkReadiness) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text(readiness.emoji)
                        .font(.title)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(readiness.tier.rawValue.capitalized)
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(readinessTierColor(readiness.tier))

                        Text(readiness.reason)
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Text.secondary)
                    }

                    Spacer()
                }

                Text(readiness.recommendation)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        }
    }

    private func detailsSection(_ benchmark: BenchmarkDefinition) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Details")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            // Scoring Type
            detailRow("Scoring", value: benchmark.scoringType.rawValue.capitalized)

            // Category
            detailRow("Category", value: benchmark.category)

            // Time Domain
            if let timeDomain = benchmark.timeDomain {
                detailRow("Time Domain", value: timeDomain)
            }

            // Equipment
            if let equipment = benchmark.equipment, !equipment.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Equipment")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Text.secondary)

                    ForEach(equipment, id: \.self) { item in
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Circle()
                                .fill(AppTheme.Accent.gold.opacity(0.5))
                                .frame(width: 4, height: 4)

                            Text(item)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Text.primary)
                        }
                    }
                }
            }
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.secondary)

            Spacer()

            Text(value)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.primary)
        }
    }

    private var previousResultsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Previous Results")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            ForEach(viewModel.previousResults) { result in
                ResultRow(result: result, formatScore: viewModel.formatScore)
            }
        }
    }

    private func readinessTierColor(_ tier: ReadinessTier) -> Color {
        switch tier {
        case .peak: return .green
        case .moderate: return AppTheme.Accent.gold
        case .recovery: return AppTheme.Accent.orange
        }
    }
}

// MARK: - Result Row

struct ResultRow: View {
    let result: BenchmarkResult
    let formatScore: (Double) -> String

    var body: some View {
        ArtDecoCard {
            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(formatScore(result.score))
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Text(result.date, style: .date)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                Spacer()

                if let phase = result.cyclePhase {
                    Text(cyclePhaseEmoji(phase))
                        .font(.headline)
                }
            }
        }
    }

    private func cyclePhaseEmoji(_ phase: CyclePhase) -> String {
        switch phase {
        case .menstrual: return "🔴"
        case .follicular: return "🟢"
        case .ovulation: return "⚡"
        case .luteal: return "🟡"
        }
    }
}

// MARK: - Score Entry View

struct BenchmarkScoreEntryView: View {
    let benchmark: BenchmarkDefinition
    let viewModel: BenchmarkDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var scoreText: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    scoreField
                } header: {
                    Text("Result")
                }

                Section {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("Log Result")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveResult()
                        }
                    }
                    .disabled(scoreText.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private var scoreField: some View {
        switch benchmark.scoringType {
        case .time:
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Time (mm:ss)")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                HStack {
                    TextField("mm", text: $scoreText)

                    Text(":")
                        .foregroundColor(AppTheme.Text.secondary)

                    TextField("ss", text: Binding(
                        get: {
                            let parts = scoreText.components(separatedBy: ":")
                            return parts.indices.contains(1) ? parts[1] : ""
                        },
                        set: { newValue in
                            let parts = scoreText.components(separatedBy: ":")
                            let minutes = parts.isEmpty ? "0" : parts[0]
                            scoreText = "\(minutes):\(newValue)"
                        }
                    ))
                }
            }

        case .roundsAndReps:
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Rounds + Reps")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                HStack {
                    TextField("Rounds", text: Binding(
                        get: {
                            let parts = scoreText.components(separatedBy: " + ")
                            return parts.isEmpty ? "" : parts[0]
                        },
                        set: { newValue in
                            let parts = scoreText.components(separatedBy: " + ")
                            let reps = parts.count > 1 ? parts[1] : ""
                            scoreText = "\(newValue) + \(reps)"
                        }
                    ))

                    Text("+")
                        .foregroundColor(AppTheme.Text.secondary)

                    TextField("Reps", text: Binding(
                        get: { scoreText.components(separatedBy: " + ").count > 1 ? scoreText.components(separatedBy: " + ")[1] : "" },
                        set: { newValue in
                            let parts = scoreText.components(separatedBy: " + ")
                            let rounds = parts.isEmpty ? "" : parts[0]
                            scoreText = "\(rounds) + \(newValue)"
                        }
                    ))
                }
            }

        default:
            TextField("Score", text: $scoreText)
        }
    }

    private func saveResult() async {
        let score = parseScore(scoreText)
        let didSave = await viewModel.saveResult(
            benchmarkId: benchmark.id,
            score: score,
            notes: notes.isEmpty ? nil : notes
        )
        if didSave {
            ReviewPromptCoordinator.recordSuccessfulAction(
                trigger: .benchmarkLogged,
                triggerID: "benchmark:\(benchmark.id)"
            )
        }
        dismiss()
    }

    private func parseScore(_ text: String) -> Double {
        switch benchmark.scoringType {
        case .time:
            let parts = text.components(separatedBy: ":")
            if parts.count == 2,
               let minutes = Double(parts[0]),
               let seconds = Double(parts[1]) {
                return minutes * 60 + seconds
            }
            return 0

        case .roundsAndReps:
            let parts = text.components(separatedBy: " + ")
            if parts.count == 2,
               let rounds = Double(parts[0]),
               let reps = Double(parts[1]) {
                return rounds * 10000 + reps
            }
            return 0

        default:
            return Double(text) ?? 0
        }
    }
}
