import SwiftUI

/// Browse and enroll in available programs.
struct ProgramListView: View {
    @State private var viewModel = ProgramListViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppTheme.Colors.accentOrange)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(error, systemImage: "exclamationmark.triangle")
                } else if viewModel.programs.isEmpty {
                    ContentUnavailableView("No Programs", systemImage: "list.bullet.rectangle.portrait")
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.md) {
                            ForEach(viewModel.programs) { program in
                                NavigationLink(value: program) {
                                    ProgramCardView(
                                        program: program,
                                        isEnrolled: viewModel.activeEnrollment?.programID == program.id
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
        .navigationDestination(for: Program.self) { program in
            ProgramDetailView(program: program, viewModel: viewModel)
        }
        .task { await viewModel.load(modelContext: modelContext) }
    }
}

// MARK: - Program Card

struct ProgramCardView: View {
    let program: Program
    let isEnrolled: Bool

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
                if isEnrolled {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.accentOrange)
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
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.card))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
