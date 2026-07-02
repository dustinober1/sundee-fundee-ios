import SwiftUI

// MARK: - CycleTrackingView
//
// Top-level tab for cycle tracking. Hosts the enable toggle, the inline
// calendar when enabled, and a link into the detailed CycleSettingsView.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct CycleTrackingView: View {
    @StateObject private var settings = SettingsViewModel()
    @EnvironmentObject private var cyclePhaseCache: CyclePhaseCache
    @State private var showingQuickCheckIn = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    cycleTrackingToggleRow
                } footer: {
                    if !settings.isLoaded {
                        Text("Loading cycle settings…")
                    } else if !settings.cycleTrackingEnabled {
                        Text("Turn on cycle tracking to see your phase, log periods, and let Sundee Fundee adapt training to your cycle.")
                    }
                }
                .onChange(of: settings.cycleTrackingEnabled) { _, _ in
                    Task { await settings.saveSettings() }
                }

                if shouldShowCyclePrompt {
                    Section("When Ready") {
                        progressivePromptRow(
                            title: "Set up cycle context",
                            message: "Add cycle details when you want training adjustments to use phase estimates.",
                            systemImage: "moon.circle"
                        )
                    }
                }

                Section("Check-Ins") {
                    Button {
                        showingQuickCheckIn = true
                    } label: {
                        Label("Quick Check-In", systemImage: "waveform.path.ecg")
                    }

                    NavigationLink {
                        PainTrackingView()
                    } label: {
                        Label("Pain Log", systemImage: "bandage")
                    }

                    NavigationLink {
                        SymptomCheckInView()
                    } label: {
                        Label("Symptom Check-In", systemImage: "waveform.path.ecg")
                    }

                }

                if settings.cycleTrackingEnabled {
                    let explanation = CycleConfidenceExplainer.explain(confidence: cyclePhaseCache.confidence)
                    Section("Phase Confidence") {
                        HStack {
                            Text(explanation.label)
                                .font(AppTheme.Typography.headlineMedium)
                                .foregroundColor(AppTheme.Text.primary)
                            Spacer()
                            if let confidence = cyclePhaseCache.confidence {
                                Text("\(Int((confidence * 100).rounded()))%")
                                    .font(AppTheme.Typography.monoMedium)
                                    .foregroundColor(AppTheme.Text.secondary)
                            }
                        }

                        Text(explanation.description)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)

                        Text(explanation.actionTitle)
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Accent.gold)
                    }

                    Section {
                        NavigationLink {
                            CycleCalendarView()
                        } label: {
                            Label("Cycle Calendar", systemImage: "calendar")
                        }

                        NavigationLink {
                            CycleSettingsView()
                        } label: {
                            Label("Cycle Settings", systemImage: "slider.horizontal.3")
                        }
                    }
                }
            }
            .navigationTitle("Cycle")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .task {
                await cyclePhaseCache.refreshIfNeeded()
            }
            .sheet(isPresented: $showingQuickCheckIn) {
                QuickCheckInView()
            }
        }
    }

    private var shouldShowCyclePrompt: Bool {
        ProgressivePromptPolicy.nextPrompt(
            context: ProgressivePromptContext(
                completedWorkoutCount: 0,
                openedCycle: true,
                isAboutToSharePhoto: false,
                declinedPromptIDs: []
            )
        ) == .cycleSetup && !settings.cycleTrackingEnabled
    }

    private var cycleTrackingToggleRow: some View {
        Button {
            guard settings.isLoaded else { return }
            settings.cycleTrackingEnabled.toggle()
        } label: {
            HStack {
                Text("Enable Cycle Tracking")
                    .foregroundColor(AppTheme.Text.primary)
                Spacer()
                switchIndicator(isOn: settings.cycleTrackingEnabled)
            }
            .padding(.vertical, AppTheme.Spacing.xs)
        }
        .buttonStyle(.plain)
        .disabled(!settings.isLoaded)
        .accessibilityLabel("Enable Cycle Tracking")
        .accessibilityValue(settings.cycleTrackingEnabled ? "On" : "Off")
        .accessibilityHint(cycleTrackingToggleHint)
    }

    private var cycleTrackingToggleHint: String {
        if !settings.isLoaded {
            return "Cycle settings are loading."
        }
        return settings.cycleTrackingEnabled
            ? "Double tap to turn cycle tracking off."
            : "Double tap to turn cycle tracking on."
    }

    private func switchIndicator(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? AppTheme.Semantic.success : AppTheme.Text.secondary.opacity(0.35))
            Circle()
                .fill(AppTheme.Background.cream)
                .padding(2)
        }
        .frame(width: 50, height: 30)
        .accessibilityHidden(true)
    }

    private func progressivePromptRow(title: String, message: String, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.headlineSmall)
                Text(message)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundColor(AppTheme.Accent.gold)
        }
    }
}
