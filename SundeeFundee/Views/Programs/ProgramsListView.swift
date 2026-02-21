import SwiftUI

struct ProgramsListView: View {
    @State private var programs: [ProgramV2] = []
    @State private var selectedCategory: String?
    @State private var searchText = ""

    private let repository = ProgramRepository.shared

    var body: some View {
        NavigationStack {
            List {
                if !repository.categories().isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(repository.categories(), id: \.self) { category in
                                CategoryChip(
                                    title: category.replacingOccurrences(of: "-", with: " ").capitalized,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                ForEach(filteredPrograms) { program in
                    NavigationLink(destination: ProgramDetailView(program: program)) {
                        ProgramRow(program: program)
                    }
                }
            }
            .navigationTitle("Programs")
            .searchable(text: $searchText, prompt: "Search programs")
            .onAppear { programs = repository.loadAll() }
        }
    }

    private var filteredPrograms: [ProgramV2] {
        var result = programs
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Program Row

private struct ProgramRow: View {
    let program: ProgramV2

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(program.name)
                .font(.headline)

            Text(program.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 12) {
                Label("\(program.durationWeeks)w", systemImage: "calendar")
                Label("\(program.sessionsPerWeek)x/wk", systemImage: "figure.run")
                Label(program.difficulty.capitalized, systemImage: "chart.bar.fill")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
