import Foundation
import SwiftData

/// View model for a single benchmark's detail screen.
///
/// Loads and displays all logged results for one `BenchmarkDefinition`,
/// computes the best result based on scoring type, and formats scores for display.
@MainActor
@Observable
final class BenchmarkDetailViewModel {
    let definition: BenchmarkDefinition
    var results: [BenchmarkResult] = []
    var isLoading = false

    private var modelContext: ModelContext?
    private var userID: String = ""
    private let resultRepoFactory: (ModelContext) -> any BenchmarkResultRepository

    init(
        definition: BenchmarkDefinition,
        resultRepoFactory: @escaping (ModelContext) -> any BenchmarkResultRepository = {
            SwiftDataBenchmarkResultRepository(context: $0)
        }
    ) {
        self.definition = definition
        self.resultRepoFactory = resultRepoFactory
    }

    func load(modelContext: ModelContext, userID: String = "") async {
        self.modelContext = modelContext
        self.userID = userID
        isLoading = true
        defer { isLoading = false }
        let repo = resultRepoFactory(modelContext)
        results = (try? repo.fetchResults(forDefinitionID: definition.id)) ?? []
    }

    /// The best result based on the definition's scoring type.
    /// - Time/distance: lowest score wins.
    /// - Weight/reps: highest score wins.
    var bestResult: BenchmarkResult? {
        switch definition.scoringType {
        case .time, .distance:
            return results.min(by: { $0.scoreValue < $1.scoreValue })
        case .weight, .reps:
            return results.max(by: { $0.scoreValue < $1.scoreValue })
        }
    }

    func logResult(scoreValue: Double, notes: String, performedAt: Date = .now) {
        guard let ctx = modelContext else { return }
        let result = BenchmarkResult(
            userID: userID,
            definitionID: definition.id,
            scoreValue: scoreValue,
            notes: notes,
            performedAt: performedAt
        )
        let repo = resultRepoFactory(ctx)
        try? repo.save(result)
        results.insert(result, at: 0)
    }

    func deleteResult(_ result: BenchmarkResult) {
        guard let ctx = modelContext else { return }
        let repo = resultRepoFactory(ctx)
        try? repo.delete(result)
        results.removeAll { $0.id == result.id }
    }

    /// Human-readable score string for a given value and scoring type.
    func formatted(score: Double, for type: BenchmarkScoringType) -> String {
        switch type {
        case .time, .distance:
            let total = Int(score)
            let minutes = total / 60
            let seconds = total % 60
            return String(format: "%d:%02d", minutes, seconds)
        case .weight:
            return String(format: "%.1f kg", score)
        case .reps:
            return "\(Int(score)) rds"
        }
    }
}
