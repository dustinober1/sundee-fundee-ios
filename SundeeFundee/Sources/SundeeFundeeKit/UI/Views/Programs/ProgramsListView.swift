import SwiftUI

// MARK: - ProgramsListView
//
// List of available training programs.
// Matches the web app's programs feature.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct ProgramsListView: View {
    @StateObject private var viewModel = ProgramsListViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.programs.isEmpty {
                    ProgressView("Loading programs...")
                } else {
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.md) {
                            ForEach(viewModel.programs) { program in
                                ProgramRow(
                                    program: program,
                                    isEnrolling: viewModel.enrollingProgramId == program.id,
                                    onEnroll: {
                                        Task {
                                            await viewModel.enrollInProgram(program.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Programs")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .task {
                await viewModel.loadPrograms()
            }
            .refreshable {
                await viewModel.loadPrograms()
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - ProgramRow

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ProgramRow: View {
    let program: ProgramListItem
    let isEnrolling: Bool
    let onEnroll: () -> Void

    var body: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Text(program.name)
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(AppTheme.Text.primary)

                    Spacer()

                    if program.isEnrolled {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(AppTheme.Accent.gold)
                            .accessibilityLabel("Currently enrolled")
                    }
                }

                Text(program.category)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Accent.gold)

                Text(program.description)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
                    .lineLimit(2)

                HStack(spacing: AppTheme.Spacing.lg) {
                    Label("\(program.durationWeeks) weeks", systemImage: "calendar")
                    Label("\(program.sessionsPerWeek)/wk", systemImage: "figure.strengthtraining.traditional")
                }
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)

                Text(program.difficulty)
                    .font(AppTheme.Typography.labelMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                if program.isEnrolled {
                    NavigationLink(destination: ProgramDetailView(program: program)) {
                        Label("View Program", systemImage: "play.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.sm)
                    }
                    .artDecoButton(style: .primary)
                    .accessibilityHint("Open the program and start a session")
                } else {
                    Button {
                        onEnroll()
                    } label: {
                        if isEnrolling {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.sm)
                        } else {
                            Text("Enroll")
                        }
                    }
                    .artDecoButton(style: .secondary)
                    .disabled(isEnrolling)
                    .accessibilityHint("Start this program")
                    .accessibilityValue(isEnrolling ? "Enrolling…" : "")
                }
            }
        }
    }
}

// MARK: - ProgramListItem

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ProgramListItem: Identifiable {
    let id: String
    let name: String
    let category: String
    let description: String
    let durationWeeks: Int
    let sessionsPerWeek: Int
    let difficulty: String
    let isEnrolled: Bool
    let template: ProgramTemplate?
}

// MARK: - ProgramDetailView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ProgramDetailView: View {
    let program: ProgramListItem
    @StateObject private var viewModel: ProgramDetailViewModel
    @State private var activeWorkout: Workout?

    init(program: ProgramListItem) {
        self.program = program
        _viewModel = StateObject(wrappedValue: ProgramDetailViewModel(program: program))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                programHeaderCard

                if let generated = viewModel.generatedProgram {
                    ForEach(generated.weeks, id: \.week) { week in
                        weekSection(week, phases: generated.phases)
                    }
                } else {
                    ProgressView("Loading sessions...")
                        .padding(AppTheme.Spacing.xxl)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .artDecoBackground()
        .navigationTitle(program.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .navigationDestination(isPresented: Binding(
            get: { activeWorkout != nil },
            set: { if !$0 { activeWorkout = nil } }
        )) {
            if let workout = activeWorkout {
                WorkoutDetailView(workout: workout)
            }
        }
        .onAppear {
            viewModel.generateSessions()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Program Header

    private var programHeaderCard: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.lg) {
                    statPill(value: "\(program.durationWeeks)", label: "Weeks")
                    statPill(value: "\(program.sessionsPerWeek)", label: "Sessions/wk")
                    statPill(value: program.difficulty.capitalized, label: "Level")
                }

                Text(program.description)
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        }
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(value)
                .font(AppTheme.Typography.monoLarge)
                .foregroundColor(AppTheme.Text.primary)
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Background.cream.opacity(0.5))
        .cornerRadius(AppTheme.CornerRadius.small)
    }

    // MARK: - Week Section

    private func weekSection(_ week: GeneratedProgramWeek, phases: [GeneratedProgramPhase]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            weekHeader(week, phases: phases)

            ForEach(week.sessions, id: \.sessionId) { session in
                sessionCard(session, week: week.week)
            }
        }
    }

    private func weekHeader(_ week: GeneratedProgramWeek, phases: [GeneratedProgramPhase]) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text("Week \(week.week)")
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)

            if let phaseId = week.phaseId,
               let phase = phases.first(where: { $0.id == phaseId }) {
                Text("· \(phase.name)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Accent.gold)
            }

            Spacer()
        }
        .padding(.top, AppTheme.Spacing.sm)
    }

    // MARK: - Session Card

    private func sessionCard(_ session: GeneratedProgramSession, week: Int) -> some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(session.sessionName)
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Text.primary)

                        Text(session.focus.prefix(1).uppercased() + session.focus.dropFirst())
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Accent.gold)
                    }

                    Spacer()

                    Label("\(session.exercises.count) exercises", systemImage: "list.bullet")
                        .font(AppTheme.Typography.labelSmall)
                        .foregroundColor(AppTheme.Text.secondary)
                }

                Divider()
                    .background(AppTheme.Accent.gold.opacity(0.2))

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    ForEach(session.exercises.prefix(4), id: \.exercise) { ex in
                        exercisePreviewRow(ex)
                    }
                    if session.exercises.count > 4 {
                        Text("+ \(session.exercises.count - 4) more")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Accent.gold)
                    }
                }

                Button {
                    Task {
                        let workout = await viewModel.startSession(session, week: week, programName: program.name)
                        if let workout {
                            activeWorkout = workout
                        }
                    }
                } label: {
                    if viewModel.startingSessionId == session.sessionId {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.sm)
                    } else {
                        Label("Start Session", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .artDecoButton(style: .accent)
                .disabled(viewModel.startingSessionId != nil)
                .accessibilityHint("Create a workout from this session and open it")
            }
        }
    }

    private func exercisePreviewRow(_ ex: GeneratedProgramExercise) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(AppTheme.Accent.gold.opacity(0.4))
                .frame(width: 4, height: 4)
                .accessibilityHidden(true)

            Text(ex.exercise)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.primary)

            Spacer()

            Text("\(ex.sets.description) × \(ex.reps.description)")
                .font(AppTheme.Typography.monoSmall)
                .foregroundColor(AppTheme.Text.secondary)
        }
    }
}

