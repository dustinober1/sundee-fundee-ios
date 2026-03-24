import SwiftUI
import SwiftData

/// Multi-step onboarding flow:
///   1. Experience level
///   2. Primary goal
///   3. Gender
///   4. Cycle tracking opt-in (shown only for female/prefer-not-to-say)
///
/// Name is collected automatically from Sign in with Apple credentials.
struct OnboardingFlowView: View {
    let userID: String

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var step: OnboardingStep = .experience
    @State private var experienceLevel: ExperienceLevel = .beginner
    @State private var primaryGoal: PrimaryGoal = .strength
    @State private var gender: Gender = .preferNotToSay
    @State private var cycleTrackingEnabled: Bool = false
    @State private var isSaving = false

    init(
        userID: String,
        initialStep: OnboardingStep = .experience,
        initialExperienceLevel: ExperienceLevel = .beginner,
        initialPrimaryGoal: PrimaryGoal = .strength,
        initialGender: Gender = .preferNotToSay,
        initialCycleTrackingEnabled: Bool = false,
        initialIsSaving: Bool = false
    ) {
        self.userID = userID
        _step = State(initialValue: initialStep)
        _experienceLevel = State(initialValue: initialExperienceLevel)
        _primaryGoal = State(initialValue: initialPrimaryGoal)
        _gender = State(initialValue: initialGender)
        _cycleTrackingEnabled = State(initialValue: initialCycleTrackingEnabled)
        _isSaving = State(initialValue: initialIsSaving)
    }

    enum OnboardingStep: Int, CaseIterable {
        case experience, goal, gender, cycle
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
                    navigationButtons
                        .padding(AppTheme.Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Navigation Buttons

    @ViewBuilder
    private var navigationButtons: some View {
        HStack {
            if Self.showsBackButton(for: step) {
                Button("Back", action: previousStepAnimatedAction)
                    .foregroundStyle(AppTheme.Color.textSecondary)
            }
            Spacer()
            Button(Self.actionTitle(for: step, gender: gender), action: nextStepAnimatedAction)
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canAdvance || isSaving)
        }
    }

