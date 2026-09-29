# Sundee Fundee Next Release Comprehensive Plan: The 4-Pillar Roadmap

**Date:** 2026-09-29  
**Status:** Approved for Implementation  
**Target:** Sundee Fundee 2.1 (iOS 18+, watchOS 11+)  
**Philosophy:** 100% Free, Zero Paywalls, Privacy-First, Strict Concurrency (Swift 6), CloudKit + HealthKit native.

---

## Executive Summary & Scope

Sundee Fundee 2.0 established the foundation of cycle-aware strength training, daily readiness scoring (Train / Modify / Recover), and foldable tabletop gym support. 

This comprehensive roadmap defines the next release across **four complementary pillars**:

1. **Pillar 1: Private Accountability & Micro-Pods (v2 Social Layer)** — 1-on-1 buddy pairing and private groups (capped at 8) via CloudKit `CKShare`, strict privacy sanitization, preset encouragement nudges, and cooperative weekly goals without toxic leaderboards.
2. **Pillar 2: Wrist Autonomy & Watch Complications (watchOS 11 v2)** — Standalone Apple Watch workout logging with `HKWorkoutSession` / `HKLiveWorkoutBuilder`, glanceable Watch Face Complications & Smart Stack widgets (Readiness & Cycle Phase), and wrist-haptic rest countdown alerts.
3. **Pillar 3: In-Gym Workout Flow (Supersets, Plate Math & Fitness Rings)** — Paired supersets/circuits in active workouts, an Art Deco barbell plate calculator, and precision calorie/duration recording in Apple Health to reliably close Apple Fitness Move and Exercise rings.
4. **Pillar 4: System Intelligence & Siri App Intents (iOS 18 Voice & Offline Polish)** — Conversational Siri queries for daily readiness and status logging, `AppShortcutsProvider` integration, and an explicit "Retry Now" manual flush control for queued offline writes in the Data Trust Center.

---

## Global Architectural Constraints

- **Strict Swift 6 Concurrency:** Pure domain logic lives in `DomainLayer/` as immutable `Sendable` structs. View models are `@MainActor`. I/O services and CloudKit coordinators are `actor`s.
- **Privacy by Default:** HealthKit metrics, cycle phase, symptoms, and pain ratings are **strictly private**. Shared snapshots contain only derived safe states (`DailyPresenceStatus`, completed session count, cooperative goal contributions).
- **Art Deco Visual System:** Only `AppTheme.*` tokens. Semantic Dynamic Type icons.
- **Apple Ecosystem First:** Zero third-party dependencies (SPM only for internal `SundeeFundeeKit`). Native HealthKit, CloudKit, WidgetKit, ActivityKit, and AppIntents.
- **Monetization Guard:** All features are free and fully unlocked. No paywalls, subscriptions, or gated access.

---

## Pillar 1: Private Accountability & Micro-Pods (v2 Social Layer)

### 1.1 Goals & Principles
- Connect users with 1 primary accountability buddy or a small private pod (maximum 8 members).
- **Zero Toxic Comparison:** No public feeds, no vanity follower counts, no leaderboard ranking by weight lifted or volume.
- **Cooperative Goals Only:** Goals reward showing up together (e.g. *"Group completes 20 sessions this week"* or *"Every member logs 1 movement day"*).
- **Preset Interactions:** No open-ended text messaging liability. Fast, supportive one-tap nudges (*"Thinking of you"*, *"Rest day well earned"*, *"Crushed it!"*).

### 1.2 Architecture & Components
- **`DomainLayer/Social/AccountabilityPod.swift`**:
  - Models `AccountabilityPod`, `PodMember`, `PodRole` (`owner`, `member`), and `CooperativeGoal`.
- **`DomainLayer/Social/SocialSnapshotBuilder.swift`**:
  - Accepts raw user records and applies an explicit `SocialVisibilityPolicy`.
  - Produces `SanitizedSocialSnapshot`: `dayKey`, `status` (`ready`, `tired`, `resting`, `trained`), `completedWorkoutCount`, and `timestamp`.
  - Explicitly strips out cycle phase, pain history, and raw HRV/sleep data.
