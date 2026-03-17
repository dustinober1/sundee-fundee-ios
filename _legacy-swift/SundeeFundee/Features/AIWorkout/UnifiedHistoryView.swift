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
