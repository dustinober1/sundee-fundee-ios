import SwiftUI
import SwiftData
import CloudKit

/// Main benchmarks screen — shows all definitions grouped by category.
struct BenchmarksView: View {
    @State private var viewModel = BenchmarksViewModel(remoteRepo: CloudKitBenchmarkDefinitionRepository())
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var showAddCustom = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.categoryGroups.isEmpty {
                    ContentUnavailableView(
                        "No Benchmarks",
                        systemImage: "checkmark.seal",
                        description: Text("Loading benchmark catalog…")
                    )
                } else {
                    List {
                        ForEach(viewModel.categoryGroups) { group in
                            Section(header: categoryHeader(group.category)) {
                                ForEach(group.definitions, id: \.id) { def in
                                    NavigationLink(destination: BenchmarkDetailView(definition: def)) {
                                        BenchmarkDefinitionRow(definition: def)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        if !def.isPredefined {
                                            Button(role: .destructive) {
                                                viewModel.deleteCustomDefinition(def)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Benchmarks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if FeatureEntitlement.canAccess(feature: .customBenchmarks, tier: appState.subscriptionTier) {
                        showAddCustom = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        if !FeatureEntitlement.canAccess(feature: .customBenchmarks, tier: appState.subscriptionTier) {
                            PremiumBadge(tier: .plus)
                        }
                    }
                }
                .accessibilityLabel("Add custom benchmark")
            }
        }
        .sheet(isPresented: $showAddCustom) {
            AddCustomBenchmarkSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(triggeredBy: .customBenchmarks)
        }
        .onAppear {
            Task { @MainActor in
                await viewModel.load(modelContext: modelContext, userID: appState.currentUserID ?? "")
            }
        }
    }

    private func categoryHeader(_ category: String) -> some View {
        Text(category)
            .font(AppTheme.Fonts.subheading)
            .foregroundStyle(AppTheme.Colors.navy)
            .textCase(nil)
    }
}

// MARK: - BenchmarkDefinitionRow

struct BenchmarkDefinitionRow: View {
    let definition: BenchmarkDefinition

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(definition.name)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                Text(scoringLabel)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
            }
            Spacer()
            if !definition.isPredefined {
                Image(systemName: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.Colors.accentOrange.opacity(0.7))
            }
        }
        .padding(.vertical, 2)
    }

    private var scoringLabel: String {
        switch definition.scoringType {
        case .time:     return "For time"
        case .reps:     return "Max reps / rounds"
        case .weight:   return "Max weight"
        case .distance:      return "For time"
        case .roundsAndReps: return "Rounds + Reps"
        }
    }
}

// MARK: - AddCustomBenchmarkSheet

struct AddCustomBenchmarkSheet: View {
    @Bindable var viewModel: BenchmarksViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = BenchmarkCatalog.generalFitness
    @State private var description = ""
    @State private var scoringType = BenchmarkScoringType.time

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. 500m Row", text: $name)
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(BenchmarkCatalog.categoryOrder, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("Scoring") {
                    Picker("Scoring type", selection: $scoringType) {
                        Text("For time").tag(BenchmarkScoringType.time)
                        Text("Max reps / rounds").tag(BenchmarkScoringType.reps)
                        Text("Max weight").tag(BenchmarkScoringType.weight)
                        Text("Distance (time)").tag(BenchmarkScoringType.distance)
                        Text("Rounds + Reps").tag(BenchmarkScoringType.roundsAndReps)
                    }
                    .pickerStyle(.segmented)
                }
                Section("Description (optional)") {
                    TextField("Movements, reps scheme…", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.cream)
            .navigationTitle("Custom Benchmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addCustomDefinition(
                            name: name.trimmingCharacters(in: .whitespaces),
                            category: category,
                            description: description,
                            scoringType: scoringType
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
