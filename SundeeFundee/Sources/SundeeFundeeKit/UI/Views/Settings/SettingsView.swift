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

                            TierBadge(tier: viewModel.currentTier)
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
                        HStack {
                            Label("Export My Data", systemImage: "square.and.arrow.up")
                            Spacer()
                            Text("Pro")
                                .font(AppTheme.Typography.labelSmall)
                                .foregroundColor(AppTheme.Accent.gold)
                        }
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
            .sheet(isPresented: $viewModel.showingSubscription) {
                SubscriptionView()
            }
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
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Choose Your Plan")
                            .font(AppTheme.Typography.displayLarge)
                            .foregroundColor(AppTheme.Text.primary)

                        Text("Train smarter. Recover better.")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                    .padding(.top, AppTheme.Spacing.md)

                    // Tier Cards
                    tierCard(
                        tier: .free,
                        price: "Free",
                        features: [
                            "5 lifts tracked",
                            "1 injury profile",
                            "30-day workout history",
                            "Basic cycle-aware hints",
                            "Prebuilt benchmarks",
                        ]
                    )

                    tierCard(
                        tier: .plus,
                        price: "$2.99/mo",
                        features: [
                            "Unlimited lifts, injuries & history",
                            "On-device AI workout builder",
                            "Advanced charts & trends",
                            "Custom benchmarks",
                            "Editable workouts & templates",
                            "Weekly planner draft",
                            "Smart lighter-day adjustments",
                        ]
                    )

                    tierCard(
                        tier: .premium,
                        price: "$4.99/mo",
                        features: [
                            "Everything in Plus",
                            "Coach memory across sessions",
                            "Adaptive weekly programming",
                            "Missed-workout reshuffle",
                            "Plateau detection & next steps",
                            "Smart substitutions",
                            "Weekly recap & recommendations",
                            "Preference learning",
                            "Export & share plans",
                        ]
                    )

                    // Restore Purchases
                    Button {
                        Task { await viewModel.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                    .padding(.top, AppTheme.Spacing.sm)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .artDecoBackground()
            .navigationTitle("Membership")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
                #endif
            }
            .task {
                await viewModel.loadSubscription()
            }
        }
    }

    private func tierCard(
        tier: SubscriptionTier,
        price: String,
        features: [String]
    ) -> some View {
        let isCurrent = viewModel.subscription.tier == tier
        let accentColor: Color = switch tier {
        case .free: AppTheme.Text.secondary
        case .plus: AppTheme.Accent.gold
        case .premium: AppTheme.Semantic.success
        }

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Tier header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.displayName)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Text(tier.tagline)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                Spacer()

                Text(price)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(accentColor)
            }

            Divider()
                .background(accentColor.opacity(0.3))

            // Feature list
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(accentColor)
                            .frame(width: 16, height: 16)

                        Text(feature)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.primary)
                    }
                }
            }

            // Action button
            if isCurrent {
                Text("Current Plan")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(accentColor.opacity(0.08))
                    .cornerRadius(AppTheme.CornerRadius.medium)
            } else if tier != .free {
                Button {
                    Task { await viewModel.purchase(tier: tier) }
                } label: {
                    Text("Upgrade to \(tier.displayName)")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(accentColor)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Background.card)
        .cornerRadius(AppTheme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .stroke(isCurrent ? accentColor : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - SubscriptionViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var subscription: SubscriptionInfo = SubscriptionInfo(tier: .free, status: .active)
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let subscriptionClient: SubscriptionClientProtocol

    init(subscriptionClient: SubscriptionClientProtocol = SubscriptionClientFactory.shared.client) {
        self.subscriptionClient = subscriptionClient
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
        errorMessage = nil
        do {
            subscription = try await subscriptionClient.purchase(tier: tier)
        } catch {
            errorMessage = "Purchase failed. Please try again."
            print("Error purchasing: \(error)")
        }
        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        do {
            subscription = try await subscriptionClient.restorePurchases()
        } catch {
            errorMessage = "No purchases to restore."
            print("Error restoring: \(error)")
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
    @Published var currentTier: SubscriptionTier = .free

    private let dataClient: DataClientProtocol
    private let subscriptionClient: SubscriptionClientProtocol
    private var hasLoaded = false

    init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client,
        subscriptionClient: SubscriptionClientProtocol = SubscriptionClientFactory.shared.client
    ) {
        self.dataClient = dataClient
        self.subscriptionClient = subscriptionClient
        Task {
            await loadSettings()
            await loadSubscriptionTier()
        }
    }

    func loadSubscriptionTier() async {
        do {
            let info = try await subscriptionClient.getSubscriptionInfo()
            currentTier = info.tier
        } catch {
            currentTier = .free
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

// MARK: - TierBadge

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct TierBadge: View {
    let tier: SubscriptionTier

    private var badgeColor: Color {
        switch tier {
        case .free: return AppTheme.Text.secondary
        case .plus: return AppTheme.Accent.gold
        case .premium: return AppTheme.Semantic.success
        }
    }

    var body: some View {
        Text(tier.displayName)
            .font(AppTheme.Typography.labelMedium)
            .foregroundColor(badgeColor)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(badgeColor.opacity(0.12))
            .cornerRadius(AppTheme.CornerRadius.small)
    }
}