// MARK: - ProgramDetailViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class ProgramDetailViewModel: ObservableObject {
    @Published var generatedProgram: GeneratedProgram?
    @Published var errorMessage: String?
    @Published var startingSessionId: String?

    private let program: ProgramListItem
    private let dataClient: DataClientProtocol

    init(
        program: ProgramListItem,
        dataClient: DataClientProtocol = DataClientFactory.shared.client
    ) {
        self.program = program
        self.dataClient = dataClient
    }

    func generateSessions() {
        guard let template = program.template else {
            // Fallback: build a minimal program structure from metadata without sessions
            generatedProgram = GeneratedProgram(
                id: program.id,
                name: program.name,
                category: program.category,
                description: program.description,
                durationWeeks: program.durationWeeks,
                sessionsPerWeek: program.sessionsPerWeek,
                difficulty: program.difficulty,
                phases: [],
                weeks: []
            )
            return
        }
        generatedProgram = generateProgram(
            template: template,
            name: program.name,
            durationWeeks: program.durationWeeks,
            sessionsPerWeek: program.sessionsPerWeek
        )
    }

    func startSession(_ session: GeneratedProgramSession, week: Int, programName: String) async -> Workout? {
        startingSessionId = session.sessionId
        defer { startingSessionId = nil }

        let workout = Workout(
            date: Date(),
            name: "\(programName) — \(session.sessionName)",
            exercises: session.exercises.map { ex in
                let setsCount: Int
                if case .fixed(let n) = ex.sets { setsCount = n } else { setsCount = 3 }

                let repCount: Int
                let setType: ExerciseType
                switch ex.reps {
                case .fixed(let n):
                    repCount = n
                    setType = .fixed
                case .amrap:
                    repCount = 0
                    setType = .amrap
                case .range(let lo, let hi):
                    repCount = lo
                    setType = .range(min: lo, max: hi)
                case .text(let t):
                    repCount = 0
                    setType = .text(t)
                }

                let targetSets = (0..<setsCount).map { _ in
                    ExerciseSet(
                        reps: repCount,
                        prescribedWeight: 0,
                        prescribedPercentage: ex.percent1RM,
                        type: setType
                    )
                }

                return Exercise(
                    id: UUID().uuidString,
                    name: ex.exercise,
                    category: ex.bodyweightOnly ? .accessory : (isWeightliftingExercise(ex.exercise) ? .compound : .accessory),
                    bodyweight: ex.bodyweightOnly ? 1.0 : 0.0,
                    targetSets: targetSets,
                    restMinutes: ex.restMinutes
                )
            }
        )

        do {
            try await dataClient.save(workout, recordType: "Workout")
            return workout
        } catch {
            errorMessage = "Failed to start session: \(error.localizedDescription)"
            return nil
        }
    }
}

