# ActiveWorkoutView Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a full-screen modal active workout view that guides users through sets one at a time, replacing the current save-and-dismiss behavior.

**Architecture:** Create `ActiveWorkoutView` as a single SwiftUI view that binds to the existing `ActiveWorkoutSessionViewModel`. The AI workout preview presents this view via a `fullScreenCover` triggered by a `@State` flag and a `@StateObject` holding the session ViewModel.

**Tech Stack:** SwiftUI, Swift 6 strict concurrency, existing AppTheme/ArtDecoCard/ArtDecoButtonStyle components.

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift` | Create | Full-screen modal: header, progress, exercise card, rest timer, complete button, completion screen |
| `SundeeFundeeKit/UI/Views/Workouts/AIWorkoutView.swift` | Modify | Replace `startGeneratedWorkout()` with presentation of ActiveWorkoutView |

---

### Task 1: Create ActiveWorkoutView skeleton with header and state binding

**Files:**
- Create: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`

- [ ] **Step 1: Create the file with the view skeleton**

Create `ActiveWorkoutView.swift` with:
- `@ObservedObject var viewModel: ActiveWorkoutSessionViewModel`
- `@Environment(\.dismiss) private var dismiss`
- `@State private var showAbandonAlert = false`
- Body: a `ZStack` that shows either the active workout content or the completion screen based on `viewModel.isComplete`
- Active workout content: `VStack` with header bar, progress section, ScrollView placeholder, and Complete Set button
- Header bar: "Close" button left, workout name center, elapsed time right
- Elapsed time formatted as `MM:SS` from `viewModel.elapsedSeconds`
- `.artDecoBackground()` modifier on the outermost view

```swift
import SwiftUI

@available(iOS 18.0, macOS 15.0, watchOS 11.0, *)
struct ActiveWorkoutView: View {
    @ObservedObject var viewModel: ActiveWorkoutSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAbandonAlert = false

    var body: some View {
        ZStack {
            if viewModel.isComplete {
                completionView
            } else {
                activeWorkoutView
            }
        }
        .artDecoBackground()
        .alert("Abandon Workout?", isPresented: $showAbandonAlert) {
            Button("Abandon", role: .destructive) {
                Task { await viewModel.abandonWorkout() }
                dismiss()
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your progress will be saved.")
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button("Close") {
                showAbandonAlert = true
            }
            .foregroundColor(AppTheme.Text.secondary)
            .font(AppTheme.Typography.labelLarge)

            Spacer()

            Text(viewModel.workout.name)
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.primary)
                .lineLimit(1)

            Spacer()

            Text(formatElapsedTime(viewModel.elapsedSeconds))
                .font(AppTheme.Typography.monoLarge)
                .foregroundColor(AppTheme.Accent.orange)
                .monospacedDigit()
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    // MARK: - Active Workout

    private var activeWorkoutView: some View {
        VStack(spacing: 0) {
            headerBar

            // Progress (placeholder — built in Task 2)
            progressSection

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Current exercise card (built in Task 3)
                    currentExerciseCard

                    // Rest timer (built in Task 4)
                    if viewModel.isResting {
                        restTimerCard
                    }

                    Spacer(minLength: AppTheme.Spacing.lg)
                }
                .padding(AppTheme.Spacing.lg)
            }

            // Bottom action button (built in Task 5)
            completeSetButton
        }
    }

    // Placeholder stubs — filled in later tasks
    private var progressSection: some View { Color.clear.frame(height: 40) }
    private var currentExerciseCard: some View { EmptyView() }
    private var restTimerCard: some View { EmptyView() }
    private var completeSetButton: some View { EmptyView() }
    private var completionView: some View { EmptyView() }

    // MARK: - Formatting

    private func formatElapsedTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `cd /Users/dustinober/Projects/sundee-fundee/SundeeFundeeApp && xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Add the new file to the Xcode project**

