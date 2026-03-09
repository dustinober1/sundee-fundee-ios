# Unified History + Programs Tab + Delete Capabilities — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Programs tab to tab bar, unify History tab to show all completed workouts (AI + program), and add swipe/bulk delete for history and enrolled programs.

**Architecture:** Extend existing `MainTabView` tabs, create a new `UnifiedHistoryViewModel` that queries both `GeneratedWorkoutRecord` and `CompletedWorkout` from SwiftData, present them via a common `HistoryItem` enum. Add delete capabilities via `AIWorkoutServiceProtocol` extension and existing `WorkoutRepository.deleteWorkoutWithSets`. Programs tab just needs to be added to `orderedTabs` with search and delete on enrollments.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, @Observable ViewModel pattern

---

### Task 1: Add Programs tab to the tab bar

**Files:**
- Modify: `SundeeFundee/Features/Shell/MainTabView.swift:45`

**Step 1: Add `.programs` to `orderedTabs`**

In `MainTabView.orderedTabs(for:)`, add `.programs` between `.dashboard` and `.history`:

```swift
static func orderedTabs(for gender: Gender?) -> [TabRoute] {
    var tabs: [TabRoute] = [.dashboard, .programs, .history, .maxes, .benchmarks]
    if gender != .male {
        tabs.append(.cycle)
    }
    tabs.append(.settings)
    return tabs
}
```

**Step 2: Build and verify in simulator**

Run:
```bash
xcodebuild build -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
Expected: Programs tab appears between Dashboard and History.

**Step 3: Update test for `orderedTabs`**

Find existing tests for `orderedTabs` and add `.programs` to expected arrays.

**Step 4: Run tests**

```bash
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests
```

**Step 5: Commit**

```bash
git add SundeeFundee/Features/Shell/MainTabView.swift
git commit -m "feat: add Programs tab to main tab bar"
```

---

### Task 2: Add delete method to `AIWorkoutServiceProtocol` and implementation

**Files:**
- Modify: `SundeeFundee/Repositories/Protocols/RepositoryProtocols.swift:154-159`
- Modify: `SundeeFundee/Repositories/Firebase/FirebaseAIWorkoutService.swift`

**Step 1: Add `deleteWorkout` to protocol**

```swift
protocol AIWorkoutServiceProtocol: Sendable {
    func generateWorkout(context: WorkoutGenerationContext) async throws -> GeneratedWorkout
    func fetchHistory(userID: String) async throws -> [GeneratedWorkout]
    func toggleFavorite(workoutID: String, isFavorite: Bool) async throws
    func fetchFavorites(userID: String) async throws -> [GeneratedWorkout]
    func deleteWorkout(workoutID: String) async throws
}
```

**Step 2: Implement in `SwiftDataAIWorkoutService`**

```swift
func deleteWorkout(workoutID: String) async throws {
    let descriptor = FetchDescriptor<GeneratedWorkoutRecord>(
        predicate: #Predicate { $0.id == workoutID }
    )
    guard let record = try? modelContext.fetch(descriptor).first else { return }
    modelContext.delete(record)
    try? modelContext.save()
}
```

**Step 3: Update `MockAIWorkoutService` in tests**

Add `func deleteWorkout(workoutID: String) async throws {}` to all mock/fake implementations found in test files.

**Step 4: Build and run tests**

**Step 5: Commit**

```bash
git commit -m "feat: add deleteWorkout to AIWorkoutServiceProtocol"
```

---

### Task 3: Create `HistoryItem` domain type and `UnifiedHistoryViewModel`

**Files:**
- Create: `SundeeFundee/Domain/History/HistoryItem.swift`
- Create: `SundeeFundee/Features/AIWorkout/UnifiedHistoryViewModel.swift`

**Step 1: Create `HistoryItem` enum**

```swift
import Foundation

enum HistoryItemSource: Hashable {
    case aiWorkout
    case program(name: String)
}

