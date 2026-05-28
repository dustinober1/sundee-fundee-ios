import SwiftUI

// MARK: - CycleTrackingView
//
// Top-level tab for cycle tracking. Hosts the enable toggle, the inline
// calendar when enabled, and a link into the detailed CycleSettingsView.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct CycleTrackingView: View {
    @StateObject private var settings = SettingsViewModel()
    @EnvironmentObject private var cyclePhaseCache: CyclePhaseCache

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Enable Cycle Tracking", isOn: $settings.cycleTrackingEnabled)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .disabled(!settings.isLoaded)
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

                Section("Pain & Recovery") {
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

                    NavigationLink {
                        RecoveryOverviewView()
                    } label: {
                        Label("Recovery Score", systemImage: "heart.circle")
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
        }
    }
}
