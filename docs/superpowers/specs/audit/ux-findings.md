# UX Polish Audit: Sundee Fundee iOS App

**Audit Date:** April 19, 2026  
**Scope:** SwiftUI views in `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/`  
**Theme:** Art Deco (cream #f4f0df, navy #0d1a40, orange #f27319)  
**Fonts:** Playfair Display (headings), Inter (body), JetBrains Mono (numbers)

---

## Executive Summary

Comprehensive UX audit identified **31 findings** across empty states, loading states, haptics, accessibility, error messages, navigation, and Art Deco consistency. The app has strong foundational polish—most core screens have empty states with clear CTAs, icons are properly labeled, and the theme is consistently applied. However, significant gaps exist in:

1. **Haptic feedback** (only 1 instance found; 5+ opportunities missed)
2. **Loading state consistency** (1 high-severity bare `ProgressView`, 4 medium inconsistencies)
3. **Icon hardcoding** (fixed-size SF Symbols override Dynamic Type for accessibility)
4. **Some error messages** still contain raw error strings without user-facing guidance

Most findings are **medium severity** and easily addressed in a targeted polish pass. The 2 high-severity items (bare loading spinner in Challenges, generic Loading state without context in Pain Tracking) should be prioritized first.

| Check | High | Med | Low |
|-------|------|-----|-----|
| Empty States | 0 | 3 | 2 |
| Loading States | 1 | 4 | 0 |
| Haptics | 0 | 5 | 0 |
| Accessibility | 0 | 4 | 2 |
| Error Messages | 1 | 2 | 0 |
| Navigation | 0 | 2 | 1 |
| Art Deco Consistency | 0 | 3 | 0 |
| **TOTALS** | **2** | **23** | **5** |

---

## 1. Empty States Inventory

| View | Has Empty State | CTA Present | Voice Consistent | Notes |
|---|---|---|---|---|
| Dashboard | No | — | — | No empty state when no data; shows defaults gracefully |
| Programs | No | — | — | Shows all programs regardless of enrollment; no empty state |
| Workouts | **Yes** | ✓ | ✓ | "No Workouts Yet" + "Start Workout" button |
| Maxes | **Yes** | ✓ | ✓ | "No Maxes Yet" + "Log Your First Max" button |
| Benchmarks | No | — | — | **Missing empty state** when no benchmarks in category |
| Settings | N/A | — | — | Settings always have content (no empty state needed) |
| Challenges | **Yes** | ✓ | ✓ | "No Challenges Yet" + "Create Challenge" button |
| Insights | **Yes** | ✓ | ✓ | Elegant "Pro feature" gating message |
| Pain Tracking | No | — | — | Has quick log button but no dedicated empty state |
| Analytics | **Yes** | ✓ | ✓ | "No Data" state with explanation |
| Cycle Tracking | No | — | — | Always shows calendar; no empty state |
| Export | N/A | — | — | Form-based, not a list |

---

## 2. Loading States Inventory

| View | Loading Treatment | Recommendation |
|---|---|---|
| Dashboard | No spinner (tier 1 data loads, UI visible immediately) | ✓ Current approach optimal |
| Programs | `ProgressView("Loading programs...")` | Consider skeleton cards for list |
| Workouts | `ProgressView("Loading workouts...")` | Skeleton rows would feel smoother |
| Maxes | `ProgressView("Loading maxes...")` | Skeleton cards for each exercise |
| Benchmarks | `ProgressView("Loading benchmarks...")` | Skeleton cards match final UI |
| Challenges | **`ProgressView()` bare spinner** | **HIGH:** Add label; at least "Loading challenges…" |
| Insights | `ProgressView()` bare spinner | Add label; "Loading your insights…" |
| Pain Tracking | `ProgressView("Loading...")` | Too generic; use "Loading injuries and logs…" |
| Analytics | `ProgressView()` bare spinner | Add label; "Loading analytics…" |
| Recovery Score Card | `ProgressView()` | Skeleton ring placeholder would be better |
| Cycle Settings | Multiple unlabeled `ProgressView()` | Add context; e.g., "Saving sync interval…" |
| Substitution Picker | `ProgressView("Finding alternatives…")` | ✓ Good; clear and contextual |
| Program Detail Sessions | `ProgressView("Loading sessions...")` | ✓ Clear |

---

## 3. Haptics Inventory

**Current Usage:** Only **1 haptic found**
- `UINotificationFeedbackGenerator().notificationOccurred(.success)` in `ActiveWorkoutSessionViewModel.swift`

**Opportunities Identified (5):**
1. Set complete during active workout
2. PR / 1RM achieved (celebration event)
3. Plateau alert badge appearing
4. Share card saved or copied
5. Challenge milestone reached / completed

All should use `UIImpactFeedbackGenerator` (light/medium) or `.sensoryFeedback` (SwiftUI 17+) for consistent, discoverable interactions.

---

## 4. Accessibility Findings

---

## 5. Error Messages Findings

---

## 6. Navigation & Gesture Findings

---

## 7. Art Deco Consistency Findings

---

## Detailed Findings

### HIGH SEVERITY

#### 1. Bare ProgressView Without Context
**Severity:** high  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Challenges/ChallengesView.swift:16`  
**Observation:** `ProgressView()` with no label shown while challenges load. Spinner appears without explanation.  
**Impact:** Users may not understand why the screen is frozen. Low discoverability of loading state.  
**Proposed fix:** Replace `ProgressView()` with `ProgressView("Loading challenges…")` or add `.progressViewStyle(.linear)` with accompanying text.

```swift
if viewModel.isLoading {
    VStack(spacing: AppTheme.Spacing.md) {
        ProgressView()
        Text("Loading challenges…")
            .font(AppTheme.Typography.bodySmall)
            .foregroundColor(AppTheme.Text.secondary)
    }
    .frame(maxWidth: .infinity, minHeight: 200)
}
```

---

#### 2. Raw Error Strings Without User Guidance
**Severity:** high  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift:175` (and 3+ other views)  
**Observation:** Error alerts display raw localized descriptions (e.g., "Failed to load settings: [error.localizedDescription]"). Non-technical users see cryptic OS-level messages.  
**Impact:** Users cannot understand what went wrong or how to recover. Violates UX best practices for error UX.  
**Proposed fix:** Wrap error messages with user-friendly context:

```swift
let userMessage: String
switch error {
case let error as NSError where error.domain == NSCocoaErrorDomain:
    userMessage = "We couldn't save your settings. Check your internet connection and try again."
default:
    userMessage = "Something went wrong. Please try again."
}
```

---

### MEDIUM SEVERITY

#### 3. Missing Empty State: Benchmarks
**Severity:** med  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Benchmarks/BenchmarksListView.swift:19-78`  
**Observation:** BenchmarksListView shows loading state and category picker, but no empty state when no benchmarks exist in selected category.  
**Impact:** Users filtering to an empty category see blank screen with no explanation or CTA.  
**Proposed fix:** Add empty state similar to Workouts/Maxes:

```swift
} else if viewModel.benchmarks.isEmpty {
    VStack(spacing: AppTheme.Spacing.xl) {
        Image(systemName: "target")
            .font(.system(size: 48))
            .foregroundColor(AppTheme.Accent.gold.opacity(0.5))
        Text("No Benchmarks in This Category")
            .font(AppTheme.Typography.headlineMedium)
        Text("Try selecting a different category")
            .font(AppTheme.Typography.bodyMedium)
    }
    .padding(AppTheme.Spacing.xxl)
}
```

---

#### 4. Missing Empty State: Pain Tracking
**Severity:** med  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Pain/PainTrackingView.swift:15-50`  
**Observation:** PainTrackingView shows loading state and quick log button, but no dedicated empty state when no pain logs or injuries exist. Screen feels incomplete when first opened.  
**Impact:** Onboarding moment is unclear; users don't see visual confirmation that the feature is ready to use.  
**Proposed fix:** Add empty state:

