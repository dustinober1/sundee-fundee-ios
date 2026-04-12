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
                                .accessibilityHidden(true)

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
                    Text("Sundee Fundee is a fitness tool, not a medical device. It is not a substitute for professional medical advice, diagnosis, or treatment. Consult your doctor before starting any exercise program.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                        .padding(.vertical, AppTheme.Spacing.xs)

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
                                .accessibilityHidden(true)
                        }
                    }

                    Link(destination: URL(string: "https://sundeefundee.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "link")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Accent.gold)
                                .accessibilityHidden(true)
                        }
                    }

                    Link(destination: URL(string: "https://sundeefundee.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "link")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Accent.gold)
                                .accessibilityHidden(true)
                        }
                    }
                }

                // Account Actions Section
                Section {
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .foregroundColor(AppTheme.Text.primary)
                    .accessibilityHint("Sign out of your account")

                    Button("Delete All Data & Account") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(AppTheme.Semantic.error)
                    .accessibilityHint("Permanently delete all data. This cannot be undone.")
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
    @State private var periodStartDate: Date = Date()
    @State private var periodEndDate: Date = Date()
    @State private var loggedPeriods: [PeriodLogRecord] = []
    @State private var isSaving: Bool = false
    @State private var isLogging: Bool = false
    @State private var isEndingPeriod: Bool = false
    @State private var errorMessage: String?

    private let dataClient: DataClientProtocol

    /// Whether there is an active period (started but not ended).
    private var activePeriod: PeriodLogRecord? {
        loggedPeriods.first(where: { $0.isActive })
    }

    init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    var body: some View {
        Form {
            // Cycle Length
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
                Button {
                    Task { await saveCycleSettings() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save Cycle Length")
                        }
                        Spacer()
                    }
                }
                .disabled(isSaving)
            }

            // Active Period / Start Period
            if let active = activePeriod {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Period started")
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Text.primary)
                            Text(formatDate(active.startDate))
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                        Spacer()
                        Text("\u{1F988} Active")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(.red)
                    }

                    Button {
                        Task { await endActivePeriod() }
                    } label: {
                        HStack {
                            Spacer()
                            if isEndingPeriod {
                                ProgressView()
                            } else {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("End Period")
                                }
                                .font(AppTheme.Typography.labelLarge)
                                .foregroundColor(.red)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isEndingPeriod)
                } header: {
                    Text("Current Period")
                }
            } else {
                Section {
                    DatePicker("Start Date", selection: $periodStartDate, in: ...Date(), displayedComponents: .date)

                    Button {
                        Task { await startPeriod() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLogging {
                                ProgressView()
                            } else {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "drop.fill")
                                    Text("Start Period")
                                }
                                .font(AppTheme.Typography.labelLarge)
                                .foregroundColor(.red)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLogging)
                } header: {
                    Text("Log Period")
                } footer: {
                    Text("You can end it later, or log a past period with start and end dates below.")
                }

                // Log a past period (with both dates) — only show when there are previous periods
                if !loggedPeriods.isEmpty {
                    Section {
                        DatePicker("Start Date", selection: $periodStartDate, in: ...Date(), displayedComponents: .date)
                        DatePicker("End Date", selection: $periodEndDate, in: ...Date(), displayedComponents: .date)

                        Button {
                            Task { await logPastPeriod() }
                        } label: {
                            HStack {
                                Spacer()
                                if isLogging {
                                    ProgressView()
                                } else {
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Log Past Period")
                                    }
                                    .font(AppTheme.Typography.labelLarge)
                                }
                                Spacer()
                            }
                        }
                        .disabled(isLogging || periodEndDate < periodStartDate)
                    } header: {
                        Text("Log Past Period")
                    } footer: {
                        if periodEndDate < periodStartDate {
                            Text("End date must be on or after start date.")
                                .foregroundColor(AppTheme.Semantic.error)
                        }
                    }
                }
            }

            // Logged Periods (completed ones only)
            let completedPeriods = loggedPeriods.filter { !$0.isActive }
            if !completedPeriods.isEmpty {
                Section("Past Periods") {
                    ForEach(completedPeriods) { period in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatDate(period.startDate))
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Text.primary)
                                if let endDate = period.endDate {
                                    Text("to \(formatDate(endDate))")
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Text.secondary)
                                }
                            }
                            Spacer()
                            if let endDate = period.endDate {
                                Text("\(daysBetween(period.startDate, endDate)) days")
                                    .font(AppTheme.Typography.labelMedium)
                                    .foregroundColor(AppTheme.Accent.gold)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { completedPeriods[$0].id }
                        Task { await deletePeriods(ids: ids) }
                    }
                }
            }
        }
        .navigationTitle("Cycle Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await loadData()
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

    // MARK: - Data

    private func loadData() async {
        do {
            let records = try await dataClient.fetchAll(
                recordType: "CycleSettings"
            ) as [CycleSettingsRecord]

            if let settings = records.first {
                cycleLength = Double(settings.averageCycleLengthDays)
            }
        } catch {
            // Use defaults
        }

        do {
            loggedPeriods = try await dataClient.fetchAll(
                recordType: "PeriodLogRecord"
            ) as [PeriodLogRecord]
            loggedPeriods.sort { $0.startDate > $1.startDate }
        } catch {
            // No logged periods yet
        }
    }

    private func saveCycleSettings() async {
        isSaving = true
        let lastStart = loggedPeriods.sorted(by: { $0.startDate > $1.startDate }).first?.startDate
        let record = CycleSettingsRecord(
            averageCycleLengthDays: Int(cycleLength),
            lastPeriodStart: lastStart
        )
        do {
            try await dataClient.save(record, recordType: "CycleSettings")
            NotificationCenter.default.post(name: .cycleDataUpdated, object: nil)
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
        isSaving = false
    }

    private func startPeriod() async {
        isLogging = true
        let startOfDay = Calendar.current.startOfDay(for: periodStartDate)
        let record = PeriodLogRecord(startDate: startOfDay, endDate: nil)
        do {
            try await dataClient.save(record, recordType: "PeriodLogRecord")
            loggedPeriods.insert(record, at: 0)

            let settingsRecord = CycleSettingsRecord(
                averageCycleLengthDays: Int(cycleLength),
                lastPeriodStart: startOfDay
            )
            try await dataClient.save(settingsRecord, recordType: "CycleSettings")

            NotificationCenter.default.post(name: .cycleDataUpdated, object: nil)
            periodStartDate = Date()
        } catch {
            errorMessage = "Failed to start period: \(error.localizedDescription)"
        }
        isLogging = false
    }

    private func endActivePeriod() async {
        guard let active = activePeriod else { return }
        isEndingPeriod = true
        let endOfDay = Calendar.current.startOfDay(for: Date())
        let updated = PeriodLogRecord(id: active.id, startDate: active.startDate, endDate: endOfDay)
        do {
            try await dataClient.save(updated, recordType: "PeriodLogRecord")
            if let idx = loggedPeriods.firstIndex(where: { $0.id == active.id }) {
                loggedPeriods[idx] = updated
            }
            NotificationCenter.default.post(name: .cycleDataUpdated, object: nil)
        } catch {
            errorMessage = "Failed to end period: \(error.localizedDescription)"
        }
        isEndingPeriod = false
    }

    private func logPastPeriod() async {
        isLogging = true
        let startOfDay = Calendar.current.startOfDay(for: periodStartDate)
        let endOfDay = Calendar.current.startOfDay(for: periodEndDate)
        let record = PeriodLogRecord(startDate: startOfDay, endDate: endOfDay)
        do {
            try await dataClient.save(record, recordType: "PeriodLogRecord")
            loggedPeriods.insert(record, at: 0)

            let settingsRecord = CycleSettingsRecord(
                averageCycleLengthDays: Int(cycleLength),
                lastPeriodStart: startOfDay
            )
            try await dataClient.save(settingsRecord, recordType: "CycleSettings")

            NotificationCenter.default.post(name: .cycleDataUpdated, object: nil)
            periodStartDate = Date()
            periodEndDate = Date()
        } catch {
            errorMessage = "Failed to log period: \(error.localizedDescription)"
        }
        isLogging = false
    }

    private func deletePeriods(ids: [String]) async {
        loggedPeriods.removeAll { ids.contains($0.id) }
        for id in ids {
            do {
                try await dataClient.delete(recordType: "PeriodLogRecord", id: id)
            } catch {
                // Best effort
            }
        }
        NotificationCenter.default.post(name: .cycleDataUpdated, object: nil)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: start), to: Calendar.current.startOfDay(for: end)).day ?? 0
        return days + 1
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
    let id: String
    let cycleTrackingEnabled: Bool
    let weightUnit: String
    let experienceLevel: String
    let primaryGoal: String

    init(
        cycleTrackingEnabled: Bool,
        weightUnit: String,
        experienceLevel: String,
        primaryGoal: String
    ) {
        self.id = "user_settings"
        self.cycleTrackingEnabled = cycleTrackingEnabled
        self.weightUnit = weightUnit
        self.experienceLevel = experienceLevel
        self.primaryGoal = primaryGoal
    }
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

            if let settings = records.last {
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
        guard hasLoaded else { return }
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

