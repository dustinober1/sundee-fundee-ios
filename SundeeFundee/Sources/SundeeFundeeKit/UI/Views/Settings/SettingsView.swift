import SwiftUI
import os.log

// MARK: - SettingsView
//
// App settings including profile, cycle tracking, and preferences.
// Matches the web app's settings feature.

private enum SettingsLinks {
    // swiftlint:disable force_unwrapping
    static let homepage = URL(string: "https://sundeefundee.com")!
    static let privacy = URL(string: "https://sundeefundee.com/privacy")!
    static let terms = URL(string: "https://sundeefundee.com/terms")!
    // swiftlint:enable force_unwrapping
}

private var appVersionString: String {
    let marketing = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.4"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    return build.isEmpty ? marketing : "\(marketing) (\(build))"
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var diagnostics = DiagnosticsService.shared
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingDeleteConfirmation = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Training") {
                    Picker("Weight Unit", selection: $viewModel.weightUnit) {
                        Text("Pounds (lbs)").tag(WeightUnit.lbs)
                        Text("Kilograms (kg)").tag(WeightUnit.kg)
                    }

                    Picker("Goal", selection: $viewModel.primaryGoal) {
                        Text("Strength").tag(PrimaryGoal.strength)
                        Text("Hypertrophy").tag(PrimaryGoal.hypertrophy)
                        Text("Endurance").tag(PrimaryGoal.endurance)
                        Text("Weight Loss").tag(PrimaryGoal.weightLoss)
                    }

                    Picker("Default Equipment", selection: $viewModel.defaultEquipment) {
                        ForEach(EquipmentAccess.userSelectableDefaults, id: \.self) { equipment in
                            Text(equipment.displayName).tag(equipment)
                        }
                    }

                    if let selectedProfile = viewModel.selectedEquipmentProfile {
                        LabeledContent("Saved Profile") {
                            Text(selectedProfile.name)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                    }

                    #if canImport(UserNotifications)
                    NavigationLink {
                        WorkoutRemindersSettingsView()
                    } label: {
                        Label("Reminders", systemImage: "bell")
                    }
                    #endif
                }
                .onChange(of: viewModel.weightUnit) { _, _ in Task { await viewModel.saveSettings() } }
                .onChange(of: viewModel.primaryGoal) { _, _ in Task { await viewModel.saveSettings() } }
                .onChange(of: viewModel.defaultEquipment) { _, _ in Task { await viewModel.saveSettings() } }
                .onChange(of: viewModel.cycleTrackingEnabled) { _, _ in Task { await viewModel.saveSettings() } }

                Section("Privacy") {
                    NavigationLink {
                        DataTrustCenterView()
                    } label: {
                        Label("Data Trust Center", systemImage: "shield.checkered")
                    }

                    #if canImport(UIKit)
                    NavigationLink {
                        SharePrivacyDefaultsView()
                    } label: {
                        Label("Share Defaults", systemImage: "hand.raised")
                    }
                    #endif

                    NavigationLink {
                        ExportView()
                    } label: {
                        Label("Export My Data", systemImage: "square.and.arrow.up")
                    }
                }

                SupportDeveloperSection()

                // Diagnostics Section — only visible when there's something to surface
                if diagnostics.decodeFailureCount > 0 {
                    Section("Diagnostics") {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(AppTheme.Accent.orange)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(diagnostics.decodeFailureCount) record\(diagnostics.decodeFailureCount == 1 ? "" : "s") couldn't be loaded")
                                    .font(AppTheme.Typography.bodyMedium)
                                Text("Some of your history may be missing. Try signing out and back in.")
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }
                        }
                    }
                }

                Section("Account") {
                    if let userName = authViewModel.userName {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(.title))
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

                    Text("Sundee Fundee is a fitness tool, not a medical device. It is not a substitute for professional medical advice, diagnosis, or treatment. Consult your doctor before starting any exercise program.")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                        .padding(.vertical, AppTheme.Spacing.xs)

                    LabeledContent("Version") {
                        Text(appVersionString)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                    }

                    Link("Website", destination: SettingsLinks.homepage)
                    Link("Privacy Policy", destination: SettingsLinks.privacy)
                    Link("Terms of Service", destination: SettingsLinks.terms)

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

// MARK: - Enums

public enum ExperienceLevel: String, Codable, Sendable {
    case beginner
    case intermediate
    case advanced
}

public enum PrimaryGoal: String, Codable, Sendable {
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
    let defaultEquipmentRaw: String

    var defaultEquipment: EquipmentAccess {
        EquipmentAccess(rawValue: defaultEquipmentRaw) ?? .fullGym
    }

    init(
        cycleTrackingEnabled: Bool,
        weightUnit: String,
        experienceLevel: String,
        primaryGoal: String,
        defaultEquipment: EquipmentAccess = .fullGym
    ) {
        self.id = "user_settings"
        self.cycleTrackingEnabled = cycleTrackingEnabled
        self.weightUnit = weightUnit
        self.experienceLevel = experienceLevel
        self.primaryGoal = primaryGoal
        self.defaultEquipmentRaw = defaultEquipment.rawValue
    }

    // CloudKit stores Bool as Int64. JSONDecoder expects Bool.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        if let boolVal = try? container.decode(Bool.self, forKey: .cycleTrackingEnabled) {
            cycleTrackingEnabled = boolVal
        } else {
            cycleTrackingEnabled = (try? container.decode(Int.self, forKey: .cycleTrackingEnabled)) != 0
        }
        weightUnit = try container.decode(String.self, forKey: .weightUnit)
        experienceLevel = try container.decode(String.self, forKey: .experienceLevel)
        primaryGoal = try container.decode(String.self, forKey: .primaryGoal)
        let rawEquipment = try container.decodeIfPresent(String.self, forKey: .defaultEquipmentRaw)
            ?? EquipmentAccess.fullGym.rawValue
        defaultEquipmentRaw = EquipmentAccess(rawValue: rawEquipment)?.rawValue
            ?? EquipmentAccess.fullGym.rawValue
    }
}

