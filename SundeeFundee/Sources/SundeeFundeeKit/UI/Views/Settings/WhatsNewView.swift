import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
public struct WhatsNewView: View {
    private let notes = ReleaseNotesContent.current

    public init() {}

    public var body: some View {
        List {
            Section {
                ForEach(notes.items) { item in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(item.title)
                            .font(AppTheme.Typography.headlineSmall)
                            .foregroundColor(AppTheme.Text.primary)
                        Text(item.body)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
            }
        }
        .navigationTitle(notes.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
