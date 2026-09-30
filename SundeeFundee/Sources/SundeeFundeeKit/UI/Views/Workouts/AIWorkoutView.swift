import SwiftUI

struct AIWorkoutEquipmentDefaultSelection: Equatable, Sendable {
    let equipment: EquipmentAccess
    let selectedProfileID: String?
}

enum AIWorkoutEquipmentDefaultResolver {
    static func resolve(
        profiles: [EquipmentProfile],
        hasPersistedProfiles: Bool,
        legacyDefaultEquipment: EquipmentAccess?
    ) -> AIWorkoutEquipmentDefaultSelection {
        if hasPersistedProfiles {
            return selection(from: profiles, fallbackEquipment: legacyDefaultEquipment ?? .fullGym)
        }

        if let legacyDefaultEquipment {
            return AIWorkoutEquipmentDefaultSelection(
                equipment: legacyDefaultEquipment,
                selectedProfileID: profiles.first { $0.equipment == legacyDefaultEquipment }?.id
            )
        }

        return selection(from: profiles, fallbackEquipment: .fullGym)
    }

    private static func selection(
        from profiles: [EquipmentProfile],
        fallbackEquipment: EquipmentAccess
    ) -> AIWorkoutEquipmentDefaultSelection {
        let profile = profiles.first(where: \.isDefault) ?? profiles.first
        return AIWorkoutEquipmentDefaultSelection(
            equipment: profile?.equipment ?? fallbackEquipment,
            selectedProfileID: profile?.id
        )
    }
}