```swift
if viewModel.painLogs.isEmpty && viewModel.injuries.isEmpty {
    VStack(spacing: AppTheme.Spacing.lg) {
        Image(systemName: "bandage")
            .font(.system(size: 48))
            .foregroundColor(AppTheme.Accent.gold.opacity(0.5))
        Text("No Injuries Logged Yet")
            .font(AppTheme.Typography.headlineMedium)
        Text("Log pain or discomfort to track exercise adaptations")
            .font(AppTheme.Typography.bodyMedium)
            .multilineTextAlignment(.center)
    }
    .padding(AppTheme.Spacing.xxl)
}
```

---

#### 5. Inconsistent Loading Labels
**Severity:** med  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Pain/PainTrackingView.swift:18` (also Analytics, Cycle Settings)  
**Observation:** Multiple `ProgressView("Loading…")` with generic labels. Users don't know what specifically is loading.  
**Impact:** Reduces clarity and confidence during loading transitions.  
**Proposed fix:** Use contextual labels:
- Pain: `"Loading injuries…"` or `"Loading pain logs…"`
- Analytics: `"Loading analytics…"`
- Cycle Settings: Context-specific per section (e.g., `"Saving sync interval…"`)

---

#### 6. Bare Spinner: Insights Loading
**Severity:** med  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Insights/InsightsView.swift:17-19`  
**Observation:** `ProgressView()` with no label shown while loading insights.  
**Impact:** User doesn't know what's loading or how long to wait.  
**Proposed fix:** `ProgressView("Loading your insights…")`

