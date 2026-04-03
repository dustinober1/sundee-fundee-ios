import SwiftUI

// MARK: - MaxesListView
//
// One-rep max tracking and history.
// Matches the web app's maxes feature.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct MaxesListView: View {
    @StateObject private var viewModel = MaxesListViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.maxes.isEmpty {
                    ProgressView("Loading maxes...")
                } else if viewModel.maxes.isEmpty {
                    emptyState
                } else {
                    maxesList
                }
            }
            .navigationTitle("One-Rep Maxes")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #endif
            }
            .task {
                await viewModel.loadMaxes()
            }
            .refreshable {
                await viewModel.loadMaxes()
            }
            .sheet(isPresented: $viewModel.showingEntry) {
                OneRepMaxEntryView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "scalemass")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Accent.gold.opacity(0.5))

            Text("No Maxes Yet")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            Text("Track your one-rep maxes to calculate prescribed weights")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)

            Button("Log Your First Max") {
                viewModel.showingEntry = true
            }
            .artDecoButton(style: .primary)
        }
        .padding(AppTheme.Spacing.xxl)
    }

    // MARK: - Maxes List

    private var maxesList: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(viewModel.maxes) { max in
                    MaxRow(max: max)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
    }
}

// MARK: - MaxRow

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct MaxRow: View {
    let max: OneRepMaxItem

    var body: some View {
        ArtDecoCard {
            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(max.exerciseName)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Text(max.date, style: .date)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                    Text("\(max.weight, specifier: "%.0f")")
                        .font(AppTheme.Typography.displayMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Text(max.unit.rawValue)
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Text.secondary)
                }
            }
        }
    }
}

// MARK: - OneRepMaxItem

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct OneRepMaxItem: Identifiable {
    let id: String
    let exerciseName: String
    let weight: Double
    let unit: WeightUnit
    let date: Date
}

// MARK: - OneRepMaxEntryView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct OneRepMaxEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exerciseName: String = ""
    @State private var weight: String = ""
    @State private var unit: WeightUnit = .lbs

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exercise Name", text: $exerciseName)

                    HStack {
                        TextField("Weight", text: $weight)

                        Picker(selection: $unit, label: Text("Unit")) {
                            Text("lbs").tag(WeightUnit.lbs)
                            Text("kg").tag(WeightUnit.kg)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("Log Max")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save the max
                        dismiss()
                    }
                    .disabled(exerciseName.isEmpty || weight.isEmpty)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Save the max
                        dismiss()
                    }
                    .disabled(exerciseName.isEmpty || weight.isEmpty)
                }
                #endif
            }
        }
    }
}

// MARK: - MaxesListViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class MaxesListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var maxes: [OneRepMaxItem] = []
    @Published var showingEntry: Bool = false

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = CloudKitClient(containerIdentifier: "icloud.com.sundeefundee.app")) {
        self.dataClient = dataClient
    }

    func loadMaxes() async {
        isLoading = true

        do {
            let records = try await dataClient.fetchAll(
                recordType: "OneRepMaxRecord"
            ) as [OneRepMaxRecord]

            maxes = records.map { record in
                OneRepMaxItem(
                    id: record.id,
                    exerciseName: record.exerciseName,
                    weight: record.weight,
                    unit: record.unit,
                    date: record.date
                )
            }
        } catch {
            print("Error loading maxes: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Model Types (shared in SharedModels.swift)
