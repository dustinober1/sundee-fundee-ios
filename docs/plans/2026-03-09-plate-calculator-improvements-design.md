# Plate Calculator Improvements Design

**Issue:** #98
**Date:** 2026-03-09

## Overview

Improve the plate calculator by adding it to Actual Weight input fields, introducing per-exercise barbell type memory with smart defaults, and a new Equipment settings section for managing barbell presets.

## Data Models

### BarbellPreset (new SwiftData model)

| Field | Type | Description |
|-------|------|-------------|
| id | String | UUID |
| userID | String | Owner |
| name | String | e.g., "Standard", "EZ Curl" |
| weightKg | Double | Bar weight in kg |
| isBuiltIn | Bool | Protects from deletion |
| sortOrder | Int | Display ordering |

Built-in presets:

| Name | Pounds | Kg |
|------|--------|----|
| Standard | 45 lb | ~20.4 kg |
| Women's | 35 lb | ~15.9 kg |
| Training | 33 lb | ~15.0 kg |
| EZ Curl | 15 lb | ~6.8 kg |

### ExerciseBarMapping (new SwiftData model)

| Field | Type | Description |
|-------|------|-------------|
| id | String | UUID |
| userID | String | Owner |
| exerciseName | String | Exercise key |
| barbellPresetID | String | References BarbellPreset.id |

Schema migration: V10 → V11, lightweight (new empty tables).

## Smart Defaults (Domain)

`BarbellDefaults.suggestedPreset(for:gender:)` — static mapping from exercise keywords to bar type:

- Exercises containing "curl", "tricep extension", "skull crusher" → EZ Curl
- Compound barbell lifts (squat, bench, deadlift, OHP, row) + female gender → Women's
- All other barbell exercises → Standard

On first plate calculator use for an exercise, auto-create an ExerciseBarMapping with the suggested preset. User can override anytime.

## UI Changes

### Actual Weight Plate Calculator Trigger

Small `scalemass.fill` icon as trailing accessory inside the weight TextField in `SetRow`. Tapping it:
1. Takes current Actual Weight value (or prescribed weight if empty)
2. Looks up ExerciseBarMapping (or creates via smart defaults)
3. Opens PlateCalculatorSheet with that weight and bar

### PlateCalculatorSheet Enhancement

Bar type picker at the top of the existing sheet:
- Menu/segmented picker showing current bar preset name + weight
- Changing it recalculates plates immediately
- Changing it updates the ExerciseBarMapping for future use

### Settings → Equipment Section

New "Equipment" section in SettingsView (between "Training" and "Profile"):
- "Barbells" row → navigates to BarbellPresetsView
- List of all presets (built-ins not deletable, custom editable/deletable)
- "Add Custom Barbell" button — name + weight input, save disabled for invalid input

### Existing Header Icon

The scalemass icon on the exercise header stays as-is for prescribed weight.

## Repository Layer

New `BarbellRepository` protocol + `SwiftDataBarbellRepository`:
- `fetchPresets(userID:) -> [BarbellPreset]`
- `savePreset(_ preset: BarbellPreset)`
- `deletePreset(_ preset: BarbellPreset)`
- `fetchMapping(exerciseName:, userID:) -> ExerciseBarMapping?`
- `saveMapping(_ mapping: ExerciseBarMapping)`
- `seedBuiltInPresets(userID:)` — called once when no presets exist

## Data Flow

```
User taps scalemass in Actual Weight field
    ↓
WorkoutExecutionViewModel.openPlateCalcForActual(exerciseName:, weightKg:)
    ↓
Look up ExerciseBarMapping for exerciseName
    ├── Found → use mapped BarbellPreset
    └── Not found → BarbellDefaults.suggestedPreset() → create mapping
    ↓
Present PlateCalculatorSheet(weightKg:, barbellWeightKg:, presets:, selectedPresetID:)
    ↓
User changes bar type → update mapping, recalculate plates
```

### ViewModel Changes

- WorkoutExecutionViewModel gains BarbellRepository (injected)
- New properties: barbellPresets, selectedPresetID
- New method: openPlateCalcForActual(exerciseName:, weightKg:)
- Existing openPlateCalc(forWeight:) unchanged for header icon

## Testing

- **BarbellDefaultsTests** — keyword matching for all categories
- **PlateCalculation** — add cases for non-standard bar weights
- **BarbellRepositoryTests** — CRUD, mapping fetch/save, seed idempotency
- **WorkoutExecutionViewModelTests** — openPlateCalcForActual creates/uses/updates mappings
- Static helper tests for any new view static methods
- 100% line coverage maintained
