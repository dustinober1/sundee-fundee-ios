# Sex-Aware Tab Visibility & Profile Editing

## Problem

The Cycle tab shows for all users including males who will never use it. Users cannot change their biological sex after onboarding.

## Design

### 1. Hide Cycle Tab for Male Users

`MainTabView` currently uses `TabRoute.allCases` unconditionally. Change `orderedTabs` to accept a `Gender` parameter and filter out `.cycle` when gender is `.male`.

The user's gender will be queried from SwiftData inside `MainTabView` using `@Query` or passed from the parent view that already has access to the model context.

### 2. Add Biological Sex & Cycle Tracking to Edit Profile

Add to `SettingsViewModel`:
- `gender: Gender` property, loaded and saved with the user
- `cycleTrackingEnabled: Bool` property, loaded and saved with the user

Add to `EditProfileView`:
- "Biological Sex" section with a `Picker` for `Gender.allCases`
- "Cycle Tracking" section (visible only when gender != `.male`) with a `Toggle` for `cycleTrackingEnabled`
- When user changes gender to `.male`, automatically set `cycleTrackingEnabled = false`

### 3. Tests

- `MainTabView`: verify `.cycle` tab excluded for `.male`, included for `.female` and `.preferNotToSay`
- `SettingsViewModel`: verify `gender` and `cycleTrackingEnabled` load/save correctly
- `EditProfileView`: verify cycle toggle visibility is conditional on gender

## Files to Change

- `SundeeFundee/Features/Shell/MainTabView.swift`
- `SundeeFundee/Features/Settings/SettingsView.swift` (EditProfileView)
- `SundeeFundee/Features/Settings/SettingsViewModel.swift`
- `SundeeFundeTests/` — corresponding test files
