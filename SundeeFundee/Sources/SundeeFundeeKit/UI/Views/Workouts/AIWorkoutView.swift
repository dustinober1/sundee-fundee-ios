import SwiftUI

// MARK: - AIWorkoutView
//
// Questionnaire-based AI workout generation flow.
// Collects preferences, generates a workout using domain logic,
// and presents it for review before starting.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct AIWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AIWorkoutViewModel()

    var body: some View {
        NavigationStack {
            Group {
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
            .navigationTitle("AI Workout")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Questionnaire

    private var questionnaireView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Header
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundColor(AppTheme.Accent.gold)
                        .accessibilityHidden(true)

                    Text("Generate Your Workout")
                        .font(AppTheme.Typography.displaySmall)
                        .foregroundColor(AppTheme.Text.primary)

                    Text("Answer a few questions and we'll build a personalized workout")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppTheme.Spacing.lg)

                // Cycle Phase (if available)
                if let phase = viewModel.cyclePhase {
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
                        .pickerStyle(.segmented)
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
                            equipmentOption(.fullGym, "Full Gym", "All equipment available")
                            equipmentOption(.homeDumbbells, "Home Dumbbells", "Dumbbells and bench")
                            equipmentOption(.bodyweightOnly, "Bodyweight Only", "No equipment")
                        }
                    }
                }

                // Generate Button
                Button {
                    Task { await viewModel.generateWorkout() }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate Workout")
                    }
                    .frame(maxWidth: .infinity)
                }
                .artDecoButton(style: .accent)
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
                    .font(.system(size: 20))
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
                    .font(.system(size: 20))
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
                    .font(.system(size: 20))
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

    private func equipmentOption(_ equipment: EquipmentAccess, _ title: String, _ subtitle: String) -> some View {
        Button {
            viewModel.equipment = equipment
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

                Image(systemName: viewModel.equipment == equipment ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(viewModel.equipment == equipment ? AppTheme.Accent.gold : AppTheme.Text.secondary.opacity(0.3))
            }
            .padding(AppTheme.Spacing.md)
            .foregroundColor(AppTheme.Text.primary)
            .background(viewModel.equipment == equipment ? AppTheme.Accent.goldLight : AppTheme.Background.cream.opacity(0.3))
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Select \(title) equipment access")
    }

    // MARK: - Generating

    private var generatingView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.Accent.gold)

            Text("Generating your workout...")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            Text("Optimizing for \(phaseName(viewModel.cyclePhase)) phase")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)

            Spacer()
        }
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
                                Text("AI Workout")
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
                            Task {
                                await viewModel.startGeneratedWorkout()
                                NotificationCenter.default.post(name: .aiWorkoutStarted, object: nil)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start This Workout")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .artDecoButton(style: .accent)
                        .accessibilityHint("Begin the generated workout now")

                        Button {
                            Task { await viewModel.generateWorkout() }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Regenerate")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .artDecoButton(style: .secondary)
                        .accessibilityHint("Generate a different workout")
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
        }
        .artDecoBackground()
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
                }

                HStack(spacing: AppTheme.Spacing.lg) {
                    Label("\(exercise.sets) sets", systemImage: "square.stack.3d.up")
                    Label("\(exercise.reps) reps", systemImage: "repeat")

                    if let weight = exercise.weightKg, weight > 0 {
                        Label("\(Int(weight)) lb", systemImage: "scalemass")
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
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.Accent.gold)

                        Text(reasoning)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Accent.gold)
                    }
                }
            }
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
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
        case .menstrual: return .red
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

// MARK: - AIWorkoutViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class AIWorkoutViewModel: ObservableObject {
    enum ViewState: Equatable {
        case questionnaire
        case generating
        case preview
        case error(String)
    }

    @Published var state: ViewState = .questionnaire
    @Published var timeMinutes: Int = 45
    @Published var focus: WorkoutFocus = .fullBody
    @Published var energyLevel: EnergyLevel = .medium
    @Published var equipment: EquipmentAccess = .fullGym
    @Published var cyclePhase: CyclePhase?
    @Published var generatedWorkout: GeneratedWorkout?
    @Published var coachingTips: [String] = []

    private let coachService: CoachServiceProtocol
    private let contextBuilder: CoachContextBuilder
    private let memoryService: CoachMemoryService
    private let dataClient: DataClientProtocol

    init(
        coachService: CoachServiceProtocol = CoachServiceFactory.makeService(),
        contextBuilder: CoachContextBuilder = CoachContextBuilder(),
        memoryService: CoachMemoryService = CoachMemoryService(),
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.coachService = coachService
        self.contextBuilder = contextBuilder
        self.memoryService = memoryService
        self.dataClient = dataClient
    }

    func loadContext() async {
        let context = await contextBuilder.build(equipment: equipment)
        cyclePhase = context.cyclePhase
    }

    func generateWorkout() async {
        state = .generating

        let questionnaire = QuestionnaireAnswers(
            timeMinutes: timeMinutes,
            focus: focus,
            energyLevel: energyLevel,
            equipment: equipment
        )

        do {
            let context = await contextBuilder.build(equipment: equipment)
            let response = try await coachService.generateWorkout(
                context: context,
                preferences: questionnaire
            )

            generatedWorkout = response.workout
            coachingTips = response.tips
            cyclePhase = context.cyclePhase
            state = .preview
        } catch {
            state = .error("Could not generate workout. Please try again.")
        }
    }

    func startGeneratedWorkout() async {
        guard let generated = generatedWorkout else { return }

        let workout = Workout(
            date: Date(),
            name: "\(focus.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) — AI",
            exercises: generated.exercises.map { ex in
                let reps = Int(ex.reps.split(separator: "-").first ?? "8") ?? 8
                return Exercise(
                    id: UUID().uuidString,
                    name: ex.name,
                    category: isWeightliftingExercise(ex.name) ? .compound : .accessory,
                    bodyweight: ex.bodyweightOnly ? 1.0 : 0.0,
                    targetSets: (0..<ex.sets).map { _ in
                        ExerciseSet(
                            reps: reps,
                            prescribedWeight: ex.weightKg ?? 0,
                            type: .fixed
                        )
                    },
                    restMinutes: ex.restMinutes ?? 1.5
                )
            },
            notes: "AI Generated — \(generated.coachingSummary)"
        )

        do {
            try await dataClient.save(workout, recordType: "Workout")

            // Record workout completion in coach memory
            await memoryService.recordWorkoutCompletion(
                questionnaire: generated.questionnaire,
                exerciseNames: generated.exercises.map(\.name)
            )
        } catch {
            state = .error("Failed to save workout: \(error.localizedDescription)")
        }
    }
}
