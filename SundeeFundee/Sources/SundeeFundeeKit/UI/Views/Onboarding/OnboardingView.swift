import SwiftUI

// MARK: - OnboardingView
//
// Minimal onboarding flow shown after first sign-in.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void
    let onStartFirstWorkout: ((Workout) -> Void)?

    public init(
        onComplete: @escaping () -> Void,
        onStartFirstWorkout: ((Workout) -> Void)? = nil
    ) {
        self.onComplete = onComplete
        self.onStartFirstWorkout = onStartFirstWorkout
    }

    public var body: some View {
        VStack(spacing: 0) {
            progressBar

            TabView(selection: $viewModel.currentStep) {
                welcomeStep.tag(0)
                minimalistPreferencesStep.tag(1)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            .accessibilityLabel("Onboarding step \(viewModel.currentStep + 1)")

            navigationButtons
        }
        .artDecoBackground()
        .task {
            await viewModel.trackOnboardingStarted()
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppTheme.Accent.goldLight)
                    .frame(height: 4)

                Rectangle()
                    .fill(AppTheme.Accent.gold)
                    .frame(
                        width: geometry.size.width * CGFloat(viewModel.currentStep + 1) / CGFloat(viewModel.totalSteps),
                        height: 4
                    )
            }
        }
        .frame(height: 4)
        .accessibilityLabel("Step \(viewModel.currentStep + 1) of \(viewModel.totalSteps)")
        .accessibilityValue("\(viewModel.currentStep + 1)")
    }

    private var welcomeStep: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(.largeTitle))
                .foregroundColor(AppTheme.Accent.gold)
                .accessibilityHidden(true)

            Text("Welcome to\nSundee Fundee")
                .font(AppTheme.Typography.displayLarge)
                .foregroundColor(AppTheme.Text.primary)
                .multilineTextAlignment(.center)

            Text("Cycle-aware strength training\npersonalized for your body")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Text("Sundee Fundee is a fitness tool, not a medical device. It is not a substitute for professional medical advice, diagnosis, or treatment. Consult your doctor before starting any exercise program.")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .padding(AppTheme.Spacing.xl)
    }

    private var minimalistPreferencesStep: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            Text("Your Preferences")
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Text.primary)

            Text("Choose the defaults that shape your training.")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)

            VStack(spacing: AppTheme.Spacing.lg) {
                ArtDecoCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Goal")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        goalPickerButton(.strength, "Strength", "scalemass")
                        goalPickerButton(.hypertrophy, "Muscle Growth", "figure.arms.open")
                        goalPickerButton(.endurance, "Endurance", "flame")
                        goalPickerButton(.weightLoss, "Weight Loss", "bolt.heart")
                    }
                }

                ArtDecoCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Weight Unit")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        Picker("Weight Unit", selection: $viewModel.weightUnit) {
                            Text("Pounds (lbs)").tag(WeightUnit.lbs)
                            Text("Kilograms (kg)").tag(WeightUnit.kg)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                ArtDecoCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text("Cycle Tracking")
                                    .font(AppTheme.Typography.headlineMedium)
                                    .foregroundColor(AppTheme.Text.primary)

                                Text("Adapt workouts to your menstrual cycle phases")
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.cycleTrackingEnabled)
                                .labelsHidden()
                                .accessibilityLabel("Enable cycle tracking")
                        }
                    }
                }

                ArtDecoCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Default Equipment")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        Picker("Default Equipment", selection: $viewModel.defaultEquipment) {
                            ForEach(EquipmentAccess.userSelectableDefaults, id: \.self) { equipment in
                                Text(equipment.displayName).tag(equipment)
                            }
                        }
                        .pickerStyle(.menu)

                        Text(viewModel.defaultEquipment.shortDescription)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
    }

    private func goalPickerButton(_ goal: PrimaryGoal, _ title: String, _ icon: String) -> some View {
        let isSelected = viewModel.primaryGoal == goal
        return Button {
            viewModel.primaryGoal = goal
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? AppTheme.Accent.gold : AppTheme.Text.secondary)
                    .frame(width: 32)

                Text(title)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppTheme.Accent.gold : AppTheme.Text.secondary.opacity(0.3))
            }
            .padding(AppTheme.Spacing.md)
            .background(isSelected ? AppTheme.Accent.goldLight : AppTheme.Background.card)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }

    private var navigationButtons: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            if viewModel.currentStep > 0 {
                Button("Back") {
                    viewModel.currentStep = max(viewModel.currentStep - 1, 0)
                }
                .artDecoButton(style: .ghost)
                .accessibilityLabel("Go back")
            }

            Spacer()

            if viewModel.currentStep < viewModel.totalSteps - 1 {
                Button("Next") {
                    viewModel.currentStep = min(viewModel.currentStep + 1, viewModel.totalSteps - 1)
                }
                .artDecoButton(style: .primary)
                .accessibilityLabel("Next step")
            } else {
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.sm) {
                    Button("Start First Workout") {
                        Task {
                            await viewModel.completeOnboarding()
                            let workout = viewModel.buildStarterWorkout()
                            await viewModel.trackFirstWorkoutStarted()
                            onStartFirstWorkout?(workout)
                        }
                    }
                    .artDecoButton(style: .accent)
                    .accessibilityHint("Complete onboarding and start your first workout")

                    Button("Not now - go to dashboard") {
                        Task {
                            await viewModel.completeOnboarding()
                            onComplete()
                        }
                    }
                    .artDecoButton(style: .ghost)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
    }
}

// MARK: - OnboardingViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var experienceLevel: ExperienceLevel = .intermediate
    @Published var primaryGoal: PrimaryGoal = .strength
    @Published var weightUnit: WeightUnit = .lbs
    @Published var cycleTrackingEnabled: Bool = false
    @Published var defaultEquipment: EquipmentAccess = .fullGym
    let totalSteps = 2

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    func completeOnboarding() async {
        _ = KeychainHelper.save(key: "onboarding_complete", value: "true")

        let settings = UserSettingsRecord(
            cycleTrackingEnabled: cycleTrackingEnabled,
            weightUnit: weightUnit.rawValue,
            experienceLevel: experienceLevel.rawValue,
            primaryGoal: primaryGoal.rawValue,
            defaultEquipment: defaultEquipment
        )
        do {
            try await dataClient.save(settings, recordType: "UserSettings")
        } catch {
            // Best effort during onboarding.
        }

        await GrowthAnalyticsService(dataClient: dataClient).track(
            GrowthEventName.onboardingCompleted,
            source: "onboarding"
        )
    }

    func buildStarterWorkout() -> Workout {
        StarterWorkoutBuilder.build(
            context: StarterWorkoutContext(
                experienceLevel: experienceLevel,
                primaryGoal: primaryGoal,
                weightUnit: weightUnit,
                cycleTrackingEnabled: cycleTrackingEnabled,
                defaultEquipment: defaultEquipment
            )
        )
    }

    func trackOnboardingStarted() async {
        await GrowthAnalyticsService(dataClient: dataClient).track(
            GrowthEventName.onboardingStarted,
            source: "onboarding"
        )
    }

    func trackFirstWorkoutStarted() async {
        await GrowthAnalyticsService(dataClient: dataClient).track(
            GrowthEventName.firstWorkoutStarted,
            source: "onboarding"
        )
    }
}
