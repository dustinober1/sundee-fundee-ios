# Travel Mode & Bodyweight-Only Mode — Design

## Concept

A persistent "Travel Mode" toggle that constrains the AI workout experience for on-the-go training. When active, it limits equipment to bodyweight-only or hotel gym, adds space/noise-aware prompt constraints, and defaults to shorter durations.

## Data Model

- Add `travelModeEnabled: Bool` to the `User` SwiftData model (default `false`)
- Add `hotelGym` case to `EquipmentAccess` enum — limited dumbbells (10-50 lb), bench, cable machine, no barbell

## Settings

- New "Travel Mode" toggle in Settings > Training section
- When toggled on, immediately takes effect for next workout generation

## Dashboard

- When Travel Mode is active, show a banner at the top: "Travel Mode active — limited equipment" with a "Turn Off" button
- Banner uses existing Art Deco theme (navy background, cream text, orange accent)

## Questionnaire Changes

- When Travel Mode is on:
  - Show a "Travel Mode" chip/indicator at the top
  - Equipment picker narrows to only `bodyweightOnly` and `hotelGym`
  - Duration defaults to 30 min instead of 45
- When Travel Mode is off: no changes to current behavior

## AI Prompt Changes

- When Travel Mode is active, `GeminiPromptBuilder` adds constraints:
  - "User is traveling — minimize space requirements"
  - "Avoid exercises requiring jumping or loud impacts"
  - "Prefer exercises that can be done in a small room or hotel gym"
- `hotelGym` equipment type gets its own weight constraints: dumbbells 10-50 lb only, no barbell, basic cable machine

## Offline Fallback

- `OfflineWorkoutGenerator` respects Travel Mode — bodyweight/hotel gym template workouts

## Testing

- Domain logic: Travel Mode context building, prompt constraints, equipment filtering
- ViewModel: toggle state, questionnaire defaults, equipment filtering
- Coverage tests for new enum case and prompt builder changes
