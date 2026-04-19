#if canImport(UIKit)
import SwiftUI
import UIKit

// MARK: - ShareCardSheet
//
// Presented sheet that renders a ShareCardVariant with a selectable aspect,
// shows a live preview, and provides a native ShareLink with the rendered image.

@available(iOS 18.0, *)
public struct ShareCardSheet: View {
    let variant: ShareCardVariant
    let defaultAspect: ShareCardAspect

    @State private var aspect: ShareCardAspect
    @State private var renderedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    public init(
        variant: ShareCardVariant,
        defaultAspect: ShareCardAspect = .story
    ) {
        self.variant = variant
        self.defaultAspect = defaultAspect
        _aspect = State(initialValue: defaultAspect)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    previewArea
                    aspectPicker
                    shareButton
                }
                .padding()
            }
            .background(AppTheme.Background.cream.ignoresSafeArea())
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .task(id: aspect) {
                renderedImage = await ShareCardRenderer.render(variant, aspect: aspect)
            }
        }
    }

    // MARK: Preview

    private var previewArea: some View {
        ZStack {
            if let image = renderedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                    .transition(.opacity)
            } else {
                ProgressView()
                    .frame(height: 320)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: renderedImage)
    }

    // MARK: Aspect picker

    private var aspectPicker: some View {
        Picker("Aspect", selection: $aspect) {
            ForEach(ShareCardAspect.allCases, id: \.self) { a in
                Text("\(a.displayName) (\(a.ratioLabel))").tag(a)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: Share

    @ViewBuilder
    private var shareButton: some View {
        if let image = renderedImage {
            ShareLink(
                item: Image(uiImage: image),
                preview: SharePreview(variant.shareTitle, image: Image(uiImage: image))
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .artDecoButton(style: .accent)
        } else {
            Button { } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .artDecoButton(style: .accent)
            .disabled(true)
        }
    }
}
#endif
