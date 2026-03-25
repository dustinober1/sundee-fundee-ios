import Foundation
import SwiftData

/// View model for the Benchmarks screen.
///
/// Merges predefined catalog entries with user-created definitions stored in SwiftData,
/// groups them by category, and provides actions for managing custom definitions.
@MainActor
@Observable
final class BenchmarksViewModel {

    struct CategoryGroup: Identifiable {
        var id: String { category }
        let category: String
        var definitions: [BenchmarkDefinition]
    }

    var categoryGroups: [CategoryGroup] = []
    var isLoading = false

    private var modelContext: ModelContext?
    private var userID: String = ""
    private let definitionRepoFactory: (ModelContext) -> any BenchmarkDefinitionRepository
    private let remoteRepo: (any RemoteBenchmarkDefinitionRepository)?

    init(
        definitionRepoFactory: @escaping (ModelContext) -> any BenchmarkDefinitionRepository = {
            SwiftDataBenchmarkDefinitionRepository(context: $0)
        },
        remoteRepo: (any RemoteBenchmarkDefinitionRepository)?
    ) {
        self.definitionRepoFactory = definitionRepoFactory
        self.remoteRepo = remoteRepo
    }


    func load(modelContext: ModelContext, userID: String = "") async {
        self.modelContext = modelContext
        self.userID = userID
        isLoading = true
        defer { isLoading = false }

        let repo = definitionRepoFactory(modelContext)
        let userCreated = (try? repo.fetchUserCreated(userID: userID)) ?? []
        let remote: [BenchmarkDefinition]
        if let repo = remoteRepo {
            remote = (try? await repo.fetchBenchmarkDefinitions()) ?? []
        } else {
            remote = []
        }

        // Merge predefined + remote + user-created, grouped by category in display order
        var grouped: [String: [BenchmarkDefinition]] = [:]
        for def in BenchmarkCatalog.predefined + remote + userCreated {
            grouped[def.category, default: []].append(def)
        }

        categoryGroups = BenchmarkCatalog.categoryOrder.compactMap { cat in
            guard let entries = grouped[cat], !entries.isEmpty else { return nil }
            return CategoryGroup(category: cat, definitions: entries.sorted { $0.sortOrder < $1.sortOrder })
        }
        // Note: AddCustomBenchmarkSheet currently limits category selection to BenchmarkCatalog.categoryOrder,
        // so this branch is not reachable through the standard UI. Preserved for future extensibility
        // if custom categories are added.
        let known = Set(BenchmarkCatalog.categoryOrder)
        for (cat, entries) in grouped where !known.contains(cat) {
            categoryGroups.append(CategoryGroup(category: cat, definitions: entries))
        }
    }

    func addCustomDefinition(name: String, category: String, description: String, scoringType: BenchmarkScoringType) {
        guard let ctx = modelContext else { return }
        let def = BenchmarkDefinition(
            userID: userID,
            name: name,
            category: category,
            workoutDescription: description,
            scoringType: scoringType,
            isPredefined: false,
            sortOrder: Int.max
        )
        let repo = definitionRepoFactory(ctx)
        try? repo.save(def)

        if let idx = categoryGroups.firstIndex(where: { $0.category == category }) {
            categoryGroups[idx].definitions.append(def)
        } else {
            categoryGroups.append(CategoryGroup(category: category, definitions: [def]))
        }
    }

    func deleteCustomDefinition(_ definition: BenchmarkDefinition) {
        guard !definition.isPredefined, let ctx = modelContext else { return }
        let repo = definitionRepoFactory(ctx)
        try? repo.delete(definition)

        for idx in categoryGroups.indices {
            categoryGroups[idx].definitions.removeAll { $0.id == definition.id }
        }
        categoryGroups.removeAll { $0.definitions.isEmpty }
    }
}