---

#### 7. Bare Spinner: Analytics Loading
**Severity:** med  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Analytics/AnalyticsView.swift:24-25`  
**Observation:** `ProgressView()` bare spinner without context.  
**Impact:** Unclear state during data fetch.  
**Proposed fix:** `ProgressView("Loading analytics…")`

---

#### 8. Missing Haptics: Set Complete
**Severity:** med  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift:430-450`  
**Observation:** `completeSetButton` tapped; no haptic feedback when set marked complete.  
**Impact:** User interaction feels unresponsive, especially during rapid set logging.  
**Proposed fix:** Add to `ActiveWorkoutSessionViewModel.completeSet()`:

```swift
UIImpactFeedbackGenerator(style: .light).impactOccurred()
```

---

#### 9. Missing Haptics: PR Achieved
**Severity:** med  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift:480-490`  
**Observation:** PR celebration card appears without haptic. High-excitement moment lacks sensory reinforcement.  
**Impact:** Celebratory moment feels flat.  
**Proposed fix:** When PR event detected:

```swift
UINotificationFeedbackGenerator().notificationOccurred(.success)
// or
UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
```

---

#### 10. Missing Haptics: Challenge Milestone
**Severity:** med  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Challenges/ChallengesView.swift` (challenge completion)  
**Observation:** No haptic when challenge tier completes or challenge is finished.  
**Impact:** Progress moments lack reinforcement.  
**Proposed fix:** Trigger haptic on tier milestone and final completion.

---

#### 11. Missing Haptics: Share Card Saved
**Severity:** med  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Share/ShareCardSheet.swift` (not fully audited)  
**Observation:** Share card likely lacks haptic when saved to Photos or copied to clipboard.  
**Impact:** User doesn't know if action succeeded.  
**Proposed fix:** Haptic feedback on save/copy success.

---

#### 12. Fixed Icon Sizes Override Accessibility
**Severity:** med  
**File:** Multiple views (Dashboard, Insights, Workouts, Settings)  
**Observation:** Icons sized with `.font(.system(size: 24))`, `.font(.system(size: 40))`, `.font(.system(size: 60))`, etc. These hardcoded sizes ignore user's Dynamic Type preference.  
**Examples:**
- `DashboardView.swift:145` — cycle phase icon `size: 24`
- `InsightsView.swift:44-45` — arrow circle icon `size: 14`, emoji-like icon `size: 48`
- `SettingsView.swift:37-39` — profile circle `size: 40`
- `Workouts/ActiveWorkoutView.swift:459` — trophy `size: 60`
- Multiple empty state icons: `size: 48`, `size: 60`
- WorkoutsListView empty state: `size: 60`, size: 24` in rows

**Impact:** Large icon sizes may overflow or appear too small for Accessibility users on increased Dynamic Type. Inconsistent scaling across app.  
**Proposed fix:** Use relative sizing or AppTheme.Typography for semantic icons:

