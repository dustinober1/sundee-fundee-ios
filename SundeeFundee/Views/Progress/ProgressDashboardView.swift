import SwiftUI
import SwiftData

struct ProgressDashboardView: View {
    @Query(sort: \CompletedWorkout.completedAt, order: .reverse)
    private var workouts: [CompletedWorkout]

    @Query private var personalRecords: [PersonalRecord]

    var body: some View {
        NavigationStack {
            BrandBackgroundView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Workout Frequency
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Workout Activity")
                                .font(.title3)
                                .fontWeight(.semibold)

                            if workouts.isEmpty {
                                Text("Complete workouts to see your activity")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                // Placeholder for heatmap calendar (Phase 8 will implement with Swift Charts)
                                Text("Heatmap calendar — coming in Phase 8")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, minHeight: 120)
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        // Personal Records
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Personal Records")
                                .font(.title3)
                                .fontWeight(.semibold)

                            if personalRecords.isEmpty {
                                Text("PRs will appear here as you train")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(personalRecords, id: \.id) { pr in
                                    HStack {
                                        let name = Exercises.find(byId: pr.exerciseId)?.name ?? pr.exerciseId
                                        Text(name)
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(pr.value, specifier: "%.0f") lbs")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text(pr.date, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        // Volume Trend Placeholder
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Volume Trend")
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text("Charts will be implemented with Swift Charts in Phase 8")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 200)
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Progress")
        }
    }
}

#Preview {
    ProgressDashboardView()
        .modelContainer(for: [CompletedWorkout.self, PersonalRecord.self], inMemory: true)
}