Since this project uses Xcode, the file may need to be added to the project. Run:
```bash
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundeeApp
# Check if xcodegen is being used
ls project.yml 2>/dev/null
```
If `project.yml` exists, no action needed (xcodegen auto-discovers). If not, add via Xcode or use `ruby` script to add to pbxproj. Verify build succeeds after.

- [ ] **Step 4: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift
git commit -m "feat(workout): add ActiveWorkoutView skeleton with header and state binding"
```

---

### Task 2: Build the progress section

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`

- [ ] **Step 1: Replace the `progressSection` placeholder**

Replace the `progressSection` computed property with a segmented progress bar and stats text:

```swift
private var progressSection: some View {
    VStack(spacing: AppTheme.Spacing.xs) {
        // Segmented progress bar — one segment per exercise
        HStack(spacing: 3) {
            ForEach(Array(viewModel.workout.exercises.enumerated()), id: \.offset) { index, exercise in
                let completedInExercise = exercise.targetSets.filter(\.isComplete).count
                let totalInExercise = exercise.targetSets.count
                let isCurrent = index == viewModel.currentExerciseIndex
                let isComplete = completedInExercise == totalInExercise

                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        isComplete ? AppTheme.Accent.orange :
                        isCurrent ? AppTheme.Accent.orange.opacity(0.5) :
                        AppTheme.Background.card.opacity(0.5)
                    )
                    .frame(height: 6)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)

        // Stats line
        HStack {
            Text("\(viewModel.completedSets) of \(viewModel.totalSets) sets")
            Text("·")
            Text("Exercise \(viewModel.currentExerciseIndex + 1) of \(viewModel.workout.exercises.count)")
        }
        .font(AppTheme.Typography.labelSmall)
        .foregroundColor(AppTheme.Text.secondary)
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift
git commit -m "feat(workout): add segmented progress bar to ActiveWorkoutView"
```

---

### Task 3: Build the current exercise card

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`

- [ ] **Step 1: Replace the `currentExerciseCard` placeholder**

```swift
private var currentExerciseCard: some View {
    ArtDecoCard {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Exercise name
            Text(viewModel.currentExercise?.name ?? "")
                .font(AppTheme.Typography.headlineLarge)
                .foregroundColor(AppTheme.Text.primary)

            // Set info
            if let exercise = viewModel.currentExercise {
                Text("Set \(viewModel.currentSetIndex + 1) of \(exercise.targetSets.count)")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }

            // Stat boxes: Reps, Weight, Rest
            HStack(spacing: AppTheme.Spacing.lg) {
                statBox(
                    value: "\(viewModel.currentSet?.reps ?? 0)",
                    label: "Reps"
                )
                statBox(
                    value: viewModel.currentSet?.prescribedWeight ?? 0 > 0
                        ? "\(Int(viewModel.currentSet?.prescribedWeight ?? 0))" : "BW",
                    label: viewModel.currentSet?.prescribedWeight ?? 0 > 0 ? "lb" : ""
                )
                if let exercise = viewModel.currentExercise, exercise.restMinutes > 0 {
                    statBox(
                        value: String(format: "%.0f", exercise.restMinutes * 60),
                        label: "sec rest"
                    )
                }
            }
        }
    }
}

