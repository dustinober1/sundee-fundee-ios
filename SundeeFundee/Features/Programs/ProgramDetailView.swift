import SwiftUI
import SwiftData

/// Detail view for a program — shows phases, sessions-per-week, and enrollment CTA.
struct ProgramDetailView: View {
    let program: Program
    @Bindable var viewModel: ProgramListViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var showCancelConfirm: Bool
    
    init(program: Program, viewModel: ProgramListViewModel, showCancelConfirm: Bool = false) {
        self.program = program
        self.viewModel = viewModel
        _showCancelConfirm = State(initialValue: showCancelConfirm)
    }

    private var isActiveEnrollment: Bool {
        viewModel.activeEnrollment?.programID == program.id
    }

    private var hasOtherActiveEnrollment: Bool {
        if let active = viewModel.activeEnrollment {
            return active.programID != program.id
        }
        return false
    }
    
    static func presentCancelConfirmationAction(isPresented: Binding<Bool>) -> () -> Void {
        { Self.presentCancelConfirmation(isPresented) }
    }
    
    static func performEnrollAction(
        _ viewModel: ProgramListViewModel,
        in program: Program,
        modelContext: ModelContext,
        userID: String
    ) -> () -> Void {
        { Self.performEnroll(viewModel, in: program, modelContext: modelContext, userID: userID) }
    }
    
    static func performCancelEnrollmentAction(
        _ viewModel: ProgramListViewModel,
        modelContext: ModelContext
    ) -> () -> Void {
        { Self.performCancelEnrollment(viewModel, modelContext: modelContext) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(program.category)
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                        .textCase(.uppercase)
                    Text(program.description)
                        .font(AppTheme.Fonts.body)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.8))
                }

                // Stats row
                HStack(spacing: AppTheme.Spacing.lg) {
                    StatBadge(label: "Duration", value: "\(program.durationWeeks) weeks")
                    StatBadge(label: "Frequency", value: "\(program.sessionsPerWeek)x / week")
                    StatBadge(label: "Level", value: program.difficulty)
                }

                if let startString = program.startDate,
                   let start = ProgramAvailability.parseDate(startString) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "calendar")
                            .foregroundStyle(AppTheme.Colors.accentOrange)
                        if let endString = program.endDate,
                           let end = ProgramAvailability.parseDate(endString) {
                            Text("\(Self.formatFullDate(start)) to \(Self.formatFullDate(end))")
                        } else {
                            Text("Starts \(Self.formatFullDate(start))")
                        }
                    }
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                }

                // Phases
                if !program.phases.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Program Structure")
                            .font(AppTheme.Fonts.subheading)
                            .foregroundStyle(AppTheme.Colors.navy)

                        ForEach(program.phases) { phase in
                            ProgramPhaseRow(phase: phase)
                        }
                    }
                }

                Spacer(minLength: AppTheme.Spacing.xl)

                // CTA
                enrollmentCTA
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.cream.ignoresSafeArea())
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Cancel Enrollment?",
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button(
                "Cancel Enrollment",
                role: .destructive,
                action: Self.performCancelEnrollmentAction(viewModel, modelContext: modelContext)
            )
        } message: {
            Text("Your progress will be saved. You can re-enroll later.")
        }
    }

    private var programAvailability: ProgramAvailability {
        ProgramAvailability.status(for: program)
    }

    @ViewBuilder
    private var enrollmentCTA: some View {
        if isActiveEnrollment {
            VStack(spacing: AppTheme.Spacing.sm) {
                Label("Currently enrolled", systemImage: "checkmark.circle.fill")
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.accentOrange)

                if case .upcoming(let startDate) = programAvailability {
                    Text("Program starts \(ProgramAvailability.formattedStartDate(startDate))")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                }

                Button("Cancel Enrollment", action: Self.presentCancelConfirmationAction(isPresented: $showCancelConfirm))
                .buttonStyle(DestructiveButtonStyle())
            }
            .frame(maxWidth: .infinity)
        } else if hasOtherActiveEnrollment {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("You're currently enrolled in another program.")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                    .multilineTextAlignment(.center)

                Button(
                    Self.enrollButtonLabel(programAvailability),
                    action: Self.performEnrollAction(viewModel, in: program, modelContext: modelContext, userID: appState.currentUserID ?? "")
                )
                .buttonStyle(PrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: AppTheme.Spacing.sm) {
                if case .upcoming(let startDate) = programAvailability {
                    Text("Program starts \(ProgramAvailability.formattedStartDate(startDate))")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                }
                Button(Self.enrollButtonLabel(programAvailability), action: Self.performEnrollAction(viewModel, in: program, modelContext: modelContext, userID: appState.currentUserID ?? ""))
                .buttonStyle(PrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity)
        }
    }

    static func enrollButtonLabel(_ availability: ProgramAvailability) -> String {
        switch availability {
        case .upcoming(let startDate):
            return "Enroll — Starts \(ProgramAvailability.formattedStartDate(startDate))"
        case .active, .past:
            return "Start Program"
        }
    }

    static func presentCancelConfirmation(_ isPresented: inout Bool) {
        isPresented = true
    }
    
    static func presentCancelConfirmation(_ isPresented: Binding<Bool>) {
        isPresented.wrappedValue = true
    }

    static func performEnroll(_ viewModel: ProgramListViewModel, in program: Program, modelContext: ModelContext, userID: String) {
        Task { await viewModel.enroll(in: program, modelContext: modelContext, userID: userID) }
    }

    static func performCancelEnrollment(_ viewModel: ProgramListViewModel, modelContext: ModelContext) {
        Task { await viewModel.cancelEnrollment(modelContext: modelContext) }
    }

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    static func formatFullDate(_ date: Date) -> String {
        fullDateFormatter.string(from: date)
    }
}

// MARK: - Supporting views

struct StatBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTheme.Fonts.subheading)
                .foregroundStyle(AppTheme.Colors.navy)
            Text(label)
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
    }
}

struct ProgramPhaseRow: View {
    let phase: ProgramPhase

    private var weekLabel: String {
        guard phase.weekRange.count == 2 else { return "" }
        return "Wk \(phase.weekRange[0])–\(phase.weekRange[1])"
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Text(weekLabel)
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.accentOrange)
                .frame(width: 60, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(phase.name)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.navy)
                Text(phase.goal)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
            }
        }
        .padding(.vertical, 4)
    }
}
