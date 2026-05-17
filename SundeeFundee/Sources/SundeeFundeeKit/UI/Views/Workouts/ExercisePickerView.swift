import SwiftUI

// MARK: - ExercisePickerView
//
// Lets user select exercises from the catalog, grouped by category.
// Selected exercises are passed back via a callback.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var selectedCategory: String? = nil
    @State private var selectedExercises: [String] = []

    let onSelect: ([String]) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Filter
                categoryFilter

                // Exercise List
                List {
                    ForEach(groupedTrainingCategories, id: \.self) { category in
                        let exercises = filteredTraining.filter { $0.categoryLabel == category }
                        if !exercises.isEmpty {
                            Section(category) {
                                ForEach(exercises) { entry in
                                    exerciseRow(entry.id)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search exercises")
            }
            .navigationTitle("Add Exercises")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedExercises.count))") {
                        onSelect(selectedExercises)
                        dismiss()
                    }
                    .disabled(selectedExercises.isEmpty)
                }
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                categoryChip("All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(groupedTrainingCategories, id: \.self) { category in
                    categoryChip(category, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.sm)
        }
        .background(AppTheme.Background.cream.opacity(0.5))
    }

    private func categoryChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(isSelected ? AppTheme.Text.cream : AppTheme.Text.secondary)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(isSelected ? AppTheme.Background.navy : AppTheme.Background.cream.opacity(0.5))
                .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(title)")
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ name: String) -> some View {
        let isSelected = selectedExercises.contains(name)

        return Button {
            if isSelected {
                selectedExercises.removeAll { $0 == name }
            } else {
                selectedExercises.append(name)
            }
        } label: {
            HStack {
                Text(name)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Accent.gold)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(AppTheme.Text.secondary.opacity(0.3))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filtered Data

    private var filteredTraining: [TrainingExerciseDefinition] {
        var results = trainingExerciseCatalog

        if let category = selectedCategory {
            results = results.filter { $0.categoryLabel == category }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            results = results.filter { $0.id.lowercased().contains(query) }
        }

        return results
    }

    private var groupedTrainingCategories: [String] {
        let preferred = ["Squat", "Hip Hinge", "Press", "Pull", "Carry", "Core", "Conditioning", "Olympic Weightlifting"]
        let available = Set(trainingExerciseCatalog.map(\.categoryLabel))
        return preferred.filter { available.contains($0) }
            + available.subtracting(preferred).sorted()
    }
}
