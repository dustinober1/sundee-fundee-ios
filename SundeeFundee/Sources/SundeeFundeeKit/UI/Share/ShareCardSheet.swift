#if canImport(UIKit)
import SwiftUI
import UIKit
import PhotosUI

// MARK: - ShareCardSheet
//
// Presented sheet that renders a ShareCardVariant with a selectable aspect,
// shows a live preview, and provides a native ShareLink with the rendered image.

@available(iOS 18.0, *)
public struct ShareCardSheet: View {
    let variant: ShareCardVariant
    let defaultAspect: ShareCardAspect
    let shareContext: ShareContext?

    @State private var aspect: ShareCardAspect
    @State private var renderedImage: UIImage?
    @State private var showCopyFeedback = false

    // Photo flow state
    @State private var useSelfie = false
    @State private var selfieImage: UIImage?
    @State private var photoSource: PhotoSource = .library
    @State private var libraryPickerItem: PhotosPickerItem?
    @State private var showCameraSheet = false
    @State private var showPermissionAlert = false
    @State private var privacyOptions: SharePrivacyOptions = SharePrivacyOptions.savedPreset
    @State private var showingShareOptions = false

    @Environment(\.dismiss) private var dismiss

    enum PhotoSource: String, CaseIterable, Identifiable {
        case library, camera
        var id: String { rawValue }
        var label: String {
            switch self {
            case .library: return "Library"
            case .camera:  return "Camera"
            }
        }
    }