    // MARK: - Step content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .experience:
            OnboardingStepView(title: "Experience level", subtitle: "How long have you been strength training?") {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    SelectionRow(
                        title: level.displayName,
                        subtitle: level.subtitle,
                        isSelected: experienceLevel == level
                    , action: Self.selectionAction(binding: $experienceLevel, value: level))
                }
            }
        case .goal:
            OnboardingStepView(title: "Primary goal", subtitle: "What are you training for?") {
                ForEach(PrimaryGoal.allCases, id: \.self) { goal in
                    SelectionRow(
                        title: goal.displayName,
                        subtitle: goal.subtitle,
                        isSelected: primaryGoal == goal
                    , action: Self.selectionAction(binding: $primaryGoal, value: goal))
                }
            }
        case .gender:
            OnboardingStepView(title: "Biological sex", subtitle: "Used to personalise training recommendations.") {
                ForEach(Gender.allCases, id: \.self) { g in
                    SelectionRow(
                        title: g.displayName,
                        subtitle: nil,
                        isSelected: gender == g
                    , action: Self.selectionAction(binding: $gender, value: g))
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
                , action: Self.selectionAction(binding: $cycleTrackingEnabled, value: true))

                SelectionRow(
                    title: "No thanks",
                    subtitle: "Follow the standard programme without cycle adjustments.",
                    isSelected: !cycleTrackingEnabled
                , action: Self.selectionAction(binding: $cycleTrackingEnabled, value: false))
            }
        }
    }

    // MARK: - Navigation

    static func visibleSteps(for gender: Gender) -> [OnboardingStep] {
        if gender == .male { return OnboardingStep.allCases.filter { $0 != .cycle } }
        return OnboardingStep.allCases
    }

    static func showsBackButton(for step: OnboardingStep) -> Bool {
        step != OnboardingStep.allCases.first
    }

    static func actionTitle(for step: OnboardingStep, gender: Gender) -> String {
        isLastStep(step, gender: gender) ? "Get Started" : "Next"
    }

    static func isLastStep(_ step: OnboardingStep, gender: Gender) -> Bool {
        step == visibleSteps(for: gender).last
    }

    static func nextVisibleStep(from step: OnboardingStep, gender: Gender) -> OnboardingStep? {
        let steps = visibleSteps(for: gender)
        guard let current = steps.firstIndex(of: step), current < steps.count - 1 else { return nil }
        return steps[current + 1]
    }

    static func previousVisibleStep(from step: OnboardingStep, gender: Gender) -> OnboardingStep? {
        let steps = visibleSteps(for: gender)
        guard let current = steps.firstIndex(of: step), current > 0 else { return nil }
        return steps[current - 1]
    }

    nonisolated static func resolvedCycleTrackingEnabled(gender: Gender, requestedValue: Bool) -> Bool {
        gender != .male && requestedValue
    }

    static func selectionAction<T: Equatable>(binding: Binding<T>, value: T) -> () -> Void {
        { binding.wrappedValue = value }
    }

    nonisolated static func applyOnboardingAnswers(
        to user: User,
        experienceLevel: ExperienceLevel,
        primaryGoal: PrimaryGoal,
        gender: Gender,
        cycleTrackingEnabled: Bool,
        updatedAt: Date = .now
    ) {
        user.experienceLevel = experienceLevel
        user.primaryGoal = primaryGoal
        user.gender = gender
        user.cycleTrackingEnabled = resolvedCycleTrackingEnabled(
            gender: gender,
            requestedValue: cycleTrackingEnabled
        )
        user.onboardingComplete = true
        user.profileUpdatedAt = updatedAt
    }

    @MainActor
    @discardableResult
    static func persistOnboardingAnswers(
        userID: String,
        experienceLevel: ExperienceLevel,
        primaryGoal: PrimaryGoal,
        gender: Gender,
        cycleTrackingEnabled: Bool,
        modelContext: ModelContext,
        appState: AppState,
        updatedAt: Date = .now
    ) -> Bool {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userID }
        )
        guard let user = (try? modelContext.fetch(descriptor))?.first else { return false }
        applyOnboardingAnswers(
            to: user,
            experienceLevel: experienceLevel,
            primaryGoal: primaryGoal,
            gender: gender,
            cycleTrackingEnabled: cycleTrackingEnabled,
            updatedAt: updatedAt
        )
        try? modelContext.save()
        appState.apply(.authenticated(userID: userID))
        return true
    }

    private var visibleSteps: [OnboardingStep] {
        Self.visibleSteps(for: gender)
    }

    private var canAdvance: Bool {
        true
    }

    var currentStep: OnboardingStep {
        step
    }

    var isSavingState: Bool {
        isSaving
    }

    @discardableResult
    func nextStepAnimated() -> Bool {
        withAnimation { nextStep() }
    }

    @discardableResult
    func previousStepAnimated() -> Bool {
        withAnimation { previousStep() }
    }

    @discardableResult
    func nextStep(saveAndFinish: () -> Void) -> Bool {
        if let next = Self.nextVisibleStep(from: step, gender: gender) {
            step = next
            return true
        }
        saveAndFinish()
        return false
    }

    @discardableResult
    func nextStep() -> Bool {
        guard let next = Self.nextVisibleStep(from: step, gender: gender) else { return false }
        step = next
        return true
    }

    @discardableResult
    func nextStepWithPersistence(appState: AppState, modelContext: ModelContext) -> Bool {
        nextStep(saveAndFinish: { _ = saveAndFinish(appState: appState, modelContext: modelContext) })
    }

    @discardableResult
    func previousStep() -> Bool {
        guard let previous = Self.previousVisibleStep(from: step, gender: gender) else { return false }
        step = previous
        return true
    }

    // MARK: - Persistence

    @discardableResult
    func saveAndFinish(
        persistAnswers: (
            _ userID: String,
            _ experienceLevel: ExperienceLevel,
            _ primaryGoal: PrimaryGoal,
            _ gender: Gender,
            _ cycleTrackingEnabled: Bool
        ) -> Bool
    ) -> Bool {
        isSaving = true
        let persisted = persistAnswers(
            userID,
            experienceLevel,
            primaryGoal,
            gender,
            cycleTrackingEnabled
        )
        isSaving = false
        return persisted
    }

    @discardableResult
    func saveAndFinish(appState: AppState, modelContext: ModelContext) -> Bool {
        saveAndFinish { userID, experienceLevel, primaryGoal, gender, cycleTrackingEnabled in
            Self.persistOnboardingAnswers(
                userID: userID,
                experienceLevel: experienceLevel,
                primaryGoal: primaryGoal,
                gender: gender,
                cycleTrackingEnabled: cycleTrackingEnabled,
                modelContext: modelContext,
                appState: appState
            )
        }
    }

    func previousStepAnimatedAction() { _ = previousStepAnimated() }
    func nextStepAnimatedAction() {
        _ = withAnimation {
            Self.isLastStep(currentStep, gender: gender)
                ? nextStepWithPersistence(appState: appState, modelContext: modelContext)
                : nextStep()
        }
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