- **`DataLayer/CloudKit/AccountabilityService.swift`**:
  - Manages `CKShare` creation, joining via universal link (`https://sundeefundee.com/pod/join?code=...` / custom URL scheme), member revocation, leaving, and owner succession.
- **`DomainLayer/Social/EncouragementService.swift`**:
  - Handles sending and receiving preset reaction tokens.
  - Queues outgoing nudges offline and deduplicates rapid repeated taps.
- **`DomainLayer/Social/GroupGoalEvaluator.swift`**:
  - Aggregates sanitized member snapshots to calculate weekly group goal completion percentages.

### 1.3 UI Surfaces
- **Today Screen Pod Card**: Shows pod members' status avatars, weekly cooperative goal ring, and 1-tap nudge shortcut.
- **`AccountabilityPodView` Sheet**: Member roster, invitation link sharing via standard `UIActivityViewController`, and cooperative goal history.
- **Invitation Acceptance Sheet**: Clean modal showing inviter's name and pod name with "Join Pod" confirmation.

---

## Pillar 2: Wrist Autonomy & Watch Complications (watchOS 11 v2)

### 2.1 Goals & Principles
- Untether the gym experience: let users leave their iPhone in a locker or gym bag.
- Bring glanceable readiness and cycle context directly to the watch face.
- Keep the lifter focused with silent wrist-haptic rest timer alerts.

### 2.2 Architecture & Components
- **`SundeeFundeeWatch/WatchWorkoutManager.swift`**:
  - Owns `HKWorkoutSession` and `HKLiveWorkoutBuilder`.
  - Collects real-time heart rate and active energy burned from the Apple Watch optical sensor.
  - Logs sets, reps, and weights directly on wrist.
  - Reconciles completed workout data to `SharedSnapshotStore` (`group.com.sundeefundee.shared`) and CloudKit when back in range.
- **`SundeeFundeeWatch/WatchHapticRestTimer.swift`**:
  - Uses `WKInterfaceDevice.current().play(.stop)` and `.notification` patterns at T-3s, T-2s, T-1s, and completion.
- **Watch Face Complications (`WidgetKit`)**:
  - `AccessoryCircular`: Readiness gauge (1–100) tinted by recommendation (Navy/Cream/Orange).
  - `AccessoryCorner`: Current cycle phase symbol and cycle day.
  - `AccessoryRectangular`: Today's recommended action (Train / Modify / Recover) + target workout name.
  - `AccessoryInline`: Compact text (e.g. *"Readiness 84 • Follicular"*).

---

## Pillar 3: In-Gym Workout Flow (Supersets, Plate Math & Fitness Rings)

### 3.1 Goals & Principles
- Eliminate common gym math friction and support standard strength training patterns (paired antagonistic supersets and conditioning circuits).
- Ensure every calorie and minute spent lifting is credited to Apple Watch Move/Exercise rings.

### 3.2 Architecture & Components
- **Supersets & Circuits**:
  - `DomainLayer/Workout/WorkoutExerciseGrouping.swift`: Models paired movements (`superset(id, [exerciseA, exerciseB])`, `circuit(id, [exercises])`).
  - `ActiveWorkoutSessionViewModel`: Alternates set progression (A1 Set 1 -> Short transition rest -> A2 Set 1 -> Long recovery rest -> A1 Set 2).
  - `ActiveWorkoutView`: Displays paired badges (`A1`, `A2`) and auto-swaps between paired exercises on set completion.
- **Barbell Plate Calculator (`PlateCalculatorService`)**:
  - Pure domain calculator: inputs target weight (e.g. 185 lbs / 82.5 kg), barbell weight (45 lb Olympic, 35 lb Technique, 55 lb Trap bar, 20 kg / 15 kg), and plate pairs inventory.
  - Returns required plates per side with visual plate stack diagrams (`PlateStackView`).
  - Accessible via one-tap plate icon beside any weight entry field in `ActiveWorkoutView` and `StartingWeightCalibrationSheet`.
- **Precision Apple Health Fitness Ring Sync**:
  - Upgrades `HealthKitClient.saveWorkout`:
    - Incorporates user body mass, duration, and exercise intensity/RPE to calculate accurate active calories burned when watch heart rate is unavailable.
    - Saves `.traditionalStrengthTraining` or `.functionalStrengthTraining` `HKWorkout`.
    - Closes Apple Fitness Move and Exercise rings immediately upon workout completion.