// MARK: - AIWorkoutView
//
// Questionnaire-based Coach Plan flow.
// Collects preferences, generates a workout using domain logic,
// and presents it for review before starting.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct AIWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AIWorkoutViewModel()
    private let onClose: (() -> Void)?
    @State private var activeWorkoutSession: ActiveWorkoutSessionViewModel?

    init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.state {
                case .questionnaire:
                    questionnaireView
                case .generating:
                    generatingView
                case .preview:
                    previewView
                case .error(let message):
                    errorView(message)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(nil, value: viewModel.state)
            .navigationTitle("Coach Plan")
            .screenshotModeBenefitBanner(caption: ScreenshotMode.caption(for: .train))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { close() }
                }
            }
            #if os(iOS)
            .fullScreenCover(item: $activeWorkoutSession) { session in
                ActiveWorkoutView(viewModel: session)
            }
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutCompleted)) { _ in
            activeWorkoutSession = nil
            close()
        }
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    // MARK: - Questionnaire

    private var questionnaireView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(AppTheme.Accent.gold)
                        .accessibilityHidden(true)

                    Text("Build Coach Plan")
                        .font(AppTheme.Typography.displaySmall)
                        .foregroundColor(AppTheme.Text.primary)

                    Text("Answer a few questions and we'll build a personalized workout")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppTheme.Spacing.lg)

                // Cycle Phase (if available and not hidden by gym privacy)
                if let phase = viewModel.cyclePhase, !SharedSnapshotStore.readGymPrivacyEnabled() {
                    cyclePhaseCard(phase)
                }

                // Time
                ArtDecoCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Label("How long?", systemImage: "clock")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        Picker("Duration", selection: $viewModel.timeMinutes) {
                            Text("20 min").tag(20)
                            Text("30 min").tag(30)
                            Text("45 min").tag(45)
                            Text("60 min").tag(60)
                            Text("75 min").tag(75)
                            Text("90 min").tag(90)
                        }
                        #if !os(watchOS)
                        .pickerStyle(.segmented)
                        #endif
                    }
                }

                // Focus
                ArtDecoCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Label("Focus area", systemImage: "figure.strengthtraining.traditional")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AppTheme.Spacing.sm) {
                            focusOption(.upperBody, "Upper Body", "figure.arms.open")
                            focusOption(.lowerBody, "Lower Body", "figure.walk")
                            focusOption(.fullBody, "Full Body", "figure.mixed.cardio")
                            focusOption(.push, "Push", "arrow.up.circle")
                            focusOption(.pull, "Pull", "arrow.down.circle")
                            focusOption(.conditioning, "Conditioning", "flame")
                        }
                    }
                }

                // Energy Level
                ArtDecoCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Label("Energy today?", systemImage: "bolt")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        HStack(spacing: AppTheme.Spacing.md) {
                            energyOption(.low, "Low", "battery.25")
                            energyOption(.medium, "Medium", "battery.50")
                            energyOption(.high, "High", "battery.100")
                        }
                    }
                }

                // Equipment
                ArtDecoCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Label("Equipment access", systemImage: "dumbbell")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        VStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(viewModel.equipmentProfiles) { profile in
                                equipmentProfileOption(profile)
                            }

                            ForEach(EquipmentAccess.userSelectableDefaults, id: \.self) { equipment in
                                equipmentOption(equipment, equipment.displayName, equipment.shortDescription)
                            }
                        }
                    }
                }

                // Build Button
                Button {
                    Task { await viewModel.generateWorkout() }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Build Coach Plan")
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ArtDecoButtonStyle(style: .accent))
                .accessibilityHint("Create a personalized workout based on your selections")
            }
            .padding(AppTheme.Spacing.lg)
        }
        .artDecoBackground()
        .task {
            await viewModel.loadContext()
        }
    }

    // MARK: - Cycle Phase Card

    private func cyclePhaseCard(_ phase: CyclePhase) -> some View {
        ArtDecoCard {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: phaseIcon(phase))
                    .font(.headline)
                    .foregroundColor(phaseColor(phase))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Current Phase")
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Text.secondary)

                    Text(phaseName(phase))
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)
                }

                Spacer()

                Text(String(format: "%.0f%%", aiCyclePhaseMultiplier(phase) * 100))
                    .font(AppTheme.Typography.monoLarge)
                    .foregroundColor(AppTheme.Accent.gold)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.Accent.goldLight)
                    .cornerRadius(AppTheme.CornerRadius.small)
                    .accessibilityLabel("Cycle phase multiplier: \(Int(aiCyclePhaseMultiplier(phase) * 100)) percent")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current phase: \(phaseName(phase)), multiplier \(Int(aiCyclePhaseMultiplier(phase) * 100)) percent")
    }

    // MARK: - Option Buttons

    private func focusOption(_ focus: WorkoutFocus, _ title: String, _ icon: String) -> some View {
        Button {
            viewModel.focus = focus
        } label: {
            VStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.headline)
                Text(title)
                    .font(AppTheme.Typography.labelMedium)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.md)
            .foregroundColor(viewModel.focus == focus ? AppTheme.Text.cream : AppTheme.Text.primary)
            .background(viewModel.focus == focus ? AppTheme.Background.navy : AppTheme.Background.cream.opacity(0.5))
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Select \(title) focus area")
    }

    private func energyOption(_ level: EnergyLevel, _ title: String, _ icon: String) -> some View {
        Button {
            viewModel.energyLevel = level
        } label: {
            VStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.headline)
                Text(title)
                    .font(AppTheme.Typography.labelMedium)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.md)
            .foregroundColor(viewModel.energyLevel == level ? AppTheme.Text.cream : AppTheme.Text.primary)
            .background(viewModel.energyLevel == level ? AppTheme.Background.navy : AppTheme.Background.cream.opacity(0.5))
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Select \(title) energy level")
    }

    private func equipmentProfileOption(_ profile: EquipmentProfile) -> some View {
        Button {
            viewModel.selectEquipmentProfile(profile)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(AppTheme.Typography.bodyMedium)
                    Text(profile.isDefault ? "Default - \(profile.equipment.displayName)" : profile.equipment.displayName)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                Spacer()

                Image(systemName: viewModel.selectedEquipmentProfileID == profile.id ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(
                        viewModel.selectedEquipmentProfileID == profile.id
                            ? AppTheme.Accent.gold
                            : AppTheme.Text.secondary.opacity(0.3)
                    )
            }
            .padding(AppTheme.Spacing.md)
            .foregroundColor(AppTheme.Text.primary)
            .background(
                viewModel.selectedEquipmentProfileID == profile.id
                    ? AppTheme.Accent.goldLight
                    : AppTheme.Background.cream.opacity(0.3)
            )
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Select \(profile.name) equipment profile")
    }

    private func equipmentOption(_ equipment: EquipmentAccess, _ title: String, _ subtitle: String) -> some View {
        Button {
            viewModel.selectRawEquipment(equipment)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.bodyMedium)
                    Text(subtitle)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                Spacer()

                Image(systemName: viewModel.isRawEquipmentSelected(equipment) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(
                        viewModel.isRawEquipmentSelected(equipment)
                            ? AppTheme.Accent.gold
                            : AppTheme.Text.secondary.opacity(0.3)
                    )
            }
            .padding(AppTheme.Spacing.md)
            .foregroundColor(AppTheme.Text.primary)
            .background(
                viewModel.isRawEquipmentSelected(equipment)
                    ? AppTheme.Accent.goldLight
                    : AppTheme.Background.cream.opacity(0.3)
            )
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Select \(title) equipment access")
    }

    // MARK: - Generating

    private var generatingView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            ProgressView("Building your Coach Plan…")
                .scaleEffect(1.5)
                .tint(AppTheme.Accent.gold)
                .accessibilityLabel("Building your Coach Plan")

            Text("Building your Coach Plan…")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            if SharedSnapshotStore.readGymPrivacyEnabled() {
                Text("Optimizing for recovery and performance")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            } else {
                Text("Optimizing for \(phaseName(viewModel.cyclePhase)) phase")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .artDecoBackground()
    }

    // MARK: - Preview

    private var previewView: some View {
        ScrollView {
            if let generated = viewModel.generatedWorkout {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Summary
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(AppTheme.Accent.gold)
                                Text("Coach Plan")
                                    .font(AppTheme.Typography.headlineMedium)
                                    .foregroundColor(AppTheme.Text.primary)
                            }

                            Text(generated.coachingSummary)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Text.secondary)

                            HStack(spacing: AppTheme.Spacing.lg) {
                                Label("\(generated.exercises.count) exercises", systemImage: "figure.strengthtraining.traditional")
                                Label("\(totalEstimatedMinutes(generated.exercises)) min", systemImage: "clock")
                            }
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)

                            // Muscle Groups
                            let groups = extractMuscleGroups(generated.exercises)
                            if !groups.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppTheme.Spacing.xs) {
                                        ForEach(groups, id: \.self) { group in
                                            Text(group)
                                                .font(AppTheme.Typography.labelMedium)
                                                .foregroundColor(AppTheme.Accent.gold)
                                                .padding(.horizontal, AppTheme.Spacing.sm)
                                                .padding(.vertical, 2)
                                                .background(AppTheme.Accent.goldLight)
                                                .cornerRadius(AppTheme.CornerRadius.small)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if let rationale = viewModel.workoutRationale {
                        rationaleCard(rationale)
                        if !coachPlanTrustBadges.isEmpty {
                            coachPlanTrustBadgeRow
                        }
                    }

                    feedbackRow

                    if !viewModel.changeNotes.isEmpty {
                        whyChangedCard(viewModel.changeNotes)
                    }

                    quickEditCard

                    // Coaching Tips
                    if !viewModel.coachingTips.isEmpty {
                        ArtDecoCard {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                Label("Tips", systemImage: "lightbulb.fill")
                                    .font(AppTheme.Typography.labelMedium)
                                    .foregroundColor(AppTheme.Accent.gold)

                                ForEach(viewModel.coachingTips, id: \.self) { tip in
                                    Text("• \(tip)")
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Text.secondary)
                                }
                            }
                        }
                    }

                    // Exercises
                    ForEach(generated.exercises) { exercise in
                        generatedExerciseCard(exercise)
                    }

                    // Actions
                    VStack(spacing: AppTheme.Spacing.md) {
                        Button {
                            if let workout = viewModel.buildWorkoutForSession() {
                                Task { await viewModel.trackWorkoutStarted() }
                                activeWorkoutSession = ActiveWorkoutSessionViewModel(workout: workout)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start This Workout")
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ArtDecoButtonStyle(style: .accent))
                        .accessibilityHint("Begin this Coach Plan now")

                        Button {
                            Task { await viewModel.generateWorkout() }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Rebuild Plan")
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ArtDecoButtonStyle(style: .secondary))
                        .accessibilityHint("Build a different Coach Plan")
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
        }
        .artDecoBackground()
        .sheet(isPresented: Binding(
            get: { viewModel.swapState != nil },
            set: { if !$0 { viewModel.dismissSwap() } }
        )) {
            substitutionSheet
        }
    }

    private var quickEditCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Label("Quick Edits", systemImage: "slider.horizontal.3")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Accent.gold)

                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach([20, 30, 45], id: \.self) { minutes in
                        Button {
                            viewModel.shortenWorkout(to: minutes)
                        } label: {
                            Text("\(minutes)m")
                                .frame(maxWidth: .infinity)
                        }
                        .artDecoButton(style: .secondary)
                        .accessibilityLabel("Shorten to \(minutes) minutes")
                    }
                }

                HStack(spacing: AppTheme.Spacing.sm) {
                    Button {
                        viewModel.reduceVolume()
                    } label: {
                        Label("Reduce Volume", systemImage: "minus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .artDecoButton(style: .secondary)

                    Button {
                        viewModel.restoreOriginalWorkout()
                    } label: {
                        Label("Restore", systemImage: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity)
                    }
                    .artDecoButton(style: .ghost)
                }
            }
        }
    }

    private func generatedExerciseCard(_ exercise: GeneratedExercise) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    Text(exercise.name)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Spacer()

                    if exercise.bodyweightOnly {
                        Text("BW")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Accent.gold)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 2)
                            .background(AppTheme.Accent.goldLight)
                            .cornerRadius(AppTheme.CornerRadius.small)
                    }

                    Button {
                        Task { await viewModel.loadSubstitutions(for: exercise.id) }
                    } label: {
                        Image(systemName: "arrow.2.squarepath")
                            .font(.footnote)
                            .foregroundColor(AppTheme.Accent.gold)
                    }
                    .accessibilityLabel("Swap \(exercise.name)")
                    .accessibilityHint("Replace this exercise with an alternative")

                    Button {
                        viewModel.removeExercise(id: exercise.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.footnote)
                            .foregroundColor(AppTheme.Semantic.warning)
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canRemoveExercise)
                    .opacity(viewModel.canRemoveExercise ? 1 : 0.35)
                    .accessibilityLabel("Remove \(exercise.name)")
                    .accessibilityHint("Remove this exercise from the plan")
                }

                HStack(spacing: AppTheme.Spacing.lg) {
                    Label("\(exercise.sets) sets", systemImage: "square.stack.3d.up")
                    Label("\(exercise.reps) reps", systemImage: "repeat")

                    if let weight = exercise.weightKg, weight > 0 {
                        Label("\(Int(weight)) lb", systemImage: "scalemass")
                    }

                    if let pct = exercise.percentageOfMax {
                        Text("\(Int(pct * 100))% max")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Accent.gold)
                    } else if exercise.weightKg == nil || exercise.weightKg == 0, !exercise.bodyweightOnly {
                        Text("Enter weight")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                    }

                    if let rest = exercise.restMinutes {
                        Label("\(rest, specifier: "%.1f")m rest", systemImage: "clock")
                    }
                }
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)

                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                        .italic()
                }

                if let reasoning = exercise.reasoning, !reasoning.isEmpty {
                    HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundColor(AppTheme.Accent.gold)

                        Text(reasoning)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Accent.gold)
                    }
                }
            }
        }
    }

    private var feedbackRow: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text("Was this useful?")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.secondary)

            Spacer()

            Button {
                Task { await viewModel.submitFeedback(.helpful) }
            } label: {
                Image(systemName: viewModel.submittedFeedback == .helpful ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.title3)
                    .foregroundColor(AppTheme.Accent.gold)
            }
            .accessibilityLabel("Coach Plan was useful")

            Button {
                Task { await viewModel.submitFeedback(.notHelpful) }
            } label: {
                Image(systemName: viewModel.submittedFeedback == .notHelpful ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .font(.title3)
                    .foregroundColor(AppTheme.Text.secondary)
            }
            .accessibilityLabel("Coach Plan was not useful")
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
    }

    private var coachPlanTrustBadges: [WorkoutTrustBadge] {
        guard let rationale = viewModel.workoutRationale else { return [] }
        return WorkoutTrustBadgeBuilder.badges(
            reasons: [rationale.headline] + rationale.reasons + rationale.cautions,
            cyclePhase: viewModel.cyclePhase,
            cycleConfidence: nil,
            deloadRecommended: rationale.cautions.contains {
                $0.localizedCaseInsensitiveContains("recovery")
            }
        )
    }

    private var coachPlanTrustBadgeRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(coachPlanTrustBadges) { badge in
                    Label(badge.title, systemImage: badge.systemImage)
                        .font(AppTheme.Typography.labelMedium)
                        .foregroundColor(AppTheme.Text.primary)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.Accent.goldLight)
                        .cornerRadius(AppTheme.CornerRadius.small)
                        .accessibilityLabel("\(badge.title), \(badge.detail)")
                }
            }
        }
    }

    private func whyChangedCard(_ notes: [WorkoutChangeNote]) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Label("Why this changed", systemImage: "info.circle")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Accent.gold)

                ForEach(notes) { note in
                    HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                        Image(systemName: note.systemImage)
                            .font(.headline)
                            .foregroundColor(AppTheme.Accent.gold)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(note.title)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Text.primary)

                            Text(note.message)
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func rationaleCard(_ rationale: WorkoutRationale) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Label("Why this workout?", systemImage: "questionmark.circle")
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Accent.gold)

                Text(rationale.headline)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)

                ForEach(rationale.reasons.prefix(4), id: \.self) { reason in
                    Text("• \(reason)")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                ForEach(rationale.cautions.prefix(2), id: \.self) { caution in
                    Text(caution)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Semantic.warning)
                }
            }
        }
    }

    // MARK: - Substitution Sheet

    private var substitutionSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    if let swap = viewModel.swapState {
                        if swap.isLoading {
                            VStack(spacing: AppTheme.Spacing.md) {
                                Spacer().frame(height: 40)
                                ProgressView()
                                    .tint(AppTheme.Accent.gold)
                                    .accessibilityLabel("Finding alternatives")
                                Text("Finding alternatives...")
                                    .font(AppTheme.Typography.bodyMedium)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }
                        } else if swap.substitutions.isEmpty {
                            VStack(spacing: AppTheme.Spacing.md) {
                                Spacer().frame(height: 40)
                                Image(systemName: "xmark.circle")
                                    .font(.title)
                                    .foregroundColor(AppTheme.Text.secondary)
                                Text("No alternatives found")
                                    .font(AppTheme.Typography.headlineMedium)
                                    .foregroundColor(AppTheme.Text.primary)
                                Text("Try regenerating the full workout instead.")
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                Text("Replace \(swap.exerciseName)")
                                    .font(AppTheme.Typography.headlineMedium)
                                    .foregroundColor(AppTheme.Text.primary)

                                if let explanation = swap.explanation {
                                    Text(explanation)
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Text.secondary)
                                }
                            }
                            .padding(.top, AppTheme.Spacing.sm)

                            ForEach(swap.substitutions, id: \.exerciseName) { sub in
                                Button {
                                    viewModel.swapExercise(with: sub)
                                } label: {
                                    ArtDecoCard {
                                        HStack {
                                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                                Text(sub.exerciseName)
                                                    .font(AppTheme.Typography.bodyMedium)
                                                    .foregroundColor(AppTheme.Text.primary)
                                                    .multilineTextAlignment(.leading)

                                                Text(sub.reason)
                                                    .font(AppTheme.Typography.bodySmall)
                                                    .foregroundColor(AppTheme.Text.secondary)
                                                    .multilineTextAlignment(.leading)
                                            }

                                            Spacer()

                                            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                                                Text("\(Int(sub.score * 100))%")
                                                    .font(AppTheme.Typography.monoLarge)
                                                    .foregroundColor(AppTheme.Accent.gold)

                                                Text("match")
                                                    .font(AppTheme.Typography.labelMedium)
                                                    .foregroundColor(AppTheme.Text.secondary)
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Swap with \(sub.exerciseName), \(Int(sub.score * 100))% match")
                                .accessibilityHint("Replace current exercise with this alternative")
                            }
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .artDecoBackground()
            .navigationTitle("Swap Exercise")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.dismissSwap() }
                }
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(.largeTitle))
                .foregroundColor(AppTheme.Semantic.warning)

            Text("Generation Failed")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            Text(message)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                viewModel.state = .questionnaire
            }
            .artDecoButton(style: .primary)

            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
        .artDecoBackground()
    }

    // MARK: - Phase Helpers

    private func phaseIcon(_ phase: CyclePhase?) -> String {
        guard let phase else { return "circle" }
        switch phase {
        case .menstrual: return "drop.fill"
        case .follicular: return "sun.max.fill"
        case .ovulation: return "sparkles"
        case .luteal: return "moon.fill"
        }
    }

    private func phaseColor(_ phase: CyclePhase?) -> Color {
        guard let phase else { return AppTheme.Text.secondary }
        switch phase {
        case .menstrual: return AppTheme.Semantic.error
        case .follicular: return AppTheme.Accent.gold
        case .ovulation: return AppTheme.Accent.orange
        case .luteal: return AppTheme.Text.secondary
        }
    }

    private func phaseName(_ phase: CyclePhase?) -> String {
        guard let phase else { return "Normal" }
        switch phase {
        case .menstrual: return "Menstrual"
        case .follicular: return "Follicular"
        case .ovulation: return "Ovulation"
        case .luteal: return "Luteal"
        }
    }
}