// MARK: - SettingsViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var isLoaded: Bool = false
    @Published var cycleTrackingEnabled: Bool = false
    @Published var weightUnit: WeightUnit = .lbs
    @Published var experienceLevel: ExperienceLevel = .intermediate
    @Published var primaryGoal: PrimaryGoal = .strength
    @Published var defaultEquipment: EquipmentAccess = .fullGym
    @Published var equipmentProfiles: [EquipmentProfile] = []
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    private let dataClient: DataClientProtocol
    private let equipmentProfileService: EquipmentProfileService
    private var hasLoaded = false

    /// Holds the in-flight save task, if any. New writes cancel the pending one
    /// so only the latest state is committed. Prevents CloudKit "client oplock"
    /// conflicts from rapid toggles across multiple `.onChange` handlers.
    private var saveTask: Task<Void, Never>?

    var selectedEquipmentProfile: EquipmentProfile? {
        equipmentProfiles.first(where: { $0.isDefault || $0.equipment == defaultEquipment })
    }

    init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.dataClient = dataClient
        self.equipmentProfileService = EquipmentProfileService(dataClient: dataClient)
        Task {
            await loadSettings()
            await loadEquipmentProfiles()
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
                defaultEquipment = settings.defaultEquipment
            }
            hasLoaded = true
            isLoaded = true
        } catch {
            // Log the raw error for debugging
            let logger = Logger(subsystem: "com.sundeefundee.app", category: "Settings")
            logger.error("Failed to load settings: \(error)")
            errorMessage = "We couldn't load your settings. Check your connection and try again."
            hasLoaded = true
            isLoaded = true
        }
    }

    func loadEquipmentProfiles() async {
        equipmentProfiles = await equipmentProfileService.loadProfiles()
    }

    func setDefaultEquipmentProfile(_ profile: EquipmentProfile) async {
        do {
            try await equipmentProfileService.setDefault(profileID: profile.id)
            equipmentProfiles = await equipmentProfileService.loadProfiles()
            defaultEquipment = profile.equipment
            await saveSettings()
        } catch {
            let logger = Logger(subsystem: "com.sundeefundee.app", category: "Settings")
            logger.error("Failed to update equipment profile: \(error)")
            errorMessage = "We couldn't update your equipment profile. Check your connection and try again."
        }
    }

    /// Schedules a save of the current settings. If another save is pending or
    /// in-flight, it is cancelled and superseded by this one. Ensures only the
    /// latest state is committed and prevents parallel saves from racing the
    /// server's changeTag.
    ///
    /// A 150ms coalescing window gives other `.onChange` handlers a chance to
    /// cancel this task before it hits the network — rapid sequential toggles
    /// (e.g. a user flipping through picker options) collapse to a single save.
    func saveSettings() async {
        guard hasLoaded else { return }

        // Cancel any in-flight save — the new one will use the latest @Published values.
        saveTask?.cancel()

        let task = Task { @MainActor [weak self] in
            guard let self else { return }

            // Coalescing window: if another onChange fires within 150ms,
            // it cancels this task before the actual save runs.
            try? await Task.sleep(nanoseconds: 150_000_000)
            if Task.isCancelled { return }

            self.isSaving = true
            let record = UserSettingsRecord(
                cycleTrackingEnabled: self.cycleTrackingEnabled,
                weightUnit: self.weightUnit.rawValue,
                experienceLevel: self.experienceLevel.rawValue,
                primaryGoal: self.primaryGoal.rawValue,
                defaultEquipment: self.defaultEquipment
            )

            do {
                try await self.dataClient.save(record, recordType: "UserSettings")
            } catch {
                if !Task.isCancelled {
                    // Log the raw error for debugging
                    let logger = Logger(subsystem: "com.sundeefundee.app", category: "Settings")
                    logger.error("Failed to save settings: \(error)")
                    self.errorMessage = "We couldn't save your settings. Check your connection and try again."
                }
            }

            if !Task.isCancelled {
                self.isSaving = false
            }
        }
        saveTask = task
        await task.value
    }
}