    public init(
        variant: ShareCardVariant,
        defaultAspect: ShareCardAspect = .story,
        shareContext: ShareContext? = nil
    ) {
        self.variant = variant
        self.defaultAspect = defaultAspect
        self.shareContext = shareContext
        _aspect = State(initialValue: defaultAspect)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    previewArea
                    DisclosureGroup(isExpanded: $showingShareOptions) {
                        VStack(spacing: AppTheme.Spacing.md) {
                            photoControls
                            privacyControls
                            aspectPicker
                        }
                        .padding(.top, AppTheme.Spacing.sm)
                    } label: {
                        Label("Share Options", systemImage: "slider.horizontal.3")
                            .font(AppTheme.Typography.labelLarge)
                            .foregroundColor(AppTheme.Text.primary)
                    }
                    .tint(AppTheme.Accent.gold)
                    privacySummary
                    shareButton
                }
                .padding()
            }
            .background(AppTheme.Background.brandCream.ignoresSafeArea())
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .task(id: RenderKey(
                aspect: aspect,
                useSelfie: useSelfie,
                hasImage: selfieImage != nil,
                showCycleContext: privacyOptions.showCycleContext,
                showPainContext: privacyOptions.showPainContext,
                showExactDate: privacyOptions.showExactDate
            )) {
                renderedImage = await ShareCardRenderer.render(
                    effectiveVariant,
                    aspect: aspect,
                    shareContext: shareContext,
                    privacyOptions: privacyOptions
                )
            }
            .task {
                await GrowthAnalyticsService().track(
                    GrowthEventName.shareSheetOpened,
                    source: variant.shareSheetOpenedSource(shareContext: shareContext),
                    properties: shareContextProperties
                )
            }
        }
    }

    // MARK: - RenderKey

    private struct RenderKey: Hashable {
        let aspect: ShareCardAspect
        let useSelfie: Bool
        let hasImage: Bool
        let showCycleContext: Bool
        let showPainContext: Bool
        let showExactDate: Bool
    }

    // MARK: - Effective variant

    private var effectiveVariant: ShareCardVariant {
        if useSelfie, let selfie = selfieImage {
            return .selfieOverlay(image: selfie, summary: summaryFromVariant(variant))
        }
        return variant
    }

    /// Sanitized cards never carry the caller's context into native sharing,
    /// clipboard links, or analytics. Their card content is already limited to
    /// `ShareSanitizedSummary`.
    private var externalShareContext: ShareContext? {
        isSanitizedVariant ? nil : shareContext
    }

    private func summaryFromVariant(_ variant: ShareCardVariant) -> ShareSummary {
        switch variant {
        case .completedWorkout(let workout, _):
            return ShareSummary(workout: workout)
        case .newPR(let exercise, let weight, let unit, _):
            return ShareSummary(
                title: "New PR — \(exercise)",
                exerciseCount: 1,
                totalVolume: weight,
                durationMinutes: 0,
                weightUnit: unit
            )
        case .cycleInsight:
            return ShareSummary(
                title: "Cycle-aware training",
                exerciseCount: 0,
                totalVolume: 0,
                durationMinutes: 0
            )
        case .coachSummary(let title, _, _, let bullets):
            return ShareSummary(
                title: title,
                exerciseCount: bullets.count,
                totalVolume: 0,
                durationMinutes: 0
            )
        case .weeklyRecap(let title, _, _, let bullets):
            return ShareSummary(
                title: title,
                exerciseCount: bullets.count,
                totalVolume: 0,
                durationMinutes: 0
            )
        case .buddyCheckIn(_, let displayName):
            return ShareSummary(
                title: "Buddy Check-In — \(displayName)",
                exerciseCount: 0,
                totalVolume: 0,
                durationMinutes: 0
            )
        case .monthlyReview(let review):
            return ShareSummary(
                title: review.monthTitle,
                exerciseCount: review.workoutCount,
                totalVolume: 0,
                durationMinutes: 0
            )
        case .readiness(let summary), .deload(let summary):
            return ShareSummary(
                title: summary.title,
                exerciseCount: 0,
                totalVolume: 0,
                durationMinutes: 0
            )
        case .selfieOverlay(_, let summary):
            return summary
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
                ProgressView("Rendering share card preview…")
                    .frame(height: 320)
                    .accessibilityLabel("Rendering share card preview")
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: renderedImage)
    }

    // MARK: Photo controls

    @ViewBuilder
    private var photoControls: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Toggle("Add your photo", isOn: $useSelfie)
                .onChange(of: useSelfie) { _, newValue in
                    if !newValue { selfieImage = nil }
                }
            if useSelfie {
                if shouldShowPhotoPrompt {
                    progressivePromptRow(
                        title: "Photo sharing uses your permission",
                        message: "Choose a photo only when you want it on a share card.",
                        systemImage: "photo"
                    )
                }

                Picker("Source", selection: $photoSource) {
                    ForEach(availablePhotoSources) { src in
                        Text(src.label).tag(src)
                    }
                }
                .pickerStyle(.segmented)
                sourceTrigger
            }
        }
    }

    private var shouldShowPhotoPrompt: Bool {
        ProgressivePromptPolicy.nextPrompt(
            context: ProgressivePromptContext(
                completedWorkoutCount: 0,
                openedCycle: false,
                isAboutToSharePhoto: useSelfie,
                declinedPromptIDs: []
            )
        ) == .photoSharing
    }

    private var availablePhotoSources: [PhotoSource] {
        CameraPicker.isAvailable ? [.library, .camera] : [.library]
    }

    @ViewBuilder
    private var sourceTrigger: some View {
        switch photoSource {
        case .library:
            let title = selfieImage == nil ? "Choose a photo" : "Change photo"
            PhotosPicker(
                selection: $libraryPickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(
                    title,
                    systemImage: "photo.on.rectangle"
                )
                .frame(maxWidth: .infinity)
            }
            .artDecoButton(style: .secondary)
            .onChange(of: libraryPickerItem) { _, newItem in
                guard let newItem else { return }
                Task { await loadLibraryImage(newItem) }
            }
        case .camera:
            Button {
                showCameraSheet = true
            } label: {
                Label(
                    selfieImage == nil ? "Take a photo" : "Retake photo",
                    systemImage: "camera"
                )
                .frame(maxWidth: .infinity)
            }
            .artDecoButton(style: .secondary)
            .sheet(isPresented: $showCameraSheet) {
                CameraPicker(image: $selfieImage) {
                    showCameraSheet = false
                }
                .ignoresSafeArea()
            }
        }
    }

    private func loadLibraryImage(_ item: PhotosPickerItem) async {
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selfieImage = image
        }
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

    private var privacyControls: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Privacy")
                .font(AppTheme.Typography.labelMedium)
                .foregroundColor(AppTheme.Text.secondary)

            Toggle("Show cycle context", isOn: $privacyOptions.showCycleContext)
            Toggle("Show pain context", isOn: $privacyOptions.showPainContext)
            Toggle("Show exact date", isOn: $privacyOptions.showExactDate)

            Button("Save as default") {
                SharePrivacyOptions.savedPreset = privacyOptions
                HapticFeedback.light()
            }
            .font(AppTheme.Typography.labelMedium)
            .foregroundColor(AppTheme.Accent.gold)
        }
    }

    /// Plain-language disclosure shown immediately before the system share
    /// control. It makes the safe boundary clear without exposing any source
    /// assessment details.
    private var privacySummary: some View {
        Label {
            Text(privacyOptions.shareDisclosureText)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Text.secondary)
        } icon: {
            Image(systemName: "lock.shield")
                .foregroundColor(AppTheme.Accent.gold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(privacyOptions.shareDisclosureText)
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

    // MARK: Share

    @ViewBuilder
    private var shareButton: some View {
        if let image = renderedImage {
            VStack(spacing: AppTheme.Spacing.sm) {
                ShareLink(
                    item: Image(uiImage: image),
                    subject: Text(variant.shareTitle),
                    message: Text(isSanitizedVariant ? ShareURL.sanitizedCaption : ShareURL.caption(for: externalShareContext)),
                    preview: SharePreview(variant.shareTitle, image: Image(uiImage: image))
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .artDecoButton(style: .accent)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        HapticFeedback.success()
                        if useSelfie {
                            UIPasteboard.general.string = (isSanitizedVariant ? ShareURL.sanitizedLink : ShareURL.link(for: externalShareContext)).absoluteString
                        }
                        Task { await trackShareTapped() }
                    }
                )

                Button {
                    UIPasteboard.general.image = image
                    HapticFeedback.success()
                    showCopyFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showCopyFeedback = false
                    }
                } label: {
                    Label(
                        showCopyFeedback ? "Copied!" : "Copy to Photos",
                        systemImage: showCopyFeedback ? "checkmark" : "photo.on.rectangle"
                    )
                    .frame(maxWidth: .infinity)
                }
                .artDecoButton(style: .secondary)
            }
        } else {
            Button { } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .artDecoButton(style: .accent)
            .disabled(true)
        }
    }

    private var shareContextProperties: [String: String] {
        guard !isSanitizedVariant else { return [:] }
        var properties: [String: String] = [:]
        if let sourceID = shareContext?.sourceID {
            properties["sourceID"] = sourceID
        }
        // Sanitized variants must never persist caller-provided context title or
        // referral text, which may contain raw assessment details.
        if !isSanitizedVariant, let title = shareContext?.title {
            properties["title"] = title
        }
        if !isSanitizedVariant, let referralCode = shareContext?.referralCode {
            properties["referralCode"] = referralCode
        }
        return properties
    }

    private var isSanitizedVariant: Bool {
        Self.isSanitizedVariant(variant)
    }

    private static func isSanitizedVariant(_ variant: ShareCardVariant) -> Bool {
        switch variant {
        case .readiness, .deload: return true
        default: return false
        }
    }

    private func trackShareTapped() async {
        let eventName: String
        switch shareContext?.surface {
        case .completedWorkout, .starterWorkout:
            eventName = GrowthEventName.shareCompletedWorkoutTapped
        case .personalRecord:
            eventName = GrowthEventName.sharePRTapped
        case .challenge:
            eventName = GrowthEventName.shareChallengeTapped
        case .cycleInsight, nil:
            eventName = GrowthEventName.shareSheetOpened
        }

        await GrowthAnalyticsService().track(
            eventName,
            source: isSanitizedVariant ? nil : shareContext?.surface.rawValue,
            properties: shareContextProperties
        )
    }
}
#endif