// MARK: - ProgramsListViewModel

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
@MainActor
class ProgramsListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var programs: [ProgramListItem] = []
    @Published var errorMessage: String?
    /// Tracks which program is currently being enrolled so the row can show a spinner.
    @Published var enrollingProgramId: String? = nil

    private let dataClient: DataClientProtocol
    private let contentClient: ContentClientProtocol

    // Maps known program display names to their template type so the detail view
    // can regenerate sessions without storing the full program in CloudKit.
    private static let nameToTemplate: [String: ProgramTemplate] = [
        "Strength Basics": .strength,
        "Hypertrophy Phase": .hypertrophy,
        "Full Body Split": .fullBody,
        "Full Body": .fullBody,
        "Linear Progression": .linear,
        "Daily Undulating Periodization": .dup,
        "Daily Undulating": .dup,
        "Block Periodization": .block,
    ]

    init(
        dataClient: DataClientProtocol = DataClientFactory.shared.client,
        contentClient: ContentClientProtocol? = nil
    ) {
        self.dataClient = dataClient
        self.contentClient = contentClient ?? BundledContentProvider()
    }

    func loadPrograms() async {
        isLoading = true

        var enrolledIds: Set<String> = []
        do {
            let enrolled = try await dataClient.fetchAll(
                recordType: "EnrolledProgramRecord"
            ) as [EnrolledProgramRecord]
            enrolledIds = Set(enrolled.filter(\.isActive).map(\.id))
        } catch {
            errorMessage = "Failed to load programs: \(error.localizedDescription)"
        }

        do {
            let contentPrograms = try await contentClient.fetchPrograms()
            programs = contentPrograms.map { prog in
                ProgramListItem(
                    id: prog.id,
                    name: prog.name,
                    category: prog.category,
                    description: prog.description,
                    durationWeeks: prog.durationWeeks,
                    sessionsPerWeek: prog.sessionsPerWeek,
                    difficulty: prog.difficulty,
                    isEnrolled: enrolledIds.contains(prog.id),
                    template: Self.nameToTemplate[prog.name]
                )
            }
        } catch {
            programs = ProgramTemplate.allCases.map { template in
                let program = generateProgram(template: template, name: templateDisplayName(template))
                return ProgramListItem(
                    id: program.id,
                    name: program.name,
                    category: program.category,
                    description: program.description,
                    durationWeeks: program.durationWeeks,
                    sessionsPerWeek: program.sessionsPerWeek,
                    difficulty: program.difficulty,
                    isEnrolled: enrolledIds.contains(program.id),
                    template: template
                )
            }
        }

        isLoading = false
    }

    func enrollInProgram(_ programId: String) async {
        enrollingProgramId = programId
        defer { enrollingProgramId = nil }

        do {
            let record = EnrolledProgramRecord(
                id: programId,
                name: programs.first(where: { $0.id == programId })?.name ?? "",
                isActive: true
            )
            try await dataClient.save(record, recordType: "EnrolledProgramRecord")

            // Update local state immediately. CloudKit query indexes may not reflect
            // a fresh write instantly (especially under rate limiting), so re-fetching
            // can silently return stale empty results and leave the row showing as unenrolled.
            programs = programs.map { p in
                guard p.id == programId else { return p }
                return ProgramListItem(
                    id: p.id,
                    name: p.name,
                    category: p.category,
                    description: p.description,
                    durationWeeks: p.durationWeeks,
                    sessionsPerWeek: p.sessionsPerWeek,
                    difficulty: p.difficulty,
                    isEnrolled: true,
                    template: p.template
                )
            }
        } catch {
            errorMessage = "Failed to enroll: \(error.localizedDescription)"
        }
    }

    private func templateDisplayName(_ template: ProgramTemplate) -> String {
        switch template {
        case .strength:    return "Strength Basics"
        case .hypertrophy: return "Hypertrophy Phase"
        case .fullBody:    return "Full Body"
        case .linear:      return "Linear Progression"
        case .dup:         return "Daily Undulating"
        case .block:       return "Block Periodization"
        }
    }
}
