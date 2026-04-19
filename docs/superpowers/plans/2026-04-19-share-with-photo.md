# Share with Photo + App Store QR — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users attach a camera/library photo to PR and completed-workout share cards, with a scannable App Store QR badge + App Store URL in the share caption.

**Architecture:** Extend the existing `ShareCardSheet` with a "Add your photo" toggle that swaps the rendered variant to `selfieOverlay` (already wired through `ShareCardRenderer`). Add `QRBadge` to the overlay and inject caption + clipboard copy into the `ShareLink` path. No data-layer changes.

**Tech Stack:** SwiftUI, UIKit (`UIImagePickerController`, `UIPasteboard`), `PhotosUI.PhotosPicker`, `CoreImage.CIFilter.qrCodeGenerator`, XCTest.

**Spec:** `docs/superpowers/specs/2026-04-19-share-with-photo-design.md`

---

## File Structure

**Create:**
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareURL.swift` — URL + caption constants.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/QRBadge.swift` — themed QR tile view.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/CameraPicker.swift` — `UIImagePickerController` wrapper.
- `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/ShareURLTests.swift`
- `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/QRBadgeTests.swift`

**Modify:**
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/Variants/SelfieOverlayShareView.swift` — embed `QRBadge`.
- `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift` — toggle, source picker, variant branching, caption, gated clipboard copy.
- `SundeeFundeeApp/SundeeFundee/Info.plist` — add `NSCameraUsageDescription`.

---

## Task 1: `ShareURL` constants + tests

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareURL.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/ShareURLTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/ShareURLTests.swift`:

```swift
import XCTest
@testable import SundeeFundeeKit

final class ShareURLTests: XCTestCase {
    func testAppStoreURLIsValidHTTPS() {
        XCTAssertEqual(ShareURL.appStore.scheme, "https")
        XCTAssertEqual(ShareURL.appStore.host, "apps.apple.com")
        XCTAssertTrue(ShareURL.appStore.absoluteString.contains("id6759870888"))
    }

