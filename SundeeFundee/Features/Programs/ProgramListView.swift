import SwiftUI

/// Browse and enroll in available programs.
struct ProgramListView: View {
    @State private var viewModel: ProgramListViewModel
    @Environment(\.modelContext) private var modelContext

    enum ContentState: Equatable {
        case loading
        case error(String)
        case empty
        case loaded
    }

    init(viewModel: ProgramListViewModel = ProgramListViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            Group {
                switch Self.contentState(
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage,
                    programCount: viewModel.filteredPrograms.count
                ) {
                case .loading:
                    ProgressView()
                        .tint(AppTheme.Colors.accentOrange)
                case .error(let error):
                    ContentUnavailableView(error, systemImage: "exclamationmark.triangle")
                case .empty:
                    Self.emptyStateView()
                case .loaded:
                    ScrollView {
                        if !viewModel.enrollments.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                Text("My Programs")
                                    .font(AppTheme.Fonts.subheading)
                                    .foregroundStyle(AppTheme.Colors.navy)
                                    .padding(.horizontal, AppTheme.Spacing.md)

                                ForEach(viewModel.enrollments, id: \.id) { enrollment in
                                    enrolledProgramRow(enrollment)
                                }
                            }
                            .padding(.top, AppTheme.Spacing.sm)

                            Divider()
                                .padding(.vertical, AppTheme.Spacing.sm)

                            Text("All Programs")
                                .font(AppTheme.Fonts.subheading)
                                .foregroundStyle(AppTheme.Colors.navy)
                                .padding(.horizontal, AppTheme.Spacing.md)
                        }

                        LazyVStack(spacing: AppTheme.Spacing.md) {
                            ForEach(ProgramAvailability.sortedPrograms(viewModel.filteredPrograms)) { program in
                                NavigationLink(value: program) {
                                    ProgramCardView(
                                        program: program,
                                        isEnrolled: viewModel.activeEnrollment?.programID == program.id,
                                        availability: ProgramAvailability.status(for: program)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("program-card-\(program.id)")
                            }
                        }
                        .padding(AppTheme.Spacing.md)
                    }
                }
            }
        }
        .navigationTitle("Programs")
        .searchable(text: $viewModel.searchText, prompt: "Search programs")
        .navigationDestination(for: Program.self) { program in
            Self.detailDestination(program: program, viewModel: viewModel)
        }
        .task { await viewModel.load(modelContext: modelContext) }
    }

    private func enrolledProgramRow(_ enrollment: EnrolledProgram) -> some View {
        let programName = viewModel.filteredPrograms.first(where: { $0.id == enrollment.programID })?.name
            ?? viewModel.programs.first(where: { $0.id == enrollment.programID })?.name
            ?? "Unknown Program"

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(programName)
                    .font(AppTheme.Fonts.body)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.Colors.navy)
                HStack(spacing: AppTheme.Spacing.xs) {
                    Text(enrollment.status.rawValue.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(enrollment.isActive
                            ? AppTheme.Colors.accentOrange.opacity(0.15)
                            : AppTheme.Colors.navy.opacity(0.1))
                        .foregroundStyle(enrollment.isActive
                            ? AppTheme.Colors.accentOrange
                            : AppTheme.Colors.navy)
                        .cornerRadius(4)
                    Text("Week \(enrollment.currentWeek), Day \(enrollment.currentDay)")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            Spacer()
            Button {
                viewModel.removeEnrollment(enrollment, modelContext: modelContext)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    static func contentState(isLoading: Bool, errorMessage: String?, programCount: Int) -> ContentState {
        if isLoading { return .loading }
        if let errorMessage { return .error(errorMessage) }
        return programCount == 0 ? .empty : .loaded
    }

    static func detailDestination(program: Program, viewModel: ProgramListViewModel) -> ProgramDetailView {
        ProgramDetailView(program: program, viewModel: viewModel)
    }

    @ViewBuilder
    static func emptyStateView() -> some View {
        ContentUnavailableView("No Programs", systemImage: "list.bullet.rectangle.portrait")
    }
}

// MARK: - Program Card

struct ProgramCardView: View {
    let program: Program
    let isEnrolled: Bool
    var availability: ProgramAvailability = .active

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(AppTheme.Fonts.subheading)
                        .foregroundStyle(AppTheme.Colors.navy)
                    Text(program.category)
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                }
                Spacer()
                if Self.showsActiveBadge(isEnrolled: isEnrolled) {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.accentOrange)
                } else if let badgeInfo = Self.availabilityBadge(availability) {
                    Label(badgeInfo.text, systemImage: badgeInfo.icon)
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(badgeInfo.color)
                }
            }

            Text(program.description)
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.8))
                .lineLimit(2)

            HStack(spacing: AppTheme.Spacing.md) {
                Label("\(program.durationWeeks)w", systemImage: "calendar")
                Label("\(program.sessionsPerWeek)x/wk", systemImage: "repeat")
                Label(program.difficulty, systemImage: "bolt.fill")
            }
            .font(AppTheme.Fonts.caption)
            .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))

            if case .upcoming(let startDate) = availability {
                Text("Starts \(ProgramAvailability.formattedStartDate(startDate))")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    static func showsActiveBadge(isEnrolled: Bool) -> Bool {
        isEnrolled
    }

    static func availabilityBadge(_ availability: ProgramAvailability) -> (text: String, icon: String, color: Color)? {
        switch availability {
        case .upcoming:
            return ("Coming Soon", "clock.fill", AppTheme.Colors.accentOrange)
        case .past:
            return ("Past Program", "clock.arrow.circlepath", AppTheme.Colors.navy.opacity(0.4))
        case .active:
            return nil
        }
    }
}