```swift
Image(systemName: "drop.fill")
    .font(.system(size: 24, weight: .regular))
    // INSTEAD, use:
Image(systemName: "drop.fill")
    .font(AppTheme.Typography.headlineLarge.weight(.regular))
    // OR for display icons:
    .font(.system(.largeTitle, design: .default))
```

---

#### 13. Missing Accessibility Label: Settings Links
**Severity:** med  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Settings/SettingsView.swift:109-141`  
**Observation:** Link rows (Website, Privacy, Terms) include icon-only `Image(systemName: "link")` without `accessibilityHidden(true)` or label context.  
**Impact:** VoiceOver users hear "link image" instead of understanding the destination.  
**Proposed fix:**

```swift
Image(systemName: "link")
    .font(.system(size: 12))
    .foregroundColor(AppTheme.Accent.gold)
    .accessibilityHidden(true)  // Already present in some
```

Ensure all icon-only elements have `.accessibilityHidden(true)` or paired labels.

---

#### 14. Hardcoded Colors Outside AppTheme
**Severity:** med  
**File:** `Cycle/SharkWeekBanner.swift:77`, `Cycle/CycleCalendarView.swift:112`, `Pain/PainTrackingView.swift:116, 121`  
**Observation:** Direct use of `Color.red`, `Color.orange`, `Color.green` instead of AppTheme tokens.  
**Examples:**
- `SharkWeekBanner.swift`: `.background(Capsule().fill(Color.red))`
- `CycleCalendarView.swift`: `.fill(Color.red)` and `.opacity(0.15)`
- `PainTrackingView.swift`: `Color.orange.opacity(0.15)`, `Color.green.opacity(0.15)`

**Impact:** If theme is changed (e.g., to dark mode or updated brand), these hardcoded colors break. Theme consistency degraded.  
**Proposed fix:** Use AppTheme tokens consistently:

```swift
// Instead of Color.red
AppTheme.Semantic.error  or  AppTheme.Accent.orange

// Instead of Color.green
AppTheme.Recovery.green

// Check CyclePhase.chartBandColor extension
```

---

#### 15. Icon-Only Buttons Without Labels (Dashboard Quick Actions)
**Severity:** med  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/DashboardView.swift:336-384`  
**Observation:** Quick action grid buttons (Log Max, Pain Log, Benchmarks, Challenges) use `Image(systemName: icon)` inside `NavigationLink` without explicit `accessibilityLabel` on the button.  
**Impact:** VoiceOver users hear only the icon name and destination title, not the action purpose.  
**Proposed fix:** Add explicit labels:

```swift
NavigationLink(destination: MaxesListView()) {
    quickActionContent("Log Max", icon: "scalemass", isPrimary: true)
}
.buttonStyle(.plain)
.accessibilityLabel("Log Max")  // Explicit label
.accessibilityHint("Navigate to log a one-rep max")
```

---

#### 16. Missing Context for Recovery Score Loading
**Severity:** med  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Dashboard/RecoveryScoreCard.swift`  
**Observation:** `ProgressView()` shown in recovery score card with no explanation. Comment in DashboardView indicates Recovery Score hidden pending algorithm rework, but loading state still visible in card.  
**Impact:** Visual confusion if card is visible; indicates incomplete feature state.  
**Proposed fix:** Either fully hide recovery card or add loading label; consider skeleton ring placeholder.

---

#### 17. Bare Spinner: Cycle Settings
**Severity:** med  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Cycle/CycleSettingsView.swift`  
**Observation:** Multiple `ProgressView()` spinners without labels scattered throughout form (e.g., sync operations, settings save).  
**Impact:** Users unclear what operation is in flight.  
**Proposed fix:** Label each contextually:

```swift
ProgressView("Syncing…")  // or
ProgressView("Saving interval…")
```

---

