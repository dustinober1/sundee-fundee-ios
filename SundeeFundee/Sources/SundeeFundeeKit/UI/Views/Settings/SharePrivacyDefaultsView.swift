import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct SharePrivacyDefaultsView: View {
    @State private var privacyOptions: SharePrivacyOptions = SharePrivacyOptions.savedPreset
    @State private var showSavedFeedback = false

    public init() {}

    public var body: some View {
        Form {
            Section {
                Toggle("Show cycle context", isOn: $privacyOptions.showCycleContext)
                Toggle("Show recovery score", isOn: $privacyOptions.showRecoveryScore)
                Toggle("Show pain context", isOn: $privacyOptions.showPainContext)
                Toggle("Show exact date", isOn: $privacyOptions.showExactDate)
            } header: {
                Text("Choose what others see when you share")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }

            Section {
                Button {
                    SharePrivacyOptions.savedPreset = privacyOptions
                    HapticFeedback.light()
                    showSavedFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showSavedFeedback = false
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(showSavedFeedback ? "Saved" : "Save Defaults")
                            .font(AppTheme.Typography.labelMedium)
                            .foregroundColor(AppTheme.Accent.gold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Share Privacy Defaults")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .background(AppTheme.Background.brandCream.ignoresSafeArea())
        #if os(iOS)
        .scrollContentBackground(.hidden)
        #endif
    }
}
