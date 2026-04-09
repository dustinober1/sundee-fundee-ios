import SwiftUI

// MARK: - SettingsView
//
// App settings including profile, subscription, cycle tracking, and preferences.
// Matches the web app's settings feature.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingDeleteConfirmation = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    if let userName = authViewModel.userName {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.Accent.gold)

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text(userName)
                                    .font(AppTheme.Typography.headlineMedium)
                                    .foregroundColor(AppTheme.Text.primary)

                                if let email = authViewModel.userEmail {
                                    Text(email)
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Text.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, AppTheme.Spacing.xs)
                    }
                }

                // Health & Tracking Section
                Section("Health & Tracking") {
                    NavigationLink {
                        PainTrackingView()
                    } label: {
                        Label("Pain & Injuries", systemImage: "bandage")
                    }

                    Toggle("Enable Cycle Tracking", isOn: $viewModel.cycleTrackingEnabled)

                    if viewModel.cycleTrackingEnabled {
                        NavigationLink {
                            CycleCalendarView()
                        } label: {
                            Label("Cycle Calendar", systemImage: "calendar")
                        }

                        NavigationLink("Cycle Settings") {
                            CycleSettingsView()
                        }
                    }
                }

                // Preferences Section
                Section("Preferences") {
                    Picker("Weight Unit", selection: $viewModel.weightUnit) {
                        Text("Pounds (lbs)").tag(WeightUnit.lbs)
                        Text("Kilograms (kg)").tag(WeightUnit.kg)
                    }

                    Picker("Experience Level", selection: $viewModel.experienceLevel) {
                        Text("Beginner").tag(ExperienceLevel.beginner)
                        Text("Intermediate").tag(ExperienceLevel.intermediate)
                        Text("Advanced").tag(ExperienceLevel.advanced)
                    }

                    Picker("Primary Goal", selection: $viewModel.primaryGoal) {
                        Text("Strength").tag(PrimaryGoal.strength)
                        Text("Hypertrophy").tag(PrimaryGoal.hypertrophy)
                        Text("Endurance").tag(PrimaryGoal.endurance)
                        Text("Weight Loss").tag(PrimaryGoal.weightLoss)
                    }
                }
                .onChange(of: viewModel.weightUnit) { _, _ in Task { await viewModel.saveSettings() } }
                .onChange(of: viewModel.experienceLevel) { _, _ in Task { await viewModel.saveSettings() } }
                .onChange(of: viewModel.primaryGoal) { _, _ in Task { await viewModel.saveSettings() } }
                .onChange(of: viewModel.cycleTrackingEnabled) { _, _ in Task { await viewModel.saveSettings() } }

                // Data & Privacy Section
                Section("Data & Privacy") {
                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("Export My Data", systemImage: "square.and.arrow.up")
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                    }

                    Link(destination: URL(string: "https://sundeefundee.com")!) {
                        HStack {
                            Text("Website")
                            Spacer()
                            Image(systemName: "link")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Accent.gold)
                        }
                    }

                    Link(destination: URL(string: "https://sundeefundee.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "link")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Accent.gold)
                        }
                    }

                    Link(destination: URL(string: "https://sundeefundee.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "link")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Accent.gold)
                        }
                    }
                }

                // Account Actions Section
                Section {
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .foregroundColor(AppTheme.Text.primary)

                    Button("Delete All Data & Account") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(AppTheme.Semantic.error)
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .confirmationDialog(
                "Delete Account?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    Task {
                        await authViewModel.deleteAccount()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your workouts, benchmarks, and settings. This action cannot be undone.")
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
}

// MARK: - CycleSettingsView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct CycleSettingsView: View {
    @State private var cycleLength: Double = 28
    @State private var lastPeriodStart: Date = Date()
    @State private var hasChanges: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("Cycle Length")
                            .font(AppTheme.Typography.headlineMedium)
                        Spacer()
                        Text("\(Int(cycleLength)) days")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Accent.gold)
                    }

                    Slider(value: $cycleLength, in: 21...35, step: 1) {
                        Text("\(Int(cycleLength)) days")
                    }
                    .accessibilityLabel("Cycle length, \(Int(cycleLength)) days")

                    Text("Average menstrual cycle length")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }

            Section {
                DatePicker("Last Period Start", selection: $lastPeriodStart, displayedComponents: .date)
            }

            Section {
                Button {
                    Task { await saveCycleSettings() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                        Spacer()
                    }
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("Cycle Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await loadCycleSettings()
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadCycleSettings() async {
        do {
            let records = try await dataClient.fetchAll(
                recordType: "CycleSettings"
            ) as [CycleSettingsRecord]

            if let settings = records.first {
                cycleLength = Double(settings.averageCycleLengthDays)
                if let lastStart = settings.lastPeriodStart {
                    lastPeriodStart = lastStart
                }
            }
        } catch {
            errorMessage = "Failed to load cycle settings: \(error.localizedDescription)"
        }
    }

    private func saveCycleSettings() async {
        isSaving = true
        let record = CycleSettingsRecord(
            averageCycleLengthDays: Int(cycleLength),
            lastPeriodStart: lastPeriodStart
        )
        do {
            try await dataClient.save(record, recordType: "CycleSettings")
        } catch {
            errorMessage = "Failed to save cycle settings: \(error.localizedDescription)"
        }
        isSaving = false
    }
}

// MARK: - Enums

enum ExperienceLevel: String, Codable, Sendable {
    case beginner
    case intermediate
    case advanced
}

enum PrimaryGoal: String, Codable, Sendable {
    case strength
    case hypertrophy
    case endurance
    case weightLoss
}

// MARK: - UserSettings Model

struct UserSettingsRecord: Codable, Sendable {
    let cycleTrackingEnabled: Bool
    let weightUnit: String
    let experienceLevel: String
    let primaryGoal: String
}

// MARK: - SettingsViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var cycleTrackingEnabled: Bool = false
    @Published var weightUnit: WeightUnit = .lbs
    @Published var experienceLevel: ExperienceLevel = .intermediate
    @Published var primaryGoal: PrimaryGoal = .strength
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    private let dataClient: DataClientProtocol
    private var hasLoaded = false

    init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.dataClient = dataClient
        Task {
            await loadSettings()
        }
    }

    func loadSettings() async {
        guard !hasLoaded else { return }
        do {
            let records = try await dataClient.fetchAll(
                recordType: "UserSettings"
            ) as [UserSettingsRecord]

            if let settings = records.first {
                cycleTrackingEnabled = settings.cycleTrackingEnabled
                weightUnit = WeightUnit(rawValue: settings.weightUnit) ?? .lbs
                experienceLevel = ExperienceLevel(rawValue: settings.experienceLevel) ?? .intermediate
                primaryGoal = PrimaryGoal(rawValue: settings.primaryGoal) ?? .strength
            }
            hasLoaded = true
        } catch {
            errorMessage = "Failed to load settings: \(error.localizedDescription)"
            hasLoaded = true
        }
    }

    func saveSettings() async {
        isSaving = true
        let record = UserSettingsRecord(
            cycleTrackingEnabled: cycleTrackingEnabled,
            weightUnit: weightUnit.rawValue,
            experienceLevel: experienceLevel.rawValue,
            primaryGoal: primaryGoal.rawValue
        )

        do {
            try await dataClient.save(record, recordType: "UserSettings")
        } catch {
            errorMessage = "Failed to save settings: \(error.localizedDescription)"
        }
        isSaving = false
    }
}

