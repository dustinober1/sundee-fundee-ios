import SwiftUI

// MARK: - Pain Tracking View
//
// Full pain and injury tracking with body region selector,
// intensity slider, pain type picker, and log history.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct PainTrackingView: View {
    @StateObject private var viewModel = PainTrackingViewModel()
    @State private var showingLogForm = false

    public init() {}

    public var body: some View {
        Group {
            if viewModel.isLoading && viewModel.painLogs.isEmpty && viewModel.injuries.isEmpty {
                ProgressView("Loading injuries and pain logs…")
            } else {
                contentView
            }
        }
        .navigationTitle("Pain & Injuries")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingLogForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Log Pain")
            }
        }
        .task {
            await viewModel.loadPainLogs()
            await viewModel.loadInjuries()
            await viewModel.loadSubstitutionSuggestions()
        }
        .sheet(isPresented: $showingLogForm) {
            PainLogFormView(viewModel: viewModel) {
                showingLogForm = false
            }
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Active Injuries
                if !viewModel.activeInjuries.isEmpty {
                    activeInjuriesBanner
                }

                // Quick Log Button
                Button {
                    showingLogForm = true
                } label: {
                    ArtDecoCard {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(AppTheme.Accent.orange)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text("Log Pain")
                                    .font(AppTheme.Typography.headlineMedium)
                                    .foregroundColor(AppTheme.Text.primary)

                                Text("Track pain or discomfort for exercise adaptation")
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.Text.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityHint("Open pain logging form")

                // Smart Substitutions (Pro)
                if !viewModel.substitutionSuggestions.isEmpty {
                    substitutionSection
                }

                // Recent Pain Logs
                if !viewModel.painLogs.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Recent Logs")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        ForEach(viewModel.painLogs.prefix(10)) { log in
                            PainLogRow(log: log)
                        }
                    }
                } else {
                    // Empty State
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Image(systemName: "heart.text.square")
                            .font(.system(.largeTitle))
                            .foregroundColor(AppTheme.Accent.gold.opacity(0.5))
                            .accessibilityHidden(true)

                        Text("No Pain Logs")
                            .font(AppTheme.Typography.headlineMedium)
                            .foregroundColor(AppTheme.Text.primary)

                        Text("Log pain or discomfort to help adapt your workouts")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(AppTheme.Text.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(AppTheme.Spacing.xxl)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
    }

    // MARK: - Smart Substitutions

    private var substitutionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "arrow.triangle.swap")
                    .foregroundColor(AppTheme.Semantic.success)

                Text("Smart Substitutions")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Text.primary)
            }

            Text("Alternatives for exercises affected by your injuries")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)

            ForEach(viewModel.substitutionSuggestions, id: \.originalExercise) { suggestion in
                ArtDecoCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Text(suggestion.originalExercise)
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Semantic.error)
                                .strikethrough()

                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundColor(AppTheme.Text.secondary)
                        }

                        ForEach(suggestion.substitutions.prefix(3), id: \.exerciseName) { sub in
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Semantic.success)

                                Text(sub.exerciseName)
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Text.primary)

                                Spacer()

                                Text(sub.reason)
                                    .font(AppTheme.Typography.labelSmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Active Injuries Banner

    private var activeInjuriesBanner: some View {
        ArtDecoCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Label("Active Injuries", systemImage: "exclamationmark.triangle.fill")
                    .font(AppTheme.Typography.headlineMedium)
                    .foregroundColor(AppTheme.Accent.orange)
                    .accessibilityLabel("Active injuries: \(viewModel.activeInjuries.count) injuries")

                ForEach(viewModel.activeInjuries) { injury in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(injury.name)
                                .font(AppTheme.Typography.bodyMedium)
                                .foregroundColor(AppTheme.Text.primary)

                            Text(injury.bodyRegions.map(\.displayName).joined(separator: ", "))
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                        }

                        Spacer()

                        Text(injury.recoveryPhase.displayName)
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Text.orange)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 2)
                            .background(AppTheme.Accent.orange.opacity(0.15))
                            .cornerRadius(AppTheme.CornerRadius.small)

                        Button {
                            Task { await viewModel.resolveInjury(id: injury.id) }
                        } label: {
                            Text("Healed")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Recovery.green)
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .padding(.vertical, 2)
                                .background(AppTheme.Recovery.green.opacity(0.15))
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                        .accessibilityLabel("Mark \(injury.name) as healed")
                    }

                    if injury.id != viewModel.activeInjuries.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