struct HistoryItem: Identifiable, Hashable {
    let id: String
    let title: String
    let source: HistoryItemSource
    let completedAt: Date
    let exerciseCount: Int
    let durationSeconds: Int
    let isCompleted: Bool

    // For navigation — one of these will be non-nil
    let generatedWorkout: GeneratedWorkout?
    let completedWorkout: CompletedWorkout?

    var sourceLabel: String {
        switch source {
        case .aiWorkout: return "AI Workout"
        case .program(let name): return name
        }
    }

    // Hashable conformance excluding non-Hashable stored properties
    static func == (lhs: HistoryItem, rhs: HistoryItem) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

**Step 2: Create `UnifiedHistoryViewModel`**

```swift
import Foundation
import SwiftData

enum HistoryFilter: String, CaseIterable {
    case all = "All"
    case ai = "AI"
    case program = "Program"
}

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

        // Fetch AI workouts
        let aiWorkouts = (try? await aiService.fetchHistory(userID: userID)) ?? []
        let aiItems = aiWorkouts.filter { $0.isCompleted }.map { workout in
            HistoryItem(
                id: "ai-\(workout.id)",
                title: workout.questionnaire.focus.displayName,
                source: .aiWorkout,
                completedAt: workout.createdAt,
                exerciseCount: workout.exercises.count,
                durationSeconds: workout.questionnaire.timeMinutes * 60,
                isCompleted: true,
                generatedWorkout: workout,
                completedWorkout: nil
            )
        }
        allItems.append(contentsOf: aiItems)

        // Fetch program workouts
        let completedWorkouts = (try? workoutRepo.fetchWorkouts()) ?? []
        let programs = (try? await programRepo.fetchPrograms()) ?? []
        let programMap = Dictionary(uniqueKeysWithValues: programs.map { ($0.id, $0.name) })

        let programItems = completedWorkouts.map { workout in
            HistoryItem(
                id: "prog-\(workout.id)",
                title: "Week \(workout.week), Day \(workout.day)",
                source: .program(name: programMap[workout.programID] ?? "Program"),
                completedAt: workout.completedAt,
                exerciseCount: 0,
                durationSeconds: workout.durationSeconds,
                isCompleted: true,
                generatedWorkout: nil,
                completedWorkout: workout
            )
        }
        allItems.append(contentsOf: programItems)

        // Sort chronologically, newest first
        items = allItems.sorted { $0.completedAt > $1.completedAt }
    }

    func deleteItem(_ item: HistoryItem) async {
        if let workout = item.generatedWorkout {
            try? await aiService.deleteWorkout(workoutID: workout.id)
        } else if let completed = item.completedWorkout {
            try? workoutRepo.deleteWorkoutWithSets(completed)
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
```

**Step 3: Add files to project.yml if needed (XcodeGen auto-discovers from Sources)**

**Step 4: Build**

**Step 5: Commit**

```bash
git commit -m "feat: add HistoryItem domain type and UnifiedHistoryViewModel"
```

---

### Task 4: Replace `WorkoutHistoryView` body with unified history UI

**Files:**
- Modify: `SundeeFundee/Features/AIWorkout/WorkoutHistoryView.swift`
- Modify: `SundeeFundee/Features/Shell/MainTabView.swift` (update `HistoryTabView`)

**Step 1: Rewrite `HistoryTabView` to create `UnifiedHistoryViewModel`**

Update `HistoryTabView` in `MainTabView.swift` to instantiate the new view model with both repos:

```swift
struct HistoryTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    private var currentUser: User? { users.first }

    var body: some View {
        UnifiedHistoryView(
            viewModel: UnifiedHistoryViewModel(
                userID: currentUser?.id ?? "",
                aiService: SwiftDataAIWorkoutService(
                    modelContext: modelContext,
                    sharedRepository: FileManager.default.ubiquityIdentityToken != nil
                        ? CloudKitSharedWorkoutRepository(modelContext: modelContext)
                        : nil
                ),
                workoutRepo: SwiftDataWorkoutRepository(context: modelContext),
                programRepo: CloudKitProgramRepository()
            )
        )
    }
}
```

**Step 2: Create `UnifiedHistoryView`**

Create `SundeeFundee/Features/AIWorkout/UnifiedHistoryView.swift` with:
- Source filter chips (All / AI / Program)
- Chronological list of `HistoryItem`
- Each row shows: title, source label tag, date, duration
- Swipe-to-delete with confirmation
- Edit mode toolbar button for bulk selection + delete
- Pull-to-refresh

```swift
import SwiftUI

struct UnifiedHistoryView: View {
    @State var viewModel: UnifiedHistoryViewModel
    @State private var itemToDelete: HistoryItem?

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView().tint(AppTheme.Colors.accentOrange)
            } else if viewModel.filteredItems.isEmpty {
                ContentUnavailableView(
                    "No Workouts Yet",
                    systemImage: "dumbbell",
                    description: Text("Complete a workout to see it here.")
                )
            } else {
                VStack(spacing: 0) {
                    sourceFilter
                    workoutList
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(viewModel.isEditing ? "Done" : "Edit") {
                    viewModel.isEditing.toggle()
                    if !viewModel.isEditing {
                        viewModel.selectedItems.removeAll()
                    }
                }
                .disabled(viewModel.filteredItems.isEmpty)
            }
            if viewModel.isEditing && !viewModel.selectedItems.isEmpty {
                ToolbarItem(placement: .bottomBar) {
                    Button("Delete \(viewModel.selectedItems.count) Selected", role: .destructive) {
                        viewModel.showDeleteConfirmation = true
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert("Delete Workouts?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteSelected() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(viewModel.selectedItems.count) workout(s).")
        }
        .alert("Delete Workout?", isPresented: .init(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    Task { await viewModel.deleteItem(item) }
                }
                itemToDelete = nil
            }
            Button("Cancel", role: .cancel) { itemToDelete = nil }
        } message: {
            Text("This will permanently delete this workout.")
        }
    }

    private var sourceFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(HistoryFilter.allCases, id: \.self) { filter in
                    Button {
                        viewModel.selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(AppTheme.Fonts.caption)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(viewModel.selectedFilter == filter
                                ? AppTheme.Colors.accentOrange
                                : AppTheme.Colors.cardBackground)
                            .foregroundStyle(viewModel.selectedFilter == filter
                                ? .white
                                : AppTheme.Colors.textPrimary)
                            .cornerRadius(AppTheme.CornerRadius.button)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
        }
    }

    private var workoutList: some View {
        List(viewModel.filteredItems, selection: viewModel.isEditing ? $viewModel.selectedItems : nil) { item in
            historyRow(item)
                .listRowBackground(AppTheme.Colors.cream)
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        itemToDelete = item
                    }
                }
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(viewModel.isEditing ? .active : .inactive))
    }

    private func historyRow(_ item: HistoryItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(AppTheme.Fonts.body)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.Colors.navy)
                HStack(spacing: AppTheme.Spacing.xs) {
                    Text(item.sourceLabel)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.source == .aiWorkout
                            ? AppTheme.Colors.accentOrange.opacity(0.15)
                            : AppTheme.Colors.navy.opacity(0.1))
                        .foregroundStyle(item.source == .aiWorkout
                            ? AppTheme.Colors.accentOrange
                            : AppTheme.Colors.navy)
                        .cornerRadius(4)
                    Text(Self.dateLabel(item.completedAt))
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            Spacer()
            Text(Self.durationLabel(item.durationSeconds))
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }

    static func durationLabel(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes) min"
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    static func dateLabel(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}
```

**Step 3: Build and verify**

**Step 4: Commit**

```bash
git commit -m "feat: replace history tab with unified workout history view"
```

---

### Task 5: Add search bar to Programs tab

**Files:**
- Modify: `SundeeFundee/Features/Programs/ProgramListView.swift`
- Modify: `SundeeFundee/Features/Programs/ProgramListViewModel.swift`

**Step 1: Add `searchText` to `ProgramListViewModel`**

```swift
var searchText: String = ""

var filteredPrograms: [Program] {
    Self.filterPrograms(programs, searchText: searchText)
}

static func filterPrograms(_ programs: [Program], searchText: String) -> [Program] {
    guard !searchText.isEmpty else { return programs }
    let query = searchText.lowercased()
    return programs.filter {
        $0.name.lowercased().contains(query) ||
        $0.category.lowercased().contains(query)
    }
}
```

**Step 2: Add `.searchable` modifier and use `filteredPrograms` in `ProgramListView`**

Replace `viewModel.programs` with `viewModel.filteredPrograms` in the `ForEach`, and add:

```swift
.searchable(text: $viewModel.searchText, prompt: "Search programs")
```

**Step 3: Build and test**

**Step 4: Commit**

```bash
git commit -m "feat: add search bar to Programs tab"
```

---

### Task 6: Add swipe-to-delete and edit mode for enrolled programs

**Files:**
- Modify: `SundeeFundee/Features/Programs/ProgramListView.swift`
- Modify: `SundeeFundee/Features/Programs/ProgramListViewModel.swift`

**Step 1: Add enrollment management to ViewModel**

Add to `ProgramListViewModel`:

```swift
var enrollments: [EnrolledProgram] = []

func loadEnrollments(modelContext: ModelContext) {
    let repo = SwiftDataEnrolledProgramRepository(context: modelContext)
    enrollmentRepo = repo
    enrollments = (try? repo.fetchAllEnrollments()) ?? []
    activeEnrollment = try? repo.fetchActiveEnrollment()
}

func removeEnrollment(_ enrollment: EnrolledProgram, modelContext: ModelContext) {
    let repo = SwiftDataEnrolledProgramRepository(context: modelContext)
    try? repo.delete(enrollment)
    enrollments.removeAll { $0.id == enrollment.id }
    if activeEnrollment?.id == enrollment.id {
        activeEnrollment = nil
    }
}
```

**Step 2: Show "My Programs" section in ProgramListView**

Add a section at the top of the ScrollView showing enrolled programs with swipe-to-delete. Each enrolled program card shows the program name, enrollment date, and status. Swipe triggers `removeEnrollment`.

**Step 3: Build and test**

**Step 4: Commit**

```bash
git commit -m "feat: add swipe-to-delete for enrolled programs"
```

---

### Task 7: Write tests for new functionality

**Files:**
- Modify or create test files for: `UnifiedHistoryViewModel`, `HistoryItem`, `ProgramListViewModel` search, tab ordering

**Step 1: Test `HistoryItem` source label**

```swift
func testSourceLabel_aiWorkout() {
    let item = HistoryItem(id: "1", title: "Strength", source: .aiWorkout, completedAt: .now, exerciseCount: 5, durationSeconds: 3600, isCompleted: true, generatedWorkout: nil, completedWorkout: nil)
    XCTAssertEqual(item.sourceLabel, "AI Workout")
}
```

**Step 2: Test `UnifiedHistoryViewModel.applyFilter`**

Test all three filter cases with mixed items.

**Step 3: Test `ProgramListViewModel.filterPrograms`**

Test search by name and category, case insensitivity, empty search returns all.

**Step 4: Test `UnifiedHistoryView.durationLabel` and `dateLabel`**

**Step 5: Test updated `orderedTabs` includes `.programs`**

**Step 6: Run all tests**

```bash
xcodebuild test -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:SundeeFundeTests
```

**Step 7: Commit**

```bash
git commit -m "test: add coverage for unified history, program search, and tab ordering"
```

---

### Task 8: Fix any remaining test failures and ensure 100% coverage

**Files:** Various test files as needed

**Step 1: Run full test suite and check coverage**

**Step 2: Add missing coverage for any new public methods/types**

**Step 3: Final commit**

```bash
git commit -m "test: ensure 100% line coverage for new features"
```
