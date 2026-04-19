import AppIntents

// MARK: - ExerciseCatalogEntity
//
// Wraps WeightliftingEntry as an AppEntity so App Intents can resolve the
// user's chosen exercise via Siri, Shortcuts, or Spotlight.

@available(iOS 18.0, *)
public struct ExerciseCatalogEntity: AppEntity, Identifiable {
    public let id: String
    public let categoryRaw: String

    public static var defaultQuery = ExerciseCatalogQuery()

    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Exercise")
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)", subtitle: "\(categoryRaw)")
    }

    public init(id: String, categoryRaw: String) {
        self.id = id
        self.categoryRaw = categoryRaw
    }

    public init(entry: WeightliftingEntry) {
        self.id = entry.id
        self.categoryRaw = entry.category.rawValue
    }
}

// MARK: - Query

@available(iOS 18.0, *)
public struct ExerciseCatalogQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [ExerciseCatalogEntity.ID]) async throws -> [ExerciseCatalogEntity] {
        weightliftingExercises
            .filter { identifiers.contains($0.id) }
            .map(ExerciseCatalogEntity.init(entry:))
    }

    public func suggestedEntities() async throws -> [ExerciseCatalogEntity] {
        weightliftingExercises.map(ExerciseCatalogEntity.init(entry:))
    }
}
