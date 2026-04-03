import SwiftUI

// MARK: - SettingsView
//
// App settings including profile, subscription, cycle tracking, and preferences.
// Matches the web app's settings feature.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel

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

                            Text("Free")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Accent.gold)
                                .padding(.horizontal, AppTheme.Spacing.md)
                                .padding(.vertical, AppTheme.Spacing.xs)
                                .background(AppTheme.Accent.goldLight)
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                        .padding(.vertical, AppTheme.Spacing.xs)
                    }

                    Button("Manage Subscription") {
                        viewModel.showingSubscription = true
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
                }

                // Sign Out Section
                Section {
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .foregroundColor(AppTheme.Semantic.error)
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .sheet(isPresented: $viewModel.showingSubscription) {
                SubscriptionView()
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

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = CloudKitClient(containerIdentifier: "icloud.com.sundeefundee.app")) {
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
            print("Error loading cycle settings: \(error)")
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
            print("Error saving cycle settings: \(error)")
        }
        isSaving = false
    }
}

// MARK: - SubscriptionView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SubscriptionViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Current Plan
                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Current Plan")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Text.secondary)

                    Text(viewModel.subscription.tier.rawValue.capitalized)
                        .font(AppTheme.Typography.displayLarge)
                        .foregroundColor(AppTheme.Text.primary)

                    if viewModel.subscription.hasAccess {
                        Text("Active")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(.green)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(AppTheme.CornerRadius.small)
                    }
                }

                // Features
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("Features")
                        .font(AppTheme.Typography.headlineMedium)

                    featureRow("Lifts Tracked", value: viewModel.maxLiftsText)
                    featureRow("AI Generations", value: "\(viewModel.subscription.tier.dailyAIGenerations)/day")
                    featureRow("Custom Benchmarks", isEnabled: viewModel.subscription.tier.hasCustomBenchmarks)
                    featureRow("Pain Trends", isEnabled: viewModel.subscription.tier.hasPainTrends)
                }

                Spacer()

                // Upgrade Button
                if !viewModel.subscription.hasAccess {
                    Button("Upgrade to Premium") {
                        Task {
                            await viewModel.purchase(tier: .premium)
                        }
                    }
                    .artDecoButton(style: .accent)
                }
            }
            .padding(AppTheme.Spacing.lg)
            .artDecoBackground()
            .navigationTitle("Subscription")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
            .task {
                await viewModel.loadSubscription()
            }
        }
    }

    private func featureRow(_ label: String, value: String? = nil, isEnabled: Bool = true) -> some View {
        HStack {
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isEnabled ? AppTheme.Accent.gold : AppTheme.Text.secondary)

            Text(label)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.primary)

            Spacer()

            if let value = value {
                Text(value)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        }
    }
}

// MARK: - SubscriptionViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var subscription: SubscriptionInfo = SubscriptionInfo(tier: .free, status: .active)
    @Published var isLoading: Bool = false

    private let subscriptionClient: SubscriptionClientProtocol

    init(subscriptionClient: SubscriptionClientProtocol = MockSubscriptionClient()) {
        self.subscriptionClient = subscriptionClient
    }

    var maxLiftsText: String {
        if let max = subscription.tier.maxLifts {
            return "\(max)"
        } else {
            return "Unlimited"
        }
    }

    func loadSubscription() async {
        isLoading = true

        do {
            subscription = try await subscriptionClient.getSubscriptionInfo()
        } catch {
            print("Error loading subscription: \(error)")
        }

        isLoading = false
    }

    func purchase(tier: SubscriptionTier) async {
        isLoading = true

        do {
            subscription = try await subscriptionClient.purchase(tier: tier)
        } catch {
            print("Error purchasing: \(error)")
        }

        isLoading = false
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

// MARK: - CycleSettingsRecord Model

struct CycleSettingsRecord: Codable, Sendable {
    let averageCycleLengthDays: Int
    let lastPeriodStart: Date?
}

// MARK: - SettingsViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var cycleTrackingEnabled: Bool = false
    @Published var weightUnit: WeightUnit = .lbs
    @Published var experienceLevel: ExperienceLevel = .intermediate
    @Published var primaryGoal: PrimaryGoal = .strength
    @Published var showingSubscription: Bool = false
    @Published var isSaving: Bool = false

    private let dataClient: DataClientProtocol
    private var hasLoaded = false

    init(dataClient: DataClientProtocol = CloudKitClient(containerIdentifier: "icloud.com.sundeefundee.app")) {
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
            print("Error loading settings: \(error)")
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
            print("Error saving settings: \(error)")
        }
        isSaving = false
    }
}
