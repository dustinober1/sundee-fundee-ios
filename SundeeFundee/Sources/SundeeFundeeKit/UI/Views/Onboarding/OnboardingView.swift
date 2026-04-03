import SwiftUI

// MARK: - OnboardingView
//
// Multi-step onboarding flow shown after first sign-in.
// Collects experience level, primary goal, weight unit, and cycle tracking preference.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            progressBar

            // Steps
            TabView(selection: $viewModel.currentStep) {
                welcomeStep.tag(0)
                experienceStep.tag(1)
                goalStep.tag(2)
                preferencesStep.tag(3)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)

            // Navigation Buttons
            navigationButtons
        }
        .artDecoBackground()
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppTheme.Accent.goldLight)
                    .frame(height: 4)

                Rectangle()
                    .fill(AppTheme.Accent.gold)
                    .frame(width: geometry.size.width * CGFloat(viewModel.currentStep + 1) / 4.0, height: 4)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundColor(AppTheme.Accent.gold)

            Text("Welcome to\nSundee Fundee")
                .font(AppTheme.Typography.displayLarge)
                .foregroundColor(AppTheme.Text.primary)
                .multilineTextAlignment(.center)

            Text("Cycle-aware strength training\npersonalized for your body")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
    }

    // MARK: - Step 1: Experience Level

    private var experienceStep: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            Text("Your Experience")
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Text.primary)

            Text("How long have you been strength training?")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)

            VStack(spacing: AppTheme.Spacing.md) {
                experienceOption(.beginner, "Beginner", "Less than 1 year", "leaf")
                experienceOption(.intermediate, "Intermediate", "1-3 years", "flame")
                experienceOption(.advanced, "Advanced", "3+ years", "bolt")
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
    }

    private func experienceOption(_ level: ExperienceLevel, _ title: String, _ subtitle: String, _ icon: String) -> some View {
        Button {
            viewModel.experienceLevel = level
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.experienceLevel == level ? AppTheme.Accent.gold : AppTheme.Text.secondary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Text(subtitle)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                Spacer()

                Image(systemName: viewModel.experienceLevel == level ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(viewModel.experienceLevel == level ? AppTheme.Accent.gold : AppTheme.Text.secondary.opacity(0.3))
            }
            .padding(AppTheme.Spacing.lg)
            .background(
                viewModel.experienceLevel == level
                    ? AppTheme.Accent.goldLight
                    : AppTheme.Background.card
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: Primary Goal

    private var goalStep: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            Text("Your Goal")
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Text.primary)

            Text("What's your primary training focus?")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)

            VStack(spacing: AppTheme.Spacing.md) {
                goalOption(.strength, "Strength", "Get stronger, lift heavier", "scalemass")
                goalOption(.hypertrophy, "Muscle Growth", "Build size and definition", "figure.arms.open")
                goalOption(.endurance, "Endurance", "Improve stamina and conditioning", "flame")
                goalOption(.weightLoss, "Weight Loss", "Burn fat, build lean muscle", "bolt.heart")
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
    }

    private func goalOption(_ goal: PrimaryGoal, _ title: String, _ subtitle: String, _ icon: String) -> some View {
        Button {
            viewModel.primaryGoal = goal
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.primaryGoal == goal ? AppTheme.Accent.gold : AppTheme.Text.secondary)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Text(subtitle)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                Spacer()

                Image(systemName: viewModel.primaryGoal == goal ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(viewModel.primaryGoal == goal ? AppTheme.Accent.gold : AppTheme.Text.secondary.opacity(0.3))
            }
            .padding(AppTheme.Spacing.lg)
            .background(
                viewModel.primaryGoal == goal
                    ? AppTheme.Accent.goldLight
                    : AppTheme.Background.card
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 3: Preferences

    private var preferencesStep: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            Text("Preferences")
                .font(AppTheme.Typography.displaySmall)
                .foregroundColor(AppTheme.Text.primary)

            Text("Customize your experience")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)

            VStack(spacing: AppTheme.Spacing.lg) {
                // Weight Unit
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

                // Cycle Tracking
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
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            if viewModel.currentStep > 0 {
                Button("Back") {
                    viewModel.currentStep -= 1
                }
                .artDecoButton(style: .ghost)
            }

            Spacer()

            if viewModel.currentStep < 3 {
                Button("Next") {
                    viewModel.currentStep += 1
                }
                .artDecoButton(style: .primary)
            } else {
                Button("Get Started") {
                    viewModel.completeOnboarding()
                    onComplete()
                }
                .artDecoButton(style: .accent)
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

    private let dataClient: DataClientProtocol

    init(dataClient: DataClientProtocol = DataClientFactory.shared.client) {
        self.dataClient = dataClient
    }

    func completeOnboarding() {
        // Mark onboarding as complete in Keychain immediately
        _ = KeychainHelper.save(key: "onboarding_complete", value: "true")

        // Save user settings to CloudKit in the background (non-blocking)
        let settings = UserSettingsRecord(
            cycleTrackingEnabled: cycleTrackingEnabled,
            weightUnit: weightUnit.rawValue,
            experienceLevel: experienceLevel.rawValue,
            primaryGoal: primaryGoal.rawValue
        )
        Task {
            do {
                try await dataClient.save(settings, recordType: "UserSettings")
            } catch {
                print("Error saving onboarding settings: \(error)")
            }
        }
    }
}
