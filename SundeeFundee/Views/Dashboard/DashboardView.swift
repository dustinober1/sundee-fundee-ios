import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<ActiveCycle> { $0.statusRaw == "active" })
    private var activeCycles: [ActiveCycle]

    @Query(sort: \CompletedWorkout.completedAt, order: .reverse)
    private var recentWorkouts: [CompletedWorkout]

    var body: some View {
        NavigationStack {
            BrandBackgroundView {
                ScrollView {
                    VStack(spacing: 20) {
                        if let activeCycle = activeCycles.first {
                            ActiveCycleCard(cycle: activeCycle)
                        } else {
                            EmptyStateCard()
                        }

                        QuickStatsSection(workouts: recentWorkouts)

                        RecentWorkoutsSection(workouts: Array(recentWorkouts.prefix(5)))
                    }
                    .padding()
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

// MARK: - Active Cycle Card

private struct ActiveCycleCard: View {
    let cycle: ActiveCycle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cycle.cycleName)
                        .font(.headline)
                    Text("Week \(cycle.currentWeek)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }

            NavigationLink("Start Workout") {
                // WorkoutSessionView will be wired in Phase 7
                Text("Workout Session — Coming Soon")
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Empty State

private struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)

            Text("No Active Program")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Choose a training program to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Quick Stats

private struct QuickStatsSection: View {
    let workouts: [CompletedWorkout]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)

            HStack(spacing: 16) {
                StatCard(
                    title: "Total",
                    value: "\(workouts.count)",
                    subtitle: "workouts",
                    icon: "checkmark.circle.fill"
                )
                StatCard(
                    title: "This Week",
                    value: "\(workoutsThisWeek)",
                    subtitle: "sessions",
                    icon: "calendar"
                )
            }
        }
    }

    private var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now))!
        return workouts.filter { $0.completedAt >= startOfWeek }.count
    }
}

// MARK: - Recent Workouts

private struct RecentWorkoutsSection: View {
    let workouts: [CompletedWorkout]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)

            if workouts.isEmpty {
                Text("No workouts yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(workouts, id: \.id) { workout in
                    WorkoutRow(workout: workout)
                }
            }
        }
    }
}

private struct WorkoutRow: View {
    let workout: CompletedWorkout

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.sessionId)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Week \(workout.week), Day \(workout.day)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(workout.completedAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [ActiveCycle.self, CompletedWorkout.self], inMemory: true)
}
