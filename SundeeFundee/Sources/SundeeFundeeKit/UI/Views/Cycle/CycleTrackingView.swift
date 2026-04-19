import SwiftUI

// MARK: - CycleTrackingView
//
// Top-level tab for cycle tracking. Hosts the enable toggle, the inline
// calendar when enabled, and a link into the detailed CycleSettingsView.

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct CycleTrackingView: View {
    @StateObject private var settings = SettingsViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Enable Cycle Tracking", isOn: $settings.cycleTrackingEnabled)
                        .padding(.vertical, AppTheme.Spacing.xs)
                } footer: {
                    if !settings.cycleTrackingEnabled {
                        Text("Turn on cycle tracking to see your phase, log periods, and let Sundee Fundee adapt training to your cycle.")
                    }
                }
                .onChange(of: settings.cycleTrackingEnabled) { _, _ in
                    Task { await settings.saveSettings() }
                }

                if settings.cycleTrackingEnabled {
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
        }
    }
}
