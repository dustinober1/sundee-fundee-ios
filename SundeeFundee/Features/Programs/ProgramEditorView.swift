import SwiftUI
import SwiftData

struct ProgramEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State var program: Program
    let userID: String
    var onSave: (Program) -> Void = { _ in }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    header

                    ForEach(Array(program.weeks.enumerated()), id: \.offset) { weekIndex, week in
                        weekSection(weekIndex: weekIndex, week: week)
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .navigationTitle("Edit Program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { saveProgram() }
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.accentOrange)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(program.name)
                .font(AppTheme.Fonts.heading)
                .foregroundStyle(AppTheme.Colors.navy)
            Text("\(program.durationWeeks) weeks · \(program.sessionsPerWeek) sessions/week")
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
        }
    }

    private func weekSection(weekIndex: Int, week: ProgramWeek) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("WEEK \(week.week)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.Colors.accentOrange)
                .tracking(1)

            VStack(spacing: 0) {
                ForEach(Array(week.sessions.enumerated()), id: \.element.id) { sessionIndex, session in
                    NavigationLink {
                        SessionEditorView(
                            program: $program,
                            weekIndex: weekIndex,
                            sessionIndex: sessionIndex
                        )
                    } label: {
                        sessionRow(session: session)
                    }
                    .buttonStyle(.plain)

                    if sessionIndex < week.sessions.count - 1 {
                        Divider().padding(.leading, AppTheme.Spacing.md)
                    }
                }
            }
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.card)
        }
    }

    private func sessionRow(session: ProgramSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.sessionName)
                    .font(AppTheme.Fonts.subheading)
                    .foregroundStyle(AppTheme.Colors.navy)
                Text("\(session.exercises.count) exercises")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.3))
        }
        .padding(AppTheme.Spacing.md)
    }

    private func saveProgram() {
        let repo = SwiftDataCustomProgramRepository(context: modelContext)
        if let record = CustomProgramRecord.from(program, userID: userID) {
            try? repo.save(record)
        }
        onSave(program)
        dismiss()
    }
}
