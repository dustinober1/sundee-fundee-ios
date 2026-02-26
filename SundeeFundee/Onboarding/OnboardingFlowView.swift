import SwiftUI
import SwiftData

/// Multi-step onboarding flow:
///   1. Name
///   2. Experience level
///   3. Primary goal
///   4. Gender
///   5. Cycle tracking opt-in (shown only for female/prefer-not-to-say)
struct OnboardingFlowView: View {
    let userID: String

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var step: OnboardingStep = .name
    @State private var name: String = ""
    @State private var experienceLevel: ExperienceLevel = .beginner
    @State private var primaryGoal: PrimaryGoal = .strength
    @State private var gender: Gender = .preferNotToSay
    @State private var cycleTrackingEnabled: Bool = false
    @State private var isSaving = false

    enum OnboardingStep: Int, CaseIterable {
        case name, experience, goal, gender, cycle
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Color.cream.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress bar
                    ProgressView(value: Double(step.rawValue + 1),
                                 total: Double(visibleSteps.count))
                        .tint(AppTheme.Color.orange)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .padding(.top, AppTheme.Spacing.lg)

                    // Step content
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                            stepContent
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing),
                                    removal: .move(edge: .leading)
                                ))
                        }
                        .padding(AppTheme.Spacing.xl)
                    }

                    // Navigation buttons
                    HStack {
                        if step.rawValue > 0 {
                            Button("Back") { withAnimation { previousStep() } }
                                .foregroundStyle(AppTheme.Color.textSecondary)
                        }
                        Spacer()
                        Button(isLastStep ? "Get Started" : "Next") {
                            withAnimation { nextStep() }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!canAdvance || isSaving)
                    }
                    .padding(AppTheme.Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .name:
            OnboardingStepView(title: "What's your name?", subtitle: "We'll use it to personalise your experience.") {
                TextField("Your name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.next)
                    .onSubmit { if canAdvance { withAnimation { nextStep() } } }
            }
        case .experience:
            OnboardingStepView(title: "Experience level", subtitle: "How long have you been strength training?") {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    SelectionRow(
                        title: level.displayName,
                        subtitle: level.subtitle,
                        isSelected: experienceLevel == level
                    ) { experienceLevel = level }
                }
            }
        case .goal:
            OnboardingStepView(title: "Primary goal", subtitle: "What are you training for?") {
                ForEach(PrimaryGoal.allCases, id: \.self) { goal in
                    SelectionRow(
                        title: goal.displayName,
                        subtitle: goal.subtitle,
                        isSelected: primaryGoal == goal
                    ) { primaryGoal = goal }
                }
            }
        case .gender:
            OnboardingStepView(title: "Biological sex", subtitle: "Used to personalise training recommendations.") {
                ForEach(Gender.allCases, id: \.self) { g in
                    SelectionRow(
                        title: g.displayName,
                        subtitle: nil,
                        isSelected: gender == g
                    ) { gender = g }
                }
            }
        case .cycle:
            OnboardingStepView(
                title: "Cycle-aware training",
                subtitle: "Sundee Fundee can adapt your programme to your menstrual cycle phases for optimised performance."
            ) {
                SelectionRow(
                    title: "Yes, enable cycle tracking",
                    subtitle: "Log your cycle and get phase-specific load adjustments.",
                    isSelected: cycleTrackingEnabled
                ) { cycleTrackingEnabled = true }

                SelectionRow(
                    title: "No thanks",
                    subtitle: "Follow the standard programme without cycle adjustments.",
                    isSelected: !cycleTrackingEnabled
                ) { cycleTrackingEnabled = false }
            }
        }
    }

    // MARK: - Navigation

    private var visibleSteps: [OnboardingStep] {
        if gender == .male { return OnboardingStep.allCases.filter { $0 != .cycle } }
        return OnboardingStep.allCases
    }

    private var isLastStep: Bool {
        step == visibleSteps.last
    }

    private var canAdvance: Bool {
        switch step {
        case .name: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }

    private func nextStep() {
        guard let current = visibleSteps.firstIndex(of: step) else { return }
        if current < visibleSteps.count - 1 {
            step = visibleSteps[current + 1]
        } else {
            saveAndFinish()
        }
    }

    private func previousStep() {
        guard let current = visibleSteps.firstIndex(of: step), current > 0 else { return }
        step = visibleSteps[current - 1]
    }

    // MARK: - Persistence

    private func saveAndFinish() {
        isSaving = true
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userID }
        )
        guard let user = (try? modelContext.fetch(descriptor))?.first else {
            isSaving = false; return
        }
        user.name = name.trimmingCharacters(in: .whitespaces)
        user.experienceLevel = experienceLevel
        user.primaryGoal = primaryGoal
        user.gender = gender
        user.cycleTrackingEnabled = gender != .male && cycleTrackingEnabled
        user.onboardingComplete = true
        user.profileUpdatedAt = .now
        try? modelContext.save()
        appState.apply(.authenticated(userID: userID))
        isSaving = false
    }
}

// MARK: - Sub-components

struct OnboardingStepView<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Font.heading(26))
                    .foregroundStyle(AppTheme.Color.navy)
                Text(subtitle)
                    .font(AppTheme.Font.body(15))
                    .foregroundStyle(AppTheme.Color.textSecondary)
            }
            content
        }
    }
}

struct SelectionRow: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(title)
                        .font(AppTheme.Font.body(16, weight: .semibold))
                        .foregroundStyle(AppTheme.Color.navy)
                    if let sub = subtitle {
                        Text(sub)
                            .font(AppTheme.Font.body(13))
                            .foregroundStyle(AppTheme.Color.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppTheme.Color.orange : AppTheme.Color.separator)
                    .font(.system(size: 22))
            }
            .padding(AppTheme.Spacing.md)
            .background(isSelected ? AppTheme.Color.orange.opacity(0.08) : AppTheme.Color.cardBg)
            .cornerRadius(AppTheme.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(isSelected ? AppTheme.Color.orange : AppTheme.Color.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Display name extensions

extension ExperienceLevel {
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    var subtitle: String {
        switch self {
        case .beginner: return "0–2 years of consistent training"
        case .intermediate: return "2–5 years of consistent training"
        case .advanced: return "5+ years of consistent training"
        }
    }
}

extension PrimaryGoal {
    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .hypertrophy: return "Muscle building"
        case .endurance: return "Endurance"
        case .weightLoss: return "Weight loss"
        }
    }
    var subtitle: String {
        switch self {
        case .strength: return "Maximise 1RM in key lifts"
        case .hypertrophy: return "Build muscle size and volume"
        case .endurance: return "Improve stamina and conditioning"
        case .weightLoss: return "Reduce body fat while maintaining muscle"
        }
    }
}

extension Gender {
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}