    func testShareCaptionContainsAppStoreURL() {
        XCTAssertTrue(ShareURL.shareCaption.contains(ShareURL.appStore.absoluteString))
        XCTAssertTrue(ShareURL.shareCaption.contains("Sundee Fundee"))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
cd SundeeFundee && swift test --filter ShareURLTests
```

Expected: compile error "cannot find 'ShareURL' in scope".

- [ ] **Step 3: Create `ShareURL.swift`**

Create `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareURL.swift`:

```swift
import Foundation

// MARK: - ShareURL
//
// Single source of truth for the public App Store link and share caption text.
// Kept free of UIKit/SwiftUI so it is reachable from tests and pure domain code.

public enum ShareURL {
    public static let appStore = URL(
        string: "https://apps.apple.com/app/sundeefundee/id6759870888"
    )!

    public static let shareCaption =
        "Training with Sundee Fundee — cycle-aware strength. \(appStore.absoluteString)"
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
cd SundeeFundee && swift test --filter ShareURLTests
```

Expected: both tests PASS.

- [ ] **Step 5: Commit**

```
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareURL.swift SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/ShareURLTests.swift
git commit -m "feat(share): add ShareURL constants for App Store link"
```

---

## Task 2: `QRBadge` view + decode test

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/QRBadge.swift`
- Create: `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/QRBadgeTests.swift`

- [ ] **Step 1: Write the failing test**

Create `SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/QRBadgeTests.swift`:

```swift
#if canImport(UIKit)
import XCTest
import SwiftUI
import CoreImage
@testable import SundeeFundeeKit

@available(iOS 18.0, *)
final class QRBadgeTests: XCTestCase {
    @MainActor
    func testQRDecodesToAppStoreURL() throws {
        let badge = QRBadge(url: ShareURL.appStore, size: 256)
        let renderer = ImageRenderer(content: badge.frame(width: 256, height: 256))
        renderer.scale = 2.0
        let image = try XCTUnwrap(renderer.uiImage)

        let ciImage = try XCTUnwrap(CIImage(image: image))
        let detector = try XCTUnwrap(
            CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil)
        )
        let features = detector.features(in: ciImage).compactMap { $0 as? CIQRCodeFeature }
        let decoded = features.compactMap(\.messageString)
        XCTAssertTrue(
            decoded.contains(ShareURL.appStore.absoluteString),
            "QR should decode to App Store URL, got: \(decoded)"
        )
    }
}
#endif
```

- [ ] **Step 2: Run test to verify it fails**

```
cd SundeeFundee && swift test --filter QRBadgeTests
```

Expected: compile error "cannot find 'QRBadge' in scope".

- [ ] **Step 3: Implement `QRBadge`**

Create `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/QRBadge.swift`:

```swift
#if canImport(UIKit)
import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

// MARK: - QRBadge
//
// Themed QR tile for share cards. Cream modules on navy background with a
// gold hairline border. Uses quartile error correction so the border + any
// future ornamentation does not break scanning.

@available(iOS 18.0, *)
struct QRBadge: View {
    let url: URL
    let size: CGFloat

    init(url: URL, size: CGFloat = 96) {
        self.url = url
        self.size = size
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(AppTheme.Background.navy)
            if let qr = Self.generate(url: url) {
                Image(uiImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.08)
            }
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(AppTheme.Accent.gold, lineWidth: 1)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("Download QR code, Sundee Fundee App Store link")
        .accessibilityHint("Scan with camera to open the App Store")
    }

    // MARK: - Generation

    private static func generate(url: URL) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "Q"
        guard let output = filter.outputImage else { return nil }

        let cream = CIColor(
            red: 0xFA / 255.0, green: 0xF6 / 255.0, blue: 0xEC / 255.0
        )
        let navy = CIColor(
            red: 0x12 / 255.0, green: 0x1E / 255.0, blue: 0x3B / 255.0
        )
        let colored = output.applyingFilter(
            "CIFalseColor",
            parameters: ["inputColor0": navy, "inputColor1": cream]
        )

        let context = CIContext()
        guard let cg = context.createCGImage(colored, from: colored.extent) else {
            return nil
        }
        return UIImage(cgImage: cg)
    }
}
#endif
```

Note: the hex values above mirror the actual values in `AppTheme.Background.navy` and cream. If those tokens expose `CIColor` directly in this codebase, replace the literals — check `SundeeFundee/Sources/SundeeFundeeKit/UI/Theme/AppTheme.swift` before committing and prefer whatever helper already exists. If none exist, keep the literals and add a `// hex mirrors AppTheme.Background.navy` comment.

- [ ] **Step 4: Verify theme values**

Read `SundeeFundee/Sources/SundeeFundeeKit/UI/Theme/AppTheme.swift`. Confirm `AppTheme.Background.navy` and `AppTheme.Background.cream` hex values match the literals above. If they differ, update the `CIColor` literals to match. Do NOT change `AppTheme` values.

- [ ] **Step 5: Run test to verify it passes**

```
cd SundeeFundee && swift test --filter QRBadgeTests
```

Expected: `testQRDecodesToAppStoreURL` PASS.

- [ ] **Step 6: Commit**

```
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Share/QRBadge.swift SundeeFundee/Tests/SundeeFundeeKitTests/UITests/Share/QRBadgeTests.swift
git commit -m "feat(share): add QRBadge with App Store link"
```

---

## Task 3: Add `NSCameraUsageDescription` to Info.plist

**Files:**
- Modify: `SundeeFundeeApp/SundeeFundee/Info.plist`

- [ ] **Step 1: Open Info.plist**

Read `SundeeFundeeApp/SundeeFundee/Info.plist` to find the `<dict>` block already containing `NSHealthShareUsageDescription`.

- [ ] **Step 2: Add camera key**

Insert immediately after the `NSHealthUpdateUsageDescription` string element:

```xml
<key>NSCameraUsageDescription</key>
<string>Sundee Fundee uses the camera so you can add a photo to your share card.</string>
```

- [ ] **Step 3: Verify build still succeeds**

```
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```
git add SundeeFundeeApp/SundeeFundee/Info.plist
git commit -m "feat(share): add NSCameraUsageDescription for share photos"
```

---

## Task 4: `CameraPicker` UIViewControllerRepresentable

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/CameraPicker.swift`

No unit test — thin representable around a UIKit class. Covered by manual QA.

- [ ] **Step 1: Implement `CameraPicker`**

Create `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/CameraPicker.swift`:

```swift
#if canImport(UIKit)
import SwiftUI
import UIKit

// MARK: - CameraPicker
//
// Minimal SwiftUI wrapper around UIImagePickerController configured for the
// rear camera. No editing UI. Reports back via the bound UIImage? and calls
// onDismiss on cancel or capture.

@available(iOS 18.0, *)
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onDismiss: () -> Void

    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = false
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let captured = info[.originalImage] as? UIImage {
                parent.image = captured
            }
            parent.onDismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onDismiss()
        }
    }
}
#endif
```

- [ ] **Step 2: Verify build**

```
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Share/CameraPicker.swift
git commit -m "feat(share): add CameraPicker SwiftUI wrapper"
```

---

## Task 5: Embed `QRBadge` in `SelfieOverlayShareView`

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/Variants/SelfieOverlayShareView.swift`

- [ ] **Step 1: Read current file**

Read `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/Variants/SelfieOverlayShareView.swift` to confirm the existing structure (image + gradient + VStack + ShareFooter).

- [ ] **Step 2: Edit — add QRBadge overlay in the bottom-right**

Replace the outer `ZStack(alignment: .bottom)` block with:

```swift
ZStack(alignment: .bottom) {
    Image(uiImage: image)
        .resizable()
        .scaledToFill()
        .frame(width: aspect.size.width, height: aspect.size.height)
        .clipped()

    LinearGradient(
        colors: [
            Color.clear,
            AppTheme.Background.navy.opacity(0.55),
            AppTheme.Background.navy.opacity(0.92)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    .frame(height: aspect.size.height * 0.55)

    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
        Text(summary.title)
            .font(AppTheme.Typography.displaySmall)
            .foregroundColor(AppTheme.Text.cream)
            .lineLimit(2)
        HStack(spacing: AppTheme.Spacing.lg) {
            metric(value: "\(summary.durationMinutes)", label: "min")
            metric(value: "\(summary.exerciseCount)", label: "lifts")
            metric(value: volumeString, label: summary.weightUnit + " vol")
        }
        ShareFooter(palette: .onDark)
            .padding(.top, AppTheme.Spacing.sm)
    }
    .padding(AppTheme.Spacing.xl)
    .frame(maxWidth: .infinity, alignment: .leading)

    // QR badge: bottom-right, sized ~10% of card width.
    QRBadge(url: ShareURL.appStore, size: aspect.size.width * 0.10)
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
}
```

Do not change the `metric` helper or `volumeString` computed property.

- [ ] **Step 3: Verify build**

```
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Share/Variants/SelfieOverlayShareView.swift
git commit -m "feat(share): embed App Store QR badge in selfie overlay"
```

---

## Task 6: Extend `ShareCardSheet` with toggle, source picker, and branching

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift`

This is the largest task. One file, multiple coordinated changes. Five steps.

- [ ] **Step 1: Add imports and new state**

Near the top of `ShareCardSheet.swift`, add below the existing `import UIKit`:

```swift
import PhotosUI
```

Inside `public struct ShareCardSheet`, add after the existing `@State private var showCopyFeedback = false`:

```swift
// Photo flow state
@State private var useSelfie = false
@State private var selfieImage: UIImage?
@State private var photoSource: PhotoSource = .library
@State private var libraryPickerItem: PhotosPickerItem?
@State private var showCameraSheet = false
@State private var showPermissionAlert = false

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
```

- [ ] **Step 2: Branch the rendered variant**

Locate the existing `.task(id: aspect) { renderedImage = await ShareCardRenderer.render(variant, aspect: aspect) }` modifier.

Replace it with a task keyed on all render inputs, using a computed `effectiveVariant`:

```swift
.task(id: RenderKey(aspect: aspect, useSelfie: useSelfie, hasImage: selfieImage != nil)) {
    renderedImage = await ShareCardRenderer.render(effectiveVariant, aspect: aspect)
}
```

Add inside `ShareCardSheet` (below `body`):

```swift
private struct RenderKey: Hashable {
    let aspect: ShareCardAspect
    let useSelfie: Bool
    let hasImage: Bool
}

private var effectiveVariant: ShareCardVariant {
    if useSelfie, let selfie = selfieImage {
        return .selfieOverlay(image: selfie, summary: summaryFromVariant(variant))
    }
    return variant
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
    case .selfieOverlay(_, let summary):
        return summary
    }
}
```

- [ ] **Step 3: Add toggle + segmented control UI**

Locate the body's main `VStack` that currently contains `previewArea`, `aspectPicker`, `shareButton`. Insert the photo controls between `previewArea` and `aspectPicker`:

```swift
previewArea
photoControls
aspectPicker
shareButton
```

Add new computed views:

```swift
@ViewBuilder
private var photoControls: some View {
    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
        Toggle("Add your photo", isOn: $useSelfie)
            .onChange(of: useSelfie) { _, newValue in
                if !newValue { selfieImage = nil }
            }
        if useSelfie {
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

private var availablePhotoSources: [PhotoSource] {
    CameraPicker.isAvailable ? [.library, .camera] : [.library]
}

@ViewBuilder
private var sourceTrigger: some View {
    switch photoSource {
    case .library:
        PhotosPicker(
            selection: $libraryPickerItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Label(
                selfieImage == nil ? "Choose a photo" : "Change photo",
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
```

- [ ] **Step 4: Update share button — caption + gated clipboard**

Replace the existing `ShareLink(item: Image(uiImage: image), preview: SharePreview(variant.shareTitle, image: Image(uiImage: image))) { ... }` block inside `shareButton` with a two-item share:

```swift
ShareLink(
    items: [Image(uiImage: image), ShareURL.shareCaption],
    subject: Text(variant.shareTitle),
    message: Text(ShareURL.shareCaption)
) {
    Label("Share", systemImage: "square.and.arrow.up")
        .frame(maxWidth: .infinity)
}
.artDecoButton(style: .accent)
.simultaneousGesture(
    TapGesture().onEnded {
        HapticFeedback.success()
        if useSelfie {
            UIPasteboard.general.string = ShareURL.appStore.absoluteString
        }
    }
)
```

Note: `ShareLink(items:subject:message:)` takes a single preview via `SharePreview` when needed. If that initializer is unavailable for a heterogeneous array in your Xcode, fall back to:

```swift
ShareLink(
    item: Image(uiImage: image),
    message: Text(ShareURL.shareCaption),
    preview: SharePreview(variant.shareTitle, image: Image(uiImage: image))
) { ... }
```

Pick whichever compiles; both deliver image + caption.

- [ ] **Step 5: Verify build**

```
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

```
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift
git commit -m "feat(share): add photo toggle, source picker, and App Store caption"
```

---

## Task 7: Full test suite + lint

- [ ] **Step 1: Run all tests**

```
cd SundeeFundee && swift test
```

Expected: all tests PASS (including `ShareURLTests`, `QRBadgeTests`, and pre-existing suites).

- [ ] **Step 2: Run lint**

```
cd /Users/dustinober/Projects/sundee-fundee-ios && swiftlint --config .swiftlint.yml
```

Expected: no new warnings on the files touched in this plan. Fix any introduced violations inline.

- [ ] **Step 3: Final build for simulator**

```
cd SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Manual QA (checklist from spec — not a commit gate, but do before merging)**

Confirm on iPhone 17 Pro simulator:
- Share from a PR → toggle on → Library → pick image → QR visible bottom-right → aspects switch cleanly → toggle off clears image.
- Tap Share → system sheet shows image + caption text containing App Store URL.

On physical device (if available):
- Camera path: permission prompt fires, capture works, permission-denied path shows alert gracefully.
- Scan QR from shared image on a second device → opens App Store product page.

---

## Self-Review Notes

- **Spec coverage:** Tasks 1–6 cover every numbered item in the spec's Components section. Task 3 covers the Info.plist item. Task 7 covers the Testing section's automated checks; manual QA is documented.
- **Type consistency:** `selfieImage`, `useSelfie`, `photoSource`, `PhotoSource`, `RenderKey`, `effectiveVariant`, `summaryFromVariant` used consistently across Tasks 2–4 of the sheet. `QRBadge(url:size:)` signature matches between Task 2 creation and Task 5 usage. `CameraPicker(image:onDismiss:)` matches between Task 4 creation and Task 6 usage.
- **Placeholder scan:** No "TBD" / "handle edge cases" / "similar to above" language in any step. All code blocks are complete.
- **Known flex point:** Task 6 Step 4 provides two `ShareLink` initializers because SwiftUI's multi-item ShareLink has evolved across Xcode versions; engineer picks the one that compiles.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-19-share-with-photo.md`.
