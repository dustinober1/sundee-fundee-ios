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

                // Cycle Tracking Section
                Section("Cycle Tracking") {
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

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Cycle Length")
                        .font(AppTheme.Typography.headlineMedium)

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
        }
        .navigationTitle("Cycle Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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

enum ExperienceLevel: String {
    case beginner
    case intermediate
    case advanced
}

enum PrimaryGoal: String {
    case strength
    case hypertrophy
    case endurance
    case weightLoss
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

    init() {
        // Load settings from UserDefaults or CloudKit
        loadSettings()
    }

    private func loadSettings() {
        // Stub: Load from persistent storage
    }
}
