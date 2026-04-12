import SwiftUI

// MARK: - CreateChallengeView

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct CreateChallengeView: View {
    @ObservedObject var viewModel: ChallengesViewModel
    @Environment(\.dismiss) private var dismiss

    enum ChallengeMode: String, CaseIterable {
        case lifetime = "Lifetime"
        case exercise = "Per Exercise"
        case custom = "Custom"
    }

    @State private var mode: ChallengeMode = .lifetime
    @State private var customTitle = ""
    @State private var targetVolume = ""
    @State private var exerciseName = ""
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                // Mode Picker
                Section {
                    Picker("Type", selection: $mode) {
                        ForEach(ChallengeMode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                switch mode {
                case .lifetime:
                    lifetimeSection
                case .exercise:
                    exerciseSection
                case .custom:
                    customSection
                }
            }
            .navigationTitle("New Challenge")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await createChallenge() }
                    }
                    .disabled(isCreating || !isValid)
                }
            }
        }
    }

    // MARK: - Lifetime

    private var lifetimeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Track total volume across all exercises")
                    .font(AppTheme.Typography.bodyMedium)
                    .foregroundColor(AppTheme.Text.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    tierRow("Bronze", "250,000 lbs")
                    tierRow("Silver", "500,000 lbs")
                    tierRow("Gold", "1,000,000 lbs")
                }
                .padding(.top, AppTheme.Spacing.xs)

                Text("Your historical workout volume will be counted retroactively.")
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        } header: {
            Text("Lifetime Volume Challenge")
        }
    }

    private func tierRow(_ name: String, _ target: String) -> some View {
        HStack {
            Image(systemName: "trophy.fill")
                .foregroundColor(AppTheme.Accent.gold)
                .font(.caption)
            Text(name)
                .font(AppTheme.Typography.headlineSmall)
                .foregroundColor(AppTheme.Text.primary)
            Spacer()
            Text(target)
                .font(AppTheme.Typography.monoMedium)
                .foregroundColor(AppTheme.Text.secondary)
        }
    }

    // MARK: - Exercise

    private var exerciseSection: some View {
        Section {
            TextField("Exercise name", text: $exerciseName)
            TextField("Target volume (lbs)", text: $targetVolume)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
        } header: {
            Text("Per-Exercise Challenge")
        } footer: {
            Text("Track volume for a single exercise.")
        }
    }

    // MARK: - Custom

    private var customSection: some View {
        Group {
            Section {
                TextField("Challenge title", text: $customTitle)
                TextField("Target volume (lbs)", text: $targetVolume)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
            } header: {
                Text("Custom Challenge")
            }

            Section {
                Toggle("Set end date", isOn: $hasEndDate)
                if hasEndDate {
                    DatePicker("End date", selection: $endDate, displayedComponents: .date)
                }
            }
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        switch mode {
        case .lifetime:
            return true
        case .exercise:
            return !exerciseName.isEmpty && (Double(targetVolume) ?? 0) > 0
        case .custom:
            return !customTitle.isEmpty && (Double(targetVolume) ?? 0) > 0
        }
    }

    // MARK: - Create

    private func createChallenge() async {
        isCreating = true
        switch mode {
        case .lifetime:
            await viewModel.createLifetimeChallenge()
        case .exercise:
            let volume = Double(targetVolume) ?? 50_000
            await viewModel.createExerciseChallenge(exerciseName: exerciseName, targetVolume: volume)
        case .custom:
            let volume = Double(targetVolume) ?? 50_000
            let date = hasEndDate ? endDate : nil
            await viewModel.createCustomChallenge(title: customTitle, targetVolume: volume, endDate: date)
        }
        isCreating = false
        dismiss()
    }
}
