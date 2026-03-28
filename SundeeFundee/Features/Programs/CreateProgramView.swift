import SwiftUI

struct CreateProgramView: View {
    @State private var viewModel = CreateProgramViewModel()
    @State private var generatedProgram: Program?
    let userID: String
    var onProgramCreated: (Program) -> Void = { _ in }

    var body: some View {
        ZStack {
            AppTheme.Colors.cream.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    if viewModel.selectedTemplate == nil {
                        templatePicker
                    } else {
                        customizeSection
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .navigationTitle(viewModel.selectedTemplate == nil ? "New Program" : "Customize")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $generatedProgram) { program in
            ProgramEditorView(program: program, userID: userID, onSave: onProgramCreated)
        }
    }

    // MARK: - Template Picker

    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Choose a starting template")
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))

            ForEach(ProgramTemplate.allCases, id: \.self) { template in
                Button {
                    viewModel.selectTemplate(template)
                } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: template.icon)
                            .font(.title2)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.displayName)
                                .font(AppTheme.Fonts.subheading)
                            Text(template.descriptionText + " · " + template.subtitle)
                                .font(AppTheme.Fonts.caption)
                                .foregroundStyle(AppTheme.Colors.navy.opacity(0.6))
                        }
                        Spacer()
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.cardBackground)
                    .foregroundStyle(AppTheme.Colors.navy)
                    .cornerRadius(AppTheme.CornerRadius.card)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Customize Section

    private var customizeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("PROGRAM NAME")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    .tracking(1)
                TextField("My Strength Block", text: $viewModel.programName)
                    .font(AppTheme.Fonts.body)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.button)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("DURATION")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    .tracking(1)
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(CreateProgramViewModel.durationOptions, id: \.self) { weeks in
                        chipButton("\(weeks) wk", isSelected: viewModel.durationWeeks == weeks) {
                            viewModel.durationWeeks = weeks
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("SESSIONS PER WEEK")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    .tracking(1)
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(CreateProgramViewModel.frequencyOptions, id: \.self) { freq in
                        chipButton("\(freq)", isSelected: viewModel.sessionsPerWeek == freq) {
                            viewModel.sessionsPerWeek = freq
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("DESCRIPTION (OPTIONAL)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.navy.opacity(0.5))
                    .tracking(1)
                TextField("Focus on squat and deadlift PRs...", text: $viewModel.programDescription)
                    .font(AppTheme.Fonts.body)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(AppTheme.CornerRadius.button)
            }

            Button {
                generatedProgram = viewModel.generateProgram()
            } label: {
                Text("Generate Program")
                    .font(AppTheme.Fonts.subheading)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.Colors.accentOrange)
            .disabled(!viewModel.canGenerate)
        }
    }

    private func chipButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppTheme.Fonts.body)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(isSelected ? AppTheme.Colors.accentOrange : AppTheme.Colors.cardBackground)
                .foregroundStyle(isSelected ? .white : AppTheme.Colors.navy)
                .cornerRadius(AppTheme.CornerRadius.button)
        }
        .buttonStyle(.plain)
    }
}