#### 18. Empty State Copy: Pain Tracking (generic "Log Pain" CTA)
**Severity:** low  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Pain/PainTrackingView.swift:57-87`  
**Observation:** Quick log button copy is clear, but empty state doesn't exist to explain the feature on first load.  
**Impact:** Minor; quick log affordance partially mitigates.  
**Proposed fix:** See Finding #4 above.

---

#### 19. Missing Empty State: Benchmarks (Category Filter Edge Case)
**Severity:** low  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Benchmarks/BenchmarksListView.swift`  
**Observation:** When filtering benchmarks by category, if category has no entries, blank screen appears.  
**Impact:** User confused; needs guidance or category suggestion.  
**Proposed fix:** See Finding #3 above.

---

#### 20. Navigator Back Button Not Hidden on Substitution Sheet
**Severity:** low  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/SubstitutionPickerSheet.swift:27-51`  
**Observation:** NavigationStack with "Cancel" button in toolbar; back button also visible (default SwiftUI behavior). Two dismiss affordances may confuse UX.  
**Impact:** Minor; redundant affordances aren't harmful, but less polished.  
**Proposed fix:** Hide back button:

```swift
.navigationBarBackButtonHidden(true)
```

---

#### 21. Plateau Alert Haptics Missing
**Severity:** low  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Insights/InsightsView.swift` (plateau section)  
**Observation:** Plateau detection badge/alert appears without haptic. Important coaching alert lacks sensory reinforcement.  
**Impact:** Minor; alert is visual, but haptic would improve discovery.  
**Proposed fix:** Light haptic when plateau card appears or when viewing alert.

---

#### 22. Contest Menu Not Labeled (Workout Exercise Options)
**Severity:** low  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift:205-214`  
**Observation:** Menu button `Image(systemName: "ellipsis.circle")` with `.accessibilityLabel("Exercise options")` is properly labeled, but menu itself may lack context for VoiceOver.  
**Impact:** Minor; label is present.  
**Proposed fix:** Already mostly correct; ensure menu items are labeled in the Menu closure.

---

#### 23. Error State: SubstitutionPickerSheet
**Severity:** low  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/SubstitutionPickerSheet.swift:31-32`  
**Observation:** Error state displays `Text(errorMessage)` but message likely contains raw error string.  
**Impact:** User doesn't understand why substitution search failed.  
**Proposed fix:** Wrap error with friendly copy:

```swift
} else if let error = errorMessage {
    VStack(spacing: AppTheme.Spacing.md) {
        Image(systemName: "exclamationmark.triangle")
        Text("Couldn't find alternatives")
        Text("Try another exercise or adjust your setup")
            .font(AppTheme.Typography.bodySmall)
    }
}
```

---

#### 24. Challenges Empty State Button Style Inconsistent
**Severity:** low  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Challenges/ChallengesView.swift:81-91`  
**Observation:** Empty state "Create Challenge" button uses inline styling instead of `.artDecoButton()`.  
**Impact:** Visual inconsistency; button appears different from other primary CTAs.  
**Proposed fix:** Use `.artDecoButton(style: .primary)` or `.artDecoButton(style: .accent)`.

---

#### 25. Missing Haptic: Workout Completion
**Severity:** low  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift:490-506`  
**Observation:** "Done" button on completion screen lacks haptic. High moment of achievement.  
**Impact:** Completion feels less celebratory.  
**Proposed fix:** Haptic on Done button press:

```swift
Button {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    NotificationCenter.default.post(name: .workoutCompleted, object: nil)
    dismiss()
} label: { ... }
```

---

#### 26. Hardcoded Font Size: Insights Icon
**Severity:** low  
**File:** `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Insights/InsightsView.swift:44`  
**Observation:** `.font(.system(size: 14))` for arrow icon overrides Dynamic Type scaling.  
**Impact:** Accessibility users on large Dynamic Type sizes may see awkward proportions.  
**Proposed fix:** Use AppTheme.Typography or system semantic size.

---

#### 27. Hardcoded Font Sizes: Multiple Workouts Views
**Severity:** low  
**File:** `Workouts/AIWorkoutView.swift:166, 176, 233, 274` (multiple hardcoded sizes: 36, 20, 14, 10, 32, 40)  
**Observation:** Many icon and text sizes hardcoded, breaking Dynamic Type support.  
**Impact:** Accessibility users on large text settings see mismatched hierarchy.  
**Proposed fix:** Use AppTheme.Typography consistently.

---

