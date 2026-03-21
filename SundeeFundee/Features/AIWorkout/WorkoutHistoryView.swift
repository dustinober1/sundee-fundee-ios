import SwiftUI

struct WorkoutHistoryView: View {
    @State var workouts: [GeneratedWorkout] = []
    @State private var isLoading = false
    @State private var selectedFocus: WorkoutFocus?
    @State private var selectedWorkout: GeneratedWorkout?
    @State private var workoutToStart: GeneratedWorkout?
    let userID: String
    let aiService: any AIWorkoutServiceProtocol
    let weightUnit: WeightUnit
    let barbellWeightKg: Double
    var onSelectWorkout: (GeneratedWorkout) -> Void = { _ in }

    init(
        userID: String,
        aiService: any AIWorkoutServiceProtocol,
        weightUnit: WeightUnit = .pounds,
        barbellWeightKg: Double = PlateCalculation.standardBarKg,
        onSelectWorkout: @escaping (GeneratedWorkout) -> Void = { _ in }
    ) {
        self.userID = userID
        self.aiService = aiService
        self.weightUnit = weightUnit
        self.barbellWeightKg = barbellWeightKg
        self.onSelectWorkout = onSelectWorkout
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if filteredWorkouts.isEmpty {
                ContentUnavailableView(
                    "No Workouts Yet",
                    systemImage: "dumbbell",
                    description: Text("Generate your first AI workout to see it here.")
                )
            } else {
                workoutList
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadHistory() }
        .refreshable { await loadHistory() }
        .navigationDestination(item: $selectedWorkout) { workout in
            WorkoutPreviewView(
                viewModel: WorkoutPreviewViewModel(workout: workout, aiService: aiService),
                userID: userID,
                weightUnit: weightUnit,
                onStartWorkout: { started in
                    workoutToStart = started
                },
                onRegenerate: {
                    selectedWorkout = nil
                }
            )
        }
        .navigationDestination(item: $workoutToStart) { workout in
            WorkoutExecutionView(
                viewModel: WorkoutExecutionViewModel(
                    generatedWorkout: workout,
                    barbellWeightKg: barbellWeightKg,
                    weightUnit: weightUnit
                )
            )
        }
    }

    private var filteredWorkouts: [GeneratedWorkout] {
        Self.filterWorkouts(workouts, focus: selectedFocus)
    }

    static func filterWorkouts(_ workouts: [GeneratedWorkout], focus: WorkoutFocus?) -> [GeneratedWorkout] {
        guard let focus else { return workouts }
        return workouts.filter { $0.questionnaire.focus == focus }
    }

    private var workoutList: some View {
        VStack(spacing: 0) {
            focusFilter
            List(filteredWorkouts) { workout in
                Button {
                    onSelectWorkout(workout)
                    selectedWorkout = workout
                } label: {
                    historyRow(workout)
                }
                .listRowBackground(AppTheme.Colors.cream)
            }
            .listStyle(.plain)
        }
    }

    private var focusFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                filterChip(title: "All", isSelected: selectedFocus == nil) {
                    selectedFocus = nil
                }
                ForEach(WorkoutFocus.allCases, id: \.self) { focus in
                    filterChip(title: focus.displayName, isSelected: selectedFocus == focus) {
                        selectedFocus = focus
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Fonts.caption)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(isSelected ? AppTheme.Colors.accentOrange : AppTheme.Colors.cardBackground)
                .foregroundStyle(isSelected ? .white : AppTheme.Colors.textPrimary)
                .cornerRadius(AppTheme.CornerRadius.button)
        }
    }

    private func historyRow(_ workout: GeneratedWorkout) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Text(workout.questionnaire.focus.displayName)
                        .font(AppTheme.Fonts.body)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.Colors.navy)
                    if workout.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.Colors.warmRose)
                    }
                    if workout.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.Colors.accentOrange)
                    }
                }
                Text(Self.dateLabel(workout.createdAt))
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(workout.exercises.count) exercises")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                Text(Self.durationLabel(workout.questionnaire.timeMinutes))
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
    }

    static func durationLabel(_ minutes: Int) -> String {
        "\(minutes) min"
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

    private func loadHistory() async {
        isLoading = true
        workouts = (try? await aiService.fetchHistory(userID: userID)) ?? []
        isLoading = false
    }
}

// MARK: - Favorites View

struct FavoritesView: View {
    @State var favorites: [GeneratedWorkout] = []
    @State private var isLoading = false
    let userID: String
    let aiService: any AIWorkoutServiceProtocol
    var onSelectWorkout: (GeneratedWorkout) -> Void = { _ in }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if favorites.isEmpty {
                ContentUnavailableView(
                    "No Favorites",
                    systemImage: "heart",
                    description: Text("Tap the heart icon on a workout to save it here.")
                )
            } else {
                List(favorites) { workout in
                    Button { onSelectWorkout(workout) } label: {
                        favoriteRow(workout)
                    }
                    .listRowBackground(AppTheme.Colors.cream)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadFavorites() }
    }

    private func favoriteRow(_ workout: GeneratedWorkout) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.questionnaire.focus.displayName)
                    .font(AppTheme.Fonts.body)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.Colors.navy)
                Text("\(workout.exercises.count) exercises")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Spacer()
            Image(systemName: "heart.fill")
                .foregroundStyle(AppTheme.Colors.warmRose)
        }
    }

    private func loadFavorites() async {
        isLoading = true
        favorites = (try? await aiService.fetchFavorites(userID: userID)) ?? []
        isLoading = false
    }
}
