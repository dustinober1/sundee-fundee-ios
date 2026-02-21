import SwiftUI
import SwiftData

struct ProgramsListView: View {
    @State private var programs: [ProgramV2] = []
    @State private var selectedCategory: String?
    @State private var searchText = ""
    @State private var showCustomBuilder = false
    @State private var isLoadingPublic = false
    @State private var featuredIds: Set<String> = []

    @Query(sort: \CustomProgram.createdAt, order: .reverse)
    private var customPrograms: [CustomProgram]

    private let repository = ProgramRepository.shared

    var body: some View {
        NavigationStack {
            List {
                if !allCategories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(allCategories, id: \.self) { category in
                                CategoryChip(
                                    title: category == "custom" ? "Custom" : category.replacingOccurrences(of: "-", with: " ").capitalized,
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

                // Custom programs
                if selectedCategory == nil || selectedCategory == "custom" {
                    if !filteredCustomPrograms.isEmpty {
                        Section("My Workouts") {
                            ForEach(filteredCustomPrograms) { program in
                                CustomProgramRow(program: program)
                            }
                        }
                    }
                }

                // Predefined programs
                if selectedCategory != "custom" {
                    let sectionHeader = filteredCustomPrograms.isEmpty ? "" : "Programs"
                    Section(sectionHeader) {
                        ForEach(filteredPrograms) { program in
                            NavigationLink(destination: ProgramDetailView(program: program)) {
                                ProgramRow(program: program, isFeatured: featuredIds.contains(program.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Programs")
            .searchable(text: $searchText, prompt: "Search programs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCustomBuilder = true
                    } label: {
                        Label("Create Workout", systemImage: "plus")
                    }
                }
            }
            .onAppear { programs = repository.loadAll() }
            .task {
                isLoadingPublic = true
                await repository.loadPublicPrograms()
                programs = repository.loadAll()
                featuredIds = repository.publicProgramIds()
                isLoadingPublic = false
            }
            .sheet(isPresented: $showCustomBuilder) {
                CustomWorkoutBuilderView()
            }
            .overlay {
                if isLoadingPublic && programs.isEmpty {
                    ProgressView("Loading programs…")
                }
            }
        }
    }

    private var allCategories: [String] {
        var cats = repository.categories()
        if !customPrograms.isEmpty { cats.append("custom") }
        return cats
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

    private var filteredCustomPrograms: [CustomProgram] {
        if !searchText.isEmpty {
            return customPrograms.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return customPrograms
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
    var isFeatured: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(program.name)
                    .font(.headline)
                if isFeatured {
                    Spacer()
                    Label("Featured", systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

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

// MARK: - Custom Program Row

private struct CustomProgramRow: View {
    let program: CustomProgram

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(program.name)
                    .font(.headline)
                Spacer()
                Label("Custom", systemImage: "pencil.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
            }

            if let notes = program.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            let count = program.exercises?.count ?? 0
            Text("\(count) exercise\(count == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
