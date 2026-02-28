import Foundation
import SwiftData

final class SwiftDataWorkoutRepository: WorkoutRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ workout: CompletedWorkout) throws {
        context.insert(workout)
        try context.save()
    }

    func fetchWorkouts() throws -> [CompletedWorkout] {
        let descriptor = FetchDescriptor<CompletedWorkout>(
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchWorkout(id: UUID) throws -> CompletedWorkout? {
        let idString = id.uuidString
        let descriptor = FetchDescriptor<CompletedWorkout>(
            predicate: #Predicate { $0.id == idString }
        )
        return try context.fetch(descriptor).first
    }

    func delete(_ workout: CompletedWorkout) throws {
        context.delete(workout)
        try context.save()
    }

    func deleteWorkoutWithSets(_ workout: CompletedWorkout) throws {
        let workoutID = workout.id
        let setsDescriptor = FetchDescriptor<CompletedSet>(
            predicate: #Predicate { $0.workoutID == workoutID }
        )
        let sets = (try? context.fetch(setsDescriptor)) ?? []
        sets.forEach { context.delete($0) }
        context.delete(workout)
        try context.save()
    }

    func save(_ set: CompletedSet) throws {
        context.insert(set)
        try context.save()
    }

    func fetchSets(for workout: CompletedWorkout) throws -> [CompletedSet] {
        let workoutID = workout.id
        let descriptor = FetchDescriptor<CompletedSet>(
            predicate: #Predicate { $0.workoutID == workoutID },
            sortBy: [SortDescriptor(\.setIndex)]
        )
        return try context.fetch(descriptor)
    }
}
