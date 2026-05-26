import Foundation

// MARK: - AnalyticsViewModel

/// View model that bridges the persistence layer to analytics chart views.
///
/// Fetches Workout, OneRepMaxRecord, and CyclePhaseInfo from the data client,
/// transforms them through ChartDataAggregator, and publishes chart-ready
/// data points. All analytics are available because Sundee Fundee is free.
@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
public class AnalyticsViewModel: ObservableObject {

    // MARK: - Published State

    /// Currently selected time range for all charts.
    @Published public var selectedTimeRange: TimeRange = .lastSixMonths {
        didSet {
            if selectedTimeRange != oldValue {
                reaggregate()
            }
        }
    }

    /// Currently selected exercise for the strength progression chart.
    /// When nil, all exercises are shown.
    @Published public var selectedExercise: String? {
        didSet {
            filterStrengthData()
        }
    }

    /// Strength progression data points for the selected exercise (or all).
    @Published public var strengthData: [StrengthDataPoint] = []

    /// Training volume data points aggregated by week.
    @Published public var volumeData: [VolumeDataPoint] = []

    /// Workout frequency data points aggregated by week.
    @Published public var frequencyData: [FrequencyDataPoint] = []

    /// Cycle-correlated performance data points.
    @Published public var cycleData: [CyclePerformancePoint] = []

    /// Unique exercise names available for the exercise picker.
    @Published public var availableExercises: [String] = []

    /// High-level progress summary shown before deeper charts.
    @Published public var progressSnapshot: ProgressSnapshot?
    @Published public var cycleInsights: [CycleAwareProgressInsight] = []

    /// Whether data is currently being fetched.
    @Published public var isLoading: Bool = false

    /// Error message to display if data fetching fails.
    @Published public var errorMessage: String?

    /// Whether there is no data to display (all sources empty).
    public var hasNoData: Bool {
        !isLoading && errorMessage == nil
            && allWorkouts.isEmpty && allORMRecords.isEmpty && allCyclePhases.isEmpty
    }

    // MARK: - Dependencies

    private let dataClient: DataClientProtocol

    // MARK: - Cached Raw Data

    /// All one-rep-max records fetched from persistence (unfiltered).
    private var allORMRecords: [OneRepMaxRecord] = []

    /// All workouts fetched from persistence (unfiltered).
    private var allWorkouts: [Workout] = []

    /// All cycle phase info records fetched from persistence (unfiltered).
    private var allCyclePhases: [CyclePhaseInfo] = []

    /// All challenges fetched from persistence (unfiltered).
    private var allChallenges: [Challenge] = []

    // MARK: - Initialization

    public init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.dataClient = dataClient
    }

    // MARK: - Public Methods

    /// Fetches all data from persistence and populates chart data via ChartDataAggregator.
    public func loadAnalytics() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all record types in parallel
            async let ormFetch: [OneRepMaxRecord] = dataClient.fetchAll(
                recordType: "OneRepMaxRecord"
            )
            async let workoutFetch: [Workout] = dataClient.fetchAll(
                recordType: "Workout"
            )
            async let phaseFetch: [CyclePhaseInfo] = dataClient.fetchAll(
                recordType: "CyclePhaseInfo"
            )

            let (ormRecords, workouts, phases) = try await (ormFetch, workoutFetch, phaseFetch)
            let challenges: [Challenge] = (try? await dataClient.fetchAll(recordType: "Challenge")) ?? []

            // Cache raw data
            allORMRecords = ormRecords
            allWorkouts = workouts
            allCyclePhases = phases
            allChallenges = challenges

            // Populate available exercises
            availableExercises = ChartDataAggregator.exercises(from: ormRecords)

            // Reaggregate with current time range
            reaggregate()
        } catch {
            errorMessage = error.localizedDescription
            // Clear chart data on error — graceful degradation
            strengthData = []
            volumeData = []
            frequencyData = []
            cycleData = []
            availableExercises = []
            progressSnapshot = nil
            cycleInsights = []
        }

        isLoading = false
    }

    /// Filters the strength progression chart to a single exercise.
    ///
    /// Pass nil to show all exercises.
    public func selectExercise(_ name: String?) {
        selectedExercise = name
    }

    // MARK: - Private Methods

    /// Re-runs all aggregators with the current time range and cached data.
    private func reaggregate() {
        let range = selectedTimeRange

        // Strength progression
        let allStrength = ChartDataAggregator.strengthProgression(
            from: allORMRecords,
            timeRange: range
        )

        // Apply exercise filter
        if let exercise = selectedExercise {
            strengthData = allStrength.filter { $0.exerciseName == exercise }
        } else {
            strengthData = allStrength
        }

        // Training volume
        volumeData = ChartDataAggregator.trainingVolume(
            from: allWorkouts,
            timeRange: range
        )

        // Workout frequency
        frequencyData = ChartDataAggregator.workoutFrequency(
            from: allWorkouts,
            timeRange: range
        )

        // Cycle correlation
        cycleData = ChartDataAggregator.cycleCorrelation(
            from: allWorkouts,
            phases: allCyclePhases,
            timeRange: range
        )

        progressSnapshot = ProgressSnapshotService.build(
            maxRecords: allORMRecords,
            workouts: allWorkouts,
            challenges: allChallenges,
            cycleData: cycleData
        )
        cycleInsights = CycleAwareProgressInsightService.build(
            cycleData: cycleData,
            workouts: allWorkouts,
            maxRecords: allORMRecords
        )
    }

    /// Filters strength data to the selected exercise without re-fetching.
    private func filterStrengthData() {
        let allStrength = ChartDataAggregator.strengthProgression(
            from: allORMRecords,
            timeRange: selectedTimeRange
        )

        if let exercise = selectedExercise {
            strengthData = allStrength.filter { $0.exerciseName == exercise }
        } else {
            strengthData = allStrength
        }
    }
}