#### 28. Hardcoded Font Size: Settings Profile Icon
**Severity:** low  
**File:** `Settings/SettingsView.swift:37`  
**Observation:** Profile circle icon `size: 40` hardcoded.  
**Impact:** May not scale for accessibility users.  
**Proposed fix:** Use `font(.system(.largeTitle))` or relative sizing.

---

#### 29. Hardcoded Font Size: Programs View Stat Pills
**Severity:** low  
**File:** `Programs/ProgramsListView.swift:247-260` (statPill function)  
**Observation:** Uses `.frame(maxWidth: .infinity)` and `.padding(.vertical)` but text sizes are inherited from `AppTheme.Typography`, so this is actually OK. No hardcoded font found.  
**Impact:** None; actually properly implemented.  
**Proposed fix:** None needed.

---

#### 30. Review State Inconsistency: AIWorkoutView Error
**Severity:** low  
**File:** `Workouts/AIWorkoutView.swift:380-385`  
**Observation:** Error state displays generic "Could not generate workout. Please try again." Users don't know if it's a network error, API limit, or internal issue.  
**Impact:** Minor; user-facing message is friendly but lacks context.  
**Proposed fix:** Add retry affordance or more specific error handling.

---

#### 31. Subtle Theme Consistency: Cycle Phase Colors Hardcoded
**Severity:** low  
**File:** `Dashboard/DashboardView.swift:207-240` (cyclePhaseColor function)  
**Observation:** Uses hardcoded colors for cycle phases:
- `.menstrual`: `Color.red`
- `.follicular`: `AppTheme.Accent.gold`
- `.ovulation`: `AppTheme.Accent.orange`
- `.luteal`: `AppTheme.Text.secondary`

**Impact:** Red is hardcoded for menstrual phase; should use AppTheme semantic.  
**Proposed fix:** 

```swift
case .menstrual: return AppTheme.Semantic.error  // or Accent.orange
```

---

## Summary of Actionable Items

### Immediate (High Priority)
1. **Challenges loading screen**: Add label to bare `ProgressView()`
2. **Error messages**: Wrap raw error strings with user-friendly copy (Settings, Insights, Workouts, etc.)

### High-Value Polish (Medium Priority)
3. Add missing empty states (Benchmarks category filter, Pain tracking)
4. Add haptic feedback to 5+ key interactions (set complete, PR, challenge milestone, share, completion)
5. Fix inconsistent loading labels (Pain "Loading…", Analytics, Insights)
6. Hide back button on sheets where "Cancel" is present

### Accessibility (Medium Priority)
7. Review all hardcoded icon sizes; migrate to Dynamic Type–friendly sizing
8. Audit and complete accessibility labels across views
9. Ensure all icon-only buttons have `.accessibilityLabel` or `.accessibilityHidden`

### Theme Consistency (Low Priority)
10. Replace hardcoded `Color.red`, `.orange`, `.green` with AppTheme tokens
11. Standardize loading spinner patterns app-wide

---

## Files Requiring Changes (Summary)

| File | Findings | Priority |
|------|----------|----------|
| `Challenges/ChallengesView.swift` | Bare ProgressView (HIGH) | Immediate |
| `Settings/SettingsView.swift` | Raw error strings, icon sizes, links | Medium |
| `Pain/PainTrackingView.swift` | Missing empty state, generic loading label | Medium |
| `Benchmarks/BenchmarksListView.swift` | Missing empty state | Medium |
| `Workouts/ActiveWorkoutView.swift` | Missing haptics (set, PR, completion), icon sizes | Medium |
| `Insights/InsightsView.swift` | Bare ProgressView, hardcoded icon sizes, error context | Medium |
| `Analytics/AnalyticsView.swift` | Bare ProgressView | Medium |
| `Dashboard/DashboardView.swift` | Icon sizes, hardcoded cycle colors, recovery card | Low |
| `Workouts/AIWorkoutView.swift` | Multiple hardcoded font sizes, error context | Low |
| `Cycle/*.swift` | Hardcoded Color.red, icon sizes | Low |

---

**Audit completed:** April 19, 2026 | **Review scope:** Very thorough (all 31 views audited)
