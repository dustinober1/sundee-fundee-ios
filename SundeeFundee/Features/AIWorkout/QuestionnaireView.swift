import SwiftUI
import SwiftData

struct QuestionnaireView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var viewModel: QuestionnaireViewModel
    @State private var showPaywall = false
    let userID: String
    var onWorkoutGenerated: (GeneratedWorkout) -> Void = { _ in }

    init(userID: String, aiService: any AIWorkoutServiceProtocol, onWorkoutGenerated: @escaping (GeneratedWorkout) -> Void = { _ in }) {
        self.userID = userID
        self.onWorkoutGenerated = onWorkoutGenerated
        self._viewModel = State(initialValue: QuestionnaireViewModel(aiService: aiService))
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                pageIndicator

                TabView(selection: $viewModel.currentPage) {
                    page1.tag(0)
                    page2.tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentPage)

                footer
            }
        }
        .navigationTitle("New Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.checkUsageLimit(tier: appState.subscriptionTier) }
        .sheet(isPresented: $showPaywall) {
            PaywallView(triggeredBy: .unlimitedLifts)
        }
        .onChange(of: viewModel.generatedWorkout) { _, workout in
            if let workout {
                onWorkoutGenerated(workout)
            }
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(0..<2, id: \.self) { index in
                Capsule()
                    .fill(index == viewModel.currentPage ? AppTheme.Colors.accentOrange : AppTheme.Colors.separator)
                    .frame(width: index == viewModel.currentPage ? 24 : 8, height: 4)
            }
        }
        .padding(.top, AppTheme.Spacing.md)
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentPage)
    }

    // MARK: - Page 1: Time + Focus

    private var page1: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                sectionHeader("How long do you have?")

                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(QuestionnaireViewModel.timeOptions, id: \.self) { minutes in
                        timeChip(minutes: minutes)
                    }
                }

                sectionHeader("What's your focus?")

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: AppTheme.Spacing.sm) {
                    ForEach(WorkoutFocus.allCases, id: \.self) { focus in
                        focusCard(focus)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
        }
    }

    // MARK: - Page 2: Energy + Equipment

    private var page2: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                sectionHeader("How's your energy?")

                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(EnergyLevel.allCases, id: \.self) { level in
                        energyCard(level)
                    }
                }

                sectionHeader("What equipment do you have?")

                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(EquipmentAccess.allCases, id: \.self) { equip in
                        equipmentRow(equip)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.error)
            }

            if viewModel.currentPage == 0 {
                Button {
                    withAnimation { viewModel.currentPage = 1 }
                } label: {
                    Text("Next")
                        .font(AppTheme.Fonts.subheading)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.Colors.accentOrange)
            } else {
                if viewModel.isAtUsageLimit {
                    Button { showPaywall = true } label: {
                        HStack {
                            Text("Upgrade for More AI Workouts")
                                .font(AppTheme.Fonts.subheading)
                            PremiumBadge(tier: FeatureEntitlement.minimumTierRequired(for: .unlimitedLifts))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.sm)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.Colors.gold)
                } else {
                    Button {
                        Task {
                            await viewModel.generateWorkout(modelContext: modelContext, userID: userID, tier: appState.subscriptionTier)
                        }
                    } label: {
                        if viewModel.isGenerating {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.sm)
                        } else {
                            Text("Generate Workout")
                                .font(AppTheme.Fonts.subheading)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.sm)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.Colors.accentOrange)
                    .disabled(viewModel.isGenerating || !viewModel.canGenerate)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cream)
    }

    // MARK: - Subviews

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Fonts.heading)
            .foregroundStyle(AppTheme.Colors.navy)
    }

    private func timeChip(minutes: Int) -> some View {
        let isSelected = viewModel.timeMinutes == minutes
        return Button {
            viewModel.timeMinutes = minutes
        } label: {
            Text(Self.timeLabel(minutes: minutes))
                .font(AppTheme.Fonts.body)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(isSelected ? AppTheme.Colors.accentOrange : AppTheme.Colors.cardBackground)
                .foregroundStyle(isSelected ? .white : AppTheme.Colors.textPrimary)
                .cornerRadius(AppTheme.CornerRadius.button)
        }
    }

    static func timeLabel(minutes: Int) -> String {
        minutes >= 75 ? "75+" : "\(minutes)"
    }

    private func focusCard(_ focus: WorkoutFocus) -> some View {
        let isSelected = viewModel.focus == focus
        return Button {
            viewModel.focus = focus
        } label: {
            Text(focus.displayName)
                .font(AppTheme.Fonts.body)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(isSelected ? AppTheme.Colors.accentOrange : AppTheme.Colors.cardBackground)
                .foregroundStyle(isSelected ? .white : AppTheme.Colors.textPrimary)
                .cornerRadius(AppTheme.CornerRadius.card)
        }
    }

    private func energyCard(_ level: EnergyLevel) -> some View {
        let isSelected = viewModel.energyLevel == level
        return Button {
            viewModel.energyLevel = level
        } label: {
            VStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: level.icon)
                    .font(.title2)
                Text(level.displayName)
                    .font(AppTheme.Fonts.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(isSelected ? AppTheme.Colors.accentOrange : AppTheme.Colors.cardBackground)
            .foregroundStyle(isSelected ? .white : AppTheme.Colors.textPrimary)
            .cornerRadius(AppTheme.CornerRadius.card)
        }
    }

    private func equipmentRow(_ equip: EquipmentAccess) -> some View {
        let isSelected = viewModel.equipment == equip
        return Button {
            viewModel.equipment = equip
        } label: {
            HStack {
                Image(systemName: equip.icon)
                    .font(.title3)
                    .frame(width: 32)
                Text(equip.displayName)
                    .font(AppTheme.Fonts.body)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(isSelected ? AppTheme.Colors.accentOrange.opacity(0.1) : AppTheme.Colors.cardBackground)
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .cornerRadius(AppTheme.CornerRadius.card)
        }
    }
}
