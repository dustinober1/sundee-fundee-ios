import Testing
import Foundation
@testable import SundeeFundee

// MARK: - HistoryItem Tests

@Suite("HistoryItem")
struct HistoryItemTests {

    @Test func sourceLabelAIWorkout() {
        let item = HistoryItem(
            id: "ai-1",
            title: "Strength",
            source: .aiWorkout,
            completedAt: .now,
            exerciseCount: 5,
            durationSeconds: 2700,
            originalID: "1",
            isAIWorkout: true
        )
        #expect(item.sourceLabel == "AI Workout")
    }

    @Test func sourceLabelProgram() {
        let item = HistoryItem(
            id: "prog-1",
            title: "Week 1, Day 1",
            source: .program(name: "Strength Builder"),
            completedAt: .now,
            exerciseCount: 0,
            durationSeconds: 3600,
            originalID: "1",
            isAIWorkout: false
        )
        #expect(item.sourceLabel == "Strength Builder")
    }

    @Test func identifiableConformance() {
        let item = HistoryItem(
            id: "test-id",
            title: "Test",
            source: .aiWorkout,
            completedAt: .now,
            exerciseCount: 0,
            durationSeconds: 0,
            originalID: "orig",
            isAIWorkout: true
        )
        #expect(item.id == "test-id")
    }

    @Test func hashableConformance() {
        let now = Date.now
        let item1 = HistoryItem(
            id: "same-id",
            title: "A",
            source: .aiWorkout,
            completedAt: now,
            exerciseCount: 1,
            durationSeconds: 100,
            originalID: "o1",
            isAIWorkout: true
        )
        // Identical items should be equal and have same hash
        let item1Copy = HistoryItem(
            id: "same-id",
            title: "A",
            source: .aiWorkout,
            completedAt: now,
            exerciseCount: 1,
            durationSeconds: 100,
            originalID: "o1",
            isAIWorkout: true
        )
        #expect(item1 == item1Copy)
        #expect(item1.hashValue == item1Copy.hashValue)

        // Different fields means not equal (synthesized Hashable uses all fields)
        let item2 = HistoryItem(
            id: "same-id",
            title: "B",
            source: .program(name: "X"),
            completedAt: now,
            exerciseCount: 2,
            durationSeconds: 200,
            originalID: "o2",
            isAIWorkout: false
        )
        #expect(item1 != item2)
    }
}

// MARK: - HistoryFilter Tests

@Suite("HistoryFilter")
@MainActor
struct HistoryFilterTests {

    private func makeItems() -> [HistoryItem] {
        [
            HistoryItem(id: "ai-1", title: "Strength", source: .aiWorkout, completedAt: .now, exerciseCount: 5, durationSeconds: 2700, originalID: "1", isAIWorkout: true),
            HistoryItem(id: "ai-2", title: "Cardio", source: .aiWorkout, completedAt: .now, exerciseCount: 3, durationSeconds: 1800, originalID: "2", isAIWorkout: true),
            HistoryItem(id: "prog-1", title: "Week 1, Day 1", source: .program(name: "Builder"), completedAt: .now, exerciseCount: 0, durationSeconds: 3600, originalID: "3", isAIWorkout: false),
        ]
    }

    @Test func filterAll() {
        let result = UnifiedHistoryViewModel.applyFilter(makeItems(), filter: .all)
        #expect(result.count == 3)
    }

    @Test func filterAI() {
        let result = UnifiedHistoryViewModel.applyFilter(makeItems(), filter: .ai)
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.source == .aiWorkout })
    }

    @Test func filterProgram() {
        let result = UnifiedHistoryViewModel.applyFilter(makeItems(), filter: .program)
        #expect(result.count == 1)
        #expect(result.first?.id == "prog-1")
    }

    @Test func filterEmptyList() {
        let result = UnifiedHistoryViewModel.applyFilter([], filter: .ai)
        #expect(result.isEmpty)
    }

    @Test func allCases() {
        #expect(HistoryFilter.allCases.count == 3)
        #expect(HistoryFilter.all.rawValue == "All")
        #expect(HistoryFilter.ai.rawValue == "AI")
        #expect(HistoryFilter.program.rawValue == "Program")
    }
}

