import Foundation
import SwiftData

/// View model for the Benchmarks screen.
///
/// Benchmarks are grouped by their `name` field so users can see how they
/// perform on the same test across multiple dates.
@MainActor
@Observable
final class BenchmarksViewModel {

    /// A named benchmark group with its associated results.
    struct BenchmarkGroup: Identifiable {
        var id: String { name }
        let name: String
        let entries: [Benchmark]

        var mostRecent: Benchmark? { entries.first }
    }

    var groups: [BenchmarkGroup] = []
    var isLoading = false

    private let repositoryFactory: (ModelContext) -> any BenchmarkRepository
    private var modelContext: ModelContext?
    private var userID: String = ""

    init(
        repositoryFactory: @escaping (ModelContext) -> any BenchmarkRepository = {
            SwiftDataBenchmarkRepository(context: $0)
        }
    ) {
        self.repositoryFactory = repositoryFactory
    }

    func load(modelContext: ModelContext, userID: String = "") async {
        self.modelContext = modelContext
        self.userID = userID
        isLoading = true
        defer { isLoading = false }

        let repo = repositoryFactory(modelContext)
        let all = (try? repo.fetchBenchmarks()) ?? []

        // Group by name, preserving insertion order of first occurrence
        var seen: [String: [Benchmark]] = [:]
        var order: [String] = []
        for b in all {
            if seen[b.name] == nil { order.append(b.name) }
            seen[b.name, default: []].append(b)
        }
        groups = order.map { name in
            BenchmarkGroup(name: name, entries: seen[name]!)
        }
    }

    func add(name: String, exercise: String, weightKg: Double, reps: Int, notes: String) {
        guard let ctx = modelContext else { return }
        let benchmark = Benchmark(
            userID: userID,
            name: name,
            exercise: exercise,
            weightKg: weightKg,
            reps: reps,
            notes: notes
        )
        let repo = repositoryFactory(ctx)
        try? repo.save(benchmark)

        // Insert at the top of the relevant group
        if let idx = groups.firstIndex(where: { $0.name == name }) {
            let updated = [benchmark] + groups[idx].entries
            groups[idx] = BenchmarkGroup(name: name, entries: updated)
        } else {
            groups.insert(BenchmarkGroup(name: name, entries: [benchmark]), at: 0)
        }
    }

    func delete(_ benchmark: Benchmark) {
        guard let ctx = modelContext else { return }
        let repo = repositoryFactory(ctx)
        try? repo.delete(benchmark)

        guard let groupIndex = groups.firstIndex(where: { group in
            group.entries.contains(where: { $0.id == benchmark.id })
        }) else { return }

        let group = groups[groupIndex]
        let filtered = group.entries.filter { $0.id != benchmark.id }
        if filtered.isEmpty {
            groups.remove(at: groupIndex)
        } else {
            groups[groupIndex] = BenchmarkGroup(name: group.name, entries: filtered)
        }
    }
}
