import Foundation
import SwiftData

// MARK: - HistoryFilter

enum HistoryFilter: String, CaseIterable, Sendable {
    case all = "All"
    case ai = "AI"
    case program = "Program"
}

// MARK: - UnifiedHistoryViewModel

@MainActor
@Observable
final class UnifiedHistoryViewModel {
    var items: [HistoryItem] = []
    var isLoading = false
    var selectedFilter: HistoryFilter = .all
    var selectedItems: Set<String> = []
    var isEditing = false
    var showDeleteConfirmation = false

    private let aiService: any AIWorkoutServiceProtocol
    private let workoutRepo: any WorkoutRepository
    private let programRepo: any ProgramRepository
    private let userID: String

    /// Cache for deletion — maps HistoryItem.originalID to CompletedWorkout.
    private var completedWorkoutCache: [String: CompletedWorkout] = [:]

    init(
        userID: String,
        aiService: any AIWorkoutServiceProtocol,
        workoutRepo: any WorkoutRepository,
        programRepo: any ProgramRepository
    ) {
        self.userID = userID
        self.aiService = aiService
        self.workoutRepo = workoutRepo
        self.programRepo = programRepo
    }

    var filteredItems: [HistoryItem] {
        Self.applyFilter(items, filter: selectedFilter)
    }

    static func applyFilter(_ items: [HistoryItem], filter: HistoryFilter) -> [HistoryItem] {
        switch filter {
        case .all: return items
        case .ai: return items.filter { $0.source == .aiWorkout }
        case .program: return items.filter {
            if case .program = $0.source { return true }
            return false
        }
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        var allItems: [HistoryItem] = []

        // Fetch AI workouts (completed only)
        let aiWorkouts = (try? await aiService.fetchHistory(userID: userID)) ?? []
        let aiItems = aiWorkouts.filter { $0.isCompleted }.map { workout in
            HistoryItem(
                id: "ai-\(workout.id)",
                title: workout.questionnaire.focus.displayName,
                source: .aiWorkout,
                completedAt: workout.createdAt,
                exerciseCount: workout.exercises.count,
                durationSeconds: workout.questionnaire.timeMinutes * 60,
                originalID: workout.id,
                isAIWorkout: true
            )
        }
        allItems.append(contentsOf: aiItems)

        // Fetch program workouts
        let completedWorkouts = (try? workoutRepo.fetchWorkouts()) ?? []
        let programs = (try? await programRepo.fetchPrograms()) ?? []
        let programMap = Dictionary(uniqueKeysWithValues: programs.map { ($0.id, $0.name) })

        // Cache CompletedWorkout objects for deletion
        completedWorkoutCache = [:]
        for workout in completedWorkouts {
            completedWorkoutCache[workout.id] = workout
        }

        let programItems = completedWorkouts.map { workout in
            HistoryItem(
                id: "prog-\(workout.id)",
                title: "Week \(workout.week), Day \(workout.day)",
                source: .program(name: programMap[workout.programID] ?? "Program"),
                completedAt: workout.completedAt,
                exerciseCount: 0,
                durationSeconds: workout.durationSeconds,
                originalID: workout.id,
                isAIWorkout: false
            )
        }
        allItems.append(contentsOf: programItems)

        // Sort chronologically, newest first
        items = allItems.sorted { $0.completedAt > $1.completedAt }
    }

    func deleteItem(_ item: HistoryItem) async {
        if item.isAIWorkout {
            try? await aiService.deleteWorkout(workoutID: item.originalID)
        } else if let completed = completedWorkoutCache[item.originalID] {
            try? workoutRepo.deleteWorkoutWithSets(completed)
            completedWorkoutCache.removeValue(forKey: item.originalID)
        }
        items.removeAll { $0.id == item.id }
    }

    func deleteSelected() async {
        for id in selectedItems {
            if let item = items.first(where: { $0.id == id }) {
                await deleteItem(item)
            }
        }
        selectedItems.removeAll()
        isEditing = false
    }
}
