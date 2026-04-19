# Share with Photo + App Store Discovery — Design

**Date:** 2026-04-19
**Status:** Draft (awaiting user review)
**Scope:** v1 of photo-enriched social sharing for Sundee Fundee, with embedded App Store discovery

## Goal

Let users share an achievement (new PR or completed workout) as a branded image that combines:
1. A photo they take or pick,
2. The achievement summary + Sundee Fundee branding,
3. A scannable QR code linking to the App Store so recipients can download the app.

Optimized for Instagram Stories (where captions are stripped), while still working well in Messages, DMs, and Feed posts.

## Non-Goals

- No server-side image hosting or share analytics.
- No photo editing (crop, filter, rotate) beyond what iOS pickers provide.
- No changes to the `CycleInsightShareView` variant — informational, not celebratory.
- No paywalls, auth gates, or network calls for the share flow.
- No Instagram/TikTok-specific SDKs; rely on the system share sheet only.

## User Flow

1. User taps Share from a PR or completed workout. `ShareCardSheet` opens with the existing branded card (current behavior).
2. User flips **"Add your photo"** toggle. Sheet reveals a **Camera / Library** segmented control.
3. **Library** → `PhotosPicker` presents; pick image → `SelfieOverlayShareView` renders with image + overlay + QR badge.
4. **Camera** → `CameraPicker` (wrapped `UIImagePickerController`) presents full-screen; capture → same result.
5. Aspect picker (Square / Story / Portrait) still works; re-renders on change.
6. **Share** button → system share sheet with two items:
    - Rendered `UIImage`
    - Caption: `"Training with Sundee Fundee — cycle-aware strength. https://apps.apple.com/app/sundeefundee/id6759870888"`
7. On Share tap: also copy the App Store URL to `UIPasteboard` so Instagram Story link stickers are one paste away. Success haptic fires (existing behavior).
8. **Copy to Photos** button stays as-is (image only).

### Edge cases

- Camera permission denied → inline alert offering Settings link; segmented control auto-flips to Library.
- Toggle off → clears `selfieImage`, re-renders branded (non-photo) card.
- Image that can't fit aspect → existing `.scaledToFill()` clip behavior (no change).

## Architecture

```
NewPRShareView ─┐
                ├─▶ ShareCardSheet
CompletedWorkoutShareView ┘        │
                                   ├─ Toggle: "Add your photo"
                                   ├─ Segmented: Camera | Library
                                   │       ├─ PhotosPicker
                                   │       └─ CameraPicker (sheet)
                                   ├─ selfieImage? ─▶ SelfieOverlayShareView
                                   │                    └─ QRBadge (bottom-right)
                                   └─ ShareLink([image, caption])
                                           └─ onTap: UIPasteboard.string = appStoreURL
```

## Components

### New

**`UI/Share/ShareURL.swift`** — constants, zero deps.
```swift
enum ShareURL {
    static let appStore = URL(string: "https://apps.apple.com/app/sundeefundee/id6759870888")!
    static let shareCaption =
        "Training with Sundee Fundee — cycle-aware strength. \(appStore.absoluteString)"
}
```

**`UI/Share/QRBadge.swift`** — pure SwiftUI QR tile.
- Input: `url: URL`, `size: CGFloat` (default scales with aspect).
- Renders: navy rounded-rect chip, cream-on-navy QR modules, 2pt gold hairline border, 4pt corner radius.
- Uses `CIFilter.qrCodeGenerator` with correction level `.quartile` so the gold border does not break scanning.
- Caches generated `UIImage` keyed by `(url, size)` within the view's lifetime.

**`UI/Share/CameraPicker.swift`** — `UIViewControllerRepresentable` wrapping `UIImagePickerController(sourceType: .camera)`.
- Inputs: `@Binding var image: UIImage?`, `onCancel: () -> Void`.
- No editing UI. Info.plist must include `NSCameraUsageDescription`; add if missing.

### Modified

**`UI/Share/Variants/SelfieOverlayShareView.swift`**
- Add param: `downloadURL: URL`.
- Place `QRBadge(url: downloadURL)` in bottom-right corner, aligned with the footer band. Sized at ~10% of card width.

**`UI/Share/ShareCardSheet.swift`**
- New state: `useSelfie: Bool`, `selfieImage: UIImage?`, `photoSource: PhotoSource`, `showCameraSheet: Bool`, `showPermissionAlert: Bool`.
- Toggle row above `aspectPicker`; segmented control appears when toggle on.
- Branch the rendered variant: when `useSelfie && selfieImage != nil`, render `SelfieOverlayShareView(image:summary:aspect:downloadURL:)`; otherwise render the variant passed in (current behavior).
- `ShareLink` item list becomes `[Image(uiImage: image), ShareURL.shareCaption]`.
- Add `UIPasteboard.general.string = ShareURL.appStore.absoluteString` to the existing share-tap `simultaneousGesture`, gated on `useSelfie == true` (keeps branded-card shares from silently overwriting clipboard).