- **Apple Health Menstrual Flow Sync Verification**:
  - Validates bidirectional sync: automatically refreshes cycle phase predictions when new menstrual flow samples are recorded in Apple Health.

---

## Pillar 4: System Intelligence & Siri App Intents (iOS 18 Voice & Offline Polish)

### 4.1 Goals & Principles
- Natural hands-free voice control when getting ready in the morning or during a workout.
- Bulletproof offline confidence: clear visual status and manual "Retry Now" trigger in the Data Trust Center.

### 4.2 Architecture & Components
- **Expanded App Intents (`SundeeFundeeKit/Intents/`)**:
  - `CheckReadinessIntent`: *"What's my readiness today in Sundee Fundee?"*
    - Returns conversational dialog: *"Your readiness is 82. Today is a great day to Train — Follicular phase energy is high."*
  - `LogDailyStatusIntent`: *"Log my status as Resting in Sundee Fundee"*
    - Updates `DailyPresenceRecord` with chosen status without needing to open the app.
  - `TodayWorkoutIntent`: *"What's my workout today?"*
    - Speaks and displays the Coach Plan session overview.
  - `SundeeFundeeShortcutsProvider`:
    - Registers Siri App Shortcuts for easy discovery in the iOS 18 Shortcuts and Spotlight apps.
- **Offline Sync Queue Polish**:
  - Add an explicit `Flush Queue Now` button in `DataTrustCenterView` when mutations are pending.
  - Expose a subtle offline badge on the Today view when running on cached data with pending writes.

---

## Delivery Phases & Execution Order

```mermaid
flowchart TD
    subgraph Phase 1: Gym Flow & Fitness Rings
        P1A["Plate Calculator Service & UI"] --> P1B["Supersets & Circuits Engine"]
        P1B --> P1C["HealthKit Ring Sync Enhancement"]
    end

    subgraph Phase 2: Wrist Autonomy
        P2A["watchOS 11 Complications"] --> P2B["Wrist Haptic Rest Cues"]
        P2B --> P2C["Standalone HKWorkoutSession on Watch"]
    end

    subgraph Phase 3: Siri App Intents
        P3A["Readiness & Status Voice Intents"] --> P3B["AppShortcutsProvider Registration"]
        P3B --> P3C["Offline Flush Controls in Data Trust Center"]
    end

    subgraph Phase 4: Private Pods & Social
        P4A["SocialSnapshotBuilder & Redaction Engine"] --> P4B["CKShare AccountabilityService"]
        P4B --> P4C["Preset Encouragement & Cooperative Goals UI"]
    end

    Phase 1 --> Phase 2
    Phase 2 --> Phase 3
    Phase 3 --> Phase 4
```

### Phase 1: Gym Flow & Fitness Rings (Fastest User Value)
- Deliver `PlateCalculatorService` and `PlateCalculatorSheet`.
- Add `WorkoutExerciseGrouping` and superset alternating progression to `ActiveWorkoutSessionViewModel`.
- Enhance `HealthKitClient.saveWorkout` calorie calculations for reliable Fitness ring closure.

### Phase 2: Wrist Autonomy (watchOS 11 v2)
- Add WidgetKit complications for Apple Watch (Readiness & Cycle).
- Implement wrist haptic rest cues on `WKInterfaceDevice`.
- Implement standalone `HKWorkoutSession` on Apple Watch for phone-free workouts.

### Phase 3: Siri Voice & Offline Polish
- Add `CheckReadinessIntent`, `LogDailyStatusIntent`, and `TodayWorkoutIntent`.
- Register `SundeeFundeeShortcutsProvider`.
- Add manual queue flush button and offline status indicators to `DataTrustCenterView`.

### Phase 4: Private Accountability & Micro-Pods (v2 Social Layer)
- Implement `SocialSnapshotBuilder` with strict privacy tests.
- Build `AccountabilityService` managing `CKShare` invitations and memberships.
- Implement `EncouragementService` and cooperative weekly goals.
- Build Today screen Pod Card and pod management sheets.