// MARK: - Pain Log Form

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct PainLogFormView: View {
    @ObservedObject var viewModel: PainTrackingViewModel
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Body Region Selector
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("Where does it hurt?")
                                .font(AppTheme.Typography.headlineMedium)
                                .foregroundColor(AppTheme.Text.primary)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: AppTheme.Spacing.sm) {
                                ForEach(BodyRegions.allRegions) { region in
                                    regionButton(region)
                                }
                            }
                        }
                    }

                    // Intensity Slider
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            HStack {
                                Text("Pain Intensity")
                                    .font(AppTheme.Typography.headlineMedium)
                                    .foregroundColor(AppTheme.Text.primary)

                                Spacer()

                                Text("\(viewModel.painIntensity)/10")
                                    .font(AppTheme.Typography.monoLarge)
                                    .foregroundColor(intensityColor)
                            }

                            Slider(
                                value: Binding(
                                    get: { Double(viewModel.painIntensity) },
                                    set: { viewModel.painIntensity = Int($0) }
                                ),
                                in: 1...10,
                                step: 1
                            )
                            .tint(intensityColor)
                            .accessibilityLabel("Pain intensity, \(viewModel.painIntensity) out of 10")

                            HStack {
                                Text("Mild")
                                    .font(AppTheme.Typography.labelSmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                                Spacer()
                                Text("Severe")
                                    .font(AppTheme.Typography.labelSmall)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }
                        }
                    }

                    // Pain Type
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("Type of Pain")
                                .font(AppTheme.Typography.headlineMedium)
                                .foregroundColor(AppTheme.Text.primary)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: AppTheme.Spacing.sm) {
                                ForEach(PainType.allCases, id: \.self) { type in
                                    painTypeButton(type)
                                }
                            }
                        }
                    }

                    // Notes
                    ArtDecoCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Notes (optional)")
                                .font(AppTheme.Typography.labelMedium)
                                .foregroundColor(AppTheme.Text.secondary)

                            TextField("Additional context...", text: $viewModel.notes, axis: .vertical)
                                .font(AppTheme.Typography.bodyMedium)
                                .lineLimit(2...4)
                                .textFieldStyle(.plain)
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.Background.cream.opacity(0.5))
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                    }

                    // Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Semantic.error)
                    }

                    // Save Button
                    Button {
                        Task {
                            await viewModel.logPain()
                            if viewModel.errorMessage == nil {
                                onDismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Log Pain")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .artDecoButton(style: .accent)
                    .disabled(viewModel.selectedBodyRegions.isEmpty || viewModel.isLoading)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .artDecoBackground()
            .navigationTitle("Log Pain")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
    }

    // MARK: - Region Button

    private func regionButton(_ region: BodyRegion) -> some View {
        let isSelected = viewModel.selectedBodyRegions.contains(region.id)

        return Button {
            if isSelected {
                viewModel.selectedBodyRegions.remove(region.id)
            } else {
                viewModel.selectedBodyRegions.insert(region.id)
            }
        } label: {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppTheme.Accent.gold : AppTheme.Text.secondary.opacity(0.3))

                Text(region.displayName)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.primary)

                Spacer()
            }
            .padding(AppTheme.Spacing.sm)
            .background(isSelected ? AppTheme.Accent.goldLight : AppTheme.Background.cream.opacity(0.3))
            .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pain Type Button

    private func painTypeButton(_ type: PainType) -> some View {
        let isSelected = viewModel.selectedPainType == type

        return Button {
            viewModel.selectedPainType = type
        } label: {
            Text(type.displayName)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(isSelected ? AppTheme.Text.cream : AppTheme.Text.primary)
                .frame(maxWidth: .infinity)
                .padding(AppTheme.Spacing.sm)
                .background(isSelected ? AppTheme.Background.navy : AppTheme.Background.cream.opacity(0.3))
                .cornerRadius(AppTheme.CornerRadius.small)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Intensity Color

    private var intensityColor: Color {
        let i = viewModel.painIntensity
        if i <= 3 { return .green }
        if i <= 6 { return AppTheme.Accent.gold }
        return .red
    }
}

// MARK: - Pain Log Row

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct PainLogRow: View {
    let log: DailyPainLog

    var body: some View {
        ArtDecoCard {
            HStack(spacing: AppTheme.Spacing.md) {
                // Intensity Circle
                ZStack {
                    Circle()
                        .fill(intensityColor(log.intensity))
                        .frame(width: 40, height: 40)

                    Text("\(log.intensity)")
                        .font(AppTheme.Typography.headlineMedium)
                        .foregroundColor(.white)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Pain intensity: \(log.intensity) out of 10")

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(log.painType.displayName)
                        .font(AppTheme.Typography.headlineSmall)
                        .foregroundColor(AppTheme.Text.primary)

                    Text(log.bodyRegions.map(\.displayName).joined(separator: ", "))
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Text.secondary)
                        .lineLimit(1)

                    if let notes = log.notes, !notes.isEmpty {
                        Text(notes)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                            .lineLimit(1)
                            .italic()
                    }
                }

                Spacer()

                Text(log.date, style: .date)
                    .font(AppTheme.Typography.labelSmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        }
    }

    private func intensityColor(_ intensity: Int) -> Color {
        if intensity <= 3 { return .green }
        if intensity <= 6 { return .orange }
        return .red
    }
}