private func statBox(value: String, label: String) -> some View {
    VStack(spacing: 2) {
        Text(value)
            .font(AppTheme.Typography.displaySmall)
            .foregroundColor(AppTheme.Text.primary)
            .monospacedDigit()
        if !label.isEmpty {
            Text(label)
                .font(AppTheme.Typography.labelSmall)
                .foregroundColor(AppTheme.Text.secondary)
        }
    }
    .frame(maxWidth: .infinity)
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift
git commit -m "feat(workout): add current exercise card to ActiveWorkoutView"
```

---

### Task 4: Build the rest timer card

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`

- [ ] **Step 1: Replace the `restTimerCard` placeholder**

```swift
private var restTimerCard: some View {
    VStack(spacing: AppTheme.Spacing.sm) {
        Text("REST")
            .font(AppTheme.Typography.labelMedium)
            .foregroundColor(AppTheme.Accent.gold)
            .tracking(2)

        Text(formatRestTime(viewModel.restTimeRemaining))
            .font(.system(size: 40, weight: .bold, design: .monospaced))
            .foregroundColor(AppTheme.Text.cream)
            .monospacedDigit()

        // Next set info
        if let exercise = viewModel.currentExercise {
            let nextSetIndex = viewModel.currentSetIndex + 1
            let set = exercise.targetSets[safe: nextSetIndex]
            if let set = set {
                Text("Next: Set \(nextSetIndex + 1) of \(set.reps) reps")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Accent.gold)
            }
        }

        Button("Skip Rest") {
            viewModel.skipRest()
        }
        .font(AppTheme.Typography.labelLarge)
        .foregroundColor(AppTheme.Accent.gold)
        .padding(.top, AppTheme.Spacing.xs)
    }
    .frame(maxWidth: .infinity)
    .padding(AppTheme.Spacing.xl)
    .background(AppTheme.Background.navy)
    .cornerRadius(AppTheme.CornerRadius.medium)
}

private func formatRestTime(_ seconds: TimeInterval) -> String {
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", mins, secs)
}
```

Note: This uses a safe array subscript. If the codebase doesn't have one, add this extension at the bottom of the file:

```swift
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift
git commit -m "feat(workout): add rest timer card to ActiveWorkoutView"
```

---

### Task 5: Build the Complete Set button and onAppear

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`

- [ ] **Step 1: Replace the `completeSetButton` placeholder**

```swift
private var completeSetButton: some View {
    VStack(spacing: 0) {
        Divider().background(AppTheme.Background.card)

        Button {
            Task {
                let reps = viewModel.currentSet?.reps ?? 0
                let weight = viewModel.currentSet?.prescribedWeight ?? 0
                await viewModel.completeSet(actualReps: reps, completedWeight: weight)
            }
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Complete Set")
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(ArtDecoButtonStyle(style: .accent))
        .disabled(viewModel.isResting || viewModel.isComplete)
        .padding(AppTheme.Spacing.lg)
    }
    .background(AppTheme.Background.cream)
}
```

- [ ] **Step 2: Add `.onAppear` to call `viewModel.beginSession()` and `.task` for dismissal on completion**

In the `activeWorkoutView` computed property, add `.onAppear` to the outer `VStack`:

```swift
// In activeWorkoutView, on the outer VStack, add:
.onAppear {
    viewModel.beginSession()
}
.onChange(of: viewModel.isComplete) { _, isComplete in
    if isComplete {
        // Stay on completion screen — user taps Done to dismiss
    }
}
```

- [ ] **Step 3: Build to verify**

Run: `xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift
git commit -m "feat(workout): add Complete Set button and session lifecycle to ActiveWorkoutView"
```

---

### Task 6: Build the completion screen

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift`

- [ ] **Step 1: Replace the `completionView` placeholder**

```swift
private var completionView: some View {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer(minLength: AppTheme.Spacing.xxl)

            // Trophy icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Accent.gold)

            // Title
            Text("Workout Complete!")
                .font(AppTheme.Typography.displayLarge)
                .foregroundColor(AppTheme.Text.primary)

            // Elapsed time
            Text(formatElapsedTime(viewModel.elapsedSeconds))
                .font(AppTheme.Typography.headlineMedium)
                .foregroundColor(AppTheme.Text.secondary)

            // Stats row
            HStack(spacing: AppTheme.Spacing.xl) {
                statBox(
                    value: "\(viewModel.completedSets)",
                    label: "Sets"
                )
                statBox(
                    value: "\(viewModel.workout.exercises.count)",
                    label: "Exercises"
                )
                statBox(
                    value: "\(viewModel.workout.duration)",
                    label: "Minutes"
                )
            }
            .padding(.horizontal, AppTheme.Spacing.xl)

            // PR celebrations
            ForEach(viewModel.celebrationEvents, id: \.self) { event in
                ArtDecoCard {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(AppTheme.Accent.gold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(celebrationTitle(event))
                                .font(AppTheme.Typography.headlineSmall)
                                .foregroundColor(AppTheme.Text.primary)
                            Text(celebrationSubtitle(event, unit: "lb"))
                                .font(AppTheme.Typography.bodySmall)
                                .foregroundColor(AppTheme.Text.secondary)
                        }
                    }
                }
            }

            // Done button
            Button {
                NotificationCenter.default.post(name: .aiWorkoutStarted, object: nil)
                dismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ArtDecoButtonStyle(style: .primary))
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.lg)

            Spacer(minLength: AppTheme.Spacing.xxl)
        }
    }
}
```

Note: `CelebrationEvent` doesn't conform to `Hashable`/`Identifiable`, so we need to use a different `ForEach` approach. Since the enum has associated values, wrap with `Indexed`:

```swift
// Replace the ForEach with indexed approach:
ForEach(Array(viewModel.celebrationEvents.enumerated()), id: \.offset) { index, event in
    ArtDecoCard {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(AppTheme.Accent.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text(celebrationTitle(event))
                    .font(AppTheme.Typography.headlineSmall)
                    .foregroundColor(AppTheme.Text.primary)
                Text(celebrationSubtitle(event, unit: "lb"))
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Text.secondary)
            }
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/ActiveWorkoutView.swift
git commit -m "feat(workout): add completion screen with celebrations to ActiveWorkoutView"
```

---

### Task 7: Wire ActiveWorkoutView into AIWorkoutView

**Files:**
- Modify: `SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/AIWorkoutView.swift`

- [ ] **Step 1: Add state properties for presenting the active workout**

In `AIWorkoutView`, add these properties below `@StateObject private var viewModel`:

```swift
@State private var activeWorkoutSession: ActiveWorkoutSessionViewModel?
@State private var showingActiveWorkout = false
```

- [ ] **Step 2: Replace `startGeneratedWorkout()` — change it to build the Workout and set up the session ViewModel instead of saving**

Replace the existing `startGeneratedWorkout()` method in `AIWorkoutViewModel`:

```swift
func startGeneratedWorkout() async {
    guard let generated = generatedWorkout else { return }

    let workout = Workout(
        date: Date(),
        name: "\(focus.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) — AI",
        exercises: generated.exercises.map { ex in
            let reps = Int(ex.reps.split(separator: "-").first ?? "8") ?? 8
            return Exercise(
                id: UUID().uuidString,
                name: ex.name,
                category: isWeightliftingExercise(ex.name) ? .compound : .accessory,
                bodyweight: ex.bodyweightOnly ? 1.0 : 0.0,
                targetSets: (0..<ex.sets).map { _ in
                    ExerciseSet(
                        reps: reps,
                        prescribedWeight: ex.weightKg ?? 0,
                        type: .fixed
                    )
                },
                restMinutes: ex.restMinutes ?? 1.5
            )
        },
        notes: "AI Generated — \(generated.coachingSummary)"
    )

    activeWorkoutSession = ActiveWorkoutSessionViewModel(workout: workout)
    showingActiveWorkout = true
}
```

Wait — the `activeWorkoutSession` and `showingActiveWorkout` state lives in the `View`, not the `ViewModel`. The ViewModel's `startGeneratedWorkout()` should instead just build and return the `Workout`, and the view handles presentation. Let me revise:

Keep the existing Workout-building logic in the ViewModel but change it to return the workout:

Replace `startGeneratedWorkout()` in `AIWorkoutViewModel`:

```swift
func buildWorkoutForSession() -> Workout? {
    guard let generated = generatedWorkout else { return nil }

    return Workout(
        date: Date(),
        name: "\(focus.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) — AI",
        exercises: generated.exercises.map { ex in
            let reps = Int(ex.reps.split(separator: "-").first ?? "8") ?? 8
            return Exercise(
                id: UUID().uuidString,
                name: ex.name,
                category: isWeightliftingExercise(ex.name) ? .compound : .accessory,
                bodyweight: ex.bodyweightOnly ? 1.0 : 0.0,
                targetSets: (0..<ex.sets).map { _ in
                    ExerciseSet(
                        reps: reps,
                        prescribedWeight: ex.weightKg ?? 0,
                        type: .fixed
                    )
                },
                restMinutes: ex.restMinutes ?? 1.5
            )
        },
        notes: "AI Generated — \(generated.coachingSummary)"
    )
}
```

- [ ] **Step 3: Add Identifiable conformance to ActiveWorkoutSessionViewModel**

In `SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift`, add `Identifiable` conformance:

```swift
// Change the class declaration from:
public class ActiveWorkoutSessionViewModel: ObservableObject {
// To:
public class ActiveWorkoutSessionViewModel: ObservableObject, Identifiable {
    public var id: String { workout.id }
```

- [ ] **Step 4: Add state property and fullScreenCover to the `AIWorkoutView` struct**

Add to `AIWorkoutView`:

```swift
@State private var activeWorkoutSession: ActiveWorkoutSessionViewModel?
```

Add the `fullScreenCover` modifier to the `NavigationStack` in `AIWorkoutView.body`, after `.toolbar { ... }`:

```swift
#if os(iOS)
.fullScreenCover(item: $activeWorkoutSession) { session in
    ActiveWorkoutView(viewModel: session)
}
#endif
```

- [ ] **Step 5: Update the "Start This Workout" button action**

In the preview view's "Start This Workout" button (around line 363-368), replace:

```swift
Button {
    Task {
        await viewModel.startGeneratedWorkout()
        NotificationCenter.default.post(name: .aiWorkoutStarted, object: nil)
        dismiss()
    }
}
```

With:

```swift
Button {
    if let workout = viewModel.buildWorkoutForSession() {
        activeWorkoutSession = ActiveWorkoutSessionViewModel(workout: workout)
    }
}
```

- [ ] **Step 6: Build to verify**

Run: `xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
git add SundeeFundee/Sources/SundeeFundeeKit/UI/ViewModels/ActiveWorkoutSessionViewModel.swift SundeeFundee/Sources/SundeeFundeeKit/UI/Views/Workouts/AIWorkoutView.swift
git commit -m "feat(workout): wire ActiveWorkoutView into AI workout flow"
```

---

### Task 8: Build, install, and test on device

**Files:** None (testing only)

- [ ] **Step 1: Build for physical device**

```bash
cd /Users/dustinober/Projects/sundee-fundee/SundeeFundeeApp
xcodebuild -project SundeeFundee.xcodeproj -scheme SundeeFundee \
  -destination 'id=00008140-00112D5E1E0B001C' \
  -derivedDataPath /tmp/sfbuild build 2>&1 | tail -5
```
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Install on device**

```bash
xcrun devicectl device install app --device 00008140-00112D5E1E0B001C \
  /tmp/sfbuild/Build/Products/Debug-iphoneos/SundeeFundee.app
```
Expected: App installed

- [ ] **Step 3: Launch app and test the full flow**

Using blitz-iphone MCP tools:
1. Launch `com.sundeefundee.app`
2. Navigate to Workouts tab → "+" → "Generate AI Workout"
3. Select Upper Body, Medium energy, Full Gym
4. Tap Generate Workout
5. In preview, tap "Start This Workout"
6. Verify: full-screen modal appears with exercise name, set info, progress bar
7. Tap "Complete Set" — verify it advances to next set
8. Verify rest timer appears after completing a set
9. Complete all sets
10. Verify completion screen appears with stats
11. Tap "Done" — verify dismiss back to workouts list

- [ ] **Step 4: Commit any fixes discovered during testing**

```bash
git add -A
git commit -m "fix(workout): address issues found during on-device testing"
```
