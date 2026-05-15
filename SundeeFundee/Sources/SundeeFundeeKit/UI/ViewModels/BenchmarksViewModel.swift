import Foundation

// MARK: - Benchmarks List View Model

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public class BenchmarksListViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedCategory: String = BenchmarkCategory.sundeeFundee.rawValue
    @Published var benchmarks: [ContentBenchmark] = []
    @Published var userResults: [String: [BenchmarkResult]] = [:]
    @Published var cyclePhase: CyclePhase?

    // MARK: - Dependencies

    private let dataClient: DataClientProtocol
    private let healthClient: HealthClientProtocol
    private let contentClient: ContentClientProtocol

    // MARK: - Initialization

    public init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client,
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client,
        contentClient: ContentClientProtocol? = nil
    ) {
        self.dataClient = dataClient
        self.healthClient = healthClient
        self.contentClient = contentClient ?? BundledContentProvider()
    }

    // MARK: - Public Methods

    /// Load benchmarks and user results
    public func loadData() async {
        isLoading = true
        errorMessage = nil

        // Load user results and cycle phase in parallel
        async let userResultsTask: Void = loadUserResults()
        async let cyclePhaseTask: Void = loadCyclePhase()
        _ = await (userResultsTask, cyclePhaseTask)

        // Update benchmarks for selected category
        updateBenchmarksForCategory()

        isLoading = false
    }

    /// Change selected category
    public func selectCategory(_ category: String) {
        selectedCategory = category
        updateBenchmarksForCategory()
    }

    /// Get readiness for a benchmark
    public func getReadiness(for benchmark: ContentBenchmark) -> BenchmarkReadiness {
        let intensity = benchmark.intensity.flatMap { BenchmarkIntensity(rawValue: $0) }
        return BenchmarkReadinessCalculator.calculateReadiness(
            phase: cyclePhase,
            benchmarkIntensity: intensity,
            movementTags: benchmark.movementTags
        )
    }

    /// Check if user has completed this benchmark
    public func hasCompletedBenchmark(_ benchmarkId: String) -> Bool {
        return userResults[benchmarkId] != nil && !(userResults[benchmarkId]?.isEmpty ?? true)
    }

    /// Get best result for a benchmark
    public func getBestResult(for benchmarkId: String) -> BenchmarkResult? {
        guard let results = userResults[benchmarkId] else { return nil }
        let scoringType = benchmarks.first { $0.id == benchmarkId }?.scoringType ?? "reps"
        if scoringType == "time" {
            return results.min(by: { $0.score < $1.score })
        } else {
            return results.max(by: { $0.score < $1.score })
        }
    }

    /// Format score for display
    public func formatScore(benchmark: ContentBenchmark, score: Double) -> String {
        switch benchmark.scoringType {
        case "time":
            let minutes = Int(score) / 60
            let seconds = Int(score) % 60
            return String(format: "%d:%02d", minutes, seconds)
        case "roundsAndReps":
            let rounds = Int(score) / 10000
            let reps = Int(score) % 10000
            return "\(rounds) rounds + \(reps) reps"
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

    // MARK: - Private Methods

    private func updateBenchmarksForCategory() {
        Task {
            do {
                let allContent = try await contentClient.fetchBenchmarks()
                benchmarks = allContent
                    .filter { $0.category == selectedCategory }
                    .sorted { $0.sortOrder < $1.sortOrder }
            } catch {
                // Fallback to bundled catalog
                benchmarks = BenchmarkCatalog.benchmarks(in: selectedCategory).map { def in
                    ContentBenchmark(
                        id: def.id,
                        name: def.name,
                        category: def.category,
                        workoutDescription: def.workoutDescription,
                        scoringType: def.scoringType.rawValue,
                        intensity: def.intensity?.rawValue,
                        movementTags: def.movementTags,
                        equipment: def.equipment,
                        timeDomain: def.timeDomain,
                        coachNotes: def.coachNotes,
                        sortOrder: def.sortOrder,
                        source: .bundled
                    )
                }
            }
        }
    }

    private func loadUserResults() async {
        do {
            let records = try await dataClient.fetchAll(
                recordType: "BenchmarkResult"
            ) as [BenchmarkResult]

            // Group by benchmark ID
            var grouped: [String: [BenchmarkResult]] = [:]
            for result in records {
                if grouped[result.benchmarkId] == nil {
                    grouped[result.benchmarkId] = []
                }
                grouped[result.benchmarkId]?.append(result)
            }

            userResults = grouped
        } catch {
            errorMessage = "Failed to load benchmark results: \(error.localizedDescription)"
        }
    }

    private func loadCyclePhase() async {
        do {
            if healthClient.isAvailable {
                let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())
                let cycles = try await healthClient.fetchMenstrualCycles(
                    startDate: sixMonthsAgo,
                    endDate: nil,
                    limit: 100
                )
                if !cycles.isEmpty {
                    if let status = CyclePhaseHelper.calculatePhase(from: cycles) {
                        cyclePhase = status.currentPhase
                    }
                }
            }
        } catch {
            // HealthKit not available or permission denied — degrade gracefully
        }
    }
}

