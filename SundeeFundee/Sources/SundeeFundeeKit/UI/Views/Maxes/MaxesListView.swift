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
                    .accessibilityLabel("Add One-Rep Max")
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add One-Rep Max")
                }
                #endif
            }
            .task {
                await viewModel.loadMaxes()
            }
            .refreshable {
                await viewModel.loadMaxes()
            }
            .onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { _ in
                Task { await viewModel.loadMaxes() }
            }
            .sheet(isPresented: $viewModel.showingEntry) {
                OneRepMaxEntryView(onSave: { name, weight, unit in
                    await viewModel.saveMax(exerciseName: name, weight: weight, unit: unit)
                })
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "scalemass")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Accent.gold.opacity(0.5))
                .accessibilityHidden(true)

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
            .accessibilityHint("Record your first one-rep max lift")
        }
        .padding(AppTheme.Spacing.xxl)
    }

    // MARK: - Maxes List

    private var maxesList: some View {
        List {
            ForEach(viewModel.maxes) { max in
                MaxesListRow(
                    max: max,
                    plateau: viewModel.plateauAlerts[max.exerciseName]
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let max = viewModel.maxes[index]
                    Task { await viewModel.deleteMax(id: max.id) }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - MaxesListRow

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
private struct MaxesListRow: View {
    let max: OneRepMaxItem
    let plateau: PlateauDetector.PlateauAlert?

    @State private var showingPlateauDetail = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(max.exerciseName)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                Text(max.date, style: .date)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }

            if plateau != nil {
                Button {
                    showingPlateauDetail = true
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.Text.orange)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Plateau detected on \(max.exerciseName)")
                .accessibilityHint("Tap to view recommendation")
                #if os(iOS)
                .popover(isPresented: $showingPlateauDetail, arrowEdge: .top) {
                    plateauPopover
                }
                #endif
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(max.exerciseName), \(Int(max.weight)) \(max.unit.rawValue)\(plateau != nil ? ", plateaued" : "")")
    }

    @ViewBuilder
    private var plateauPopover: some View {
        if let p = plateau {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.Text.orange)
                    Text("Plateau detected")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)
                }
                Text(p.recommendation)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(p.stallCount) attempts, \(p.daysSinceBest) days since best")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Text.secondary)
            }
            .padding(AppTheme.Spacing.lg)
            .frame(minWidth: 260, maxWidth: 320)
            .presentationCompactAdaptation(.popover)
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
    @State private var isCustom: Bool = false
    @State private var weight: String = ""
    @State private var unit: WeightUnit = .lbs
    @State private var isSaving: Bool = false

    let onSave: (String, Double, WeightUnit) async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ExerciseCatalogMenu(selectedName: $exerciseName, isCustom: $isCustom)
                    if isCustom {
                        TextField("Custom Exercise Name", text: $exerciseName)
                    }

                    HStack {
                        TextField("Weight", text: $weight)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif

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
                        save()
                    }
                    .disabled(!canSave)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }
                #endif
            }
        }
    }

    private var canSave: Bool {
        !exerciseName.isEmpty && !weight.isEmpty && Double(weight) != nil && !isSaving
    }

    private func save() {
        guard let weightValue = Double(weight) else { return }
        isSaving = true
        Task {
            await onSave(exerciseName, weightValue, unit)
            dismiss()
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
    @Published var errorMessage: String?
    @Published var preferredUnit: WeightUnit = .lbs
    @Published var plateauAlerts: [String: PlateauDetector.PlateauAlert] = [:]

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    func saveMax(exerciseName: String, weight: Double, unit: WeightUnit) async {
        let record = OneRepMaxRecord(
            id: UUID().uuidString,
            exerciseName: exerciseName,
            weight: weight,
            unit: unit,
            date: Date()
        )

        do {
            try await dataClient.save(record, recordType: "OneRepMaxRecord")
            await loadMaxes()
        } catch {
            errorMessage = "Failed to save max: \(error.localizedDescription)"
        }
    }

    func loadMaxes() async {
        isLoading = true

        do {
            // Load user's preferred unit from settings
            let settings = try? await dataClient.fetchAll(
                recordType: "UserSettings"
            ) as [UserSettingsRecord]
            if let unit = settings?.first.flatMap({ WeightUnit(rawValue: $0.weightUnit) }) {
                preferredUnit = unit
            }

            let records = try await dataClient.fetchAll(
                recordType: "OneRepMaxRecord"
            ) as [OneRepMaxRecord]

            let alerts = PlateauDetector.detect(from: records)
            plateauAlerts = Dictionary(uniqueKeysWithValues: alerts.map { ($0.exerciseName, $0) })

            maxes = records.map { record in
                let displayWeight: Double
                if record.unit == preferredUnit {
                    displayWeight = record.weight
                } else if record.unit == .lbs {
                    displayWeight = lbsToKg(record.weight)
                } else {
                    displayWeight = kgToLbs(record.weight)
                }
                return OneRepMaxItem(
                    id: record.id,
                    exerciseName: record.exerciseName,
                    weight: displayWeight,
                    unit: preferredUnit,
                    date: record.date
                )
            }
        } catch {
            errorMessage = "Failed to load maxes: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func deleteMax(id: String) async {
        do {
            try await dataClient.delete(recordType: "OneRepMaxRecord", id: id)
            maxes.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete max: \(error.localizedDescription)"
        }
    }
}