### Unchanged

- `ShareCardRenderer`, `ShareCardVariant`, `ShareCardAspect`, `ShareFooter`.
- `NewPRShareView`, `CompletedWorkoutShareView` — no interface changes; they pass the same summary as today. Photo logic lives entirely inside the sheet.
- `CycleInsightShareView` — out of scope.

## Data Flow

- No new persistence. `UIImage` lives only in `ShareCardSheet` state.
- No CloudKit writes. Photo is never uploaded, logged, or persisted.
- No network I/O. QR is generated locally via CoreImage.
- `DataClientProtocol`, `SyncQueue`, `DiagnosticsService` all untouched.

## Error Handling

| Scenario | Handling |
| --- | --- |
| Camera permission denied | Alert with "Open Settings" action; source auto-flips to Library. |
| `UIImagePickerController` unavailable (simulator, iPad without camera) | Camera option hidden. |
| `PhotosPicker` cancelled | No state change. |
| QR generation fails | Badge omitted silently; shared image still valid. Log to `DiagnosticsService` debug channel only (no user-facing error). |
| Share sheet cancelled | Existing behavior; no side effects beyond clipboard copy which is acceptable. |

User-facing error copy uses the project convention: actionable sentence, raw error kept in logs.

## Accessibility

- Toggle: `accessibilityLabel("Add your photo to the share card")`.
- Segmented control: standard; ensure both segments have clear labels.
- QR badge: `accessibilityLabel("Download QR code, Sundee Fundee App Store link")` + `accessibilityHint("Scan with camera to open the App Store")`.
- Share button already announces correctly via `ShareLink`.
- Dynamic Type: overlay text already uses semantic tokens; QR badge uses fixed pt sizing per spec (intentional — legibility).

## Theme Compliance

- All colors via `AppTheme.*` tokens. QR modules: `AppTheme.Text.cream` on `AppTheme.Background.navy`; border: `AppTheme.Accent.gold`.
- Typography unchanged.
- Haptics via `HapticFeedback.success()` on share (existing).

## Testing

### Automated (XCTest)

- **`QRBadgeTests`**
    - `testQRDecodesToAppStoreURL` — render `QRBadge(url: ShareURL.appStore)` to `UIImage` at production size, decode with `CIDetector(ofType: CIDetectorTypeQRCode)`, assert decoded string equals `ShareURL.appStore.absoluteString`. Guards against styling breaking scannability.
- **`ShareURLTests`**
    - `testAppStoreURLIsValid` — non-nil, scheme `https`, host `apps.apple.com`.
    - `testShareCaptionContainsURL` — caption includes `appStore.absoluteString`.

### Manual QA checklist

- [ ] iPhone simulator: Library pick, image renders in all 3 aspects, toggle off clears.
- [ ] Physical device: Camera capture works; permission prompt fires once.
- [ ] Permission-denied path: alert shows, Settings link opens app settings, source flips to Library.
- [ ] Share sheet to Messages: image + caption both visible; tap URL opens App Store.
- [ ] Share sheet to Instagram Story: image posts; caption stripped (expected); clipboard holds URL; manual paste into link sticker works.
- [ ] Second device scans QR badge from shared image → App Store product page opens.
- [ ] VoiceOver: toggle, segmented control, QR badge all announce correctly.
- [ ] iPad Pro 13": sheet layout holds; aspect picker functional.

### Out of scope for tests

- SwiftUI composition of `SelfieOverlayShareView` (visual; covered by manual QA).
- `CameraPicker` / `PhotosPicker` representables (thin system wrappers).

## Implementation Order

1. `ShareURL.swift` + tests.
2. `QRBadge.swift` + tests.
3. `CameraPicker.swift`.
4. `SelfieOverlayShareView` modification (add `downloadURL`, embed `QRBadge`).
5. `ShareCardSheet` modification (toggle, source picker, branching, clipboard copy, caption).
6. Info.plist: confirm `NSCameraUsageDescription` present; add if missing.
7. Manual QA pass on device.

## Risks / Open Questions

- **QR + branding contrast:** navy-on-cream is the inverse of typical QR. If scan reliability degrades on photo backgrounds, fall back to a solid cream chip behind the QR with navy modules. Decide from test renders.
- **Clipboard-on-share side effect:** silently overwriting the user's clipboard on every share is mildly invasive. Mitigation: only copy when the selfie flow is active (where the Instagram-Story use case applies). Re-evaluate if feedback surfaces.
- **App Store URL stability:** Apple URL scheme `apps.apple.com/app/<slug>/id<number>` is stable; no action needed.