// MARK: - Benchmark Detail View Model

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public class BenchmarkDetailViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var benchmark: BenchmarkDefinition?
    @Published var readiness: BenchmarkReadiness?
    @Published var attemptWindow: AttemptWindow?
    @Published var previousResults: [BenchmarkResult] = []
    @Published var showingScoreEntry: Bool = false

    // MARK: - Dependencies

    private let dataClient: DataClientProtocol
    private let healthClient: HealthClientProtocol
    private var cachedCyclePhase: CyclePhase?

    // MARK: - Initialization

    public init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client,
        healthClient: HealthClientProtocol = HealthClientFactory.shared.client
    ) {
        self.dataClient = dataClient
        self.healthClient = healthClient
    }

    // MARK: - Public Methods

    /// Load benchmark details
    public func loadBenchmark(id: String) async {
        isLoading = true
        errorMessage = nil

        guard let benchmark = BenchmarkCatalog.benchmark(id: id) else {
            errorMessage = "Benchmark not found"
            isLoading = false
            return
        }

        self.benchmark = benchmark

        // Load readiness and previous results in parallel
        async let readinessTask: Void = loadReadiness(for: benchmark)
        async let resultsTask: Void = loadPreviousResults(benchmarkId: id)
        _ = await (readinessTask, resultsTask)

        isLoading = false
    }

    /// Save a new benchmark result
    public func saveResult(
        benchmarkId: String,
        score: Double,
        notes: String?
    ) async -> Bool {
        isLoading = true

        let result = BenchmarkResult(
            id: UUID().uuidString,
            benchmarkId: benchmarkId,
            benchmarkName: benchmark?.name ?? "Unknown",
            score: score,
            notes: notes,
            date: Date(),
            cyclePhase: readiness?.tier != nil ? getCurrentCyclePhase() : nil
        )

        do {
            try await dataClient.save(
                [result],
                recordType: "BenchmarkResult"
            )

            // Reload previous results
            await loadPreviousResults(benchmarkId: benchmarkId)
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to save result: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Delete a result
    public func deleteResult(resultId: String) async {
        isLoading = true

        // For now, just reload the results (the result will be filtered out)
        // In a full implementation, we'd need to track CKRecord.ID
        await loadPreviousResults(benchmarkId: benchmark?.id ?? "")

        isLoading = false
    }

    /// Format score for display
    public func formatScore(score: Double) -> String {
        guard let benchmark = benchmark else { return "\(score)" }

        switch benchmark.scoringType {
        case .time:
            let minutes = Int(score) / 60
            let seconds = Int(score) % 60
            return String(format: "%d:%02d", minutes, seconds)
        case .roundsAndReps:
            let rounds = Int(score) / 10000
            let reps = Int(score) % 10000
            return "\(rounds) rounds + \(reps) reps"
        case .load:
            return "\(Int(score)) lb"
        case .reps:
            return "\(Int(score)) reps"
        case .calories:
            return "\(Int(score)) cal"
        case .distance:
            return "\(Int(score)) m"
        }
    }

    // MARK: - Private Methods

    private func loadReadiness(for benchmark: BenchmarkDefinition) async {
        // Get current cycle phase from HealthKit
        var currentPhase: CyclePhase?
        var lastPeriodStart: Date?
        do {
            if healthClient.isAvailable {
                let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())
                let cycles = try await healthClient.fetchMenstrualCycles(
                    startDate: sixMonthsAgo,
                    endDate: nil,
                    limit: 100
                )
                if !cycles.isEmpty {
                    if let status = CyclePhaseHelper.calculatePhase(from: cycles) {
                        currentPhase = status.currentPhase
                        cachedCyclePhase = status.currentPhase
                    }
                    let periodLogs = CyclePhaseHelper.convertToPeriodLogs(cycles)
                    lastPeriodStart = periodLogs.last?.startDate
                }
            }
        } catch {
            // HealthKit not available or permission denied — degrade gracefully
        }

        readiness = BenchmarkReadinessCalculator.calculateReadiness(
            phase: currentPhase,
            benchmarkIntensity: benchmark.intensity,
            movementTags: benchmark.movementTags
        )

        // Calculate best attempt window if we have cycle data
        if currentPhase != nil, let lastStart = lastPeriodStart {
            attemptWindow = BenchmarkReadinessCalculator.getBestAttemptWindow(
                averageCycleLength: 28,
                lastPeriodStart: lastStart
            )
        }
    }

    private func loadPreviousResults(benchmarkId: String) async {
        do {
            let allResults = try await dataClient.fetchAll(
                recordType: "BenchmarkResult"
            ) as [BenchmarkResult]

            previousResults = allResults
                .filter { $0.benchmarkId == benchmarkId }
                .sorted { $0.date > $1.date }
        } catch {
            errorMessage = "Failed to load results: \(error.localizedDescription)"
        }
    }

    private func getCurrentCyclePhase() -> CyclePhase? {
        return cachedCyclePhase
    }
}
