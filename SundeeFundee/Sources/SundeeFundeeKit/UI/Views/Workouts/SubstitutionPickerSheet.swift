import SwiftUI

// MARK: - SubstitutionPickerSheet
//
// In-flow swap picker presented from the active workout exercise card. Uses
// the deterministic CoachService to rank substitutes for the current exercise.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct SubstitutionPickerSheet: View {
    let exerciseName: String
    let onSelect: (SubstitutionRanker.RankedSubstitution) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var substitutions: [SubstitutionRanker.RankedSubstitution] = []
    @State private var errorMessage: String?

    public init(
        exerciseName: String,
        onSelect: @escaping (SubstitutionRanker.RankedSubstitution) -> Void
    ) {
        self.exerciseName = exerciseName
        self.onSelect = onSelect
    }

    public var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Finding alternatives…")
                } else if let error = errorMessage {
                    errorState(error)
                } else if substitutions.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Swap \(exerciseName)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await load()
            }
        }
    }

    // MARK: Sections

    private var list: some View {
        List {
            ForEach(substitutions.prefix(5), id: \.exerciseName) { sub in
                Button {
                    onSelect(sub)
                    dismiss()
                } label: {
                    row(sub)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }

    private func row(_ sub: SubstitutionRanker.RankedSubstitution) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(sub.exerciseName)
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)
                Text(sub.reason)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
                    .lineLimit(2)
            }
            Spacer()
            scoreDots(for: sub.score)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sub.exerciseName), \(Int(sub.score * 5)) out of 5")
    }

    private func scoreDots(for score: Double) -> some View {
        let filled = Int((score * 5).rounded())
        return HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { idx in
                Circle()
                    .fill(idx < filled ? AppTheme.Accent.gold : AppTheme.Accent.gold.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.Text.secondary)
            Text("No alternatives found")
                .font(AppTheme.Typography.headlineMedium)
            Text("We couldn't find a close substitute for \(exerciseName).")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(AppTheme.Spacing.xxl)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(AppTheme.Text.orange)
            Text(message)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.xxl)
    }

    // MARK: Load

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        let service = CoachServiceFactory.makeService()
        let context = CoachContext(
            tier: .premium,
            injuries: [],
            equipment: .fullGym
        )

        do {
            let response = try await service.suggestSubstitutions(
                for: exerciseName,
                context: context
            )
            substitutions = response.substitutions
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
