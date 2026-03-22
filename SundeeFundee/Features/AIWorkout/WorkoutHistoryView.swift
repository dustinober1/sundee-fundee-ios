import SwiftUI

struct WorkoutHistoryView: View {
    @State var workouts: [GeneratedWorkout] = []
    @State private var isLoading = false
    @State private var selectedFocus: WorkoutFocus?
    @Environment(AppState.self) private var appState
    let userID: String
    let aiService: any AIWorkoutServiceProtocol
    var onSelectWorkout: (GeneratedWorkout) -> Void = { _ in }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            if !FeatureEntitlement.canAccess(feature: .aiWorkoutHistory, tier: appState.subscriptionTier) {
                VStack(spacing: AppTheme.Spacing.md) {
                    ContentUnavailableView(
                        "AI Workout History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Upgrade to Premium to access your AI workout history and favorites.")
                    )
                    PremiumBadge(tier: .premium)
                }
            } else if isLoading {
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
        .task {
            if FeatureEntitlement.canAccess(feature: .aiWorkoutHistory, tier: appState.subscriptionTier) {
                await loadHistory()
            }
        }
        .refreshable {
            if FeatureEntitlement.canAccess(feature: .aiWorkoutHistory, tier: appState.subscriptionTier) {
                await loadHistory()
            }
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
                Button { onSelectWorkout(workout) } label: {
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
                HStack {
                    Text(workout.questionnaire.focus.displayName)
                        .font(AppTheme.Fonts.body)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.Colors.navy)
                    if workout.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.Colors.warmRose)
                    }
                }
                Text(Self.dateLabel(workout.createdAt))
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Spacer()
            Text("\(workout.exercises.count) exercises")
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
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