// MARK: - ProgramListViewModel.filterPrograms Tests

@Suite("ProgramListViewModel filterPrograms")
@MainActor
struct ProgramFilterTests {

    private func makeProgram(id: String, name: String, category: String) -> Program {
        Program(
            id: id,
            name: name,
            category: category,
            description: "",
            durationWeeks: 4,
            sessionsPerWeek: 3,
            difficulty: "beginner",
            phases: [],
            cycleAdjustmentProfile: nil,
            weeks: []
        )
    }

    @Test func emptySearchReturnsAll() {
        let programs = [
            makeProgram(id: "1", name: "Strength Builder", category: "Strength"),
            makeProgram(id: "2", name: "Cardio Blast", category: "Conditioning"),
        ]
        let result = ProgramListViewModel.filterPrograms(programs, searchText: "")
        #expect(result.count == 2)
    }

    @Test func filterByName() {
        let programs = [
            makeProgram(id: "1", name: "Strength Builder", category: "Strength"),
            makeProgram(id: "2", name: "Cardio Blast", category: "Conditioning"),
        ]
        let result = ProgramListViewModel.filterPrograms(programs, searchText: "strength")
        #expect(result.count == 1)
        #expect(result.first?.id == "1")
    }

    @Test func filterByCategory() {
        let programs = [
            makeProgram(id: "1", name: "Strength Builder", category: "Strength"),
            makeProgram(id: "2", name: "Cardio Blast", category: "Conditioning"),
        ]
        let result = ProgramListViewModel.filterPrograms(programs, searchText: "conditioning")
        #expect(result.count == 1)
        #expect(result.first?.id == "2")
    }

    @Test func filterCaseInsensitive() {
        let programs = [
            makeProgram(id: "1", name: "Strength Builder", category: "Strength"),
        ]
        let result = ProgramListViewModel.filterPrograms(programs, searchText: "STRENGTH")
        #expect(result.count == 1)
    }

    @Test func filterNoMatch() {
        let programs = [
            makeProgram(id: "1", name: "Strength Builder", category: "Strength"),
        ]
        let result = ProgramListViewModel.filterPrograms(programs, searchText: "yoga")
        #expect(result.isEmpty)
    }
}

// MARK: - UnifiedHistoryView Static Helpers

@Suite("UnifiedHistoryView Statics")
@MainActor
struct UnifiedHistoryViewStaticTests {

    @Test func durationLabelMinutes() {
        #expect(UnifiedHistoryView.durationLabel(3600) == "60 min")
        #expect(UnifiedHistoryView.durationLabel(2700) == "45 min")
        #expect(UnifiedHistoryView.durationLabel(1800) == "30 min")
        #expect(UnifiedHistoryView.durationLabel(0) == "0 min")
    }

    @Test func dateLabelNotEmpty() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let label = UnifiedHistoryView.dateLabel(date)
        #expect(!label.isEmpty)
    }
}

// MARK: - HistoryItemSource Hashable

@Suite("HistoryItemSource")
struct HistoryItemSourceTests {

    @Test func aiWorkoutEquality() {
        #expect(HistoryItemSource.aiWorkout == HistoryItemSource.aiWorkout)
    }

    @Test func programEquality() {
        #expect(HistoryItemSource.program(name: "A") == HistoryItemSource.program(name: "A"))
        #expect(HistoryItemSource.program(name: "A") != HistoryItemSource.program(name: "B"))
    }

    @Test func crossTypeInequality() {
        #expect(HistoryItemSource.aiWorkout != HistoryItemSource.program(name: "X"))
    }
}
